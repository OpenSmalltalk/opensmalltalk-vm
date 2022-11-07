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

extern const char *getAttributeString(sqInt id);
#define XFN(export) {"", #export, (void*)export},
#define XFEN(export,name) {"", name, (void*)export},

void *os_exports[][3] = {
	XFN(getAttributeString)
	XFEN(getAttributeString,"GetAttributeString") // backwards compatibility for UnixOSProcessPlugin
	XFN(getSTWindow)
	XFN(getImageName)
	XFN(getWindowChangedHook)
	XFN(setWindowChangedHook)

	{NULL, NULL, NULL}
};
