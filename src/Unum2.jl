module Unum2

# package code goes here
bitstype 64 PFloat{lattice, epochbits} <: AbstractFloat
export PFloat

type PBound{lattice, epochbits} <: AbstractFloat
  lower::PFloat{lattice, epochbits}
  upper::PFloat{lattice, epochbits}
  function PBound(lower::PFloat{lattice, epochbits}, upper::PFloat{lattice, epochbits})
    new(lower, upper)
  end
end

doc"""
  magmask()
  magnitude of the number mask (ignores sign)
"""
function magmask{lattice, epochbits}(::Type{PFloat{lattice, epochbits}})
  0x8000_0000_0000_0000 - 0x0000_0000_0000_0001 << (62 - latticebits(lattice) - epochbits)
end

include("epochs.jl")
include("lattices.jl")

@generated function call{lattice, epochbits}(::Type{PFloat{lattice, epochbits}}, value)
  validate(__MASTER_LATTICE_LIST[lattice], __MASTER_PIVOT_LIST[lattice])  #double check to make sure it's ok, because why not.
  #make sure epochs is more than 0
  (epochbits > 0) || throw(ArgumentError("must have at least one epoch bit"))
  return :()
end

include("tools.jl")
include("constants.jl")
include("synthesize.jl")
include("properties.jl")
include("inverses.jl")

include("math/tables.jl")
include("math/cmp.jl")
include("math/add.jl")
include("math/mul.jl")
include("math/div.jl")
include("math/sub.jl")

include("h-layer.jl")

end # module
