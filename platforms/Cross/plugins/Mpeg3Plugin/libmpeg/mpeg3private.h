/* Changed Sept 15th by John M McIntosh to support Macintosh & Squeak
 * Changed 2015/1/30 by Eliot Miranda to include memoryAllocate/memoryFree decls
 */

#ifndef MPEG3PRIVATE_H
#define MPEG3PRIVATE_H

void * memoryAllocate(int number,unsigned size);
void memoryFree(void *stuff);

/** configuration **/
#if defined(__MWERKS__)
#define TARGET_MAC_OS 1
#endif

/* how should functions be inlined? */
#ifndef INLINE
#ifdef TARGET_MAC_OS
#define INLINE
#else
#define INLINE inline
#endif
#endif

#ifdef _MSC_VER
/* disallow INLINE since those functions cannot be linked */
#undef INLINE
#define INLINE
#endif

/* use pthreads? */
#ifndef NOPTHREADS
#ifndef TARGET_MAC_OS
#define USE_PTHREADS
#endif
#endif


#include "mpeg3atrack.h"
#include "mpeg3css.h"
#include "mpeg3io.h"
#include "mpeg3private.inc"
#include "mpeg3title.h"
#include "mpeg3vtrack.h"

typedef struct
{
	mpeg3_fs_t *fs;      /* Store entry path here */
	mpeg3_demuxer_t *demuxer;        /* Master tables */

/* Media specific */
	int has_audio;
	int has_video;
	int total_astreams;
	int total_vstreams;
	mpeg3_atrack_t *atrack[MPEG3_MAX_STREAMS];
	mpeg3_vtrack_t *vtrack[MPEG3_MAX_STREAMS];

/* Only one of these is set to 1 to specify what kind of stream we have. */
	int is_transport_stream;
	int is_program_stream;
	int is_audio_stream;         /* Elemental stream */
	int is_video_stream;         /* Elemental stream */
	long packet_size;
/* Type and stream for getting current percentage */
	int last_type_read;  /* 1 - audio   2 - video */
	int last_stream_read;

	int program;  /* Number of program to play */
	int cpus;
	int have_mmx;
} mpeg3_t;




#endif
