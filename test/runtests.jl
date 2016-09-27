using Unum2
using Base.Test

include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")
include("5bitepochtest.jl")

import_lattice(:PFloatD1)

#fma(PTileD1(0b0111100), PTileD1(0b0101010), PTileD1(0b1001000)) not single: PTileD1(0b0111001) → PTileD1(0b0111101)
#=
x = PTileD1(0b0111100)
y = PTileD1(0b0101010)
z = PTileD1(0b1001000)

println(▾(x) * ▾(y) + ▾(z))
println(fma(▾(x), ▾(y), ▾(z)))
println((▾(x) + ▾(z) / ▾(y)) * ▾(y))
println((▾(y) + ▾(z) / ▾(x)) * ▾(x))
=#

#PTileD1(0b1000100), PTileD1(0b1111110), PTileD1(0b1100010)
#=
x = ▾(PTileD1(0b1000100))
y = ▾(PTileD1(0b1111110))
z = ▾(PTileD1(0b1100010))

println(x)
println(y)
println(z)

println(fma(x, y, z))
println("should be 0b01100")
=#
