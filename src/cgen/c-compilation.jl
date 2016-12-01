#c-compilation.jl - files relating to compilation of c files
const cc = split("cc -I. -fPIC")

function compile(directory)
  srcdir = joinpath(directory, "src")
  for file in readdir(srcdir)
    (filename, extension) = splitext(file)

    if extension == ".c"
      cfile = joinpath(srcdir, file) # path to files
      objdir = joinpath(directory, "obj")
      ofile = joinpath(objdir, string(filename,".o"))
      run(`$cc -c -o $ofile $cfile`)
    end
  end
end

function link(directory)
  objdir = joinpath(directory, "obj")
  objlist = [joinpath(objdir, file) for file in readdir(objdir) if splitext(file)[2] == ".o"]
  sopath = joinpath(directory, "libpfloat.so")
  run(`$cc -shared -Wl,-soname,libpfloat.so -o $sopath $objlist`)
end
