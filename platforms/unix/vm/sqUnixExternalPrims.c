/* sqUnixExternalPrims.c -- Unix named primitives and loadable modules
 * 
 *   Copyright (C) 1996-2004 by Ian Piumarta and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
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
 */

/* If one really wants debugging output use e.g. -DDEBUG=2 */
#if DEBUG <= 1
# undef DEBUG
# define DEBUG 0
#endif
 
#include "sq.h"		/* sqUnixConfig.h */
#include "sqAssert.h"
#include "sqUnixMain.h"

#if (DEBUG)
# define DPRINTF(ARGS) fprintf ARGS
#else
# define DPRINTF(ARGS)
#endif
 
#if !defined(HAVE_LIBDL) && defined(HAVE_DYLD)
# include "dlfcn-dyld.c"
#endif

#if defined(HAVE_LIBDL)	/* non-starter without this! */

#ifdef HAVE_DLFCN_H
# include <dlfcn.h>
#else
  extern void *dlopen (const char *filename, int flag);
  extern const char *dlerror(void);
  extern void *dlsym(void *handle, const char *symbol);
  extern int dlclose (void *handle);
#endif
 
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

#if (DEBUG)
# define sqIgnorePluginErrors 0
#else
  extern int sqIgnorePluginErrors;
#endif

/*** options ***/

extern char *squeakPlugins; /* defaults to vmPath */

/*** variables determined at startup ***/

extern char vmPath[];

/*** local functions ***/


#define USE_SIMPLIFIED_PLUGIN_LOGIC 0
#if USE_SIMPLIFIED_PLUGIN_LOGIC

#if !defined(MODULE_PREFIX)
/* These are defined by the cmake configuration and I'm not about to go there.
 * eliot Wed Jan 20
 */
# if __linux__
# define MODULE_PREFIX ""
# define MODULE_SUFFIX ""
# define LIBRARY_PREFIX "lib"
# define LIBRARY_SUFFIX ".so"
# endif
#endif


static void *
tryLoadModule(char *in, char *name)
{
  char path[PATH_MAX], *out= path;
  void *handle= 0;
  int c;
  DPRINTF((stderr, __FILE__ " %d tryLoadModule(%s,%s)\n", __LINE__, in, name));
  while ((c= *in++) && ':' != c) {	/* copy next plugin path to path[] */
    switch (c) {
    case '%':
      if ('n' == *in || 'N' == *in) {	/* replace %n with name of plugin */
	++in;
	strcpy(out, name);
	out += strlen(name);
	continue;
      }
      if ('%' == *in) {
	++in;
	*out++= '%';
	continue;
      }
      /* fall through... */
    default:
      *out++= c;
      continue;
    }
  }
  snprintf(out, sizeof(path) - (out - path),
    "/" MODULE_PREFIX "%s" MODULE_SUFFIX, name);
  handle= dlopen(path, RTLD_NOW | RTLD_GLOBAL);
  DPRINTF((stderr, __FILE__ " %d tryLoading dlopen(%s) = %p\n", __LINE__, path, handle));
  if (!handle) {
    struct stat buf;
    if ((0 == stat(path, &buf)) && ! S_ISDIR(buf.st_mode))
      fprintf(stderr, "%s\n", dlerror());
  }
  return handle;
}


void *ioLoadModule(char *pluginName)
{
  char  path[PATH_MAX];
  char *dir= squeakPlugins;
  void *handle= 0;

  DPRINTF((stderr, __FILE__ " %d ioLoadModule(%s)\n", __LINE__, pluginName));
  if ((0 == pluginName) || ('\0' == pluginName[0])) {	/* find module in main program */
    handle= dlopen(0, RTLD_NOW | RTLD_GLOBAL);
    if (handle == 0) {
      fprintf(stderr, __FILE__ " %d ioLoadModule dlopen(<intrinsic>): %s\n", __LINE__, dlerror());
    }
    else {
      DPRINTF((stderr, __FILE__ " %d ioLoadModule loaded: <intrinsic>\n", __LINE__));
    }
    return handle;
  }

  /* try loading {pluginPaths}/MODULE_PREFIX<name>MODULE_SUFFIX */

  while (*dir) {
    if ((handle= tryLoadModule(dir, pluginName)))
      return handle;
    while (*dir && ':' != *dir++)
      ;
  }

  /* try dlopen()ing LIBRARY_PREFIX<name>LIBRARY_SUFFIX searching only the default locations modulo LD_LIBRARY_PATH et al */

  snprintf(path, sizeof(path), "%s%s%s", LIBRARY_PREFIX, pluginName, LIBRARY_SUFFIX);

  handle= dlopen(path, RTLD_NOW | RTLD_GLOBAL);
  DPRINTF((stderr, __FILE__ " %d ioLoadModule dlopen(%s) = %p%s\n", __LINE__, path, handle, handle ? "" : dlerror()));

  return handle;
}


