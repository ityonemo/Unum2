#Unum2 subtraction

import Base.-
-{lattice, epochbits}(x::PTile{lattice, epochbits}, y::PTile{lattice, epochbits}) = sub(x, y, Val{:auto})
-{lattice, epochbits}(x::PTile{lattice, epochbits}) = additiveinverse(x)

function sub{lattice, epochbits, output}(x::PTile{lattice, epochbits}, y::PTile{lattice, epochbits}, OT::Type{Val{output}})
  add(x, -y, OT)
end

function exact_arithmetic_subtraction{lattice, epochbits, output}(x::PTile{lattice, epochbits}, y::PTile{lattice, epochbits}, OT::Type{Val{output}})
  is_zero(x) && return -y
  is_zero(y) && return x
  (x == y) && return zero(PTile{lattice, epochbits})
  #first, we should sort the two numbers into high
  flipped = isnegative(x) $ (x < y)
  (outer, inner) = (flipped) ? (y, x) : (x, y)
  #for now, only support adding a non-inverted value to a non-inverted value.

  o_inverted = isinverted(outer)
  i_inverted = isinverted(inner)

  if (!o_inverted) && (!i_inverted)
    v = exact_arithmetic_subtraction_uninverted(outer, inner, OT)
  elseif (o_inverted) && (i_inverted)
    v = exact_arithmetic_subtraction_inverted(outer, inner, OT)
  else
    v = exact_arithmetic_subtraction_crossed(outer, inner, OT)
  end

  (flipped) ? -v : v
end

bumpup(x) = iseven(x) ? (x + 0x0000_0000_0000_0001) : x
bumpdn(x) = iseven(x) ? (x - 0x0000_0000_0000_0001) : x

lattice_length(l::Symbol) = length(__MASTER_LATTICE_LIST[l])

@generated function invertresult{lattice, output}(value, L::Type{Val{lattice}}, OT::Type{Val{output}})
  inv_table             = table_name(lattice, :inv)
  isdefined(Unum2, inv_table) || create_inversion_table(Val{lattice})
  mval = (lattice_length(lattice) * 2) + 1
  if (output == :lower)  || (output == :inner)
    :(iseven(value) ? $inv_table[value >> 1] :
      x = ((value == $mval) ? one(UInt64) : bumpup($inv_table[value >> 1 + 1])))
  elseif (output == :upper) || (output == :outer)
    :(iseven(value) ? $inv_table[value >> 1] : bumpdn($inv_table[value >> 1]))
  else #__BOUND or __AUTO
    #return a tuple.
    :(iseven(value) ? ($inv_table[value >> 1], $inv_table[value >> 1]) :
      (((value == $mval) ? one(UInt64): bumpup($inv_table[value >> 1 + 1])), bumpdn($inv_table[value >> 1])))
  end
end

@generated function exact_arithmetic_subtraction_uninverted{lattice, epochbits, output}(outer::PTile{lattice, epochbits}, inner::PTile{lattice, epochbits}, OT::Type{Val{output}})
  sub_table             = table_name(lattice, :sub)
  sub_epoch_table       = table_name(lattice, :sub_epoch)

  isdefined(Unum2, sub_table)       || create_subtraction_table(Val{lattice})

  m_epoch = max_epoch(epochbits)
  quote
    (o_negative, o_inverted, o_epoch, o_value) = decompose(outer)
    (i_negative, i_inverted, i_epoch, i_value) = decompose(inner)

    #for now, only support adding things that are in the same epoch.
    if o_epoch == i_epoch
      result_value = $sub_table[o_value >> 1 + 1, i_value >> 1 + 1]
      result_epoch = @s(o_epoch) - @s($sub_epoch_table[o_value >> 1 + 1, i_value >> 1 + 1])
    else
      return nothing #for now.
    end

    result_inverted = false
    #may need to reverse the orientation on the result.
    if (result_epoch < 0)
      result_inverted = true
      result_epoch = (-result_epoch) - 1


      if (OT == __BOUND) || (OT == __AUTO)
        (_l_res, _u_res) = invertresult(result_value, Val{lattice}, OT)
      else
        result_value = invertresult(result_value, Val{lattice}, OT)
      end
    elseif (OT == __BOUND) || (OT == __AUTO)
      _l_res = result_value
      _u_res = result_value
    end

    #check to see if we've gone really small.
    (result_epoch > $m_epoch) && return extremum(PTile{lattice, epochbits}, o_negative, true)

    if (OT == __BOUND) || (OT == __AUTO)
      PBound{lattice, epochbits}(synthesize(PTile{lattice, epochbits}, o_negative, result_inverted, result_epoch, _l_res),
      synthesize(PTile{lattice, epochbits}, o_negative, result_inverted, result_epoch, _u_res))
    else
      synthesize(PTile{lattice, epochbits}, o_negative, result_inverted, result_epoch, result_value)
    end
  end
end

