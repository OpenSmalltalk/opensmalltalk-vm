/* zipio.c -- buffered i/o for gzip images
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
 * Last edited: Thu Aug 17 03:37:47 2000 by piumarta (Ian Piumarta) on emilia
 * 
 * See zipio.h for additional information.
 */

#include "zipio.h"

#include <stdlib.h>
#include <string.h>

#include "sqUnixConfig.h"


#define dprintf(ARGS) /* printf ARGS */

/*** external variables available to clients ***/


int  z_errno= 0;	/* last zlib error number */
char z_error[128];	/* last zlib error message */


/*** private structures ***/


typedef struct {
  long    position;
  void   *data;
  size_t  ndata;
} z_file;

#define ZS_POSITION(S)	(((z_file *)(S)->opaque)->position)
#define ZS_DATA(S)	(((z_file *)(S)->opaque)->data)
#define ZS_NDATA(S)	(((z_file *)(S)->opaque)->ndata)


/*** private functions ***/


static void *zalloc(void *opaque, unsigned items, unsigned size)
{
  return malloc(items * size);
}

static void zfree(void *opaque, void *address, unsigned nbytes)
{
  free(address);
}

static size_t error0(char *what, int zerr, z_stream *stream, int cleanup)
{
  z_errno= zerr;
  sprintf(z_error, "%s: %s", what, stream->msg);
  if (cleanup)
    free(stream);
  dprintf(("%s\n", z_error));
  return 0;
}

#define error(__what, __zerr, __stream, __cleanup) \
     ( error0(__what, __zerr, __stream, __cleanup), -1 )

static unsigned char *badHeader(char *why)
{
  strcpy(z_error, why);
  return 0;
}


/*** public functions ***/


/* check the integrity of a gzip header, filling in name[nname] and
 * comment[ncomment] with the name and/or comment as stored in the header.
 * answer the address of the start of the deflated data, or zero if error
 * and set z_error appropriately.
 */
unsigned char *gzstat(unsigned char *header,
		      char *name, size_t nname, char *comment, size_t ncomment)
{
  /* according to /etc/magic we should expect...
   *
   *   0       string          \037\213        gzip compressed data
   *   >2      byte            <8              \b, reserved method,
   *   >2      byte            8               \b, deflated,
   *   >3      byte            &0x01           ASCII,
   *   >3      byte            &0x02           continuation,
   *   >3      byte            &0x04           extra field,
   *   >3      byte            &0x08           original filename,
   *   >3      byte            &0x10           comment,
   *   >3      byte            &0x20           encrypted,
   *   [...not interesting...]
   *   >9      byte                            os type
   */
  unsigned char *data=  header + 10;	/* nominal data start */
  unsigned char method= header[2];
  unsigned char flags=  header[3];

  if (name    != 0) *name=    '\0';
  if (comment != 0) *comment= '\0';

  if ((header[0] != '\037') || (header[1] != (unsigned char)'\213'))
    return badHeader("not in gzip format");

  if (method != 8)  return badHeader("method is not deflate");
  if (flags & 0x01) return badHeader("gzip data is ASCII");
  if (flags & 0x02) return badHeader("gzip data is continuation");
  if (flags & 0x20) return badHeader("gzip data is encrypted");

  if (flags & 0x04)
    /* field length is leshort */
    data= data + 2 + data[0] + (data[1] << 8);

  if (flags &0x08)
    {
      if (name != 0)
	strncpy(name, data, nname);
      while (*data++ != '\0')
	;
    }

  if (flags &0x10)
    {
      if (comment != 0)
	strncpy(comment, data, ncomment);
      while (*data++ != '\0')
	;
    }

  return data;
}


/* decompress an entire LZ77 compressed block in[inSize] to out[outSize].
 * client must ensure outSize is sufficient for the decompressed data.
 * answer the number of bytes written to out, or -1 for error and set
 * z_error appropriately.
 */
size_t zload(void *out, size_t nout, unsigned char *in, size_t nin)
{
  int zerr= 0;
  z_stream stream;
  
  stream.zalloc= zalloc;
  stream.zfree=  zfree;
  if (Z_OK != (zerr= inflateInit2(&stream, -(MAX_WBITS))))
    return error("inflateInit2", zerr, &stream, 0);
  stream.next_in=   in;
  stream.avail_in=  nin;
  stream.next_out=  out;
  stream.avail_out= nout;
  if ((Z_OK != (zerr= inflate(&stream, Z_FINISH)))
      && (Z_STREAM_END != zerr))
    return error("inflate", zerr, &stream, 0);
  if (Z_OK != (zerr= inflateEnd(&stream)))
    return error("inflateEnd", zerr, &stream, 0);
  return stream.next_out - (unsigned char *)out;
}


/* decompress an entire gzip image in[inSize] to out[outSize].
 * client must ensure outSize is sufficient for the decompressed data.
 * answer the number of bytes written to out, or -1 for error and set
 * z_errno and z_error appropriately.
 */
size_t gzload(void *out, size_t nout, unsigned char *in, size_t nin)
{
  unsigned char *data= gzstat(in, 0, 0, 0, 0);
  if (data == 0)
    return -1;
  if (data > (in + nin))
    return (size_t)badHeader("truncated data") - 1;
  return zload(out, nout, data, nin + (data - in));
}


