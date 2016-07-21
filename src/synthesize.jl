#synthesize puts together a PFloat from three components:  sign, epoch, and lvalue

const t64 = 0x8000_0000_0000_0000

#note that the lvalue might be flipped based on the epoch and the sign.
@generated function synthesize{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}, negative::Bool, inverse::Bool, epoch::Integer, lvalue)
  eshift = latticebits(lattice)
  tshift = 63 - latticebits(lattice) - epochbits
  quote
    flipsign = negative $ inverse

    result::UInt64 = @i (((epoch << $eshift) | (lvalue)) * (flipsign ? -1 : 1)) << $tshift

    result &= magmask(T)

    result += t64 * negative

    #synthesize epoch + lvalue combination.

    @p result
  end
end
