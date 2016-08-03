#pbound.jl - type definition for pbounds

#create a series of symbols which are effectively state symbols.
const PFLOAT_NULLSET   = 0x0000 #no values
const PFLOAT_SINGLETON = 0x0001 #a single value
const PFLOAT_STDBOUND  = 0x0002 #two values in a standard bound
const PFLOAT_ALLPREALS = 0x0003 #all projective reals

#create a series of value types which can specify the nature of the output.
const __LOWER = Val{:lower}  #if the result is a PBound, only output the lower PFloat.
const __UPPER = Val{:upper}  #if the result is a PBound, only output the upper PFloat.
const __BOUND = Val{:bound}  #if the result is a PBound, output the entire PBound.  Promote PFloats to PBound
const __AUTO  = Val{:auto}   #output a PFloat or a PBound as desired.
#note the __AUTO case will result in the worst performance, because the julia
#typesystem will have to keep track of types during runtime instead of compile t ime.

type PBound{lattice, epochbits} <: AbstractFloat
  lower::PFloat{lattice, epochbits}
  upper::PFloat{lattice, epochbits}
  state::UInt16
end

function PBound{lattice, epochbits}(lower::PFloat{lattice, epochbits}, upper::PFloat{lattice, epochbits})
  if (lower == upper)
    PBound{lattice, epochbits}(lower, zero(PFloat{lattice, epochbits}), PFLOAT_SINGLETON)
  else
    PBound{lattice, epochbits}(lower, upper, PFLOAT_STDBOUND)
  end
end

PBound{lattice, epochbits}(x::PFloat{lattice, epochbits}) = PBound{lattice, epochbits}(x, zero(PFloat{lattice, epochbits}), PFLOAT_SINGLETON)
PBound{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = PBound{lattice, epochbits}
# COOL SYMBOLS FOR PBOUNDS

function →{lattice, epochbits}(lower::PFloat{lattice, epochbits}, upper::PFloat{lattice, epochbits})
  (lower == upper) && throw(ArgumentError("→ cannot take identical ubounds"))
  PBound{lattice, epochbits}(lower, upper, PFLOAT_STDBOUND)
end

▾{lattice, epochbits}(x::PFloat{lattice, epochbits}) = PBound{lattice, epochbits}(x, zero(PFloat{lattice, epochbits}), PFLOAT_SINGLETON)

∅{lattice, epochbits}(::Type{PBound{lattice, epochbits}}) = emptyset(PBound{lattice, epochbits})

ℝ{lattice, epochbits}(::Type{PBound{lattice, epochbits}}) = PBound{lattice,epochbits}(neg_many(PFloat{lattice, epochbits}), pos_many(PFloat{lattice, epochbits}))

ℝᵖ{lattice, epochbits}(::Type{PBound{lattice, epochbits}}) = allprojectivereals(PBound{lattice, epochbits})

doc"""
  Unum2.coerce(::PFloat, Val{output}) casts the PFloat into a singleton PBound if the
  desired output is a bound, otherwise, it returns the naked float.
"""
coerce{lattice, epochbits, output}(x::PFloat{lattice, epochbits}, ::Type{Val{output}}) = (output == :bound) ? PBound(x) : x

export PBound, →, ▾, ∅, ℝ, ℝᵖ
