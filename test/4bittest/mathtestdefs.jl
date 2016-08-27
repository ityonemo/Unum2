looo = PTile4(Inf)
lool = PTile4(-3)
lolo = PTile4(-2)
loll = PTile4(-1.5)
lloo = PTile4(-1)
llol = PTile4(-0.75)
lllo = PTile4(-0.5)
llll = PTile4(-0.25)
oooo = PTile4(0)
oool = PTile4(0.25)
oolo = PTile4(0.5)
ooll = PTile4(0.75)
oloo = PTile4(1)
olol = PTile4(1.5)
ollo = PTile4(2)
olll = PTile4(3)

#and a general purpose function for testing an operation,
function testop(op, expected)
  #now create a matrix of warlpiris
  fails = 0
  for i=1:16
    for j=1:16
      try
        res = op(▾(p4vec[i]), ▾(p4vec[j]))

        if (res != expected[i, j])
          println("$i, $j: $(p4vec[i]) $op $(p4vec[j]) failed as $(res); should be $(expected[i,j])")
          fails += 1
        end
      catch e
        println("$i, $j: $(p4vec[i]) $op $(p4vec[j]) failed due to thrown error: $e")
        bt = catch_backtrace()
        s = sprint(io->Base.show_backtrace(io, bt))
        println("$s")
        fails += 1
      end
    end
  end
  println("$op $fails / 256 = $(100 * fails/256)% failure!")
end
