#comparison

@pfunction Base.<(x::PFloat, y::PFloat) = isinfinite(y) | isinfinite(x) | (@s x) < (@s y)
