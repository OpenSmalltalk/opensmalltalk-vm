//JMM 2/13/01 create docs folder if non-existant
//JMM 4/4/01  look for documents/My Squeak folder versus just documents as secure location
//JMM 5/3/01  path was wrong for unsecure folder which uncovered a bug in lookupPath
//JMM 8/15/01 only allow call to ioInitSecurity Once, also return  proper return code
//JMM 9/5/01  make it as a plugin

#include "sq.h"
#include "sqMacFileLogic.h"	
#include "securityPlugin.h"
#include <files.h> 
extern struct VirtualMachine * interpreterProxy;

#define fromSqueak(string,length) string
void fixPath(char *path);
int dir_CreateSecurity(char *pathString, int pathStringLength);
int _ioSetFileAccess(int enable);

static char secureUserDirectory[256];
static char untrustedUserDirectory[256];
static Boolean gInitialized = false;

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* file security */
static int allowFileAccess = 1;  /* full access to files */

static int isAccessiblePathName(char *pathName) {
  int i;
  /* Check if the path/file name is subdirectory of the image path */
  for(i=0; i<strlen(untrustedUserDirectory)-1; i++)
    if(untrustedUserDirectory[i] != pathName[i]) return 0;
  /* special check for the trusted directory */
  if(pathName[i] == 0) return 1; /* allow access to trusted directory */
  /* check last character in image path (e.g., backslash) */
  if(untrustedUserDirectory[i] != pathName[i]) return 0;
  /* check if somebody wants to trick us into using relative
     paths ala Foo:My Squeak:allowed::" */
  while(pathName[i]) {
    if(pathName[i] == ':') {
      if(pathName[i+1] == ':')
	return 0; /* Gotcha! */
    }
    i++;
  }
  return 1;
}

static int isAccessibleFileName(char *fileName) {
  int i;
  /* Check if the path/file name is subdirectory of the image path */
  for(i=0; i<strlen(untrustedUserDirectory); i++)
    if(untrustedUserDirectory[i] != fileName[i]) return 0;
  /* check if somebody wants to trick us into using relative
     paths ala Foo:My Squeak:allowed::" */
  while(fileName[i]) {
    if(fileName[i] == ':') {
      if(fileName[i+1] == ':')
	return 0; /* Gotcha! */
    }
    i++;
  }
  return 1;
}

/* directory access */
int ioCanCreatePathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}

int ioCanListPathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}

int ioCanDeletePathOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessiblePathName(fromSqueak(pathString, pathStringLength));
}

/* file access */
int ioCanOpenFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag) {
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}

int ioCanOpenAsyncFileOfSizeWritable(char* pathString, int pathStringLength, int writeFlag) {
  return ioCanOpenFileOfSizeWritable(pathString,pathStringLength,writeFlag);
}
int ioCanDeleteFileOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}

int ioCanRenameFileOfSize(char* pathString, int pathStringLength) {
  if(allowFileAccess) return 1;
  return isAccessibleFileName(fromSqueak(pathString, pathStringLength));
}


int ioCanGetFileTypeOfSize(char* pathString, int pathStringLength) {
  return 1; /* of no importance here */
}

int ioCanSetFileTypeOfSize(char* pathString, int pathStringLength) {
  return 1; /* of no importance here */
}

/* disabling/querying */
int ioDisableFileAccess(void) {
  allowFileAccess = 0;
}

