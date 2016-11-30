
doc"""
  `Unum2.cgen`

  a module containg methods to generate Unum2 c libraries.
"""
module cgen

  using ...Unum2: table_name, latticebits, incrementor
  using ...Unum2

  ##############################################################################
  ## HEADER PARTS

  function header_hstring(floatname::Symbol)
    allcaps = replace(string(floatname),r"([a-z]*)", (s) -> map((c) -> c - 32, s))

    "#ifndef __$(allcaps)_H\n#define __$(allcaps)_H\n"
  end

  function includes_hstring(dir::String)
    "#include \"$dir/penv.h\"\n#include \"$dir/pbound.h\"\n#include \"$dir/ptile.h\"\n"
  end

  function footer_hstring(floatname::Symbol)
    "#endif\n"
  end

  #generate an extern statement for the table
  function table_hstring(lattice::Symbol, table::Symbol)
    table_to_output = table_name(lattice, table)
    isdefined(Unum2, table_to_output) || throw(ArgumentError("error attempting to access an undefined lattice $table_to_output"))
    table = eval(Unum2, :($table_to_output))
    l = length(table)

    "extern const unsigned long long $table_to_output[$l];\n"
  end

  tablelist=[:add, :add_inv, :add_cross, :sub, :sub_epoch, :sub_inv, :sub_inv_epoch, :sub_cross, :sub_cross_epoch, :mul, :div, :inv_div, :inv]

  function write_hfile(io::IO, hdir::String, floatname::Symbol, latticename::Symbol)
    write(io, header_hstring(floatname))
    write(io, includes_hstring(hdir))
    for table in tablelist
      write(io, table_hstring(latticename, table))
    end
    write(io, footer_hstring(floatname))
  end

  ##############################################################################
  ## C FILE PARTS

  #generate a string that creates the environment statement in C.
  function envstring{lattice, epochbits}(label::Symbol, PType::Type{PTile{lattice, epochbits}})
    lb = latticebits(lattice)
    inc = string("0x",hex(incrementor(PType),16))
    tablenames = join(map((s) -> table_name(lattice, s), tablelist), ",")
    "const PEnv $(label)_ENV={$lb,$epochbits,$inc,{$tablenames}};\n"
  end

  #generate a string that creates the table in C.
  function tablestring(lattice::Symbol, table::Symbol)
    table_to_output = table_name(lattice, table)
    isdefined(Unum2, table_to_output) || throw(ArgumentError("error attempting to access an undefined lattice"))
    table = eval(Unum2, :($table_to_output))

    l = length(table)
    contents = join(map((x) -> string("0x",hex(reinterpret(UInt64, x), 16)), table[:]), ",")
    "const unsigned long long $table_to_output[$l]={$contents};\n"
  end

  header_cstring(label::Symbol) = "#include \"$label.h\"\n"

  function write_cfile{lattice, epochbits}(io::IO, hdir::String, floatname::Symbol, PType::Type{PTile{lattice, epochbits}})
    write(io, header_cstring(floatname))
    for table in tablelist
      write(io, tablestring(lattice, table))
    end
    write(io, envstring(floatname, PType))
  end
end

doc"""
  `generate_c_library(path, hpath, floatname, PType)`

"""
function generate_c_library{lattice, epochbits}(path::String, hpath::String, floatname::Symbol, PType::Type{PTile{lattice, epochbits}})
  #test to see if the path exists.
  isdir(path) || mkdir(path)
  #next, create a file for the header.
  hfile_fio = open(string(path, "/", floatname, ".h"), "w")
  cfile_fio = open(string(path, "/", floatname, ".c"), "w")
  try
    #write the contents
    cgen.write_hfile(hfile_fio, hpath, floatname, lattice)
    cgen.write_cfile(cfile_fio, hpath, floatname, PType)
  finally
    #close the directory
    close(hfile_fio)
    close(cfile_fio)
  end
end
#=
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
=#

export generate_c_library
