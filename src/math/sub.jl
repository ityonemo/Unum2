#sub.jl -- Unum2 subtration.
#impmements the following:
#  - Operator overloading.
#  PBound subtraction.
#  Subtraction algorithms.
#  Subtraction table generation.

import Base.-

################################################################################
# OPERATOR OVERLOADING
################################################################################

@pfunction function -(lhs::PBound, rhs::PBound)
  #encapuslates calling the more efficient "add" function, which does not need
  #to allocate memory.
  res::B = copy(rhs)
  additiveinverse!(res)
  add!(res, lhs)
  res
end

@pfunction function -(x::PBound)
  res::B = copy(x)
  additiveinverse!(res)
  res
end

#we allow the (-) operator for PTiles because there is no memory overhead.
@pfunction function -(x::PTile)
  additiveinverse(x)
end

################################################################################
# PBOUND SUBTRACTION
################################################################################

doc"""
  `Unum2.sub!(res::PBound, lhs::PBound, rhs::PBound)`  Takes two input values,
  lhs and rhs and subtracts them together into the memory slot allocated by res.
"""

@pfunction function sub!(res::PBound, lhs::PBound, rhs::PBound)
  copy!(res, rhs)
  additiveinverse!(res)
  add!(res, rhs)
  nothing
end

################################################################################
# ALGORITHMIC SUBTRACTION
################################################################################

function exact_algorithmic_subtraction{lattice, epochbits, output}(x::PTile{lattice, epochbits}, y::PTile{lattice, epochbits}, OT::Type{Val{output}})
  (x == y) && return zero(PTile{lattice, epochbits})

  #first, we should sort the two numbers into high
  flipped = isnegative(x) $ (x < y)
  (outer, inner) = (flipped) ? (y, x) : (x, y)
  #for now, only support adding a non-inverted value to a non-inverted value.

  big = decompose(outer)
  sml = decompose(inner)

  res::__dc_tile = big

  if is_uninverted(big) && is_uninverted(sml) #sub a non-inverted value from a non-inverted value.
    (invert, res.epoch, res.lvalue) = uninverted_subtraction_decomposed(big, sml, Val{lattice}, OT)
    invert && set_inverted!(res)
  elseif (is_inverted(big) && is_inverted(sml))   #sub an inverted value from an inverted value.
    (res.epoch, res.lvalue) = inverted_subtraction_decomposed(big, sml, Val{lattice}, OT)
  else
    (invert, res.epoch, res.lvalue) = crossed_subtraction_decomposed(big, sml, Val{lattice}, OT)
    invert && set_inverted!(res)
  end

  v = synthesize(PTile{lattice, epochbits}, res)

  (flipped) ? -v : v
end

lattice_length(l::Symbol) = length(__MASTER_LATTICE_LIST[l])

