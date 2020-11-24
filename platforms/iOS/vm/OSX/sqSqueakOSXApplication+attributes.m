//
//  sqSqueakOSXApplication+attributes.m
//  SqueakPureObjc
//
//  Created by John M McIntosh on 09-11-11.
/*
 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.

 The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
 "This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
 and its contributors", in the same place and form as other third-party acknowledgments. 
 Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
 such third-party acknowledgments.
 */
//

#import "sqSqueakOSXApplication+attributes.h"
#import "sqSqueakMainApplication+attributes.h"
#import "sqSqueakMainApplication+vmAndImagePath.h"

#import <Foundation/NSProcessInfo.h>

extern struct VirtualMachine* interpreterProxy;

#if __MAC_OS_X_VERSION_MAX_ALLOWED <= 1090
typedef struct {
    NSInteger majorVersion;
    NSInteger minorVersion;
    NSInteger patchVersion;
} NSOperatingSystemVersion;
#endif

@implementation sqSqueakOSXApplication (attributes)

- (char *) getAttribute:(sqInt)indexNumber {
	//indexNumber is a positive/negative number

	switch (indexNumber) {
	case 1001: /* OS type: "unix", "win32", "mac", ... */
		return "Mac OS"; // Should be "Mac OS X", sigh...

	case 1002:  { /* OS name: "solaris2.5" on unix, "win95" on win32, ... */
        static char data[32] = { 0 };
        NSOperatingSystemVersion version = [self getOperatingSystemVersion];
        sprintf(data,"%ld%02ld.%ld",
                (long)version.majorVersion,
                (long)version.minorVersion,
                (long)version.patchVersion);
		return data;
	}
	case 1003: { /* processor architecture: "68k", "x86", "PowerPC", ...  */
#if __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101000
# if __ppc__
		return "powerpc";
# elif __x86_64__
		return "x64";
# elif __i386__
		return "intel";
# elif __arm64__
		return "aarch64";
# else
		return "unknown";
# endif
#else
		SInt32 myattr;

		Gestalt(gestaltSysArchitecture, &myattr);
# if 0
		if (myattr == gestalt68k) 
			return "68K";
# elif __ppc__
		if (myattr == gestaltPowerPC) 
			return "powerpc";
# elif __x86_64__
		if (myattr == gestaltIntel) 
			return "x64";
# elif __i386__
		if (myattr == gestaltIntel) 
			return "intel";
# elif __arm64__
		if (myattr == gestaltArm) 
			return "aarch64";
# endif
		return "unknown";
#endif
	}

#if 0 /* see iOS/vm/Common/Classes/sqSqueakMainApplication+attributes.m */
   if (id == 1004) {
		CFBundleRef mainBundle;
		CFStringRef versionString;
		static char data[255];
		mainBundle = CFBundleGetMainBundle ();
		versionString = CFBundleGetValueForInfoDictionaryKey(mainBundle, CFSTR("CFBundleShortVersionString"));
		bzero(data,255);
		strcat(data,interpreterVersion);
		if (versionString) {
			strcat(data," ");
			CFStringGetCString (versionString, data+strlen(data), 255-strlen(data), gCurrentVMEncoding);
		}
		return data;            
	}
#endif

	case 1005:
		return "Aqua";

	case 1006:  {/* vm build string also info.plist */
		extern char vmBuildString[];
		return vmBuildString;
	}
	case 1007: { /* vm build string also info.plist */
#if STACKVM
		extern char *__interpBuildInfo;
		return __interpBuildInfo;
#endif
		break;
	}
	case 1008: { /* vm build string also info.plist */
# if COGVM
		extern char *__cogitBuildInfo;
		return __cogitBuildInfo;
#endif
		break;
	}
	default: 
		break;
	}
	return (char *) [super getAttribute: indexNumber];
}

- (NSOperatingSystemVersion) getOperatingSystemVersion
{
    static NSOperatingSystemVersion osv = { 0 };
    if (osv.majorVersion != 0) // fast cached path
        return osv;

#if __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101000
	osv = [self getNSOperatingSystemVersion];
#else
    // This is officially true since 10.10 but unofficially since 10.9, hence the invocation
    if ([[NSProcessInfo processInfo] respondsToSelector: @selector(operatingSystemVersion)]) {
        osv = [self getNSOperatingSystemVersion];
    }
	else {
        SInt32 versionMajor=0, versionMinor=0, versionBugFix=0;
        Gestalt(gestaltSystemVersionMajor, &versionMajor);
        Gestalt(gestaltSystemVersionMinor, &versionMinor);
        Gestalt(gestaltSystemVersionBugFix, &versionBugFix);
        osv.majorVersion = versionMajor;
        osv.minorVersion = versionMinor;
        osv.patchVersion = versionBugFix;
    }
#endif /* __ENVIRONMENT_MAC_OS_X_VERSION_MIN_REQUIRED__ >= 101000 */
    return osv;
}

- (NSOperatingSystemVersion) getNSOperatingSystemVersion
{
    static NSOperatingSystemVersion osv = { 0 };
    SEL _osv = @selector(operatingSystemVersion);

    NSMethodSignature* osvSignature = [NSProcessInfo instanceMethodSignatureForSelector: _osv];
    NSInvocation* osvInvocation = [NSInvocation invocationWithMethodSignature: osvSignature];
    [osvInvocation setTarget: [NSProcessInfo processInfo]];
    [osvInvocation setSelector: _osv];
    [osvInvocation invoke];
    [osvInvocation getReturnValue: &osv];
    return osv;
}

@end
