
//  Created by John M McIntosh on 09-11-27.
//  This file orginally comes from the sqUnixExternalPrims.c written by Ian Piumarta
//  With additional work for the 3.x and 4.x series of macintosh carbon vms
//  To preserve the behavior, bugs, etc I decided to copy the code versus a new re-write

/* sqUnixExternalPrims.c -- Unix named primitives and loadable modules
 * 
 *   Copyright (C) 1996-2009 by Ian Piumarta
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

 /* Author: Ian.Piumarta@INRIA.Fr
 *
 * Last edited: 2005-04-06 06:09:36 by piumarta on pauillac.hpl.hp.com
	
 * Altered by John M McIntosh johnmci@smalltalkconsulting.com Feb 24th, 2006 for os-x carbon support
 3.8.11b2 load from resource location first, avoid plugins external directory because of intel migration effort issues.
 3.8.17b1 April 25, 2007, JMM rework for 10.2.8 backwards support using Ian's dl* logic. 
 5.0.0b6  Nov 27, 2009, JMM rework for the 32/64bit 5.0 VM
  
 */
#import "sqSqueakOSXInfoPlistInterface.h"
#import "SqueakOSXAppDelegate.h"
#import "sq.h"

extern SqueakOSXAppDelegate *gDelegateApp;

# define dprintf(ARGS) if (((sqSqueakOSXInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic).SqueakDebug) fprintf ARGS
 
#if defined(HAVE_LIBDL)	/* non-starter without this! */

#include <dlfcn.h> 
#include <sys/param.h>
#include <sys/stat.h>

/* get a value for RTLD_NOW, with increasing levels of desperation... */

#if !defined(RTLD_NOW)
# if defined(DL_NOW)
#   define RTLD_NOW DL_NOW
# elif defined(RTLD_LAZY)
#   define RTLD_NOW RTLD_LAZY
# elif defined(DL_LAZY)
#   define RTLD_NOW DL_LAZY
# else
#   warning: defining RTLD_NOW as 1
#   define RTLD_NOW 1
# endif
#endif

#if !defined(RTLD_GLOBAL)
# define RTLD_GLOBAL 0
#endif

#endif


/*** local functions ***/
void *ioLoadModuleRaw(char *pluginName);

/*  Attempt to load the shared library named by the concatenation of prefix,
 *  moduleName and suffix.  Answer the new module entry, or 0 if the shared
 *  library could not be loaded.
 */