#else /* USE_SIMPLIFIED_PLUGIN_LOGIC */

/*  Attempt to load the shared library named by the concatenation of prefix,
 *  moduleName and suffix.  Answer the new module entry, or 0 if the shared
 *  library could not be loaded. Try all combinations of prefixes and suffixes,
 *	including no prefix or suffix.
 */
static void *
tryLoading(char *dirName, char *moduleName)
{
  static char *prefixes[]= { "", "lib", 0 };
  static char *suffixes[]= { "", ".so", ".dylib", 0 };
  void        *handle= 0;
  char	     **prefix= 0, **suffix= 0;

  DPRINTF((stderr, __FILE__ " %d tryLoadModule(%s,%s)\n", __LINE__, dirName, moduleName));
  for (prefix= prefixes;  *prefix;  ++prefix)
	for (suffix= suffixes;  *suffix;  ++suffix) {
		char        libName[NAME_MAX + 32];	/* headroom for prefix/suffix */
		struct stat buf;
		int         n;
		n = snprintf(libName, sizeof(libName), "%s%s%s%s",dirName,*prefix,moduleName,*suffix);
		assert(n >= 0 && n < NAME_MAX + 32);
		if (!stat(libName, &buf)) {
			if (S_ISDIR(buf.st_mode))
				DPRINTF((stderr, __FILE__ " %d ignoring directory: %s\n", __LINE__, libName));
			else {
				handle= dlopen(libName, RTLD_NOW | RTLD_GLOBAL);
				DPRINTF((stderr, __FILE__ " %d tryLoading dlopen(%s) = %p\n", __LINE__, libName, handle));
				if (handle == 0) {
					if (!sqIgnorePluginErrors)
						fprintf(stderr, "ioLoadModule(%s):\n  %s\n", libName, dlerror());
				}
				else {
# if DEBUG
					printf("%s: loaded plugin `%s'\n", exeName, libName);
# endif
					return handle;
				}
			}
		}
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
	  snprintf(buf, sizeof(buf), "%s/", path);
	  DPRINTF((stderr, "  path dir = %s\n", buf));
	  if ((handle= tryLoading(buf, pluginName)) != 0)
	    break;
	}
    }
  return handle;
}

#ifdef PharoVM
static void *tryLoadingLinked(char *libName)
{
  void *handle= dlopen(libName, RTLD_NOW | RTLD_GLOBAL);
  DPRINTF((stderr, __FILE__ " %d tryLoadingLinked dlopen(%s) = %p\n", __LINE__, libName, handle));
# if DEBUG
  if(handle != 0) 
	printf("%s: loaded plugin `%s'\n", exeName, libName);
# endif
  return handle;
}
#else
# define tryLoadingLinked(libName) 0
#endif


/*  Find and load the named module.  Answer 0 if not found (do NOT fail
 *  the primitive!).
 */
