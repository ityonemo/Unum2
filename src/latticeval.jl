#lattice value is the unsigned, epochless value for a particular floating point representation.
@generated function latticeval{lattice, epochbits}(p::PFloat{lattice, epochbits})
  
  mask = latticemask(epochbits)

  shift = 63 - epochbits - latticelength(lattice)

  :((@i(p) & $mask) >> $shift)
end
