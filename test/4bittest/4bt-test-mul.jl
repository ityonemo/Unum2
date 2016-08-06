#4bt-test-mul.jl
#testing an multiplication table for the 4 bit PFloat.
#note the vector looks like this:
#  inf (inf -2) -2  (-2 -1) -1  (-1 -0.5) -0.5 (-0.5 0)     0  (0 0.5) 0.5 (0.5 1)  1   (1 2)  2   (2 inf)
# [1000  1001  1010  1011  1100  1101     1110  1111      0000  0001  0010  0011  0100  0101  0110  0111]

R = ℝᵖ(PBound4)

btmul = [
#   inf    (inf -2)        -2        (-2 -1)         -1   (-1 -0.5)     -0.5        (-0.5 0)       0     (0 0.5)         0.5          (0.5 1)      1           (1 2)           2         (2 inf)
#inf * ...                                                                                           |
  ▾(looo)  ▾(looo)      ▾(looo)      ▾(looo)      ▾(looo) ▾(looo)     ▾(looo)     ▾(looo)      R        ▾(looo)     ▾(looo)      ▾(looo)      ▾(looo)      ▾(looo)      ▾(looo)     ▾(looo);
#(inf -2) * ...                                                                               |
  ▾(looo)  ▾(olll)      ▾(olll)      ▾(olll)      ▾(olll) olol → olll olol → olll oool → olll  ▾(oooo)  lool → llll lool → loll  lool → loll  ▾(lool)      ▾(lool)      ▾(lool)     ▾(lool);
#-2 * ...                                                                                     |
  ▾(looo)  ▾(olll)      ▾(olll)      ▾(olll)      ▾(ollo) ▾(olol)     ▾(oloo)     oool → ooll  ▾(oooo)  llol → llll ▾(lloo)      ▾(loll)      ▾(lolo)      ▾(lool)      ▾(lool)     ▾(lool);
#(-2 -1) * ...                                                                                |
  ▾(looo)  ▾(olll)      ▾(olll)      olol → olll  ▾(olol) ooll → olol ▾(ooll)     oool → ooll  ▾(oooo)  llol → llll ▾(llol)      loll → llol  ▾(loll)      lool → loll  ▾(lool)     ▾(lool);
#-1 * ...                                                                                     |
  ▾(looo)  ▾(olll)      ▾(ollo)      ▾(olol)      ▾(oloo) ▾(ooll)     ▾(oolo)     ▾(oool)      ▾(oooo)  ▾(llll)     ▾(lllo)      ▾(llol)      ▾(lloo)      ▾(loll)      ▾(lolo)     ▾(lool);
#(-1 -0.5) * ...                                                                              |
  ▾(looo)  olol → olll  ▾(olol)      ooll → olol  ▾(ooll) oool → ooll ▾(oool)     ▾(oool)      ▾(oooo)  ▾(llll)     ▾(llll)      llol → llll  ▾(llol)      loll → llol  ▾(loll)     lool → loll;
#-0.5 * ...                                                                                   |
  ▾(looo)  olol → olll  ▾(oloo)      ▾(ooll)      ▾(oolo) ▾(oool)     ▾(oool)     ▾(oool)      ▾(oooo)  ▾(llll)     ▾(llll)      ▾(llll)      ▾(lllo)      ▾(llol)      ▾(lloo)     lool → loll;
#(-0.5 0) * ...                                                                               |
  ▾(looo)  oool → olll  oool → ooll  oool → ooll  ▾(oool) ▾(oool)     ▾(oool)     ▾(oool)      ▾(oooo)  ▾(llll)     ▾(llll)      ▾(llll)      ▾(llll)      llol → llll  llol → llll lool → llll;
#0 * ...                                                                                      |
  R        ▾(oooo)      ▾(oooo)      ▾(oooo)      ▾(oooo) ▾(oooo)     ▾(oooo)     ▾(oooo)      ▾(oooo)  ▾(oooo)     ▾(oooo)      ▾(oooo)      ▾(oooo)      ▾(oooo)      ▾(oooo)     ▾(oooo);
#(0 0.5) * ...                                                                                |
  ▾(looo)  lool → llll  llol → llll  llol → llll  ▾(llll) ▾(llll)     ▾(llll)     ▾(llll)      ▾(oooo)  ▾(oool)     ▾(oool)      ▾(oool)      ▾(oool)      oool → ooll  oool → ooll oool → olll;
#0.5 + ...                                                                                    |
  ▾(looo)  lool → loll  ▾(lloo)      ▾(llol)      ▾(lllo) ▾(llll)     ▾(llll)     ▾(llll)      ▾(oooo)  ▾(oool)     ▾(oool)      ▾(oool)      ▾(oolo)      ▾(ooll)      ▾(oloo)     olol → olll;
#(0.5 1) * ...                                                                                |
  ▾(looo)  lool → loll  ▾(loll)      loll → llol  ▾(llol) llol → llll ▾(llll)     ▾(llll)      ▾(oooo)  ▾(oool)     ▾(oool)      oool → ooll  ▾(ooll)      ooll → olol  ▾(olol)     olol → olll;
#1 * ...                                                                                      |
  ▾(looo)  ▾(lool)      ▾(lolo)      ▾(loll)      ▾(lloo) ▾(llol)     ▾(lllo)     ▾(llll)      ▾(oooo)  ▾(oool)     ▾(oolo)      ▾(ooll)      ▾(oloo)      ▾(olol)      ▾(ollo)     ▾(olll);
#(1 2) + ...                                                                                  |
  ▾(looo)  ▾(lool)      ▾(lool)      lool → loll  ▾(loll) loll → llol ▾(llol)     llol → llll  ▾(oooo)  oool → ooll ▾(ooll)      ooll → olol  ▾(olol)      olol → olll  ▾(olll)     ▾(olll);
#2 + ...                                                                                      |
  ▾(looo)  ▾(lool)      ▾(lool)      ▾(lool)      ▾(lolo) ▾(loll)     ▾(lloo)     llol → llll  ▾(oooo)  oool → ooll ▾(oloo)      ▾(olol)      ▾(ollo)      ▾(olll)      ▾(olll)     ▾(olll);
#(2 inf) + ...                                                                                |
  ▾(looo)  ▾(lool)      ▾(lool)      ▾(lool)      ▾(lool) lool → loll lool → loll lool → llll  ▾(oooo)  oool → olll olol → olll  olol → olll  ▾(olll)      ▾(olll)      ▾(olll)     ▾(olll);
]
