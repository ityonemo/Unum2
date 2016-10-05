doc"""
  `Unum2.elaborate(a)` takes an array a of rational values and elaborates
  it to a full-fledged number series.
"""
elaborate_mul(a::Array{Int64, 1}, stride, bits) = elaborate_mul(a.//1, stride, bits)

function elaborate_mul(a::Array{Rational{Int64}, 1}, stride, bits)

  latticepoints = unique(sort(vcat(a, [stride // v for v in a])))

  ##############################################################################
  #parameter checking.
  #make sure bits fills correctly.
  full_count = (1 << (bits - 1) - 1)
  #figure out how many bits we have left.
  remains = full_count - length(latticepoints)
  (remains < 0) && throw(ErrorException("too much"))

  while (remains > 0)
    println("remains: $remains")
    grow_list_mul!(latticepoints, stride, remains) #add onto b as much as we can.

    remains = full_count - length(latticepoints) #update the count of b.
  end

  latticepoints
end

function grow_list_mul!(latticepoints, stride, remains)
  bestkeys = pick_nums_to_add(latticepoints, stride)

  if (remains == 1)
    push!(latticepoints, bestkeys[1])
    sort!(latticepoints)
  else
    println("bestkeys:  $bestkeys")
    numtoadd = min(div(remains, 2), length(bestkeys)) #count how many values we should add.
    for idx = 1:numtoadd
      (bestkeys[idx] in latticepoints)       || push!(latticepoints, bestkeys[idx])
      (stride / bestkeys[idx] in latticepoints) || push!(latticepoints, stride / bestkeys[idx])
      sort!(latticepoints)
    end
  end
end

function pick_nums_to_add(latticepoints, stride)
  rdict = Dict{Rational{Int64}, Int64}()

  #generate the extended lattice.

  xlattice = vcat([1//1], latticepoints, [stride // 1])

  for (a, b) in uppertriangular(latticepoints)
    mulres = contract(a * b, stride)
    if !(mulres in xlattice)
      #next do a comprehensive addition.
      for c in latticepoints
        if test_multitile_fma(latticepoints, a, b, c, stride)
          rdict[mulres] = haskey(rdict, mulres) ? rdict[mulres] + 1 : 1
        end
        if test_multitile_fma(latticepoints, a, b, -c, stride)
          rdict[mulres] = haskey(rdict, mulres) ? rdict[mulres] + 1 : 1
        end
      end
    end
    divres = contract(a / b, stride)
    if !(divres in xlattice)
      for c in latticepoints
        if test_multitile_fma(latticepoints, a, 1/b, c, stride)
          rdict[divres] = haskey(rdict, mulres) ? rdict[mulres] + 1 : 1
        end
        if test_multitile_fma(latticepoints, a, 1/b, -c, stride)
          rdict[divres] = haskey(rdict, mulres) ? rdict[mulres] + 1 : 1
        end
      end
    end
    divres2 = contract(b / a, stride)
    if !(divres2 in xlattice)
      for c in latticepoints
        if test_multitile_fma(latticepoints, 1/a, b, c, stride)
          rdict[divres2] = haskey(rdict, mulres) ? rdict[mulres] + 1 : 1
        end
        if test_multitile_fma(latticepoints, 1/a, b, -c, stride)
          rdict[divres2] = haskey(rdict, mulres) ? rdict[mulres] + 1 : 1
        end
      end
    end
  end

  commonest(rdict)
end

function epoch_multiplier(stride, value)
  #calculates the epoch of a value.
  #preconditions:  0 < value < inf
  #postconditions: epoch_multiplier returns the value (stride^n)
  # wherein stride^n <= value < stride^(n+1)

  _t_multiplier = 1//1 #temporary multiplier

  if (value < 1)

    while (_t_multiplier > value)
      _t_multiplier /= stride
    end

    return _t_multiplier
  elseif (value >= stride)
    _t_multiplier *= stride

    while (_t_multiplier < value)
      _t_multiplier *= stride
    end

    return _t_multiplier / stride
  else
    return 1//1
  end
end

function find_upper_bound(array, value)
  for v in array
    (v > value) && return v
  end
  return last(array)
end

function find_lower_bound(array, value)
  for v in reverse(array)
    (v < value) && return v
  end
  return first(array)
end

function upperbound(array, stride, value, final = false)
  #calculates the upper bounding value of a particular operation within any
  #given lattice.  array is array list (not including 1 and stride).

  #first find the lower bounding epoch multiplier.
  m = epoch_multiplier(stride, value)
  #check the edge cases.
  (value == m) && return (final ? 1//1 : m)
  ((value / m) in array) && return (final ? value / m : value)

  (value > last(array) * m) && return (final ? stride // 1 : (m * stride))

  #search the array to find the result.
  if final
    find_upper_bound(array .* m, value) / m
  else
    find_upper_bound(array .* m, value)
  end
end


function lowerbound(array, stride, value, final = false)
  #this function works pretty much like the upperbound function, except operates
  #to find the lower bound.

  (value == 0//1) && return 0//1

  #first find the lower bounding epoch multiplier
  m = epoch_multiplier(stride, value)

  #check the bounding conditions.
  (value == (m * stride)) && return (final ? stride // 1 : (m * stride))
  (value < first(array) * m) && return (final ? 1 : m)
  ((value / m) in array) && return (final ? value / m : value)

  #search the array to find the result.
  if final
    find_lower_bound(array .* m, value) / m
  else
    find_lower_bound(array .* m, value)
  end
end


function test_multitile_fma(array, a, b, c, stride)

  xarray = vcat([1//1], array, [stride // 1])

  #first, multiply a * b, and find the bounds.
  product = abs(a * b)

  lower_bound_product = lowerbound(array, stride, product)
  upper_bound_product = upperbound(array, stride, product)

  lower_bound_sum = abs(lower_bound_product + c)
  upper_bound_sum = abs(upper_bound_product + c)

  lower_lower = min(lower_bound_sum, upper_bound_sum)
  upper_upper = max(lower_bound_sum, upper_bound_sum)

  lower_bound_fma = lowerbound(array, stride, lower_lower, true)
  upper_bound_fma = upperbound(array, stride, upper_upper, true)

  res = (lower_bound_fma == 0//1)
  res = res || (epoch_multiplier(stride, lower_lower) < epoch_multiplier(stride, upper_upper))
  res = res || length(filter((x) -> (lower_bound_fma < x < upper_bound_fma), xarray)) > 0

  #do our second round filter check.
  #=
  ## EMPIRICALLY, THIS DOES NOT RESULT IN IMPROVED FMA CLOSURE
  if res
    # use: (a * b) + c == (a + c/b) * b
    multiplicand = abs(a + c / b)
    lower_bound_multiplicand = lowerbound(array, stride, multiplicand)
    upper_bound_multiplicand = upperbound(array, stride, multiplicand)

    lower_bound_product = lowerbound(array, stride, lower_bound_multiplicand * b, true)
    upper_bound_product = upperbound(array, stride, upper_bound_multiplicand * b, true)

    lower_bound_fma = max(lower_bound_product, lower_bound_fma)
    upper_bound_fma = min(upper_bound_product, upper_bound_fma)

    # use: (a * b) + c == (b + c/a) * a
    multiplicand = abs(b + c / a)
    lower_bound_multiplicand = lowerbound(array, stride, multiplicand)
    upper_bound_multiplicand = upperbound(array, stride, multiplicand)

    lower_bound_product = lowerbound(array, stride, lower_bound_multiplicand * a, true)
    upper_bound_product = upperbound(array, stride, upper_bound_multiplicand * a, true)

    lower_bound_fma = max(lower_bound_product, lower_bound_fma)
    upper_bound_fma = min(upper_bound_product, upper_bound_fma)

    res = (lower_bound_fma == 0//1)
    res = res || (epoch_multiplier(stride, lower_bound_fma) < epoch_multiplier(stride, upper_bound_fma))
    res = res || length(filter((x) -> (lower_bound_fma < x < upper_bound_fma), xarray)) > 0
  end
  =#

  res
end


export elaborate_mul
