
import_lattice(:PFloat5e)

include("5bitepochtest/5betdefs.jl")

#make sure decompose and synthesize work.

@test decompose(ooool) == __dc_tile(ST_Int(1),    UT_Int(3), 0x01)
@test decompose(ooolo) == __dc_tile(ST_Int(1),    UT_Int(2), 0x01)
@test decompose(oooll) == __dc_tile(ST_Int(1),    UT_Int(1), 0x01)
@test decompose(ooloo) == __dc_tile(ST_Int(1),    UT_Int(0), 0x01)
@test decompose(oolol) == __dc_tile(zero(ST_Int), UT_Int(3), 0x01)
@test decompose(oollo) == __dc_tile(zero(ST_Int), UT_Int(2), 0x01)
@test decompose(oolll) == __dc_tile(zero(ST_Int), UT_Int(1), 0x01)
#----------------------------------------------------------------------------
@test decompose(olooo) == __dc_tile(zero(ST_Int), UT_Int(0), 0x00)
@test decompose(olool) == __dc_tile(zero(ST_Int), UT_Int(1), 0x00)
@test decompose(ololo) == __dc_tile(zero(ST_Int), UT_Int(2), 0x00)
@test decompose(ololl) == __dc_tile(zero(ST_Int), UT_Int(3), 0x00)
@test decompose(olloo) == __dc_tile(ST_Int(1),    UT_Int(0), 0x00)
@test decompose(ollol) == __dc_tile(ST_Int(1),    UT_Int(1), 0x00)
@test decompose(olllo) == __dc_tile(ST_Int(1),    UT_Int(2), 0x00)
@test decompose(ollll) == __dc_tile(ST_Int(1),    UT_Int(3), 0x00)
#-------------------------------------------------------------------------------
@test synthesize(PTile5e, __dc_tile(ST_Int(1),    UT_Int(3), 0x01)) == (ooool)
@test synthesize(PTile5e, __dc_tile(ST_Int(1),    UT_Int(2), 0x01)) == (ooolo)
@test synthesize(PTile5e, __dc_tile(ST_Int(1),    UT_Int(1), 0x01)) == (oooll)
@test synthesize(PTile5e, __dc_tile(ST_Int(1),    UT_Int(0), 0x01)) == (ooloo)
@test synthesize(PTile5e, __dc_tile(zero(ST_Int), UT_Int(3), 0x01)) == (oolol)
@test synthesize(PTile5e, __dc_tile(zero(ST_Int), UT_Int(2), 0x01)) == (oollo)
@test synthesize(PTile5e, __dc_tile(zero(ST_Int), UT_Int(1), 0x01)) == (oolll)
#----------------------------------------------------------------------------
@test synthesize(PTile5e, __dc_tile(zero(ST_Int), UT_Int(0), 0x00)) == (olooo)
@test synthesize(PTile5e, __dc_tile(zero(ST_Int), UT_Int(1), 0x00)) == (olool)
@test synthesize(PTile5e, __dc_tile(zero(ST_Int), UT_Int(2), 0x00)) == (ololo)
@test synthesize(PTile5e, __dc_tile(zero(ST_Int), UT_Int(3), 0x00)) == (ololl)
@test synthesize(PTile5e, __dc_tile(ST_Int(1),    UT_Int(0), 0x00)) == (olloo)
@test synthesize(PTile5e, __dc_tile(ST_Int(1),    UT_Int(1), 0x00)) == (ollol)
@test synthesize(PTile5e, __dc_tile(ST_Int(1),    UT_Int(2), 0x00)) == (olllo)
@test synthesize(PTile5e, __dc_tile(ST_Int(1),    UT_Int(3), 0x00)) == (ollll)

include("5bitepochtest/5be-test-add.jl")
include("5bitepochtest/5be-test-sub.jl")
include("5bitepochtest/5be-test-mul.jl")

#test addition
testop5e(+, betadd5)
testop5e(-, betsub5)
testop5e(*, betmul5)
