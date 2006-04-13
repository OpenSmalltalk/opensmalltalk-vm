/**************************************************************************/
/*  A Squeak VM for Acorn RiscOS machines by Tim Rowledge                 */
/*  tim@rowledge.org & http://www.rowledge.org/tim                        */
/*  Known to work on RiscOS >3.7 for StrongARM RPCs and Iyonix,           */
/*  other machines not yet tested.                                        */
/*                       osExports.c                                      */
/*  internal plugin hookups                                               */
/**************************************************************************/

/* To recompile this reliably you will need    */           
/* OSLib -  http://ro-oslib.sourceforge.net/   */
/* Castle/AcornC/C++, the Acorn TCPIPLib       */
/* and a little luck                           */
/* note: this file is only a backward compatible wrapper
 * for the old-style "platform.exports" definitions.
 * If your platform has migrated to the new exports
 * style you may as well insert the exports right here
 */
#include <stdio.h>
/* duh ... this is ugly */
#define XFN(export) {"", #export, (void*)export},
#define XFN2(plugin, export) {#plugin, #export, (void*)plugin##_##export}
extern void  setSocketPollFunction(int spf );
void *os_exports[][3] = {
   XFN(setSocketPollFunction)
	{NULL, NULL, NULL}
};
