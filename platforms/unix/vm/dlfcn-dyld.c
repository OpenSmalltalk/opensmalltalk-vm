/* dlfcn-darwin.c -- provides dlopen() and friends as wrappers to Mach's dylib
 * 
 * Author: Ian.Piumarta@INRIA.Fr
 * 
 *   Copyright (C) 1996-2002 Ian Piumarta and other authors/contributors
 *     as listed elsewhere in this file.
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
 *   2. This notice must not be removed or altered in any source distribution.
 * 
 *   Using (or modifying this file for use) in any context other than Squeak
 *   changes these copyright conditions.  Read the file `COPYING' in the
 *   directory `platforms/unix/doc' before proceeding with any such use.
 * 
 *   You are not allowed to distribute a modified version of this file
 *   under its original name without explicit permission to do so.  If
 *   you change it, rename it.
 * 
 * Last edited: 2002-12-01 10:28:43 by piumarta on calvin.inria.fr
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


static const char *dlerror(void)
{
  if (dlErrorSet)
    {
      dlErrorSet= 0;
      return (const char *)dlErrorString;
    }
  return 0;
}


static void *dlopen(const char *path, int mode)
{
  void			*handle= 0;
  NSObjectFileImage	 ofi= 0;

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

  return handle;
}


void *dlsym(void *handle, const char *symbol)
{
  char		_symbol[256];
  NSSymbol	*nsSymbol= 0;

  snprintf(_symbol, sizeof(_symbol), "_%s", symbol);

  dprintf((stderr, "dlsym: looking for %s (%s) in %d\n", symbol, _symbol, (int)handle));

  if (!handle)
    {
      dprintf((stderr, "dlsym: setting app context for this handle\n"));
      handle= DL_APP_CONTEXT;
    }

  if (DL_APP_CONTEXT == handle)
    {
      dprintf((stderr, "dlsym: looking in app context\n"));
      if (NSIsSymbolNameDefined(_symbol))
	nsSymbol= NSLookupAndBindSymbol(_symbol);
    }
  else
    {
      if ((  (MH_MAGIC == ((struct mach_header *)handle)->magic))	/* ppc */
	  || (MH_CIGAM == ((struct mach_header *)handle)->magic)) /* 386 */
	{
	  if (NSIsSymbolNameDefinedInImage((struct mach_header *)handle, _symbol))
	    nsSymbol= NSLookupSymbolInImage
	      ((struct mach_header *)handle,
	       _symbol,
	       NSLOOKUPSYMBOLINIMAGE_OPTION_BIND
	       | NSLOOKUPSYMBOLINIMAGE_OPTION_RETURN_ON_ERROR);
	  dprintf((stderr, "dlsym: bundle (image) lookup returned %p\n", nsSymbol));
	}
      else
	{
	  nsSymbol= NSLookupSymbolInModule(handle, _symbol);
	  dprintf((stderr, "dlsym: dylib (module) lookup returned %p\n", nsSymbol));
	}
    }

  if (!nsSymbol)
    {
      dlSetError("symbol not found: %s", _symbol);
      return 0;
    }

  return NSAddressOfSymbol(nsSymbol);
}


int dlclose(void *handle)
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


/* autoconf has bugs */

#ifdef HAVE_DLFCN_H
# undef HAVE_DLFCN_H
#endif

#ifndef HAVE_LIBDL
# define HAVE_LIBDL
#endif
