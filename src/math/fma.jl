#fma.jl - implementation of the fused-multiply add.

@pfunction function Base.fma(a::PBound,b::PBound,c::PBound)
  res = emptyset(B)
  fma!(res, a, b, c)
  res
end

function Base.fma{lattice, epochbits, output}(a::PTile{lattice, epochbits},b::PTile{lattice, epochbits},c::PTile{lattice, epochbits}, OT::Type{Val{output}})
  (is_inf(a)) && return inf(PTile{lattice, epochbits})
  (is_inf(b)) && return inf(PTile{lattice, epochbits})
  (is_inf(c)) && return inf(PTile{lattice, epochbits})
  (is_zero(a)) && return c
  (is_zero(b)) && return c
  (is_zero(c)) && return mul(a, b, OT)
  (is_one(a)) && return add(b, c, OT)
  (is_one(b)) && return add(a, c, OT)
  (is_neg_one(a)) && return add(c, -b, OT)
  (is_neg_one(b)) && return add(c, -a, OT)

  if isexact(a) && isexact(b) && isexact(c)
    exact_fma(a, b, c, OT)
  else
    inexact_fma(a, b, c, OT)
  end
end

function checked_exact_fma{lattice, epochbits, output}(a::PTile{lattice, epochbits},b::PTile{lattice, epochbits},c::PTile{lattice, epochbits}, OT::Type{Val{output}})
  (is_inf(a)) && return inf(PTile{lattice, epochbits})
  (is_inf(b)) && return inf(PTile{lattice, epochbits})
  (is_inf(c)) && return inf(PTile{lattice, epochbits})
  (is_zero(a)) && return c
  (is_zero(b)) && return c
  (is_zero(c)) && return exact_mul(a, b)
  (is_one(a)) && return checked_exact_add(b, c)
  (is_one(b)) && return checked_exact_add(a, c)
  (is_neg_one(a)) && return checked_exact_add(c, -b)
  (is_neg_one(b)) && return checked_exact_add(c, -a)

  exact_fma(a, b, c, OT)
end

@generated function lvup!{lattice}(a::__dc_tile, OT::Type{Val{lattice}})
  max_lvalue = (length(__MASTER_LATTICE_LIST[lattice]) << 1) + 1
  quote
    if a.lvalue == $max_lvalue
      a.lvalue = 0
      a.epoch += 1
    else
      a.lvalue += 1
    end
  end
end

@generated function lvdn!{lattice}(a::__dc_tile, OT::Type{Val{lattice}})
  max_lvalue = (length(__MASTER_LATTICE_LIST[lattice]) << 1) + 1
  quote
    if a.lvalue == 0
      if a.epoch == 0
        a.lvalue = 1
        flip_inverted!(a)
      else
        a.lvalue = $max_lvalue
        a.epoch -= 1
      end
    else
      a.lvalue -= 1
    end
  end
end

function glb!{lattice}(a::__dc_tile, OT::Type{Val{lattice}})
  if isodd(a.lvalue)
    if (a.flags == 1) || (a.flags == 2)
      lvup!(a, OT)
    else
      a.lvalue -= 1
    end
  end
end

function lub!{lattice}(a::__dc_tile, OT::Type{Val{lattice}})
  if isodd(a.lvalue)
    if (a.flags == 1) || (a.flags == 2)
      a.lvalue -= 1
    else
      lvup!(a, OT)
    end
  end
end

function upper_ulp!{lattice}(a::__dc_tile, OT::Type{Val{lattice}})
  if iseven(a.lvalue)
    if (a.flags == 1) || (a.flags == 2)
      lvdn!(a, OT)
    else
      a.lvalue += 1
    end
  end
end

function lower_ulp!{lattice}(a::__dc_tile, OT::Type{Val{lattice}})
  if iseven(a.lvalue)
    if (a.flags == 1) || (a.flags == 2)
      a.lvalue += 1
    else
      lvdn!(a, OT)
    end
  end
end

