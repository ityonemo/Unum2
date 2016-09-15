using Unum2
using Base.Test

include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")
include("5bitepochtest.jl")



#w = [fma(▾(x), ▾(y), ▾(z)) for x in exacts(PTileD1), y in exacts(PTileD1), z in exacts(PTileD1)]

#println(w)

#=
import_lattice(:PFloat5)

# 14, 12: PTile5e(0b01110) - PTile5e(0b01100) failed as ▾(PTile5e(0b10100)); should be ▾(PTile5e(0b01100))

x = ▾(PTile5(0b01110))
y = ▾(PTile5(0b01100))

println(x)
println(y)

println(x - y)
=#
