using Unum2
using Base.Test


include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")
include("5bitepochtest.jl")

#=
import_lattice(:PFloat5e)

#2, 6: PTile5e(0b00010) + PTile5e(0b00110) failed as ▾(PTile5e(0b01000)); should be ▾(PTile5e(0b00111))

x = ▾(PTile5e(0b00010))
y = ▾(PTile5e(0b00110))

println(x)
println(y)

println(x + y)
=#
