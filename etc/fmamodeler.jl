#fma modeler.  Models random generation of lattices and tests the FMA
#properties.

rmsl_arr = Array{Float64, 1}
mbec_arr = Array{Int64, 1}

#an upper-triangular type.
type uppertriangular; iterable; end
Base.start(x::uppertriangular) = (1,1)
function Base.next(x::uppertriangular,state)
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
  (state[2] > length(x.iterable))
end
function Base.length(x::uppertriangular)
  l = length(x.iterable)
  (l * l + l) / 2
end
###########################################

#evaluate the root mean square distance.
function eval_rmsl(lattice)
  ref_arr = collect(1:31)
  sqrt(sum((ref_arr .- log.(lattice .// 32)) .^ 2) / 31)
end

global lat_idx = 1
#evaluate the minimally bounded error closure rate.
function eval_mbec(lattice)
  global lat_idx
  totalsofar = 0
  lat = Unum2.LatticeNum(lattice)
  lat_sym = Symbol(:lat_, lat_idx)

  #add the lattice, registering stride as 10, and then create the tables.
  Unum2.addlattice(lat_sym, lat, 10)
  create_tables(lat_sym)

  top_val = PTile{lat_sym, 2}(10)
  bot_val = /(top_val)
  pos_bound = PBound(bot_val, top_val)
  neg_bound = -pos_bound

  for (a, b) in uppertriangular(pos_bound), c in pos_bound
    fma_glb = glb(▾(a) * ▾(b)) + ▾(c)
    fma_lub = lub(▾(a) * ▾(b)) + ▾(c)
    if is_single(fma_glb) && is_single(fma_lub)
      totalsofar += (fma_glb == fma_lub)
    end

    fms_glb = glb(▾(a) * ▾(b)) - ▾(c)
    fms_lub = lub(▾(a) * ▾(b)) - ▾(c)
    if is_single(fms_glb) && is_single(fms_lub)
      totalsofar += (fms_glb == fms_lub)
    end
  end

  totalsofar
end

function latticegen(lattice)
end

#generate the data
count = 10

for idx = 1:count
  #start with the basic decimal lattice array.
  starting_lattice = collect(2:9)

  new_lattice = latticegen(starting_lattice)
  println("generated lattice $idx.")

  rmsl = eval_rmsl(new_lattice)
  mbec = eval_mbec(new_lattice)
  println("evaluated lattice $idx. $rmsl, $mbec")

  push!(rmsl_arr, rmsl)
  push!(mbec_arr, mbec)
end
