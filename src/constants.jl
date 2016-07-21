#constants.jl
#in this implementation, the constants are all pretty straightforward.

const pfloat_inf = 0x8000_0000_0000_0000
const pfloat_zero = 0x0000_0000_0000_0000
const pfloat_one = 0x4000_0000_0000_0000
const pfloat_neg_one = 0xC000_0000_0000_0000

Base.inf{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}})  = @p(pfloat_inf)
Base.zero{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = @p(pfloat_zero)
Base.one{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}})  = @p(pfloat_one)
neg_one{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}})   = @p(pfloat_neg_one)

export neg_one

is_zero(x::PFloat) = @i(x) == pfloat_zero
is_inf(x::PFloat) = @i(x) == pfloat_inf
