using Unum2
using Base.Test

#=
include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")
include("5bitepochtest.jl")
=#
#=
a = collect(2:9)
a = elaborate(a, 10, 6)

println(a)
=#

a = collect(2:9)
#=
b = unique(sort(vcat(a, 10//1 ./ a)))

x = Unum2.test_multitile_fma_old(b, 10//7, 5//1, 10//3, 10)
println(x)
println("----")
y = Unum2.test_multitile_fma_new(b, 10//7, 5//1, 10//3, 10)
println(y)
=#

b = elaborate_mul(a, 10, 6)

println(b)

#=
a = collect(11//10:1//10:99//10)
b = elaborate(a, 10, 10)

println(b)
=#
#=
a = collect(2:9)

a = elaborate(a, 10, 7)

println(a)
=#
