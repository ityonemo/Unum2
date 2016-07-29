function table_name(lattice::Symbol, operation::Symbol)
  return Symbol("__$(lattice)_$(operation)_table")
end
