#iter.jl - treating PNums as iterables.

#iterating through PTile type
Base.start{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}) = (inf(T), false)
@generated function Base.next{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}, state)
  :((state[1], (next(state[1]), true)))
end
Base.done{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}, state) = (state[2] && state[1] == inf(T))
Base.eltype{lattice, epochbits}(T::Type{Type{PTile{lattice, epochbits}}}) = PTile{lattice, epochbits}
Base.length{lattice, epochbits}(T::Type{PTile{lattice, epochbits}}) = 1 << (1 + latticebits(lattice) + epochbits)

#iterating through PBounds

function Base.start{lattice, epochbits}(x::PBound{lattice, epochbits})
  isempty(x) && throw(BoundsError("null set PBound"))
  #start at infinity if we're all reals
  ispreals(x) && return inf(PTile{lattice, epochbits})
  (x.lower, false)
end
function Base.next{lattice, epochbits}(x::PBound{lattice, epochbits}, state)
  (state[1], (next(state[1]), true))
end
function Base.done{lattice, epochbits}(x::PBound{lattice, epochbits}, state)
  ispreals(x) && state[2] && (state[1] == inf(T))
  issingle(x) && return state[2]
  state[2] && (state[1] > x.upper)
end
Base.eltype{lattice, epochbits}(T::Type{PBound{lattice, epochbits}}) = PTile{lattice, epochbits}
function Base.length{lattice, epochbits}(x::PBound{lattice, epochbits})
  isempty(x) && return 0
  ispreals(x) && return length(PTile{lattice, epochbits})
  issingle(x) && return 1
  @s(((@i x.upper) - (@i x.lower)) >> (64 - 1 - latticebits(lattice) - epochbits)) + 1
end

################################################################################
## FUNCTIONS RELATED TO ITERATION.

@generated function Base.next{lattice, epochbits}(x::PTile{lattice, epochbits})
  INCREMENTOR = incrementor(PTile{lattice, epochbits})
  :(@p ((@i x) + $INCREMENTOR))
end
@generated function prev{lattice, epochbits}(x::PTile{lattice, epochbits})
  INCREMENTOR = incrementor(PTile{lattice, epochbits})
  :(@p ((@i x) - $INCREMENTOR))
end

################################################################################
# Special "exactiterator" type

type ExactIterator{lattice, epochbits}
  lower::PTile{lattice, epochbits}
  upper::PTile{lattice, epochbits}
end

Base.start{lattice, epochbits}(x::ExactIterator{lattice, epochbits}) = (x.lower, false)
function Base.next{lattice, epochbits}(x::ExactIterator{lattice, epochbits}, state)
  (state[1], (next(next(state[1])), true))
end
Base.done{lattice, epochbits}(x::ExactIterator{lattice, epochbits}, state) = state[2] && (state[1] > x.upper)
Base.eltype{lattice, epochbits}(T::Type{ExactIterator{lattice, epochbits}}) = PTile{lattice, epochbits}
Base.length{lattice, epochbits}(x::ExactIterator{lattice, epochbits}) =
  @s(((@i x.upper) - (@i x.lower)) >> (64 - latticebits(lattice) - epochbits)) + 1


function exacts{lattice, epochbits}(x::PBound{lattice, epochbits})
  isempty(x) && throw(BoundsError("null set PBound has no exacts"))
  if issingle(x)
    if isexact(x.lower)
      return ExactIterator(x.lower, x.lower)
    else
      throw(BoundsError("inexact tile PBound has no exacts"))
    end
  end
  ispreals(x) && return ExactIterator(inf(PTile{lattice, epochbits}), maxexact(PTile{lattice, epochbits}))
  lower = glb(x.lower)
  upper = lub(x.upper)
  (upper == lower) && (upper = prev(prev(upper)))
  ExactIterator(lower, upper)
end

function exacts{lattice, epochbits}(T::Type{PTile{lattice, epochbits}})
  ExactIterator(inf(PTile{lattice, epochbits}), maxexact(T))
end

export exacts

##### DEDEKIND CUT FUNCTIONS

doc"""
  lub(::PTile) outputs the least upper bound for PTile.  If the PTile is exact
  then it returns the value; if it's an ulp, it return the next PTile.
"""
lub{lattice, epochbits}(x::PTile{lattice, epochbits}) = isexact(x) ? x : next(x)

doc"""
  glb(::PTile) outputs the greates lower bound for PTile.  If the PTile is exact
  then it returns the value; if it's an ulp, it return the previous PTile.
"""
glb{lattice, epochbits}(x::PTile{lattice, epochbits}) = isexact(x) ? x : prev(x)

doc"""
  upperulp(::PTile) outputs the ulp that is just above the value if it's exact,
  otherwise leaves it unchanged.
"""
upperulp{lattice, epochbits}(x::PTile{lattice, epochbits}) = isulp(x) ? x : next(x)

doc"""
  lowerulp(::PTile) outputs the ulp that is just below the value if it's exact,
  otherwise leaves it unchanged.
"""
lowerulp{lattice, epochbits}(x::PTile{lattice, epochbits}) = isulp(x) ? x : prev(x)

export prev, lub, glb, upperulp, lowerulp
