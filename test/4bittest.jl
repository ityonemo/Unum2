#4-bit unum2 basics.

import Unum2.PFloat4

@test inf(PFloat4)     : lookslike : 0x8000_0000_0000_0000
@test zero(PFloat4)    : lookslike : 0x0000_0000_0000_0000
@test one(PFloat4)     : lookslike : 0x4000_0000_0000_0000
@test neg_one(PFloat4) : lookslike : 0xC000_0000_0000_0000

pone = one(PFloat4)
ptwo = reinterpret(PFloat4, 0x6000_0000_0000_0000)
phlf = reinterpret(PFloat4, 0x2000_0000_0000_0000)
ntwo = reinterpret(PFloat4, 0xA000_0000_0000_0000)
nhlf = reinterpret(PFloat4, 0xE000_0000_0000_0000)

################################################################################

@test Unum2.decompose(ptwo) == (false, false, 0x0000_0000_0000_0000, 0x0000_0000_0000_0002)
@test Unum2.decompose(pone) == (false, false, 0x0000_0000_0000_0000, 0x0000_0000_0000_0000)
@test Unum2.decompose(phlf) == (false, true,  0x0000_0000_0000_0000, 0x0000_0000_0000_0002)
@test Unum2.decompose(ntwo) == (true,  false, 0x0000_0000_0000_0000, 0x0000_0000_0000_0002)
@test Unum2.decompose(nhlf) == (true,  true,  0x0000_0000_0000_0000, 0x0000_0000_0000_0002)

################################################################################

@test !isnegative(inf(PFloat4))
@test !isinverted(inf(PFloat4))

@test !isnegative(zero(PFloat4))
@test !isinverted(zero(PFloat4))

################################################################################
#mathey stuff

@test Unum2.mul(ptwo, ptwo) == pos_many(PFloat4)
@test Unum2.mul(ntwo, ntwo) == pos_many(PFloat4)
@test Unum2.mul(ptwo, ntwo) == neg_many(PFloat4)
@test Unum2.mul(ntwo, ptwo) == neg_many(PFloat4)

@test Unum2.mul(phlf, phlf) == pos_few(PFloat4)
@test Unum2.mul(nhlf, nhlf) == pos_few(PFloat4)
@test Unum2.mul(phlf, nhlf) == neg_few(PFloat4)
@test Unum2.mul(nhlf, phlf) == neg_few(PFloat4)

################################################################################

@test Unum2.add(ptwo, ptwo) == pos_many(PFloat4)
@test Unum2.add(pone, pone) == ptwo
=#
