module Unum2

include("ptile.jl")
include("pbound.jl")
include("epochs.jl")
include("lattices.jl")
include("tools.jl")
include("constants.jl")
include("dc_tile.jl")
include("properties.jl")
include("inverses.jl")

#include("math/boundmath.jl")
include("math/tables.jl")
include("math/iter.jl")
include("math/cnv.jl")
include("math/cmp.jl")
include("math/add.jl")
include("math/mul.jl")
include("math/div.jl")
include("math/sub.jl")
include("math/fma.jl")

include("math/xadd.jl")

include("h-layer.jl")

include("rationalarray.jl")
include("rationalarray2.jl")

#c generation tools
include("cgen/cgen.jl")

end # module
