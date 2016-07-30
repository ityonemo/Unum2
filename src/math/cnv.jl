#cnv.jl - conversions from general number types to a PFloat.
function cnv{lattice, epochbits}(P::Type{PFloat{lattice, epochbits}}, x::Real)
  #set key constants.
  T = typeof(x)
  _pivot = Float64(pivot(lattice))
  _value = Float64(x)
  l = __MASTER_LATTICE_LIST[lattice]

  #first thing to check are infinites and zeros, which will not play nice with
  #our conversion algorithm.
  !isfinite(x) && return inf(P)
  (_value == zero(T)) && return zero(P)

  #first handle the negative situation.
  if (_value < zero(T))
    is_negative = true
    _value = -_value
  else
    is_negative = false
  end

  if (_value == one(T))
    is_inverted = false
    result_epoch = 0
    result_value = 0x0000_0000_0000_0000
  elseif (_value > one(T))
    is_inverted = false
    result_epoch = 0
    _epoch_bottom = 1.0
    while (_value > _epoch_bottom * _pivot)
      _epoch_bottom *= _pivot
      result_epoch += 1
    end
    #now we know that _current_pivot is just over the pivot.
    _value /= _epoch_bottom
    result_value = search_lattice(l, _value)
  else #inverted
    is_inverted = true
    result_epoch = 0
    while (_value < 1.0)
      _value *= _pivot
      result_epoch += 1
    end

    result_value = search_lattice(l, _pivot / _value)
  end

  synthesize(P, is_negative, is_inverted, result_epoch, result_value)
end

Base.call{lattice, epochbits}(P::Type{PFloat{lattice, epochbits}}, x) = cnv(P, x)
