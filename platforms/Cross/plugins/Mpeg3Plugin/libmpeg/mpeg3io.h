#ifndef MPEG3IO_H
#define MPEG3IO_H


#include <stdio.h>
#if _MSC_VER
# define fseeko(a,b,c) _fseeki64(a,b,c)
#endif
#include "mpeg3css.h"
#include "mpeg3private.inc"

/* Filesystem structure */

typedef struct
{
	FILE *fd;
	mpeg3_css_t *css;          /* Encryption object */
	char path[MPEG3_STRLEN];
/* Hypothetical position of file pointer */
	long current_byte;
	long total_bytes;
	unsigned long id3v2_offset;
	unsigned char*	mpeg_is_in_buffer;
	long	mpeg_is_in_buffer_file_position;
	long	mpeg_buffer_size;
} mpeg3_fs_t;

#define mpeg3io_tell(fs) (((mpeg3_fs_t *)(fs))->current_byte)

// End of file
#define mpeg3io_eof(fs) (((mpeg3_fs_t *)(fs))->current_byte >= ((mpeg3_fs_t *)(fs))->total_bytes)

// Beginning of file
#define mpeg3io_bof(fs)	(((mpeg3_fs_t *)(fs))->current_byte < 0)

#ifdef _WIN32
#define inline __inline
#endif

#define mpeg3io_total_bytes(fs) (((mpeg3_fs_t *)(fs))->total_bytes)

static inline int
mpeg3io_fgetc(mpeg3_fs_t *fs) {
	if (fs->mpeg_is_in_buffer) {
		unsigned int value;
		fs->mpeg_is_in_buffer_file_position++;
		if (fs->mpeg_is_in_buffer_file_position >= fs->mpeg_buffer_size) {
			fs->mpeg_is_in_buffer_file_position = fs->mpeg_buffer_size;
			return 0;
		}
		value = (unsigned int) fs->mpeg_is_in_buffer[fs->mpeg_is_in_buffer_file_position-1];
		return value;
	}
	return (fs->fd ? fgetc(fs->fd) : 0);
}


static inline unsigned int
mpeg3io_read_int32(mpeg3_fs_t *fs)
{
	int a, b, c, d;
	unsigned int result;
/* Do not fread.  This breaks byte ordering. */
	a = (unsigned char)mpeg3io_fgetc(fs);
	b = (unsigned char)mpeg3io_fgetc(fs);
	c = (unsigned char)mpeg3io_fgetc(fs);
	d = (unsigned char)mpeg3io_fgetc(fs);
	result = ((int)a << 24) |
					((int)b << 16) |
					((int)c << 8) |
					((int)d);
	fs->current_byte += 4;
	return result;
}

static inline unsigned int mpeg3io_read_char(mpeg3_fs_t *fs)
{
	fs->current_byte++;
	return mpeg3io_fgetc(fs);
}

#endif
