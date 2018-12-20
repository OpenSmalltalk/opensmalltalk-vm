
#include "sq.h"
#include <Carbon/Carbon.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#define MAXPATHLEN 256

extern struct VirtualMachine *interpreterProxy;

static kern_return_t FindModems(io_iterator_t *matchingServices);
static void GetModemPath(io_iterator_t serialPortIterator, char *bsdPath, CFIndex maxPathSize, char *key, CFIndex maxKeySize);
int serialPortFindNamesPlusKeysstorage(int numberOf,int storage);

int serialPortFindNamesPlusKeysstorage(int numberOf,int storage) {
    char *where;
    int	i;
    io_iterator_t serialPortIterator;
    kern_return_t  kernResult; 
    char  bsdPath[MAXPATHLEN], key[MAXPATHLEN];
 
    where = (char *) storage;
    kernResult = FindModems(&serialPortIterator);
    if (kernResult != 0) 
        return kernResult;
        
    for(i=0;i<numberOf;i++) {
	GetModemPath(serialPortIterator, bsdPath, sizeof(bsdPath),key,sizeof(key));
        if (bsdPath[0] == 0x00) 
                goto done;
        memmove(where,key,strlen(key)+1);
        where+= 256;
        memmove(where,bsdPath,strlen(bsdPath)+1);
        where+= 256;
        
    }
    done:
    IOObjectRelease(serialPortIterator); // Release the iterator.
    return 0;
 
}
// Returns an iterator across all known modems. Caller is responsible for
// releasing the iterator when iteration is complete.
static kern_return_t FindModems(io_iterator_t *matchingServices)
{
    kern_return_t  kernResult; 
    mach_port_t   masterPort;
    CFMutableDictionaryRef classesToMatch;

/*! @function IOMasterPort
    @abstract Returns the mach port used to initiate communication with IOKit.
    @discussion Functions that don't specify an existing object require the IOKit master port to be passed. This function obtains that port.
    @param bootstrapPort Pass MACH_PORT_NULL for the default.
    @param masterPort The master port is returned.
    @result A kern_return_t error code. */

    kernResult = IOMasterPort(MACH_PORT_NULL, &masterPort);
    if (KERN_SUCCESS != kernResult)
    {
        goto exit;
    }
        
/*! @function IOServiceMatching
    @abstract Create a matching dictionary that specifies an IOService class match.
    @discussion A very common matching criteria for IOService is based on its class. IOServiceMatching will create a matching dictionary that specifies any IOService of a class, or its subclasses. The class is specified by C-string name.
    @param name The class name, as a const C-string. Class matching is successful on IOService's of this class or any subclass.
    @result The matching dictionary created, is returned on success, or zero on failure. The dictionary is commonly passed to IOServiceGetMatchingServices or IOServiceAddNotification which will consume a reference, otherwise it should be released with CFRelease by the caller. */

    // Serial devices are instances of class IOSerialBSDClient
    classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
    if (classesToMatch == NULL)
    {
    }
    else {
/*!
 @function CFDictionarySetValue
 Sets the value of the key in the dictionary.
 @param theDict The dictionary to which the value is to be set. If this
  parameter is not a valid mutable CFDictionary, the behavior is
  undefined. If the dictionary is a fixed-capacity dictionary and
  it is full before this operation, and the key does not exist in
  the dictionary, the behavior is undefined.
 @param key The key of the value to set into the dictionary. If a key 
  which matches this key is already present in the dictionary, only
  the value is changed ("add if absent, replace if present"). If
  no key matches the given key, the key-value pair is added to the
  dictionary. If added, the key is retained by the dictionary,
  using the retain callback provided
  when the dictionary was created. If the key is not of the sort
  expected by the key retain callback, the behavior is undefined.
 @param value The value to add to or replace into the dictionary. The value
  is retained by the dictionary using the retain callback provided
  when the dictionary was created, and the previous value if any is
  released. If the value is not of the sort expected by the
  retain or release callbacks, the behavior is undefined.
*/
        /*CFDictionarySetValue(classesToMatch,
                             CFSTR(kIOSerialBSDTypeKey),
                             CFSTR(kIOSerialBSDModemType));
        CFDictionarySetValue(classesToMatch,
                             CFSTR(kIOSerialBSDTypeKey),
                             CFSTR(kIOSerialBSDRS232Type));*/
       // Each serial device object has a property with key
        // kIOSerialBSDTypeKey and a value that is one of kIOSerialBSDAllTypes,
        // kIOSerialBSDModemType, or kIOSerialBSDRS232Type. 
    }
    
    /*! @function IOServiceGetMatchingServices
        @abstract Look up registered IOService objects that match a matching dictionary.
        @discussion This is the preferred method of finding IOService objects currently registered by IOKit. IOServiceAddNotification can also supply this information and install a notification of new IOServices. The matching information used in the matching dictionary may vary depending on the class of service being looked up.
        @param masterPort The master port obtained from IOMasterPort().
        @param matching A CF dictionary containing matching information, of which one reference is consumed by this function. IOKitLib can contruct matching dictionaries for common criteria with helper functions such as IOServiceMatching, IOOpenFirmwarePathMatching.
        @param existing An iterator handle is returned on success, and should be released by the caller when the iteration is finished.
        @result A kern_return_t error code. */

    kernResult = IOServiceGetMatchingServices(masterPort, classesToMatch, matchingServices);    
    if (KERN_SUCCESS != kernResult)
    {
        goto exit;
    }
        
exit:
    return kernResult;
}

