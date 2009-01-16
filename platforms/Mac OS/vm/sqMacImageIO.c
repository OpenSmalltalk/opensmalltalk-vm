/****************************************************************************
*   PROJECT: Mac read and write the image 
*   FILE:    sqMacImageIO.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id$
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
 3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
 3.8.11b1 Mar 4th, 2006 JMM refactor, cleanup and add headless support
*****************************************************************************/

#include "sq.h"
#include "sqMacImageIO.h"
#include "sqMacUIConstants.h"
#include "sqMacWindow.h"
#include "sqMacFileLogic.h"
#include "sqMacEncoding.h"



/*** VM Home Directory Path ***/

int vmPathSize(void) {
        char path[VMPATH_SIZE + 1];
        
        getVMPathWithEncoding(path,gCurrentVMEncoding);
	return strlen(path);
}

int vmPathGetLength(sqInt sqVMPathIndex, int length) {
	char *stVMPath = (char *) sqVMPathIndex;
	int count, i;
        char path[VMPATH_SIZE + 1];

        getVMPathWithEncoding(path,gCurrentVMEncoding);
	count = strlen(path);
	count = (length < count) ? length : count;

	/* copy the file name into the Squeak string */
	for (i = 0; i < count; i++) {
		stVMPath[i] = path[i];
	}
	return count;
}

/*** Image File Naming ***/

int imageNameSize(void) {
    char path[IMAGE_NAME_SIZE+1];
    getImageNameWithEncoding(path,gCurrentVMEncoding);

    return strlen(path);
}

int imageNameGetLength(sqInt sqImageNameIndex, int length) {
	char *sqImageName = (char *) sqImageNameIndex;
	int count, i;
        char path[IMAGE_NAME_SIZE+1];
        getImageNameWithEncoding(path,gCurrentVMEncoding);

	count = strlen(path);
	count = (length < count) ? length : count;

	/* copy the file name into the Squeak string */
	for (i = 0; i < count; i++) {
		sqImageName[i] = path[i];
	}
	return count;
}

int imageNamePutLength(sqInt sqImageNameIndex, int length) {
	char *sqImageName = (char *) sqImageNameIndex;
	int count, i, ch, j;
	int lastColonIndex = -1;
        char name[IMAGE_NAME_SIZE + 1];  /* full path to image file */
        char shortImageName[SHORTIMAGE_NAME_SIZE+1];

	count = (IMAGE_NAME_SIZE < length) ? IMAGE_NAME_SIZE : length;

	/* copy the file name into a null-terminated C string */
	for (i = 0; i < count; i++) {
		ch = name[i] = sqImageName[i];
		if (ch == DELIMITERInt) {
			lastColonIndex = i;
		}
	}
	name[count] = 0; 
        SetImageNameViaString(name,gCurrentVMEncoding);

	/* copy short image name into a null-terminated C string */
	for (i = lastColonIndex + 1, j = 0; i < count; i++, j++) {
		shortImageName[j] = name[i];
	}
	shortImageName[j] = 0;

        SetShortImageNameViaString(shortImageName,gCurrentVMEncoding);
	SetWindowTitle(1,shortImageName);
	return count;
}

int IsImageName(char *name) {
	char *suffix;

	suffix = strrchr(name, '.');  /* pointer to last period in name */
	if (suffix == NULL) return false;
	if (strcmp(suffix, ".ima") == 0) return true;
	if (strcmp(suffix, ".image") == 0) return true;
	if (strcmp(suffix, ".IMA") == 0) return true;
	if (strcmp(suffix, ".IMAGE") == 0) return true;
	return false;
}

/*** Image File Operations ***/
void sqImageFileClose(sqImageFile f) {
   if (f != 0)
      fclose(f);
}

sqImageFile sqImageFileOpen(char *fileName, char *mode) {
    char cFileName[DOCUMENT_NAME_SIZE+1];
    sqImageFile remember;
    
    sqFilenameFromStringOpen(cFileName,(sqInt) fileName, strlen(fileName));
    remember = fopen(cFileName, mode);
    if (remember == null) 
        return null;
    setvbuf(remember,0, _IOFBF, 256*1024);
    return remember;
}

squeakFileOffsetType sqImageFilePosition(sqImageFile f) {
    if (f != 0)
      return ftello(f);
    return 0;
}

size_t      sqImageFileRead(void *ptr, size_t elementSize, size_t count, sqImageFile f) {
    if (f != 0)
      return fread(ptr, elementSize, count, f);
    return 0;
}

size_t      sqImageFileReadEntireImage(void *ptr, size_t elementSize, size_t count, sqImageFile f) {
	extern Boolean gSqueakUseFileMappedMMAP;
	if (gSqueakUseFileMappedMMAP) 
		return count;
	return sqImageFileRead(ptr, elementSize, count, f); 
}

void        sqImageFileSeek(sqImageFile f, squeakFileOffsetType pos) {
    if (f != 0)
      fseeko(f, pos, SEEK_SET);
}

sqInt sqImageFileWrite(void *ptr, size_t elementSize, size_t count, sqImageFile f) {
    if (f != 0)
      return fwrite(ptr,elementSize,count,f);
	return 0;
}

squeakFileOffsetType sqImageFileStartLocation(sqInt fileRef, char *filename, squeakFileOffsetType imageSize){
#pragma unused(fileRef,filename,imageSize)
    return 0;
}



