#testtools.jl

#a dummy lookslike type for an infix lookslike operator
type lookslike; end

function Base.colon(a::PTile, b::Type{lookslike}, c::Unum2.UT_Int)
  reinterpret(Unum2.UT_Int, a) == c
end
