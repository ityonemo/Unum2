#constants.jl
#in this implementation, the constants are all pretty straightforward.

const pfloat_inf = 0x8000_0000_0000_0000
const pfloat_zero = 0x0000_0000_0000_0000
const pfloat_one = 0x4000_0000_0000_0000
const pfloat_neg_one = 0xC000_0000_0000_0000

@generated function incrementor{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}})
  x = one(UInt64) << (63 - latticebits(lattice) - epochbits)
  :($x)
end

Base.inf{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}})  = @p(pfloat_inf)
Base.zero{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = @p(pfloat_zero)
Base.one{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}})  = @p(pfloat_one)
neg_one{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}})   = @p(pfloat_neg_one)

export neg_one

is_zero(x::PFloat) = @i(x) == pfloat_zero
is_inf(x::PFloat) = @i(x) == pfloat_inf
is_one(x::PFloat) = @i(x) == pfloat_one
is_neg_one(x::PFloat) = @i(x) == pfloat_neg_one

################################################################################
# infinite and infinitesimal ulps

pos_many{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = @p(pfloat_inf - incrementor(T))
neg_many{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = @p(pfloat_inf + incrementor(T))
pos_few{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = @p(pfloat_zero + incrementor(T))
neg_few{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = @p(pfloat_zero - incrementor(T))

function extremum{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}, negative::Bool, inverted::Bool)
  if negative
    inverted ? (neg_few(T)) : (neg_many(T))
  else
    inverted ? (pos_few(T)) : (pos_many(T))
  end
end

################################################################################
# PBOUND constants

emptyset{lattice, epochbits}(T::Type{PBound{lattice, epochbits}}) = T(zero(PFloat{lattice, epochbits}), zero(PFloat{lattice, epochbits}), PFLOAT_NULLSET)
emptyset{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = PBound{lattice, epochbit}(zero(T), zero(T), PFLOAT_NULLSET)

allprojectivereals{lattice, epochbits}(T::Type{PBound{lattice, epochbits}}) = T(zero(PFloat{lattice, epochbits}), zero(PFloat{lattice, epochbits}), PFLOAT_ALLPREALS)
allprojectivereals{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = PBound{lattice, epochbits}(zero(T), zero(T), PFLOAT_ALLPREALS)
################################################################################

export pos_many, neg_many, pos_few, neg_few
