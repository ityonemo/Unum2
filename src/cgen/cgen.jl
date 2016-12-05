
doc"""
  `Unum2.cgen`

  a module containg methods to generate Unum2 c libraries.
"""
module cgen

  using ...Unum2: table_name, latticebits, incrementor
  using ...Unum2

  #general c compilation tools.
  include("c-compilation.jl")

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

  tablelist=[
    :add, :add_inv, :add_cross,
    :sub, :sub_inv, :sub_cross,

    :inv_add_inv,
    :inv_sub,
    :inv_sub_cross,

    :sub_epoch,
    :sub_inv_epoch,
    :sub_cross_epoch,

    :mul, :div, :inv_div, :inv]

  multitablelist = [:add, :add_inv, :add_cross, :sub, :sub_inv, :sub_cross]

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
    "const PEnv $(label)_ENV={$lb,$epochbits,$inc,__$(lattice)_table_counts,{$tablenames}};\n"
  end

  function setter_string(label::Symbol)
    "void set_$label(){PENV = (PEnv *)(&$(label)_ENV);}\n"
  end

  typealias IArray{N} Union{Array{UInt64, N}, Array{Int64, N}}
  rearrange(lut::IArray{1}) = lut
  function rearrange(lut::IArray{2})
    entries = size(lut, 1)
    indexcalc = (lhs_idx, rhs_idx) -> (lhs_idx - 1) * (entries) + rhs_idx

    res = lut[:]
    for lhs_idx = 1:entries, rhs_idx = 1:entries
      res[indexcalc(lhs_idx, rhs_idx)] = lut[lhs_idx, rhs_idx]
    end

    res
  end

  function rearrange(lut::IArray{3})
    tables = size(lut, 1)
    entries = size(lut, 2)
    indexcalc = (table_idx, lhs_idx, rhs_idx) -> (table_idx - 1) * (entries) * (entries) + (lhs_idx - 1) * (entries) + rhs_idx

    #copy the res vector as a flattend lut.
    res = lut[:]
    for table_idx = 1:tables, lhs_idx = 1:entries, rhs_idx = 1:entries
      res[indexcalc(table_idx, lhs_idx, rhs_idx)] = lut[table_idx, lhs_idx, rhs_idx]
    end

    res
  end

  #generate a string that creates the table in C.
  function tablestring(lattice::Symbol, table::Symbol)
    table_to_output = table_name(lattice, table)
    isdefined(Unum2, table_to_output) || throw(ArgumentError("error attempting to access an undefined lattice"))
    table_vals = eval(Unum2, :($table_to_output))

    l = length(table_vals)
    contents = join(map((x) -> string("0x",hex(reinterpret(UInt64, x), 16)), rearrange(table_vals)[:]), ",")
    "const unsigned long long $table_to_output[$l]={$contents};\n"
  end

  header_cstring(label::Symbol) = "#include \"$label.h\"\n"

  function tablecount(lattice::Symbol, table::Symbol)
    table_to_output = table_name(lattice, table)
    isdefined(Unum2, table_to_output) || throw(ArgumentError("error attempting to access the undefined lattice $lattice"))
    table = eval(Unum2, :($table_to_output))

    size(table, 1)
  end

  function tablesize_cstring(lattice::Symbol)
    tstring = join(map((table) -> tablecount(lattice, table), multitablelist), ",")
    "const int __$(lattice)_table_counts[6]={$tstring};\n"
  end

  function write_cfile{lattice, epochbits}(io::IO, hdir::String, floatname::Symbol, PType::Type{PTile{lattice, epochbits}})
    write(io, header_cstring(floatname))
    for table in tablelist
      write(io, tablestring(lattice, table))
    end
    write(io, tablesize_cstring(lattice))
    write(io, envstring(floatname, PType))
    write(io, setter_string(floatname))
  end
end

doc"""
  `generate_lattice_files(path, hpath, floatname, PType <: PTile)`
"""
function generate_lattice_files{lattice, epochbits}(path::String, hpath::String, floatname::Symbol, PType::Type{PTile{lattice, epochbits}})
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

doc"""
  `generate_library(path_to_c_library::String, pfloat_label::Symbol, destination_dir::String="./")`
  `generate_library(path_to_c_library::String, pfloat_labels::Array{Symbol, 1}, destination_dir::String="./")`
  returns the full path to the library file
"""
generate_library(path_to_c_library::String, pfloat_label::Symbol, destination_dir::String="./") = generate_library(path_to_c_library, [pfloat_label], destination_dir)
function generate_library(path_to_c_library::String, pfloat_labels::Array{Symbol,1}, destination_dir::String="./")
  #check to see if the path_to_c_library is actually a dir.
  isdir(path_to_c_library) || return nothing

  #create the temp directory
  mktempdir((tdir)->begin
    #next, copy the contents of path_to_c_library into the temp directory
    cp(path_to_c_library, tdir; remove_destination=true)

    #then, generate the c files for all of the desired lattices.
    for lattice_label in pfloat_labels
    PType = import_lattice(lattice_label)
    generate_lattice_files(string(tdir,"/src"), "../include", lattice_label, PType)
    end

    cgen.compile(tdir)
    cgen.link(tdir)

    respath = joinpath(destination_dir,"libpfloat.so")
    #now move the thing out of the temporary directory
    cp(joinpath(tdir, "libpfloat.so"), respath, remove_destination=true)

    #return the path for the resulting library
    respath
  end)
end

export generate_lattice_files, generate_library
