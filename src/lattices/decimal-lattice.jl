decimal_lattice = Unum2.LatticeNum[10//9, 5//4, 10//7, 3//2, 5//3, 2//1, 5//2, 3//1, 10//3, 4//1, 5//1, 6//1, 7//1, 8//1, 9//1]

Unum2.addlattice(:LnumD1, decimal_lattice, 10)

typealias PTileD1 PTile{:LnumD1, 1}
typealias PBoundD1 PBound{:LnumD1, 1}

Base.show(io::IO, ::Type{PTileD1}) = print(io, "PTileD1")

create_tables(:LnumD1)

nothing
