#div.jl -- Unum2 division.
#impmements the following:
#  / Operator overloading.
#  PBound division.
#  Division algorithms.
#  Division table generation.

import Base./

################################################################################
# OPERATOR OVERLOADING
################################################################################

@pfunction function /(lhs::PBound, rhs::PBound)
  #encapuslates calling the more efficient "add" function, which does not need
  #to allocate memory.
  res::B = emptyset(B)
  copy!(res, rhs)
  multiplicativeinverse!(res)
  mul!(res, lhs)
  res
end

@pfunction function /(x::PBound)
  res::B = emptyset(B)
  copy!(res, x)
  multiplicativeinverse!(res)
  res
end

#we allow the (-) operator for PTiles because there is no memory overhead.
@pfunction function /(x::PTile)
  multiplicativeinverse(x)
end

################################################################################
# PBOUND DIVISION
################################################################################

doc"""
  `Unum2.div!(res::PBound, lhs::PBound, rhs::PBound)`  Takes two input values,
  lhs and rhs and divides rhs from lhs into the memory slot allocated by res.
"""

@pfunction function div!(res::PBound, lhs::PBound, rhs::PBound)
  copy!(res, rhs)
  multiplicativeinverse!(res)
  mul!(res, rhs)
  nothing
end


################################################################################
# ALGORITHMIC DIVISION
################################################################################

function exact_algorithmic_division{lattice, epochbits}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits})
  (lhs == rhs) && return one(PTile{lattice, epochbits})

  dc_lhs = decompose(lhs)
  dc_rhs = decompose(rhs)

  (invert, dc_lhs.epoch, dc_lhs.lvalue) = algorithmic_division_decomposed(dc_lhs, dc_rhs, Val{lattice})

  #reconstitute the result.
  x = synthesize(PTile{lattice, epochbits}, dc_lhs)
  invert ? multiplicativeinverse(x) : x
end

@generated function algorithmic_division_decomposed{lattice}(lhs::__dc_tile, rhs::__dc_tile, L::Type{Val{lattice}})
  #note that parameters passed to this function will always be pointing in the
  #same direction (out or in) relative to one.
  div_table = table_name(lattice, :div)
  inv_table = table_name(lattice, :inv)
  div_inv_table = table_name(lattice, :div_inv)

  #create the multiplication table, if necessary.
  isdefined(Unum2, div_table) || create_division_table(Val{lattice})
  isdefined(Unum2, inv_table) || create_inversion_table(Val{lattice})
  quote
    res_epoch = lhs.epoch - rhs.epoch - ((lhs.lvalue < rhs.lvalue) * 1)

    res_inverted = res_epoch < 0

    if res_inverted
      res_epoch = (-res_epoch) - 1

      if (rhs.lvalue == 0)
        res_lvalue = $inv_table[lhs.lvalue >> 1]
      elseif (lhs.lvalue == 0)
        res_lvalue = rhs.lvalue
      else
        res_lvalue = $div_inv_table[lhs.lvalue >> 1, rhs.lvalue >> 1]
      end
      (res_lvalue == 0) && (res_epoch += 1)
    else
      if (rhs.lvalue == 0)
        res_lvalue = lhs.lvalue
      elseif (lhs.lvalue == 0)
        res_lvalue = $inv_table[rhs.lvalue >> 1]
      else
        res_lvalue = $div_table[lhs.lvalue >> 1, rhs.lvalue >> 1]
      end
    end

    (res_inverted, res_epoch, res_lvalue)
  end
end

#being a generated function is the cleanest way to generate and use the new symbol.
@generated function create_division_table{lattice}(::Type{Val{lattice}})
  div_table = table_name(lattice, :div)
  div_inv_table = table_name(lattice, :div_inv)
  quote
    #store the lattice values and the stride values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    stride_value = __MASTER_STRIDE_LIST[lattice]
    l = length(lattice_values)
    #allocate the memory for the matrix.
    global const $div_table = Matrix{UT_Int}(l, l)
    global const $div_inv_table = Matrix{UT_Int}(l, l)

    for idx = 1:l
      for idx2 = 1:l
        true_value = lattice_values[idx] / lattice_values[idx2]
        #first check to see if the true_value corresponds to the stride value.
        (true_value < 1) && (true_value *= stride_value)

        $div_table[idx, idx2] = @i search_lattice(lattice_values, true_value)

        $div_inv_table[idx, idx2] = (true_value == 1) ? UT_Int(0) :
          @i search_lattice(lattice_values, stride_value / true_value)
      end
    end
  end
end
