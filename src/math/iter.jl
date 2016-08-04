#iter.jl - treating PNums as iterables.

#iterating through PFloat type
Base.start{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = inf(T)
@generated function Base.next{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}, state)
  :((state, next(state)))
end
Base.done{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}, state) = (state == pos_many(T))
Base.eltype{lattice, epochbits}(T::Type{Type{PFloat{lattice, epochbits}}}) = PFloat{lattice, epochbits}
Base.length{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = 1 << (1 + latticebits(lattice) + epochbits)

#iterating through PBounds

function Base.start{lattice, epochbits}(x::PBound{lattice, epochbits})
  isempty(x) && throw(BoundsError("null set PBound"))
  #start at infinity if we're all reals
  ispreals(x) && return inf(PFloat{lattice, epochbits})
  x.lower
end
@generated function Base.next{lattice, epochbits}(x::PBound{lattice, epochbits}, state)
  :((state, next(state)))
end
function Base.done{lattice, epochbits}(x::PBound{lattice, epochbits}, state)
  ispreals(x) && (state == pos_many(T))
  issingle(x) && return true
  state == x.upper
end
Base.eltype{lattice, epochbits}(T::Type{PBound{lattice, epochbits}}) = PFloat{lattice, epochbits}
function Base.length{lattice, epochbits}(x::PBound{lattice, epochbits})
  isempty(x) && return 0
  ispreals(x) && return length(PFloat{lattice, epochbits})
  issingle(x) && return 1
  @s(((@i x.upper) - (@i x.lower)) >> (64 - 1 - latticebits(lattice) - epochbits)) + 1
end

################################################################################
## FUNCTIONS RELATED TO ITERATION.

@generated function Base.next{lattice, epochbits}(x::PFloat{lattice, epochbits})
  INCREMENTOR = incrementor(PFloat{lattice, epochbits})
  :(@p ((@i x) + $INCREMENTOR))
end
@generated function prev{lattice, epochbits}(x::PFloat{lattice, epochbits})
  INCREMENTOR = incrementor(PFloat{lattice, epochbits})
  :(@p ((@i x) - $INCREMENTOR))
end

##### DEDEKIND CUT FUNCTIONS

doc"""
  lub(::PFloat) outputs the least upper bound for PFloat.  If the PFloat is exact
  then it returns the value; if it's an ulp, it return the next PFloat.
"""
lub{lattice, epochbits}(x::PFloat{lattice, epochbits}) = isexact(x) ? x : next(x)

doc"""
  glb(::PFloat) outputs the greates lower bound for PFloat.  If the PFloat is exact
  then it returns the value; if it's an ulp, it return the previous PFloat.
"""
glb{lattice, epochbits}(x::PFloat{lattice, epochbits}) = isexact(x) ? x : prev(x)

doc"""
  upperulp(::PFloat) outputs the ulp that is just above the value if it's exact,
  otherwise leaves it unchanged.
"""
upperulp{lattice, epochbits}(x::PFloat{lattice, epochbits}) = isulp(x) ? x : next(x)

doc"""
  lowerulp(::PFloat) outputs the ulp that is just below the value if it's exact,
  otherwise leaves it unchanged.
"""
lowerulp{lattice, epochbits}(x::PFloat{lattice, epochbits}) = isulp(x) ? x : prev(x)

export prev, lub, glb, upperulp, lowerulp
