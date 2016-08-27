
#the synthesize/decompose functions convert a unum into a "deconstructed tile"
#object.  deconstructed tile will have (hopefully) register-bound values as
#it's passed between utility functions.

const __DC_NEGATIVE = 0x02
const __DC_INVERTED = 0x01
const z8 = 0x00

type __dc_tile
  epoch  ::ST_Int
  lvalue ::UT_Int
  flags  ::UInt8
end

Base.zero(::Type{__dc_tile}) = __dc_tile(zero(ST_Int), zero(UT_Int), zero(UInt8))

#properties
is_positive(v::__dc_tile) = (v.lvalue & __DC_NEGATIVE) == z8
is_uninverted(v::__dc_tile) = (v.lvalue & __DC_INVERTED) == z8
is_negative(v::__dc_tile) = (v.lvalue & __DC_NEGATIVE) != z8
is_inverted(v::__dc_tile) = (v.lvalue & __DC_INVERTED) != z8
flag_parity(v::__dc_tile) = reinterpret(Bool, v.lvalue $ (v.lvalue >> 1))
#setters
set_positive!(v::__dc_tile)   = (v.lvalue &= ~__DC_NEGATIVE; nothing)
set_uninverted!(v::__dc_tile) = (v.lvalue &= ~__DC_INVERTED; nothing)
set_negative!(v::__dc_tile)   = (v.lvalue |= __DC_NEGATIVE; nothing)
set_inverted!(v::__dc_tile)   = (v.lvalue |= __DC_INVERTED; nothing)
flip_negative!(v::__dc_tile)  = (v.lvalue $= __DC_NEGATIVE; nothing)
flip_inverted!(v::__dc_tile)  = (v.lvalue $= __DC_INVERTED; nothing)

#note that the lattice component of the tile value might be flipped based on the epoch and the sign.
synthesize{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}, v::__dc_tile) = synthesize(T, v::__dc_tile, __AUTO)

@generated function synthesize{lattice, epochbits, output}(T::Type{PTile{lattice, epochbits}}, v::__dc_tile, OT::Type{Val{output}})
  eshift = latticebits(lattice)
  tshift = PT_Bits - 1 - latticebits(lattice) - epochbits
  quote
    flipsign = flag_parity(v)

    res::ST_Int = @s(((v.epoch << $eshift) | (v.lvalue))  << $tshift)
    res |= PTILE_ONE * !is_uninverted(v)
    flipsign && (res = -res)
    res |= PTILE_INF * is_negative(v)
    #synthesize epoch + lvalue combination.
    coerce((@p res), OT)
  end
end

@generated function decompose{lattice, epochbits}(p::PTile{lattice, epochbits})
  eshift = PT_bits - 1 - epochbits
  tshift = eshift - latticebits(lattice)
  lmask = latticemask(epochbits)
  quote

    #special case where we want to cast the negative one integer as being uninverted.
    ((@i p) == PTile_NEG_ONE) && return __dc_tile(zero(ST_Int), zero(UT_Int), __DC_NEGATIVE)

    #first create a new value.
    res::__dc_tile = zero(__dc_tile)

    ivalue = @i p

    negative = (SIGN_MASK & ivalue) != z64
    inverted = ((INV_MASK & ivalue) == z64) $ negative

    tvalue::UT_Int = @i(((negative != inverted) ? -1 : 1) * @s p)
    epoch::ST_Int  = @s((tvalue & MAG_MASK) >>> $eshift)
    lvalue::UT_int = (tvalue & $lmask) >> $tshift
    epoch -= !((@i p) & MAG_MASK == zero)

    return __dc_tile(epoch, lvalue , negative * __DC_NEGATIVE + inverted * __DC_INVERTED)
  end
end
