function table_name(lattice::Symbol, operation::Symbol)
  return Symbol("__$(lattice)_$(operation)_table")
end

function check_table_or_throw(tablename::Symbol)
  isdefined(Unum2, tablename) || throw(ErrorException("$tablename table not defined"))
end

function create_tables(lattice::Symbol)
  create_addition_tables(lattice)
  create_subtraction_tables(lattice)
  create_multiplication_table(Val{lattice})
  create_division_table(Val{lattice})
  create_inversion_table(Val{lattice})
end

export create_tables
