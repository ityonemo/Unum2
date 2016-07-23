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
  m_epoch = max_epoch(epochbits)

  #create the additive reduction table, if necessary.
  #NB THE MORE ACCURATE WAY TO DO THIS IS TO HAVE A FULL ADDITION MATRIX FOR EACH
  #EPOCH REDUCTION, BUT THIS IS THE MORE MEMORY-PERFORMANT WAY TO DO THIS.  IF
  #THE LATTICE DELTA IS NEVER DECREASING, THIS IS ALWAYS GOOD ENOUGH?  MAYBE.

  isdefined(Unum2, additive_reduction_table) || create_adr_table(Val{lattice})
  #create the addition table, if necessary.
  isdefined(Unum2, add_table) || create_addition_table(Val{lattice})
  #figure out how many epochs will reduce to the smallest ulp automatically.
  max_epoch_delta = find_reduction_iterations(Val{lattice})

  quote
    (x_negative, x_inverted, x_epoch, x_value) = decompose(x)
    (y_negative, y_inverted, y_epoch, y_value) = decompose(y)

    #for now, only support adding a non-inverted value to a non-inverted value.
    if (!x_inverted) && (!y_inverted)
      #for now, only support adding things that are in the same epoch.
      if x_epoch > y_epoch
        result_epoch = x_epoch
        epoch_delta = y_epoch - x_epoch
        base_value = x_value
        add_value = reduce_by_epochs(y_value, epoch_delta, Val{lattice})
      else
        result_epoch = y_epoch
        epoch_delta = x_epoch - y_epoch
        base_value = y_value
        add_value = reduce_by_epochs(x_value, epoch_delta, Val{lattice})
      end
      result_value = $add_table[base_value >> 1 + 1, add_value >> 1 + 1]

      (result_value < base_value) && (result_epoch += 1)

      ((result_epoch) > $m_epoch) && return extremum(PFloat{lattice, epochbits}, x_negative, false)

      synthesize(PFloat{lattice, epochbits}, x_negative, false, result_epoch, result_value)
    else
      nothing
    end
  end
end

@generated function reduce_by_epochs{lattice}(value, epochs, ::Type{Val{lattice}})
  additive_reduction_table = Symbol("__$(lattice)_adr_table")
  quote
    (value == z64) && return value
    for idx = 1:epochs
      value = $additive_reduction_table[value]
    end
    return value
  end
end

@generated function create_adr_table{lattice}(::Type{Val{lattice}})
  additive_reduction_table = Symbol("__$(lattice)_adr_table")
  quote
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]

    l = length(lattice_values)

    global const $additive_reduction_table = Vector{UInt64}(l)

    for idx = 1:l
      true_value = 1 + lattice_values[idx] / pivot_value
      $additive_reduction_table[idx] = @i search_lattice(lattice_values, true_value)
    end
  end
end

@generated function find_reduction_iterations{lattice}(::Type{Val{lattice}})
  additive_reduction_table = Symbol("__$(lattice)_adr_table")
  quote
    iterations = 1
    nextval = $additive_reduction_table[end]
    for idx = 1:length($additive_reduction_table)  #this is the absolute maximum size.
      if nextval == one(UInt64)  #look for the smallest ulp bigger than one.
        return iterations
      end
    end
  end
end

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
