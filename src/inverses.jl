function additiveinverse{lattice, epochbits}(x::PTile{lattice, epochbits})
  @p -(@s x)
end

function multiplicativeinverse{lattice, epochbits}(x::PTile{lattice, epochbits})
  @p (-(@s x)) + (@s 0x8000_0000_0000_0000)
end