function exact_fma{lattice, epochbits, output}(a::PTile{lattice, epochbits},b::PTile{lattice, epochbits},c::PTile{lattice, epochbits}, OT::Type{Val{output}})
  #a few easy cases.

  dc_a = decompose(a)
  dc_b = decompose(b)
  dc_c = decompose(c)

  (is_negative(dc_a) $ is_negative(dc_b)) ? set_negative!(dc_a) : set_positive!(dc_a)

  #perform the algorithmic multiplication
  if (is_inverted(dc_a) $ is_inverted(dc_b))
    flip_inverted!(dc_b)
    (invert, dc_a.epoch, dc_a.lvalue) = algorithmic_division_decomposed(dc_a, dc_b, Val{lattice})
    invert && flip_inverted!(dc_a)
  else
    (dc_a.epoch, dc_a.lvalue) = algorithmic_multiplication_decomposed(dc_a, dc_b, Val{lattice})
  end
  #check to see if they're inverses of each other.

  if iseven(dc_a.lvalue)
    #next, do the algorithmic addition/subtraction
    additiveinverses(dc_a, dc_c) && return zero(PTile{lattice, epochbits})
    dc_a = exact_add(dc_a, dc_c, Val{lattice})
  elseif output == :lower
    glb!(dc_a, Val{lattice})
    additiveinverses(dc_a, dc_c) && return pos_few(PTile{lattice, epochbits})
    dc_a = exact_add(dc_a, dc_c, Val{lattice})
    upper_ulp!(dc_a, Val{lattice})
  else #output == :upper
    lub!(dc_a, Val{lattice})
    additiveinverses(dc_a, dc_c) && return neg_few(PTile{lattice, epochbits})
    dc_a = exact_add(dc_a, dc_c, Val{lattice})
    lower_ulp!(dc_a, Val{lattice})
  end

  synthesize(PTile{lattice, epochbits}, dc_a)
end

@generated function inexact_fma{lattice, epochbits, output}(a::PTile{lattice, epochbits},b::PTile{lattice, epochbits},c::PTile{lattice, epochbits}, OT::Type{Val{output}})
  #for positive values of multiply (for now.)
  if output == :lower
    quote
      #decide if the multiplication result will be positive or negative.
      mul_res_sign = isnegative(a) $ isnegative(b)
      #if the result is negative, the lower value will be the outer values for both
      #if the result is positive, the lower value will result from the inner values for both.
      a_bound = (mul_res_sign $ isnegative(a)) ? lub(a) : glb(a)
      b_bound = (mul_res_sign $ isnegative(b)) ? lub(b) : glb(b)

      upperulp(check_exact_fma(a_bound, b_bound, glb(c), OT))
    end
  else #output == :upper
    quote
      #decide if the multiplication result will be positive or negative.
      mul_res_sign = isnegative(a) $ isnegative(b)
      #if the result is negative, the upper value will result from the inner values for both
      #if the result is positive, the upper value will result from the outer values for both.
      a_bound = (mul_res_sign $ isnegative(a)) ? glb(a) : lub(a)
      b_bound = (mul_res_sign $ isnegative(b)) ? glb(b) : lub(b)

      lowerulp(checked_exact_fma(a_bound, b_bound, lub(c), OT))
    end
  end
end

@pfunction function fma!(res::PBound, a::PBound, b::PBound, c::PBound)
  #terminate early on special values.
  (isempty(a) || isempty(b) || isempty(c)) && (set_empty!(res); return)
  (ispreals(a) || ispreals(b) || ispreals(c)) && (set_preals!(res); return)
  #check on special cases for multiplication:

  # if c contains inf, it may result in "erasure" of wraparound property from
  # a multiplied a/b result.
  if containsinf(c) && (containsinf(a) || containsinf(b))
    #do a multiplication test.
    mul!(res, a, b)
    ispreals(res) && return
  end

  if issingle(a)
    single_fma!(res, a, b, c)
  elseif issingle(b)
    single_fma!(res, b, a, c)
  elseif containsinf(a)
    inf_fma!(res, a, b, c)
  elseif containsinf(b)
    inf_fma!(res, b, a, c)
  elseif __simple_roundszero(a)
    zero_fma!(res, a, b, c)
  elseif __simple_roundszero(b)
    zero_fma!(res, b, a, c)
  else
    std_fma!(res, b, a, c)
  end
end

