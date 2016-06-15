/* header for OggPlugin */

#include <vorbis/codec.h>
#include <vorbis/vorbisenc.h>
#include <speex/speex.h>
#include <stdio.h>

/* Result status */
#define SQ_OGG_SUCCESS 0
#define SQ_OGG_NEED_MORE -1
#define SQ_OGG_ERROR -2
#define SQ_OGG_ERROR_HEADER -3
#define SQ_OGG_ERROR_BODY -4

/* Hi level codec state */
#define SQ_OGG_INITIALIZED 1
#define SQ_VORBIS_GOT_INFO 2
#define SQ_SPEEX_GOT_INFO 2
#define SQ_VORBIS_GOT_COMMENT 3
#define SQ_OGG_RUNNING 4 /* Codec header is successfully processed */

/* Low level packet state */
#define SQ_STREAM_UNINITIALIZED 0
#define SQ_STREAM_BEGAN 1 /* b_o_f was written in encoding */
#define SQ_STREAM_INITIALIZED 2 /* serial number was gotten in decoding */

/* Open mode */
#define SQ_OGG_ENCODE 1
#define SQ_OGG_DECODE 2
#define SQ_VORBIS 4
#define SQ_SPEEX 8

typedef void * SpeexState;

/* a buffer for output of the result */
typedef struct _SqOggResult {
  char * buffer;
  size_t size;   /* size of the buffer */
  struct _SqOggResult * next;   /* next buffer, or NULL */
} SqOggResult;

/* Speex codec object */
typedef struct _SqSpeex {
  SpeexBits bits;
  SpeexState state;
  ogg_int16_t remain[1024]; /* remain sound buffer */
  int remainSize; /* remain sound buffer size in frames */
} SqSpeex;

/* Vorbis codec object */
typedef struct _SqVorbis {
  vorbis_info vinfo;
  vorbis_comment comment;

  vorbis_dsp_state dsp_state;
  vorbis_block     block;
} SqVorbis;

/* Encoder | Decoder status object */
typedef struct _SqOgg {
  int mode; /* ogg | vorbis + decode | encode */

  ogg_sync_state sync_state;
  ogg_stream_state stream_state;
  ogg_page page; /* the current proccessing page */
  void (* page_callback) (ogg_page *);

  int channels;
  int rate;
  float quality;

  int packetStatus;
  int state;

  SqVorbis * vorbis;
  SqSpeex * speex;

  SqOggResult * resultList;
} SqOgg;

/* SqOggPtr is used to pass SqOgg pointer to Squeak image.  The
 * structure is copied as a ByteArray object so that the ByteArray
 * keeps a pair of {sessionID, ogg}.  SqOggPtr is checked the
 * sessionID whether if the pointer is valid in current session when
 * it is called to avoid segfault error.
 */
typedef struct _SqOggPtr {
  int sessionID;
  SqOgg * ogg;
} SqOggPtr;

/* Basic buffer oparations for Ogg Vorbis | Speex */
void SqOggOpen(int mode, SqOggPtr * oggp);
int SqOggWrite(SqOggPtr * ogg, const char * buffer, size_t bytes);
size_t SqOggReadSize(SqOggPtr * ogg);
size_t SqOggRead(SqOggPtr * ogg, char * dest, size_t bytes);
void SqOggWriteEOS(SqOggPtr * ogg);
void SqOggClose(SqOggPtr * oggp);

/* Accessors */
int  SqOggGetChannels(SqOggPtr * ogg);
void SqOggSetChannels(SqOggPtr * ogg, int channels);
int  SqOggGetRate(SqOggPtr * ogg);
void SqOggSetRate(SqOggPtr * ogg, int rate);

int SqOggGetVendor(SqOggPtr * ogg, char * dest, size_t size);
int SqOggGetCommentSize(SqOggPtr * ogg);
int SqOggGetComment(SqOggPtr * ogg, char * dest, size_t size);
void SqOggSetQuality(SqOggPtr * ogg, float quality);
int SqOggGetState(SqOggPtr * ogg);

/* Low level ogg interface */
void SqOggPacketWrite(SqOggPtr * ogg, ogg_packet * packet);
void SqOggPacketWriteEOS(SqOggPtr * ogg);
int  SqOggPacketNext(SqOggPtr * ogg, ogg_packet * packet);
void SqOggPacketFlush(SqOggPtr * ogg);
int  SqOggPacketRead(SqOggPtr * ogg, ogg_packet * packet);

/* Result buffer (only for unit test) */
SqOggResult * SqOggResultNewBuffer(SqOggResult * head, int size);
void SqOggResultDestroy(SqOggResult * head);
int  SqOggResultCopy(SqOggResult * head, char * dest, int size);
void SqOggResultWrite(SqOggPtr * ogg, FILE * file);
int  SqOggResultSize(SqOggResult * head);

/* Low level speex interface. These are available for future use of
 * speex directly (speex is not depend on ogg container).
 */
SqSpeex * SqSpeexDecoder(ogg_packet * packet);
int SqSpeexDecodeWrite(SqSpeex * speex, char * buffer, size_t size);
void SqSpeexDecodeRead(SqSpeex * speex, char * buffer);
