function additiveinverse{lattice, epochbits}(x::PTile{lattice, epochbits})
  @p -(@s x)
end

function multiplicativeinverse{lattice, epochbits}(x::PTile{lattice, epochbits})
  @p (-(@s x)) + (@s 0x8000_0000_0000_0000)
end

function additiveinverse!{lattice, epochbits}(x::PBound{lattice, epochbits})
  if issingle(x)
    x.lower = additiveinverse(x.lower)
  elseif isdouble(x)
    (x.lower, x.upper) = (additiveinverse(x.upper), additiveinverse(x.lower))
  end
  nothing
end

function multiplicativeinverse!{lattice, epochbits}(x::PBound{lattice, epochbits})
  if issingle(x)
    x.lower = multiplicativeinverse(x.lower)
  elseif isdouble(x)
    (x.lower, x.upper) = (multiplicativeinverse(x.upper), multiplicativeinverse(x.lower))
  end
  nothing
end
