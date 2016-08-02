#four-bit-lattice.jl
#definition for the four-bit lattice.
#four-bit Lnum

four_bit_lattice = Unum2.LatticeNum[2]

Unum2.addlattice(:Lnum4, four_bit_lattice, 4)

typealias PFloat4 PFloat{:Lnum4, 1}
typealias PBound4 PBound{:Lnum4, 1}
