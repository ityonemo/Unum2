#testtools.jl

#a dummy lookslike type for an infix lookslike operator
type lookslike; end

function Base.colon(a::PTile, b::Type{lookslike}, c::UInt64)
  reinterpret(UInt64, a) == c
end
