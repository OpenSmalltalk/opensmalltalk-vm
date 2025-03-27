// defines for controlling the memory permissions of the Cogit's code zone on arm64

#include <libkern/OSCacheControl.h> // for sys_dcache_flush et al

// variables to debug set/clear mismatches
int PJWPNChange = 0;
int PJWPNClear = 0;
int PJWPNSet = 0;
int PJWPNState = 0;

#define needsCodeZoneExecuteWriteSwitch(ign) 1

#define ensureExecutableCodeZoneAt(line) do{\
	pthread_jit_write_protect_np(1);		\
	PJWPNSet = line;						\
	if (PJWPNState) {						\
		PJWPNChange = line;					\
		PJWPNState = 1;						\
	}										\
} while(0)

#define ensureWritableCodeZoneAt(line) do { \
	pthread_jit_write_protect_np(0);		\
	PJWPNClear = line;						\
	if (PJWPNState) {						\
		PJWPNChange = line;					\
		PJWPNState = 0;						\
	}										\
} while(0)
