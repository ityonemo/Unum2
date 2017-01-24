#cgen-epochtest.jl

#makes sure the c library is calculating the epochs correctly.

function c_epoch(ptile)
  uval = reinterpret(UInt64, ptile)
  ccall((:tile_epoch, "./libpfloat.so"), UInt64, (UInt64,), uval)
end

function epochtest{lattice, epochbits}(T::Type{PTile{lattice, epochbits}})
  #set the
  setfunction[PBound{lattice, epochbits}]()
  for tile in T
    if (tile != zero(T) && tile != inf(T))
      #first calculate the actual epoch
      epoch = Unum2.decompose(tile).epoch

      cepoch = c_epoch(tile)

      if (epoch != cepoch)
        println("$tile epoch failed! julia epoch $epoch != c epoch $cepoch")
      end
    end
  end
end
