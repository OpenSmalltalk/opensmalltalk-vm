/*	Regular Expression Plugin (This class comment becomes part of rePlugin.c)

	RePlugin translate: 'RePlugin.c' doInlining: true.

See documentation and source code for the PCRE C Library Code.  This plugin is designed to serve an object such as RePattern:

	patternStr		A 0-terminated string comprising the pattern to be compiled.
	compileFlags	An Integer representing re compiler options
	PCREBuffer		A ByteArray of regular expression bytecodes
	extraPtr			A ByteArray of match optimization data (or nil)
	errorString		A String Object For Holding an Error Message (when compile failed) 
	errorOffset		The index in patternStr (0-based) where the error ocurred (when compile failed)
	matchFlags		An Integer representing re matcher options
	matchSpaceObj	An Integer array for match results and workspace during matching.

The instance variables must appear in the preceding order.  MatchSpaceObj must be allocated by the calling routine and contain at least 6*(numGroups+1) bytes.
*/
#include "pcre.h"
#include "internal.h"

/* Adjust malloc and free routines as used by PCRE */
static void rePluginFree(void * aPointer);
static void * rePluginMalloc(size_t anInteger);
void *(*pcre_malloc)(size_t) = rePluginMalloc;
void  (*pcre_free)(void *) = rePluginFree;
