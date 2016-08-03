#4-bit unum2 basics.

@unumbers

import_lattice(:PFloat4)

#create the entire circle of values.
p4_inf   = PFloat4(Inf)
p4n_many = PFloat4(-3)
p4n_two  = PFloat4(-2)
p4n_much = PFloat4(-1.5)
p4n_one  = PFloat4(-1)
p4n_most = PFloat4(-0.75)
p4n_half = PFloat4(-0.5)
p4n_some = PFloat4(-0.25)
p4_zero  = PFloat4(0)
p4p_some = PFloat4(0.25)
p4p_half = PFloat4(0.5)
p4p_most = PFloat4(0.75)
p4p_one  = PFloat4(1)
p4p_much = PFloat4(1.5)
p4p_two  = PFloat4(2)
p4p_many = PFloat4(3)

p4vec = [p4_inf, p4n_many, p4n_two, p4n_much, p4n_one, p4n_most, p4n_half, p4n_some, p4_zero, p4p_some, p4p_half, p4p_most, p4p_one, p4p_much, p4p_two, p4p_many]

#test to make sure that everything looks as it should.
intvalue = 0x8000_0000_0000_0000
for x in p4vec
  @test (x : lookslike : intvalue)
  intvalue += 0x1000_0000_0000_0000
end

################################################################################
#test decompose and synthesize

@test Unum2.decompose(p4n_many) == (true,  false, z64, 0x0000_0000_0000_0003)
@test Unum2.decompose(p4n_two ) == (true,  false, z64, 0x0000_0000_0000_0002)
@test Unum2.decompose(p4n_much) == (true,  false, z64, 0x0000_0000_0000_0001)
@test Unum2.decompose(p4n_one ) == (true,  true,  z64, 0x0000_0000_0000_0000)  #NB:  negative one results as inverted when decomposed.
@test Unum2.decompose(p4n_most) == (true,  true,  z64, 0x0000_0000_0000_0001)
@test Unum2.decompose(p4n_half) == (true,  true,  z64, 0x0000_0000_0000_0002)
@test Unum2.decompose(p4n_some) == (true,  true,  z64, 0x0000_0000_0000_0003)
#----------------------------------------------------------------------------
@test Unum2.decompose(p4p_some) == (false, true,  z64, 0x0000_0000_0000_0003)
@test Unum2.decompose(p4p_half) == (false, true,  z64, 0x0000_0000_0000_0002)
@test Unum2.decompose(p4p_most) == (false, true,  z64, 0x0000_0000_0000_0001)
@test Unum2.decompose(p4p_one ) == (false, false, z64, 0x0000_0000_0000_0000)
@test Unum2.decompose(p4p_much) == (false, false, z64, 0x0000_0000_0000_0001)
@test Unum2.decompose(p4p_two ) == (false, false, z64, 0x0000_0000_0000_0002)
@test Unum2.decompose(p4p_many) == (false, false, z64, 0x0000_0000_0000_0003)

@test Unum2.synthesize(PFloat4, true,  false, z64, 0x0000_0000_0000_0003) == (p4n_many)
@test Unum2.synthesize(PFloat4, true,  false, z64, 0x0000_0000_0000_0002) == (p4n_two )
@test Unum2.synthesize(PFloat4, true,  false, z64, 0x0000_0000_0000_0001) == (p4n_much)
@test Unum2.synthesize(PFloat4, true,  false, z64, 0x0000_0000_0000_0000) == (p4n_one )
@test Unum2.synthesize(PFloat4, true,  true,  z64, 0x0000_0000_0000_0001) == (p4n_most)
@test Unum2.synthesize(PFloat4, true,  true,  z64, 0x0000_0000_0000_0002) == (p4n_half)
@test Unum2.synthesize(PFloat4, true,  true,  z64, 0x0000_0000_0000_0003) == (p4n_some)
#--------------------------------------------------------------------------------------
@test Unum2.synthesize(PFloat4, false, true,  z64, 0x0000_0000_0000_0003) == (p4p_some)
@test Unum2.synthesize(PFloat4, false, true,  z64, 0x0000_0000_0000_0002) == (p4p_half)
@test Unum2.synthesize(PFloat4, false, true,  z64, 0x0000_0000_0000_0001) == (p4p_most)
@test Unum2.synthesize(PFloat4, false, false, z64, 0x0000_0000_0000_0000) == (p4p_one )
@test Unum2.synthesize(PFloat4, false, false, z64, 0x0000_0000_0000_0001) == (p4p_much)
@test Unum2.synthesize(PFloat4, false, false, z64, 0x0000_0000_0000_0002) == (p4p_two )
@test Unum2.synthesize(PFloat4, false, false, z64, 0x0000_0000_0000_0003) == (p4p_many)

################################################################################
#test properties like negative and inverted.

@test !isnegative(p4_inf  )
@test  isnegative(p4n_many)
@test  isnegative(p4n_two )
@test  isnegative(p4n_much)
@test  isnegative(p4n_one )
@test  isnegative(p4n_most)
@test  isnegative(p4n_half)
@test  isnegative(p4n_some)
@test !isnegative(p4_zero )
@test !isnegative(p4p_some)
@test !isnegative(p4p_half)
@test !isnegative(p4p_most)
@test !isnegative(p4p_one )
@test !isnegative(p4p_much)
@test !isnegative(p4p_two )
@test !isnegative(p4p_many)

