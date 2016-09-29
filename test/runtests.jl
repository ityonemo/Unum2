using Unum2
using Base.Test

#=
include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")
include("5bitepochtest.jl")
=#


a = collect(11//10:1//10:99//10)
b = elaborate(a, 10, 10)

println(b)

#=
a = collect(2:9)

a = elaborate(a, 10, 7)

println(a)
=#