/* open the LZ77 compressed block in[nin] for reading.  answer the open
 * stream, or 0 if error and set z_error appropropriately.
 */
z_stream *zopen(unsigned char *in, size_t nin)
{
  z_stream *stream= 0;
  z_file   *file=   0;
  int zerr= 0;

  stream= (z_stream *)malloc(sizeof(z_stream));
  file= (z_file *)malloc(sizeof(z_file));
  
  file->position= 0;
  file->data=     in;
  file->ndata=    nin;

  stream->zalloc= zalloc;
  stream->zfree=  zfree;
  stream->opaque= (void *)file;
  if (Z_OK != (zerr= inflateInit2(stream, -(MAX_WBITS))))
    return (z_stream *)error0("inflateInit2", zerr, stream, 1);
  stream->next_in=  in;
  stream->avail_in= nin;
  return stream;
}


/* open the gzip image in[nin] for reading.  answer the open stream,
 * or 0 if error and set z_error appropropriately.
 */
z_stream *gzopen(unsigned char *in, size_t nin)
{
  unsigned char *data= gzstat(in, 0, 0, 0, 0);
  if (data == 0)
    return 0;
  if (data > (in + nin))
    return (z_stream *)badHeader("truncated data");
  return zopen(data, nin - (data - in));
}


/* read at most nmemb elements of size bytes from the stream,
 * storing them at ptr.  answer the number of items read, or zero if
 * error and set z_errno and z_error appropriately.
 */
size_t zread(void *ptr, size_t size, size_t nmemb, z_stream *stream)
{
  dprintf(("zread %p %d %d %p\n", ptr, size, nmemb, stream));
  stream->next_out=  (unsigned char *)ptr;
  stream->avail_out= size * nmemb;
  {
    int zerr= inflate(stream, Z_PARTIAL_FLUSH);
    if ((Z_OK != zerr) && (Z_STREAM_END != zerr))
      /* client must zclose() the stream */
      return error0("inflate", zerr, stream, 0);
  }
  /* update stream pointer */
  ZS_POSITION(stream)+= (size * nmemb);
  dprintf(("=> %d\n", (size_t)(stream->next_out - (unsigned char *)ptr) / size));
  return (size_t)(stream->next_out - (unsigned char *)ptr) / size;
}


/* answer the current byte offset in the decompressed stream.
 */
long ztell(z_stream *stream)
{
  dprintf(("ztell %p => %ld\n", stream, ZS_POSITION(stream)));
  return ZS_POSITION(stream);
}


/* rewind the stream to the beginning.
 */
void zrewind(z_stream *stream)
{
  int zerr= 0;
  dprintf(("zrewind %p\n", stream));
  if (Z_OK != (zerr= inflateReset(stream)))
    error0("inflateEnd", zerr, stream, 0);
  stream->next_in= ZS_DATA(stream);
  stream->avail_in= ZS_NDATA(stream);
  ZS_POSITION(stream)= 0;
}



static int wind(z_stream *stream, int distance)
{
  unsigned char buf[8192];

  dprintf(("wind %p %d\n", stream, distance));

  /* negative distance means "infinity" */
  while (distance != 0)
    {
      int skip= (distance < sizeof(buf) ? distance : sizeof(buf));
      stream->next_out= buf;
      stream->avail_out= skip;
      {
	int zerr= inflate(stream, Z_PARTIAL_FLUSH);
	if ((Z_OK != zerr) && (Z_STREAM_END != zerr))
	  {
	    error("inflate", zerr, stream, 0);
	    return -1;
	  }
	skip= stream->next_out - buf;
	if ((skip == 0) && (zerr != Z_STREAM_END))
	  {
	    fprintf(stderr, "wind: ran out of data before end of stream\n");
	    abort();
	  }
	if (skip > distance)
	  {
	    fprintf(stderr, "wind: inflate wrote too much data\n");
	    abort();
	  }
      }
      /* update stream pointer */
      ZS_POSITION(stream)+= skip;
      distance-= skip;
    }
  return 0;
}


/* reposition the stream to the given location.
 */
int zseek(z_stream *stream, long offset, int whence)
{
  long origin= ztell(stream);
  long dest= 0;

  dprintf(("zseek %p %ld %d\n", stream, offset, whence));

  switch (whence)
    {
    case SEEK_SET:
      dest= offset;
      break;
    case SEEK_CUR:
      dest= origin + offset;
      break;
    case SEEK_END:
      if (0 != wind(stream, -1))
	return -1;
      dest= ztell(stream) + offset;
      break;
    default:
      return -1;
    }

  if (dest > origin)
    return wind(stream, dest - origin);

  if (dest == origin)
    return 0;

  /* assert(dest < origin); */

  zrewind(stream);
  return wind(stream, dest);
}


/* close the stream.
 */
int zclose(z_stream *stream)
{
  int zerr= inflateEnd(stream);
  if (Z_OK != zerr)
    {
      error("inflateEnd", zerr, stream, 1);
      zerr= -1;
    }
  else
    zerr= 0;
  free(stream->opaque);
  free(stream);
  return zerr;
}
