#Unum2 multiplication.

import Base.*
*{lattice, epochbits}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits}) = mul(x, y, Val{:auto})

function noisy_R{output}(P::Type, ::Type{Val{output}})
  if (output == :auto) || (output == :bound)
    return allprojectivereals(P)
  else
    throw(ArgumentError("output type doesn't support all real values"))
    return zero(P)  #to keep homoiconicity.
  end
end

function mul{lattice, epochbits, output}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits}, OT::Type{Val{output}})
  is_inf(x) && return (is_zero(y) ? noisy_R(PBound{lattice, epochbits}, OT) : coerce(inf(PFloat{lattice, epochbits}), OT))
  is_inf(y) && return (is_zero(x) ? noisy_R(PBound{lattice, epochbits}, OT) : coerce(inf(PFloat{lattice, epochbits}), OT))
  is_zero(x) && return (is_inf(y) ? noisy_R(PBound{lattice, epochbits}, OT) : coerce(zero(PFloat{lattice, epochbits}), OT))
  is_zero(y) && return (is_inf(x) ? noisy_R(PBound{lattice, epochbits}, OT) : coerce(zero(PFloat{lattice, epochbits}), OT))

  if isexact(x) & isexact(y)
    exact_mul(x, y, OT)
  else
    inexact_mul(x, y, OT)
  end
end


function exact_mul{lattice, epochbits, output}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits}, OT::Type{Val{output}})
  if (isinverted(x) $ isinverted(y))
    coerce(exact_arithmetic_division(x, multiplicativeinverse(y)), OT)
  else
    coerce(exact_arithmetic_multiplication(x, y), OT)
  end
end

function inexact_mul{lattice, epochbits, output}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits}, OT::Type{Val{output}})
  return nothing
end


@generated function exact_arithmetic_multiplication{lattice, epochbits}(x::PFloat{lattice, epochbits}, y::PFloat{lattice, epochbits})
  mult_table = Symbol("__$(lattice)_mult_table")
  m_epoch = max_epoch(epochbits)

  #create the multiplication table, if necessary.
  isdefined(Unum2, mult_table) || create_multiplication_table(Val{lattice})
  quote
    x_negative = y_negative = x_inverted = y_inverted= false
    x_epoch = y_epoch = x_value = y_value = z64

    (x_negative, x_inverted, x_epoch, x_value) = decompose(x)
    (y_negative, y_inverted, y_epoch, y_value) = decompose(y)

    res_epoch = x_epoch + y_epoch

    if x_value == z64
      res_value = y_value
    elseif y_value == z64
      res_value = x_value
    else
      #do a lookup.
      res_value = $mult_table[x_value >> 1, y_value >> 1]
      #check to see if we need to go to a higher epoch.
      (res_value < x_value) && (res_epoch += 1)
    end

    res_sign = x_negative $ y_negative

    #check to see if we overflow to extremum.
    ((res_epoch) > $m_epoch) && return extremum(PFloat{lattice, epochbits}, res_sign, x_inverted)

    synthesize(PFloat{lattice, epochbits}, res_sign, x_inverted, res_epoch, res_value)
  end
end

#I didn't want this to be a generated function, but it was the cleanest way to
#generate and use the new sybol.
@generated function create_multiplication_table{lattice}(::Type{Val{lattice}})
  mult_table = Symbol("__$(lattice)_mult_table")
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
