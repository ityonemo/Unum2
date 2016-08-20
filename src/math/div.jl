#Unum2 multiplication.

import Base./
/{lattice, epochbits}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits}) = div(x, y, Val{:auto})
/{lattice, epochbits}(x::PFloat{lattice, epochbits}) = multiplicativeinverse(x)

function div{lattice, epochbits, output}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits}, OT::Type{Val{output}})
  mul(x, /(y), OT)
end

@generated function exact_arithmetic_division{lattice, epochbits, output}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits}, OT::Type{Val{output}})

  #note that parameters passed to this function will always be pointing in the
  #same direction (out or in) relative to one.

  div_table = Symbol("__$(lattice)_div_table")
  inv_table = Symbol("__$(lattice)_inv_table")
  m_epoch = max_epoch(epochbits)

  #create the multiplication table, if necessary.
  isdefined(Unum2, div_table) || create_division_table(Val{lattice})
  isdefined(Unum2, inv_table) || create_inversion_table(Val{lattice})
  quote
    is_inf(x) && return inf(PFloat{lattice, epochbits})
    is_inf(y) && return zero(PFloat{lattice, epochbits})
    is_zero(x) && return zero(PFloat{lattice, epochbits})
    is_zero(y) && return inf(PFloat{lattice, epochbits})
    is_one(x) && return /(y)
    is_one(y) && return x
    is_neg_one(x) && return -(/(y))
    is_neg_one(y) && return -x

    (x_negative, x_inverted, x_epoch, x_value) = decompose(x)
    (y_negative, y_inverted, y_epoch, y_value) = decompose(y)

    res_epoch = x_epoch - y_epoch

    if x_value == z64
      res_value = $inv_table[y_value >> 1]
      res_epoch -= 1
    elseif y_value == z64
      res_value = x_value
    else
      #do a lookup.
      res_value = $div_table[x_value >> 1, y_value >> 1]
      #check to see if we need to go to a lower epoch.
      (res_value > x_value) && (res_epoch -= 1)
    end

    res_sign = x_negative $ y_negative

    res_inverted = x_inverted
    #may need to reverse the orientation on the result.
    if (res_epoch < 0)
      res_inverted = !x_inverted
      res_epoch = (-res_epoch) - 1

      if (OT == __BOUND) || (OT == __AUTO)
        (_l_res, _u_res) = invertresult(res_value, Val{lattice}, OT)
      else
        res_value = invertresult(res_value, Val{lattice}, OT)
      end
    elseif (OT == __BOUND) || (OT == __AUTO)
      _l_res = res_value
      _u_res = res_value
    end

    if (OT == __BOUND) || (OT == __AUTO)
      PBound{lattice, epochbits}(synthesize(PFloat{lattice, epochbits}, res_sign, res_inverted, res_epoch, _l_res),
      synthesize(PFloat{lattice, epochbits}, res_sign, res_inverted, res_epoch, _u_res))
    else
      synthesize(PFloat{lattice, epochbits}, res_sign, res_inverted, res_epoch, res_value)
    end
  end
end

#I didn't want this to be a generated function, but it was the cleanest way to
#generate and use the new symbol.
@generated function create_division_table{lattice}(::Type{Val{lattice}})
  div_table = Symbol("__$(lattice)_div_table")
  quote
    #store the lattice values and the pivot values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)
    #allocate the memory for the matrix.
    global const $div_table = Matrix{UInt64}(l, l)

    for idx = 1:l
      for idx2 = 1:l
        true_value = lattice_values[idx] / lattice_values[idx2]
        #first check to see if the true_value corresponds to the pivot value.
        (true_value < 1) && (true_value *= pivot_value)

        $div_table[idx, idx2] = @i search_lattice(lattice_values, true_value)
      end
    end
  end
end

@generated function create_inversion_table{lattice}(::Type{Val{lattice}})
  inv_table = Symbol("__$(lattice)_inv_table")
  quote
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)

    #actually allocate the memory for the inversion table.
    global const $inv_table = Vector{UInt64}(l)

    for idx = 1:l
      true_value = pivot_value / lattice_values[idx]
      $inv_table[idx] = @i search_lattice(lattice_values, true_value)
    end
  end
end
