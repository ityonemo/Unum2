#four-bit-lattice.jl
#definition for the four-bit lattice.
#four-bit Lnum

four_bit_lattice = LatticeNum[2]

addlattice(:Lnum4, four_bit_lattice)

typealias PFloat4 PFloat{:Lnum4, 1}
