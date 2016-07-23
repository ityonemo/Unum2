
magnitude_mask = 0x7FFF_FFFF_FFFF_FFFF

doc"""
  latticemask retrieves the number of bits that the lattice requires
"""
epochmask(epochbits) = magnitude_mask - ((one(UInt64) << (63 - epochbits)) - one(UInt64))

max_epoch(epochbits) = (1 << (epochbits - 1)) - 1
