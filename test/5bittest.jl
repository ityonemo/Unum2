
import_lattice(:PTile5)

include("5bittest/5btdefs.jl")
include("5bittest/5bt-test-add.jl")
include("5bittest/5bt-test-sub.jl")
include("5bittest/5bt-test-mul.jl")

#test addition
testop5(+, btadd5)
testop5(-, btsub5)
testop5(*, btmul5)
