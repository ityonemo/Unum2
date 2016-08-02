#h-layer.jl

function Base.bits{lattice, epochbits}(x::PFloat{lattice, epochbits})
  rep = @i(x)
  bits(rep)[1:bitlength(PFloat{lattice,epochbits})]
end

function Base.show{lattice, epochbits}(io::IO, x::PFloat{lattice, epochbits})
  print(io, bits(x))
end

function Base.show{lattice, epochbits}(io::IO, x::PBound{lattice, epochbits})
  if (x.flags & PFLOAT_SINGLETON != 0)
    print(io, "▾(")
    show(io, x.lower)
    print(io, ")")
  elseif (x.flags & PFLOAT_STDBOUND  != 0)
    show(io, x.lower)
    print(io, " → ")
    show(io, x.upper)
  elseif (x.flags & PFLOAT_ALLPREALS != 0)
    print(io, string("ℝᵖ(PBound{:", lattice ,",", epochbits, "})"))
  else
    print(io, string("∅(PBound{:", lattice ,",", epochbits, "})"))
  end
end
