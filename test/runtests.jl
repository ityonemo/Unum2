using Unum2
using Base.Test

include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")
include("5bitepochtest.jl")
include("cgentest.jl")

#=
a = collect(2:9)

b = elaborate_mul(a, 10, 6)

println(b)
=#
