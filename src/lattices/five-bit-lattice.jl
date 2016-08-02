#five-bit-lattice.jl
#definition for the five-bit lattice.
#five-bit Lnum

five_bit_lattice = Unum2.LatticeNum[2]

Unum2.addlattice(:Lnum4, five_bit_lattice, 4)

typealias PFloat5 PFloat{:Lnum4, 2}
typealias PBound5 PFloat{:Lnum4, 2}
