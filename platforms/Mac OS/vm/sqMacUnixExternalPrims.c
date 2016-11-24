/* sqUnixExternalPrims.c -- Unix named primitives and loadable modules
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file was part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */

/* Author: Ian.Piumarta@INRIA.Fr
 *
 * Last edited: 2005-04-06 06:09:36 by piumarta on pauillac.hpl.hp.com
	
 * Altered by John M McIntosh johnmci@smalltalkconsulting.com Feb 24th, 2006 for os-x carbon support
 3.8.11b2 load from resource location first, avoid plugins external directory because of intel migration effort issues.
 3.8.17b1 April 25, 2007, JMM rework for 10.2.8 backwards support using Ian's dl* logic. 
 
 */
 
#include "sq.h"		/* sqUnixConfig.h */
#include "sqMacUIConstants.h"
#include "sqMacEncoding.h"
#include "sqMacUnixFileInterface.h"
extern int gSqueakDebug;

# define DPRINTF(ARGS) if (gSqueakDebug) fprintf ARGS
 
#if defined(HAVE_LIBDL)	/* non-starter without this! */

# include <dlfcn.h>
    void *dlopen(const char *filename, int flag) __attribute__((weak_import));
	char *dlerror(void) __attribute__((weak_import));
    void *dlsym(void *handle, const char *symbol) __attribute__((weak_import));
    int dlclose(void *handle) __attribute__((weak_import));
   static void *dlopenSqueak (const char *filename, int flag);
   static const char *dlerrorSqueak(void);
   static void *dlsymSqueak(void *handle, const char *symbol);
   static int dlcloseSqueak (void *handle);
 
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
 
#ifndef NAME_MAX
# ifdef MAXPATHLEN
#   define NAME_MAX MAXPATHLEN
# else
#   ifdef FILENAME_MAX
#     define NAME_MAX FILENAME_MAX
#   else
#     define NAME_MAX 256	/* nobody has fewer than this (since the PDP-8 ;) */
#   endif
# endif
#endif

#if !defined(HAVE_SNPRINTF)
# if defined(HAVE___SNPRINTF)	/* Solaris 2.5 */
    extern int __snprintf(char *buf, size_t limit, const char *fmt, ...);
#   define snprintf __snprintf
#   define HAVE_SNPRINTF
# endif
#endif


/*** options ***/

extern Boolean gSqueakPluginsBuiltInOrLocalOnly;

/*** configured variables ***/

extern char vmLibDir[];

/*** local functions ***/


/*  Attempt to load the shared library named by the concatenation of prefix,
 *  moduleName and suffix.  Answer the new module entry, or 0 if the shared
 *  library could not be loaded.
 */
static void *tryLoadingInternals(char *libName)
{	
  struct stat buf;
  int         err;
  void        *handle= 0;

	if ((!(err= stat(libName, &buf))) && S_ISDIR(buf.st_mode)) {
	  DPRINTF((stderr, "ignoring directory: %s\n", libName));
	}
	else
	  {
	    DPRINTF((stderr, "tryLoading %s\n", libName));
		if (dlopen == NULL)
			handle= dlopenSqueak(libName, RTLD_NOW | RTLD_GLOBAL);
		else
			handle= dlopen(libName, RTLD_NOW | RTLD_GLOBAL);
	    if (handle == 0)
	      {
			const char* why;
			if (dlerror == NULL)
				why = dlerrorSqueak();
			else
				why = dlerror();
			if ((!err) && (gSqueakDebug))
				fprintf(stderr, "ioLoadModule(%s):\n  %s\n", libName, why);
	      }
	    else
	      {
#if EXTERNALPRIMSDEBUG
			fprintf(stderr,"squeak: loaded plugin `%s'\n", libName);
#endif
		    return handle;
	      }
	  }
	return 0;
}

