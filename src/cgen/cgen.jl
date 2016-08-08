
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

export generate_c_library
