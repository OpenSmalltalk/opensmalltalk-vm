int sqCopyFilesizetosize(char *srcNameIndex, int srcNameSize, char *dstNameIndex, int dstNameSize);
int sqCopyDirectorysizetosize(char *srcNameIndex, int srcNameSize, char *dstNameIndex, int dstNameSize);
pascal Boolean handleDupError(OSErr error,
					short failedOperation,
					short srcVRefNum,
					long srcDirID,
					ConstStr255Param srcName,
					short dstVRefNum,
					long dstDirID,
					ConstStr255Param dstName);
