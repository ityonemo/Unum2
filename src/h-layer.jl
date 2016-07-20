#h-layer.jl

function Base.bits{lattice, epochbits}(x::PFloat{lattice, epochbits})
  rep = @i(x)
  bits(rep)[1:bitlength(PFloat{lattice,epochbits})]
end
