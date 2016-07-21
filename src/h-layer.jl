#h-layer.jl

function Base.bits{lattice, epochbits}(x::PFloat{lattice, epochbits})
  rep = @i(x)
  bits(rep)[1:bitlength(PFloat{lattice,epochbits})]
end

function Base.show{lattice, epochbits}(io::IO, x::PFloat{lattice, epochbits})

  print(io, bits(x))

end
