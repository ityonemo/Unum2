#add.jl -- Unum2 addition.
#impmements the following:
#  + Operator overloading.
#  PBound addition.
#  Call decision for algorithmic addition vs. algorithmic subtraction
#  Addition algorithms.
#  Addition table generation.

import Base.+

################################################################################
# OPERATOR OVERLOADING
################################################################################

@pfunction function +(lhs::PBound, rhs::PBound)
  #encapuslates calling the more efficient "add" function, which does not need
  #to allocate memory.

  res::B = emptyset(B)
  add!(res, lhs, rhs)
  res
end

################################################################################
# PBOUND ADDITION
################################################################################

doc"""
  `Unum2.add!(res::PBound, lhs::PBound, rhs::PBound)`  Takes two input values,
  lhs and rhs and adds them together into the memory slot allocated by res.

  `Unum2.add!(acc::PBound, rhs::PBound)`  Takes the value in rhs and adds it
  in to the accumulator slot.
"""
@pfunction function add!(res::PBound, lhs::PBound, rhs::PBound)
  copy!(res, lhs)
  add!(res, rhs)
end

@pfunction function add!(acc::PBound, rhs::PBound)
  (isempty(acc) || isempty(rhs)) && (set_empty!(acc); return)
  (ispreals(acc) || ispreals(rhs)) && (set_preals!(acc); return)

  check_roundsinf::Bool = containsinf(acc) || containsinf(rhs)

  #create some proxy variables that refer to the correct type
  l_upper_proxy::T = issingle(acc) ? acc.lower : acc.upper
  r_upper_proxy::T = issingle(rhs) ? rhs.lower : rhs.upper

  set_double!(acc)

  #for addition, result_upper = left_upper + right_upper, always.
  acc.upper = add(l_upper_proxy, r_upper_proxy, __UPPER)
  #for addition, result_lower = left_lower + right_lower, always.
  acc.lower = add(acc.lower, rhs.lower, __LOWER)

  if (check_roundsinf)
    # let's make sure our result still rounds inf, this is a property which is
    # invariant under addition.  Losing this property suggests that the answer
    # should be recast as "allreals."  While we're at it, check to see if the
    # answer ends now "touch", which makes them "allreals".
    (@s acc.lower) <= (@s acc.upper) && (set_preals!(acc); return)
    (next(acc.upper) == acc.lower) && (set_preals!(acc); return)
  end

  (acc.upper == acc.lower) && set_single!(acc)

  nothing
end


################################################################################
# CALL DECISION for algorithmic addition or subtraction.
################################################################################

