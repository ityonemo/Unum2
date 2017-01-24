@test fma(▾(PTile4(2)), ▾(PTile4(2)), ▾(PTile4(2))) == ▾(PTile4(6))
@test fma(▾(PTile4(2)), ▾(PTile4(-0.25)), ▾(PTile4(0.25))) == (PTile4(-0.75) → PTile4(0.25))
@test fma(▾(PTile4(-0.25)), ▾(PTile4(2)), ▾(PTile4(0.25))) == (PTile4(-0.75) → PTile4(0.25))
@test fma(▾(PTile4(-0.25)),▾(PTile4(-1.5)),▾(PTile4(-0.25))) == (PTile4(-0.25) → PTile4(0.75))
@test fma(▾(PTile4(-0.75)),▾(PTile4(2)),▾(PTile4(0.25))) == (PTile4(-1.5) → PTile4(-0.75))

@test fma(▾(PTile5e(0.75)),▾(PTile5e(2.5)),▾(PTile5e(0.3))) == (PTile5e(1.25) → PTile5e(5))
