#Unum2 multiplication.
@pfunction function mul(x::PFloat, y::PFloat)
  is_inf(x) && return (is_zero(y) ? R : inf(P))
  is_inf(y) && return (is_zero(x) ? R : inf(P))
  is_zero(x) && return (is_inf(y) ? R : zero(P))
  is_zero(y) && return (is_inf(x) ? R : zero(P))

  if (is_mag_lessthanone(x) $ is_mag_lessthanone(y))
    arithmetic_division(x, y)
  else
    arithmetic_multiplication(x, y)
  end
end

@generated function arithmetic_multiplication{lattice, epochbits}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits})
  mult_table = Symbol("__$(lattice)_mult_table")
  carry_table = Symbol("__$(lattice)_mult_carry_table")
  create_multiplication_table(Val{lattice})
  quote
    epoch_x = evalue(x)
    epoch_y = evalue(y)

    lvalue_x = lvalue(x)
    lvalue_y = lvalue(y)

    if iseven(lvalue_x) && iseven(lvalue_y)
      xidx = lvalue_x >> 1
      yidx = lvalue_y >> 1
      return synthesize($mult_table[xidx, yidx])
    end
  end
end

@generated function create_multiplication_table{lattice}(::Type{Val{lattice}})
  mult_table = Symbol("__$(lattice)_mult_table")
  mult_carry_table = Symbol("__$(lattice)_mult_carry_table")
  quote
    #store the lattice values and the pivot values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $mult_table = Matrix{UInt64}(l, l)
    global const $mult_carry_table = Matrix{Bool}(l, l)
    for idx = 1:l
      for idx2 = 1:l
        true_value = lattice_values[idx] * lattice_values[idx2]
        #first check to see if the true_value corresponds to the pivot value.
        if (true_value >= pivot_value)
          $mult_carry_table[idx, idx2] = true
          true_value /= pivot_value
        else
          $mult_carry_table[idx, idx2] = false
        end
        $mult_table[idx, idx2] = @i search_lattice(lattice_values, true_value)
      end
    end
  end
end
