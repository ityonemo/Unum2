#Unum2 subtraction

import Base.-
-{lattice, epochbits}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits}) = sub(x,y)
-{lattice, epochbits}(x::PFloat{lattice, epochbits}) = additiveinverse(x)

@pfunction function sub(x::PFloat, y::PFloat)
  is_inf(x) && return inf(P)
  is_inf(y) && return inf(P)
  is_zero(x) && return -(y)
  is_zero(y) && return x

  if isexact(x) & isexact(y)
    exact_sub(x, y)
  else
    return nothing
    #inexact_sub(x, y)
  end
end

@pfunction function exact_sub(x::PFloat, y::PFloat)
  if (isnegative(x) $ isnegative(y))
    return exact_arithmetic_addition(x, -(y))
  else
    exact_arithmetic_subtraction(x, y)
  end
end

@generated function exact_arithmetic_subtraction{lattice, epochbits}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits})
  #first figure out the epoch reduction limit
  sub_table = Symbol("__$(lattice)_sub_table")
  sub_epoch_table = Symbol("__$(lattice)_sub_epoch_table")
  inv_table = Symbol("__$(lattice)_inv_table")
  m_epoch = max_epoch(epochbits)

  #create the inversion table table, if necessary.
  isdefined(Unum2, inv_table) || create_inversion_table(Val{lattice})

  isdefined(Unum2, sub_table) || create_subtraction_table(Val{lattice})
  #isdefined(Unum2, sub_epoch_table) || create_inverted_addition_table(Val{lattice})

  quote
    #first, we should sort the two numbers into higher and lower.
    println("hey, $x, $y.")
    if x == y
      return zero(PFloat{lattice, epochbits})
    else
      (h, l) = (x > y) ? (x, y) : (y, x)
    end

    (h_negative, h_inverted, h_epoch, h_value) = decompose(h)
    (l_negative, l_inverted, l_epoch, l_value) = decompose(l)

    result_epoch::Int64
    #for now, only support adding a non-inverted value to a non-inverted value.
    if (!h_inverted) && (!l_inverted)
      #for now, only support adding things that are in the same epoch.
      if h_epoch == l_epoch

        println(h_value >> 1 + 1, "-" , l_value >> 1 + 1)

        result_value = $sub_table[h_value >> 1 + 1, l_value >> 1 + 1]
        result_epoch = @s(h_epoch) - @s($sub_epoch_table[h_value >> 1 + 1, l_value >> 1 + 1])

        println("result_value: $result_value")
        println("result_epoch: $result_epoch")
      else
        return nothing #for now.
        #(result_value, result_epoch) = (x_epoch > y_epoch) ? add_unequal_epoch(x, y) : add_unequal_epoch(y, x)
      end

      #may need to reverse the orientation on the result.
      if (result_epoch < 0)
        result_inverted = !h_inverted
        result_epoch = (-result_epoch) - 1

        println("result value: $(hex(result_value))")

        result_value = $inv_table[result_value >> 1]
      end

      ((result_epoch) > $m_epoch) && return extremum(PFloat{lattice, epochbits}, x_negative, false)

      synthesize(PFloat{lattice, epochbits}, h_negative, false, result_epoch, result_value)
    else
      return nothing # for now.
      #=
      if (x_epoch == y_epoch)
        result_value = $add_inv_table[x_value >> 1  + 1, y_value >> 1 + 1]
        result_epoch = (result_value > x_value) ? (x_epoch - 1) : x_epoch
      else
        return nothing # for now.
      end
      =#
      #x_epoch needs to be an Int64

      #synthesize(PFloat{lattice, epochbits}, x_negative, false, result_epoch, result_value)
    end
  end
end

################################################################################
# SUBTRACTION TABLES

function search_epochs(true_value, pivot_value)
  (true_value <= 0.0) && throw(ArgumentError("error ascertaining epoch for value $true_value"))
  epoch_delta = 0
  while (true_value < 1.0)
    true_value *= pivot_value
    epoch_delta += 1
  end
  return (epoch_delta, true_value)
end


@generated function create_subtraction_table{lattice}(::Type{Val{lattice}})
  sub_table = Symbol("__$(lattice)_sub_table")
  sub_epoch_table = Symbol("__$(lattice)_sub_epoch_table")
  #we need two tables, the subtraction table and the subtraction epoch table.
  quote
    #store the lattice values and the pivot values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $sub_table = Matrix{UInt64}(l + 1, l + 1)
    global const $sub_epoch_table = Matrix{UInt64}(l + 1, l + 1)

    for idx = 0:l, idx2 = 0:l
      if (idx > idx2)
        true_value = ((idx == 0) ? 1 : lattice_values[idx]) -
                     ((idx2 == 0) ? 1 : lattice_values[idx2])
        #decompose the result into an epoch and a
        (epoch_delta, true_value) = search_epochs(true_value, pivot_value)
        $sub_table[idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
        $sub_epoch_table[idx + 1, idx2 + 1] = @i epoch_delta
      else
        $sub_table[idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
        $sub_epoch_table[idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
      end
    end
  end
end