static void *tryLoading(char *dirName, char *moduleName)
{
  static char *prefixes[]= { "", "lib", 0 };
  static char *suffixes[]= { "", ".so", ".dylib",0 };
  void        *handle= 0;
  char	     **prefix= 0, **suffix= 0;
  char        libName[MAXPATHLEN + 32];	/* headroom for prefix/suffix */
  
  sprintf(libName, "%s%s%s%s", dirName, moduleName,".bundle/Contents/MacOS/", moduleName);
  handle = tryLoadingInternals(libName);
  if (handle) 
	 return handle;

  sprintf(libName, "%s%s", dirName, moduleName);
  handle = tryLoadingInternals(libName);
  if (handle) 
	 return handle;

  if (gSqueakPluginsBuiltInOrLocalOnly)
	return 0;
	
  for (prefix= prefixes;  *prefix;  ++prefix)
    for (suffix= suffixes;  *suffix;  ++suffix)
      {
		sprintf(libName, "%s%s%s%s", dirName, *prefix, moduleName, *suffix);
		handle = tryLoadingInternals(libName);
		if (handle) 
			return handle;
      }
  return 0;
}


static void *tryLoadingPath(char *varName, char *pluginName)
{
  char *path= getenv(varName);
  void *handle= 0;

  if (path)
    {
      char pbuf[MAXPATHLEN];
      DPRINTF((stderr, "try %s=%s\n", varName, path));
      strncpy(pbuf, path, sizeof(pbuf));
      pbuf[sizeof(pbuf) - 1]= '\0';
      for (path= strtok(pbuf, ":");
	   path != 0;
	   path= strtok(0, ":"))
	{
	  char buf[MAXPATHLEN];
	  sprintf(buf, "%s/", path);
	  DPRINTF((stderr, "  path dir = %s\n", buf));
	  if ((handle= tryLoading(buf, pluginName)) != 0)
	    break;
	}
    }
  return handle;
}


/*  Find and load the named module.  Answer 0 if not found (do NOT fail
 *  the primitive!).
 */
