/* sqUnixCharConv.c -- conversion between character encodings
 * 
 * Author: Ian.Piumarta@squeakland.org
 * 
 *   Copyright (C) 1996-2005 by Ian Piumarta and other authors/contributors
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
 * Last edited: 2005-03-17 21:09:51 by piumarta on squeak.hpl.hp.com
 */

#if !defined(__MACH__)
# include "sqMemoryAccess.h"
#endif
#include "sqUnixCharConv.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>

static inline int min(int x, int y) { return (x < y) ? x : y; }

static int convertCopy(char *from, int fromLen, char *to, int toLen, int term)
{
  int len= min(toLen - term, fromLen);
  strncpy(to, from, len);
  if (term) to[len]= '\0';
  return len;
}


#if defined(__MACH__)

// we have to do something special on MacOSX (surprise surprise) because:
// - MacOSX is not Unix98 compliant and lacks builtin iconv functions
// - the free libiconv cannot handle the canonical decomposition used in HFS+
// ho hum dee dumb

# include <CoreFoundation/CoreFoundation.h>
# include "sqMemoryAccess.h"

typedef struct
{
  char *alias;
  void *encoding;
} alias;

static alias encodings[]=
{
  { "MACROMAN",		(void *)kCFStringEncodingMacRoman },
  { "MAC",		(void *)kCFStringEncodingMacRoman },
  { "MACINTOSH",	(void *)kCFStringEncodingMacRoman },
  { "CSMACINTOSH",	(void *)kCFStringEncodingMacRoman },
  { "UTF8",		(void *)kCFStringEncodingUTF8 },
  { "UTF-8",		(void *)kCFStringEncodingUTF8 },
  { "ISOLATIN9",	(void *)kCFStringEncodingISOLatin9 },
  { "LATIN9",		(void *)kCFStringEncodingISOLatin9 },
  { "ISO-8859-15",	(void *)kCFStringEncodingISOLatin9 },
  { "ISOLATIN1",	(void *)kCFStringEncodingISOLatin1 },
  { "LATIN1",		(void *)kCFStringEncodingISOLatin1 },
  { "ISO-8859-1",	(void *)kCFStringEncodingISOLatin1 },
  // there are many tens of these and I cannot be bothered.
  { 0,			0 }
};

// defaults

void *sqTextEncoding=	((void *)kCFStringEncodingMacRoman);	// xxxFIXME -> kCFStringEncodingISOLatin9
void *uxTextEncoding=	((void *)kCFStringEncodingISOLatin9);
void *uxPathEncoding=	((void *)kCFStringEncodingUTF8);
void *uxUTF8Encoding=	((void *)kCFStringEncodingUTF8);
void *uxXWinEncoding=	((void *)kCFStringEncodingISOLatin1);

void setEncoding(void **encoding, char *rawName)
{
  char *name= strdup(rawName);
  int   len= strlen(name);
  int   i;
  int   utf8= 0;
  alias *ap= encodings;
  for (i= 0;  i < len;  ++i)
    name[i]= toupper(name[i]);
  while (ap->alias)
    if (!strcmp(name, ap->alias))
      {
	*encoding= ap->encoding;
	goto done;
      }
    else
      ++ap;
  fprintf(stderr, "setEncoding: could not set encoding '%s'\n", name);
 done:
  free(name);
}

int convertChars(char *from, int fromLen, void *fromCode, char *to, int toLen, void *toCode, int norm, int term)
{
  CFStringRef	     cfs= CFStringCreateWithBytes(NULL, from, fromLen, (CFStringEncoding)fromCode, 0);
  CFMutableStringRef str= CFStringCreateMutableCopy(NULL, 0, cfs);
  CFRelease(cfs);
  if (norm) // HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
    CFStringNormalize(str, kCFStringNormalizationFormD); // canonical decomposition
  {
    CFRange rng= CFRangeMake(0, CFStringGetLength(str));
    CFIndex len= 0;
    CFIndex num= CFStringGetBytes(str, rng, (CFStringEncoding)toCode, '?', 0, (UInt8 *)to, toLen - term, &len);
    CFRelease(str);
    if (!num)
      return convertCopy(from, fromLen, to, toLen, term);
    if (term)
      to[len]= '\0';
    return len;
  }
}


