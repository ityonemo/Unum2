#master lattice list

typealias LatticeNum Union{AbstractFloat, Integer, Symbol}
typealias Lattice Array{LatticeNum, 1}
const __MASTER_LATTICE_LIST = Dict{Symbol, Lattice}()

function validate(l::Lattice)
  #makes sure that a lattice has a valid properties.
  #first, the numebr of elements in the lattice must be 2^n, or zero.
  (length(l) == 0) || ispow2(length(l)) || throw(ArgumentError("proposed lattice has invalid: member count must be a power of 2"))

  #next scan the lattice and make sure it obeys ordering properties.
  for idx = 1:length(l)
    (l[idx] == 1) && throw(ArgumentError("proposed lattice is invalid: cannot contain 1"))  #1 is not allowed to be in the lattice.
    (idx > 1) && (floatval(l[idx]) > floatval(l[idx - 1]) || throw(ArgumentError("proposed lattice has invalid structure, $(l[idx]) < $(l[idx - 1])")))
    (idx < length(l)) && (floatval(l[idx]) < floatval(l[idx + 1]) || throw(ArgumentError("proposed lattice has invalid structure, $(l[idx]) > $(l[idx + 1])")))
  end
end

floatval(x::AbstractFloat) = BigFloat(x)
floatval(n::Integer) = BigFloat(n)
#each lattice should implement precompiled value functions which correspond to your
#favorite symbols.
floatval(s::Symbol) = floatval(Val{s})

function describe(n::LatticeNum)
  string(n)
end

pivotvalue(l::Lattice) = floatval(l[end])

function addlattice(name::Symbol, l::Lattice)
  #first, validate the lattice
  haskey(__MASTER_LATTICE_LIST, name) && throw(ArgumentError("Proposed lattice for symbol $name is already defined."))
  validate(l)
  __MASTER_LATTICE_LIST[name] = l
end

function list(l::Lattice)
  println("members of lattice:")
  println(join(l, ", "))
end

function latticelength(l::Lattice)
  (length(l) == 0) && return 1
  trailing_zeros(length(l)) + 2
end
