dmq = Unum2.LatticeNum[10//9,5//4,4//3,10//7,3//2,25//16,5//3,16//9,15//8,2//1,25//12,12//5,5//2,25//9,3//1,10//3,18//5,4//1,25//6,9//2,24//5,5//1,16//3,45//8,6//1,32//5,20//3,7//1,15//2,8//1,9//1]

Unum2.addlattice(:LnumDM7, dmq, 10)

typealias PTileDM7 PTile{:LnumDM7, 1}
typealias PBoundDM7 PBound{:LnumDM7, 1}

Base.show(io::IO, ::Type{PTileDM7}) = print(io, "PTileDM7")

create_tables(:LnumDM7)

nothing
