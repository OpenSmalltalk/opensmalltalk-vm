#include <Windows.h>
#include "CroquetPlugin.h"

static int loaded = 0;
static HMODULE hAdvApi32 = NULL;
static BOOLEAN (__stdcall *RtlGenRandom)(PVOID, ULONG) = NULL;

sqInt ioGatherEntropy(char *bufPtr, sqInt bufSize) {
  if(!loaded) {
    loaded = 1;
    hAdvApi32 = LoadLibraryA("advapi32.dll");
	if (!hAdvApi32) return 0;
    RtlGenRandom = (void*)GetProcAddress(hAdvApi32, "SystemFunction036");
  }
  if(!RtlGenRandom) return 0;
  return RtlGenRandom(bufPtr, bufSize);
}
