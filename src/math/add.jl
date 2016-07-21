#Unum2 addition.

#adds two numbers x, y
function add{lattice, epochbits}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits})

  is_inf(x) && return inf(P)
  is_inf(y) && return inf(P)
  is_zero(x) && return y
  is_zero(y) && return x

  if (is_positive(x) $ is_positive(y))
    (outer, inner) = mag_sort(x, y)
    arithmetic_subtract(outer, inner)
  else
    (outer, inner) = mag_sort(x, y)
    arithmetic_addition(outer, inner)
  end
end
