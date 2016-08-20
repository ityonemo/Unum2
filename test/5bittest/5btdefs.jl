ooooo = PFloat5(0)
ooool = PFloat5(0.1)
ooolo = PFloat5(0.125)
oooll = PFloat5(0.13)
ooloo = PFloat5(0.25)
oolol = PFloat5(0.3)
oollo = PFloat5(0.5)
oolll = PFloat5(0.6)
olooo = PFloat5(1)
olool = PFloat5(1.5)
ololo = PFloat5(2)
ololl = PFloat5(3)
olloo = PFloat5(4)
ollol = PFloat5(6)
olllo = PFloat5(8)
ollll = PFloat5(9)

lllll = -PFloat5(0.1)
llllo = -PFloat5(0.125)
lllol = -PFloat5(0.13)
llloo = -PFloat5(0.25)
lloll = -PFloat5(0.3)
llolo = -PFloat5(0.5)
llool = -PFloat5(0.6)
llooo = -PFloat5(1)
lolll = -PFloat5(1.5)
lollo = -PFloat5(2)
lolol = -PFloat5(3)
loloo = -PFloat5(4)
looll = -PFloat5(6)
loolo = -PFloat5(8)
loool = -PFloat5(9)

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
