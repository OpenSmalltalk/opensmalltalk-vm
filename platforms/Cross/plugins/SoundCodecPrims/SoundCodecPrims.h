/* SoundCodec Plugin */
/* prototypes */
#include "sqMemoryAccess.h"

void gsmEncode(
	usqIntptr_t state, sqInt frameCount,
	usqIntptr_t src, sqInt srcIndex, sqInt srcSize,
	usqIntptr_t dst, sqInt dstIndex, sqInt dstSize,
	sqInt *srcDelta, sqInt *dstDelta);
	
void gsmDecode(
	usqIntptr_t state, sqInt frameCount,
	usqIntptr_t src, sqInt srcIndex, sqInt srcSize,
	usqIntptr_t dst, sqInt dstIndex, sqInt dstSize,
	sqInt *srcDelta, sqInt *dstDelta);
	
void gsmInitState(usqIntptr_t state);

sqInt gsmStateBytes(void);