// Given an iterator across a set of modems, return the BSD path to the first one.
// If no modems are found the path name is set to an empty string.
static void GetModemPath(io_iterator_t serialPortIterator, char *bsdPath, CFIndex maxPathSize, char* key,CFIndex maxKeySize)
{
    io_object_t  modemService;
    CFTypeRef bsdPathAsCFString,keyAtCFString;
    
    // Initialize the returned path
    *bsdPath = '\0';
    
    // Iterate across all modems found. 
        
    modemService = IOIteratorNext(serialPortIterator);
    if (modemService == nil)
        return;
 
 // Get the callout device's path (/dev/cu.xxxxx). The callout device should almost always be
 // used: the dialin device (/dev/tty.xxxxx) would be used when monitoring a serial port for
 // incoming calls, e.g. a fax listener.
 
    bsdPathAsCFString = IORegistryEntryCreateCFProperty(modemService,
                                                            CFSTR(kIOCalloutDeviceKey),
                                                            kCFAllocatorDefault,
                                                            0);
    if (bsdPathAsCFString)  {
        Boolean result;
            
        // Convert the path from a CFString to a C (NUL-terminated) string for use
        // with the POSIX open() call.
     
        result = CFStringGetCString(bsdPathAsCFString,
                                        bsdPath,
                                        maxPathSize, 
                                        kCFStringEncodingUTF8);
        CFRelease(bsdPathAsCFString);
    }
    
        
    keyAtCFString = IORegistryEntryCreateCFProperty(modemService,
                                                            CFSTR(kIOTTYDeviceKey),
                                                            kCFAllocatorDefault,
                                                            0);
    if (keyAtCFString)  {
        Boolean result;
            
        // Convert the path from a CFString to a C (NUL-terminated) string for use
        // with the POSIX open() call.
     
        result = CFStringGetCString(keyAtCFString,
                                        key,
                                        maxKeySize, 
                                        kCFStringEncodingMacRoman);
        CFRelease(keyAtCFString);
        IOObjectRelease(modemService);
    }
    
    IOObjectRelease(modemService);
    return;
}
/* Description: This sample demonstrates how to use IOKitLib to find all serial ports on the system.
                
    Copyright:    Copyright 2000-2002 Apple Computer, Inc. All rights reserved.
 
    Disclaimer:  IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
                        ("Apple") in consideration of your agreement to the following terms, and your
                        use, installation, modification or redistribution of this Apple software
                        constitutes acceptance of these terms.  If you do not agree with these terms,
                        please do not use, install, modify or redistribute this Apple software.

                        In consideration of your agreement to abide by the following terms, and subject
                        to these terms, Apple grants you a personal, non-exclusive license, under Apple's
                        copyrights in this original Apple software (the "Apple Software"), to use,
                        reproduce, modify and redistribute the Apple Software, with or without
                        modifications, in source and/or binary forms; provided that if you redistribute
                        the Apple Software in its entirety and without modifications, you must retain
                        this notice and the following text and disclaimers in all such redistributions of
                        the Apple Software.  Neither the name, trademarks, service marks or logos of
                        Apple Computer, Inc. may be used to endorse or promote products derived from the
                        Apple Software without specific prior written permission from Apple.  Except as
                        expressly stated in this notice, no other rights or licenses, express or implied,
                        are granted by Apple herein, including but not limited to any patent rights that
                        may be infringed by your derivative works or by other works in which the Apple
                        Software may be incorporated.

                        The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
                        WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
                        WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
                        PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                        COMBINATION WITH YOUR PRODUCTS.

                        IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
                        CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
                        GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
                        ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                        OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
                        (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
                        ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. */
                        