@generated function uninverted_subtraction_decomposed{lattice, output}(big::__dc_tile, sml::__dc_tile,  L::Type{Val{lattice}}, OT::Type{Val{output}})
  sub_table             = table_name(lattice, :sub)
  sub_epoch_table       = table_name(lattice, :sub_epoch)
  isdefined(Unum2, sub_table)       || create_uninverted_subtraction_tables(Val{lattice})
  quote
    #for now, only support adding things that are in the same epoch.
    if big.epoch == sml.epoch
      res_lvalue = $sub_table[big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
      res_epoch = @s(big.epoch) - @s($sub_epoch_table[big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1])
    else
      return nothing #for now.
    end

    #may need to reverse the orientation on the result.
    res_inverted = false
    if (res_epoch < 0)
      res_inverted = true
      res_epoch = (-res_epoch) - 1
      res_lvalue = lattice_invert(res_lvalue, Val{lattice}, OT)
    end

    (res_inverted, res_epoch, res_lvalue)
  end
end

@generated function inverted_subtraction_decomposed{lattice, output}(big::__dc_tile, sml::__dc_tile, L::Type{Val{lattice}},  OT::Type{Val{output}})
  sub_inv_table         = table_name(lattice, :sub_inv)
  sub_inv_epoch_table   = table_name(lattice, :sub_inv_epoch)
  isdefined(Unum2, sub_inv_table)   || create_inverted_subtraction_tables(Val{lattice})
  quote
    #for now, only support adding things that are in the same epoch.
    if big.epoch == sml.epoch
      res_lvalue = $sub_inv_table[big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
      res_epoch = @s(big.epoch) + @s($sub_inv_epoch_table[big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1])
    else
      return nothing #for now.
    end

    (res_epoch, res_lvalue)
  end
end

@generated function crossed_subtraction_decomposed{lattice, output}(big::__dc_tile, sml::__dc_tile, L::Type{Val{lattice}},  OT::Type{Val{output}})

  #first figure out the epoch reduction limit
  sub_cross_table       = table_name(lattice, :sub_cross)
  sub_cross_epoch_table = table_name(lattice, :sub_cross_epoch)
  #create the inversion table table, if necessary.
  isdefined(Unum2, sub_cross_table) || create_crossed_subtraction_tables(Val{lattice})

  quote
    if (big.epoch == sml.epoch == 0)
      res_lvalue = $sub_cross_table[big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
      res_epoch = - @s($sub_cross_epoch_table[big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1])
    end

    res_inverted = false
    #we may need to reverse the orientation here.
    if (res_epoch < 0)
      res_inverted = true
      res_epoch = (-res_epoch) - 1
      res_lvalue = lattice_invert(res_lvalue, Val{lattice}, OT)
    end

    (res_inverted, res_epoch, res_lvalue)
  end
end

################################################################################
# LATTICE INVERSION
################################################################################

bumpup(x) = iseven(x) ? (x + 0x0000_0000_0000_0001) : x
bumpdn(x) = iseven(x) ? (x - 0x0000_0000_0000_0001) : x

@generated function lattice_invert{lattice, output}(value, L::Type{Val{lattice}}, OT::Type{Val{output}})
  inv_table             = table_name(lattice, :inv)
  isdefined(Unum2, inv_table) || create_inversion_table(Val{lattice})
  mval = (lattice_length(lattice) * 2) + 1
  if (output == :lower)  || (output == :inner)
    :(iseven(value) ? $inv_table[value >> 1] :
      x = ((value == $mval) ? one(UInt64) : bumpup($inv_table[value >> 1 + 1])))
  elseif (output == :upper) || (output == :outer)
    :(iseven(value) ? $inv_table[value >> 1] : bumpdn($inv_table[value >> 1]))
  end
end

################################################################################
# SUBTRACTION TABLES

function search_epochs(true_value, stride_value)
  (true_value <= 0.0) && throw(ArgumentError("error ascertaining epoch for value $true_value"))
  epoch_delta = 0
  while (true_value < 1.0)
    true_value *= stride_value
    epoch_delta += 1
  end
  return (epoch_delta, true_value)
end

@generated function create_uninverted_subtraction_tables{lattice}(::Type{Val{lattice}})
  sub_table       = table_name(lattice, :sub)
  sub_epoch_table = table_name(lattice, :sub_epoch)
  #we need two tables, the subtraction table and the subtraction epoch table.
  quote
    #store the lattice values and the stride values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    stride_value = __MASTER_STRIDE_LIST[lattice]
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
        (epoch_delta, true_value) = search_epochs(true_value, stride_value)
        $sub_table[idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
        $sub_epoch_table[idx + 1, idx2 + 1] = @i epoch_delta
      else
        $sub_table[idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
        $sub_epoch_table[idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
      end
    end
  end
end


@generated function create_inverted_subtraction_tables{lattice}(::Type{Val{lattice}})
  sub_inv_table       = table_name(lattice, :sub_inv)
  sub_inv_epoch_table = table_name(lattice, :sub_inv_epoch)
  #we need two tables, the subtraction table and the subtraction epoch table.
  quote
    #store the lattice values and the stride values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    stride_value = __MASTER_STRIDE_LIST[lattice]
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
        (epoch_delta, true_value) = search_epochs(true_value, stride_value)
        $sub_inv_table[idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
        $sub_inv_epoch_table[idx + 1, idx2 + 1] = @i epoch_delta
      else
        $sub_inv_table[idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
        $sub_inv_epoch_table[idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
      end
    end
  end
end

@generated function create_crossed_subtraction_tables{lattice}(::Type{Val{lattice}})
  sub_cross_table       = table_name(lattice, :sub_cross)
  sub_cross_epoch_table = table_name(lattice, :sub_cross_epoch)
  #we need two tables, the subtraction table and the subtraction epoch table.
  quote
    #store the lattice values and the stride values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    stride_value = __MASTER_STRIDE_LIST[lattice]
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
        (epoch_delta, true_value) = search_epochs(true_value, stride_value)
        $sub_cross_table[idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
        $sub_cross_epoch_table[idx + 1, idx2 + 1] = @i epoch_delta
      end
    end
  end
end


@generated function create_inversion_table{lattice}(::Type{Val{lattice}})
  inv_table = table_name(lattice, :inv)
  quote
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    stride_value = __MASTER_STRIDE_LIST[lattice]
    l = length(lattice_values)

    #actually allocate the memory for the inversion table.
    global const $inv_table = Vector{UInt64}(l)

    for idx = 1:l
      true_value = stride_value / lattice_values[idx]
      $inv_table[idx] = @i search_lattice(lattice_values, true_value)
    end
  end
end
