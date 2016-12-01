#five-bit-lattice.jl
#definition for the five-bit lattice with epochs.
#five-bit Lnum

if !isdefined(:PTile5e)
  five_bit_epoch_lattice = Unum2.LatticeNum[2]

  Unum2.addlattice(:Lnum5e, five_bit_epoch_lattice, 4)

  typealias PTile5e PTile{:Lnum5e, 2}
  typealias PBound5e PBound{:Lnum5e, 2}

  Base.show(io::IO, ::Type{PTile5e}) = print(io, "PTile5e")

  create_tables(:Lnum5e)
end

PTile5e
