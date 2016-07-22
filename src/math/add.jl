#Unum2 addition.

import Base.+
+{lattice, epochbits}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits}) = add(x,y)

#adds two numbers x, y
@pfunction function add(x::PFloat, y::PFloat)

  is_inf(x) && return inf(P)
  is_inf(y) && return inf(P)
  is_zero(x) && return y
  is_zero(y) && return x

  if isexact(x) & isexact(y)
    exact_add(x, y)
  else
    return nothing
    #inexact_mul(x, y)
  end
end

@pfunction function exact_add(x::PFloat, y::PFloat)
  if (isnegative(x) $ isnegative(y))
    return nothing
    #exact_arithmetic_subtraction(x, y)
  else
    exact_arithmetic_addition(x, y)
  end
end

@generated function exact_arithmetic_addition{lattice, epochbits}(x, y)
  #first figure out the epoch reduction limit
end
