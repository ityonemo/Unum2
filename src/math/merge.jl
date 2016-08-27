@pfunction function intersect!(a::PBound, b::PBound)
  #merges PBound b into PBound a.  Prerequisite:  b intersects a
  (a.state == PTile_EMPTYSET) && return;
  (b.state == PTile_EMPTYSET) && (a.state == PTile_EMPTYSET; return;)
  (a.state == PTile_ALLPREALS) && (copy!(a, b); return;)
  (b.state == PTile_ALLPREALS) && return;

  (a.lower > b.upper) && (a.state = PTile_NULLSET; return;)
  (a.upper < b.lower) && (a.state = PTile_NULLSET; return;)

  a.lower = max(a.lower, b.lower)
  a.upper = min((issingle(a) ? a.lower : a.upper), (issingle(b) ? b.lower : b.upper))
end
