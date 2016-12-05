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

  dimension = length(exacts(PTtype))
  totalsize = dimension * dimension
  fails = 0

  for tile1 in exacts(PTtype)
    for tile2 in exacts(PTtype)
      pval1 = ▾(tile1)
      pval2 = ▾(tile2)
      #println("doing $pval1 + $pval2")
      try
        expected = op(pval1, pval2)
        res = c_fun[op](pval1, pval2)
        if res != expected
          println("$tile1 $op $tile2 failed as $res, should be $expected")
          fails += 1
        end
      catch e
        println("$tile1 $op $tile2: failed due to thrown error: $e")
        bt = catch_backtrace()
        s = sprint(io->Base.show_backtrace(io, bt))
        println("$s")
        fails += 1
      end
    end
  end

  println("for $PTtype, $op fails $fails / $(totalsize) = $(100 * fails/totalsize)% failure!")

end
