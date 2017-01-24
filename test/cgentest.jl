#necessary if PFloat5 has not been previously imported.
#import_lattice(:PFloat5)

#generating environment H files
@test Unum2.cgen.table_hstring(:Lnum5, :mul) == "extern const unsigned long long __Lnum5_mul_table[9];\n"
#generating table C files
@test Unum2.cgen.header_cstring(:PFloat5) == "#include \"PFloat5.h\"\n"
#test out creating a table string.
@test Unum2.cgen.tablestring(:Lnum5, :mul) == "const unsigned long long __Lnum5_mul_table[9]={0x0000000000000004,0x0000000000000006,0x0000000000000000,0x0000000000000006,0x0000000000000000,0x0000000000000002,0x0000000000000000,0x0000000000000002,0x0000000000000004};\n"
#test out creating an environment string.
@test Unum2.cgen.envstring(:PFloat5, PTile5) == "const PEnv PFloat5_ENV={3,1,0x0800000000000000,__Lnum5_table_counts,{__Lnum5_add_table,__Lnum5_add_inv_table,__Lnum5_add_cross_table,__Lnum5_sub_table,__Lnum5_sub_inv_table,__Lnum5_sub_cross_table,__Lnum5_inv_add_inv_table,__Lnum5_inv_sub_table,__Lnum5_inv_sub_cross_table,__Lnum5_sub_epoch_table,__Lnum5_sub_inv_epoch_table,__Lnum5_sub_cross_epoch_table,__Lnum5_mul_table,__Lnum5_div_table,__Lnum5_inv_div_table,__Lnum5_inv_table}};\n"
#open the reference file.
#the target directory
mktempdir((tgtdir) -> begin
  #the reference directory
  refdir = string(Pkg.dir("Unum2"), "/test/res")

  generate_lattice_files(tgtdir, "../include", :PFloat5, PTile5)

  reference_header_file = open(string(refdir, "/PFloat5.h"), "r")
  target_header_file    = open(string(tgtdir, "/PFloat5.h"), "r")
  try
    while !(eof(reference_header_file))
      @test chomp(readline(reference_header_file)) == chomp(readline(target_header_file))
    end
  finally
    close(reference_header_file)
    close(target_header_file)
  end

  reference_code_file = open(string(refdir, "/PFloat5.c"), "r")
  target_code_file    = open(string(tgtdir, "/PFloat5.c"), "r")

  try
    while !(eof(reference_code_file))
      @test chomp(readline(reference_code_file)) == chomp(readline(target_code_file))
    end
  finally
    close(reference_code_file)
    close(target_code_file)
  end
end)

################################################################################
## COMPREHENSIVE TESTING of lattices.

#a shimming type to convert from Julia PBounds to C PBounds
type PShim
  lower::UInt64
  upper::UInt64
  state::UInt64
end

PShim(b::PBound) = PShim(reinterpret(UInt64, b.lower), reinterpret(UInt64, b.upper), UInt64(b.state))
(::Type{PBound{lattice, epochbits}}){lattice, epochbits}(s::PShim) = PBound{lattice, epochbits}(
  reinterpret(PTile{lattice,epochbits}, s.lower),
  reinterpret(PTile{lattice,epochbits}, s.upper),
  UInt8(s.state & 0x0000_0000_0000_00FF)
)

function add_fun{lattice, epochbits}(x::PBound{lattice, epochbits}, y::PBound{lattice, epochbits})
  cres = PShim(0, 0, 0)
  setfunction[PBound{lattice, epochbits}]()
  ccall((:add, "./libpfloat.so"), Void, (Ref{PShim}, Ref{PShim}, Ref{PShim}), Ref{PShim}(cres), Ref{PShim}(PShim(x)), Ref{PShim}(PShim(y)))
  #convert back to the proper pbound
  PBound{lattice, epochbits}(cres)
end

function mul_fun{lattice, epochbits}(x::PBound{lattice, epochbits}, y::PBound{lattice, epochbits})
  cres = PShim(0, 0, 0)
  setfunction[PBound{lattice, epochbits}]()
  ccall((:mul, "./libpfloat.so"), Void, (Ref{PShim}, Ref{PShim}, Ref{PShim}), Ref{PShim}(cres), Ref{PShim}(PShim(x)), Ref{PShim}(PShim(y)))
  #convert back to the proper pbound
  PBound{lattice, epochbits}(cres)
end

function div_fun{lattice, epochbits}(x::PBound{lattice, epochbits}, y::PBound{lattice, epochbits})
  cres = PShim(0, 0, 0)
  setfunction[PBound{lattice, epochbits}]()
  ccall((:div, "./libpfloat.so"), Void, (Ref{PShim}, Ref{PShim}, Ref{PShim}), Ref{PShim}(cres), Ref{PShim}(PShim(x)), Ref{PShim}(PShim(y)))
  #convert back to the proper pbound
  PBound{lattice, epochbits}(cres)
end

function fma_fun{lattice, epochbits}(a::PBound{lattice, epochbits}, b::PBound{lattice, epochbits}, c::PBound{lattice, epochbits})
  cres = PShim(0,0,0)
  setfunction[PBound{lattice, epochbits}]()
  ccall((:pfma, "./libpfloat.so"), Void, (Ref{PShim}, Ref{PShim}, Ref{PShim}, Ref{PShim}), Ref{PShim}(cres), Ref{PShim}(PShim(a)), Ref{PShim}(PShim(b)), Ref{PShim}(PShim(c)))
  PBound{lattice, epochbits}(cres)
end

const setfunction = Dict{Type, Function}(
  PBound5  => () -> ccall((:set_PFloat5,  "./libpfloat.so"), Void, ()),
  PBound4  => () -> ccall((:set_PFloat4,  "./libpfloat.so"), Void, ()),
  PBound5e => () -> ccall((:set_PFloat5e, "./libpfloat.so"), Void, ())
)

addf = +
mulf = *
divf = /
const c_fun = Dict{Function, Function}(
  addf => add_fun,
  mulf => mul_fun,
  divf => div_fun,
  fma  => fma_fun
)

generate_library(expanduser("~/code/Unum2-c"), [:PFloat5, :PFloat4, :PFloat5e])

#▾(Unum2.PTile{:Lnum5e,2}(0b10110)) * ▾(Unum2.PTile{:Lnum5e,2}(0b11110)) failed as ▾(Unum2.PTile{:Lnum5e,2}(0b01000)), should be ▾(Unum2.PTile{:Lnum5e,2}(0b00100))
#=
testop_c(*, PTile5e(2), PTile5e(-1/8), describe = true)
=#

include("cgen-epochtest.jl")
epochtest(PTile4)
epochtest(PTile5)
epochtest(PTile5e)

testop_c(+, PTile4)
testop_c(*, PTile4)
testop_c(/, PTile4)
testop_c(fma, PTile4, Val{:ternary})

testop_c(+, PTile5)
testop_c(*, PTile5)
testop_c(/, PTile5)
testop_c(fma, PTile5, Val{:ternary})

testop_c(+, PTile5e)
testop_c(*, PTile5e)
testop_c(/, PTile5e)
