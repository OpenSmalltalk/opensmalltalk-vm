
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
#import "SqueakNoOGLIPhoneAppDelegate.h"
#import "sq.h"

extern SqueakNoOGLIPhoneAppDelegate *gDelegateApp;

#if DEBUGVM
#  define dprintf(ARGS) fprintf ARGS
#else
#  define dprintf(ARGS)
#endif
 
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
		handle = dlopen(libName, RTLD_NOW /* | RTLD_GLOBAL */);
	    if (handle == NULL) {
			const char* why = dlerror();
			if ((!err) /* && (((sqSqueakOSXInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic).SqueakDebug) */)
				fprintf(stderr, "ioLoadModule(%s):\n  %s\n", libName, why);
		} else {
		    return handle;
		}
	}
	return NULL;
}

static void *tryLoading(NSString *dirNameString, char *moduleName) {
	void        *handle= NULL;
	NSString    *libName;
	
	libName = [dirNameString stringByAppendingPathComponent: [NSString stringWithFormat: @"lib%s.dylib", moduleName]];
	handle = tryLoadingInternals(libName);
    return handle;
}


/*  Find and load the named module.  Answer 0 if not found (do NOT fail
 *  the primitive!).
 */
void *ioLoadModule(char *pluginName) {
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
	void* result = ioLoadModuleRaw(pluginName);
	[pool drain];	return result;
}
	
void *ioLoadModuleRaw(char *pluginName) {
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
	
    //Plugins in iOS can be just in same directory as executable (which is same as resource... :)
	NSString *vmDirPath = [[NSBundle mainBundle] resourcePath];

    handle = tryLoading(vmDirPath, pluginName);

    return handle;
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

  if ((fn == NULL) /* && (((sqSqueakOSXInfoPlistInterface*) gDelegateApp.squeakApplication.infoPlistInterfaceLogic).SqueakDebug ) */
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
