/* note: this file is only a backward compatible wrapper
   for the old-style "platform.exports" definitions.
   If your platform has migrated to the new exports
   style you may as well insert the exports right here */
#include <stdio.h>
/* duh ... this is ugly */
#define XFN(export) {"", #export, (void*)export},
#define XFN2(plugin, export) {#plugin, #export, (void*)plugin##_##export}
extern void  setSocketPollFunction(int spf );
void *os_exports[][3] = {
   XFN(setSocketPollFunction)
	{NULL, NULL, NULL}
};
