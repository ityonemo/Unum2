using Unum2
using Base.Test


include("testtools.jl")
include("4bittest.jl")
include("5bittest.jl")
include("5bitepochtest.jl")

#=
import_lattice(:PFloat5e)

# one(PTile5e) - PTile5e(0b00100)

x = ▾(PTile5e(0b01000))
y = ▾(PTile5e(0b00100))

println(x)
println(y)

println(x - y)
=#
#=
println("====")
display(Unum2.__Lnum5e_sub_table)
println()
println("----")
display(Unum2.__Lnum5e_sub_epoch_table)
println()
=#