@test !ispositive(p4_inf  )
@test !ispositive(p4n_many)
@test !ispositive(p4n_two )
@test !ispositive(p4n_much)
@test !ispositive(p4n_one )
@test !ispositive(p4n_most)
@test !ispositive(p4n_half)
@test !ispositive(p4n_some)
@test !ispositive(p4_zero )
@test  ispositive(p4p_some)
@test  ispositive(p4p_half)
@test  ispositive(p4p_most)
@test  ispositive(p4p_one )
@test  ispositive(p4p_much)
@test  ispositive(p4p_two )
@test  ispositive(p4p_many)

@test !isinverted(p4_inf  )
@test !isinverted(p4n_many)
@test !isinverted(p4n_two )
@test !isinverted(p4n_much)
@test  isinverted(p4n_one )
@test  isinverted(p4n_most)
@test  isinverted(p4n_half)
@test  isinverted(p4n_some)
@test !isinverted(p4_zero )
@test  isinverted(p4p_some)
@test  isinverted(p4p_half)
@test  isinverted(p4p_most)
@test !isinverted(p4p_one )
@test !isinverted(p4p_much)
@test !isinverted(p4p_two )
@test !isinverted(p4p_many)

################################################################################
# MATH THINGS

################################################################################
# inversion

@test Unum2.multiplicativeinverse(p4_inf  ) == p4_zero
@test Unum2.multiplicativeinverse(p4n_many) == p4n_some
@test Unum2.multiplicativeinverse(p4n_two ) == p4n_half
@test Unum2.multiplicativeinverse(p4n_much) == p4n_most
@test Unum2.multiplicativeinverse(p4n_one ) == p4n_one
@test Unum2.multiplicativeinverse(p4n_most) == p4n_much
@test Unum2.multiplicativeinverse(p4n_half) == p4n_two
@test Unum2.multiplicativeinverse(p4n_some) == p4n_many
@test Unum2.multiplicativeinverse(p4_zero ) == p4_inf
@test Unum2.multiplicativeinverse(p4p_some) == p4p_many
@test Unum2.multiplicativeinverse(p4p_half) == p4p_two
@test Unum2.multiplicativeinverse(p4p_most) == p4p_much
@test Unum2.multiplicativeinverse(p4p_one ) == p4p_one
@test Unum2.multiplicativeinverse(p4p_much) == p4p_most
@test Unum2.multiplicativeinverse(p4p_two ) == p4p_half
@test Unum2.multiplicativeinverse(p4p_many) == p4p_some

@test Unum2.additiveinverse(p4_inf  ) == p4_inf
@test Unum2.additiveinverse(p4n_many) == p4p_many
@test Unum2.additiveinverse(p4n_two ) == p4p_two
@test Unum2.additiveinverse(p4n_much) == p4p_much
@test Unum2.additiveinverse(p4n_one ) == p4p_one
@test Unum2.additiveinverse(p4n_most) == p4p_most
@test Unum2.additiveinverse(p4n_half) == p4p_half
@test Unum2.additiveinverse(p4n_some) == p4p_some
@test Unum2.additiveinverse(p4_zero ) == p4_zero
@test Unum2.additiveinverse(p4p_some) == p4n_some
@test Unum2.additiveinverse(p4p_half) == p4n_half
@test Unum2.additiveinverse(p4p_most) == p4n_most
@test Unum2.additiveinverse(p4p_one ) == p4n_one
@test Unum2.additiveinverse(p4p_much) == p4n_much
@test Unum2.additiveinverse(p4p_two ) == p4n_two
@test Unum2.additiveinverse(p4p_many) == p4n_many

################################################################################

include("4bittest/mathtestdefs.jl")
include("4bittest/4bt-test-add.jl")

#test addition
testop(+, btadd)

#=
@test Unum2.mul(ptwo, ptwo) == pos_many(PFloat4)
@test Unum2.mul(ntwo, ntwo) == pos_many(PFloat4)
@test Unum2.mul(ptwo, ntwo) == neg_many(PFloat4)
@test Unum2.mul(ntwo, ptwo) == neg_many(PFloat4)

@test Unum2.mul(phlf, phlf) == pos_few(PFloat4)
@test Unum2.mul(nhlf, nhlf) == pos_few(PFloat4)
@test Unum2.mul(phlf, nhlf) == neg_few(PFloat4)
@test Unum2.mul(nhlf, phlf) == neg_few(PFloat4)

################################################################################
@test Unum2.div(ptwo, ptwo) == pone
@test Unum2.div(pone, phlf) == ptwo
@test Unum2.div(pone, ptwo) == phlf
@test Unum2.div(phlf, ptwo) == pos_few(PFloat4)
################################################################################

@test Unum2.add(ptwo, ptwo) == pos_many(PFloat4)
@test Unum2.add(pone, pone) == ptwo
@test Unum2.add(phlf, phlf) == pone

################################################################################

@test Unum2.sub(ptwo, ptwo) == zero(PFloat4)
@test Unum2.sub(ptwo, pone) == pone
@test Unum2.sub(ntwo, ntwo) == zero(PFloat4)
@test Unum2.sub(ntwo, neg_one(PFloat4)) == neg_one(PFloat4)
@test Unum2.sub(pone, phlf) == phlf
=#
