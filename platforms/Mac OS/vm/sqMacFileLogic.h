#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
#else
	#include <Navigation.h>
	#include <StandardFile.h>
	#if defined(__MWERKS__)
		#include <path2fss.h>
	#endif
	#include <Aliases.h>
	#include <Gestalt.h>
	#include <string.h>	
#endif

OSErr	FSMakeFSSpecCompat(short vRefNum, long dirID, ConstStr255Param fileName,  FSSpec *spec);
OSStatus GetApplicationDirectory(FSSpec *workingDirectory);
int PathToDir(char *pathName, int pathNameMax, FSSpec *workingDirectory);
int PathToFile(char *pathName, int pathNameMax, FSSpec *workingDirectory);
OSErr makeFSSpec(char *pathString, int pathStringLength, FSSpec *spec);
							   
OSErr squeakFindImage(const FSSpecPtr defaultLocationfssPtr,FSSpecPtr documentfsSpec);
pascal void findImageEventProc(NavEventCallbackMessage callBackSelector,   NavCBRecPtr callBackParms,  NavCallBackUserData callBackUD);
pascal Boolean findImageFilterProc(AEDesc* theItem, void* info, NavCallBackUserData callBackUD, NavFilterModes filterMode);                       
pascal short DialogHook(short item, DialogPtr theDialog,  void *userData);
int fetchFileInfo(int dirIndex,FSSpec *spec,unsigned char *name,Boolean doAlias,long *parentDirectory, int *isFolder,int *createDateStorage,int *modificationDateStorage,squeakInt64 *sizeOfFile,Str255 *longFileName);
int doItTheHardWay(unsigned char *pathString,FSSpec *spec,Boolean noDrillDown);
int lookupPath(char *pathString, int pathStringLength, FSSpec *spec,Boolean noDrillDown);
void makeOSXPath(char * dst, int src, int num,Boolean resolveAlias);Boolean isVmPathVolumeHFSPlus(void);