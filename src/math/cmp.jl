#comparison

#unfortunately all of these things need to be overloaded, because of the special
#nature of infinity.

import Base: <, >, <=, >=, ==

@pfunction function <(x::PTile, y::PTile)
  is_inf(y) | is_inf(x) | (@s x) < (@s y)
end

@pfunction function >(x::PTile, y::PTile)
  is_inf(y) | is_inf(x) | (@s y) < (@s x)
end

@pfunction function <=(x::PTile, y::PTile)
  is_inf(y) | is_inf(x) | (@s x) <= (@s y)
end

@pfunction function >=(x::PTile, y::PTile)
  is_inf(y) | is_inf(x) | (@s y) >= (@s x)
end

@pfunction function Base.max(x::PTile, y::PTile)
  (x > y) ? x : y
end

@pfunction function Base.min(x::PTile, y::PTile)
  (x < y) ? x : y
end

@pfunction function ==(x::PBound, y::PBound)
  if x.state == PTile_NULLSET
    y.state == PTile_NULLSET
  elseif x.state == PTile_SINGLETON
    (x.lower == y.lower)
  elseif x.state == PTile_STDBOUND
    (x.lower == y.lower) && (x.upper == y.upper)
  elseif x.state == PTile_ALLPREALS
    y.state == PTile_ALLPREALS
  else
    false
  end
end
