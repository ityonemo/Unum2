if !isdefined(:PTileDM7a)
  dmqa = Unum2.LatticeNum[10//9,9//8,5//4,32//25,25//18,10//7,40//27,25//16,5//3,9//5,2//1,12//5,5//2,25//9,3//1,10//3,18//5,4//1,25//6,24//5,5//1,50//9,6//1,32//5,27//4,7//1,36//5,125//16,8//1,80//9,9//1]
  Unum2.addlattice(:LnumDM7a, dmqa, 10)

  typealias PTileDM7a PTile{:LnumDM7a, 1}
  typealias PBoundDM7a PBound{:LnumDM7a, 1}

  Base.show(io::IO, ::Type{PTileDM7a}) = print(io, "PTileDM7a")

  create_tables(:LnumDM7a)
end

PTileDM7a
