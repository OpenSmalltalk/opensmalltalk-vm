#include "pharo.h"
#include "aioWin.h"

sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds){
    aioSleepForUsecs(microSeconds);

    ceCheckForInterrupts();
    return 0;
}

long aioPoll(long microSeconds){

	// TODO: Dummy Impl

	return 0;
}

long aioSleepForUsecs(long microSeconds)
{
	// TODO: Dummy Impl

	Sleep(microSeconds / 1000);

	return aioPoll(0);
}


void aioInit(){

}
