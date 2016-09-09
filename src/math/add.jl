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
      (rhs == -lhs) && return zero(PTile{lattice, epochbits})
      exact_add(lhs, rhs, OT)
    else
      inexact_add(lhs, rhs, OT)
    end
  end
end

#sometimes you need to double check it's not a special value.
function checked_exact_add{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  is_zero(lhs) && return rhs
  is_zero(rhs) && return lhs
  (rhs == -lhs) && return zero(PTile{lattice, epochbits})

  exact_add(lhs, rhs, OT)
end

function exact_add{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  (big, sml) = abs(lhs) > abs(rhs) ? (decompose(lhs), decompose(rhs)) : (decompose(rhs), decompose(lhs))

  synthesize(PTile{lattice, epochbits}, exact_add_sorted(big, sml, Val{lattice}, OT))
end

function exact_add{lattice, output}(lhs::__dc_tile, rhs::__dc_tile, L::Type{Val{lattice}}, OT::Type{Val{output}})
  (big, sml) = magbigger(lhs, rhs) ? (lhs, rhs) : (rhs, lhs)

  exact_add_sorted(lhr, rhs, L, OT)
end

function magbigger(lhs::__dc_tile, rhs::__dc_tile)
  lhs_inverted = is_inverted(lhs)
  (lhs_inverted $ is_inverted(rhs)) && return is_uninverted(lhs)

  (lhs.epoch < rhs.epoch)   && return !lhs_inverted
  (lhs.epoch > rhs.epoch)   && return lhs_inverted
  (lhs.lvalue < rhs.lvalue) && return !lhs_inverted
  return lhs_inverted
end

function exact_add_sorted{lattice, output}(big::__dc_tile, sml::__dc_tile, L::Type{Val{lattice}}, OT::Type{Val{output}})

  subtraction = is_negative(big) $ is_negative(sml)

  if (subtraction)
    #for now, only support adding a non-inverted value to a non-inverted value.
    res = exact_algorithmic_subtraction(big, sml, Val{lattice}, OT)
  else
    res = exact_algorithmic_addition(big, sml, Val{lattice}, OT)
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

function exact_algorithmic_addition{lattice, output}(big::__dc_tile, sml::__dc_tile, L::Type{Val{lattice}}, OT::Type{Val{output}})
  res::__dc_tile = big

  if is_uninverted(big) && is_uninverted(sml) #add a non-inverted value to a non-inverted value.
    (res.epoch, res.lvalue) = uninverted_addition_decomposed(big, sml, Val{lattice}, OT)
  elseif (is_inverted(big) && is_inverted(sml))   #add an inverted value to an inverted value.
    (invert, res.epoch, res.lvalue) = inverted_addition_decomposed(big, sml, Val{lattice}, OT)
    invert && set_uninverted!(res)
  else #add two values which are crossed.
    (res.epoch, res.lvalue) = crossed_addition_decomposed(big, sml, Val{lattice}, OT)
  end

  res
end

#perform the calculation of uninverted addition using partial (decomposed) values.
@generated function uninverted_addition_decomposed{lattice, output}(big::__dc_tile, sml::__dc_tile, L::Type{Val{lattice}}, OT::Type{Val{output}})

  #ensure that the requisite tables exist.
  add_table = table_name(lattice, :add)
  isdefined(Unum2, add_table) || create_uninverted_addition_tables(Val{lattice})
  quote
    #NB:  move this to be a precompiled value instead of a calculated value.

    cells = size($add_table, 1)

    lookup_cell = big.epoch - sml.epoch + 1

    if lookup_cell <= cells #if the cells exist...
      res_lvalue = $add_table[lookup_cell, big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
      res_epoch = (res_lvalue < big.lvalue) ? (big.epoch + 1) : big.epoch
    else  #we don't need any informational cells because the result is simply bumped up.
      res_epoch = big.epoch
      res_lvalue = big.lvalue + 1
    end

    (res_epoch, res_lvalue)
  end
end

#perform the calculation of inverted addition using partial (decomposed) values.
@generated function inverted_addition_decomposed{lattice, output}(big::__dc_tile, sml::__dc_tile, L::Type{Val{lattice}}, OT::Type{Val{output}})

  #ensure that the requisite tables exist.
  add_inv_table = table_name(lattice, :add_inv)
  isdefined(Unum2, add_inv_table) || create_inverted_addition_tables(Val{lattice})
  max_lvalue = (length(__MASTER_LATTICE_LIST[lattice]) << 1) + 1
  quote
    cells = size($add_inv_table, 1)
    lookup_cell = sml.epoch - big.epoch + 1

    if lookup_cell <= cells
      res_lvalue = $add_inv_table[1, big.lvalue >> 1  + 1, sml.lvalue >> 1 + 1]
      res_epoch = (res_lvalue > big.lvalue) ? (big.epoch - 1) : big.epoch
    elseif (big.lvalue != 0)
      res_epoch = big.epoch
      res_lvalue = big.lvalue - 1
    else
      res_epoch -= 1
      res_lvalue = $max_lvalue
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
  isdefined(Unum2, add_cross_table) || create_crossed_addition_tables(Val{lattice})
  quote
    cells = size($add_cross_table, 1)

    #calculating the lookup cell looks funny, but really it's fine.  Example:
    # uninverted 0, inverted 0 - cell 1
    # uninverted 0, inverted 1 - cell 2
    # uninverted 1, inverted 0 - cell 2
    lookup_cell = big.epoch + sml.epoch + 1

    #if (lookup_cell <= cells)
    if lookup_cell == 1
      res_lvalue = $add_cross_table[lookup_cell, big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
      res_epoch = (res_lvalue < big.lvalue) ? (big.epoch + 1) : big.epoch
    else
      res_epoch = big.epoch
      res_lvalue = big.lvalue + 1
    end

    (res_epoch, res_lvalue)
  end
end

################################################################################
# ADDITION TABLES
################################################################################

doc"""
  Unum2.create_uninverted_addition_tables(::Type{Val{lattice}})

  creates addition tables for a given lattice, including cross-epoch lattices
"""
@generated function create_uninverted_addition_tables{lattice}(::Type{Val{lattice}})
  add_table = table_name(lattice, :add)
  quote
    #calculate how many addition lattice cells we'll need.
    cells = count_uninverted_addition_cells(Val{lattice}) + 1

    #store the lattice values and the stride values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    stride_value = __MASTER_STRIDE_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $add_table = Array(UT_Int, cells, l + 1, l + 1)

    #create all the tables.
    for add_cell = 1:cells
      populate_uninverted_addition_table!($add_table, lattice_values, stride_value, add_cell - 1)
    end

    #create the secondary tables.
  end
end

function populate_uninverted_addition_table!(table, lattice_values, stride_value, epoch_delta)
  l = length(lattice_values)
  power_factor = stride_value ^ epoch_delta

  for idx = 0:l, idx2 = 0:l
    true_value = ((power_factor * ((idx == 0) ? 1 : 1 * lattice_values[idx]))) +
                 ((idx2 == 0) ? 1 : lattice_values[idx2])
    #first check to see if the true_value corresponds to the stride value.
    (true_value >= power_factor * stride_value) && (true_value /= stride_value)

    table[epoch_delta + 1, idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value, power_factor)
  end
end

@generated function create_inverted_addition_tables{lattice}(::Type{Val{lattice}})
  add_inv_table = table_name(lattice, :add_inv)
  quote
    inv_cells = count_uninverted_addition_cells(Val{lattice}) + 1

    #store the lattice values and the stride values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    stride_value = __MASTER_STRIDE_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $add_inv_table = Array(UT_Int, inv_cells, l + 1, l + 1)

    #create all the tables.
    for add_inv_cell = 1:inv_cells
      populate_inverted_addition_table!($add_inv_table, lattice_values, stride_value, add_inv_cell - 1)
    end
  end
end

function populate_inverted_addition_table!(table, lattice_values, stride_value, epoch_delta)
  l = length(lattice_values)
  power_factor = stride_value ^ epoch_delta
  for idx = 0:l, idx2 = 0:l
    true_value = 1 / (((idx == 0) ? power_factor : power_factor/lattice_values[idx]) +
                 ((idx2 == 0) ? 1 : 1/lattice_values[idx2]))
    #first check to see if the true_value corresponds to the stride value.
    (true_value < power_factor) && (true_value *= stride_value)

    table[epoch_delta + 1, idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value, power_factor)
  end
end

@generated function create_crossed_addition_tables{lattice}(::Type{Val{lattice}})
  add_cross_table = table_name(lattice, :add_cross)
  quote

    #calculate how many addition lattice cells we'll need.
    cross_cells = count_crossed_addition_cells(Val{lattice}) + 1

    #store the lattice values and the stride values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    stride_value = __MASTER_STRIDE_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $add_cross_table = Array(UT_Int, cross_cells, l + 1, l + 1)

    for add_cross_cell = 1:cross_cells
      populate_crossed_addition_table!($add_cross_table, lattice_values, stride_value, add_cross_cell)
    end
  end
end

function populate_crossed_addition_table!(table, lattice_values, stride_value, epoch_delta)
  l = length(lattice_values)
  power_factor = stride_value ^ epoch_delta

  for idx = 0:l, idx2 = 0:l
    true_value = (((idx == 0) ? power_factor : power_factor * lattice_values[idx]) +
                 ((idx2 == 0) ? 1 : 1/lattice_values[idx2]))
    #first check to see if the true_value corresponds to the stride value.
    (true_value >= power_factor * stride_value) && (true_value /= stride_value)

    table[epoch_delta, idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value, power_factor)
  end
end
