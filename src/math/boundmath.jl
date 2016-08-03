#boundmath.jl - math on pbounds.

+{lattice, epochbits}(x::PBound{lattice, epochbits}, y::PBound{lattice, epochbits}) = add(x,y)
@pfunction function add(x::PBound, y::PBound)
  (isempty(x) || isempty(y)) && return emptyset(B)
  (ispreals(x) || ispreals(y)) && return allprojectivereals(B)

  x_upper_proxy = issingle(x) ? x.lower : x.upper
  y_upper_proxy = issingle(y) ? y.lower : y.upper

  B(add(x.lower, y.lower, __LOWER), add(x_upper_proxy, y_upper_proxy, __UPPER))
end

-{lattice, epochbits}(x::PBound{lattice, epochbits}) = issingle(x) ? B(-x.lower, x.upper, x.state) : B(-x.upper, -x.lower, x.state)
-{lattice, epochbits}(x::PBound{lattice, epochbits}, y::PBound{lattice, epochbits}) = sub(x,y)
@pfunction sub(x::PBound, y::PBound) = add(x, -y)

*{lattice, epochbits}(x::PBound{lattice, epochbits}, y::PBound{lattice, epochbits}) = mul(x,y)
@pfunction function mul(x::PBound, y::PBound)
  (isempty(x) || isempty(y)) && return emptyset(B)
  (ispreals(x) || ispreals(y)) && return allprojectivereals(B)

  #to make calculations simple, ensure that the upper is equal to the lower.
  issingle(x) && return single_mul(x, y)
  issingle(y) && return single_mul(y, x)

  rounds_inf(x) && return inf_mul(x, y)
  rounds_inf(y) && return inf_mul(y, x)

  rounds_zero(x) && return zero_mul(x, y)
  rounds_zero(y) && return zero_mul(y, x)

  #now we know the resulting value must be standard intervals across either positive
  #or negative parts of the number line.
  flip_sign = false
  x_val = isnegative(x) ? (flip_sign = true; -x) : x
  y_val = isnegative(y) ? (flip_sign $= true; -y) : y

  flip_sign && return B(-mul(x.upper, y.upper, __UPPER), -mul(x.lower, y.lower, __LOWER))
  return B(mul(x.lower, y.lower, __LOWER), mul(x.upper, y.upper, __UPPER))
end

#do a multiplication where we know x is a singleton bound.
@pfunction function single_mul(x::PBound, y::PBound)
  #first check if y is single.
  if issingle(y)
    mul(x, y, __BOUND)
  else
    B(mul(x.lower, y.lower, __LOWER), mul(x.lower, y.upper, __UPPER))
  end
end

__negative_sided(x::PBound) = (!ispositive(x.lower))

#x definitely rounds infinity, y may or may not round infinity.  Either may
#or may not round zero.
@pfunction function inf_mul(x::PBound, y::PBound)
  if rounds_zero(y)
    allprojectivereals(B)
  elseif rounds_zero(x)
    rounds_inf(y) && return allprojectivereals(B)

    #at this juncture, the value x must round both zero and infinity, and
    #the value y must be a standard, nonflipped double interval that is only on
    #one side of zero.

    # (100, 1) * (3, 4)     -> (300, 4)    (l * l, u * u)
    # (100, 1) * (-4, -3)   -> (-4, -300)  (u * l, l * u)
    # (-1, -100) * (3, 4)   -> (-4, -300)  (l * u, u * l)
    # (-1, -100) * (-4, -3) -> (300, 4)    (u * u, l * l)

    _state = _negative_sided(x) * 1 + isnegative(y) * 2

    if (state == 0)
      B(mul(x.lower, y.lower, __LOWER), mul(x.upper, y.upper, __UPPER))
    elseif (state == 1)
      B(mul(x.upper, y.lower, __LOWER), mul(x.lower, y.upper, __UPPER))
    elseif (state == 2)
      B(mul(x.upper, y.lower, __LOWER), mul(x.lower, y.upper, __UPPER))
    else   #state == 3
      B(mul(x.upper, y.upper, __LOWER), mul(x.lower, y.lower, __UPPER))
    end
  elseif rounds_inf(y)  #now we must check if y rounds infinity.
    #like the double "rounds zero" case, we have to check four possible endpoints.
    #unlinke the "rounds zero" case, the lower ones are positive valued, so that's not "crossed"
    _l = min(mul(x.lower, y.lower, __LOWER), mul(x.upper, y.upper, __LOWER))
    _u = max(mul(x.lower, y.upper, __LOWER), mul(x.upper, y.lower, __LOWER))

    #construct the result.
    B(_l, _u)
  else  #the last case is if x rounds infinity but y is a "well-behaved" value.

    #canonical example:
    # (2, -3) * (5, 7) -> (10, -15)
    # (2, -3) * (-7, -5) -> (15, -10)

    if isnegative(y)
      B(mul(x.upper, y.upper, __LOWER), mul(x.lower, y.upper, __UPPER))
    else
      B(mul(x.lower, y.lower, __LOWER), mul(x.upper, y.lower, __UPPER))
    end
  end
end

#x definitely rounds zero, y may or may not round zero.  None of the results
#go around infinity.
@pfunction function zero_mul(x::PBound, y::Pbound)
  #NB:  We need to check for strange situations with infinity here.

  if rounds_zero(y)

  # when rhs spans zero, we have to check four possible endpoints.
    _l = min(mul(x.lower, y.upper, __LOWER), mul(x.upper, y.lower, __LOWER))
    _u = max(mul(x.lower, y.lower, __UPPER), mul(x.upper, y.upper, __UPPER))

    #construct the result.
    B(_l, _u)

  # in the case where the rhs doesn't span zero, we must only multiply by the
  # extremum.
  elseif is_positive(y)
    B(mul(x.lower, y.upper, __LOWER), mul(x.upper, y.upper, __UPPER))
  else #y must be negative
    B(mul(x.upper, y.lower, __LOWER), mul(x.lower, y.lower, __UPPER))
  end
end

/{lattice, epochbits}(x::PBound{lattice, epochbits}) = issingle(x) ? B(-x.lower, x.upper, x.state) : B(/(x.upper), /(x.lower), x.state)
/{lattice, epochbits}(x::PBound{lattice, epochbits}, y::PBound{lattice, epochbits}) = div(x,y)
@pfunction div(x::PBound, y::PBound) = mul(x, /(y))
