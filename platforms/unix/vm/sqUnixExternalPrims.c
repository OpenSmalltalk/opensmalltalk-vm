/* sqUnixExternalPrims.c -- Unix named primitives and loadable modules
 * 
 *   Copyright (C) 1996 1997 1998 1999 2000 2001 Ian Piumarta and individual
 *      authors/contributors listed elsewhere in this file.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   This file is distributed in the hope that it will be useful, but WITHOUT
 *   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *   FITNESS FOR A PARTICULAR PURPOSE.
 *   
 *   You may use and/or distribute this file ONLY as part of Squeak, under
 *   the terms of the Squeak License as described in `LICENSE' in the base of
 *   this distribution, subject to the following restrictions:
 * 
 *   1. The origin of this software must not be misrepresented; you must not
 *      claim that you wrote the original software.  If you use this software
 *      in a product, an acknowledgment to the original author(s) (and any
 *      other contributors mentioned herein) in the product documentation
 *      would be appreciated but is not required.
 * 
 *   2. This notice may not be removed or altered in any source distribution.
 * 
 *   Using or modifying this file for use in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the base
 *   of the distribution before proceeding with any such use.
 * 
 *   You are STRONGLY DISCOURAGED from distributing a modified version of
 *   this file under its original name without permission.  If you must
 *   change it, rename it first.
 */

/* Author: Ian.Piumarta@INRIA.Fr
 *
 * Last edited: 2001-07-23 14:45:39 CEST by piumarta on emilia.inria.fr
 */

#include "sq.h"		/* sqUnixConfig.h */

#ifdef HAVE_LIBDL	/* non-starter without this! */

#ifdef HAVE_DLFCN_H
# include <dlfcn.h>
#else
  extern void *dlopen (const char *filename, int flag);
  extern const char *dlerror(void);
  extern void *dlsym(void *handle, char *symbol);
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
 
#undef	DEBUG
 
#ifdef DEBUG
# define dprintf(ARGS) fprintf ARGS
#else
# define dprintf(ARGS)
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


/*** local functions ***/


/*  Attempt to load the shared library named by the concatenation of prefix,
 *  moduleName and suffix.  Answer the new module entry, or 0 if the shared
 *  library could not be loaded.
 */
static void *tryLoading(char *prefix, char *moduleName, char *suffix)
{
  char libName[NAME_MAX + 32];	/* headroom for prefix/suffix */
  void *handle;

  sprintf(libName, "%s%s%s", prefix, moduleName, suffix);
  dprintf(("tryLoading %s\n", libName));
  handle= dlopen(libName, RTLD_NOW);
  if (handle == 0)
    {
      /* to preserve the humour of Jitter hackers: try to differentiate
	 between "file not found" and a genuine load error (which would be
	 difficult to diagnose out of context) when the lib is in the CWD */
      struct stat buf;
      if (/*(strcmp(prefix,  "./") == 0)
	    && (strcmp(suffix, ".so") == 0)
	    && */ (stat(libName, &buf) == 0))
	{
	  /* insist on the error message: the shared lib really _is_ broken */
	  if (!(S_ISDIR(buf.st_mode)))
	  {
	    fprintf(stderr, "ioLoadModule(%s): %s\n", libName, dlerror());
	  }
	}
      else
	{
	  dprintf(("not found\n"));
	}
    }
  else
    {
      dprintf((stderr, "loaded:  %s\n", libName));
    }
  return handle;
}


/*  Find and load the named module.  Answer 0 if not found (do NOT fail
 *  the primitive!).
 */
int ioLoadModule(char *pluginName)
{
  void *handle= 0;

  if ((pluginName == 0) || (pluginName[0] == '\0'))
    {
      handle = dlopen(0, RTLD_NOW);
      if (handle == 0)
	fprintf(stderr, "ioLoadModule(<intrinsic>): %s\n", dlerror());
      else
	dprintf((stderr, "loaded:  <intrinsic>\n"));
    } 
  else
    {
      (void)(/* these are ordered such that a knowledgeable user can
		override a "system" library with one in the CWD */
	     (   handle= tryLoading(        "./", pluginName, ".so"))
	     /* these are the normal cases: when LD_LIBRARY_PATH is not
		set they search /etc/ld.so.cache, /usr/lib and /lib */
	     || (handle= tryLoading(          "", pluginName, ".so"))
	     || (handle= tryLoading(          "", pluginName,    ""))
	     /* this is the standard location for the plugins */
	     || (handle= tryLoading(SQ_LIBDIR"/", pluginName, ".so"))
	     || (handle= tryLoading(       "lib", pluginName, ""   ))
	     || (handle= tryLoading(       "lib", pluginName, ".so")));
    }

  if (handle == 0)
    {
      /* ld.so is broken on some platforms: try LD_LIBRARY_PATH ourselves */
      char *path= getenv("LD_LIBRARY_PATH");
      dprintf(("try LD_LIBRARY_PATH %s\n", path));
      if (path != 0)
	{
	  char pbuf[MAXPATHLEN];
	  strncpy(pbuf, path, sizeof(pbuf));
	  pbuf[sizeof(pbuf) - 1]= '\0';
	  for (path= strtok(pbuf, ":");
	       path != 0;
	       path= strtok(0, ":"))
	    {
	      char buf[MAXPATHLEN];
	      sprintf(buf, "%s/", path);
	      dprintf(("LD_LIBRARY_PATH dir = %s\n", buf));
	      if ((handle= tryLoading(buf, pluginName, ".so")) != 0)
		break;
	    }
	}
    }

  return (int)handle;
}


/*  Find a function in a loaded module.  Answer 0 if not found (do NOT
 *  fail the primitive!).
 */
int ioFindExternalFunctionIn(char *lookupName, int moduleHandle)
{
  void *fn= dlsym((void *)moduleHandle, lookupName);

  dprintf((stderr, "ioFindExternalFunctionIn(%s, %d)\n",
	   lookupName, moduleHandle));

  if (fn == 0)
    {
      dprintf((stderr, "ioFindExternalFunctionIn(%s, %d):\n  %s\n",
	       lookupName, moduleHandle, dlerror()));
    }

  return (int)fn;
}



/*  Free the module with the associated handle.  Answer 0 on error (do
 *  NOT fail the primitive!).
*/
int ioFreeModule(int moduleHandle)
{
  if (dlclose((void *)moduleHandle))
    {
      dprintf((stderr, "ioFreeModule(%d): %s\n", moduleHandle, dlerror()));
      return 0;
    }
  return 1;
}


#else /* !HAVE_LIBDL */



int ioLoadModule(char *pluginName)
{
  return 0;
}

int ioFindExternalFunctionIn(char *lookupName, int moduleHandle)
{
  return 0;
}

int ioFreeModule(int moduleHandle)
{
  return 0;
}



#endif /* !HAVE_LIBDL */