#elif defined(HAVE_ICONV_H)


#include <iconv.h>

typedef char ichar_t;

#ifdef __sparc
void *sqTextEncoding=	(void *)"mac";		/* xxxFIXME -> "ISO-8859-15" */ 
void *uxPathEncoding=	(void *)"iso";
void *uxTextEncoding=	(void *)"iso";
void *uxXWinEncoding=	(void *)"iso";
void *uxUTF8Encoding=	(void *)"UTF-8";
#else
void *sqTextEncoding=	(void *)"MACINTOSH";	/* xxxFIXME -> "ISO-8859-15" */ 
void *uxPathEncoding=	(void *)"UTF-8";
void *uxTextEncoding=	(void *)"ISO-8859-15";
void *uxXWinEncoding=	(void *)"ISO-8859-1";
void *uxUTF8Encoding=	(void *)"UTF-8";
#endif

void setEncoding(void **encoding, char *rawName)
{
  char *name= strdup(rawName);	// teeny memory leak, but we don't care
  int   len= strlen(name);
  int   i;
#ifndef __sparc
  for (i= 0;  i < len;  ++i)
    name[i]= toupper(name[i]);
#endif
  if      (!strcmp(name, "MACROMAN"))  *encoding= "MACINTOSH";
  else if (!strcmp(name, "MAC-ROMAN")) *encoding= "MACINTOSH";
  else
    *encoding= (void *)name;
}

int convertChars(char *from, int fromLen, void *fromCode, char *to, int toLen, void *toCode, int norm, int term)
{
  ichar_t     *inbuf= from;
  size_t     inbytes= fromLen;
  char       *outbuf= to;
  size_t    outbytes= toLen - term;
  static iconv_t  cd= (iconv_t)-1;
  static void   *pfc= 0;
  static void   *ptc= 0;

  if ((pfc != fromCode) || (ptc != toCode))
    {
      if (cd != (iconv_t)-1) iconv_close(cd);
      pfc= ptc= (void *)-1;
      cd= iconv_open((const char *)toCode, (const char *)fromCode);
      if ((iconv_t)-1 != cd)
	{
	  pfc= fromCode;
	  ptc= toCode;
	}
    }
#if 0 /* unsupported on OSF1 and Solaris */
  else
    iconv(cd, 0, 0, 0, 0);	/* reset cd state */
#endif

#if 0 /* original */
  if ((iconv_t)-1 != cd)
    {
      int n= iconv(cd, &inbuf, &inbytes, &outbuf, &outbytes);
      if ((size_t)-1 != n)
	{
	  if (term) *outbuf= '\0';
	  return outbuf - to;
	}
      else
	perror("iconv");
    }
  else
    perror("iconv_open");
#else /* Ned's changes -- to be verified on OSX and Solaris */
  if ((iconv_t)-1 != cd)
    {
      while (inbytes > 0)
	{
	  int n= iconv(cd, &inbuf, &inbytes, &outbuf, &outbytes);
	  if ((size_t)-1 == n)
	    {
	      switch (errno)
		{
		case EINVAL:  /* broken multibyte at end of input */
		case EILSEQ:  /* broken multibyte in input */
		  {
		    unsigned char c= (unsigned char)*inbuf;
		    unsigned char mask= 0x80;
		    size_t skip= 0;

		    if (0xfe == c || 0xff == c)		/* invalid */
		      skip= 1;
		    else 
		      while ((skip < inbytes) && (mask & c))
			{
			  skip++;
			  mask >>= 1;
			}
		    inbuf += skip;
		    inbytes -= skip;
		    if (outbytes > 0)
		      {
			*outbuf++ = '?';
			outbytes--;
		      }
		  }
		  break;

		case E2BIG:   /* out of room in output buffer */
		  inbytes= 0;
		  /* fall through */

		default:
		  perror("iconv");
		  break;
		}
	    }
	}
      if (term) *outbuf= '\0';
      return outbuf - to;
    }
  else
    perror("iconv_open");
#endif

  return convertCopy(from, fromLen, to, toLen, term);
}


#else /* !__MACH__ && !HAVE_LIBICONV */

void *sqTextEncoding= 0;
void *uxTextEncoding= 0;
void *uxPathEncoding= 0;
void *uxUTF8Encoding= 0;
void *uxXWinEncoding= 0;

