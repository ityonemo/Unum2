#comparison

#unfortunately all of these things need to be overloaded, because of the special
#nature of infinity.

import Base: <, >, <=, >=, ==

@pfunction function <(x::PTile, y::PTile)
  is_inf(y) | is_inf(x) | ((@s x) < (@s y))
end

@pfunction function >(x::PTile, y::PTile)
  is_inf(y) | is_inf(x) | ((@s y) < (@s x))
end

@pfunction function <=(x::PTile, y::PTile)
  is_inf(y) | is_inf(x) | ((@s x) <= (@s y))
end

@pfunction function >=(x::PTile, y::PTile)
  is_inf(y) | is_inf(x) | ((@s y) >= (@s x))
end

@pfunction function Base.max(x::PTile, y::PTile)
  is_inf(y) && return y
  (x > y) ? x : y
end

@pfunction function Base.min(x::PTile, y::PTile)
  is_inf(y) && return y
  (x < y) ? x : y
end

@pfunction function ==(x::PBound, y::PBound)
  if isempty(x)
    isempty(y)
  elseif issingle(x)
    issingle(y) && (x.lower == y.lower)
  elseif isdouble(x)
    isdouble(y) && (x.lower == y.lower) && (x.upper == y.upper)
  elseif ispreals(x)
    ispreals(y)
  else
    false
  end
end

@pfunction function Base.abs(x::PTile)
  isnegative(x) ? additiveinverse(x) : x
end
