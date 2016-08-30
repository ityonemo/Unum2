#mul.jl -- Unum2 multiplication.
#impmements the following:
#  * Operator overloading.
#  PBound multiplication.
#  Call decision for algorithmic multiplication vs. algorithmic division.
#  Multiplication algorithms.
#  Multiplication table generation.

import Base.*

################################################################################
# OPERATOR OVERLOADING
################################################################################

@pfunction function *(lhs::PBound, rhs::PBound)
  #encapuslates calling the more efficient "add" function, which does not need
  #to allocate memory.

  res::B = emptyset(B)
  mul!(res, lhs, rhs)
  res
end

################################################################################
# PBOUND MULTIPLICATION
################################################################################

doc"""
  `Unum2.mul!(res::PBound, lhs::PBound, rhs::PBound)`  Takes two input values,
  lhs and rhs and multiplies them together into the memory slot allocated by res.
"""
@pfunction function mul!(res::PBound, lhs::PBound, rhs::PBound)
  #terminate early on special values.
  (isempty(lhs) || isempty(rhs)) && (set_empty!(res); return)
  (ispreals(lhs) || ispreals(rhs)) && (set_preals!(res); return)

  set_double!(res)

  #to make calculations simple, ensure that the upper is equal to the lower.
  issingle(lhs) && (single_mul!(res, lhs, rhs); return)
  issingle(rhs) && (single_mul!(res, rhs, lhs); return)

  roundsinf(lhs) && (inf_mul!(res, lhs, rhs); return)
  roundsinf(rhs) && (inf_mul!(res, rhs, lhs); return)

  roundszero(lhs) && (zero_mul!(res, lhs, rhs); return)
  roundszero(rhs) && (zero_mul!(res, rhs, lhs); return)

  std_mul!(res, lhs, rhs)
end

doc"""
  Unum2.std_mul!(res::PBound, lhs::PBound, rhs::PBound)

  performs a standard multiplication on two PBounds which are well-behaved (don't
  cross zero or infinity).  Result is stored in "res" variable.
"""
@pfunction function std_mul!(res::PBound, lhs::PBound, rhs::PBound)
  flip_sign = false
  (lhs_lower, lhs_upper) = isnegative(lhs) ? (flip_sign = true; (lhs.upper, lhs.lower)) : (lhs.lower, lhs.upper)
  (rhs_lower, rhs_upper) = isnegative(rhs) ? (flip_sign $= true; (rhs.upper, rhs.lower)) : (rhs.lower, rhs.upper)

  if flip_sign
    res.lower = -sided_abs_mul(lhs_upper, rhs_upper, __UPPER)
    res.upper = -sided_abs_mul(lhs_lower, rhs_lower, __LOWER)
  else
    res.lower = sided_abs_mul(lhs_lower, rhs_lower, __LOWER)
    res.upper = sided_abs_mul(lhs_upper, rhs_upper, __UPPER)
  end

  (res.lower == res.upper) && set_single!(res)
end


################################################################################
# PTILE MULTIPLICATION
################################################################################

doc"""
  Unum2.sided_abs_mul(x::PTile, y::PTile, ::Type{Val{output}})

  perform a mul on one side or the other, returning the appropriate tile value.
  the absolute value of the multiply is calculated; it's the responsibility of
  the caller to figure out parity.
"""
function sided_abs_mul{lattice, epochbits, output}(x::PTile{lattice, epochbits}, y::PTile{lattice, epochbits}, OT::Type{Val{output}})
  #don't do infinity or zero checks. This should be handled outside the sided mul call.
  is_unit(lhs) && return abs(rhs)
  is_unit(rhs) && return abs(lhs)

  if isexact(lhs) & isexact(rhs)
    exact_mul(abs(lhs), abs(rhs), OT)
  else
    inexact_mul(abs(lhs), abs(rhs), OT)
  end
end

function checked_exact_mul(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  is_inf(lhs) && return inf(PTile{lattice, epochbits})
  is_inf(rhs) && return inf(PTile{lattice, epochbits})
  is_zero(lhs) && return zero(PTile{lattice, epochbits})
  is_zero(rhs) && return zero(PTile{lattice, epochbits})
  is_one(rhs) && return lhs
  is_one(lhs) && return rhs

  exact_mul(lhs, rhs, OT)
end

function exact_mul{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  if (isinverted(lhs) $ isinverted(rhs))
    exact_arithmetic_division(lhs, multiplicativeinverse(rhs), OT)
  else
    exact_arithmetic_multiplication(lhs, rhs, OT)
  end
end

@generated function inexact_mul{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}})
  if output == :lower
    :(lub(checked_exact_mul(glb(abs(lhs)), glb(abs(rhs)), OT)))
  else #output == :upper
    :(lub(checked_exact_mul(lub(abs(lhs)), lub(abs(rhs)), OT)))
  end
end

################################################################################
# ALGORITHMIC MULTIPLICATION
################################################################################

function exact_algorithmic_multiplication{lattice, epochbits, output}(lhs::PTile{lattice, epochbits}, rhs::PTile{lattice, epochbits}, OT::Type{Val{output}} )
  dc_lhs = decompose(lhs)
  dc_rhs = decompose(rhs)

  (dc_lhs.epoch, dc_lhs.lvalue) = algorithmic_multiplication_decomposed(dc_lhs, dc_rhs, OT)

  #reconstitute the result.
  synthesize(PTile{lattice, epochbits}, dc_lhs)
end


@generated function algorithmic_multiplication_decomposed{lattice, output}(lhs::__dc_tile, rhs::__dc_tile, OT::Type{Val{output}} )
  mul_table = table_name(lattice, :mul)
  m_epoch = max_epoch(epochbits)

  #create the multiplication table, if necessary.
  isdefined(Unum2, mul_table) || create_multiplication_table(Val{lattice})
  quote
    res_epoch = lhs.epoch + rhs.epoch

    if lhs.lvalue == z64
      res_lvalue = rhs.lvalue
    elseif rhs.lvalue == z64
      res_lvalue = lhs.lvalue
    else
      #do a lookup.
      res_lvalue = $mul_table[lhs.lvalue >> 1, rhs.lvalue >> 1]
      #check to see if we need to go to a higher epoch.
      (res_lvalue < lhs.lvalue) && (res_epoch += 1)
    end

    (res_epoch, res_value)
  end
end

################################################################################
# MULTIPLICATION TABLES
################################################################################

#I didn't want this to be a generated function, but it was the cleanest way to
#generate and use the new sybol.
@generated function create_multiplication_table{lattice}(::Type{Val{lattice}})
  mult_table = Symbol("__$(lattice)_mul_table")
  quote
    #store the lattice values and the pivot values.
    lattice_values = __MASTER_LATTICE_LIST[lattice]
    pivot_value = __MASTER_PIVOT_LIST[lattice]
    l = length(lattice_values)
    #actually allocate the memory for the matrix.  We can make easy inferences about
    #some things, because we know that 1 * value == value, and bounds must be bounded
    #by exacts.
    global const $mult_table = Matrix{UInt64}(l, l)

    for idx = 1:l
      for idx2 = 1:l
        true_value = lattice_values[idx] * lattice_values[idx2]
        #first check to see if the true_value corresponds to the pivot value.
        (true_value >= pivot_value) && (true_value /= pivot_value)

        $mult_table[idx, idx2] = @i search_lattice(lattice_values, true_value)
      end
    end
  end
end
