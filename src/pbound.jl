#pbound.jl - type definition for pbounds

#create a series of symbols which are effectively state symbols.
const P_NULLSET   = 0x00 #no values
const P_SINGLETON = 0x01 #a SINGLETON value
const P_STDBOUND  = 0x02 #two values in a standard bound
const P_ALLPREALS = 0x03 #all projective reals

#create a series of value types which can specify the nature of the output.
const __LOWER = Val{:lower}  #if the result is a PBound, only output the lower PTile.
const __UPPER = Val{:upper}  #if the result is a PBound, only output the upper PTile.
const __INNER = Val{:inner}  #if the result is a PBound, only output the inner PTile. (only use for multiplication)
const __OUTER = Val{:outer}  #if the result is a PBound, only output the outer PTile. (only use for multiplication)

const __BOUND = Val{:bound}  #if the result is a PBound, output the entire PBound.  Promote PTiles to PBound
const __AUTO  = Val{:auto}   #output a PTile or a PBound as desired.
#note the __AUTO case will result in the worst performance, because the julia
#typesystem will have to keep track of types during runtime instead of compile t ime.

type PBound{lattice, epochbits} <: AbstractFloat
  lower::PTile{lattice, epochbits}
  upper::PTile{lattice, epochbits}
  state::UInt8
end

function Base.call{lattice, epochbits}(::Type{PBound{lattice, epochbits}}, lower::PTile{lattice, epochbits}, upper::PTile{lattice, epochbits})
  if (lower == upper)
    PBound{lattice, epochbits}(lower, zero(PTile{lattice, epochbits}), PTile_SINGLETON)
  else
    PBound{lattice, epochbits}(lower, upper, PTile_STDBOUND)
  end
end

#Base.call{lattice, epochbits}(::Type{PBound{lattice, epochbits}}, x::PBound{lattice, epochbits}) = PBound{lattice, epochbits}(x.lower, x.upper, x.state)
Base.call{lattice, epochbits}(::Type{PBound{lattice, epochbits}}, x::PTile{lattice, epochbits}) = PBound{lattice, epochbits}(x, zero(PTile{lattice, epochbits}), PTile_SINGLETON)
Base.call{lattice, epochbits}(::Type{PBound{lattice, epochbits}}) = PBound{lattice, epochbits}
# COOL SYMBOLS FOR PBOUNDS

function →{lattice, epochbits}(lower::PTile{lattice, epochbits}, upper::PTile{lattice, epochbits})
  (lower == upper) && throw(ArgumentError("→ cannot take identical ubounds"))
  PBound{lattice, epochbits}(lower, upper, PTile_STDBOUND)
end

▾{lattice, epochbits}(x::PTile{lattice, epochbits}) = PBound{lattice, epochbits}(x, zero(PTile{lattice, epochbits}), PTile_SINGLETON)

∅{lattice, epochbits}(::Type{PBound{lattice, epochbits}}) = emptyset(PBound{lattice, epochbits})

ℝ{lattice, epochbits}(::Type{PBound{lattice, epochbits}}) = PBound{lattice,epochbits}(neg_many(PTile{lattice, epochbits}), pos_many(PTile{lattice, epochbits}))

ℝᵖ{lattice, epochbits}(::Type{PBound{lattice, epochbits}}) = allprojectivereals(PBound{lattice, epochbits})

doc"""
  Unum2.coerce(::PTile, Val{output}) casts the PTile into a singleton PBound if the
  desired output is a bound, otherwise, it returns the naked float.
"""
coerce{lattice, epochbits, output}(x::PTile{lattice, epochbits}, ::Type{Val{output}}) = (output == :bound) ? PBound(x, zero(PTile{lattice, epochbits}), PTile_SINGLETON) : x

doc"""
  Unum2.\_auto(::PTile, ::PTile) casts the PTile into a singleton PBound if the
  desired output is auto, otherwise, it returns the naked float.
"""
_auto{lattice, epochbits}(l::PTile{lattice, epochbits}, u::PTile{lattice, epochbits}) = (l == u) ? l : PBound(l, u, PTile_STDBOUND)

export PBound, →, ▾, ∅, ℝ, ℝᵖ