int ioHasFileAccess(void) {
  return allowFileAccess;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* image security */

static int allowImageWrite = 1;  /* allow writing the image */

int ioCanRenameImage(void) {
  return allowImageWrite; /* only when we're allowed to save the image */
}

int ioCanWriteImage() {
  return allowImageWrite;
}

int ioDisableImageWrite() {
  allowImageWrite = 0;
}


/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* socket security - for now it's all or nothing */
static int allowSocketAccess = 1; /* allow access to sockets */

int ioCanCreateSocketOfType(int netType, int socketType) {
  return allowSocketAccess;
}

int ioCanConnectToPort(int netAddr, int port) {
  return allowSocketAccess;
}

int ioCanListenOnPort(int  s, int port) {
  return allowSocketAccess;
}

int ioDisableSocketAccess() {
  allowSocketAccess = 0;
}

int ioHasSocketAccess() {
  return allowSocketAccess;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* SecurityPlugin primitive support */


char *ioGetSecureUserDirectory(void) {
  return  secureUserDirectory;
}

char *ioGetUntrustedUserDirectory(void) {
  return untrustedUserDirectory;
}

/* note: following is called from VM directly, not from plugin */
int ioInitSecurity(void) {
  short vRefNum;
  long  dirID;
  OSErr err;
  FSSpec spec;
  int   iLoadAS,iDropDrag;
  char  *data;
  
  if (gInitialized) return 1;
  gInitialized  = true;

  iDropDrag = interpreterProxy->ioLoadFunctionFrom("setFileAccessCallback", "DropPlugin");
  if (iDropDrag != 0) {
    ((int (*) (void *)) iDropDrag)(&_ioSetFileAccess);
  }

  iLoadAS = interpreterProxy->ioLoadFunctionFrom("GetAttributeString", "");
  if (iLoadAS == 0) {
    return 0;
  }

    /* establish the secure user directory */
  data =  ((char * (*) (int)) iLoadAS)(1);
  strcpy(secureUserDirectory, data);
  fixPath(secureUserDirectory);
  
  /* establish untrusted user directory */

	/* get the path to the system folder preference area*/
	err = FindFolder(kOnSystemDisk, kPreferencesFolderType, kDontCreateFolder, &vRefNum, &dirID);
	if (err != noErr) {
      strcpy(untrustedUserDirectory, "foobar:tooBar:forSqueak:bogus:");
      fixPath(untrustedUserDirectory);
      return 1;
	}
	
	// Look for folder, if not found abort */
        FSMakeFSSpecCompat(vRefNum,dirID,"\p",&spec);
	PathToFile(untrustedUserDirectory,255,&spec);
	strcat(untrustedUserDirectory,"Squeak:Internet");
 	err = makeFSSpec(untrustedUserDirectory, strlen(untrustedUserDirectory),&spec);
 	if (err != noErr) {
	      strcpy(untrustedUserDirectory, "foobar:tooBar:forSqueak:bogus:");
	      fixPath(untrustedUserDirectory);
		return 0;
	}	
	strcat(untrustedUserDirectory,":My Squeak");
	err = makeFSSpec(untrustedUserDirectory, strlen(untrustedUserDirectory),&spec);
	if (err != noErr) {
		if (!dir_CreateSecurity(untrustedUserDirectory,strlen(untrustedUserDirectory))) {
	      strcpy(untrustedUserDirectory, "foobar:tooBar:forSqueak:bogus:");
		  fixPath(untrustedUserDirectory);
		}
	}
  return 1;
}

/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/***************************************************************************/
/* private entries for restoring rights */
int _ioSetImageWrite(int enable) {
  if(enable == allowImageWrite) return 1;
  allowImageWrite = enable;
  return 1;
}

int _ioSetFileAccess(int enable) {
  if(enable == allowFileAccess) return 1;
  allowFileAccess = enable;
  return 1;
}

int _ioSetSocketAccess(int enable) {
  if(enable == allowSocketAccess) return 1;
  allowSocketAccess = enable;
  return 1;
}


void fixPath(char *path) {
    long i;
    for(i=strlen(path);i>0;i--) 
        if(path[i-1]==':') {
            path[i-1]=0x00;
            return;
        }
}

int dir_CreateSecurity(char *pathString, int pathStringLength) {
	/* Create a new directory with the given path. By default, this
	   directory is created in the current directory. Use
	   a full path name such as "MyDisk:Working:New Folder" to
	   create folders elsewhere. */

    //JMM tests create file in Vm directory, other place, other volume
    
    FSSpec spec;
    OSErr  err;
    long  createdDirID;
    
    if ((err = makeFSSpec(pathString, pathStringLength,&spec)) == -1)
        return false;
        
   	return FSpDirCreate(&spec,smSystemScript,&createdDirID) == noErr;
}
