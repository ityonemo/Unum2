const sign_mask    = 0x8000_0000_0000_0000
const inv_mask     = 0x4000_0000_0000_0000
const z64          = 0x0000_0000_0000_0000

isnegative{lattice, epochbits}(x::PFloat{lattice, epochbits}) = ((@i x) & (~sign_mask) != 0) & (z64 != (sign_mask & (@i x)))
ispositive{lattice, epochbits}(x::PFloat{lattice, epochbits}) = ((@i x) & (~sign_mask) != 0) & (z64 == (sign_mask & (@i x)))
isinverted{lattice, epochbits}(x::PFloat{lattice, epochbits}) = ((@i x) & (~sign_mask) != 0) & ((z64 != (inv_mask & (@i x))) == (z64 != (sign_mask & (@i x))))
isexact{lattice, epochbits}(x::PFloat{lattice, epochbits}) = (@i x) & incrementor(typeof(x)) == 0
isulp{lattice, epochbits}(x::PFloat{lattice, epochbits}) = (@i x) & incrementor(typeof(x)) != 0

export isnegative, ispositive, isinverted

#pbound properties.

isempty{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.flags == 0x0000)
issingle{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.flags == 0x0001)
isdouble{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.flags == 0x0002)
ispreals{lattice, epochbits}(x::PBound{lattice, epochbits}) = (x.flags == 0x0004)

roundsinf{lattice, epochbits}(x::PBound{lattice,epochbits}) = (x.flags == 0x0002) && (x.upper < x.lower)
function roundszero{lattice, epochbits}(x::PBound{lattice,epochbits})
  (x.flags == 0x0002) || return false
  if roundsinf(x)
    (ispositive(x.lower) && ispositive(x.upper)) || (isnegative(x.lower) && isnegative(x.upper))
  else
    isnegative(x.lower) && ispositive(x.upper)
  end
end

function isnegative{lattice, epochbits}(x::PBound{lattice, epochbits})
  if (x.flags == 0x0001)
    return isnegative(x.lower)
  elseif (x.flags == 0x0002)
    return !ispositive(x.lower) && !ispositive(x.upper) && (x.lower < x.upper)
  else
    return false
  end
end

function ispositive{lattice, epochbits}(x::PBound{lattice, epochbits})
  if (x.flags == 0x0001)
    return ispositive(x.lower)
  elseif (x.flags == 0x0002)
    return !isnegative(x.lower) && !isnegative(x.upper) && (x.lower < x.upper)
  else
    return false
  end
end

export isempty, issingle, isdouble, ispreals, roundsinf, roundszero
