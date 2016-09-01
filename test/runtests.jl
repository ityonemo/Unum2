using Unum2
using Base.Test
#=
include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")
include("5bitepochtest.jl")
=#

import_lattice(:PFloat6)

x = Unum2.count_cell_condition(Val{:LNum6}, Unum2.check_uninverted_addition)
__MASTER_STRIDE_LIST(x)
x = Unum2.count_cell_condition(Val{:LNum6}, Unum2.check_crossed_addition)
__MASTER_STRIDE_LIST(x)
x = Unum2.count_cell_condition(Val{:LNum6}, Unum2.check_inverted_addition)
__MASTER_STRIDE_LIST(x)
x = Unum2.count_cell_condition(Val{:LNum6}, Unum2.check_uninverted_subtraction)
__MASTER_STRIDE_LIST(x)
x = Unum2.count_cell_condition(Val{:LNum6}, Unum2.check_crossed_subtraction)
__MASTER_STRIDE_LIST(x)
x = Unum2.count_cell_condition(Val{:LNum6}, Unum2.check_inverted_subtraction)
__MASTER_STRIDE_LIST(x)


#5, 13: PTile5e(0b00101) * PTile5e(0b01101) failed as PTile5e(0b01001) → PTile5e(0b00111); should be PTile5e(0b01001) → PTile5e(0b01011)
#=
x = ▾(PTile5e(0b00100))
y = ▾(PTile5e(0b01100))

__MASTER_STRIDE_LIST(x)
__MASTER_STRIDE_LIST(y)

__MASTER_STRIDE_LIST(x * y)
=#
