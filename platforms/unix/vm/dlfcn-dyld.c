/* dlfcn-dyld.c -- provides dlopen() and friends as wrappers around Mach dyld
 * 
 * Author: Ian.Piumarta@INRIA.Fr
 * 
 *   Copyright (C) 1996-2006 by Ian Piumarta and other authors/contributors
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


static void dlUndefined(const char *symbol)
{
  fprintf(stderr, "dyld: undefined symbol: %s\n", symbol);
}

static NSModule dlMultiple(NSSymbol s, NSModule oldModule, NSModule newModule)
{
  DPRINTF((stderr, "dyld: %s: %s previously defined in %s, new definition in %s\n",
	   NSNameOfSymbol(s), NSNameOfModule(oldModule), NSNameOfModule(newModule)));
  return newModule;
}

static void dlLinkEdit(NSLinkEditErrors errorClass, int errorNumber,
		       const char *fileName, const char *errorString)

{
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


static void *dlopen(const char *path, int mode)
{
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


static void *dlsym(void *handle, const char *symbol)
{
  char		_symbol[256];
  NSSymbol	*nsSymbol= 0;

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


static int dlclose(void *handle)
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
