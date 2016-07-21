const sign_mask    = 0x8000_0000_0000_0000
const inv_mask     = 0x4000_0000_0000_0000
const z64          = 0x0000_0000_0000_0000

isnegative(x::PFloat) = ((@i x) & (~sign_mask) != 0) & (z64 != (sign_mask & (@i x)))
isinverted(x::PFloat) = ((@i x) & (~sign_mask) != 0) & ((z64 != (inv_mask & (@i x))) == (z64 != (sign_mask & (@i x))))

export isnegative, isinverted
