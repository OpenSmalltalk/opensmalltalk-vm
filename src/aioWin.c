#include "pharovm/pharo.h"
#include "pharovm/aioWin.h"

sqInt ioRelinquishProcessorForMicroseconds(sqInt microSeconds){
    aioSleepForUsecs(microSeconds);
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


sqOSThread ioCurrentOSThread(){
	return GetCurrentThreadId();
}

void aioInit(){

}
