#mul.jl -- Unum2 multiplication.
#impmements the following:
#  * Operator overloading.
#  PBound multiplication.
#  Call decision for algorithmic multiplication vs. algorithmic division.
#  Multiplication algorithms.
#  Multiplication table generation.

import Base.*

################################################################################
# OPERATOR OVERLOADING
################################################################################

@pfunction function *(lhs::PBound, rhs::PBound)
  #encapuslates calling the more efficient "add" function, which does not need
  #to allocate memory.

  res::B = emptyset(B)
  mul!(res, lhs, rhs)
  res
end

################################################################################
# PBOUND MULTIPLICATION
################################################################################

doc"""
  `Unum2.mul!(res::PBound, lhs::PBound, rhs::PBound)`  Takes two input values,
  lhs and rhs and multiplies them together into the memory slot allocated by res.

  `Unum2.mul!(acc::PBound, rhs::PBound)`  Takes two input values,
  acc and rhs and multiplies them together into the memory slot allocated by acc.
"""
@pfunction function mul!(res::PBound, lhs::PBound, rhs::PBound)
  copy!(res, lhs)
  mul!(res, rhs)
end

@pfunction function mul!(acc::PBound, rhs::PBound)
  #terminate early on special values.
  (isempty(acc) || isempty(rhs)) && (set_empty!(acc); return)
  (ispreals(acc) || ispreals(rhs)) && (set_preals!(acc); return)

  #to make calculations simple, ensure that the upper is equal to the lower.
  if issingle(acc)
    single_mul!(acc, acc, rhs)
  elseif issingle(rhs)
    single_mul!(acc, rhs, acc)
  elseif containsinf(acc)
    inf_mul!(acc, acc, rhs)
  elseif containsinf(rhs)
    inf_mul!(acc, rhs, acc)
  elseif __simple_roundszero(acc)
    zero_mul!(acc, acc, rhs)
  elseif __simple_roundszero(rhs)
    zero_mul!(acc, rhs, acc)
  else
    std_mul!(acc, rhs)
  end

  acc
end


doc"""
  Unum2.single_mul!(acc::PBound, lhs::PBound, rhs::PBound)

  performs a multiplication on two PBounds, placing the result into the acc
  value.  lhs is guaranteed to be a "single" element.
"""
@pfunction function single_mul!(acc::PBound, lhs::PBound, rhs::PBound)  #do a few critical single checks.
  #first check if rhs is SINGLETON.
  if issingle(rhs)
    if is_zero(lhs.lower)
      is_inf(rhs.lower) && (set_preals!(acc); return)
      (acc.lower = zero(T); set_single!(acc); return)
    end

    if is_zero(rhs.lower)
      is_inf(lhs.lower) && (set_preals!(acc); return)
      (acc.lower = zero(T); set_single!(acc); return)
    end

    is_inf(lhs.lower) && (acc.lower = inf(T); set_single!(acc); return)
    is_inf(rhs.lower) && (acc.lower = inf(T); set_single!(acc); return)
    is_zero(lhs.lower) && (acc.lower = zero(T); set_single!(acc); return)
    is_zero(rhs.lower) && (acc.lower = zero(T); set_single!(acc); return)

    set_double!(acc)

    flip_sign = isnegative(lhs) $ isnegative(rhs)
    acc.upper = sided_abs_mul(lhs.lower, rhs.lower, __UPPER)
    acc.lower = sided_abs_mul(lhs.lower, rhs.lower, __LOWER)
    flip_sign && additiveinverse!(acc)

    (acc.lower == acc.upper) ? set_single!(acc) : set_double!(acc)
  else
    if (is_zero(lhs.lower) && containsinf(rhs)) || (is_inf(lhs.lower) && containszero(rhs))
      set_preals!(acc)
      return
    end
    acc.lower = mul(lhs.lower, rhs.lower, __LOWER)
    acc.upper = mul(lhs.lower, rhs.upper, __UPPER)

    (acc.lower == acc.upper) ? set_single!(acc) : set_double!(acc)
  end
end

