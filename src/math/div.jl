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
  res::B = copy(rhs)
  multiplicativeinverse!(res)
  add!(res, lhs)
  res
end

@pfunction function /(x::PBound)
  res::B = copy(x)
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

function exact_algorithmic_division{lattice, epochbits, output}(x::PTile{lattice, epochbits}, y::PTile{lattice, epochbits}, OT::Type{Val{output}})
  dc_lhs = decompose(lhs)
  dc_rhs = decompose(rhs)

  (invert, dc_lhs.epoch, dc_lhs.lvalue) = algorithmic_division_decomposed(dc_lhs, dc_rhs, Val{lattice}, OT)

  #reconstitute the result.
  x = synthesize(PTile{lattice, epochbits}, dc_lhs)
  invert ? multiplicativeinverse(x) : x
end

@generated function algorithmic_division_decomposed{lattice, output}(lhs::__dc_tile, rhs::__dc_tile, L::Type{Val{lattice}}, OT::Type{Val{output}} )
  #note that parameters passed to this function will always be pointing in the
  #same direction (out or in) relative to one.
  div_table = table_name(lattice, :div)
  inv_table = table_name(lattice, :inv)

  m_epoch = max_epoch(epochbits)

  #create the multiplication table, if necessary.
  isdefined(Unum2, div_table) || create_division_table(Val{lattice})
  isdefined(Unum2, inv_table) || create_inversion_table(Val{lattice})
  quote
    res_epoch = lhs.epoch - rhs.epoch

    if lhs.lvalue == z64
      res_lvalue = $inv_table[lhs.lvalue >> 1]
      res_epoch -= 1
    elseif rhs.lvalue == z64
      res_lvalue = lhs.lvalue
    else
      #do a lookup.
      res_lvalue = $div_table[lhs.lvalue >> 1, rhs.lvalue >> 1]
      #check to see if we need to go to a lower epoch.
      (res_lvalue > lhs.lvalue) && (res_epoch -= 1)
    end

    res_inverted = false
    #may need to reverse the orientation on the result.
    if (res_epoch < 0)
      res_inverted = true
      res_epoch = (-res_epoch) - 1
      #invert the value.
      res_lvalue = lattice_invert(res_lvalue, Val{lattice}, OT)
    end

    (res_inverted, res_epoch, res_lvalue)
  end
end

#I didn't want this to be a generated function, but it was the cleanest way to
#generate and use the new symbol.
@generated function create_division_table{lattice}(::Type{Val{lattice}})
  div_table = table_name(lattice, :div)
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