doc"""
  `Unum2.add(lhs::PTile, rhs::PTile, ::Type{Val{output}})`  Takes two input values,
  lhs, and rhs, and adds them.  It then strictly outputs the PTile that corresponds
  to the output type, which may be "upper" or "lower."
"""
@generated function add{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  #guard this function, protecting from other types of output values besides
  #upper or lower.

  (output != :upper) && (output != :lower) && throw(ArgumentError("output type $output is not supported"))

  quote
    (is_inf(lhs) | is_inf(rhs)) && return inf(PTile{lattice,epochbits})
    is_zero(lhs) && return rhs
    is_zero(rhs) && return lhs

    if isexact(lhs) & isexact(rhs)
      exact_add(lhs, rhs, OT)
    else
      inexact_add(lhs, rhs, OT)
    end
  end
end

#sometimes you need to double check it's not a special value.
function checked_exact_add{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  is_zero(lhs) && return rhs;
  is_zero(rhs) && return lhs;

  exact_add(lhs, rhs, OT)
end

function exact_add{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  if (isnegative(lhs) $ isnegative(rhs))
    exact_algorithmic_subtraction(lhs, -rhs, OT)
  else
    exact_algorithmic_addition(lhs, rhs, OT)
  end
end

@generated function inexact_add{lattice, epochbits, output}(x::PTile{lattice, epochbits}, y::PTile{lattice, epochbits}, OT::Type{Val{output}})
  if output == :lower
    quote
      (is_neg_many(x) || is_neg_many(y)) ? neg_many(PTile{lattice, epochbits}) : upperulp(checked_exact_add(glb(x), glb(y), OT))
    end
  elseif output == :upper
    quote
      (is_pos_many(x) || is_pos_many(y)) ? pos_many(PTile{lattice, epochbits}) : lowerulp(checked_exact_add(lub(x), lub(y), OT))
    end
  end
end

################################################################################
# ALGORITHMIC ADDITION
################################################################################

function exact_algorithmic_addition{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  #reorder the two values so that they're in magnitude order.
  (h, l) = ((lhs > rhs) $ (isnegative(lhs))) ? (lhs, rhs) : (rhs, lhs)

  big = decompose(h)
  sml = decompose(l)

  res::__dc_tile = big

  if is_uninverted(big) && is_uninverted(sml) #add a non-inverted value to a non-inverted value.
    (res.epoch, res.lvalue) = uninverted_addition_decomposed(big, sml, Val{lattice}, OT)
  elseif (is_inverted(big) && is_inverted(sml))   #add an inverted value to an inverted value.
    (invert, res.epoch, res.lvalue) = inverted_addition_decomposed(big, sml, Val{lattice}, OT)
    invert && set_uninverted!(res)
  else #add two values which are crossed.
    (res.epoch, res.lvalue) = crossed_addition_decomposed(big, sml, Val{lattice}, OT)
  end

  #reconstitute the result.
  synthesize(PTile{lattice, epochbits}, res)
end


#perform the calculation of uninverted addition using partial (decomposed) values.
@generated function uninverted_addition_decomposed{lattice, output}(big::__dc_tile, sml::__dc_tile, L::Type{Val{lattice}}, OT::Type{Val{output}})

  #ensure that the requisite tables exist.
  add_table = table_name(lattice, :add)
  isdefined(Unum2, add_table) || create_addition_table(Val{lattice})

  quote
    if big.epoch == sml.epoch
      res_value = $add_table[big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
      res_epoch = (res_value < big.lvalue) ? (big.epoch + 1) : big.epoch
    else
      return nothing #for now.
      #(result_value, result_epoch) = (h_epoch > l_epoch) ? add_unequal_epoch(x, y) : add_unequal_epoch(y, x)
    end
    (res_epoch, res_value)
  end
end

#perform the calculation of inverted addition using partial (decomposed) values.
@generated function inverted_addition_decomposed{lattice, output}(big::__dc_tile, sml::__dc_tile, L::Type{Val{lattice}}, OT::Type{Val{output}})

  #ensure that the requisite tables exist.
  add_inv_table = table_name(lattice, :add_inv)
  isdefined(Unum2, add_inv_table) || create_inverted_addition_table(Val{lattice})
  quote
    #println("this screws up...")
    if (big.epoch == sml.epoch)
      res_lvalue = $add_inv_table[big.lvalue >> 1  + 1, sml.lvalue >> 1 + 1]
      res_epoch = (res_lvalue > big.lvalue) ? (big.epoch - 1) : big.epoch
    else
      return nothing # for now.
    end

    #may need to reverse the orientation on the result.
    res_uninvert = false
    if (res_epoch < 0)
      res_uninvert = true
      res_epoch = (-res_epoch) - 1
      res_lvalue = lattice_invert(res_lvalue, Val{lattice}, OT)
    end

    (res_uninvert, res_epoch, res_lvalue)
  end
end

@generated function crossed_addition_decomposed{lattice, output}(big::__dc_tile, sml::__dc_tile, L::Type{Val{lattice}}, OT::Type{Val{output}})

  #ensure that the requisite tables exist.
  add_cross_table = table_name(lattice, :add_cross)
  isdefined(Unum2, add_cross_table) || create_crossed_addition_table(Val{lattice})
  quote
    if (big.epoch == 0) && (big.epoch == 0) #h is not inverted, and l is inverted
      res_value = $add_cross_table[big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
      res_epoch = (res_value < big.lvalue) ? (big.epoch + 1) : big.epoch
    else
      return nothing #for now.
    end

    (res_epoch, res_value)
  end
end

################################################################################
# ADDITION TABLES
################################################################################

@generated function create_addition_table{lattice}(::Type{Val{lattice}})
  add_table = table_name(lattice, :add)
  quote
    #store the lattice values and the pivot values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $add_table = Matrix{UInt64}(l + 1, l + 1)

    for idx = 0:l, idx2 = 0:l
      true_value = ((idx == 0) ? 1 : lattice_values[idx]) +
                   ((idx2 == 0) ? 1 : lattice_values[idx2])
      #first check to see if the true_value corresponds to the pivot value.
      (true_value >= pivot_value) && (true_value /= pivot_value)

      $add_table[idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
    end
  end
end

@generated function create_inverted_addition_table{lattice}(::Type{Val{lattice}})
  add_inv_table = table_name(lattice, :add_inv)
  quote
    #store the lattice values and the pivot values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $add_inv_table = Matrix{UInt64}(l + 1, l + 1)

    for idx = 0:l, idx2 = 0:l
      true_value = 1/(((idx == 0) ? 1 : 1/lattice_values[idx]) +
                   ((idx2 == 0) ? 1 : 1/lattice_values[idx2]))

      #first check to see if the true_value corresponds to the pivot value.
      (true_value < 1) && (true_value *= pivot_value)

      $add_inv_table[idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
    end
  end
end

@generated function create_crossed_addition_table{lattice}(::Type{Val{lattice}})
  add_cross_table = table_name(lattice, :add_cross)
  quote
    #store the lattice values and the pivot values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $add_cross_table = Matrix{UInt64}(l + 1, l + 1)

    for idx = 0:l, idx2 = 0:l
      true_value = (((idx == 0) ? 1 : lattice_values[idx]) +
                   ((idx2 == 0) ? 1 : 1/lattice_values[idx2]))
      #first check to see if the true_value corresponds to the pivot value.
      (true_value >= pivot_value) && (true_value /= pivot_value)

      $add_cross_table[idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
    end
  end
end
