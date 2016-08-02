#boundmath.jl - math on pbounds.

+{lattice, epochbits}(x::PBound{lattice, epochbits}, y::PBound{lattice, epochbits}) = add(x,y)
@pfunction function add(x::PBound, y::PBound)
  (isempty(x) || isempty(y)) && return emptyset(B)
  (ispreals(x) || ispreals(y)) && return allprojectivereals(B)

  x_upper_proxy = issingle(x) ? x.lower : x.upper
  y_upper_proxy = issingle(y) ? y.lower : y.upper

  B(add(x.lower, y.lower, :lower), add(x_upper_proxy, y_upper_proxy, :upper))
end

-{lattice, epochbits}(x::PBound{lattice, epochbits}) = issingle(x) ? B(-x.lower, x.upper, x.flags) : B(-x.upper, -x.lower, x.flags)
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

  flip_sign && return B(-mul(x.upper, y.upper, :upper), -mul(x.lower, y.lower, :lower))
  return B(mul(x.lower, y.lower, :lower), mul(x.upper, y.upper, :upper))
end

#do a multiplication where we know x is a singleton bound.
@pfunction function single_mul(x::PBound, y::PBound)
  #first check if y is single.
  if issingle(y)
    mul(x, y, :bound)
  else
    B(mul(x.lower, y.lower, :lower), mul(x.lower, y.upper, :upper))
  end
end

#x definitely rounds infinity, y may or may not round infinity.  Either may
#or may not round zero.
@pfunction function inf_mul(x::PBound, y::PBound)
  if rounds_zero(y)
    allprojectivereals(B)
  elseif rounds_zero(x)
    rounds_inf(y) && return allprojectivereals(B)
    #more interesting shit.

  else

  end
end

#x definitely rounds zero, y may or may not round zero.  None of the results
#go around infinity.
@pfunction function zero_mul(x::PBound, y::Pbound)
  #NB:  We need to check for strange situations with infinity here.

  if rounds_zero(y)
  #############
  # when rhs spans zero, we have to check four possible endpoints.
    _l = min(mul(x.lower, y.upper, :lower), mul(x.upper, y.lower, :lower))
    _u = max(mul(x.lower, y.lower, :upper), mul(x.upper, y.upper, :upper))

    #construct the result.
    B(_l, _u)

  #############
  # in the case where the rhs doesn't span zero, we must only multiply by the
  # extremum.
  elseif is_positive(y)
    B(mul(x.lower, y.upper, :lower), mul(x.upper, y.upper, :upper))
  else #y must be negative
    B(mul(x.upper, y.lower, :lower), mul(x.lower, y.lower, :upper))
  end
end

/{lattice, epochbits}(x::PBound{lattice, epochbits}) = issingle(x) ? B(-x.lower, x.upper, x.flags) : B(/(x.upper), /(x.lower), x.flags)
/{lattice, epochbits}(x::PBound{lattice, epochbits}, y::PBound{lattice, epochbits}) = div(x,y)
@pfunction div(x::PBound, y::PBound) = mul(x, /(y))
