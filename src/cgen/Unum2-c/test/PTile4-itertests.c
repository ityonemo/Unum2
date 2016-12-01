#include "PTile4-test.h"

void PTile4_itertests(){
  assert(next(pf1000) == pf1001);
  assert(next(pf1001) == pf1010);
  assert(next(pf1010) == pf1011);
  assert(next(pf1011) == pf1100);
  assert(next(pf1100) == pf1101);
  assert(next(pf1101) == pf1110);
  assert(next(pf1110) == pf1111);
  assert(next(pf1111) == pf0000);
  assert(next(pf0000) == pf0001);
  assert(next(pf0001) == pf0010);
  assert(next(pf0010) == pf0011);
  assert(next(pf0011) == pf0100);
  assert(next(pf0100) == pf0101);
  assert(next(pf0101) == pf0110);
  assert(next(pf0110) == pf0111);
  assert(next(pf0111) == pf1000);

  assert(prev(pf1000) == pf0111);
  assert(prev(pf1001) == pf1000);
  assert(prev(pf1010) == pf1001);
  assert(prev(pf1011) == pf1010);
  assert(prev(pf1100) == pf1011);
  assert(prev(pf1101) == pf1100);
  assert(prev(pf1110) == pf1101);
  assert(prev(pf1111) == pf1110);
  assert(prev(pf0000) == pf1111);
  assert(prev(pf0001) == pf0000);
  assert(prev(pf0010) == pf0001);
  assert(prev(pf0011) == pf0010);
  assert(prev(pf0100) == pf0011);
  assert(prev(pf0101) == pf0100);
  assert(prev(pf0110) == pf0101);
  assert(prev(pf0111) == pf0110);

  assert(glb(pf1000) == pf1000);
  assert(glb(pf1001) == pf1000);
  assert(glb(pf1010) == pf1010);
  assert(glb(pf1011) == pf1010);
  assert(glb(pf1100) == pf1100);
  assert(glb(pf1101) == pf1100);
  assert(glb(pf1110) == pf1110);
  assert(glb(pf1111) == pf1110);
  assert(glb(pf0000) == pf0000);
  assert(glb(pf0001) == pf0000);
  assert(glb(pf0010) == pf0010);
  assert(glb(pf0011) == pf0010);
  assert(glb(pf0100) == pf0100);
  assert(glb(pf0101) == pf0100);
  assert(glb(pf0110) == pf0110);
  assert(glb(pf0111) == pf0110);

  assert(lub(pf1000) == pf1000);
  assert(lub(pf1001) == pf1010);
  assert(lub(pf1010) == pf1010);
  assert(lub(pf1011) == pf1100);
  assert(lub(pf1100) == pf1100);
  assert(lub(pf1101) == pf1110);
  assert(lub(pf1110) == pf1110);
  assert(lub(pf1111) == pf0000);
  assert(lub(pf0000) == pf0000);
  assert(lub(pf0001) == pf0010);
  assert(lub(pf0010) == pf0010);
  assert(lub(pf0011) == pf0100);
  assert(lub(pf0100) == pf0100);
  assert(lub(pf0101) == pf0110);
  assert(lub(pf0110) == pf0110);
  assert(lub(pf0111) == pf1000);

  assert(upper_ulp(pf1000) == pf1001);
  assert(upper_ulp(pf1001) == pf1001);
  assert(upper_ulp(pf1010) == pf1011);
  assert(upper_ulp(pf1011) == pf1011);
  assert(upper_ulp(pf1100) == pf1101);
  assert(upper_ulp(pf1101) == pf1101);
  assert(upper_ulp(pf1110) == pf1111);
  assert(upper_ulp(pf1111) == pf1111);
  assert(upper_ulp(pf0000) == pf0001);
  assert(upper_ulp(pf0001) == pf0001);
  assert(upper_ulp(pf0010) == pf0011);
  assert(upper_ulp(pf0011) == pf0011);
  assert(upper_ulp(pf0100) == pf0101);
  assert(upper_ulp(pf0101) == pf0101);
  assert(upper_ulp(pf0110) == pf0111);
  assert(upper_ulp(pf0111) == pf0111);

  assert(lower_ulp(pf1000) == pf0111);
  assert(lower_ulp(pf1001) == pf1001);
  assert(lower_ulp(pf1010) == pf1001);
  assert(lower_ulp(pf1011) == pf1011);
  assert(lower_ulp(pf1100) == pf1011);
  assert(lower_ulp(pf1101) == pf1101);
  assert(lower_ulp(pf1110) == pf1101);
  assert(lower_ulp(pf1111) == pf1111);
  assert(lower_ulp(pf0000) == pf1111);
  assert(lower_ulp(pf0001) == pf0001);
  assert(lower_ulp(pf0010) == pf0001);
  assert(lower_ulp(pf0011) == pf0011);
  assert(lower_ulp(pf0100) == pf0011);
  assert(lower_ulp(pf0101) == pf0101);
  assert(lower_ulp(pf0110) == pf0101);
  assert(lower_ulp(pf0111) == pf0111);
}
