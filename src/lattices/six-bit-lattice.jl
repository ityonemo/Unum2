#five-bit-lattice.jl
#definition for the five-bit lattice with epochs.
#five-bit Lnum

if !isdefined(:PTile6)
  six_bit_lattice = Unum2.LatticeNum[1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 3.5]

  Unum2.addlattice(:Lnum6, six_bit_lattice, 4)

  typealias PTile6 PTile{:Lnum6, 2}
  typealias PBound6 PBound{:Lnum6, 2}

  Base.show(io::IO, ::Type{PTile6}) = print(io, "PTile6")

  create_tables(:Lnum6)
end

PTile6
