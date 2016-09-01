#cnv.jl - conversions from general number types to a PTile.
function cnv{lattice, epochbits}(P::Type{PTile{lattice, epochbits}}, x::Real)
  #set key constants.
  T = typeof(x)
  _pivot = Float64(pivot(lattice))
  _value = Float64(x)
  l = __MASTER_LATTICE_LIST[lattice]

  #first thing to check are infinites and zeros, which will not play nice with
  #our conversion algorithm.
  !isfinite(x) && return inf(P)
  (_value == zero(T)) && return zero(P)

  #create a placeholder decomposed value.
  dc_res::__dc_tile = zero(__dc_tile)

  #first handle the negative situation.
  if (_value < zero(T))
    set_negative!(dc_res)
    _value = -_value
  end

  if (_value == one(T))
    dc_res.epoch = zero(ST_Int)
    dc_res.lvalue = zero(UT_Int)
  elseif (_value > one(T))
    dc_res.epoch = 0
    _epoch_bottom = 1.0
    while (_value > _epoch_bottom * _pivot)
      _epoch_bottom *= _pivot
      dc_res.epoch += 1
    end
    #now we know that _current_pivot is just over the pivot.
    _value /= _epoch_bottom
    if (_value == _pivot)
      dc_res.epoch += 1
      dc_res.lvalue = zero(UT_Int)
    else
      dc_res.lvalue = search_lattice(l, _value)
    end
  else #inverted
    set_inverted!(dc_res)
    _value *= _pivot
    dc_res.epoch = 0
    while (_value < 1.0)
      _value *= _pivot
      dc_res.epoch += 1
    end
    if (_value == one(T))
      dc_res.epoch += 1
      dc_res.lvalue = zero(UT_Int)
    else
      dc_res.lvalue = search_lattice(l, _pivot / _value)
    end
  end
  synthesize(P, dc_res)
end

@generated function Base.call{lattice, epochbits}(::Type{PTile{lattice, epochbits}}, value)
  validate(__MASTER_LATTICE_LIST[lattice], __MASTER_PIVOT_LIST[lattice])  #double check to make sure it's ok, because why not.
  #make sure epochs is more than 0
  (epochbits > 0) || throw(ArgumentError("must have at least one epoch bit"))
  return :(cnv(PTile{lattice, epochbits}, value))
end
