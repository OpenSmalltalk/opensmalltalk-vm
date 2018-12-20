#include <windows.h>
#include "CroquetPlugin.h"

static int loaded = 0;
static HMODULE hAdvApi32 = NULL;
static BOOLEAN (__stdcall *RtlGenRandom)(PVOID, ULONG) = NULL;

int ioGatherEntropy(char *bufPtr, int bufSize) {
  if(!loaded) {
    loaded = 1;
    hAdvApi32 = LoadLibrary("advapi32.dll");
    RtlGenRandom = (void*)GetProcAddress(hAdvApi32, "SystemFunction036");
  }
  if(!RtlGenRandom) return 0;
  return RtlGenRandom(bufPtr, bufSize);
}
