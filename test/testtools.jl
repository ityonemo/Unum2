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
