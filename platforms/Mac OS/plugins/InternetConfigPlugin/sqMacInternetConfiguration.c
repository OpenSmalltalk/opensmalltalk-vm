/*  Sep 26th 2001
	Interface to the Internet Configuration toolkit
	John M McIntosh of Corporate Smalltalk Consulting Ltd
	johnmci@smalltalkconsulting.com 
	http://www.smalltalkconsulting.com 
        
    Nov 24th 2001 JMM fixed broken tempSpec code, was causing memory exception under os-x
    3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
    
	3.8.18b2  fix broken endian code in sqInternetGetMacintoshFileTypeAndCreatorFromkeySizeinto
    */


#include <InternetConfig.h>
#include "sq.h"
#include "InternetConfigPlugin.h"
#include "sqMacUnixFileInterface.h"
#include "sqMacUIConstants.h"

static OSType GetApplicationSignature(void);
void convertPassword(unsigned char *buffer);
							   
static ICInstance gICInstance;
static Boolean gInitializedOk=false;
void convertPSTRToString(unsigned char*pstr,char *target);

int sqInternetConfigurationInit(void) {
    OSStatus error;
    OSType   signature;
    
    if (gInitializedOk) 
        return 1;
        
#if !__LP64__
    if ((Ptr)ICStart==(Ptr)kUnresolvedCFragSymbolAddress) 
        return 0;
#endif
    
    signature = GetApplicationSignature();
    
    error = ICStart(&gICInstance, signature);
    if (error != noErr) 
        return 0;
        
    gInitializedOk = true;
    return 1;
}

int sqInternetConfigurationShutdown(void) {
    if (!gInitializedOk) 
        return 1;
    ICStop(gICInstance);
    gInitializedOk = false;
	return 1;
}

int sqInternetConfigurationGetStringKeyedBykeySizeinto(char *aKey,int keyLength, char *aString) {
    ICAttr junkAttr;
    long     size=0;
    OSStatus error;
    Str255   key;
    char     convertedKey[256],buffer[DOCUMENT_NAME_SIZE+1];
    ICFileSpec *tempICFileSpec;
    
    if (!gInitializedOk) 
        return 0;
   if (keyLength+1 > (int) sizeof(convertedKey))
        return 0;
   
    strncpy(convertedKey,aKey,keyLength);
    convertedKey[keyLength] = 0;
    CopyCStringToPascal(convertedKey,key);
    
    if (strcmp(convertedKey,"DownLoadPath") == 0) {
        size = sizeof(ICFileSpec);
        error  = ICGetPref(gICInstance, "\pDownloadFolder", nil, &buffer, &size);
        if (error == noErr || error == icTruncatedErr) {
			FSRef theFSRef;
			
            tempICFileSpec = (ICFileSpec *) &buffer;
			error = FSpMakeFSRef (&tempICFileSpec->fss, &theFSRef);
			if(error)
				return 0;
			PathToFileViaFSRef(aString, DOCUMENT_NAME_SIZE, &theFSRef,gCurrentVMEncoding);
           size = strlen(aString);
       } else 
            return 0;
   } else { 
        size = 1024;
        error  = ICGetPref(gICInstance, key, &junkAttr, &buffer, &size);
        if (error == noErr) {
            if (size == 0)
                return size;
                
            if ((strcmp(convertedKey,"FTPProxyPassword") == 0||
                strcmp(convertedKey,"MailPassword") == 0 ||
                strcmp(convertedKey,"NewsAuthPassword") == 0)) {
                convertPassword((unsigned char *)buffer);
            }
             
            if ((strcmp(convertedKey,"UseFTPProxy") == 0  ||
               strcmp(convertedKey,"UseGopherProxy") == 0 ||
               strcmp(convertedKey,"UseHTTPProxy") == 0   ||
               strcmp(convertedKey,"UsePassiveFTP") == 0  ||
               strcmp(convertedKey,"UseSocks") == 0)) {
                    if (buffer[0] == 0x01)
                        strcpy(aString,"1");
                    else
                        strcpy(aString,"0");
                    size = 1; 
            } else if (strcmp(convertedKey,"NoProxyDomains") == 0) {
                convertPSTRToString((unsigned char *)buffer,aString); 
                return strlen(aString);
            } else {
                CopyPascalStringToC((unsigned char *)buffer,aString);
                size--;
            }
        }
    }
    return size;
}

void sqInternetGetMacintoshFileTypeAndCreatorFromkeySizeinto(char * aFileName, int keyLength, char * creator){
    Str255      filename;
    char        convertedKey[256];
    ICMapEntry  mapEntry;
    OSStatus    error;
    
    if (!gInitializedOk)
        goto abort;

    if (keyLength+1 > (int) sizeof(convertedKey))
        goto abort;
   
    strncpy(convertedKey,aFileName,keyLength);
    convertedKey[keyLength] = 0;
    CopyCStringToPascal(convertedKey,filename);
    error = ICMapFilename(gICInstance,filename,&mapEntry);
    
    if (error != noErr)             
        goto abort;

	*((int *) creator) = CFSwapInt32BigToHost(mapEntry.fileType);
	*((int *) (creator+4)) = CFSwapInt32BigToHost(mapEntry.fileCreator);

    return;

    abort:
        strncpy(creator,"********",8);
        return;
}


static OSType GetApplicationSignature() {
    ProcessSerialNumber PSN;
    ProcessInfoRec pinfo;
    FSSpec pspec;
    OSStatus err;
        /* set up process serial number */
    PSN.highLongOfPSN = 0;
    PSN.lowLongOfPSN = kCurrentProcess;
        /* set up info block */
    pinfo.processInfoLength = sizeof(pinfo);
    pinfo.processName = NULL;
#if __LP64__
    pinfo.processAppRef = &pspec;
#else
    pinfo.processAppSpec = &pspec;
#endif
        /* grab the vrefnum and directory */
    err = GetProcessInformation(&PSN, &pinfo);
    if (err == noErr) {
        return pinfo.processSignature;
    }
    return 0;
}


void convertPassword(unsigned char *buffer) {
 int size,i;
 
 size = buffer[0];
 for (i=0;i<size;i++) {
    buffer[i+1] = buffer[i+1] ^ (0x55 + i + 1);
 }  
}

void convertPSTRToString(unsigned char*pstr,char *target) {
    unsigned char * arrayOfpstr;
    int    i,totalSize,size;
    short  numberOfpstr;
    
    numberOfpstr = *((short *) pstr);
    arrayOfpstr = pstr+sizeof(short);
    totalSize = 0;
    
    for(i=0;i<numberOfpstr;i++) {
        size = arrayOfpstr[0];
        if (totalSize + size > 1024) { 
            target[totalSize] = 0x00;
            return;
        }    
        memcpy(target+totalSize,(char *) arrayOfpstr+1,size);
        totalSize += size;
        target[totalSize++] = ',';
        arrayOfpstr += (size+1);
    }
    if (totalSize > 0)
         totalSize--;
    target[totalSize] = 0x00;
    return;
}
