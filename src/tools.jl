#tools.jl - various tools to make programming Lnums easier.
doc"""
  latticebits retrieves the number of bits that the lattice requires
"""
latticebits(lattice) = lnumlength(__MASTER_LATTICE_LIST[lattice])

doc"""
  latticemask retrieves the number of bits that the lattice requires
"""
latticemask(epochbits) = (one(UInt64) << (63 - epochbits)) - one(UInt64)

doc"""
  @i reinterprets a PFloat as an integer
"""
macro i(p)
  esc(:(reinterpret(UInt64, $p)))
end

doc"""
  @p reinterprets a integer as a PFloat
"""
macro p(i)
  esc(:(reinterpret(PFloat{lattice, epochbits}, $i)))
end

function latticelength(lattice::Symbol)
  latticelength(__MASTER_LATTICE_LIST[lattice])
end

bitlength{lattice, epochbits}(::Type{PFloat{lattice, epochbits}}) = 1 + epochbits + latticelength(lattice)