@generated function exact_arithmetic_subtraction_inverted{lattice, epochbits, output}(outer::PTile{lattice, epochbits}, inner::PTile{lattice, epochbits}, OT::Type{Val{output}})

  sub_inv_table         = table_name(lattice, :sub_inv)
  sub_inv_epoch_table   = table_name(lattice, :sub_inv_epoch)

  isdefined(Unum2, sub_inv_table)   || create_inverted_subtraction_table(Val{lattice})

  m_epoch = max_epoch(epochbits)

  quote
    (o_negative, o_inverted, o_epoch, o_value) = decompose(outer)
    (i_negative, i_inverted, i_epoch, i_value) = decompose(inner)

    #for now, only support adding things that are in the same epoch.
    if o_epoch == i_epoch
      result_value = $sub_inv_table[o_value >> 1 + 1, i_value >> 1 + 1]
      result_epoch = @s(o_epoch) + @s($sub_inv_epoch_table[o_value >> 1 + 1, i_value >> 1 + 1])
    else
      return nothing #for now.
    end

    (result_epoch > $m_epoch) && return extremum(PTile{lattice, epochbits}, o_negative, true)

    synthesize(PTile{lattice, epochbits}, o_negative, true, result_epoch, result_value)
  end
end

@generated function exact_arithmetic_subtraction_crossed{lattice, epochbits, output}(outer::PTile{lattice, epochbits}, inner::PTile{lattice, epochbits}, OT::Type{Val{output}})

  #first figure out the epoch reduction limit
  sub_cross_table       = table_name(lattice, :sub_cross)
  sub_cross_epoch_table = table_name(lattice, :sub_cross_epoch)
  inv_table             = table_name(lattice, :inv)


  #create the inversion table table, if necessary.
  isdefined(Unum2, sub_cross_table) || create_crossed_subtraction_table(Val{lattice})
  isdefined(Unum2, inv_table)       || create_inversion_table(Val{lattice})

  m_epoch = max_epoch(epochbits)

  quote
    (o_negative, o_inverted, o_epoch, o_value) = decompose(outer)
    (i_negative, i_inverted, i_epoch, i_value) = decompose(inner)

    result_value = $sub_cross_table[o_value >> 1 + 1, i_value >> 1 + 1]
    result_epoch = - @s($sub_cross_epoch_table[o_value >> 1 + 1, i_value >> 1 + 1])

    result_inverted = false
    #may need to reverse the orientation on the result.
    if (result_epoch < 0)
      result_inverted = true
      result_epoch = (-result_epoch) - 1

      if (OT == __BOUND) || (OT == __AUTO)
        (_l_res, _u_res) = invertresult(result_value, Val{lattice}, OT)
      else
        result_value = invertresult(result_value, Val{lattice}, OT)
      end
    elseif (OT == __BOUND) || (OT == __AUTO)
      _l_res = result_value
      _u_res = result_value
    end

    #check to see if we've gone really small.
    ((result_epoch) > $m_epoch) && return extremum(PTile{lattice, epochbits}, o_negative, true)

    if (OT == __BOUND) || (OT == __AUTO)
      B(synthesize(PTile{lattice, epochbits}, o_negative, result_inverted, result_epoch, _l_res),
      synthesize(PTile{lattice, epochbits}, o_negative, result_inverted, result_epoch, _u_res))
    else
      synthesize(PTile{lattice, epochbits}, o_negative, result_inverted, result_epoch, result_value)
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


@generated function create_inverted_subtraction_table{lattice}(::Type{Val{lattice}})
  sub_inv_table = Symbol("__$(lattice)_sub_inv_table")
  sub_inv_epoch_table = Symbol("__$(lattice)_sub_inv_epoch_table")
  #we need two tables, the subtraction table and the subtraction epoch table.
  quote
    #store the lattice values and the pivot values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $sub_inv_table = Matrix{UInt64}(l + 1, l + 1)
    global const $sub_inv_epoch_table = Matrix{UInt64}(l + 1, l + 1)

    for idx = 0:l, idx2 = 0:l
      if (idx < idx2)
        true_value = 1/(((idx == 0) ? 1 : 1/lattice_values[idx]) - ((idx2 == 0) ? 1 : 1/lattice_values[idx2]))
        #decompose the result into an epoch and a
        (epoch_delta, true_value) = search_epochs(true_value, pivot_value)
        $sub_inv_table[idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
        $sub_inv_epoch_table[idx + 1, idx2 + 1] = @i epoch_delta
      else
        $sub_inv_table[idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
        $sub_inv_epoch_table[idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
      end
    end
  end
end

@generated function create_crossed_subtraction_table{lattice}(::Type{Val{lattice}})
  sub_cross_table       = table_name(lattice, :sub_cross)
  sub_cross_epoch_table = table_name(lattice, :sub_cross_epoch)
  #we need two tables, the subtraction table and the subtraction epoch table.
  quote
    #store the lattice values and the pivot values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $sub_cross_table = Matrix{UInt64}(l + 1, l + 1)
    global const $sub_cross_epoch_table = Matrix{UInt64}(l + 1, l + 1)

    for idx = 0:l, idx2 = 0:l
      if (idx == 0) && (idx2 == 0)
        $sub_cross_table[idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
        $sub_cross_epoch_table[idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
      else
        true_value = ((idx == 0) ? 1 : lattice_values[idx]) -
                     ((idx2 == 0) ? 1 : 1/lattice_values[idx2])
        #decompose the result into an epoch and a
        (epoch_delta, true_value) = search_epochs(true_value, pivot_value)
        $sub_cross_table[idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
        $sub_cross_epoch_table[idx + 1, idx2 + 1] = @i epoch_delta
      end
    end
  end
end
