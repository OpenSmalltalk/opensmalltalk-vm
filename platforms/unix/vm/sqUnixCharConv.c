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
 * 
 * Last edited: 2006-10-18 10:06:05 by piumarta on emilia.local
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

#ifdef __sun__
void *sqTextEncoding=	(void *)"mac";		/* xxxFIXME -> "ISO-8859-15" */ 
void *uxPathEncoding=	(void *)"iso5";
void *uxTextEncoding=	(void *)"iso5";
void *uxXWinEncoding=	(void *)"iso5";
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
