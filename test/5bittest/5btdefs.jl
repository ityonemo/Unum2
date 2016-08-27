ooooo = PTile5(0)
ooool = PTile5(0.1)
ooolo = PTile5(0.125)
oooll = PTile5(0.13)
ooloo = PTile5(0.25)
oolol = PTile5(0.3)
oollo = PTile5(0.5)
oolll = PTile5(0.6)
olooo = PTile5(1)
olool = PTile5(1.5)
ololo = PTile5(2)
ololl = PTile5(3)
olloo = PTile5(4)
ollol = PTile5(6)
olllo = PTile5(8)
ollll = PTile5(9)

lllll = -PTile5(0.1)
llllo = -PTile5(0.125)
lllol = -PTile5(0.13)
llloo = -PTile5(0.25)
lloll = -PTile5(0.3)
llolo = -PTile5(0.5)
llool = -PTile5(0.6)
llooo = -PTile5(1)
lolll = -PTile5(1.5)
lollo = -PTile5(2)
lolol = -PTile5(3)
loloo = -PTile5(4)
looll = -PTile5(6)
loolo = -PTile5(8)
loool = -PTile5(9)

p5vec = [ooool, ooolo, oooll, ooloo, oolol, oollo, oolll, olooo, olool, ololo, ololl, olloo, ollol, olllo, ollll]

#and a general purpose function for testing an operation,
function testop5(op, expected)
  #now create a matrix of warlpiris
  fails = 0
  for i=1:15
    for j=1:15
      try
        res = op(▾(p5vec[i]), ▾(p5vec[j]))

        if (res != expected[i, j])
          println("$i, $j: $(p5vec[i]) $op $(p5vec[j]) failed as $(res); should be $(expected[i,j])")
          fails += 1
        end
      catch e
        println("$i, $j: $(p5vec[i]) $op $(p5vec[j]) failed due to thrown error: $e")
        bt = catch_backtrace()
        s = sprint(io->Base.show_backtrace(io, bt))
        println("$s")
        fails += 1
      end
    end
  end
  println("$op $fails / 225 = $(100 * fails/225)% failure!")
end
