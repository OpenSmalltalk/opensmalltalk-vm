/* SoundCodec Plugin */
/* prototypes */
void gsmEncode(
	int state, int frameCount,
	int src, int srcIndex, int srcSize,
	int dst, int dstIndex, int dstSize,
	int *srcDelta, int *dstDelta);
	
void gsmDecode(
	int state, int frameCount,
	int src, int srcIndex, int srcSize,
	int dst, int dstIndex, int dstSize,
	int *srcDelta, int *dstDelta);
	
void gsmInitState(int state);

int gsmStateBytes(void);
