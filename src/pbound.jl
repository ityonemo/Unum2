#pbound.jl - type definition for pbounds

#create a series of symbols which are effectively state symbols.
const PBOUND_NULLSET   = 0x00 #no values
const PBOUND_SINGLE = 0x01 #a SINGLETON value
const PBOUND_DOUBLE  = 0x02 #two values in a standard bound
const PBOUND_ALLPREALS = 0x03 #all projective reals

#create a series of value types which can specify the nature of the output.
const __LOWER = Val{:lower}  #if the result is a PBound, only output the lower PTile.
const __UPPER = Val{:upper}  #if the result is a PBound, only output the upper PTile.
const __INNER = Val{:inner}  #if the result is a PBound, only output the inner PTile.
const __OUTER = Val{:outer}  #if the result is a PBound, only output the outer PTile.

#note the __AUTO case will result in the worst performance, because the julia
#typesystem will have to keep track of types during runtime instead of compile t ime.

type PBound{lattice, epochbits} <: AbstractFloat
  lower::PTile{lattice, epochbits}
  upper::PTile{lattice, epochbits}
  state::UInt8
end

function (::Type{PBound{lattice, epochbits}}){lattice,epochbits}(lower::PTile{lattice, epochbits}, upper::PTile{lattice, epochbits})
  if (lower == upper)
    PBound{lattice, epochbits}(lower, zero(PTile{lattice, epochbits}), PBOUND_SINGLE)
  else
    PBound{lattice, epochbits}(lower, upper, PBOUND_DOUBLE)
  end
end

(::Type{PBound{lattice, epochbits}}){lattice, epochbits}(x::PTile{lattice, epochbits}) = PBound{lattice, epochbits}(x, zero(PTile{lattice, epochbits}), PTile_SINGLETON)
(::Type{PBound{lattice, epochbits}}){lattice, epochbits}(::Type{PTile{lattice, epochbits}}) = PBound{lattice, epochbits}

function Base.copy!{lattice, epochbits}(dest::PBound{lattice, epochbits}, src::PBound{lattice, epochbits})
  dest.lower = src.lower
  dest.upper = src.upper
  dest.state = src.state

  nothing
end

# COOL SYMBOLS FOR PBOUNDS

function →{lattice, epochbits}(lower::PTile{lattice, epochbits}, upper::PTile{lattice, epochbits})
  (lower == upper) && throw(ArgumentError("→ cannot take identical ubounds"))
  PBound{lattice, epochbits}(lower, upper, PBOUND_DOUBLE)
end

▾{lattice, epochbits}(x::PTile{lattice, epochbits}) = PBound{lattice, epochbits}(x, zero(PTile{lattice, epochbits}), PBOUND_SINGLE)

∅{lattice, epochbits}(::Type{PBound{lattice, epochbits}}) = emptyset(PBound{lattice, epochbits})

ℝ{lattice, epochbits}(::Type{PBound{lattice, epochbits}}) = PBound{lattice,epochbits}(neg_many(PTile{lattice, epochbits}), pos_many(PTile{lattice, epochbits}))

ℝᵖ{lattice, epochbits}(::Type{PBound{lattice, epochbits}}) = allprojectivereals(PBound{lattice, epochbits})

doc"""
  Unum2.coerce(::PTile, Val{output}) casts the PTile into a singleton PBound if the
  desired output is a bound, otherwise, it returns the naked float.
"""
coerce{lattice, epochbits, output}(x::PTile{lattice, epochbits}, ::Type{Val{output}}) = (output == :bound) ? PBound(x, zero(PTile{lattice, epochbits}), PBOUND_SINGLE) : x

doc"""
  Unum2.\_auto(::PTile, ::PTile) casts the PTile into a singleton PBound if the
  desired output is auto, otherwise, it returns the naked float.
"""
_auto{lattice, epochbits}(l::PTile{lattice, epochbits}, u::PTile{lattice, epochbits}) = (l == u) ? l : PBound(l, u, PBOUND_DOUBLE)

export PBound, →, ▾, ∅, ℝ, ℝᵖ
