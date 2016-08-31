using Unum2
using Base.Test

include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")


#=
import_lattice(:PFloat5)

#2, 4: PTile5(0b00010) + PTile5(0b00100) failed as ▾(PTile5(0b00110)); should be ▾(PTile5(0b00101))

x = ▾(PTile5(0b00010))
y = ▾(PTile5(0b00100))

println(x + y)
=#