@pfunction function single_fma!(res::PBound, a::PBound, b::PBound, c::PBound)
  set_double!(res)

  if issingle(b) #b is a single tile.

    #some special cases:  a or b is zero.
    if is_zero(a.lower)
      is_inf(b.lower) && (set_preals!(res); return)
      copy!(res, c)
      return
    end

    if is_zero(b.lower)
      is_inf(a.lower) && (set_preals!(res); return)
      copy!(res, c)
      return
    end

    is_inf(a.lower) && (res.lower = inf(T); set_single!(res); return)
    is_inf(b.lower) && (res.lower = inf(T); set_single!(res); return)

    set_double!(res)

    c_upper_proxy = issingle(a) ? c.lower : c.upper
    res.lower = fma(a.lower, b.lower, c.lower, __LOWER)
    res.upper = fma(a.lower, b.lower, c_upper_proxy, __UPPER)

    #although we know that the product of two tiles must be on the same half
    #of the real number line, we must consider if the added part might wind
    #up as all real numbers, which can happen if the starting bit contains inf.
    #note that containsinf is a property which is invariant under addition.
    if (containsinf(c))
      (@s (prev(res.lower))) <= (@s res.upper) && (set_preals!(res); return)
    end
  else  #b is a multi-tile interval.
    #check if we have a zero/inf situation
    if (is_zero(a.lower) && containsinf(b)) || (is_inf(a.lower) && containszero(b))
      set_preals!(res)
      return
    end

    #do a simple multiplication.  This could result in going round the horn.
    set_double!(res)

    c_upper_proxy = issingle(c) ? c.lower : c.upper
    res.lower = fma(a.lower, b.lower, c.lower, __LOWER)
    res.upper = fma(a.lower, b.lower, c_upper_proxy, __UPPER)

    #although we know that the product of two tiles must be on the same half
    #of the real number line, we must consider if the added part might wind
    #up as all real numbers, which can happen if the starting bit contains inf.
    #note that containsinf is a property which is invariant under tile
    #multiplication and addition.
    if (containsinf(b) || containsinf(c))
      (@s (prev(res.lower))) <= (@s res.upper) && (set_preals!(res); return)
    end
  end

  (res.lower == res.upper) ? set_single!(res) : set_double!(res)
end


