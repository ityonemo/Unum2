
magnitude_mask = 0x7FFF_FFFF_FFFF_FFFF

doc"""
  latticemask retrieves the number of bits that the lattice requires
"""
epochmask(epochbits) = magnitude_mask - ((one(UInt64) << (63 - epochbits)) - one(UInt64))

@generated function evalue{lattice, epochbits}(x::PFloat{lattice, epochbits})
  shift = 63 - epochbits
  mask = epochmask(epochbits)
  :(((@i x) & $mask) >> $shift)
end
