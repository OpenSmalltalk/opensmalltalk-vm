/* SoundCodec Plugin */
/* prototypes */
void gsmEncode(
	long state, long frameCount,
	long src, long srcIndex, long srcSize,
	long dst, long dstIndex, long dstSize,
	long *srcDelta, long *dstDelta);
	
void gsmDecode(
	long state, long frameCount,
	long src, long srcIndex, long srcSize,
	long dst, long dstIndex, long dstSize,
	long *srcDelta, long *dstDelta);
	
void gsmInitState(long state);

long gsmStateBytes(void);
