module Unum2

# package code goes here
bitstype 64 PFloat{lattice, epochbits} <: AbstractFloat
export PFloat

include("lattices.jl")

@generated function call{lattice, epochbits}(::Type{PFloat{lattice, epochbits}}, value)
  validate(__MASTER_LATTICE_LIST[lattice])  #double check to make sure it's ok, because why not.
  #make sure epochs is more than 0
  (epochbits > 0) || throw(ArgumentError("must have at least one epoch bit"))
  return :()
end

include("tools.jl")
include("constants.jl")
include("latticeval.jl")

include("lattices/four-bit-lattice.jl")
include("h-layer.jl")

end # module
