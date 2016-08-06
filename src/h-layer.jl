#h-layer.jl

function Base.bits{lattice, epochbits}(x::PFloat{lattice, epochbits})
  rep = @i(x)
  bits(rep)[1:bitlength(PFloat{lattice,epochbits})]
end

function Base.show{lattice, epochbits}(io::IO, x::PFloat{lattice, epochbits})
  if is_zero(x)
    print(io, "zero(")
    show(io, typeof(x))
    print(io, ")")
  elseif is_inf(x)
    print(io, "inf(")
    show(io, typeof(x))
    print(io, ")")
  elseif is_one(x)
    print(io, "one(")
    show(io, typeof(x))
    print(io, ")")
  elseif is_neg_one(x)
    print(io, "-one(")
    show(io, typeof(x))
    print(io, ")")
  else
    #for now don't deal with epoch
    print(io, typeof(x), "(0b", bits(x),")")
  end
end

function Base.show{lattice, epochbits}(io::IO, x::PBound{lattice, epochbits})
  if (x.state == PFLOAT_SINGLETON)
    print(io, "▾(", typeof(x.lower), "(0b", bits(x.lower), "))")
  elseif (x.state == PFLOAT_STDBOUND)
    print(io, typeof(x.lower), "(0b", bits(x.lower), ") → ", typeof(x.lower), "(0b", bits(x.upper), ")")
  elseif (x.state == PFLOAT_ALLPREALS)
    print(io, string("ℝᵖ(PBound{:", lattice ,",", epochbits, "})"))
  else
    print(io, string("∅(PBound{:", lattice ,",", epochbits, "})"))
  end
end
