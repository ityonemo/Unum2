#h-layer.jl

function Base.bits{lattice, epochbits}(x::PFloat{lattice, epochbits})
  rep = @i(x)
  bits(rep)[1:bitlength(PFloat{lattice,epochbits})]
end

function Base.show{lattice, epochbits}(io::IO, x::PFloat{lattice, epochbits})
  print(io, bits(x))
end

function Base.show{lattice, epochbits}(io::IO, x::PBound{lattice, epochbits})
  if (x.state == PFLOAT_SINGLETON)
    print(io, "▾(")
    show(io, x.lower)
    print(io, ")")
  elseif (x.state == PFLOAT_STDBOUND)
    show(io, x.lower)
    print(io, " → ")
    show(io, x.upper)
  elseif (x.state == PFLOAT_ALLPREALS)
    print(io, string("ℝᵖ(PBound{:", lattice ,",", epochbits, "})"))
  else
    print(io, string("∅(PBound{:", lattice ,",", epochbits, "})"))
  end
end
