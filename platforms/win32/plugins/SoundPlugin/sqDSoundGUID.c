/* Declare/define the necessary GUIDs */

#include <initguid.h>

/* Including <initguid.h> above results in INITGUID being #defined.
   The files below include macros which declare/define GUID values.
   Since INITGUID is defined, these macros actually define and
   initialize the GUIDs; if INITGUID is not defined, these same 
   macros simply declare an extern reference to the GUID.

   Therefore, we must #include the GUID-defining header files below
   exactly once while INITGUID is defined (we can #include them
   as often as we want when INITGUID is not defined).  Otherwise,
   we will fail with either multiply-defined or undefined symbols.

   For further discussion, see http://support.microsoft.com/kb/130869,
   or Google for "INITGUID".
*/

/* If we're built as an internal plugin, the sqWin32GUID.c takes care
   of these definitions. */
#ifndef SQUEAK_BUILTIN_PLUGIN
#include <dsound.h>
#include <dsconf.h>
#endif

#include <mmdeviceapi.h>
#include <wmcodecdsp.h>
#include <uuids.h>
