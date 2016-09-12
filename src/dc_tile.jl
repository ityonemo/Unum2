
#dc_tile.jl - type definition and user functions for the __dc_tile type.

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
is_positive(v::__dc_tile) =   (v.flags & __DC_NEGATIVE) == z8
is_uninverted(v::__dc_tile) = (v.flags & __DC_INVERTED) == z8
is_negative(v::__dc_tile) =   (v.flags & __DC_NEGATIVE) != z8
is_inverted(v::__dc_tile) =   (v.flags & __DC_INVERTED) != z8
flag_parity(v::__dc_tile) = reinterpret(Bool, v.flags $ (v.flags >> 1))
#setters
set_positive!(v::__dc_tile)   = (v.flags &= ~__DC_NEGATIVE; nothing)
set_uninverted!(v::__dc_tile) = (v.flags &= ~__DC_INVERTED; nothing)
set_negative!(v::__dc_tile)   = (v.flags |= __DC_NEGATIVE; nothing)
set_inverted!(v::__dc_tile)   = (v.flags |= __DC_INVERTED; nothing)
flip_negative!(v::__dc_tile)  = (v.flags $= __DC_NEGATIVE; nothing)
flip_inverted!(v::__dc_tile)  = (v.flags $= __DC_INVERTED; nothing)

function additiveinverses(lhs::__dc_tile, rhs::__dc_tile)
  ((lhs.flags $ rhs.flags) == __DC_NEGATIVE) || return false
  (lhs.epoch == rhs.epoch) || return false
  return lhs.lvalue == rhs.lvalue
end

#basic comparison - ability to test equality (good for test suites)
import Base: ==
==(a::__dc_tile, b::__dc_tile) = (a.flags == b.flags) && (a.epoch == b.epoch) && (a.lvalue == b.lvalue)

@generated function synthesize{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}, v::__dc_tile)
  eshift = latticebits(lattice)
  tshift = PT_bits - 1 - latticebits(lattice) - epochbits
  m_epoch = max_epoch(epochbits)
  quote
    #set the value of the result, taking into acount that if we overflow on the
    #epoch, we should return an extreme value
    res::ST_Int = (v.epoch > $m_epoch) ? (@s pos_many(PTile{lattice, epochbits})) : @s(((v.epoch << $eshift) | (v.lvalue))  << $tshift)
    res |= @s(PTILE_ONE)
    res *= flag_parity(v) ? -one(ST_Int) : one(ST_Int)
    res = (res & @s(MAG_MASK)) | @s(is_negative(v) ? PTILE_INF : PTILE_ZERO)
    #synthesize epoch + lvalue combination.
    @p res
  end
end

@generated function decompose{lattice, epochbits}(p::PTile{lattice, epochbits})
  eshift = PT_bits - 1 - epochbits
  tshift = eshift - latticebits(lattice)
  lmask = latticemask(epochbits)
  quote

    #special case where we want to cast the negative one integer as being uninverted.
    ((@i p) == PTILE_NEG_ONE) && return __dc_tile(zero(ST_Int), zero(UT_Int), __DC_NEGATIVE)

    #first create a new value.
    res::__dc_tile = zero(__dc_tile)

    ivalue = @s p

    negative = ivalue < zero(ST_Int)
    ivalue = abs(ivalue)
    inverted = ivalue & PTILE_ONE == zero(ST_Int)
    ivalue = (inverted ? -ivalue : ivalue) & (@s CON_MASK)

    epoch::ST_Int  = ivalue >> $eshift
    lvalue::UT_Int = @i(ivalue & $lmask) >> $tshift

    return __dc_tile(epoch, lvalue , negative * __DC_NEGATIVE + inverted * __DC_INVERTED)
  end
end
