#4bt-test-bounds.jl

#######################
## ADDITION

#make sure that additive inverses work
@test -(ooll → oloo) == (lloo → llol)
#and additive inverses of things that cross zero
@test -(lllo → oool) == (llll → oolo)
#as well as infinity.
@test -(ollo → loll) == (olol → lolo)

#testing various bound mathematics.
#(0.5 1] + (0.5 1] == (1 2]
@test (ooll → oloo) + (ooll → oloo) == (olol → ollo)
#test that bound addition annihilates exact ends.
@test (ooll → oloo) + (oolo → oloo) == (olol → ollo)
#...on both sides
@test (oolo → oloo) + (ooll → oloo) == (olol → ollo)
#...and reversewise
@test (oolo → ooll) + (ooll → oloo) == ▾(olol)
#test that compression to pmany works:
@test (oool → olol) + ▾(ollo) == ▾(olll)
#test that annhiliation to inf works:
@test (oool → olol) + ▾(looo) == ▾(looo)

# test that addition to something which rounds inf can give allreals
# (2 -2) + (2 inf) == allreals
@test (olll → lool) + ▾(olll) == ℝᵖ(PBound4)
# an even stranger one which is not strictly mathematically correct when read
# using a naive translation.  Also tests "effective tiling".
#(2 1] + [1] == allreals
@test (olll → oloo) + ▾(oloo) == ℝᵖ(PBound4)

#######################
## MULTIPLICATION

#make sure that multiplicative inverses work.
@test /(ooll → oloo) == (oloo → olol)
#when they round zero only
@test /(lloo → oloo) == (oloo → lloo)
@test /(lllo → ollo) == (oolo → lolo)
#when they round zero and round infinity
@test /(oloo → ooll) == (olol → oloo)

#test basic multiplication on bounds
#(0.5 1] * (0.5 1] == (0 1]
@test (ooll → oloo) * (ooll → oloo) == (oool → oloo)
#(0.5 1] * -((0.5 1]) == [1 0)
@test (ooll → oloo) * (-(ooll → oloo)) == (lloo → llll)
#bound endpoint annihilation.
#(0.5 2) * [0.5 1] == (0 2)
@test (ooll → olol) * (oolo → oloo) == (oool → olol)
#(0.5 2) * [0 0.5] == [0 1)
@test (oool → ollo) * (oooo → oool) == (oooo → ooll)
#(0.5 inf) * (0.5 2) == (0 inf)
@test (ooll → olll) * (ooll → olol) == (oool → olll)
#(0.5 inf] * (0.5 2) == (0 inf]
@test (ooll → looo) * (ooll → olol) == (oool → looo)

#test basic multiplication on things that round zero
#[-2 2] * (0 1/2) == (-1 1)
@test (lolo → ollo) * ▾(oool) == (llol → ooll)
#[-2 2) * (0 1] == [-2 2)
@test (lolo → olol) * (oool → oloo) == (lolo → olol)
#[-2 2) * [-1 0] == (-2 2]
@test (lolo → olol) * (lloo → oooo) == (loll → ollo)
#[-2 2) * inf == allreals
@test (lolo → ollo) * ▾(looo) == ℝᵖ(PBound4)

#test basic multiplication on things that round infinity.
#[2 -2] * [1/2 2) == [1 -1]
@test (ollo → lolo) * (oolo → ooll) == (oloo → lloo)
#(2 -2] * [1/2 2) == (1 -1]
@test (olll → lolo) * (oolo → ooll) == (olol → lloo)
#(2 -2] * [-2 -1/2) == [1 -1)
@test (olll → lolo) * (-(oolo → ooll)) == (oloo → loll)
#(2 -2] * 0 == allreals
@test (olll → lolo) * ▾(oooo) == ℝᵖ(PBound4)
#[2 -2] * (0 1) == allreals
@test (olll → lolo) * (oooo → ooll) == ℝᵖ(PBound4)

#bounds that round infinity and zero
#[2 1/2] * [0] = allerals
@test (ollo → oolo) * ▾(oooo) == ℝᵖ(PBound4)
#[2 1/2] * [inf] = allerals
@test (ollo → oolo) * ▾(looo) == ℝᵖ(PBound4)
@test (ollo → oolo) * (oooo → oool) == ℝᵖ(PBound4)
@test (ollo → oolo) * (olll → looo) == ℝᵖ(PBound4)
@test (ollo → oolo) * (llll → oool) == ℝᵖ(PBound4)
@test (ollo → oolo) * (olll → lool) == ℝᵖ(PBound4)

#(2 1/2) * [1/2, 2] == R\[1]
@test (olll → oool) * (oolo → ollo) == (olol → ooll)

#wrap around to stitch together.
#[2 1/2] * [1/2 2] == allreals
@test (ollo → oolo) * (oolo → ollo) == ℝᵖ(PBound4)
#[2 1/2] * [1/2 2) == allreals
@test (ollo → oolo) * (oolo → olol) == ℝᵖ(PBound4)
#[2 1/2) * [1/2 2) == allreals
@test (ollo → oool) * (oolo → olol) == ℝᵖ(PBound4)
#(2 1/2) * (1/2 2) == R\[1]
@test (olol → oool) * (oolo → olol) == ℝᵖ(PBound4)
