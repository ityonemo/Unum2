#five-bit-lattice.jl
#definition for the five-bit lattice.
#five-bit Lnum

five_bit_lattice = Unum2.LatticeNum[2, 4, 8]

Unum2.addlattice(:Lnum5, five_bit_lattice, 16)

typealias PTile5 PTile{:Lnum5, 1}
typealias PBound5 PBound{:Lnum5, 1}

Base.show(io::IO, ::Type{PTile5}) = print(io, "PTile5")

create_tables(:Lnum5)

nothing
