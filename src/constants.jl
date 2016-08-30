#constants.jl
#in this implementation, the constants are all pretty straightforward.



@generated function incrementor{lattice, epochbits}(T::Type{PTile{lattice, epochbits}})
  x = one(UInt64) << (63 - latticebits(lattice) - epochbits)
  :($x)
end

Base.inf{lattice, epochbits}(T::Type{PTile{lattice, epochbits}})  = @p(PTILE_INF)
Base.zero{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}) = @p(PTILE_ZERO)
Base.one{lattice, epochbits}(T::Type{PTile{lattice, epochbits}})  = @p(PTILE_ONE)
neg_one{lattice, epochbits}(T::Type{PTile{lattice, epochbits}})   = @p(PTILE_NEG_ONE)

export neg_one

is_zero(x::PTile) = @i(x) == PTILE_ZERO
is_inf(x::PTile) = @i(x) == PTILE_INF
is_one(x::PTile) = @i(x) == PTILE_ONE
is_neg_one(x::PTile) = @i(x) == PTILE_NEG_ONE
is_unit(x::PTile) = (@i(x) & MAG_MASK) == PTILE_ONE

################################################################################
# infinite and infinitesimal ulps

pos_many{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}) = @p(PTILE_INF - incrementor(T))
neg_many{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}) = @p(PTILE_INF + incrementor(T))
pos_few{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}) = @p(PTILE_ZERO + incrementor(T))
neg_few{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}) = @p(PTILE_ZERO - incrementor(T))

function extremum{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}, negative::Bool, inverted::Bool)
  if negative
    inverted ? (neg_few(T)) : (neg_many(T))
  else
    inverted ? (pos_few(T)) : (pos_many(T))
  end
end

################################################################################
# PBOUND constants

emptyset{lattice, epochbits}(T::Type{PBound{lattice, epochbits}}) = T(zero(PTile{lattice, epochbits}), zero(PTile{lattice, epochbits}), PBOUND_NULLSET)
emptyset{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}) = PBound{lattice, epochbit}(zero(T), zero(T), PBOUND_NULLSET)

allprojectivereals{lattice, epochbits}(T::Type{PBound{lattice, epochbits}}) = T(zero(PTile{lattice, epochbits}), zero(PTile{lattice, epochbits}), PBOUND_ALLPREALS)
allprojectivereals{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}) = PBound{lattice, epochbits}(zero(T), zero(T), PBOUND_ALLPREALS)
################################################################################

export pos_many, neg_many, pos_few, neg_few
