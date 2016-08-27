using Unum2
using Base.Test

include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")


#=
import_lattice(:PTile5)
include("5bittest/5btdefs.jl")
x = ▾(PTile5(0b01001))
y = ▾(PTile5(0b00010))
println(x)
println(y)
println(x * y)
=#