doc"""
  Unum2.inf_mul!(acc::PBound, lhs::PBound, rhs::PBound)

  performs a multiplication on two PBounds, placing the result into the acc
  value.  lhs is guaranteed to be a "double" element that "containsinf", which
  according to our definition, either has infnity as the upper or lower element,
  or has its upper element less than its lower element (going 'round the horn'
  on the projective reals).
"""
@pfunction function inf_mul!(acc::PBound, lhs::PBound, rhs::PBound)  #do a few critical single checks.
  if containszero(rhs)
    #check to see if the rhs contains zero in any way, which will trigger the
    #result to be all projective reals.
    set_preals!(acc)

  elseif containszero(lhs)
    #it's possible for the value to round both infinity AND zero.

    #check if we have an infinite-valued rhs, which triggers preals.
    containsinf(rhs) && (set_preals!(acc); return)

    #at this juncture, the value lhs must round both zero and infinity, and
    #the value rhs must be a standard, nonflipped double interval that is only on
    #one side of zero.

    # (100, 1) * (3, 4)     -> (300, 4)    (l * l, u * u)
    # (100, 1) * (-4, -3)   -> (-4, -300)  (u * l, l * u)
    # (-1, -100) * (3, 4)   -> (-4, -300)  (l * u, u * l)
    # (-1, -100) * (-4, -3) -> (300, 4)    (u * u, l * l)

    _state = isnegative(lhs) * 1 + isnegative(rhs) * 2

    #assign upper and lower values based on the bounds
    if (_state == 0)
      _l = mul(lhs.lower, rhs.lower, __LOWER)
      _u = mul(lhs.upper, rhs.upper, __UPPER)
    elseif (_state == 1)
      _l = mul(lhs.upper, rhs.lower, __LOWER)
      _u = mul(lhs.lower, rhs.upper, __UPPER)
    elseif (_state == 2)
      _l = mul(lhs.upper, rhs.lower, __LOWER)
      _u = mul(lhs.lower, rhs.upper, __UPPER)
    else   #state == 3
      _l = mul(lhs.upper, rhs.upper, __LOWER)
      _u = mul(lhs.lower, rhs.lower, __UPPER)
    end

    #check two cases: if the result has "flipped around" and now need to be
    #represented by all reals.
    (@s _l) <= (@s _u) && (set_preals!(acc); return)
    (next(_u) == _l) && (set_preals!(acc); return)

    acc.lower = _l
    acc.upper = _u
  elseif containsinf(rhs)  #now we must check if rhs rounds infinity.
    #like the double "rounds zero" case, we have to check four possible endpoints.
    _l1 = is_inf(lhs.lower) | is_inf(rhs.lower) ? inf(T) : mul(lhs.lower, rhs.lower, __LOWER)
    _l2 = is_inf(lhs.upper) | is_inf(rhs.upper) ? inf(T) : mul(lhs.upper, rhs.upper, __LOWER)
    _u1 = is_inf(lhs.lower) | is_inf(rhs.upper) ? inf(T) : mul(lhs.lower, rhs.upper, __UPPER)
    _u2 = is_inf(lhs.upper) | is_inf(rhs.lower) ? inf(T) : mul(lhs.upper, rhs.lower, __UPPER)

    #construct the result.
    acc.lower = min(_l1, _l2)
    acc.upper = max(_l1, _l2)
  else  #the last case is if lhs rounds infinity but rhs is a "well-behaved" value.
    #canonical example:
    # (2, -3) * (5, 7) -> (10, -15)
    # (2, -3) * (-7, -5) -> (15, -10)

    if isnegative(rhs)
      _l = is_inf(lhs.upper) | is_inf(rhs.upper) ? inf(T) : mul(lhs.upper, rhs.upper, __LOWER)
      _u = is_inf(lhs.lower) | is_inf(rhs.lower) ? inf(T) : mul(lhs.lower, rhs.upper, __UPPER)

      acc.lower = _l
      acc.upper = _u
    else
      acc.lower = is_inf(lhs.lower) | is_inf(rhs.lower) ? inf(T) : mul(lhs.lower, rhs.lower, __LOWER)
      acc.upper = is_inf(lhs.upper) | is_inf(rhs.upper) ? inf(T) : mul(lhs.upper, rhs.lower, __UPPER)
    end
  end
end


#a quick accessory function that tests if a bound (that is known to not round infinity)
# rounds zero.
__simple_roundszero(x::PBound) = isnegative(x.lower) && ispositive(x.upper)

