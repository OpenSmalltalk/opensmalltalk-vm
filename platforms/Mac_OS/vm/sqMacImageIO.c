/****************************************************************************
*   PROJECT: Mac read and write the image 
*   FILE:    sqMacImageIO.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacImageIO.c 1708 2007-06-10 00:40:04Z johnmci $
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
#include "sqMacUnixFileInterface.h"
#include "sqMacEncoding.h"


/* On Newspeak we want to answer the Resources directory for vmPathGetLength/
 * primitiveVMPath/primVMPath since this allows us to put the sources file
 * in the Resources directory.  Controlled by the SqueakVMPathAnswersResources
 * boolean in the Info.plist file.
 */
extern Boolean gSqueakVMPathAnswersResources;

static void
getVMResourcesDirectory(char *path)
{
extern char **argVec;

	ux2sqPath(argVec[0], strlen(argVec[0]), path, VMPATH_SIZE,1);	
	strcpy(strstr(path,"MacOS/"),"Resources/");
}

/*** VM Home Directory Path ***/

sqInt
vmPathSize(void) {
	char path[VMPATH_SIZE + 1];

	if (gSqueakVMPathAnswersResources)
		getVMResourcesDirectory(path);
	else
		getVMPathWithEncoding(path,gCurrentVMEncoding);
	return strlen(path);
}

sqInt
vmPathGetLength(sqInt sqVMPathIndex, sqInt length) {
	char *stVMPath = (char *) sqVMPathIndex;
	int count, i;
	char path[VMPATH_SIZE + 1];

	if (gSqueakVMPathAnswersResources)
		getVMResourcesDirectory(path);
	else
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

sqInt
imageNameSize(void) {
    char path[IMAGE_NAME_SIZE+1];
    getImageNameWithEncoding(path,gCurrentVMEncoding);

    return strlen(path);
}

sqInt
imageNameGetLength(sqInt sqImageNameIndex, sqInt length) {
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

sqInt
imageNamePutLength(sqInt sqImageNameIndex, sqInt length) {
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

int
IsImageName(char *name) {
	char *suffix;

	suffix = strrchr(name, '.');  /* pointer to last period in name */
	if (suffix) {
		if (!strcmp(suffix, ".ima")) return true;
		if (!strcmp(suffix, ".image")) return true;
		if (!strcmp(suffix, ".IMA")) return true;
		if (!strcmp(suffix, ".IMAGE")) return true;
	}
	return false;
}

/*** Image File Operations ***/
void
sqImageFileClose(sqImageFile f) {
   if (f != 0)
      fclose(f);
}

sqImageFile
sqImageFileOpen(char *fileName, char *mode) {
    char cFileName[DOCUMENT_NAME_SIZE+1];
    sqImageFile remember;
    
    sqFilenameFromStringOpen(cFileName,(sqInt) fileName, strlen(fileName));
    remember = fopen(cFileName, mode);
    if (remember == null) 
        return null;
    setvbuf(remember,0, _IOFBF, 256*1024);
    return remember;
}

squeakFileOffsetType
sqImageFilePosition(sqImageFile f) { return f ? ftello(f) : 0; }

size_t
sqImageFileRead(void *ptr, size_t elementSize, size_t count, sqImageFile f) {
	return f ? fread(ptr, elementSize, count, f) : 0;
}

void
sqImageFileSeek(sqImageFile f, squeakFileOffsetType pos) {
	if (f != 0)
		fseeko(f, pos, SEEK_SET);
}

sqInt
sqImageFileWrite(void *ptr, size_t elementSize, size_t count, sqImageFile f) {
	return f ? fwrite(ptr,elementSize,count,f) : 0;
}
