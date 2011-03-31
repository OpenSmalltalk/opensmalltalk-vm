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

/* Last edited: 2010-04-09 00:37:36 by piumarta on ubuntu
 */

#define DEBUG 0
 
#include "sq.h"		/* sqUnixConfig.h */

#if (DEBUG)
# define fdebugf(ARGS) fprintf ARGS
#else
# define fdebugf(ARGS)
#endif
 
#if !defined(HAVE_DLOPEN) && defined(HAVE_DYLD)
# include "dlfcn-dyld.c"
#endif

#if defined(HAVE_DLOPEN)	/* non-starter without this! */

#ifdef HAVE_DLFCN_H
# include <dlfcn.h>
#else
  extern void *dlopen (const char *filename, int flag);
  extern const char *dlerror(void);
  extern void *dlsym(void *handle, const char *symbol);
  extern int dlclose (void *handle);
#endif
 
#include <limits.h>
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

#if 1 /* simplified plugin logic */


static void *tryLoadModule(char *in, char *name)
{
  char path[PATH_MAX], *out= path;
  void *handle= 0;
  int c;
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
  sprintf(out, "/" MODULE_PREFIX "%s" MODULE_SUFFIX, name);
  handle= dlopen(path, RTLD_NOW | RTLD_GLOBAL);
  fdebugf((stderr, "tryLoading(%s) = %p\n", path, handle));
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

  if ((0 == pluginName) || ('\0' == pluginName[0])) {	/* find module in main program */
    handle= dlopen(0, RTLD_NOW | RTLD_GLOBAL);
    if (handle == 0) {
      fprintf(stderr, "ioLoadModule(<intrinsic>): %s\n", dlerror());
    }
    else {
      fdebugf((stderr, "loaded: <intrinsic>\n"));
    }
    return handle;
  }

  /* try loading the name unmodified */

  if ((handle= dlopen(pluginName, RTLD_NOW | RTLD_GLOBAL)))
    return handle;

  /* try loading {pluginPaths}/MODULE_PREFIX<name>MODULE_SUFFIX */

  while (*dir) {
    if ((handle= tryLoadModule(dir, pluginName)))
      return handle;
    while (*dir && ':' != *dir++)
      ;
  }

  /* try dlopen()ing LIBRARY_PREFIX<name>LIBRARY_SUFFIX searching only the default locations modulo LD_LIBRARY_PATH et al */

# if defined(HAVE_SNPRINTF)
  snprintf(path, sizeof(path), "%s%s%s", LIBRARY_PREFIX, pluginName, LIBRARY_SUFFIX);
# else
  sprintf(path, "%s%s%s", LIBRARY_PREFIX, pluginName, LIBRARY_SUFFIX);
# endif

  if ((handle= dlopen(path, RTLD_NOW | RTLD_GLOBAL)))
    return handle;

  fdebugf((stderr, "ioLoadModule(%s) = %p\n", path, handle));

  return handle;
}


#else /* obsolete plugin logic */

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
	if ((err= stat(libName, &buf)))
	  fdebugf((stderr, "cannot read: %s\n", libName));
	else
	  {
	    if (S_ISDIR(buf.st_mode))
	      fdebugf((stderr, "ignoring directory: %s\n", libName));
	    else
	      {
		fdebugf((stderr, "tryLoading %s\n", libName));
		handle= dlopen(libName, RTLD_NOW | RTLD_GLOBAL);
		if (handle == 0)
		  {
		    /*if ((!err) && !(sqIgnorePluginErrors))*/
		      fprintf(stderr, "ioLoadModule(%s):\n  %s\n", libName, dlerror());
		  }
		else
		  {
#	           if DEBUG
		    printf("squeak: loaded plugin `%s'\n", libName);
#	           endif
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
      fdebugf((stderr, "try %s=%s\n", varName, path));
      strncpy(pbuf, path, sizeof(pbuf));
      pbuf[sizeof(pbuf) - 1]= '\0';
      for (path= strtok(pbuf, ":");
	   path != 0;
	   path= strtok(0, ":"))
	{
	  char buf[MAXPATHLEN];
	  sprintf(buf, "%s/", path);
	  fdebugf((stderr, "  path dir = %s\n", buf));
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
	  fdebugf((stderr, "loaded: <intrinsic>\n"));
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
	fdebugf((stderr, "ioLoadModule plugins = %s\n                path = %s\n",
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
#endif /* DARWIN */

  /* finally (for VM hackers) try the pre-install build location */
  {
    char pluginDir[MAXPATHLEN];
#  ifdef HAVE_SNPRINTF
    snprintf(pluginDir, sizeof(pluginDir), "%s%s/", vmPath, pluginName);
#  else
    sprintf(pluginDir, "%s%s/", vmPath, pluginName);
#  endif
    if ((handle= tryLoading(pluginDir, pluginName)))
      return handle;
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

#endif /* obsolete plugin logic */

/*  Find a function in a loaded module.  Answer 0 if not found (do NOT
 *  fail the primitive!).
 */
void *ioFindExternalFunctionIn(char *lookupName, void *moduleHandle)
{
  void *fn= dlsym(moduleHandle, lookupName);
  fdebugf((stderr, "ioFindExternalFunctionIn(%s, %p) = %p\n", lookupName, moduleHandle, fn));

  if ((fn == 0) && (!sqIgnorePluginErrors)
      && strcmp(lookupName, "initialiseModule")
      && strcmp(lookupName, "shutdownModule")
      && strcmp(lookupName, "setInterpreter")
      && strcmp(lookupName, "getModuleName"))
    fprintf(stderr, "ioFindExternalFunctionIn(%s, %p):\n  %s\n", lookupName, moduleHandle, dlerror());

  return fn;
}

/*  Free the module with the associated handle.  Answer 0 on error (do
 *  NOT fail the primitive!).
*/
sqInt ioFreeModule(void *moduleHandle)
{
  if (dlclose(moduleHandle))
    {
      fdebugf((stderr, "ioFreeModule(%d): %s\n", moduleHandle, dlerror()));
      return 0;
    }
  return 1;
}


#else /* !HAVE_DLOPEN */



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



#endif /* !HAVE_DLOPEN */