void *ioLoadModule(char *pluginName)
{
  void *handle= 0;
  char pluginDirPath[DOCUMENT_NAME_SIZE+1+8];
  static char vmDirPath[DOCUMENT_NAME_SIZE] = { 0 };

  if ((pluginName == 0) || (pluginName[0] == '\0'))
    {
      if (dlopen == NULL)
		handle= dlopenSqueak(0, RTLD_NOW | RTLD_GLOBAL);
	  else
		handle= dlopen(0, RTLD_NOW | RTLD_GLOBAL);
      if (handle == 0) {
		const char *why;
			if (dlerror == NULL)
				why = dlerrorSqueak();
			else
				why = dlerror();
		fprintf(stderr, "ioLoadModule(<intrinsic>): %s\n", why);
	  }
      else
	{
	  DPRINTF((stderr, "loaded: <intrinsic>\n"));
	  return handle;
	}
    }

	/* first, look in the "<Squeak VM directory>Plugins" directory for the library */
	getVMPathWithEncoding(pluginDirPath,kCFStringEncodingUTF8);
	
	strcat(pluginDirPath, "Plugins/");
	if (!vmDirPath[0]) {
            CFBundleRef mainBundle;
            CFURLRef	bundleURL,bundleURL2,resourceURL;
			CFStringRef filePath,resourcePathString;
			
            mainBundle = CFBundleGetMainBundle();   
			bundleURL = CFBundleCopyBundleURL(mainBundle);
			resourceURL = CFBundleCopyResourcesDirectoryURL(mainBundle);
			resourcePathString = CFURLCopyPath(resourceURL);
			CFRelease(resourceURL);

			bundleURL2 = CFURLCreateCopyAppendingPathComponent( kCFAllocatorSystemDefault, bundleURL, resourcePathString, false );
			CFRelease(bundleURL);
			filePath = CFURLCopyFileSystemPath (bundleURL2, kCFURLPOSIXPathStyle);
			CFRelease(bundleURL2);
            CFRelease(resourcePathString);
			
			CFStringGetCString (filePath,vmDirPath,DOCUMENT_NAME_SIZE, kCFStringEncodingUTF8);
			strcat(vmDirPath,"/");
			CFRelease(filePath);
			
 		}

    if (gSqueakPluginsBuiltInOrLocalOnly) {
	  if ( (handle= tryLoading( vmDirPath, pluginName))
		|| (handle= tryLoading( pluginDirPath,	pluginName))
		)
			return handle;
    } else {
		  if ((   handle= tryLoading( pluginDirPath,	pluginName))
			  || (handle= tryLoading( vmDirPath,		pluginName))
			  || (handle= tryLoadingPath("SQUEAK_PLUGIN_PATH",	pluginName))
		//JMM || (handle= tryLoadingPath("LD_LIBRARY_PATH",	pluginName))
			  || (handle= tryLoading(    "./",			pluginName))
			  || (handle= tryLoading(    "",			pluginName))
#    if defined(VM_X11DIR)
			  || (handle= tryLoading(VM_X11DIR"/",		pluginName))
#    endif
			  )
			return handle;
	}

#if defined(DARWIN)
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

	static char systemFolder[MAXPATHLEN+1]={0};
    char **framework= 0;
	char workingData[MAXPATHLEN+1];
	int pluginNameLength;
	char path[DOCUMENT_NAME_SIZE],path2[DOCUMENT_NAME_SIZE];
	
	if (!systemFolder[0]) {
		OSErr err;
		FSRef frameworksFolderRef;
		
		err = FSFindFolder(kSystemDomain, kFrameworksFolderType, false, &frameworksFolderRef);
		if (err) 
			strcpy(systemFolder,"/System/Library/Frameworks/");
		else {
			PathToFileViaFSRef(systemFolder,MAXPATHLEN,&frameworksFolderRef,kCFStringEncodingUTF8);     
		}
	}
	
	pluginNameLength = strlen(pluginName);
	if (pluginNameLength > 10) {
		strncpy(workingData,pluginName+pluginNameLength-10,10);
		workingData[10] = 0x00;
		if (strcmp(workingData,".framework") == 0) {
			strncpy(workingData,pluginName,pluginNameLength-10);
			workingData[pluginNameLength-10] = 0x00;
			sprintf(path, "%s%s/",vmDirPath,pluginName);
			if (gSqueakPluginsBuiltInOrLocalOnly) {
				sprintf(path2, "%s%s", path, workingData);
				if ((handle = tryLoadingInternals(path2)))
					return handle;
			} else {
				if ((handle= tryLoading(path, workingData)))
					return handle;
			}
			sprintf(path, "%s%s/",pluginDirPath,pluginName);
			if (gSqueakPluginsBuiltInOrLocalOnly) {
				sprintf(path2, "%s%s", path, workingData);
				if ((handle = tryLoadingInternals(path2)))
					return handle;
			} else {
				if ((handle= tryLoading(path, workingData)))
					return handle;
			}
			sprintf(path, "%s%s/",systemFolder,pluginName);
			if (gSqueakPluginsBuiltInOrLocalOnly) {
				sprintf(path2, "%s%s", path, workingData);
				if ((handle = tryLoadingInternals(path2)))
					return handle;
			} else {
				if ((handle= tryLoading(path, workingData)))
					return handle;
			}
		}
	}
	
 if (gSqueakPluginsBuiltInOrLocalOnly)
	return 0;
	
    for (framework= frameworks;  *framework;  ++framework)
      {
	sprintf(path, "%s%s/%s/", systemFolder,*framework, pluginName);
	if ((handle= tryLoading(path, pluginName)))
	  return handle;
	sprintf(path, "%s%s/%s.framework/", systemFolder,*framework, pluginName);
	if ((handle= tryLoading(path, pluginName)))
	  return handle;
      }
  }
#endif

  /* finally (for VM hackers) try the pre-install build location */
  {
    char pluginDir[DOCUMENT_NAME_SIZE];
	char vmPath[VMPATH_SIZE+1];
	getVMPathWithEncoding(vmPath,kCFStringEncodingUTF8);
#  ifdef HAVE_SNPRINTF
    snprintf(pluginDir, sizeof(pluginDir), "%s%s/.libs/", vmPath, pluginName);
#  else
    sprintf(pluginDir, "%s%s/.libs/", vmPath, pluginName);
#  endif
    if ((handle= tryLoading(pluginDir, pluginName)))
      return handle;
  }

#if EXTERNALPRIMSDEBUG
  fprintf(stderr, "squeak: could not load plugin `%s'\n", pluginName);
#endif 
  return 0;
}


/*  Find a function in a loaded module.  Answer 0 if not found (do NOT
 *  fail the primitive!).
 */
#if SPURVM
void *
ioFindExternalFunctionInAccessorDepthInto(char *lookupName, void *moduleHandle,
											sqInt *accessorDepthPtr)
