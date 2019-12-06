#include "pharovm/pharo.h"

sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds)
{
    aioSleepForUsecs(microSeconds);
    return 0;
}
