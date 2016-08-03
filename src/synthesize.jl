#synthesize puts together a PFloat from three components:  sign, epoch, and lvalue

#note that the lvalue might be flipped based on the epoch and the sign.
@generated function synthesize{lattice, epochbits, output}(T::Type{PFloat{lattice, epochbits}}, negative::Bool, inverted::Bool, epoch::Integer, lvalue, ::Type{Val{output}})
  eshift = latticebits(lattice)
  tshift = 63 - latticebits(lattice) - epochbits
  quote
    flipsign = negative $ inverted

    result::Int64 = ((epoch << $eshift) | (lvalue))  << $tshift
    result |= 0x4000_0000_0000_0000
    result *= (flipsign ? -1 : 1)
    result &= @s magmask(T)

    result |= @s(sign_mask * negative)

    #synthesize epoch + lvalue combination.

    coerce(@p result, OT)
  end
end

@generated function decompose{lattice, epochbits}(p::PFloat{lattice, epochbits})
  eshift = 63 - epochbits
  tshift = eshift - latticebits(lattice)
  lmask = latticemask(epochbits)
  quote
    ivalue = @i p
    negative = (sign_mask & ivalue) != z64
    inverted = ((inv_mask & ivalue) == z64) $ negative
    tvalue = @i(((negative != inverted) ? -1 : 1) * @s p)
    epoch::Int64 = @s((tvalue & magnitude_mask) >>> $eshift)
    lvalue = (tvalue & $lmask) >> $tshift
    epoch -= (!((@i p) & magnitude_mask == 0x0000_0000_0000_0000)) * 1

    return (negative, inverted, epoch, lvalue)
  end
end