static void *tryLoadingInternals(NSString *libNameString) {	
	struct stat buf;
	int         err;
	void        *handle = NULL;
	const char* libName = [libNameString fileSystemRepresentation];
	
	if ((!(err= stat(libName, &buf))) && S_ISDIR(buf.st_mode)) {
		dprintf((stderr, "ignoring directory: %s\n", libName));
	} else {
	    dprintf((stderr, "tryLoading %s\n", libName));
		handle= dlopen(libName, RTLD_NOW | RTLD_GLOBAL);
	    if (handle == NULL) {
			const char* why = dlerror();
			if ((!err) && (((sqSqueakOSXInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic).SqueakDebug))
				fprintf(stderr, "ioLoadModule(%s):\n  %s\n", libName, why);
		} else {
		    return handle;
		}
	}
	return NULL;
}

static void *tryLoading(NSString *dirNameString, char *moduleName)
{
	void        *handle= NULL;
	NSString    *libName;
	
	libName = [dirNameString stringByAppendingPathComponent: @(moduleName)];
	libName = [libName stringByAppendingPathExtension: @"bundle/Contents/MacOS/"];
	libName = [libName stringByAppendingPathComponent: @(moduleName)];
	handle = tryLoadingInternals(libName);
	if (handle) 
		return handle;
	
	libName = [dirNameString stringByAppendingPathComponent: @(moduleName)];
	handle = tryLoadingInternals(libName);
	if (handle) 
		return handle;
	
	if (((sqSqueakOSXInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic).SqueakPluginsBuiltInOrLocalOnly)
		return NULL;
	
	static char *prefixes[]= { "", "lib", 0 };
	static char *suffixes[]= { "", "so", "dylib",0 };
	char	     **prefix= NULL, **suffix= NULL;

	for (prefix= prefixes;  *prefix;  ++prefix)
		for (suffix= suffixes;  *suffix;  ++suffix)		{
			libName = [dirNameString stringByAppendingPathComponent: @(*prefix)];
			libName = [libName stringByAppendingString: @(moduleName)];
			libName = [libName stringByAppendingPathExtension: @(*suffix)];

			handle = tryLoadingInternals(libName);
			if (handle) 
				return handle;
		}
	return NULL;
}


/*  Find and load the named module.  Answer 0 if not found (do NOT fail
 *  the primitive!).
 */
void *ioLoadModule(char *pluginName) {
	@autoreleasepool {
		void* result = ioLoadModuleRaw(pluginName);
		return result;
	}
}
	
void *ioLoadModuleRaw(char *pluginName)
{
	void *handle= null;

	if ((pluginName == null) || (pluginName[0] == 0x00)) {
		handle = dlopen(0, RTLD_NOW | RTLD_GLOBAL);
		if (handle == null) {
			char * why = dlerror();
			dprintf((stderr, "ioLoadModule(<intrinsic>): %s\n", why));
		} else {
			dprintf((stderr, "loaded: <intrinsic>\n"));
			return handle;
		}
    }
	
	/* first, look in the "<Squeak VM directory>Plugins" directory for the library */
	NSString *pluginDirPath = [[gDelegateApp.squeakApplication.vmPathStringURL path] stringByAppendingPathComponent: @"Plugins/"];
	NSString *vmDirPath = [[NSBundle mainBundle] resourcePath];

	if (((sqSqueakOSXInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic).SqueakPluginsBuiltInOrLocalOnly) {
	  if ( (handle= tryLoading( vmDirPath, pluginName)) || (handle= tryLoading( pluginDirPath,	pluginName)))
			return handle;
    } else {
		  if ((   handle= tryLoading( pluginDirPath,	pluginName))
			  || (handle= tryLoading( @"./",			pluginName))
			  || (handle= tryLoading( vmDirPath,		pluginName))
			  || (handle= tryLoading( @"",				pluginName))
			  )
			return handle;
	}

	// the following is needed so that, for example, the FFI can pick up
	// things like <cdecl: 'xyz' module: 'CoreServices'>
	{
		static char *frameworks[]=
		{
			"",
			"/CoreServices.framework/Frameworks",
			"/ApplicationServices.framework/Frameworks",
			"/Carbon.framework/Frameworks",
			0
		};
		
		static NSString *systemFolder = NULL;
		char **framework= NULL;
		char workingData[PATH_MAX+1];
		size_t pluginNameLength;
		NSString *path,*path2;
		
		if (!systemFolder) {
			struct FSRef frameworksFolderRef;
			OSErr err = FSFindFolder(kSystemDomain, kFrameworksFolderType, false, &frameworksFolderRef);
#pragma unused(err)
			NSURL *myURLRef = (NSURL *) CFBridgingRelease(CFURLCreateFromFSRef(kCFAllocatorDefault, &frameworksFolderRef));
			systemFolder = [myURLRef path];
		}
		
		pluginNameLength = strlen(pluginName);
		if (pluginNameLength > 10) {
			strncpy(workingData,pluginName+pluginNameLength-10,10);
			workingData[10] = 0x00;
			if (strcmp(workingData,".framework") == 0) {
				strncpy(workingData,pluginName,pluginNameLength-10);
				workingData[pluginNameLength-10] = 0x00;
				path = [vmDirPath stringByAppendingPathComponent: @(pluginName)];
				if (((sqSqueakOSXInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic).SqueakPluginsBuiltInOrLocalOnly) {
					path2 = [path stringByAppendingPathComponent: @(workingData)];
					if ((handle = tryLoadingInternals(path2)))
						return handle;
				} else {
					if ((handle= tryLoading(path, workingData)))
						return handle;
				}
				path = [pluginDirPath stringByAppendingPathComponent: @(pluginName)];

				if (((sqSqueakOSXInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic).SqueakPluginsBuiltInOrLocalOnly) {
					path2 = [path stringByAppendingPathComponent: @(workingData)];
					if ((handle = tryLoadingInternals(path2)))
						return handle;
				} else {
					if ((handle= tryLoading(path, workingData)))
						return handle;
				}

				path = [systemFolder stringByAppendingPathComponent: @(pluginName)];
				if (((sqSqueakOSXInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic).SqueakPluginsBuiltInOrLocalOnly) {
					path2 = [path stringByAppendingPathComponent: @(workingData)];
					if ((handle = tryLoadingInternals(path2)))
						return handle;
				} else {
					if ((handle= tryLoading(path, workingData)))
						return handle;
				}
			}
		}
		
		if (((sqSqueakOSXInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic).SqueakPluginsBuiltInOrLocalOnly)
			return NULL;
		
		for (framework= frameworks;  *framework;  ++framework) {
			path = [[systemFolder stringByAppendingPathComponent: @(*framework)]
					stringByAppendingPathComponent: @(pluginName)];
			if ((handle= tryLoading(path, pluginName)))
				return handle;
			
			path = [systemFolder stringByAppendingPathComponent: @(*framework)];
			path = [path stringByAppendingPathComponent: @(pluginName)];
			path = [path stringByAppendingPathExtension: @"framework"];
			
			if ((handle= tryLoading(path, pluginName)))
				return handle;
		}
	}
	
	return NULL;
}


/*  Find a function in a loaded module.  Answer 0 if not found (do NOT
 *  fail the primitive!).
 */
void *ioFindExternalFunctionIn(char *lookupName, void *moduleHandle)
{
  char buf[NAME_MAX+1];
 
  snprintf(buf, sizeof(buf), "%s", lookupName);
  void *fn = dlsym(moduleHandle, buf);

  dprintf((stderr, "ioFindExternalFunctionIn(%s, %ld)\n",lookupName, (long) moduleHandle));

  if ((fn == NULL) && (((sqSqueakOSXInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic).SqueakDebug)
      && strcmp(lookupName, "initialiseModule")
      && strcmp(lookupName, "shutdownModule")
      && strcmp(lookupName, "setInterpreter")
      && strcmp(lookupName, "getModuleName")) {
	char *why = dlerror();
    fprintf(stderr, "ioFindExternalFunctionIn(%s, %p):\n  %s\n",lookupName, moduleHandle, why);
	}

  return fn;
}

/*  Free the module with the associated handle.  Answer 0 on error (do
 *  NOT fail the primitive!).
*/
sqInt ioFreeModule(void *moduleHandle)
{
  int results = dlclose(moduleHandle);
	
  if (results) {
	  char* why = dlerror();
      dprintf((stderr, "ioFreeModule(%ld): %s\n", (long) moduleHandle, why));
      return 0;
    }
  return 1;
}