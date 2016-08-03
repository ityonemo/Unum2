#4bt-test-add.jl
#testing an addition table for the 4 bit PFloat.
#note the vector looks like this:
#  inf (inf -2) -2  (-2 -1) -1  (-1 -0.5) -0.5 (-0.5 0)     0  (0 0.5) 0.5 (0.5 1)  1   (1 2)  2   (2 inf)
# [1000, 1001, 1010, 1011, 1100, 1101,    1110, 1111,     0000, 0001, 0010, 0011, 0100, 0101, 0110, 0111]

btadd = [
#   inf    (inf -2)        -2        (-2 -1)         -1         (-1 -0.5)     -0.5        (-0.5 0)       0     (0 0.5)         0.5          (0.5 1)      1           (1 2)           2         (2 inf)
#inf +...                                                                                            |
  ▾(looo), ▾(looo),     ▾(looo),     ▾(looo),     ▾(looo),     ▾(looo),     ▾(looo),     ▾(looo),     ▾(looo), ▾(looo),     ▾(looo),     ▾(looo),     ▾(looo),     ▾(looo),     ▾(looo),    ▾(looo);
#(inf -2) + ...                                                                                      |
  ▾(looo), ▾(lool),     ▾(lool),     ▾(lool),     ▾(lool),     ▾(lool),     ▾(lool),     ▾(lool),     ▾(lool), lool → loll, lool → loll, lool → llol, lool → llol, lool → llll, lool → llll, lool → olll;
#-2 + ...                                                                                            |
  ▾(looo), ▾(lool),     ▾(lool),     ▾(lool),     ▾(lool),     ▾(lool),     ▾(lool),     ▾(lool),     ▾(lolo), ▾(loll),     ▾(loll),     ▾(loll),     ▾(lloo),     llol → llll, ▾(oooo),     oool → olll;
#(-2 -1) + ...                                                                                       |
  ▾(looo), ▾(lool),     ▾(lool),     ▾(lool),     ▾(lool),     lool → loll, lool → loll, lool → loll, ▾(loll), loll → llol, loll → llll, loll → llll, llol → llll, llol → ooll, oool → ooll, oool → olll;
#-1 + ...                                                                                            |
  ▾(looo), ▾(lool),     ▾(lool),     ▾(lool),     ▾(lolo),     lool → loll, ▾(loll),     ▾(loll),     ▾(lloo), ▾(llol),     ▾(lllo),     ▾(llll),     ▾(oooo),     oooo → ooll, ▾(oloo),     olol → olll;
#(-1 -0.5) + ...                                                                                     |
  ▾(looo), ▾(lool),     ▾(lool),     lool → loll, ▾(loll),     ▾(loll),     ▾(loll),     loll → llol, ▾(llol), llol → llll, ▾(llll),     llll → oool, ▾(oool),     oool → olol, ▾(olol),     olol → olll;
#-0.5 + ...                                                                                          |
  ▾(looo), ▾(lool),     ▾(lool),     lool → loll, ▾(loll),     ▾(loll),     ▾(lloo),     ▾(llol),     ▾(lllo), ▾(llll),     ▾(oooo),     ▾(oool),     ▾(oolo),     ooll → olol, ▾(olol),     olol → olll;
#(-0.5 0) + ...                                                                                      |
  ▾(looo), ▾(lool),     ▾(lool),     lool → loll, ▾(loll),     loll → llol, ▾(llol),     llol → llll, ▾(llll), llll → oool, ▾(oool),     oool → ooll, ▾(ooll),     ooll → olol, ▾(olol),     olol → olll;
#0 + ...                                                                                             |
  ▾(looo), ▾(lool),     ▾(lolo),     ▾(loll),     ▾(lloo),     ▾(llol),     ▾(lllo),     ▾(llll),     ▾(oooo), ▾(oool),     ▾(oolo),     ▾(ooll),     ▾(oloo),     ▾(olol),     ▾(ollo),    ▾(olll);
#(0 0.5) + ...                                                                                       |
  ▾(looo), lool → loll, ▾(loll),     loll → llol, ▾(llol),     llol → llll, ▾(llll),     llll → oool, ▾(oool), oool → ooll, ▾(ooll),     ooll → olol, ▾(olol),     olol → olll, ▾(olll),    ▾(olll);
#0.5 + ...                                                                                           |
  ▾(looo), lool → loll, ▾(loll),     loll → llol, ▾(lllo),     ▾(llll),     ▾(oooo),     ▾(oool),     ▾(oolo), ▾(ooll),     ▾(oloo),     ▾(olol),     ▾(olol),     olol → olll, ▾(olll),    ▾(olll);
#(0.5 1) + ...                                                                                       |
  ▾(looo), lool → loll, ▾(loll),     loll → llll, ▾(llll),     llll → oool, ▾(oool),     oool → ooll, ▾(ooll), ooll → olol, ▾(olol),     ▾(olol),     olol → olll, olol → olll, ▾(olll),    ▾(olll);
#1 + ...                                                                                             |
  ▾(looo), lool → loll, ▾(lloo),     llol → llll, ▾(oooo),     ▾(oool),     ▾(oolo),     ▾(ooll),     ▾(oloo), ▾(olol),     ▾(olol),     ▾(olol),     ▾(ollo),     ▾(olll),     ▾(olll),    ▾(olll);
#(1 2) + ...                                                                                         |
  ▾(looo), lool → llll, loll → llll, loll → ooll, oool → ooll, oool → olol, ooll → olol, ooll → olol, ▾(olol), olol → olll, olol → olll, ▾(olll),     ▾(olll),     ▾(olll),     ▾(olll),    ▾(olll);
#2 + ...                                                                                             |
  ▾(looo), lool → oool, ▾(oooo),     oool → olol, ▾(oloo),     ▾(olol),     ▾(olol),     ▾(olol),     ▾(ollo), ▾(olll),     ▾(olll),     ▾(olll),     ▾(olll),     ▾(olll),     ▾(olll),    ▾(olll);
#(2 inf) + ...                                                                                       |
  ▾(looo), lool → olll, oool → olll, oool → olll, olol → olll, olol → olll, olol → olll, olol → olll, ▾(olll), ▾(olll),     ▾(olll),     ▾(olll),     ▾(olll),     ▾(olll),     ▾(olll),    ▾(olll);
]
