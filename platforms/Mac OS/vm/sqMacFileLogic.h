/****************************************************************************
*   PROJECT: Mac directory logic
*   FILE:    sqMacFileLogic.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id$
*
*   NOTES: See change log below.
*	Jan 2nd 2002 JMM added logic to make lookups faster
*	Jan 22nd 2002 JMM squeak file type offset change
*       Nov 25th 2003 JMM add gCurrentVMEncoding
        3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
	Mar 24th, 2005 JMM add routine for posix to HFS+
*/
#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
    extern CFStringEncoding gCurrentVMEncoding;

#else
	#include <Navigation.h>
	#include <StandardFile.h>
	#if defined(__MWERKS__)
		#include <path2fss.h>
	#endif
	#include <Aliases.h>
	#include <Gestalt.h>
	#include <string.h>	
	extern UInt32 gCurrentVMEncoding;
#endif

OSErr	FSMakeFSSpecCompat(short vRefNum, long dirID, ConstStr255Param fileName,  FSSpec *spec);
OSStatus GetApplicationDirectory(FSSpec *workingDirectory);
int PathToDir(char *pathName, int pathNameMax, FSSpec *workingDirectory,UInt32 encoding);
int PathToFile(char *pathName, int pathNameMax, FSSpec *workingDirectory,UInt32 encoding);
OSErr makeFSSpec(char *pathString, int pathStringLength, FSSpec *spec);
							   
OSErr squeakFindImage(const FSSpecPtr defaultLocationfssPtr,FSSpecPtr documentfsSpec);
pascal void findImageEventProc(NavEventCallbackMessage callBackSelector,   NavCBRecPtr callBackParms,  NavCallBackUserData callBackUD);
pascal Boolean findImageFilterProc(AEDesc* theItem, void* info, NavCallBackUserData callBackUD, NavFilterModes filterMode);                       
pascal short DialogHook(short item, DialogPtr theDialog,  void *userData);
int fetchFileInfo(int dirIndex,FSSpec *spec,unsigned char *name,Boolean doAlias,long *parentDirectory, int *isFolder,int *createDateStorage,int *modificationDateStorage,squeakFileOffsetType *sizeOfFile,Str255 *longFileName);
int doItTheHardWay(unsigned char *pathString,FSSpec *spec,Boolean noDrillDown);
int lookupPath(char *pathString, int pathStringLength, FSSpec *spec,Boolean noDrillDown,Boolean tryShortCut);
void makeOSXPath(char * dst, int src, int num,Boolean resolveAlias);
Boolean isVmPathVolumeHFSPlus(void);
int makeHFSFromPosixPath(char *pathString, int pathStringLength,char *dst, char *lastPath) ;