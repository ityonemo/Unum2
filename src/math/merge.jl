@pfunction function intersect!(a::PBound, b::PBound)
  #merges PBound b into PBound a.  Prerequisite:  b intersects a
  (a.state == PFLOAT_EMPTYSET) && return;
  (b.state == PFLOAT_EMPTYSET) && (a.state == PFLOAT_EMPTYSET; return;)
  (a.state == PFLOAT_ALLPREALS) && (copy!(a, b); return;)
  (b.state == PFLOAT_ALLPREALS) && return;

  (a.lower > b.upper) && (a.state = PFLOAT_NULLSET; return;)
  (a.upper < b.lower) && (a.state = PFLOAT_NULLSET; return;)

  a.lower = max(a.lower, b.lower)
  a.upper = min((issingle(a) ? a.lower : a.upper), (issingle(b) ? b.lower : b.upper))
end
