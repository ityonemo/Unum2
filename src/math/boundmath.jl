
*{lattice, epochbits}(lhs::PBound{lattice, epochbits}, rhs::PBound{lattice, epochbits}) = mul(lhs,rhs)
@pfunction function mul(lhs::PBound, rhs::PBound)

end

#do a multiplication where we know lhs is a singleton bound.
@pfunction function single_mul(lhs::PBound, rhs::PBound)
  #do a few critical single checks.
  #first check if rhs is SINGLETON.
  if issingle(rhs)
    mul(lhs.lower, rhs.lower, __BOUND)
  else
    if (is_zero(lhs.lower) && roundsinf(rhs)) || (is_inf(lhs.lower) && roundszero(rhs))
      return allprojectivereals(B)
    end
    B(mul(lhs.lower, rhs.lower, __LOWER), mul(lhs.lower, rhs.upper, __UPPER))
  end
end

__negative_sided(lhs::PBound) = (!ispositive(lhs.lower))

#lhs definitely rounds infinity, rhs may or may not round infinity.  Either may
#or may not round zero.
@pfunction function inf_mul(lhs::PBound, rhs::PBound)
  if roundszero(rhs) || is_zero(rhs.lower) || is_zero(rhs.upper)
    allprojectivereals(B)
  elseif roundszero(lhs)
    roundsinf(rhs) && return allprojectivereals(B)

    #at this juncture, the value lhs must round both zero and infinity, and
    #the value rhs must be a standard, nonflipped double interval that is only on
    #one side of zero.

    # (100, 1) * (3, 4)     -> (300, 4)    (l * l, u * u)
    # (100, 1) * (-4, -3)   -> (-4, -300)  (u * l, l * u)
    # (-1, -100) * (3, 4)   -> (-4, -300)  (l * u, u * l)
    # (-1, -100) * (-4, -3) -> (300, 4)    (u * u, l * l)

    _state = __negative_sided(lhs) * 1 + isnegative(rhs) * 2

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

    (@s _l) <= (@s _u) && return allprojectivereals(B)
    (next(_u) == _l) && return allprojectivereals(B)

    B(_l, _u)
  elseif roundsinf(rhs)  #now we must check if rhs rounds infinity.
    #like the double "rounds zero" case, we have to check four possible endpoints.
    #unlinke the "rounds zero" case, the lower ones are positive valued, so that's not "crossed"
    _l = min(mul(lhs.lower, rhs.lower, __LOWER), mul(lhs.upper, rhs.upper, __LOWER))
    _u = max(mul(lhs.lower, rhs.upper, __LOWER), mul(lhs.upper, rhs.lower, __LOWER))

    #construct the result.
    B(_l, _u)
  else  #the last case is if lhs rounds infinity but rhs is a "well-behaved" value.

    #canonical example:
    # (2, -3) * (5, 7) -> (10, -15)
    # (2, -3) * (-7, -5) -> (15, -10)

    if isnegative(rhs)
      B(mul(lhs.upper, rhs.upper, __LOWER), mul(lhs.lower, rhs.upper, __UPPER))
    else
      B(mul(lhs.lower, rhs.lower, __LOWER), mul(lhs.upper, rhs.lower, __UPPER))
    end
  end
end

#lhs definitely rounds zero, rhs may or may not round zero.  None of the results
#go around infinity.
@pfunction function zero_mul(lhs::PBound, rhs::PBound)
  #NB:  We need to check for strange situations with infinity here.

  if roundszero(rhs)

    # when rhs spans zero, we have to check four possible endpoints.
    _l = min(mul(lhs.lower, rhs.upper, __LOWER), mul(lhs.upper, rhs.lower, __LOWER))
    _u = max(mul(lhs.lower, rhs.lower, __UPPER), mul(lhs.upper, rhs.upper, __UPPER))

    #construct the result.
    B(_l, _u)

    # in the case where the rhs doesn't span zero, we must only multiply by the
    # extremum.
  elseif ispositive(rhs)
    B(mul(lhs.lower, rhs.upper, __LOWER), mul(lhs.upper, rhs.upper, __UPPER))
  else #rhs must be negative
    B(mul(lhs.upper, rhs.lower, __LOWER), mul(lhs.lower, rhs.lower, __UPPER))
  end
end

/{lattice, epochbits}(lhs::PBound{lattice, epochbits}) = issingle(lhs) ? PBound(/(lhs.lower), lhs.upper, lhs.state) : PBound(/(lhs.upper), /(lhs.lower), lhs.state)
/{lattice, epochbits}(lhs::PBound{lattice, epochbits}, rhs::PBound{lattice, epochbits}) = div(lhs,rhs)
@pfunction div(lhs::PBound, rhs::PBound) = mul(lhs, /(rhs))