void *
ioLoadModule(char *pluginName)
{
	void *handle= 0;

	if (!pluginName || !*pluginName) {
		if (!(handle= dlopen(0, RTLD_NOW | RTLD_GLOBAL))) {
			fprintf(stderr, __FILE__ " %d ioLoadModule(<intrinsic>): %s\n", __LINE__, dlerror());
			return 0;
		}
		DPRINTF((stderr, __FILE__ " %d ioLoadModule loaded: <intrinsic>\n", __LINE__));
		return handle;
	}

	if (squeakPlugins) {
		char path[NAME_MAX];
		char c, *in= squeakPlugins, *out= path;
		while ((c= *in++)) {
			if (c == '%' && ((*in == 'n') || (*in == 'N'))) {
				++in;
				strcpy(out, pluginName);
				out+= strlen(pluginName);
			}
			else
				*out++= c;
		}
		*out= '\0';
		DPRINTF((stderr, "%s %d ioLoadModule plugins = %s path = %s\n",
				__FILE__, __LINE__, squeakPlugins, path));
		if ((handle= tryLoading("", path)))
			return handle;
		if (!(out > path && *(out - 1) == '/')) {
			*out++= '/';
			*out= '\0';
		}
		if ((handle= tryLoading(path, pluginName)))
			return handle;
	}

    if (   (handle= tryLoadingLinked(				pluginName)) 	// Try linked/referenced libs (Pharo only)
        || (handle= tryLoading(    "./",			pluginName))	// Try local dir
        || (handle= tryLoadingPath("SQUEAK_PLUGIN_PATH", 	pluginName))	// Try squeak path
        || (handle= tryLoadingPath("LD_LIBRARY_PATH",		pluginName)) 	// Try library path
        || (handle= tryLoading(    "",				pluginName))	// Try no path
  #    if defined(VM_X11DIR)
        || (handle= tryLoading(VM_X11DIR"/",			pluginName))	// Try X11 path
  #    endif
        )
    return handle;

#if defined(DARWIN)
  // look in the bundle contents dir
  {
    static char *contents= 0;
    if (!contents)
      {
	char *delim;
	contents= strdup(vmPath);
	if ((delim= strrchr(contents, '/')))
	  delim[1]= '\0';
      }
    if ((handle= tryLoading(contents, pluginName)))
      return handle;
  }
  // the following is needed so that, for example, the FFI can pick up
  // things like <cdecl: 'xyz' module: 'CoreServices'>
  {
    static char *frameworks[]=
      {
	"/System/Library/Frameworks",
	"/System/Library/Frameworks/CoreServices.framework/Frameworks",
	"/System/Library/Frameworks/ApplicationServices.framework/Frameworks",
	"/System/Library/Frameworks/Carbon.framework/Frameworks",
	0
      };
    char **framework= 0;
    for (framework= frameworks;  *framework;  ++framework)
      {
	char path[NAME_MAX];
	snprintf(path, sizeof(path), "%s/%s.framework/", *framework, pluginName);
	if ((handle= tryLoading(path, pluginName)))
	  return handle;
      }
  }
#endif /* DARWIN */

  /* finally (for VM hackers) try the pre-install build location */
  {
    char pluginDir[MAXPATHLEN];
    snprintf(pluginDir, sizeof(pluginDir), "%s%s/.libs/", vmPath, pluginName);
    if ((handle= tryLoading(pluginDir, pluginName)))
      return handle;
  }

#if DEBUG
  fprintf(stderr, "%s: could not load plugin `%s'\n", exeName, pluginName);
#endif
  return 0;
}
#endif /* USE_SIMPLIFIED_PLUGIN_LOGIC */

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

  snprintf(buf, sizeof(buf), "%s", lookupName);

  if (!*lookupName) /* avoid errors in dlsym from eitherPlugin: code. */
    return 0;

  fn= dlsym(moduleHandle, buf);

  DPRINTF((stderr, "ioFindExternalFunctionIn(%s, %d)\n",
	   lookupName, moduleHandle));

  if ((fn == 0) && (!sqIgnorePluginErrors)
      && strcmp(lookupName, "initialiseModule")
      && strcmp(lookupName, "shutdownModule")
      && strcmp(lookupName, "moduleUnloaded")
      && strcmp(lookupName, "setInterpreter")
      && strcmp(lookupName, "getModuleName"))
    fprintf(stderr, "ioFindExternalFunctionIn(%s, %p):\n  %s\n",
	    lookupName, moduleHandle, dlerror());

#if SPURVM
  if (fn && accessorDepthPtr) {
	signed char *accessorDepthVarPtr;

	snprintf(buf+strlen(buf), sizeof(buf) - strlen(buf), "AccessorDepth");
	accessorDepthVarPtr = dlsym(moduleHandle, buf);
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
  if (dlclose(moduleHandle))
    {
      DPRINTF((stderr, "ioFreeModule(%d): %s\n", moduleHandle, dlerror()));
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
