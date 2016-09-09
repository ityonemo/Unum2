#fma.jl - implementation of the fused-multiply add.

function exact_fma{lattice, epochbits, output}(a::PTile{lattice, epochbits},b::PTile{lattice, epochbits},c::PTile{lattice, epochbits}, OT::Type{Val{output}})
  #a few easy cases.
  (is_inf(a)) && return is_zero(b) ? noisy_R(PBound{lattice, epochbits}, OT) : coerce(inf(PTile{lattice, epochbits}), OT)
  (is_inf(b)) && return is_zero(a) ? noisy_R(PBound{lattice, epochbits}, OT) : coerce(inf(PTile{lattice, epochbits}), OT)
  (is_inf(c)) && return coerce(inf(PTile{lattice, epochbits}), OT)
  (is_zero(a)) && return coerce(c, OT)
  (is_zero(b)) && return coerce(c, OT)
  (is_zero(c)) && return exact_mul(a, b, OT)
  (is_one(a)) && return exact_add(b, c, OT)
  (is_one(b)) && return exact_add(a, c, OT)
  (is_neg_one(a)) && return exact_add(c, -b, OT)
  (is_neg_one(b)) && return exact_add(c, -a, OT)

  dc_a = decompose(a)
  dc_b = decompose(b)
  dc_c = decompose(c)

  (is_negative(dc_a) $ is_negative(dc_b)) ? set_negative!(dc_a) : set_positive!(dc_a)

  #perform the algorithmic multiplication
  if (is_inverted(dc_a) $ is_inverted(dc_b))
    (invert, dc_a.epoch, dc_a.lvalue) = algorithmic_division_decomposed(lhs, multiplicativeinverse(rhs), Val{lattice}, OT)
    invert && flip_inverted!(dc_a)
  else
    (dc_a.epoch, dc_a.lvalue) = algorithmic_multiplication_decomposed(lhs, rhs, Val{lattice}, OT)
  end

  #next, do the algorithmic addition/subtraction
  exact_add(dc_a, dc_c, OT)

  synthesize(dc_a)
end

@generated function inexact_fma{lattice, epochbits, output}(a::PTile{lattice, epochbits},b::PTile{lattice, epochbits},c::PTile{lattice, epochbits}, OT::Type{Val{output}})
  #for positive values of multiply (for now.)
  if output == :lower
    quote
      #decide if the multiplication result will be positive or negative.
      mul_res_sign = isnegative(a) $ isnegative(b)
      #if the result is negative, the lower value will be the outer values for both
      #if the result is positive, the lower value will result from the inner values for both.
      a_bound = mul_res_sign $ isnegative(a) ? lub(a) : glb(a)
      b_bound = mul_res_sign $ isnegative(b) ? lub(b) : glb(b)

      upperulp(exact_fma(
        a_bound,
        b_bound,
        glb(c),
        OT))
    end
  else #output == :upper
    quote
      #decide if the multiplication result will be positive or negative.
      mul_res_sign = isnegative(a) $ isnegative(b)
      #if the result is negative, the upper value will result from the inner values for both
      #if the result is positive, the upper value will result from the outer values for both.
      a_bound = mul_res_sign $ isnegative(a) ? glb(a) : lub(a)
      b_bound = mul_res_sign $ isnegative(b) ? glb(b) : lub(b)

      lowerulp(exact_fma(
        a_bound,
        b_bound,
        lub(c),
        OT)))
    end
  end
end

@pfunction function fma!(res::PBound, a::PBound, b::PBound, c::PBound)
  #terminate early on special values.
  (isempty(a) || isempty(b) || isempty(c)) && (set_empty!(res); return)
  (ispreals(a) || ispreals(b) || ispreals(c)) && (set_preals!(acc); return)
  #check on special cases for multiplication:

  if issingle(a)
    single_fma!(res, a, b, c)
  elseif issingle(b)
    single_fma!(res, b, a, c)
  elseif containsinf(a)
    inf_fma!(res, a, b, c)
  elseif containsinf(b)
    inf_fma!(res, b, a, c)
  elseif __simple_roundszero(a)
    zero_fma!(res, a, b, c)
  elseif __simple_roundszero(b)
    zero_fma!(res, b, a, c)
  else
    std_fma!(res, b, a, c)
  end
end

@pfunction function single_fma!(res::PBound, a::PBound, b::PBound, c::PBound)
end

@pfunction function inf_fma!(res::PBound, a::PBound, b::PBound, c::PBound)
  nothing
end

@pfunction function zero_fma!(res::PBound, a::PBound, b::PBound, c::PBound)
  nothing
end

@pfunction function std_fma!(res::PBound, a::PBound, b::PBound, c::PBound)
  #decide if the multiplication result will be positive or negative.
  mul_res_sign = isnegative(a.lower) $ isnegative(b.lower)
  #if the result is negative, the lower value will be the outer values for both
  #if the result is positive, the lower value will result from the inner values for both.
  (a_lower_component, a_upper_component) = mul_res_sign $ isnegative(a) ? (a.upper, a.lower) : (a.lower, a.upper)
  (b_lower_component, b_upper_component) = mul_res_sign $ isnegative(b) ? (b.upper, b.lower) : (b.lower, b.upper)

  c_upper_proxy = issingle(c) ? c.lower : c.upper

  res.lower = fma(a_lower_component, b_lower_component, c.lower)
  res.upper = fma(a_upper_component, b_upper_component, c_upper_proxy)

  (res.lower == res.upper) && set_single!(res)
  res
end
