#include "pharovm/pharo.h"

time_t convertToSqueakTime(time_t unixTime)
{
  /* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970: 17 leap years
     and 52 non-leap years later than Squeak. */
  return unixTime + ((52*365UL + 17*366UL) * 24*60*60UL) + getVMGMTOffset();
}
