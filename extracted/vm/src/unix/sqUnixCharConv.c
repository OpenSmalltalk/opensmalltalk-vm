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
 * Last edited: 2009-08-15 12:59:49 by piumarta on emilia-2.local
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

#include "pharovm/debug.h"

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

void *localeEncoding=   0;
void *sqTextEncoding=	((void *)kCFStringEncodingMacRoman);	// xxxFIXME -> kCFStringEncodingISOLatin9
void *uxTextEncoding=	((void *)kCFStringEncodingISOLatin9);
void *sqPathEncoding=	((void *)kCFStringEncodingUTF8);
void *uxPathEncoding=	((void *)kCFStringEncodingUTF8);
void *uxUTF8Encoding=	((void *)kCFStringEncodingUTF8);
void *uxXWinEncoding=	((void *)kCFStringEncodingISOLatin1);

void setLocaleEncoding(char *locale) { }

void freeEncoding(void *encoding) { }

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
  logError("setEncoding: could not set encoding '%s'\n", name);

  done:
  free(name);
}

void setNEncoding(void **encoding, char *rawName, int n)
{
  setEncoding(encoding, rawName);
}

int convertChars(char *from, int fromLen, void *fromCode, char *to, int toLen, void *toCode, int norm, int term)
{
  CFStringRef	     cfs= CFStringCreateWithBytes(NULL, (unsigned char *)from, fromLen, (CFStringEncoding)fromCode, 0);
  CFMutableStringRef str= CFStringCreateMutableCopy(NULL, 0, cfs);
  CFRelease(cfs);
  // HFS+ imposes Unicode2.1 decomposed UTF-8 encoding on all path elements
  if (norm == 1)
    CFStringNormalize(str, kCFStringNormalizationFormD); // canonical decomposition
  else if (norm == 2)
    CFStringNormalize(str, kCFStringNormalizationFormC); // canonical composition
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

# include <iconv.h>

typedef char ichar_t;

static char macEncoding[]=     "MACINTOSH";
static char utf8Encoding[]=    "UTF-8";
static char iso1Encoding[]=    "ISO-8859-1";
static char iso15Encoding[]=   "ISO-8859-15";

static char *preDefinedEncodings[]=
  {
    macEncoding,
    utf8Encoding,
    iso1Encoding,
    iso15Encoding
  };

void *localeEncoding=   0;
void *sqTextEncoding=   (void *)macEncoding;
void *uxTextEncoding=   (void *)iso15Encoding;
void *sqPathEncoding=	(void *)utf8Encoding;
void *uxPathEncoding=   (void *)utf8Encoding;
void *uxUTF8Encoding=   (void *)utf8Encoding;
void *uxXWinEncoding=   (void *)iso1Encoding;

void freeEncoding(void *encoding)
{
  int i;
  for (i= 0;  i < sizeof(preDefinedEncodings) / sizeof(char *);  ++i)
    if (encoding == preDefinedEncodings[i])
      return;
  free(encoding);
}

typedef struct
{
  char *name;
  char *encoding;
} alias;

void setNEncoding(void **encoding, char *rawName, int n)
{
  char *name= malloc((size_t)((n + 1) * sizeof(char)));
  int   i;

  static alias aliases[]=
    {
      {"UTF8",      utf8Encoding},
      {"MACROMAN",  macEncoding},
      {"MAC-ROMAN", macEncoding},
    };

  for (i= 0;  i < n;  ++i)
    name[i]= toupper(rawName[i]);
  name[n]= '\0';
  if ((*encoding) && (*encoding != localeEncoding))
    freeEncoding(*encoding);
  if (localeEncoding && !strcmp(name, localeEncoding))
    {
      *encoding= localeEncoding;
      free(name);
      return;
    }
  for(i= 0;  i < sizeof(preDefinedEncodings) / sizeof(char *);  ++i)
    if (!strcmp(name, preDefinedEncodings[i]))
      {
	*encoding= preDefinedEncodings[i];
	free(name);
	return;
      }
  for (i= 0;  i < sizeof(aliases) / sizeof(alias);  ++i)
    if(!strcmp(name, aliases[i].name))
      {
	*encoding= aliases[i].encoding;
	free(name);
	return;
      }
  *encoding= name;
}

void setLocaleEncoding(char *locale)
{
  while (*locale)
    if (*locale++ == '.')
      {
	int len= 0;
	while (locale[len] && (locale[len] != '@'))
	  ++len;
	setNEncoding(&localeEncoding, locale, len);
	sqTextEncoding= uxTextEncoding= uxPathEncoding= uxXWinEncoding= localeEncoding;
	return;
      }
}

void setEncoding(void **encoding, char *rawName)
{
  setNEncoding(encoding, rawName, strlen(rawName));
}

static void iconvFail(char *toCode, char *fromCode)
{
  static int warned= 0;
  if (!warned++)
    {
      char buf[256];
      snprintf(buf, sizeof(buf), "iconv_open(%s, %s)", toCode, fromCode);
      logErrorFromErrno(buf);
    }
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
		  iconvFail(toCode, fromCode);
		  break;
		}
	    }
	}
      if (term) *outbuf= '\0';
      return outbuf - to;
    }
  else
    iconvFail(toCode, fromCode);

  return convertCopy(from, fromLen, to, toLen, term);
}

#else /* !__MACH__ && !HAVE_LIBICONV */

void *localeEncoding= 0;
void *sqTextEncoding= 0;
void *sqPathEncoding= 0;
void *uxTextEncoding= 0;
void *uxPathEncoding= 0;
void *uxUTF8Encoding= 0;
void *uxXWinEncoding= 0;

void setLocaleEncoding(char *locale) { }

void freeEncoding(void *encoding) { }

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
Convert(sq,ux, Path, sqPathEncoding, uxPathEncoding, 1, 0);	// normalised paths for HFS+
Convert(ux,sq, Path, uxPathEncoding, sqPathEncoding, 2, 0);
#else
Convert(sq,ux, Path, sqPathEncoding, uxPathEncoding, 0, 0);	// composed paths for others
Convert(ux,sq, Path, uxPathEncoding, sqPathEncoding, 0, 0);
#endif
Convert(sq,ux, UTF8, sqTextEncoding, uxUTF8Encoding, 0, 1);
Convert(ux,sq, UTF8, uxUTF8Encoding, sqTextEncoding, 0, 1);
Convert(ux,sq, XWin, uxXWinEncoding, sqTextEncoding, 0, 1);

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

/*
  cc -Wall -DCONV_TEST -g -o main sqUnixCharConv.c -framework CoreFoundation	# MacOSX
  cc -Wall -DCONV_TEST -g -o main sqUnixCharConv.c				# glibc >= 2.2
  cc -Wall -DCONV_TEST -g -o main sqUnixCharConv.c -liconv			# others
*/

#endif /* defined(CONV_TEST) */
