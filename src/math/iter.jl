#iter.jl - treating PNums as iterables.

#iterating through PFloat type
Base.start{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = inf(T)
@generated function Base.next{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}, state)
  INCREMENTOR = incrementor(PFloat{lattice, epochbits})
  :((state, @p ((@i state) + $INCREMENTOR)))
end
Base.done{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}, state) = (state == pos_many(T))
Base.eltype{lattice, epochbits}(T::Type{Type{PFloat{lattice, epochbits}}}) = PFloat{lattice, epochbits}
Base.length{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}) = 1 << (1 + latticebits(lattice) + epochbits)
#also define a new function Base.prev which pulls the previous value.
@generated function prev{lattice, epochbits}(T::Type{PFloat{lattice, epochbits}}, state)
  INCREMENTOR = incrementor(PFloat{lattice, epochbits})
  :((state, @p ((@i state) - $INCREMENTOR)))
end

#iterating through PBounds

function Base.start{lattice, epochbits}(x::PBound{lattice, epochbits})
  isempty(x) && throw(BoundsError("null set PBound"))
  #start at infinity if we're all reals
  ispreals(x) && return inf(PFloat{lattice, epochbits})
  x.lower
end
@generated function Base.next{lattice, epochbits}(x::PBound{lattice, epochbits}, state)
  INCREMENTOR = incrementor(PFloat{lattice, epochbits})
  :((state, @p ((@i state) + $INCREMENTOR)))
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
@generated function prev{lattice, epochbits}(x::PBound{lattice, epochbits}, state)
  INCREMENTOR = incrementor(PFloat{lattice, epochbits})
  :((state, @p ((@i state) - $INCREMENTOR)))
end
