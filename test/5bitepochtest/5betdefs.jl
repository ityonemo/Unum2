ooooo = PTile5e(0)
ooool = PTile5e(0.1)
ooolo = PTile5e(0.125)
oooll = PTile5e(0.13)
ooloo = PTile5e(0.25)
oolol = PTile5e(0.3)
oollo = PTile5e(0.5)
oolll = PTile5e(0.6)
olooo = PTile5e(1)
olool = PTile5e(1.5)
ololo = PTile5e(2)
ololl = PTile5e(3)
olloo = PTile5e(4)
ollol = PTile5e(6)
olllo = PTile5e(8)
ollll = PTile5e(9)

lllll = -PTile5e(0.1)
llllo = -PTile5e(0.125)
lllol = -PTile5e(0.13)
llloo = -PTile5e(0.25)
lloll = -PTile5e(0.3)
llolo = -PTile5e(0.5)
llool = -PTile5e(0.6)
llooo = -PTile5e(1)
lolll = -PTile5e(1.5)
lollo = -PTile5e(2)
lolol = -PTile5e(3)
loloo = -PTile5e(4)
looll = -PTile5e(6)
loolo = -PTile5e(8)
loool = -PTile5e(9)

p5evec = [ooool, ooolo, oooll, ooloo, oolol, oollo, oolll, olooo, olool, ololo, ololl, olloo, ollol, olllo, ollll]

testop5e(op, expected) = testop(op, p5evec, expected, :PFloat5e)
