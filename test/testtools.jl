#testtools.jl

#and a general purpose function for testing an operation against a matrix
function testop(op, inputs, expected, testname)
  #now create a matrix of warlpiris
  dimension = length(inputs)
  totalsize = dimension * dimension
  fails = 0
  for i=1:dimension
    for j=1:dimension
      try
        res = op(▾(inputs[i]), ▾(inputs[j]))

        if (res != expected[i, j])
          println("$i, $j: $(inputs[i]) $op $(inputs[j]) failed as $(res); should be $(expected[i,j])")
          fails += 1
        end
      catch e
        println("$i, $j: $(inputs[i]) $op $(inputs[j]) failed due to thrown error: $e")
        bt = catch_backtrace()
        s = sprint(io->Base.show_backtrace(io, bt))
        println("$s")
        fails += 1
      end
    end
  end
  println("$testname: $op $fails / $(totalsize) = $(100 * fails/totalsize)% failure!")
end

#a general purpose function for testing operations in the c framework.
function testop_c(op, PTtype)

  dimension = length(PTtype)
  totalsize = dimension * dimension
  fails = 0

  for tile1 in PTtype
    for tile2 in PTtype
      fails += testop_c(op, tile1, tile2)
    end
  end
  println("for $PTtype, $op in C fails $fails / $(totalsize) = $(100 * fails/totalsize)% failure!")
end

function testop_c{PType}(op, pval1::PType, pval2::PType; describe::Bool = false)
  if PType <: PTile
    pval1 = ▾(pval1)
    pval2 = ▾(pval2)
  end

  describe && println("$pval1 $op $pval2")

  try
    expected = op(pval1, pval2)
    res = c_fun[op](pval1, pval2)

    if res != expected
      println("$pval1 $op $pval2 failed as $res, should be $expected")
      return true
    end

  catch e
    println("$pval1 $op $pval2: failed due to thrown error: $e")
    bt = catch_backtrace()
    s = sprint(io->Base.show_backtrace(io, bt))
    println("$s")
    return true
  end

  return false
end
