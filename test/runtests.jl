using Unum2
using Base.Test

include("testtools.jl")

include("4bittest.jl")
include("5bittest.jl")
include("5bitepochtest.jl")
include("fma_test.jl")


import_lattice(:PFloat5)
import_lattice(:PFloat5e)
import_lattice(:PFloat4)

include("cgentest.jl")
