#include <Navigation.h>
#include <StandardFile.h>
#if !defined( __MPW__ ) &&  !defined ( __APPLE__ ) && !defined ( __MACH__ )
 #include <path2fss.h>
#else
#include <Aliases.h>
#include <Gestalt.h>
#endif

pascal	OSErr	FSMakeFSSpecCompat(short vRefNum,
								   long dirID,
								   ConstStr255Param fileName,
								   FSSpec *spec);
OSErr FSpLocationFromFullPath(short fullPathLength,
									 const void *fullPath,
									 FSSpec *spec);
									 
pascal	OSErr	GetFullPath(short vRefNum,
							long dirID,
							ConstStr255Param name,
							short *fullPathLength,
							Handle *fullPath);

pascal	OSErr	FSpGetFullPath(const FSSpec *spec,
							   short *fullPathLength,
							   Handle *fullPath);
							   
OSErr squeakFindImage(const FSSpecPtr defaultLocationfssPtr,FSSpecPtr documentfsSpec);
pascal void findImageEventProc(NavEventCallbackMessage callBackSelector, 
                        NavCBRecPtr callBackParms, 
                        NavCallBackUserData callBackUD);
pascal Boolean findImageFilterProc(AEDesc* theItem, void* info, 
                            NavCallBackUserData callBackUD,
                            NavFilterModes filterMode);                        						
pascal short DialogHook(short item, DialogPtr theDialog, 
	void *userData);
	
OSStatus GetApplicationDirectory(short *vRefNum, long *dirID);
int PathToWorkingDir(char *pathName, int pathNameMax, short volumeNumber,long directoryID);
int PrefixPathWith(char *pathName, int pathNameSize, int pathNameMax, char *prefix);
void StoreFullPathForLocalNameInto(char *shortName, char *fullName, int length, short VolumeNumber,long directoryID);
OSErr makeFSSpec(char *pathString, int pathStringLength,FSSpec *spec);
int fetchFileInfo(CInfoPBRec *pb,int dirIndex,FSSpec *spec,unsigned char *name, Boolean doAlias, Boolean *isFolder);
int doItTheHardWay(unsigned char *pathString,FSSpec *spec,CInfoPBRec *pb,Boolean noDrillDown);
int lookupPath(char *pathString, int pathStringLength, FSSpec *spec,Boolean noDrillDown);
void makePascalStringFromSqName(char *pathString, int pathStringLength,unsigned char *name);
