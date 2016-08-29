#tools.jl - various tools to make programming Lnums easier.

doc"""
  @i reinterprets a PTile as an integer
"""
macro i(p)
  esc(:(reinterpret(UInt64, $p)))
end

doc"""
  @s reinterprets as a signed integer
"""
macro s(p)
  esc(:(reinterpret(Int64, $p)))
end

doc"""
  @p reinterprets a integer as a PTile
"""
macro p(i)
  esc(:(reinterpret(PTile{lattice, epochbits}, $i)))
end

bitlength{lattice, epochbits}(::Type{PTile{lattice, epochbits}}) = 1 + epochbits + latticebits(lattice)

doc"""
the `@gen_code` macro rejigs the standard julia `@generate` macro so that at the
end the function expects a `code` expression variable that can be created and
automatically extended using the `@code` macro.
"""
macro gen_code(f)
  #make sure this macro precedes a function definition.
  isa(f, Expr) || error("gen_code macro must precede a function definition")
  (f.head == :function) || error("gen_code macro must precede a function definition")

  #automatically generate a 'code-creation' statement at the head of the function.
  unshift!(f.args[2].args, :(code = :(nothing)))
  #insert the code release statement at the tail of the function.
  push!(f.args[2].args, :(code))

  #return the escaped function to the parser so that it generates the new function.
  ##next, wrap the function f inside of the @generated macro and escape it
  esc(:(@generated $f))
end

#fname extracts the function name from the expression
function __fname(ex::Expr)
  ex.args[1].args[1]
end
#__vfunc generates a type-parameter variadic function head.
function __vfunc(fn)
  :($fn{lattice, epochbits})
end

doc"""
  the `@pfunction` macro is prepended to a function defined with parameters that
  are generic Unum2 types (PTile, PBound), and generates the function with
  default parameters {lattice, epochbits}.  Also gives access to default type
  variables P for PTile{lattice, epochbits}, and B for PBound{lattice, epochbits},
  ∅ for the NaN PBound and R "for all projective reals" PBound.
"""
#creates a universal function f that operates across all types of unums
macro pfunction(f)
  if (f.head == :(=))
    (f.args[1].head == :call) || throw(ArgumentError("@pfunction macro must operate on a function"))
  elseif (f.head == :function)
    nothing  #we're good.
  else
    throw(ArgumentError("@pfunction macro must operate on a function"))
  end

  #extract the functionname and append the {ESS,FSS} signature onto the functionname
  functionname = __fname(f)
  functioncall = __vfunc(functionname)

  #replace the function call.
  f.args[1].args[1] = functioncall

  #next work with the parameters
  parameters = f.args[1].args

  ptypedefs = quote
    T = PTile{lattice, epochbits}
    B = PBound{lattice, epochbits}
    N = emptyset(PBound{lattice, epochbits})
    R = allprojectivereals(PBound{lattice, epochbits})
  end

  #append these type definitions onto fsmall and flarge.
  unshift!(f.args[2].args, ptypedefs)

  for idx = 2:length(parameters)
    if (isa(parameters[idx], Expr)
         && (parameters[idx].head == :(::)))
      utype = parameters[idx].args[2]
      if (utype in [:PTile, :PBound])
        f.args[1].args[idx].args[2] = :($utype{lattice, epochbits})
      elseif isa(utype, Expr)
        if (utype.head == :curly) && (utype.args[1] == :Type) && (utype.args[2] in [:PTile, :Pbound])
          f.args[1].args[idx].args[2].args[2] = :($utype{lattice, epochbits})
        end
      end
    end
  end

  return esc(:(Base.@__doc__ $f))
end
