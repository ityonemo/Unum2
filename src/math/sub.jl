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
  res::B = emptyset(B)
  copy!(res, rhs)
  additiveinverse!(res)
  add!(res, lhs)
  res
end

@pfunction function -(x::PBound)
  res::B = emptyset(B)
  copy!(res, x)
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

function exact_algorithmic_subtraction{lattice}(big::__dc_tile, sml::__dc_tile,  L::Type{Val{lattice}})
  #first, we should sort the two numbers into high
  res::__dc_tile = big

  if is_uninverted(big) && is_uninverted(sml) #sub a non-inverted value from a non-inverted value.
    (invert, res.epoch, res.lvalue) = uninverted_subtraction_decomposed(big, sml, Val{lattice})
    invert && set_inverted!(res)
  elseif (is_inverted(big) && is_inverted(sml))   #sub an inverted value from an inverted value.
    (res.epoch, res.lvalue) = inverted_subtraction_decomposed(big, sml, Val{lattice})
  else
    (invert, res.epoch, res.lvalue) = crossed_subtraction_decomposed(big, sml, Val{lattice})
    invert && set_inverted!(res)
  end

  res
end

lattice_length(l::Symbol) = length(__MASTER_LATTICE_LIST[l])

@generated function uninverted_subtraction_decomposed{lattice}(big::__dc_tile, sml::__dc_tile,  L::Type{Val{lattice}})
  sub_table             = table_name(lattice, :sub)
  inv_sub_table         = table_name(lattice, :inv_sub)
  sub_epoch_table       = table_name(lattice, :sub_epoch)
  isdefined(Unum2, sub_table)       || create_uninverted_subtraction_tables(Val{lattice})
  max_lvalue = (length(__MASTER_LATTICE_LIST[lattice]) << 1) + 1
  quote

    #NB:  move this to be a precompiled value instead of a calculated value.
    cells = size($sub_table, 1)
    lookup_cell = big.epoch - sml.epoch + 1

    #in the case that we don't have enough cells to cover this, we simply
    #bump down the value to the next lower ulp.
    if lookup_cell > cells

      res_inverted = false

      if (big.lvalue == 0)
        if (big.epoch == 0)
          res_inverted = true
          res_epoch = 0
          res_lvalue = one(UT_Int)
        else
          res_epoch = big.epoch - 1
          res_lvalue = $max_lvalue
        end
      else
        res_epoch = big.epoch
        res_lvalue = big.lvalue - 1
      end

      return (res_inverted, res_epoch, res_lvalue)
    end

    res_epoch = @s(big.epoch) - $sub_epoch_table[lookup_cell, big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]

    res_inverted = res_epoch < 0

    if res_inverted
      res_epoch = (-res_epoch) - 1

      res_lvalue = $inv_sub_table[lookup_cell, big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
    else
      res_lvalue = $sub_table[lookup_cell, big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
    end

    (res_inverted, res_epoch, res_lvalue)
  end
end

@generated function inverted_subtraction_decomposed{lattice}(big::__dc_tile, sml::__dc_tile, L::Type{Val{lattice}})
  sub_inv_table         = table_name(lattice, :sub_inv)
  sub_inv_epoch_table   = table_name(lattice, :sub_inv_epoch)
  isdefined(Unum2, sub_inv_table)   || create_inverted_subtraction_tables(Val{lattice})
  quote
    #NB:  move this to be a precompiled value instead of a calculated value.
    cells = size($sub_inv_table, 1)
    lookup_cell = sml.epoch - big.epoch + 1

    if lookup_cell <= cells
      res_lvalue = $sub_inv_table[lookup_cell, big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
      res_epoch = big.epoch + $sub_inv_epoch_table[lookup_cell, big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
    else
      res_epoch = big.epoch
      res_lvalue = big.lvalue + 1
    end

    (res_epoch, res_lvalue)
  end
end

@generated function crossed_subtraction_decomposed{lattice}(big::__dc_tile, sml::__dc_tile, L::Type{Val{lattice}})

  #first figure out the epoch reduction limit
  sub_cross_table       = table_name(lattice, :sub_cross)
  inv_sub_cross_table   = table_name(lattice, :inv_sub_cross)
  sub_cross_epoch_table = table_name(lattice, :sub_cross_epoch)
  #create the inversion table table, if necessary.
  isdefined(Unum2, sub_cross_table) || create_crossed_subtraction_tables(Val{lattice})
  max_lvalue = (length(__MASTER_LATTICE_LIST[lattice]) << 1) + 1

  quote
    #NB:  move this to be a precompiled value instead of a calculated value.
    cells = size($sub_cross_table, 1)
    lookup_cell = big.epoch + sml.epoch + 1

    #in the case that we don't have enough cells to cover this, we simply
    #bump down the value to the next lower ulp.
    if lookup_cell > cells
      res_inverted = false

      if (big.lvalue == 0)
        if (big.epoch == 0)
          res_inverted = true
          res_epoch = 0
          res_lvalue = one(UT_Int)
        else
          res_epoch = big.epoch - 1
          res_lvalue = $max_lvalue
        end
      else
        res_epoch = big.epoch
        res_lvalue = big.lvalue - 1
      end

      return (res_inverted, res_epoch, res_lvalue)
    end

    res_epoch = @s(big.epoch) - $sub_cross_epoch_table[lookup_cell, big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]

    res_inverted = res_epoch < 0

    if res_inverted
      res_epoch = (-res_epoch) - 1

      res_lvalue = $inv_sub_cross_table[lookup_cell, big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
    else
      res_lvalue = $sub_cross_table[lookup_cell, big.lvalue >> 1 + 1, sml.lvalue >> 1 + 1]
    end

    (res_inverted, res_epoch, res_lvalue)
  end
end

################################################################################
# SUBTRACTION TABLES

doc"""
  Unum2.search_epochs(value, stride)

  takes a value from (0 stride) and normalizes it to the range [1 stride) with
  an associated number of epochs to bring it to that range.
"""
function search_epochs(true_value, stride_value)
  (true_value <= 0.0) && throw(ArgumentError("error ascertaining epoch for value $true_value, cannot be negative"))
  (true_value >= stride_value) && throw(ArgumentError("error ascertaining epoch for value $true_value, cannot be greater than stride $stride_value"))

  epoch_delta = 0
  while (true_value < 1.0)

    true_value *= stride_value
    epoch_delta += 1
  end
  return (epoch_delta, true_value)
end
doc"""
  Unum2.search_epochs_inverted(value, stride)
  takes a value in (0 1) and normalizes it to the range [1 stride) with an
  associated number of epochs to bring it to that range.  Also inverts the
  result to make it easily interpretable.
"""
function search_epochs_inverted(true_value, stride_value)
  (true_value <= 0.0) && throw(ArgumentError("error ascertaining epoch for value $true_value, cannot be negative"))
  (true_value >= 1.0) && throw(ArgumentError("error ascertaining epoch for value $true_value, cannot be greater than 1"))

  epoch_delta = 0
  while (true_value < 1/stride_value)
    true_value *= stride_value
    epoch_delta += 1
  end
  if (true_value == 1/stride_value)
    return (1, 1)
  else
    return (epoch_delta, 1/true_value)
  end
end

@generated function create_uninverted_subtraction_tables{lattice}(::Type{Val{lattice}})
  sub_table       = table_name(lattice, :sub)
  sub_epoch_table = table_name(lattice, :sub_epoch)
  inv_sub_table   = table_name(lattice, :inv_sub)
  #we need two tables, the subtraction table and the subtraction epoch table.
  quote
    cells = count_uninverted_subtraction_cells(Val{lattice}) + 1

    #store the lattice values and the stride values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    stride_value = __MASTER_STRIDE_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $sub_table = Array(UT_Int, cells, l + 1, l + 1)
    global const $inv_sub_table = Array(UT_Int, cells, l + 1, l + 1)
    global const $sub_epoch_table = Array(ST_Int, cells, l + 1, l + 1)

    for sub_cell = 1:cells
      populate_uninverted_subtraction_table!($sub_table, $inv_sub_table, $sub_epoch_table, lattice_values, stride_value, sub_cell - 1)
    end
  end
end

function populate_uninverted_subtraction_table!(table, inv_table, epoch_table, lattice_values, stride_value, epoch_delta)
  l = length(lattice_values)
  power_factor = stride_value ^ epoch_delta

  for idx = 0:l, idx2 = 0:l
    if (epoch_delta != 0) || (idx > idx2)
      true_value = (power_factor * ((idx == 0) ? 1 : lattice_values[idx])) -
                   ((idx2 == 0) ? 1 : lattice_values[idx2])
      #decompose the result into an epoch and a
      (res_epoch_delta, true_value) = search_epochs(true_value / power_factor, stride_value)
      table[epoch_delta + 1, idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
      inv_table[epoch_delta + 1, idx + 1, idx2 + 1] = @i search_lattice(lattice_values, stride_value / true_value)
      epoch_table[epoch_delta + 1, idx + 1, idx2 + 1] = @s res_epoch_delta
    else
      table[1, idx + 1, idx2 + 1]       = @i -1
      inv_table[1, idx + 1, idx2 + 1]   = @i -1
      epoch_table[1, idx + 1, idx2 + 1] = @s -1
    end
  end
end


@generated function create_inverted_subtraction_tables{lattice}(::Type{Val{lattice}})
  sub_inv_table       = table_name(lattice, :sub_inv)
  sub_inv_epoch_table = table_name(lattice, :sub_inv_epoch)
  #we need two tables, the subtraction table and the subtraction epoch table.
  quote
    sub_inv_cells = count_inverted_subtraction_cells(Val{lattice}) + 1

    #store the lattice values and the stride values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    stride_value = __MASTER_STRIDE_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $sub_inv_table = Array(UT_Int, sub_inv_cells, l + 1, l + 1)
    global const $sub_inv_epoch_table = Array(ST_Int, sub_inv_cells, l + 1, l + 1)

    for sub_inv_cell = 1:sub_inv_cells
      populate_inverted_subtraction_table!($sub_inv_table, $sub_inv_epoch_table, lattice_values, stride_value, sub_inv_cell - 1)
    end
  end
end

function populate_inverted_subtraction_table!(table, epoch_table, lattice_values, stride_value, epoch_delta)
  l = length(lattice_values)
  power_factor = stride_value ^ epoch_delta
  for idx = 0:l, idx2 = 0:l
    if (epoch_delta == 0) && (idx >= idx2)
      table[1, idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
      epoch_table[1, idx + 1, idx2 + 1] = @s 0xFFFF_FFFF_FFFF_FFFF
    else
      base_value = ((idx == 0) ? power_factor : (power_factor/lattice_values[idx]))
      sub_value = ((idx2 == 0) ? 1 : (1 / lattice_values[idx2]))

      true_value = base_value - sub_value

      (res_epoch_delta, search_value) = search_epochs_inverted(true_value / power_factor, stride_value)
      table[epoch_delta + 1, idx + 1, idx2 + 1] = tr = @i search_lattice(lattice_values, search_value)
      epoch_table[epoch_delta + 1, idx + 1, idx2 + 1] = etr = @s res_epoch_delta
    end
  end
end

@generated function create_crossed_subtraction_tables{lattice}(::Type{Val{lattice}})
  sub_cross_table       = table_name(lattice, :sub_cross)
  inv_sub_cross_table   = table_name(lattice, :inv_sub_cross)
  sub_cross_epoch_table = table_name(lattice, :sub_cross_epoch)
  #we need two tables, the subtraction table and the subtraction epoch table.
  quote
    sub_cross_cells = count_crossed_subtraction_cells(Val{lattice}) + 1

    #store the lattice values and the stride values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    stride_value = __MASTER_STRIDE_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $sub_cross_table = Array(UT_Int, sub_cross_cells, l + 1, l + 1)
    global const $inv_sub_cross_table = Array(UT_Int, sub_cross_cells, l + 1, l + 1)
    global const $sub_cross_epoch_table = Array(ST_Int, sub_cross_cells, l + 1, l + 1)

    for sub_cross_cell = 1:sub_cross_cells
      populate_crossed_subtraction_table!($sub_cross_table, $inv_sub_cross_table, $sub_cross_epoch_table, lattice_values, stride_value, sub_cross_cell - 1)
    end
  end
end

function populate_crossed_subtraction_table!(table, inv_table, epoch_table, lattice_values, stride_value, epoch_delta)
  l = length(lattice_values)
  power_factor = stride_value ^ epoch_delta

  for idx = 0:l, idx2 = 0:l

    if (epoch_delta == 0) && (idx == 0) && (idx2 == 0)
      table[1, idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
      inv_table[1, idx + 1, idx2 + 1] = 0xFFFF_FFFF_FFFF_FFFF
      epoch_table[1, idx + 1, idx2 + 1] = @s 0xFFFF_FFFF_FFFF_FFFF
    else
      true_value = (power_factor * ((idx == 0) ? 1 : lattice_values[idx])) -
                   ((idx2 == 0) ? 1 : 1/lattice_values[idx2])
      #decompose the result into an epoch and a
      (res_epoch_delta, true_value) = search_epochs(true_value / power_factor, stride_value)
      table[epoch_delta + 1, idx + 1, idx2 + 1] = @i search_lattice(lattice_values, true_value)
      inv_table[epoch_delta + 1, idx + 1, idx2 + 1] = @i search_lattice(lattice_values, stride_value / true_value)
      epoch_table[epoch_delta + 1, idx + 1, idx2 + 1] = @s res_epoch_delta
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
