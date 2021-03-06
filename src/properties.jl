const SIGN_MASK    = 0x8000_0000_0000_0000
const INV_MASK     = 0x4000_0000_0000_0000

isnegative{lattice, epochbits}(x::PTile{lattice, epochbits}) = ((@i x) & (~SIGN_MASK) != 0) & (PTILE_ZERO != (SIGN_MASK & (@i x)))
ispositive{lattice, epochbits}(x::PTile{lattice, epochbits}) = ((@i x) & (~SIGN_MASK) != 0) & (PTILE_ZERO == (SIGN_MASK & (@i x)))
isinverted{lattice, epochbits}(x::PTile{lattice, epochbits}) = ((@i x) & (~SIGN_MASK) != 0) & ((PTILE_ZERO != (INV_MASK & (@i x))) == (PTILE_ZERO != (SIGN_MASK & (@i x))))
isexact{lattice, epochbits}(x::PTile{lattice, epochbits}) = (@i x) & incrementor(typeof(x)) == 0
isulp{lattice, epochbits}(x::PTile{lattice, epochbits}) = (@i x) & incrementor(typeof(x)) != 0

@generated function is_neg_many{lattice, epochbits}(x::PTile{lattice, epochbits})
  magic_value = SIGN_MASK | incrementor(x)
  :((@i x) == $magic_value)
end
@generated function is_pos_many{lattice, epochbits}(x::PTile{lattice, epochbits})
  magic_value = SIGN_MASK - incrementor(x)
  :((@i x) == $magic_value)
end

export isnegative, ispositive, isinverted

import Base.isempty
#pbound properties.
isempty{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.state == PBOUND_NULLSET)
issingle{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.state == PBOUND_SINGLE)
isdouble{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.state == PBOUND_DOUBLE)
ispreals{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.state == PBOUND_ALLPREALS)

#property coercion
set_empty!{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.state = PBOUND_NULLSET)
set_single!{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.state = PBOUND_SINGLE)
set_double!{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.state = PBOUND_DOUBLE)
set_preals!{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.state = PBOUND_ALLPREALS)

containsinf{lattice, epochbits}(x::PBound{lattice,epochbits}) = x.state == (PBOUND_ALLPREALS) || (x.state == PBOUND_DOUBLE) && (x.upper < x.lower)
function containszero{lattice, epochbits}(x::PBound{lattice,epochbits})
  ((x.state & PBOUND_DOUBLE) == 0) && return false  #traps both allreals and stdbound
  (is_zero(x.lower) || is_zero(x.upper)) && return true

  if containsinf(x)
    ispositive(x.lower) == ispositive(x.upper)
  else
    isnegative(x.lower) && ispositive(x.upper)
  end
end

function isnegative{lattice, epochbits}(x::PBound{lattice, epochbits})
  if issingle(x)
    return isnegative(x.lower)
  elseif isdouble(x)
    return !ispositive(x.lower) && !ispositive(x.upper) && (x.lower < x.upper)
  else
    return false
  end
end

function ispositive{lattice, epochbits}(x::PBound{lattice, epochbits})
  if issingle(x)
    return ispositive(x.lower)
  elseif isdouble(x)
    return !isnegative(x.lower) && !isnegative(x.upper) && (x.lower < x.upper)
  else
    return false
  end
end

export isempty, issingle, isdouble, ispreals, roundsinf, roundszero