doc"""
  Unum2.zero_mul!(acc::PBound, lhs::PBound, rhs::PBound)

  performs a multiplication on two PBounds, placing the result into the acc
  value.  lhs is guaranteed to be a "double" element that "containsinf", which
  according to our definition, either has infnity as the upper or lower element,
  or has its upper element less than its lower element (going 'round the horn'
  on the projective reals).
"""
@pfunction function zero_mul!(acc::PBound, lhs::PBound, rhs::PBound)
  if __simple_roundszero(rhs)
    # when rhs spans zero, we have to check four possible endpoints.
    _l = min(mul(lhs.lower, rhs.upper, __LOWER), mul(lhs.upper, rhs.lower, __LOWER))
    _u = max(mul(lhs.lower, rhs.lower, __UPPER), mul(lhs.upper, rhs.upper, __UPPER))

    # in the case where the rhs doesn't span zero, we must only multiply by the
    # extremum.
  elseif ispositive(rhs.lower)
    _l = mul(lhs.lower, rhs.upper, __LOWER)
    _u = mul(lhs.upper, rhs.upper, __UPPER)
  else #rhs must be negative
    _l = mul(lhs.upper, rhs.lower, __LOWER)
    _u = mul(lhs.lower, rhs.lower, __UPPER)
  end

  acc.lower = _l
  acc.upper = _u
end

doc"""
  Unum2.std_mul!(lhs::PBound, rhs::PBound)

  performs a standard multiplication on two PBounds which are well-behaved (don't
  cross zero or infinity).  Result is stored in "lhs" variable.
"""
@pfunction function std_mul!(lhs::PBound, rhs::PBound)
  flip_sign = false
  (lhs_lower, lhs_upper) = isnegative(lhs) ? (flip_sign = true; (lhs.upper, lhs.lower)) : (lhs.lower, lhs.upper)
  (rhs_lower, rhs_upper) = isnegative(rhs) ? (flip_sign $= true; (rhs.upper, rhs.lower)) : (rhs.lower, rhs.upper)

  if flip_sign
    lhs.lower = -zero_check_sided_abs_mul(lhs_upper, rhs_upper, __UPPER)
    lhs.upper = -zero_check_sided_abs_mul(lhs_lower, rhs_lower, __LOWER)
  else
    lhs.lower = zero_check_sided_abs_mul(lhs_lower, rhs_lower, __LOWER)
    lhs.upper = zero_check_sided_abs_mul(lhs_upper, rhs_upper, __UPPER)
  end

  (lhs.lower == lhs.upper) && set_single!(lhs)
end

################################################################################
# PTILE MULTIPLICATION
################################################################################

