/* sqUnixExternalPrims.c -- Unix named primitives and loadable modules
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
 */

/* Author: Ian.Piumarta@INRIA.Fr
 *
 * Last edited: 2005-04-06 06:09:36 by piumarta on pauillac.hpl.hp.com
 */

#define DEBUG 0
 
#include "sq.h"		/* sqUnixConfig.h */

#if (DEBUG)
# define dprintf(ARGS) fprintf ARGS
#else
# define dprintf(ARGS)
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

extern char *squeakPlugins;

/*** configured variables ***/

extern char vmLibDir[];
extern char vmPath[];

/*** local functions ***/


/*  Attempt to load the shared library named by the concatenation of prefix,
 *  moduleName and suffix.  Answer the new module entry, or 0 if the shared
 *  library could not be loaded.
 */
static void *tryLoading(char *dirName, char *moduleName)
{
  static char *prefixes[]= { "", "lib", 0 };
  static char *suffixes[]= { "", ".so", ".dylib", 0 };
  void        *handle= 0;
  char	     **prefix= 0, **suffix= 0;

  for (prefix= prefixes;  *prefix;  ++prefix)
    for (suffix= suffixes;  *suffix;  ++suffix)
      {
	char        libName[NAME_MAX + 32];	/* headroom for prefix/suffix */
	struct stat buf;
	int         err;
	sprintf(libName, "%s%s%s%s", dirName, *prefix, moduleName, *suffix);
	if ((!(err= stat(libName, &buf))) && S_ISDIR(buf.st_mode))
	  dprintf((stderr, "ignoring directory: %s\n", libName));
	else
	  {
	    dprintf((stderr, "tryLoading %s\n", libName));
	    handle= dlopen(libName, RTLD_NOW | RTLD_GLOBAL);
	    if (handle == 0)
	      {
		if ((!err) && !(sqIgnorePluginErrors))
		  fprintf(stderr, "ioLoadModule(%s):\n  %s\n", libName, dlerror());
	      }
	    else
	      {
#	       if DEBUG
		printf("squeak: loaded plugin `%s'\n", libName);
#	       endif
		return handle;
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
      dprintf((stderr, "try %s=%s\n", varName, path));
      strncpy(pbuf, path, sizeof(pbuf));
      pbuf[sizeof(pbuf) - 1]= '\0';
      for (path= strtok(pbuf, ":");
	   path != 0;
	   path= strtok(0, ":"))
	{
	  char buf[MAXPATHLEN];
	  sprintf(buf, "%s/", path);
	  dprintf((stderr, "  path dir = %s\n", buf));
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

  if ((pluginName == 0) || (pluginName[0] == '\0'))
    {
      handle= dlopen(0, RTLD_NOW | RTLD_GLOBAL);
      if (handle == 0)
	fprintf(stderr, "ioLoadModule(<intrinsic>): %s\n", dlerror());
      else
	{
	  dprintf((stderr, "loaded: <intrinsic>\n"));
	  return handle;
	}
    }

  if (squeakPlugins)
      {
	char path[NAME_MAX];
	char c, *in= squeakPlugins, *out= path;
	while ((c= *in++))
	  {
	    if (c == '%' && ((*in == 'n') || (*in == 'N')))
	      {
		++in;
		strcpy(out, pluginName);
		out+= strlen(pluginName);
	      }
	    else
	      *out++= c;
	  }
	*out= '\0';
	dprintf((stderr, "ioLoadModule plugins = %s\n                path = %s\n",
		 squeakPlugins, path));
	if ((handle= tryLoading("", path)))
	  return handle;
	*out++= '/';
	*out= '\0';
	if ((handle= tryLoading(path, pluginName)))
	  return handle;
      }

  if ((   handle= tryLoading(    "./",			pluginName))
      || (handle= tryLoadingPath("SQUEAK_PLUGIN_PATH",	pluginName))
      || (handle= tryLoading(    VM_LIBDIR"/",		pluginName))
      || (handle= tryLoadingPath("LD_LIBRARY_PATH",	pluginName))
      || (handle= tryLoading(    "",			pluginName))
#    if defined(VM_X11DIR)
      || (handle= tryLoading(VM_X11DIR"/",		pluginName))
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
	sprintf(path, "%s/%s.framework/", *framework, pluginName);
	if ((handle= tryLoading(path, pluginName)))
	  return handle;
      }
  }
#endif

  /* finally (for VM hackers) try the pre-install build location */
  {
    char pluginDir[MAXPATHLEN];
#  ifdef HAVE_SNPRINTF
    snprintf(pluginDir, sizeof(pluginDir), "%s%s/.libs/", vmPath, pluginName);
#  else
    sprintf(pluginDir, "%s%s/.libs/", vmPath, pluginName);
#  endif
    if ((handle= tryLoading(pluginDir, pluginName)))
      return handle;
  }

#if DEBUG
  fprintf(stderr, "squeak: could not load plugin `%s'\n", pluginName);
#endif
  return 0;
}


/*  Find a function in a loaded module.  Answer 0 if not found (do NOT
 *  fail the primitive!).
 */
void *ioFindExternalFunctionIn(char *lookupName, void *moduleHandle)
{
  char buf[256];
  void *fn;

#ifdef HAVE_SNPRINTF
  snprintf(buf, sizeof(buf), "%s", lookupName);
#else
  sprintf(buf, "%s", lookupName);
#endif

  fn= dlsym(moduleHandle, buf);

  dprintf((stderr, "ioFindExternalFunctionIn(%s, %d)\n",
	   lookupName, moduleHandle));

  if ((fn == 0) && (!sqIgnorePluginErrors)
      && strcmp(lookupName, "initialiseModule")
      && strcmp(lookupName, "shutdownModule")
      && strcmp(lookupName, "setInterpreter")
      && strcmp(lookupName, "getModuleName"))
    fprintf(stderr, "ioFindExternalFunctionIn(%s, %p):\n  %s\n",
	    lookupName, moduleHandle, dlerror());

  return fn;
}



/*  Free the module with the associated handle.  Answer 0 on error (do
 *  NOT fail the primitive!).
*/
sqInt ioFreeModule(void *moduleHandle)
{
  if (dlclose(moduleHandle))
    {
      dprintf((stderr, "ioFreeModule(%d): %s\n", moduleHandle, dlerror()));
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
