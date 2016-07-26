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

@generated function exact_arithmetic_addition{lattice, epochbits}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits})
  #first figure out the epoch reduction limit
  additive_reduction_table = Symbol("__$(lattice)_adr_table")
  add_table = Symbol("__$(lattice)_add_table")
  add_inv_table = Symbol("__$(lattice)_add_inv_table")
  m_epoch = max_epoch(epochbits)

  #create the additive reduction table, if necessary.
  #NB THE MORE ACCURATE WAY TO DO THIS IS TO HAVE A FULL ADDITION MATRIX FOR EACH
  #EPOCH REDUCTION, BUT THIS IS THE MORE MEMORY-PERFORMANT WAY TO DO THIS.  IF
  #THE LATTICE DELTA IS NEVER DECREASING, THIS IS ALWAYS GOOD ENOUGH?  MAYBE.
  #create the addition table, if necessary.

  isdefined(Unum2, add_table) || create_addition_table(Val{lattice})
  isdefined(Unum2, add_inv_table) || create_inverted_addition_table(Val{lattice})

  quote
    (x_negative, x_inverted, x_epoch, x_value) = decompose(x)
    (y_negative, y_inverted, y_epoch, y_value) = decompose(y)

    result_epoch::Int64

    #for now, only support adding a non-inverted value to a non-inverted value.
    if (!x_inverted) && (!y_inverted)
      #for now, only support adding things that are in the same epoch.
      if x_epoch == y_epoch
        result_value = $add_table[x_value >> 1 + 1, y_value >> 1 + 1]
        result_epoch = (result_value < x_value) ? (x_epoch + 1) : x_epoch
      else
        return nothing #for now.
        #(result_value, result_epoch) = (x_epoch > y_epoch) ? add_unequal_epoch(x, y) : add_unequal_epoch(y, x)
      end

      ((result_epoch) > $m_epoch) && return extremum(PFloat{lattice, epochbits}, x_negative, false)

      synthesize(PFloat{lattice, epochbits}, x_negative, false, result_epoch, result_value)
    else
      if (x_epoch == y_epoch)
        result_value = $add_inv_table[x_value >> 1  + 1, y_value >> 1 + 1]
        result_epoch = (result_value > x_value) ? (x_epoch - 1) : x_epoch
      else
        return nothing # for now.
      end

      #x_epoch needs to be an Int64

      synthesize(PFloat{lattice, epochbits}, x_negative, false, result_epoch, result_value)
    end
  end
end

################################################################################
# ADDITION TABLES

@generated function create_addition_table{lattice}(::Type{Val{lattice}})
  add_table = Symbol("__$(lattice)_add_table")
  quote
    #store the lattice values and the pivot values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $add_table = Matrix{UInt64}(l + 1, l + 1)

    for idx = 0:l
      for idx2 = 0:l
        true_value = ((idx == 0) ? 1 : lattice_values[idx]) +
                     ((idx2 == 0) ? 1 : lattice_values[idx2])
        #first check to see if the true_value corresponds to the pivot value.
        (true_value >= pivot_value) && (true_value /= pivot_value)

        $add_table[idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
      end
    end
  end
end

@generated function create_inverted_addition_table{lattice}(::Type{Val{lattice}})
  add_inv_table = Symbol("__$(lattice)_add_inv_table")
  quote
    #store the lattice values and the pivot values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $add_inv_table = Matrix{UInt64}(l + 1, l + 1)

    for idx = 0:l
      for idx2 = 0:l
        true_value = 1/(((idx == 0) ? 1 : 1/lattice_values[idx]) +
                     ((idx2 == 0) ? 1 : 1/lattice_values[idx2]))
        #first check to see if the true_value corresponds to the pivot value.
        (true_value >= pivot_value) && (true_value /= pivot_value)

        $add_inv_table[idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
      end
    end
  end
end
