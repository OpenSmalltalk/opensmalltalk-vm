/****************************************************************************
*   PROJECT: Mac read and write the image 
*   FILE:    sqMacImageIO.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacImageIO.c,v 1.4 2003/12/02 04:52:31 johnmci Exp $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
 3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
*****************************************************************************/

#include "sq.h"
#include "sqMacImageIO.h"
#include "sqMacUIConstants.h"
#include "sqMacWindow.h"
#include "sqMacFileLogic.h"
#include "sqMacEncoding.h"



/*** VM Home Directory Path ***/

squeakFileOffsetType calculateStartLocationForImage(void);

int vmPathSize(void) {
        char path[VMPATH_SIZE + 1];
        
        getVMPathWithEncoding(path,gCurrentVMEncoding);
	return strlen(path);
}

int vmPathGetLength(int sqVMPathIndex, int length) {
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

int imageNameGetLength(int sqImageNameIndex, int length) {
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

int imageNamePutLength(int sqImageNameIndex, int length) {
	char *sqImageName = (char *) sqImageNameIndex;
	int count, i, ch, j;
	int lastColonIndex = -1;
        char name[IMAGE_NAME_SIZE + 1];  /* full path to image file */
        char shortImageName[SHORTIMAGE_NAME_SIZE+1];

	count = (IMAGE_NAME_SIZE < length) ? IMAGE_NAME_SIZE : length;

	/* copy the file name into a null-terminated C string */
	for (i = 0; i < count; i++) {
		ch = name[i] = sqImageName[i];
		if (ch == ':') {
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
	SetWindowTitle(shortImageName);
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
#if defined ( __APPLE__ ) && defined ( __MACH__ )
void sqImageFileClose(sqImageFile f) {
   if (f != 0)
      fclose(f);
}

sqImageFile sqImageFileOpen(char *fileName, char *mode) {
    char cFileName[1024];
    sqImageFile remember;
    
    sqFilenameFromStringOpen(cFileName,(long) fileName, strlen(fileName));
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

void        sqImageFileSeek(sqImageFile f, squeakFileOffsetType pos) {
    if (f != 0)
      fseeko(f, pos, SEEK_SET);
}

int sqImageFileWrite(void *ptr, size_t elementSize, size_t count, sqImageFile f) {
    if (f != 0)
      return fwrite(ptr,elementSize,count,f);
}

squeakFileOffsetType calculateStartLocationForImage() {
    return 0;
}

squeakFileOffsetType sqImageFileStartLocation(int fileRef, char *filename, squeakFileOffsetType imageSize){
    return 0;
}
#else
void sqImageFileClose(sqImageFile f) {
    FSClose(f);
}

sqImageFile sqImageFileOpen(char *fileName, char *mode) {
	short int err, err2, fRefNum;
	FInfo fileInfo;
        FSSpec imageSpec;
        
        makeFSSpec(fileName, strlen(fileName), &imageSpec);
	if (strchr(mode, 'w') != null) 
	    err = FSpOpenDF(&imageSpec,fsRdWrPerm, &fRefNum);
	 else
	    err = FSpOpenDF(&imageSpec,fsRdPerm, &fRefNum);
	    
	if ((err != noErr) && (strchr(mode, 'w') != null)) {
		/* creating a new file for "save as" */
		err2 = FSpCreate(&imageSpec,'FAST', 'STim',smSystemScript);
		if (err2 == noErr) {
                    err = FSpOpenDF(&imageSpec,fsRdWrPerm, &fRefNum);
		}
	}

	if (err != 0) return null;

	if (strchr(mode, 'w') != null) {
        err = FSpGetFInfo(&imageSpec,&fileInfo);
        if (err != noErr) return 0; //This should not happen
        
        //On the mac we start at location 0 if this isn't an VM
        
    	if (!(fileInfo.fdType == 'APPL' && fileInfo.fdCreator == 'FAST')){
    		/* truncate non-VM file if opening in write mode */
    		err = SetEOF(fRefNum, 0);
    		if (err != 0) {
    			FSClose(fRefNum);
    			return null;
    		}
	    }
	}
	return (sqImageFile) fRefNum;
}

squeakFileOffsetType sqImageFilePosition(sqImageFile f) {
	long int currentPosition = 0;

	GetFPos(f, &currentPosition);
	return currentPosition;
}

size_t sqImageFileRead(void *ptr, size_t elementSize, size_t count, sqImageFile f) {
	size_t byteCount = elementSize * count;
	ParamBlockRec pb;
    OSErr error;

	pb.ioParam.ioRefNum = f;
    pb.ioParam.ioCompletion = NULL;
    pb.ioParam.ioBuffer = (Ptr)ptr;
    pb.ioParam.ioReqCount = byteCount;
    pb.ioParam.ioPosMode = fsAtMark + noCacheMask;
    pb.ioParam.ioPosOffset = 0;
    error = PBReadSync(&pb);
    byteCount = pb.ioParam.ioActCount;       
    
	if (error != 0) return 0;
	return byteCount / elementSize;
}

void sqImageFileSeek(sqImageFile f, squeakFileOffsetType pos) {
	SetFPos(f, fsFromStart, pos);
}

int sqImageFileWrite(void *ptr, size_t elementSize, size_t count, sqImageFile f) {
	long int byteCount = elementSize * count;
	ParamBlockRec pb;
    OSErr error;

    pb.ioParam.ioRefNum = f;
    pb.ioParam.ioCompletion = NULL;
    pb.ioParam.ioBuffer = (Ptr)ptr;
    pb.ioParam.ioReqCount = byteCount;
    pb.ioParam.ioPosMode = fsAtMark + noCacheMask;
    pb.ioParam.ioPosOffset = 0;
    error = PBWriteSync(&pb);
    byteCount = pb.ioParam.ioActCount;       
    
	if (error != 0) 
	    return 0;
	return byteCount / elementSize;
}

squeakFileOffsetType calculateStartLocationForImage() { 

	Handle cfrgResource;  
	long	memberCount,i;
	CFragResourceMember *target;
	
	cfrgResource = GetResource(kCFragResourceType,0); 
	if (cfrgResource == nil || ResError() != noErr) { return 0;};  
	
	memberCount = ((CFragResource *)(*cfrgResource))->memberCount;
	if (memberCount <= 1) {
        ReleaseResource(cfrgResource);
	    return 0; //Need FAT to get counters right
	}
	
	target = &((CFragResource *)(*cfrgResource))->firstMember;
	for(i=0;i<memberCount;i++) {
		if (target->architecture == 'FAST') {			
		    ReleaseResource(cfrgResource);
		    return target->offset;
		}
		target = NextCFragResourceMemberPtr(target); 
	}
    ReleaseResource(cfrgResource);
	return 0;
}

squeakFileOffsetType sqImageFileStartLocation(int fileRef, char *filename, squeakFileOffsetType imageSize){
    FInfo fileInfo;
	OSErr   err; 
    SInt16  resFileRef;
	Handle  cfrgResource,newcfrgResource;  
    UInt32  maxOffset=0,maxOffsetLength,targetOffset;
	long    memberCount,i;
	CFragResourceMember *target;
    FSSpec  imageSpec;
    
    makeFSSpec(filename, strlen(filename), &imageSpec);
    err = FSpGetFInfo(&imageSpec,&fileInfo);
    if (err != noErr) return 0; //This should not happen
    
    //On the mac we start at location 0 if this isn't an VM
    
	if (!(fileInfo.fdType == 'APPL' && fileInfo.fdCreator == 'FAST')) return 0;
    
    //Ok we have an application file, open the resource part and attempt to find the crfg
    
    err = FSpOpenDF(&imageSpec,fsWrPerm, &resFileRef);
    if (err != noErr || resFileRef == -1) return 0;
    
	cfrgResource = GetResource(kCFragResourceType,0);
	if (cfrgResource == nil || ResError() != noErr) {CloseResFile(resFileRef); return 0;};  
	
	memberCount = ((CFragResource *)(*cfrgResource))->memberCount;
	if (memberCount == 0) {ReleaseResource(cfrgResource); CloseResFile(resFileRef); return 0;};  //Need FAT to get counters right
	
	target = &((CFragResource *)(*cfrgResource))->firstMember;
	
	if (memberCount == 1) {
	   if (target->length == 0) {
        	SInt16 fileRef;
        	long lengthOfDataFork;
        	err = FSpOpenDF(&imageSpec,fsRdPerm, &fileRef);
        	if (err) {ReleaseResource(cfrgResource); CloseResFile(resFileRef); FSClose(fileRef); return 0;}; 
        	
        	GetEOF(fileRef,&lengthOfDataFork);
            FSClose(fileRef);
            
	        target->length = lengthOfDataFork; //Fix up zero length targets
			maxOffset = target->offset;
			maxOffsetLength = target->length;
       } else {
			maxOffset = target->offset;
			maxOffsetLength = target->length;
       }
    } else {
	    for(i=0;i<memberCount;i++) {
    		if (target->architecture == 'FAST') {
    		    targetOffset = target->offset;
    		    target->length = imageSize;
    		    ChangedResource(cfrgResource);
            	if (ResError() != noErr) {ReleaseResource(cfrgResource); CloseResFile(resFileRef); return 0;}; 
    		    UpdateResFile(resFileRef);
            	if (ResError() != noErr) {ReleaseResource(cfrgResource); CloseResFile(resFileRef); return 0;}; 
                ReleaseResource(cfrgResource); 
    		    CloseResFile(resFileRef);
    			return targetOffset;
    		}
    		if (target->offset > maxOffset) {
    			maxOffset = target->offset;
    			maxOffsetLength = target->length;
    		}
    		target = NextCFragResourceMemberPtr(target);
    	}
	}
	//Ok at this point we need to alter the crfg to add the new tag for the image part
	
	newcfrgResource = cfrgResource;
	err = HandToHand(&newcfrgResource);
	if (err != noErr || MemError() != noErr)  {ReleaseResource(cfrgResource); CloseResFile(resFileRef); return 0;}; 
	SetHandleSize(newcfrgResource,GetHandleSize(cfrgResource)+AlignToFour(kBaseCFragResourceMemberSize + 1));
	if (MemError() != noErr)  {ReleaseResource(cfrgResource); CloseResFile(resFileRef); return 0;}; 
	
	target = &((CFragResource *)(*newcfrgResource))->firstMember; 
	for(i=0;i<memberCount;i++) {
		target = NextCFragResourceMemberPtr(target); 
	}

    target->architecture = 'FAST';
    target->reservedA = 0;                  /* ! Must be zero!*/
    target->reservedB = 0;                  /* ! Must be zero!*/
    target->updateLevel = 0;
    target->currentVersion = 0;
    target->oldDefVersion = 0;
    target->uUsage1.appStackSize = 0;
    target->uUsage2.appSubdirID = 0;
    target->uUsage2.libFlags = 0;
    target->usage = kApplicationCFrag;
    target->where = kDataForkCFragLocator;
    target->offset = maxOffset + maxOffsetLength;
    targetOffset = target->offset;
    target->length = imageSize;
    target->uWhere1.spaceID = 0;
    target->extensionCount = 0;             /* The number of extensions beyond the name.*/
    target->memberSize = AlignToFour(kBaseCFragResourceMemberSize + 1);   /* Size in bytes, includes all extensions.*/
    target->name[0] = 0x00;

	((CFragResource *)(*newcfrgResource))->memberCount = memberCount+1;
	RemoveResource(cfrgResource);
	if (ResError() != noErr) {CloseResFile(resFileRef); return 0;}; 
 	AddResource(newcfrgResource,kCFragResourceType,0,nil);
	if (ResError() != noErr) {CloseResFile(resFileRef); return 0;}; 
    UpdateResFile(resFileRef);
	if (ResError() != noErr) {CloseResFile(resFileRef); return 0;}; 
    CloseResFile(resFileRef);
    
	return targetOffset;
}

#endif




