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

  `Unum2.add!(acc::Pbound, rhs::PBound)`  Takes the value in rhs and adds it
  in to the accumulator slot.
"""
@pfunction function add!(res::PBound, lhs::PBound, rhs::Pbound)
  copy!(res, lhs)
  add!(res, rhs)
end

@pfunction function add!(acc::PBound, rhs::PBound)
  (isempty(acc) || isempty(rhs)) && (set_empty!(acc); return)
  (ispreals(acc) || ispreals(rhs)) && (set_preals!(acc); return)

  check_roundsinf::Bool = roundsinf(acc) || roundsinf(rhs)

  #create some proxy variables that refer to the correct type
  l_upper_proxy::T = issingle(acc) ? acc.lower : acc.upper
  r_upper_proxy::T = issingle(rhs) ? rhs.lower : rhs.upper

  set_double!(dest)

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

function add{lattice, epochbits, output}(x::PTile{lattice, epochbits}, y::PTile{lattice, epochbits}, OT::Type{Val{output}})
  is_inf(x) && return inf(PTile{lattice,epochbits})
  is_inf(y) && return inf(PTile{lattice,epochbits})
  is_zero(x) && return y
  is_zero(y) && return x

  if isexact(x) & isexact(y)
    exact_add(x, y, OT)
  else
    inexact_add(x, y, OT)
  end
end

#=
#adds two numbers x, y

function exact_add{lattice, epochbits, output}(x::PTile{lattice, epochbits}, y::PTile{lattice, epochbits}, OT::Type{Val{output}})
  if (isnegative(x) $ isnegative(y))
    exact_arithmetic_subtraction(x, -y, OT)
  else
    exact_arithmetic_addition(x, y, OT)
  end
end

@generated function exact_arithmetic_addition{lattice, epochbits, output}(x::PTile{lattice, epochbits}, y::PTile{lattice, epochbits}, OT::Type{Val{output}})
  #first figure out the epoch reduction limit
  add_table       = table_name(lattice, :add)
  add_inv_table   = table_name(lattice, :add_inv)
  add_cross_table = table_name(lattice, :add_cross)
  m_epoch = max_epoch(epochbits)

  #create the additive reduction table, if necessary.
  #NB THE MORE ACCURATE WAY TO DO THIS IS TO HAVE A FULL ADDITION MATRIX FOR EACH
  #EPOCH REDUCTION, BUT THIS IS THE MORE MEMORY-PERFORMANT WAY TO DO THIS.  IF
  #THE LATTICE DELTA IS NEVER DECREASING, THIS IS ALWAYS GOOD ENOUGH?  MAYBE.
  #create the addition table, if necessary.

  isdefined(Unum2, add_table)       || create_addition_table(Val{lattice})
  isdefined(Unum2, add_inv_table)   || create_inverted_addition_table(Val{lattice})
  isdefined(Unum2, add_cross_table) || create_crossed_addition_table(Val{lattice})

  quote
    is_zero(x) && return y
    is_zero(y) && return x
    #reorder the two values so that they're in magnitude order.
    (h, l) = ((x > y) $ (isnegative(x))) ? (x, y) : (y, x)

    (h_negative, h_inverted, h_epoch, h_value) = decompose(h)
    (l_negative, l_inverted, l_epoch, l_value) = decompose(l)

    result_epoch::Int64

    #for now, only support adding a non-inverted value to a non-inverted value.
    if (!h_inverted) && (!l_inverted)
      #for now, only support adding things that are in the same epoch.
      if h_epoch == l_epoch
        result_value = $add_table[h_value >> 1 + 1, l_value >> 1 + 1]
        result_epoch = (result_value < h_value) ? (h_epoch + 1) : h_epoch
      else
        return nothing #for now.
        #(result_value, result_epoch) = (h_epoch > l_epoch) ? add_unequal_epoch(x, y) : add_unequal_epoch(y, x)
      end

      ((result_epoch) > $m_epoch) && return coerce(extremum(PTile{lattice, epochbits}, h_negative, false), OT)

      return synthesize(PTile{lattice, epochbits}, h_negative, false, result_epoch, result_value, OT)
    elseif ((h_inverted) && (l_inverted))
      result_inverted = true

      #in case we've crossed over.
      if (result_epoch < 0)
        result_inverted = false
        result_epoch = 0
      end

      return synthesize(PTile{lattice, epochbits}, h_negative, result_inverted, result_epoch, result_value, OT)
    elseif (h_epoch == 0) && (l_epoch == 0) #h is not inverted, and l is inverted
      result_value = $add_cross_table[h_value >> 1 + 1, l_value >> 1 + 1]
      result_epoch = (result_value > h_value) ? (h_epoch + 1) : h_epoch

      return synthesize(PTile{lattice, epochbits}, h_negative, false, result_epoch, result_value, OT)
    else
      return nothing #for now.
    end
  end
end

################################################################################
# ADDITION TABLES

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

@generated function inexact_add{lattice, epochbits, output}(x::PTile{lattice, epochbits}, y::PTile{lattice, epochbits}, OT::Type{Val{output}})
  if output == :lower
    quote
      (is_neg_many(x) || is_neg_many(y)) ? neg_many(PTile{lattice, epochbits}) : upperulp(exact_add(glb(x), glb(y), OT))
    end
  elseif output == :upper
    quote
      (is_pos_many(x) || is_pos_many(y)) ? pos_many(PTile{lattice, epochbits}) : lowerulp(exact_add(lub(x), lub(y), OT))
    end
  else
    quote
      _l = inexact_add(x, y, Val{:lower})
      _u = inexact_add(x, y, Val{:upper})

      (output == :bound) ? PBound{lattice, epochbits}(_l, _u) : _auto(_l, _u)
    end
  end
end
=#
