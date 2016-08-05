looo = PFloat4(Inf)
lool = PFloat4(-3)
lolo = PFloat4(-2)
loll = PFloat4(-1.5)
lloo = PFloat4(-1)
llol = PFloat4(-0.75)
lllo = PFloat4(-0.5)
llll = PFloat4(-0.25)
oooo = PFloat4(0)
oool = PFloat4(0.25)
oolo = PFloat4(0.5)
ooll = PFloat4(0.75)
oloo = PFloat4(1)
olol = PFloat4(1.5)
ollo = PFloat4(2)
olll = PFloat4(3)

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
