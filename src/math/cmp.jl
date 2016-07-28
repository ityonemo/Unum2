#comparison

import Base: <, >

@pfunction function <(x::PFloat, y::PFloat)
  is_inf(y) | is_inf(x) | (@s x) < (@s y)
end

@pfunction function >(x::PFloat, y::PFloat)
  y < x
end