#else
void *
ioFindExternalFunctionIn(char *lookupName, void *moduleHandle)
#endif
{
  char buf[256];
  void *fn;

#ifdef HAVE_SNPRINTF
  snprintf(buf, sizeof(buf), "%s", lookupName);
#else
  sprintf(buf, "%s", lookupName);
#endif

  fn = dlsym == NULL
	? dlsymSqueak(moduleHandle, buf)
	: dlsym(moduleHandle, buf);

  DPRINTF((stderr, "ioFindExternalFunctionIn(%s, %d)\n",
	   lookupName, (int) moduleHandle));

  if ((fn == 0) && (gSqueakDebug)
      && strcmp(lookupName, "initialiseModule")
      && strcmp(lookupName, "shutdownModule")
      && strcmp(lookupName, "setInterpreter")
      && strcmp(lookupName, "getModuleName")) {
      const char *why;
	  if (dlerror == NULL)
				why = dlerrorSqueak();
			else
				why = dlerror();
    fprintf(stderr, "ioFindExternalFunctionIn(%s, %p):\n  %s\n",
	    lookupName, moduleHandle, why);
  }
#if SPURVM
  if (fn && accessorDepthPtr) {
	signed char *accessorDepthVarPtr;

# ifdef HAVE_SNPRINTF
	snprintf(buf+strlen(buf), sizeof(buf), "AccessorDepth");
# else
	sprintf(buf+strlen(buf), "AccessorDepth");
# endif
	accessorDepthVarPtr = dlsym == NULL
							? dlsymSqueak(moduleHandle, buf)
							: dlsym(moduleHandle, buf);
	/* The Slang machinery assumes accessor depth defaults to -1, which
	 * means "no accessor depth".  It saves space not outputting -1 depths.
	 */
	*accessorDepthPtr = accessorDepthVarPtr
							? *accessorDepthVarPtr
							: -1;
  }
#endif /* SPURVM */

  return fn;
}



/*  Free the module with the associated handle.  Answer 0 on error (do
 *  NOT fail the primitive!).
*/
sqInt ioFreeModule(void *moduleHandle)
{
  int results;
  if (dlclose == NULL)
	results = dlcloseSqueak(moduleHandle);
  else
	results = dlclose(moduleHandle);
	
  if (results)
    {
	const char* why;
	if (dlerror == NULL)
		why = dlerrorSqueak();
	else
		why = dlerror();
      DPRINTF((stderr, "ioFreeModule(%d): %s\n", (int) moduleHandle, why));
      return 0;
    }
  return 1;
}


#else /* !HAVE_LIBDL */



void *ioLoadModule(char *pluginName)
{
  return 0;
}

void *ioFindExternalFunctionIn(char *lookupName, void *moduleHandle)
{
  return 0;
}

sqInt ioFreeModule(void *moduleHandle)
{
  return 0;
}


#endif /* !HAVE_LIBDL */

/* dlfcn-dyld.c -- provides dlopen() and friends as wrappers around Mach dyld
 * 
 * Author: Ian.Piumarta@INRIA.Fr
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *      You are NOT ALLOWED to distribute modified versions of this file
 *      under its original name.  If you modify this file then you MUST
 *      rename it before making your modifications available publicly.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following additional restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. You must not distribute (or make publicly available by any
 *      means) a modified copy of this file unless you first rename it.
 * 
 *   3. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 * 
 * Last edited: 2004-04-03 11:33:44 by piumarta on emilia.local
 */

#include <stdio.h>
#include <stdarg.h>
#include <mach-o/dyld.h>

#define RTLD_NOW	0
#define RTLD_GLOBAL	0

#define	DL_APP_CONTEXT	((void *)-1)


static char dlErrorString[256];
static int  dlErrorSet= 0;


static void dlSetError(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(dlErrorString, sizeof(dlErrorString), fmt, ap);
  va_end(ap);
  dlErrorSet= 1;
}


static const char *dlerrorSqueak(void)
{
  if (dlErrorSet)
    {
      dlErrorSet= 0;
      return (const char *)dlErrorString;
    }
  return 0;
}


static void dlUndefined(const char *symbol)
{
  fprintf(stderr, "dyld: undefined symbol: %s\n", symbol);
}

static NSModule dlMultiple(NSSymbol s, NSModule oldModule, NSModule newModule)
{
  DPRINTF((stderr, "dyld: %s: %s previously defined in %s\n",
	   NSNameOfSymbol(s), NSNameOfModule(oldModule), NSNameOfModule(newModule)));
  return newModule;
}

