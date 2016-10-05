
#upper triangular indices - iterates over upper triangular indices in a list of
#indices.
type uppertriangular; iterable; end

Base.start(x::uppertriangular) = (1, 1)
function Base.next(x::uppertriangular, state)
  (idx1, idx2) = state
  next1 = idx1
  next2 = idx2 + 1
  if next2 > length(x.iterable)
    next1 += 1
    next2 = next1
  end
  ((x.iterable[idx1], x.iterable[idx2]), (next1, next2))
end
function Base.done(x::uppertriangular, state)
  (state[1] > length(x.iterable))
end
function Base.length(x::uppertriangular)
  (x.length * x.length + x.length) / 2
end

doc"""
  `Unum2.elaborate(a)` takes an array a of rational values and elaborates
  it to a full-fledged number series.
"""
elaborate(a::Array{Int64, 1}, top, bits) = elaborate(a.//1, top, bits)

function elaborate(a::Array{Rational{Int64}, 1}, top, bits)

  ##############################################################################
  latticepoints = unique(sort(vcat(a, [top // v for v in a])))

  ##############################################################################
  #parameter checking.
  #make sure bits fills correctly.
  full_count = (1 << (bits - 1) - 1)
  #figure out how many bits we have left.
  remains = full_count - length(latticepoints)
  (remains < 0) && throw(ErrorException("too much"))

  #generate an extended lattice from the lattice points.
  xlattice = vcat(latticepoints, [top])
  append!(xlattice, map((x) -> (1/x), xlattice))
  push!(xlattice, (1//1))

  fma_dict = Dict{Rational{Int64}, Int64}()

  for (x, y) in uppertriangular(xlattice), z in xlattice
    a1 = abs(x * y + z)
    a1 = contract(a1, top)

    if !(a1 in xlattice)
      fma_dict[a1] = haskey(fma_dict, a1) ? (fma_dict[a1] + 1) : 1
    end

    a2 = abs(x * y - z)
    contract(a2, top)

    if !(a2 in xlattice) && (a1 != 0)
      fma_dict[a2] = haskey(fma_dict, a2) ? (fma_dict[a2] + 1) : 1
    end
  end

  while (remains > 0)
    println("remains: $remains")
    grow_list!(latticepoints, fma_dict, top, remains) #add onto b as much as we can.

    remains = full_count - length(latticepoints) #update the count of b.
  end

  sort!(latticepoints)
  latticepoints
end

function contract(x::Rational{Int64}, top)
  x == 0 && return 0//1
  while (x < 1 || x > top)
    (x < 1) && (x *= top)
    (x > top) && (x /= top)
  end
  x
end

function grow_list!(latticepoints::Array{Rational{Int64}, 1}, fma_results::Dict{Rational{Int64}, Int64}, top, remains)
  #first regenerate the extended lattice from the initial lattice points.
  xlattice = vcat(latticepoints, Rational{Int64}(top))
  append!(xlattice, map((x) -> 1/x, latticepoints))
  push!(xlattice, (1//1))

  #retrieve the commonest key.
  bestkeys = commonest(fma_results)

  if (remains == 1)
    push!(latticepoints, bestkeys[1])
  else
    numtoadd = min(div(remains, 2), length(bestkeys)) #count how many values we should add.
    for idx = 1:numtoadd
      println("current lattice has length $(length(latticepoints))")

      this_best = bestkeys[idx]
      this_invb = top / this_best

      push!(latticepoints, this_best)
      push!(latticepoints, this_invb)
      append!(xlattice, this_best)
      append!(xlattice, 1/this_best)
      append!(xlattice, this_invb)
      append!(xlattice, 1/this_invb)

      add_fma_products!(fma_results, xlattice, this_best, top)
      add_fma_products!(fma_results, xlattice, this_invb, top)
      add_fma_products!(fma_results, xlattice, 1/this_best, top)
      add_fma_products!(fma_results, xlattice, 1/this_invb, top)

      delete!(fma_results, this_best)
    end
  end
end

function add_fma_products!(fma_results::Dict{Rational{Int64}, Int64}, xlattice::Array{Rational{Int64}}, target::Rational{Int64}, top)
  for (a, b) in uppertriangular(xlattice)
    add_single_result!(fma_results, xlattice, a * b + target, top)
    add_single_result!(fma_results, xlattice, a * b - target, top)
  end
  for a in xlattice, c in xlattice
    add_single_result!(fma_results, xlattice, a * target + c, top)
    add_single_result!(fma_results, xlattice, a * target - c, top)
  end
end

function add_single_result!(fma_results::Dict{Rational{Int64}, Int64}, xlattice::Array{Rational{Int64}}, target::Rational{Int64}, top)
  target = contract(abs(target), top)

  ((target in xlattice) || (target == 0)) && return

  fma_results[target] = haskey(fma_results, target) ? (fma_results[target] + 1) : 1
end

function commonest(valuedict::Dict)

  max_count = maximum(values(valuedict))

  resarray = []

  for k in keys(valuedict)
    (valuedict[k] == max_count) && push!(resarray, k)
  end

  resarray
end

export elaborate
