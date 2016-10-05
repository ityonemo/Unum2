dfq = Unum2.LatticeNum[11//10,10//9,6//5,5//4,4//3,10//7,3//2,20//13,5//3,20//11,2//1,20//9,5//2,20//7,3//1,10//3,7//2,4//1,9//2,5//1,11//2,6//1,13//2,20//3,7//1,15//2,8//1,25//3,17//2,9//1,100//11]

Unum2.addlattice(:LnumDF7, dfq, 10)

typealias PTileDF7 PTile{:LnumDF7, 1}
typealias PBoundDF7 PBound{:LnumDF7, 1}

Base.show(io::IO, ::Type{PTileDF7}) = print(io, "PTileDF7")

create_tables(:LnumDF7)

nothing
