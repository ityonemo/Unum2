#necessary if PFloat5 has not been previously imported.
#import_lattice(:PFloat5)

#generating environment H files
@test Unum2.cgen.table_hstring(:Lnum5, :mul) == "extern const unsigned long long __Lnum5_mul_table[9];\n"

#generating table C files
@test Unum2.cgen.header_cstring(:PFloat5) == "#include \"PFloat5.h\"\n"
#test out creating a table string.
@test Unum2.cgen.tablestring(:Lnum5, :mul) == "const unsigned long long __Lnum5_mul_table[9]={0x0000000000000004,0x0000000000000006,0x0000000000000000,0x0000000000000006,0x0000000000000000,0x0000000000000002,0x0000000000000000,0x0000000000000002,0x0000000000000004};\n"
#test out creating an environment string.
@test Unum2.cgen.envstring(:PFloat5, PTile5) == "const PEnv PFloat5_ENV={3,1,0x0800000000000000,{__Lnum5_add_table,__Lnum5_add_inv_table,__Lnum5_add_cross_table,__Lnum5_sub_table,__Lnum5_sub_epoch_table,__Lnum5_sub_inv_table,__Lnum5_sub_inv_epoch_table,__Lnum5_sub_cross_table,__Lnum5_sub_cross_epoch_table,__Lnum5_mul_table,__Lnum5_div_table,__Lnum5_inv_div_table,__Lnum5_inv_table}};\n"

#open the reference file.
#the target directory
tgtdir = string(Pkg.dir("Unum2"), "/test/tgt")
#the reference directory
refdir = string(Pkg.dir("Unum2"), "/test/res")

generate_c_library(tgtdir, "../include", :PFloat5, PTile5)

reference_header_file = open(string(tgtdir, "/PFloat5.h"), "r")
target_header_file    = open(string(refdir, "/PFloat5.h"), "r")
try
  while !(eof(reference_header_file))
    @test chomp(readline(reference_header_file)) == chomp(readline(target_header_file))
  end
finally
  close(reference_header_file)
  close(target_header_file)
end

reference_code_file = open(string(tgtdir, "/PFloat5.c"), "r")
target_code_file    = open(string(refdir, "/PFloat5.c"), "r")
try
  while !(eof(reference_code_file))
    @test chomp(readline(reference_code_file)) == chomp(readline(target_code_file))
  end
finally
  close(reference_code_file)
  close(target_code_file)
end

#clean up.
rm(tgtdir, recursive=true)
