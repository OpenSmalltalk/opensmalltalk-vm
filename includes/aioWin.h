#pragma once

#ifndef ioCurrentOSThread
#define ioCurrentOSThread() GetCurrentThreadId()
#endif


long aioPoll(long microSeconds);
long aioSleepForUsecs(long microSeconds);
void aioInit();
