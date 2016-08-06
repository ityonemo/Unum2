#pfloat.jl - type definition for PFloats.

# package code goes here
bitstype 64 PFloat{lattice, epochbits} <: AbstractFloat
export PFloat

#don't call PFloat constructor with an unsigned integer, that is reserved for direct binary initialization
@generated function Base.call{lattice, epochbits}(::Type{PFloat{lattice, epochbits}}, n::Unsigned)
  shiftbits = 64 - (latticebits(lattice) + 2)
  quote
    #the pfloat library keeps its values shifted right.
    @p ((UInt64(n)) << $shiftbits)
  end
end
