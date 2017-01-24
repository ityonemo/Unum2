#ptile.jl - type definition for PTiles.

#TODO:  put this in an "options" package, allowing the package to be recompiled
#as a 32-bit integer

#alias for int type flexibility.  This should be able to be changed based on the
#options system.  UT_Int means "Unsigned Tile Integer"
typealias UT_Int UInt64

#make sure our assigend UT_Int class is unsigned.
@assert UT_Int <: Unsigned
#generate derived types from the Unsigned tile integer.
typealias ST_Int typeof(signed(one(UT_Int)))
@assert ST_Int <: Signed



const PT_bits = sizeof(UT_Int) * 8
bitstype PT_bits PTile{lattice, epochbits} <: AbstractFloat
export PTile

const PTILE_ZERO = zero(UT_Int)
const PTILE_INF  = one(UT_Int) << (PT_bits - 1)
const PTILE_ONE  = one(UT_Int) << (PT_bits - 2)
const PTILE_NEG_ONE = PTILE_INF | PTILE_ONE
#magnitude mask
const MAG_MASK = ~PTILE_INF
#contents mask
const CON_MASK = ~PTILE_NEG_ONE

#don't call PTile constructor with an unsigned integer, that is reserved for direct binary initialization
@generated function (::Type{PTile{lattice, epochbits}}){lattice, epochbits}(::Type{PTile{lattice, epochbits}}, n::Unsigned)
  shiftbits = PT_bits - epochbits - (latticebits(lattice) + 1)
  quote
    #the PTile library keeps its values shifted right.
    @p ((UT_Int(n)) << $shiftbits)
  end
end
