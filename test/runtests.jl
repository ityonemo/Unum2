using Unum2
using Base.Test

include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")

#=
import_lattice(:PFloat5)
include("5bittest/5btdefs.jl")

x = PFloat5(1/8)
y = PFloat5(1/10)
println(x)
println(y)
println(x - y)
=#
