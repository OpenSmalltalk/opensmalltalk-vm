/* zipio.h -- buffered i/o for gzip images
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
 * Last edited: Thu Aug 17 03:35:28 2000 by piumarta (Ian Piumarta) on emilia
 * 
 * NOTE: for the most part the functions follow the same conventions as
 * their counterparts in stdio.  E.g: to understand zseek() just read
 * the man page for fseek() and think "z_stream *" instead of "FILE *".
 * 
 * BUGS: only the input half is implemented.
 */

#include "zlib.h"

#include <stdio.h>		/* SEEK_... */
#include <sys/types.h>		/* size_t */

extern int  z_errno;		/* last zlib error number */
extern char z_error[];		/* last zlib error message */

/* check the integrity of a gzip header, filling in name[nname] and
 * comment[ncomment] with the name and/or comment as stored in the header.
 * answer the address of the start of the deflated data, or zero if error
 * and set z_error appropriately.
 */
unsigned char *gzstat(unsigned char *header,
		      char *name, size_t nname, char *comment, size_t ncomment);

/* decompress an entire LZ77 compressed block in[nin] to out[nout].
 * client must ensure nout is sufficient for the decompressed data.
 * answer the number of bytes written to out, or -1 for error and set
 * z_errno and z_error appropriately.
 */
size_t zload(void *out, size_t nout, unsigned char *in, size_t nin);

/* decompress an entire gzip image in[nin] to out[nout].
 * client must ensure nout is sufficient for the decompressed data.
 * answer the number of bytes written to out, or -1 for error and set
 * z_errno and z_error appropriately.
 */
size_t gzload(void *out, size_t nout, unsigned char *in, size_t nin);

/* open the LZ77 compressed block in[nin] for reading.  answer the open
 * stream, or 0 if error and set z_error appropropriately.
 */
z_stream *zopen(unsigned char *in, size_t nin);

/* open the gzip image in[nin] for reading.  answer the open stream,
 * or 0 if error and set z_errno and z_error appropropriately.
 */
z_stream *gzopen(unsigned char *in, size_t nin);

/* read at most nmemb elements of size bytes from the stream,
 * storing them at ptr.  answer the number of items read, or zero if
 * error and set z_error appropriately.
 */
size_t zread(void *ptr, size_t size, size_t nmemb, z_stream *stream);

/* answer the current byte offset in the decompressed stream.
 */
long ztell(z_stream *stream);

/* rewind the stream to the beginning.
 */
void zrewind(z_stream *stream);

/* reposition the stream to the given location.
 */
int zseek(z_stream *stream, long offset, int whence);

/* close a stream.
 */
int zclose(z_stream *stream);
