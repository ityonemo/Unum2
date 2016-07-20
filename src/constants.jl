#constants.jl
#in this implementation, the constants are all pretty straightforward.

const pfloat_inf = 0x8000_0000_0000_0000
const pfloat_zero = 0x0000_0000_0000_0000
const pfloat_one = 0x4000_0000_0000_0000
const pfloat_neg_one = 0xC000_0000_0000_0000

Base.inf{lattice, epochs}(T::Type{PFloat{lattice, epochs}})     = reinterpret(T, pfloat_inf)
Base.zero{lattice, epochs}(T::Type{PFloat{lattice, epochs}})    = reinterpret(T, pfloat_zero)
Base.one{lattice, epochs}(T::Type{PFloat{lattice, epochs}})     = reinterpret(T, pfloat_one)
neg_one{lattice, epochs}(T::Type{PFloat{lattice, epochs}}) = reinterpret(T, pfloat_neg_one)

export neg_one
