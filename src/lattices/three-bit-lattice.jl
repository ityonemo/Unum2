#three-bit-lattice.jl
#definition for the four-bit lattice.
#four-bit Lnum

three_bit_lattice = Unum2.LatticeNum[]

Unum2.addlattice(:Lnum3, three_bit_lattice, 2)

typealias PFloat3 PFloat{:Lnum4, 1}
