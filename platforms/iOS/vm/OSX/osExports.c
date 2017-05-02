/* note: this file is only a backward compatible wrapper

   for the old-style "platform.exports" definitions.

   If your platform has migrated to the new exports

   style you may as well insert the exports right here */

#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */

#include <stdio.h>

#define FOR_OS_EXPORTS 1
#include "sqSqueakOSXScreenAndWindow.h"
#include "sqSqueakVmAndImagePathAPI.h"

#define XFN(export) {"", #export, (void*)export},
#define XFN2(plugin, export) {#plugin, #export, (void*)plugin##_##export}

void *os_exports[][3] = {
	XFN(getSTWindow)
	XFN(getImageName)
	XFN(getWindowChangedHook)
	XFN(setWindowChangedHook)

	{NULL, NULL, NULL}
};
