#4-bit unum2 basics.

const utop = Unum2.PTILE_INF
const uzero = Unum2.PTILE_ZERO

import_lattice(:PFloat4)

#create the entire circle of values.
p4_inf   = PTile4(Inf)
p4n_many = PTile4(-3)
p4n_two  = PTile4(-2)
p4n_much = PTile4(-1.5)
p4n_one  = PTile4(-1)
p4n_most = PTile4(-0.75)
p4n_half = PTile4(-0.5)
p4n_some = PTile4(-0.25)
p4_zero  = PTile4(0)
p4p_some = PTile4(0.25)
p4p_half = PTile4(0.5)
p4p_most = PTile4(0.75)
p4p_one  = PTile4(1)
p4p_much = PTile4(1.5)
p4p_two  = PTile4(2)
p4p_many = PTile4(3)

p4vec = [p4_inf, p4n_many, p4n_two, p4n_much, p4n_one, p4n_most, p4n_half, p4n_some, p4_zero, p4p_some, p4p_half, p4p_most, p4p_one, p4p_much, p4p_two, p4p_many]

#test to make sure that everything looks as it should.
intvalue = utop
for x in p4vec
  @test (x : lookslike : intvalue)
  intvalue += Unum2.incrementor(PTile4)
end

################################################################################
#test decompose and synthesize

import Unum2: decompose, synthesize, __dc_tile, UT_Int, ST_Int

@test decompose(p4n_many) == __dc_tile(zero(ST_Int), UT_Int(3), 0x02)
@test decompose(p4n_two ) == __dc_tile(zero(ST_Int), UT_Int(2), 0x02)
@test decompose(p4n_much) == __dc_tile(zero(ST_Int), UT_Int(1), 0x02)
@test decompose(p4n_one ) == __dc_tile(zero(ST_Int), UT_Int(0), 0x02)
@test decompose(p4n_most) == __dc_tile(zero(ST_Int), UT_Int(1), 0x03)
@test decompose(p4n_half) == __dc_tile(zero(ST_Int), UT_Int(2), 0x03)
@test decompose(p4n_some) == __dc_tile(zero(ST_Int), UT_Int(3), 0x03)
#----------------------------------------------------------------------------
@test decompose(p4p_some) == __dc_tile(zero(ST_Int), UT_Int(3), 0x01)
@test decompose(p4p_half) == __dc_tile(zero(ST_Int), UT_Int(2), 0x01)
@test decompose(p4p_most) == __dc_tile(zero(ST_Int), UT_Int(1), 0x01)
@test decompose(p4p_one ) == __dc_tile(zero(ST_Int), UT_Int(0), 0x00)
@test decompose(p4p_much) == __dc_tile(zero(ST_Int), UT_Int(1), 0x00)
@test decompose(p4p_two ) == __dc_tile(zero(ST_Int), UT_Int(2), 0x00)
@test decompose(p4p_many) == __dc_tile(zero(ST_Int), UT_Int(3), 0x00)

@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(3), 0x02)) == (p4n_many)
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(2), 0x02)) == (p4n_two )
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(1), 0x02)) == (p4n_much)
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(0), 0x02)) == (p4n_one )
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(1), 0x03)) == (p4n_most)
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(2), 0x03)) == (p4n_half)
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(3), 0x03)) == (p4n_some)
#--------------------------------------------------------------------------------------
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(3), 0x01)) == (p4p_some)
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(2), 0x01)) == (p4p_half)
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(1), 0x01)) == (p4p_most)
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(0), 0x00)) == (p4p_one )
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(1), 0x00)) == (p4p_much)
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(2), 0x00)) == (p4p_two )
@test synthesize(PTile4, __dc_tile(zero(ST_Int), UT_Int(3), 0x00)) == (p4p_many)

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

include("4bittest/4btdefs.jl")
include("4bittest/4bt-test-add.jl")
include("4bittest/4bt-test-mul.jl")

#test addition
testop4(+, btadd)
#test multiplication
testop4(*, btmul)

include("4bittest/4bt-test-bounds.jl")
