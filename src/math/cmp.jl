#comparison

#unfortunately all of these things need to be overloaded, because of the special
#nature of infinity.

import Base: <, >, <=, >=

@pfunction function <(x::PFloat, y::PFloat)
  is_inf(y) | is_inf(x) | (@s x) < (@s y)
end

@pfunction function >(x::PFloat, y::PFloat)
  is_inf(y) | is_inf(x) | (@s y) < (@s x)
end

@pfunction function <=(x::PFloat, y::PFloat)
  is_inf(y) | is_inf(x) | (@s x) <= (@s y)
end

@pfunction function >=(x::PFloat, y::PFloat)
  is_inf(y) | is_inf(x) | (@s y) >= (@s x)
end

@pfunction function Base.max(x::PFloat, y::PFloat)
  (x > y) ? x : y
end

@pfunction function Base.min(x::PFloat, y::PFloat)
  (x < y) ? x : y
end