void setEncoding(void **encoding, char *name) { }

int convertChars(char *from, int fromLen, void *fromCode, char *to, int toLen, void *toCode, int norm, int term)
{
  return convertCopy(from, fromLen, to, toLen, term);
}

#endif


static inline void sq2uxLines(char *string, int n)
{
  while (n--)
    {
      if ('\015' == *string) *string= '\012';
      ++string;
    }
}

static inline void ux2sqLines(char *string, int n)
{
  while (n--)
    {
      if ('\012' == *string) *string= '\015';
      ++string;
    }
}


#define Convert(sq,ux, type, F, T, N, L)					\
  int sq##2##ux##type(char *from, int fromLen, char *to, int toLen, int term)	\
  {										\
    int n= convertChars(from, fromLen, F, to, toLen, T, N, term);		\
    if (L) sq##2##ux##Lines(to, n);						\
    return n;									\
  }

Convert(sq,ux, Text, sqTextEncoding, uxTextEncoding, 0, 1);
Convert(ux,sq, Text, uxTextEncoding, sqTextEncoding, 0, 1);
#if defined(__MACH__)
Convert(sq,ux, Path, sqTextEncoding, uxPathEncoding, 1, 0);	// normalised paths for HFS+
#else
Convert(sq,ux, Path, sqTextEncoding, uxPathEncoding, 0, 0);	// composed paths for others
#endif
Convert(ux,sq, Path, uxPathEncoding, sqTextEncoding, 0, 0);
Convert(sq,ux, UTF8, sqTextEncoding, uxUTF8Encoding, 0, 1);
Convert(ux,sq, UTF8, uxUTF8Encoding, sqTextEncoding, 0, 1);

#undef Convert



void sqFilenameFromString(char *uxName, sqInt sqNameIndex, int sqNameLength)
{
  /*xxx BUG: lots of code generate from the image assumes 1000 chars max path len */
  sq2uxPath(pointerForOop(sqNameIndex), sqNameLength, uxName, 1000, 1);
}



#if defined(CONV_TEST)


#if defined(HAVE_LANGINFO_CODESET)
# include <langinfo.h>
#endif

int main()
{
#if defined(HAVE_LANGINFO_CODESET)
  if (0 == strcmp(nl_langinfo(CODESET), "UTF-8"))
    printf("UTF-8 codeset selected\n");
#else
  {
    char *s;
    if (((   (s = getenv("LC_ALL"))   && *s)
	 || ((s = getenv("LC_CTYPE")) && *s)
	 || ((s = getenv("LANG"))     && *s))
	&& strstr(s, "UTF-8"))
      printf("UTF-8 locale selected\n");
  }
#endif

  {
    char *in, out[256];
    int   n;
    in= "tésté";		// UTF-8 composed Unicode
    n= convertChars(in, strlen(in), uxPathEncoding, out, sizeof(out), uxTextEncoding, 0, 1);
    printf("%d: %s -> %s\n", n, in, out);
    in= "tésté";	// UTF-8 decomposed Unicode (libiconv fails on this one, MacOSX passes)
    n= convertChars(in, strlen(in), uxPathEncoding, out, sizeof(out), uxTextEncoding, 0, 1);
    printf("%d: %s -> %s\n", n, in, out);
    in= "t�st�";		// ISO-8859-15
    n= convertChars(in, strlen(in), uxTextEncoding, out, sizeof(out), uxPathEncoding, 0, 1);
    printf("%d: %s -> %s\n", n, in, out); // default composition -- should yield "tésté"
    n= convertChars(in, strlen(in), uxTextEncoding, out, sizeof(out), uxPathEncoding, 1, 1);
    printf("%d: %s -> %s\n", n, in, out); // canonical decomposition -- should yield "tésté"
  }
  return 0;
}

/*
  cc -Wall -DCONV_TEST -g -o main sqUnixCharConv.c -framework CoreFoundation	# MacOSX
  cc -Wall -DCONV_TEST -g -o main sqUnixCharConv.c				# glibc >= 2.2
  cc -Wall -DCONV_TEST -g -o main sqUnixCharConv.c -liconv			# others
*/

#endif /* defined(CONV_TEST) */
