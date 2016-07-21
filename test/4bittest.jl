#4-bit unum2 basics.

import Unum2.PFloat4

@test inf(PFloat4)     : lookslike : 0x8000_0000_0000_0000
@test zero(PFloat4)    : lookslike : 0x0000_0000_0000_0000
@test one(PFloat4)     : lookslike : 0x4000_0000_0000_0000
@test neg_one(PFloat4) : lookslike : 0xC000_0000_0000_0000

ptwo = reinterpret(PFloat4, 0x6000_0000_0000_0000)
phlf = reinterpret(PFloat4, 0x2000_0000_0000_0000)
ntwo = reinterpret(PFloat4, 0xA000_0000_0000_0000)
nhlf = reinterpret(PFloat4, 0xE000_0000_0000_0000)


################################################################################

@test Unum2.lvalue(ptwo) == 0x0000_0000_0000_0002
@test Unum2.lvalue(phlf) == 0x0000_0000_0000_0002
@test Unum2.lvalue(ntwo) == 0x0000_0000_0000_0002
@test Unum2.lvalue(nhlf) == 0x0000_0000_0000_0002

################################################################################
@test !isnegative(inf(PFloat4))
@test !isinverted(inf(PFloat4))

@test !isnegative(zero(PFloat4))
@test !isinverted(zero(PFloat4))

@test !isnegative(ptwo)
@test !isnegative(phlf)
@test isnegative(ntwo)
@test isnegative(nhlf)
@test !isinverted(ptwo)
@test !isinverted(ntwo)
@test isinverted(nhlf)
@test isinverted(phlf)
