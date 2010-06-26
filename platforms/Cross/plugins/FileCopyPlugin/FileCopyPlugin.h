/* This is a hopefully temporary plugin that provides a platform specific way
 * to copy files with all the type and status information intact -
 * rather useful for makefiles, unix shell scripts, Mac resources etc
 * It will fade away once Squeak has decent file handling.
 */
 
int sqCopyFilesizetosize(char *srcNameIndex, int srcNameSize, char *dstNameIndex, int dstNameSize);
int sqCopyDirectorysizetosize(char *srcNameIndex, int srcNameSize, char *dstNameIndex, int dstNameSize);