doc"""
  Unum2.mul(x::PTile, y::PTile, ::Type{Val{output}})

  performs a mul on one side or the other, returning the appropriate tile value.
"""
@generated function mul{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  if (output == :lower)
    :( (isnegative(lhs) $ isnegative(rhs)) ? additiveinverse(sided_abs_mul(lhs, rhs, Val{:upper})) : sided_abs_mul(lhs, rhs, Val{:lower}) )
  else
    :( (isnegative(lhs) $ isnegative(rhs)) ? additiveinverse(sided_abs_mul(lhs, rhs, Val{:lower})) : sided_abs_mul(lhs, rhs, Val{:upper}) )
  end
end

doc"""
  Unum2.zero_check_sided_abs_mul(x::PTile, y::PTile, ::Type{Val{output}})

  perform a mul on one side or the other, returning the appropriate tile value.
  the absolute value of the multiply is calculated; it's the responsibility of
  the caller to figure out parity.  This version will correctly multiply zero.
"""
function zero_check_sided_abs_mul{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  is_zero(lhs) && return zero(PTile{lattice, epochbits})
  is_zero(rhs) && return zero(PTile{lattice, epochbits})

  sided_abs_mul(lhs, rhs, OT)
end

doc"""
  Unum2.sided_abs_mul(x::PTile, y::PTile, ::Type{Val{output}})

  perform a mul on one side or the other, returning the appropriate tile value.
  the absolute value of the multiply is calculated; it's the responsibility of
  the caller to figure out parity.  This version will fail for inputs of zero or
  infinity.
"""
function sided_abs_mul{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  #don't do infinity or zero checks. This should be handled outside the sided mul call.
  is_unit(lhs) && return abs(rhs)
  is_unit(rhs) && return abs(lhs)

  if isexact(lhs) & isexact(rhs)
    exact_mul(abs(lhs), abs(rhs), OT)
  else
    inexact_mul(abs(lhs), abs(rhs), OT)
  end
end

doc"""
  Unum2.checked_exact_mul(lhs::PTile, rhs::PTile, ::Type{Val{output}})

  perform an exact multiply on one side or another, but also check for some
  special values.  This is useful when an inexact mul needs to perform an
  exact mul using one of the extrema, but allowing for the direct exact mul
  to not have this overhead.
"""
function checked_exact_mul{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  is_inf(lhs) && return inf(PTile{lattice, epochbits})
  is_inf(rhs) && return inf(PTile{lattice, epochbits})
  is_zero(lhs) && return zero(PTile{lattice, epochbits})
  is_zero(rhs) && return zero(PTile{lattice, epochbits})
  is_one(rhs) && return lhs
  is_one(lhs) && return rhs

  exact_mul(lhs, rhs, OT)
end

doc"""
  Unum2.exact_mul(lhs::PTile, rhs::PTile, ::Type{Val{output}})

  perform an exact multiply, reporting the tile on the far left or far right.
"""
function exact_mul{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  if (isinverted(lhs) $ isinverted(rhs))
    exact_algorithmic_division(lhs, multiplicativeinverse(rhs), OT)
  else
    exact_algorithmic_multiplication(lhs, rhs, OT)
  end
end

@generated function inexact_mul{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  if output == :lower
    :(upperulp(checked_exact_mul(glb(abs(lhs)), glb(abs(rhs)), OT)))
  else #output == :upper
    :(lowerulp(checked_exact_mul(lub(abs(lhs)), lub(abs(rhs)), OT)))
  end
end

################################################################################
# ALGORITHMIC MULTIPLICATION
################################################################################

function exact_algorithmic_multiplication{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}} )
  dc_lhs = decompose(lhs)
  dc_rhs = decompose(rhs)

  (dc_lhs.epoch, dc_lhs.lvalue) = algorithmic_multiplication_decomposed(dc_lhs, dc_rhs, Val{lattice}, OT)

  #reconstitute the result.
  synthesize(PTile{lattice, epochbits}, dc_lhs)
end


@generated function algorithmic_multiplication_decomposed{lattice, output}(lhs::__dc_tile, rhs::__dc_tile, L::Type{Val{lattice}}, OT::Type{Val{output}})
  mul_table = table_name(lattice, :mul)

  #create the multiplication table, if necessary.
  isdefined(Unum2, mul_table) || create_multiplication_table(Val{lattice})
  quote
    res_epoch = lhs.epoch + rhs.epoch

    if lhs.lvalue == zero(UT_Int)
      res_lvalue = rhs.lvalue
    elseif rhs.lvalue == zero(UT_Int)
      res_lvalue = lhs.lvalue
    else
      #do a lookup.
      res_lvalue = $mul_table[lhs.lvalue >> 1, rhs.lvalue >> 1]
      #check to see if we need to go to a higher epoch.
      (res_lvalue < lhs.lvalue) && (res_epoch += 1)
    end

    (res_epoch, res_lvalue)
  end
end

################################################################################
# MULTIPLICATION TABLES
################################################################################

#I didn't want this to be a generated function, but it was the cleanest way to
#generate and use the new sybol.
@generated function create_multiplication_table{lattice}(::Type{Val{lattice}})
  mult_table = Symbol("__$(lattice)_mul_table")
  quote
    #store the lattice values and the stride values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_STRIDE_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $mult_table = Matrix{UInt64}(l, l)

    for idx = 1:l
      for idx2 = 1:l
        true_value = lattice_values[idx] * lattice_values[idx2]
        #first check to see if the true_value corresponds to the stride value.
        (true_value >= pivot_value) && (true_value /= pivot_value)

        $mult_table[idx, idx2] = @i search_lattice(lattice_values, true_value)
      end
    end
  end
end
