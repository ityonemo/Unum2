using Unum2

function whittle!(w, w1)
  (w.upper > w1.upper) && (w.upper = w1.upper)
  (w.lower < w1.lower) && (w.lower = w1.lower)
end

#does stuff with fma stats
function fmastats(T)
  total_fmas = 0
  naive_nonsingles =  0
  fma_nonsingles = 0
  redo_nonsingles = 0
  whit_nonsingles = 0

  for x in exacts(T), y in exacts(T), z in exacts(T)
    w0 = ▾(x) * ▾(y) + ▾(z)

    #ignore trivial cases where we get all projective reals.
    ispreals(w0) && continue

    total_fmas += 1

    issingle(w0) || (naive_nonsingles += 1)

    w = fma(▾(x), ▾(y), ▾(z))
    if !issingle(w)
      fma_nonsingles += 1

      w1 = (▾(x) + ▾(z) / ▾(y)) * ▾(y)
      w2 = (▾(y) + ▾(z) / ▾(x)) * ▾(x)

      if issingle(w1) || issingle(w2)
      else
        redo_nonsingles += 1

        whittle!(w, w1)
        whittle!(w, w2)

        if !issingle(w)
          whit_nonsingles += 1
        end
      end
    end
  end

  println("===========================")
  println("FMA stats for type $T")
  println("total fmas: $total_fmas")
  println("naively nonsingle: $naive_nonsingles")
  println("fma nonsingle: $fma_nonsingles")
  println("redo nonsingle: $redo_nonsingles")
  println("whittled nonsingle: $whit_nonsingles")
end


import_lattice(:PFloat4)
fmastats(PTile4)
import_lattice(:PFloat5)
fmastats(PTile5)
import_lattice(:PFloatD1)
fmastats(PTileD1)
