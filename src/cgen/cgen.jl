
doc"""
  `generate_c_library(path, lattice)`

  generates a c library into the directory specified by path, or creates said
  directory and then populates files into
  the relevant files are "pmath.h", "pmath.cpp", and "(lattice).h", and "(lattice).cpp",

"""
function generate_c_library(path::ASCIIString, lattice::Symbol)
  #first test to see if the path exists.
  isdir(path) || mkdir(path)
end

function generate_tables(io::IO, lattice::Symbol)

  isdefined(Unum2, add_table)       || create_uninverted_addition_tables(Val{lattice})
  isdefined(Unum2, add_inv_table)   || create_inverted_addition_tables(Val{lattice})
  isdefined(Unum2, add_cross_table) || create_crossed_addition_tables(Val{lattice})
  isdefined(Unum2, sub_table)       || create_uninverted_subtraction_tables(Val{lattice})
  isdefined(Unum2, sub_inv_table)   || create_inverted_subtraction_tables(Val{lattice})
  isdefined(Unum2, sub_cross_table) || create_crossed_subtraction_tables(Val{lattice})
  isdefined(Unum2, mul_table)       || create_multiplication_table(Val{lattice})
  isdefined(Unum2, div_table)       || create_division_table(Val{lattice})
  isdefined(Unum2, inv_table)       || create_inversion_table(Val{lattice})
end

export generate_c_library
