using Unum2
using Base.Test
#=
include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")
include("5bitepochtest.jl")
=#

import_lattice(:PFloat6)

x = Unum2.count_cell_condition(PTile6, Unum2.check_uninverted_addition)
println(x)
x = Unum2.count_cell_condition(PTile6, Unum2.check_crossed_addition)
println(x)
x = Unum2.count_cell_condition(PTile6, Unum2.check_inverted_addition)
println(x)
x = Unum2.count_cell_condition(PTile6, Unum2.check_uninverted_subtraction)
println(x)
x = Unum2.count_cell_condition(PTile6, Unum2.check_crossed_subtraction)
println(x)
x = Unum2.count_cell_condition(PTile6, Unum2.check_inverted_subtraction)
println(x)


#5, 13: PTile5e(0b00101) * PTile5e(0b01101) failed as PTile5e(0b01001) → PTile5e(0b00111); should be PTile5e(0b01001) → PTile5e(0b01011)
#=
x = ▾(PTile5e(0b00100))
y = ▾(PTile5e(0b01100))

println(x)
println(y)

println(x * y)
=#