doc"""
  Unum2.inf_fma!(res::PBound, a::PBound, b::PBound, c::PBound)

  performs a fused multiply-add on two PBounds, placing the result into the res
  value.  a is guaranteed to be a "double" element that "containsinf", which
  according to our definition, either has infnity as the upper or lower element,
  or has its upper element less than its lower element (going 'round the horn'
  on the projective reals).
"""
@pfunction function inf_fma!(res::PBound, a::PBound, b::PBound, c::PBound)
  set_double!(res)

  if containszero(b)
    #check to see if the rhs contains zero in any way, which will instantly
    #trigger the result to be all projective reals.
    set_preals!(res)
  elseif containszero(a)
    #it's possible for the value to round both infinity AND zero.

    #check if we have an infinite-valued rhs, which triggers preals.
    containsinf(b) && (set_preals!(res); return)

    #at this juncture, the value a must round both zero and infinity, and
    #the value rhs must be a standard, nonflipped double interval that is only on
    #one side of zero.

    _state = isnegative(a) * 1 + isnegative(b) * 2

    c_upper_proxy = issingle(c) ? c.lower : c.upper

    #assign upper and lower values based on the bounds
    if (_state == 0)
      res.lower = fma(a.lower, b.lower, c.lower, __LOWER)
      res.upper = fma(a.upper, b.upper, c_upper_proxy, __UPPER)
    elseif (_state == 1)
      res.lower = fma(a.upper, b.lower, c.lower, __LOWER)
      res.upper = fma(a.lower, b.upper, c_upper_proxy, __UPPER)
    elseif (_state == 2)
      res.lower = fma(a.upper, b.lower, c.lower, __LOWER)
      res.upper = fma(a.lower, b.upper, c_upper_proxy, __UPPER)
    else   #state == 3
      res.lower = fma(a.upper, b.upper, c.lower, __LOWER)
      res.upper = fma(a.lower, b.lower, c_upper_proxy, __UPPER)
    end

    #check two cases: if the result has "flipped around" and now need to be
    #represented by all reals.
    (@s prev(res.lower)) <= (@s res.upper) && (set_preals!(res); return)
  elseif containsinf(b)  #now we must check if rhs rounds infinity.
    #like the double "rounds zero" case, we have to check four possible endpoints.
    zero_check = containszero(b) || containsinf(c)

    c_upper_proxy = issingle(c) ? c.lower : c.upper
    _l1 = is_inf(a.lower) | is_inf(b.lower) ? inf(T) : fma(a.lower, b.lower, c.lower, __LOWER)
    _l2 = is_inf(a.upper) | is_inf(b.upper) ? inf(T) : fma(a.upper, b.upper, c.lower, __LOWER)
    _u1 = is_inf(a.lower) | is_inf(b.upper) ? inf(T) : fma(a.lower, b.upper, c_upper_proxy, __UPPER)
    _u2 = is_inf(a.upper) | is_inf(b.lower) ? inf(T) : fma(a.upper, b.lower, c_upper_proxy, __UPPER)

    #construct the result.
    res.lower = min(_l1, _l2)
    res.upper = max(_l1, _l2)

    #check for wraparound to allreals.
    if (zero_check)
      (@s prev(res.lower)) <= (@s res.upper) && (set_preals!(res); return)
    end
  else
    #the last case is if a rounds infinity but b is a "well-behaved" value.
    #canonical example:

    c_upper_proxy = issingle(c) ? c.lower : c.upper

    if isnegative(b)
      res.lower = is_inf(a.upper) ? inf(T) : fma(a.upper, b.upper, c.lower, __LOWER)
      res.upper = is_inf(a.lower) ? inf(T) : fma(a.lower, b.upper, c_upper_proxy, __UPPER)
    else
      res.lower = is_inf(a.lower) ? inf(T) : fma(a.lower, b.lower, c.lower, __LOWER)
      res.upper = is_inf(a.upper) ? inf(T) : fma(a.upper, b.lower, c_upper_proxy, __UPPER)
    end
  end

  (res.lower == res.upper) && set_single!(res)
end

@pfunction function zero_fma!(res::PBound, a::PBound, b::PBound, c::PBound)
  set_double!(res)
  c_upper_proxy = issingle(c) ? c.lower : c.upper

  if __simple_roundszero(b)
    # when rhs spans zero, we have to check four possible endpoints.
    res.lower = min(fma(a.lower, b.upper, c.lower, __LOWER), fma(a.upper, b.lower, c.lower, __LOWER))
    res.upper = max(fma(a.lower, b.lower, c_upper_proxy, __UPPER), fma(a.upper, b.upper, c_upper_proxy, __UPPER))

    # in the case where the rhs doesn't span zero, we must only multiply by the
    # extremum.
  elseif ispositive(rhs.lower)
    res.lower = fma(a.lower, b.upper, c.lower, __LOWER)
    res.upper = fma(a.upper, b.upper, c_upper_proxy, __UPPER)
  else #rhs must be negative
    res.lower = fma(a.upper, b.lower, c.lower, __LOWER)
    res.upper = fma(a.lower, b.lower, c_upper_proxy, __UPPER)
  end

  (res.lower == res.upper) && set_single!(res)
end

@pfunction function std_fma!(res::PBound, a::PBound, b::PBound, c::PBound)
  set_double!(res) 
  #decide if the multiplication result will be positive or negative.
  mul_res_sign = isnegative(a.lower) $ isnegative(b.lower)
  #if the result is negative, the lower value will be the outer values for both
  #if the result is positive, the lower value will result from the inner values for both.
  (a_lower_component, a_upper_component) = mul_res_sign $ isnegative(a) ? (a.upper, a.lower) : (a.lower, a.upper)
  (b_lower_component, b_upper_component) = mul_res_sign $ isnegative(b) ? (b.upper, b.lower) : (b.lower, b.upper)

  c_upper_proxy = issingle(c) ? c.lower : c.upper

  res.lower = fma(a_lower_component, b_lower_component, c.lower)
  res.upper = fma(a_upper_component, b_upper_component, c_upper_proxy)

  (res.lower == res.upper) && set_single!(res)
end