static void dlLinkEdit(NSLinkEditErrors errorClass, int errorNumber,
		       const char *fileName, const char *errorString)

{
#pragma unused(errorClass,errorNumber,mode)
  fprintf(stderr, "dyld: %s: %s\n", fileName, errorString);
}

static NSLinkEditErrorHandlers errorHandlers=
  {
    dlUndefined,
    dlMultiple,
    dlLinkEdit
  };

static void dlinit(void)
{
  NSInstallLinkEditErrorHandlers(&errorHandlers);
}

static int dlInitialised= 0;


static void *dlopenSqueak(const char *path, int mode)
{
#pragma unused(mode)
  void			*handle= 0;
  NSObjectFileImage	 ofi= 0;

  if (!dlInitialised)
    {
      dlinit();
      dlInitialised= 1;
    }

  if (!path)
    return DL_APP_CONTEXT;

  switch (NSCreateObjectFileImageFromFile(path, &ofi))
    {
    case NSObjectFileImageSuccess:
      handle= NSLinkModule(ofi, path, NSLINKMODULE_OPTION_RETURN_ON_ERROR);
      NSDestroyObjectFileImage(ofi);
      break;
    case NSObjectFileImageInappropriateFile:
      handle= (void *)NSAddImage(path, NSADDIMAGE_OPTION_RETURN_ON_ERROR);
      break;
    default:
      handle= 0;
      break;
    }

  if (!handle)
    dlSetError("could not load shared object: %s", path);

  DPRINTF((stderr, "dlopen: %s => %d\n", path, (int)handle));

  return handle;
}


static void *dlsymSqueak(void *handle, const char *symbol)
{
  char		_symbol[256];
  NSSymbol	nsSymbol= 0;

  snprintf(_symbol, sizeof(_symbol), "_%s", symbol);

  DPRINTF((stderr, "dlsym: looking for %s (%s) in %d\n", symbol, _symbol, (int)handle));

  if (!handle)
    {
      DPRINTF((stderr, "dlsym: setting app context for this handle\n"));
      handle= DL_APP_CONTEXT;
    }

  if (DL_APP_CONTEXT == handle)
    {
      DPRINTF((stderr, "dlsym: looking in app context\n"));
      if (NSIsSymbolNameDefined(_symbol))
	nsSymbol= NSLookupAndBindSymbol(_symbol);
    }
  else
    {
      if ((  (MH_MAGIC == ((struct mach_header *)handle)->magic))	/* ppc */
	  || (MH_CIGAM == ((struct mach_header *)handle)->magic))	/* 386 */
	{
	  if (NSIsSymbolNameDefinedInImage((struct mach_header *)handle, _symbol))
	    {
	      nsSymbol= NSLookupSymbolInImage
		((struct mach_header *)handle,
		 _symbol,
		 NSLOOKUPSYMBOLINIMAGE_OPTION_BIND
		 /*| NSLOOKUPSYMBOLINIMAGE_OPTION_RETURN_ON_ERROR*/);
	      DPRINTF((stderr, "dlsym: bundle (image) lookup returned %p\n", nsSymbol));
	    }
	  else
	    DPRINTF((stderr, "dlsym: bundle (image) symbol not defined\n"));
	}
      else
	{
	  nsSymbol= NSLookupSymbolInModule(handle, _symbol);
	  DPRINTF((stderr, "dlsym: dylib (module) lookup returned %p\n", nsSymbol));
	}
    }

  if (!nsSymbol)
    {
      dlSetError("symbol not found: %s", _symbol);
      return 0;
    }

  return NSAddressOfSymbol(nsSymbol);
}


int dlcloseSqueak(void *handle)
{
  if ((  (MH_MAGIC == ((struct mach_header *)handle)->magic))	/* ppc */
      || (MH_CIGAM == ((struct mach_header *)handle)->magic))	/* 386 */
    return 0;	/* can't unlink, but pretend we did */

  if (!NSUnLinkModule(handle, 0))
    {
      dlSetError("could not unlink shared object: %s", NSNameOfModule(handle));
      return -1;
    }

  return 0;
}



#ifndef HAVE_LIBDL
# define HAVE_LIBDL
#endif  
