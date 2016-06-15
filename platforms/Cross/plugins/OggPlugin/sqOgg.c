/* sqOgg.c -- Ogg Vorbis plugin
 *
 * Copyright (c) 2006 Takashi Yamamiya
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <time.h>
#include <speex/speex_header.h>
#include "OggPlugin.h"

static time_t thisSession;

/************************************************************
 * Squeak Interface
 *************************************************************/

/* Validate SqOgg pointer
 * - oggp : [in] SqOggPtr
 * return value: SqOgg object or
 *               NULL if it is invalid object.
 */
SqOgg * validate(SqOggPtr * oggp)
{
  if ((oggp != NULL) &&
      (oggp->ogg != NULL) &&
      (oggp->sessionID == thisSession)) {
    return oggp->ogg;
  } else {
    return NULL;
  }
}

/************************************************************
 * Low level Ogg operation
 *************************************************************/

/* Set new data to the buffer
 * - buffer : [in] data
 * - size: [in] size of the data
 */
void writeBuffer(SqOgg * ogg, const char * buffer, size_t bytes)
{
  char * ogg_buffer= ogg_sync_buffer(&ogg->sync_state, bytes);
  memcpy(ogg_buffer, buffer, bytes);
  ogg_sync_wrote(&ogg->sync_state, bytes);
}

/* Get next page and set into ogg->page
 * return value : SQ_OGG_SUCCESS if successed
 *                SQ_OGG_NEED_MORE if more data is needed
 */
int get_next_page(SqOgg * ogg)
{
  /* get a page from the buffer */
  int result= ogg_sync_pageout(&ogg->sync_state, &ogg->page); 

  if (result == 0) return SQ_OGG_NEED_MORE; /* need more data */
  if (result < 0) { /* missing or corrupt data at this page position */
    fprintf(stderr,"Corrupt or missing data in bitstream; "
            "continuing...\n");
    return SQ_OGG_NEED_MORE;
  }
  if (ogg->page_callback) (ogg->page_callback)(&ogg->page);
  return SQ_OGG_SUCCESS;
}

/* Get next packet
 * - packet : [out] next pakcet
 * return value : SQ_OGG_SUCCESS if successed
 *                SQ_OGG_NEED_MORE if more data is needed
 */
int SqOggPacketNext(SqOggPtr * oggp, ogg_packet * packet)
{
  int result;
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return SQ_OGG_ERROR; /* UNDOCUMENTED */
  while(1) {
    if (ogg->packetStatus == SQ_STREAM_INITIALIZED) {
      result= ogg_stream_packetout(&ogg->stream_state, packet);
      if (result == 1) {
        return SQ_OGG_SUCCESS;
      } else if (result == -1) {
        /* There are a gap (TODO: maybe SQ_OGG_ERROR is better, but
           because the caller doesn't handle the error well.) */
        return SQ_OGG_NEED_MORE;
      }
    }
    result= get_next_page(ogg);
    if (result == SQ_OGG_NEED_MORE) return SQ_OGG_NEED_MORE;

    if (ogg->packetStatus == SQ_STREAM_UNINITIALIZED) {
      /* Initialize the logical stream */
      ogg_stream_init(&ogg->stream_state, ogg_page_serialno(&ogg->page));
      ogg->packetStatus= SQ_STREAM_INITIALIZED;
    }
    /* build packets from the page */
    ogg_stream_pagein(&ogg->stream_state, &ogg->page);
  }
}

/************************************************************
 * SqOggResult Object
 *************************************************************/

/* Add new buffer in a list with specific size
 * - head : [in] top of the list, or NULL
 * - size : [in] the size of the buffer in bytes
 * return value : allocated object
 */
SqOggResult * SqOggResultNewBuffer(SqOggResult * head, int size)
{
  SqOggResult * object= (SqOggResult *) malloc(sizeof(SqOggResult));
  object->buffer= (char *) malloc(sizeof(char) * size);
  object->size= size;
  object->next= NULL;
  if (head != NULL) {
    SqOggResult * tail;
    for (tail= head; tail->next != NULL; tail= tail->next);
    tail->next= object;
  }
  return object;
}

/* Allocate new buffer for result.
 * - size : [in] size of required buffer
 */
void * requestBuffer(SqOgg * ogg, size_t size)
{
  SqOggResult * bufferNode=
    SqOggResultNewBuffer(ogg->resultList, size);
  if (ogg->resultList == NULL) {
    ogg->resultList= bufferNode;
  }
  return bufferNode->buffer;
}

/* Destroy list of buffers
 * - head : [in] top of the list
 */
void SqOggResultDestroy(SqOggResult * head)
{
  if (head->next != NULL) {
    SqOggResultDestroy(head->next);
    head->next= NULL;
  }
  free(head->buffer);
  head->buffer= NULL;
  free(head);
};

/* Copy all of the buffer.
 * The size of dest should be the result of SqOggReadSize()
 * - head       : [in] top of the list
 * - dest       : [out] flatten buffers
 * - size       : [in] size of dest.
 * return value : written size
 */
int SqOggResultCopy(SqOggResult * head, char * dest, int size)
{
  int pos= 0;
  SqOggResult * each;
  for (each= head; each != NULL; each= each->next) {
    int eachSize= each->size < (size - pos) ? each->size : (size - pos);
    memcpy(dest + pos, each->buffer, sizeof(char) * eachSize);
    pos= pos + eachSize;
    if (pos >= size) break;
  }
  return pos;
};

/* write result buffer to the file handle (debug use)
 * - file : [in] file handle
 */
void SqOggResultWrite(SqOggPtr * oggp, FILE * file)
{
  char * buf;
  int bytes;
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return;

  bytes= SqOggReadSize(oggp);
  if (bytes == 0) return;
  buf= (char *) malloc(bytes);
  SqOggRead(oggp, buf, bytes);
  fwrite(buf, 1, bytes, file);
}

/************************************************************
 * Low level Vorbis operation
 *************************************************************/

/* Process vorbis header
 * return value : SQ_OGG_SUCCESS if the header is complete
 *                SQ_OGG_NEED_MORE if more data is needed (not error)
 *                SQ_OGG_ERROR_HEADER if fatal error
 */
int vorbisDecodeHeader(SqOggPtr * oggp)
{
  ogg_packet packet;
  int result;
  SqVorbis * v;
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return SQ_OGG_ERROR_HEADER;
  v= ogg->vorbis;

  if (ogg->state == SQ_OGG_RUNNING) return SQ_OGG_SUCCESS;

  //  memset(&packet, 0, sizeof(packet));
  if (ogg->state == SQ_OGG_INITIALIZED) {
    if (SqOggPacketNext(oggp, &packet) == SQ_OGG_NEED_MORE) return SQ_OGG_NEED_MORE;
    result= vorbis_synthesis_headerin(&v->vinfo, &v->comment, &packet);
    if (result != 0) return SQ_OGG_ERROR_HEADER;
    ogg->state= SQ_VORBIS_GOT_INFO;
  }
  if (ogg->state == SQ_VORBIS_GOT_INFO) {
    if (SqOggPacketNext(oggp, &packet) == SQ_OGG_NEED_MORE) return SQ_OGG_NEED_MORE;
    result= vorbis_synthesis_headerin(&v->vinfo, &v->comment, &packet);
    if (result != 0) return SQ_OGG_ERROR_HEADER;
    ogg->state= SQ_VORBIS_GOT_COMMENT;
  }
  if (ogg->state == SQ_VORBIS_GOT_COMMENT) {
    if (SqOggPacketNext(oggp, &packet) == SQ_OGG_NEED_MORE) return SQ_OGG_NEED_MORE;
    result= vorbis_synthesis_headerin(&v->vinfo, &v->comment, &packet);
    if (result != 0) return SQ_OGG_ERROR_HEADER;
    ogg->channels= v->vinfo.channels;
    ogg->rate= v->vinfo.rate;
    vorbis_synthesis_init(&v->dsp_state, &v->vinfo);
    vorbis_block_init(&v->dsp_state,&v->block);
    ogg->state= SQ_OGG_RUNNING;
    return SQ_OGG_SUCCESS;
  }
  return SQ_OGG_NEED_MORE;
}

/* Get next pcm buffer
 * return value : SQ_OGG_SUCCESS if success
 *                SQ_OGG_ERROR_HEADER if error in header process
 *                SQ_OGG_ERROR_BODY if error in body process
 */
int vorbisDecode(SqOggPtr * oggp)
{
  int channelsize;
  SqVorbis * v;
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return SQ_OGG_ERROR /* UNDOCUMENTED */;
  v= ogg->vorbis;
  
  if (ogg->state != SQ_OGG_RUNNING) {
    int result= vorbisDecodeHeader(oggp);
    if (result == SQ_OGG_NEED_MORE) return SQ_OGG_SUCCESS;
    if (result == SQ_OGG_ERROR_HEADER) return SQ_OGG_ERROR_HEADER;
  }
  
  channelsize= v->vinfo.channels;

  while(1) {
    ogg_packet packet;
    if (SqOggPacketNext(oggp, &packet) == SQ_OGG_NEED_MORE) break;
    if(vorbis_synthesis(&v->block, &packet) == 0) {
      vorbis_synthesis_blockin(&v->dsp_state, &v->block);
    } else {
      fprintf(stderr, "ERROR!\n");
      return SQ_OGG_ERROR_BODY;
    }
  
    while(1){
      int pos;
      int channel;
      float **pcm;
      SqOggResult * bufferNode;
      ogg_int16_t * buffer;
      int samples= vorbis_synthesis_pcmout(&v->dsp_state, &pcm);
      if (samples <= 0) break;
      
      bufferNode=
        SqOggResultNewBuffer(ogg->resultList, sizeof(ogg_int16_t) * samples * channelsize);
      if (ogg->resultList == NULL) {
        ogg->resultList= bufferNode;
      }
      buffer= (ogg_int16_t *) bufferNode->buffer;
      
      /* convert floats to 16 bit signed ints little endian
	 interleave */
      for(channel= 0; channel < channelsize; channel++) {
	for(pos= 0; pos < samples; pos++) {
	  int val= pcm[channel][pos] * 32767.f;
	  
	  /* might as well guard against clipping */
	  if (val > 32767) val= 32767;
	  if (val < -32768) val= -32768;
	  
	  /* write in interleave platform endian */
	  buffer[pos * channelsize + channel]= val;
	}
      }
      vorbis_synthesis_read(&v->dsp_state, samples);
    }
  }
  return SQ_OGG_SUCCESS;
}

/* write the logical stream into the result list
 * - ogg : ogg state
 * - func :ogg_stream_flush or ogg_stream_pageout
 */
void outputEncoded(SqOgg * ogg, int (*func)(ogg_stream_state *os, ogg_page *og))
{
  while(1){
    ogg_page page;
    int size;
    SqOggResult * bufferNode;
    int result= func(&ogg->stream_state, &page);
    if (result == 0) {
      break;
    }
    size= page.header_len + page.body_len;
    bufferNode=
      SqOggResultNewBuffer(ogg->resultList, size);
    if (ogg->resultList == NULL) {
      ogg->resultList= bufferNode;
    }
    memcpy(bufferNode->buffer, page.header, page.header_len);
    memcpy(bufferNode->buffer + page.header_len, page.body, page.body_len);
  }
}

/* Output vorbis header */
int vorbisEncodeHeader(SqOgg * ogg)
{
  ogg_packet header;
  ogg_packet header_comm;
  ogg_packet header_code;

  {
    int result= vorbis_encode_init_vbr(&ogg->vorbis->vinfo, ogg->channels, ogg->rate, ogg->quality);
    if (result != 0) return SQ_OGG_ERROR_HEADER;
    vorbis_analysis_init(&ogg->vorbis->dsp_state, &ogg->vorbis->vinfo);
  }
  
  vorbis_comment_init(&ogg->vorbis->comment);
  vorbis_comment_add_tag(&ogg->vorbis->comment, "ENCODER", "Squeak");
  
  /* write info and headers into three packets */
  vorbis_analysis_headerout(&ogg->vorbis->dsp_state, &ogg->vorbis->comment, &header, &header_comm, &header_code);
  vorbis_comment_clear(&ogg->vorbis->comment);

  /* write three packets into the logical stream */
  ogg_stream_packetin(&ogg->stream_state, &header);
  ogg_stream_packetin(&ogg->stream_state, &header_comm);
  ogg_stream_packetin(&ogg->stream_state, &header_code);

  outputEncoded(ogg, ogg_stream_flush);
  ogg->state= SQ_OGG_RUNNING;
  return SQ_OGG_SUCCESS;
}

/* Write encoded vorbis stream to packets */

void vorbisPacketWrite(SqOgg * ogg)
{
  /* vorbis does some data preanalysis, then divvies up blocks for
     more involved (potentially parallel) processing.  Get a single
     block for encoding now */
  vorbis_block block; /* TODO!!!! */
  vorbis_block_init(&ogg->vorbis->dsp_state, &block);
  
  while(vorbis_analysis_blockout(&ogg->vorbis->dsp_state, &block) == 1) {
    ogg_packet packet; /* one raw packet of data for decode */
    
    vorbis_analysis(&block, NULL);
    vorbis_bitrate_addblock(&block);
    
    /* Write dsp state to a packet. */
    while(vorbis_bitrate_flushpacket(&ogg->vorbis->dsp_state, &packet)) {
      /* Write a packet to logical stream */
      ogg_stream_packetin(&ogg->stream_state, &packet);
    }
    /* Write logical stream to page */
    outputEncoded(ogg, ogg_stream_pageout);
  }
  vorbis_block_clear(&block);
}

/* Encode vorbis body
 * - buffer : [in] sound data
 * - size : [in] buffer size in bytes
 */
int vorbisEncode(SqOggPtr * oggp, ogg_int16_t * readbuffer, int size)
{
  int channelsize;
  int framesize;
  float ** buffer;
  long i, c;
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return 0;

  if (ogg->state != SQ_OGG_RUNNING) {
    if (vorbisEncodeHeader(ogg) == SQ_OGG_ERROR_HEADER) return SQ_OGG_ERROR_HEADER;
  }

  channelsize= ogg->vorbis->vinfo.channels;
  framesize= size / (sizeof(ogg_int16_t) * channelsize);
  buffer= vorbis_analysis_buffer(&ogg->vorbis->dsp_state, framesize);

  /* platform endian uninterleave samples */
  for(i = 0; i < framesize; i++) {
    for (c= 0; c < channelsize; c++) {
      buffer[c][i]= readbuffer[i * channelsize + c] /32768.f;
    }
  }
  vorbis_analysis_wrote(&ogg->vorbis->dsp_state, framesize);
  vorbisPacketWrite(ogg);
  return SQ_OGG_SUCCESS;
}

/* output end of stream */
void vorbisEOS(SqOgg * ogg)
{
  vorbis_analysis_wrote(&ogg->vorbis->dsp_state, 0);
  vorbisPacketWrite(ogg);
}

/************************************************************
 * Low level Speex interface
 *************************************************************/

/* Initialize Speex encoder */
SqSpeex * SqSpeexEncoder()
{
  SqSpeex * speex;
  speex= (SqSpeex *) calloc(1, sizeof(SqSpeex));
  speex->remainSize= 0;
  return speex;
}

/* Initialize Speex decoder from a packet
 * - packet : source packet
 * return value: a pointer of SqSpeex
 *             : NULL if error
 */
SqSpeex * SqSpeexDecoder(ogg_packet * packet)
{
  SqSpeex * speex;
  int modeID;
  SpeexMode * mode;
  SpeexHeader * header;
  SpeexState speexState;
  int channels;

  speex= (SqSpeex *) calloc(1, sizeof(SqSpeex));
  
  header = speex_packet_to_header((char *) packet->packet, packet->bytes);
  if (!header) {
    return NULL;
  }
  modeID= header->mode;
  mode= speex_lib_get_mode(modeID);
  speexState= speex_decoder_init(mode);
  if (!speexState) {
    return NULL;
  }
  speex_decoder_ctl(speexState, SPEEX_SET_SAMPLING_RATE, &header->rate);
  channels= header->nb_channels;
  free(header);
  if (channels != 1) return NULL; /* only supports mono channel */
  speex->state= speexState;
  speex_bits_init(&speex->bits);
  return speex;
}

/* Decode a chunk
 * speex : Speex decoder
 * buffer : compressed data
 * bytes : size of the buffer in bytes
 * return value : size of decoded sound in bytes
 */
int SqSpeexDecodeWrite(SqSpeex * speex, char * buffer, size_t bytes)
{
  int frame_size;
  speex_bits_read_from(&speex->bits, buffer, bytes);
  speex_decoder_ctl(speex->state, SPEEX_GET_FRAME_SIZE, &frame_size); 
  return frame_size * 2;
}

/* Get decoded sound, SqSpeexDecodeWrite() should be called before this.
 * speex : Speex decoder
 * buffer : sound buffer
 * bytes : size of the buffer in bytes
 */
void SqSpeexDecodeRead(SqSpeex * speex, char * buffer)
{
  speex_decode_int(speex->state, &speex->bits, (short *) buffer);
}

/************************************************************
 * Ogg Speex interface
 *************************************************************/

/* Decode Ogg Speex packet in the buffer
 */
int speexDecode(SqOggPtr * oggp)
{
  ogg_packet packet;
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return SQ_OGG_ERROR;

  while (1) {
    if (SqOggPacketNext(oggp, &packet) == SQ_OGG_NEED_MORE) return SQ_OGG_SUCCESS;
    if (ogg->state == SQ_OGG_INITIALIZED) {
      ogg->speex= SqSpeexDecoder(&packet);
      if (ogg->speex == NULL) return SQ_OGG_ERROR_HEADER;
      speex_decoder_ctl(ogg->speex->state, SPEEX_GET_SAMPLING_RATE, &ogg->rate);
      ogg->channels= 1; /* now only supports mono channel */
      ogg->state= SQ_SPEEX_GOT_INFO;
    } else if (ogg->state == SQ_SPEEX_GOT_INFO) {
      /* process comment (but not implemented yet */
      ogg->state= SQ_OGG_RUNNING;
    } else if (ogg->state == SQ_OGG_RUNNING) {
      short * decompressed;
      int sound_size= SqSpeexDecodeWrite(ogg->speex, (char *) packet.packet, packet.bytes);
      decompressed = (short *) requestBuffer(ogg, sound_size);
      SqSpeexDecodeRead(ogg->speex, (char *) decompressed);
    }
  }
}

/* Build dummy comment structure.
 * Now this library doesn't support comment in speex.
 * It genarates just a placeholder for the second packet.
 * It was copied from speexenc.c in speex-1.0.5 dist.
 */
#define writeint(buf, base, val) do{ buf[base+3]=((val)>>24)&0xff; \
                                     buf[base+2]=((val)>>16)&0xff; \
                                     buf[base+1]=((val)>>8)&0xff; \
                                     buf[base]=(val)&0xff; \
                                 }while(0)

void comment_init(char **comments, int* length, char *vendor_string)
{
  int vendor_length=strlen(vendor_string);
  int user_comment_list_length=0;
  int len=4+vendor_length+4;
  char *p=(char*)malloc(len);
  if(p==NULL){
  }
  writeint(p, 0, vendor_length);
  memcpy(p+4, vendor_string, vendor_length);
  writeint(p, 4+vendor_length, user_comment_list_length);
  *length=len;
  *comments=p;
}
#undef writeint

void speexEncodeHeader(SqOggPtr * oggp)
{
   SpeexHeader header;
   SpeexMode *mode= NULL;
   int modeID= SPEEX_MODEID_WB;
   int nframes= 1;
   ogg_packet packet;
   int rate;
   int nb_channels;
   int quality;

  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return;

   rate= ogg->rate;
   nb_channels= ogg->channels;
   quality= ogg->quality;

   if (rate > 25000) {
     modeID = SPEEX_MODEID_UWB;
   } else if (rate > 12500) {
     modeID = SPEEX_MODEID_WB;
   } else {
     modeID = SPEEX_MODEID_NB;
   }
   mode = speex_lib_get_mode (modeID);

   speex_init_header(&header, rate, nb_channels, mode);
   header.frames_per_packet= nframes;
   header.vbr= 0;
   header.nb_channels= nb_channels;

   packet.packet = (unsigned char *) speex_header_to_packet(&header,
                                                            (int*) &(packet.bytes));
   packet.b_o_s = 1;
   packet.e_o_s = 0;
   packet.granulepos = 0;
   packet.packetno = 0;
   SqOggPacketWrite(oggp, &packet);
   free(packet.packet);

   ogg->speex->state = speex_encoder_init(mode);
   speex_encoder_ctl(ogg->speex->state, SPEEX_SET_SAMPLING_RATE, &rate);
   speex_encoder_ctl(ogg->speex->state, SPEEX_SET_QUALITY, &quality);
   speex_bits_init(&ogg->speex->bits);

   {
     char *comments;
     int comments_length;
     char *vendor_string = "Encoded with Squeak";
     comment_init(&comments, &comments_length, vendor_string);
     
     packet.packet = (unsigned char *)comments;
     packet.bytes = comments_length;

     packet.b_o_s = 0;
     packet.e_o_s = 0;
     packet.granulepos = 0;
     packet.packetno = 1;
   }

   SqOggPacketWrite(oggp, &packet);
   SqOggPacketFlush(oggp);
   ogg->state= SQ_OGG_RUNNING;
}

/* Encode Ogg Speex packet in the buffer
 * - buffer : [in] sound data
 * - bytes : [in] size of the data in bytes
 */
int speexEncode(SqOggPtr * oggp, const char * buffer, size_t bytes)
{
  int frameSize;
  ogg_int16_t * source;
  int totalFrame;
  int written= 0; /* written sound size in frames */
  SqSpeex * spx;
  ogg_packet packet;

  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return SQ_OGG_ERROR;
  spx= ogg->speex;

  if (ogg->state != SQ_OGG_RUNNING) speexEncodeHeader(oggp);

  /* Copy given sound + remain sound to working buffer */
  totalFrame= bytes / sizeof(ogg_int16_t) + spx->remainSize;
  source= (ogg_int16_t *) malloc(sizeof(ogg_int16_t) * totalFrame);
  memcpy(source, spx->remain, sizeof(ogg_int16_t) * spx->remainSize);
  memcpy(source + spx->remainSize, buffer, bytes);

  speex_encoder_ctl(spx->state, SPEEX_GET_FRAME_SIZE, &frameSize); 
  /* Send each frame */
  for (written= 0; totalFrame - written >= frameSize; written += frameSize) {
    int nbBytes;
    unsigned char * encoded;
    speex_bits_reset(&spx->bits);
    speex_encode_int(spx->state, source + written, &spx->bits);
    nbBytes= speex_bits_nbytes(&spx->bits);
    encoded = (unsigned char *)malloc(nbBytes);
    //    speex_bits_insert_terminator(&spx->bits);
    speex_bits_write(&spx->bits, (char *) encoded, nbBytes); /* write data */
    packet.packet= encoded;
    packet.bytes= nbBytes;
    packet.e_o_s= 0;
    SqOggPacketWrite(oggp, &packet);
    free(encoded);
  }
  spx->remainSize= totalFrame - written;
  memcpy(spx->remain, source + written, sizeof(ogg_int16_t) * spx->remainSize);
  return SQ_OGG_SUCCESS;
}

/************************************************************
 * Low level Ogg interface
 *************************************************************/

void SqOggPacketWrite(SqOggPtr * oggp, ogg_packet * packet)
{
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return;

  if (ogg->packetStatus == SQ_STREAM_UNINITIALIZED) {
    packet->b_o_s= 1;
    ogg->packetStatus= SQ_STREAM_BEGAN;
  }
  ogg_stream_packetin(&ogg->stream_state, packet);
  outputEncoded(ogg, ogg_stream_pageout);
}

/* Write end of stream packet
 */
void SqOggPacketWriteEOS(SqOggPtr * oggp)
{
  ogg_packet packet;
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return;

  packet.packet = NULL;
  packet.bytes = 0;
  packet.b_o_s = 0;
  packet.e_o_s = 1;
  SqOggPacketWrite(oggp, &packet);
}

void SqOggPacketFlush(SqOggPtr * oggp)
{
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return;
  outputEncoded(ogg, ogg_stream_flush);
}

/************************************************************
 * Basic Ogg Vorbis / Speex buffer operations
 *************************************************************/
/* Initialize vorbis encoder */
SqVorbis * initVorbis()
{
  SqVorbis * vorbis= (SqVorbis *) calloc(1, sizeof(SqVorbis));
  vorbis_info_init(&vorbis->vinfo);
  vorbis_comment_init(&vorbis->comment);
  return vorbis;
}

/* Create new instance of decoder
 * mode - [in]  open mode
 * oggp - [out] built object pointer
 * return value: an initialized struct
 */
void SqOggOpen(int mode, SqOggPtr * oggp)
{
  SqOgg * ogg = (SqOgg *) calloc(1, sizeof(SqOgg));
  ogg_sync_init(&ogg->sync_state);
  ogg->packetStatus= SQ_STREAM_UNINITIALIZED;
  ogg->state= SQ_OGG_INITIALIZED;
  ogg->resultList= NULL;

  ogg->mode= mode;
  if (mode & SQ_OGG_ENCODE) {
    ogg_stream_init(&ogg->stream_state, 0x999); /* initialize logical stream */
  }
  if (ogg->mode == (SQ_SPEEX | SQ_OGG_ENCODE)) {
    ogg->speex= SqSpeexEncoder();
    ogg->rate= 16000;
    ogg->channels= 1;
    ogg->quality= 8;
  }
  if (ogg->mode & SQ_VORBIS) {
    ogg->vorbis= initVorbis();
    ogg->rate= 22050;
    ogg->channels= 1;
    ogg->quality= 0.1;
  }
  if (! thisSession) {
    thisSession= time(NULL);
  }
  oggp->sessionID= thisSession;
  oggp->ogg= ogg;
}

/* Encode or Decode process
 * - buffer     : [in] data
 * - bytes      : [in] size of the data
 * return value : SQ_OGG_SUCCESS if success
 *                SQ_OGG_ERROR_HEADER if error in header process
 *                SQ_OGG_ERROR_BODY if error in body process
 */
int SqOggWrite(SqOggPtr * oggp, const char * buffer, size_t bytes)
{
  int result= SQ_OGG_SUCCESS;
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return SQ_OGG_ERROR;

  if (ogg->mode == (SQ_VORBIS | SQ_OGG_ENCODE)) {
    result= vorbisEncode(oggp, (ogg_int16_t *) buffer, bytes);
  } else if (ogg->mode == (SQ_SPEEX | SQ_OGG_ENCODE)) {
    result= speexEncode(oggp, buffer, bytes);
  } else if (ogg->mode == (SQ_VORBIS | SQ_OGG_DECODE)) {
    writeBuffer(ogg, buffer, bytes);
    result= vorbisDecode(oggp);
  } else if (ogg->mode == (SQ_SPEEX | SQ_OGG_DECODE)) {
    writeBuffer(ogg, buffer, bytes);
    result= speexDecode(oggp);
  } else {
    writeBuffer(ogg, buffer, bytes); /* It is also used in test/packet.c */
  }
  return result;
}

/* Get the size of result buffer
 * return value : size
 */
size_t SqOggReadSize(SqOggPtr * oggp)
{
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return 0;
  return SqOggResultSize(ogg->resultList);
}

/* Get flatten size of the buffers
 * - head       : [in] top of the list
 * return value : size
 */
int SqOggResultSize(SqOggResult * head)
{
  SqOggResult * each;
  int size= 0;
  for (each= head; each != NULL; each= each->next) {
    size= size + each->size;
  }
  return size;
};

/* Read the result, and cleanup buffer.
 * - dest : buffer to store the result
 * - bytes : size of the result buffer
 * return value: actually written size (in bytes)
 */ 
size_t SqOggRead(SqOggPtr * oggp, char * dest, size_t bytes)
{
  int result;
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return 0;

  if (ogg->resultList == NULL) return 0;
  result= SqOggResultCopy(ogg->resultList, dest, bytes);
  SqOggResultDestroy(ogg->resultList);
  ogg->resultList= NULL;
  return result;
}

/* Write End Of Stream packet.  */
void SqOggWriteEOS(SqOggPtr * oggp)
{
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return;

  if (ogg->mode & SQ_VORBIS) {
    vorbisEOS(ogg);
  } else {
    SqOggPacketWriteEOS(oggp);
  }
}

/* Destroy the instance */
void SqOggClose(SqOggPtr * oggp)
{
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return;
  ogg_sync_clear(&ogg->sync_state);
  if (ogg->mode & SQ_SPEEX) free(ogg->speex);
  if (ogg->mode & SQ_VORBIS) {
    vorbis_info_clear(&ogg->vorbis->vinfo);
    vorbis_comment_clear(&ogg->vorbis->comment);
    free(ogg->vorbis);
  }
  oggp->sessionID= 0;
  oggp->ogg= NULL;
  free(ogg);
}

/************************************************************
 * Accessors
 *************************************************************/

/* Set size of channels */
void SqOggSetChannels(SqOggPtr * oggp, int channels)
{
  if(validate(oggp) == NULL) return;
  oggp->ogg->channels= channels;
}
/* Set rate */
void SqOggSetRate(SqOggPtr * oggp, int rate)
{
  if(validate(oggp) == NULL) return;
  oggp->ogg->rate= rate;
}
/* Set quality */
void SqOggSetQuality(SqOggPtr * oggp, float quality)
{
  if(validate(oggp) == NULL) return;
  oggp->ogg->quality= quality;
}
/* Get rate */
int SqOggGetRate(SqOggPtr * oggp)
{
  if(validate(oggp) == NULL) return SQ_OGG_ERROR;
  return oggp->ogg->rate;
}
/* Get size of channles */
int SqOggGetChannels(SqOggPtr * oggp)
{
  if(validate(oggp) == NULL) return SQ_OGG_ERROR;
  return oggp->ogg->channels;
}
/* Get vendor name */
int SqOggGetVendor(SqOggPtr * oggp, char * dest, size_t size)
{
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return SQ_OGG_ERROR;

  if (!(ogg->mode & SQ_VORBIS)) return SQ_OGG_ERROR;
  if (ogg->state != SQ_OGG_RUNNING) return SQ_OGG_NEED_MORE;
  strncpy(dest, ogg->vorbis->comment.vendor, size);
  return SQ_OGG_SUCCESS;
}

/* Answer comments */
int SqOggGetComment(SqOggPtr * oggp, char * dest, size_t size)
{
  int pos= 0;
  char **ptr;
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return SQ_OGG_ERROR;

  if (!(ogg->mode & SQ_VORBIS)) return SQ_OGG_ERROR;
  if (ogg->state != SQ_OGG_RUNNING) return SQ_OGG_NEED_MORE;
  ptr= ogg->vorbis->comment.user_comments;
  while(*ptr){
    int eachSize= strlen(*ptr) + 1;
    eachSize= (eachSize < size - pos) ? eachSize : (size - pos);
    strncpy(dest + pos, *ptr, eachSize);
    pos= pos + eachSize;
    if (pos >= size) return SQ_OGG_SUCCESS;
    ++ptr;
  }
  return SQ_OGG_SUCCESS;
}

/* Get length of comments */
int SqOggGetCommentSize(SqOggPtr * oggp)
{
  int pos= 0;
  char **ptr;
  SqOgg * ogg= validate(oggp);
  if (ogg == NULL) return SQ_OGG_ERROR;

  if (!(ogg->mode & SQ_VORBIS)) return SQ_OGG_ERROR;
  if (ogg->state != SQ_OGG_RUNNING) return SQ_OGG_NEED_MORE;
  ptr=ogg->vorbis->comment.user_comments;
  while(*ptr){
    pos= pos + strlen(*ptr) + 1;
    ++ptr;
  }
  return pos;
}

/* Answer pcm state */
int SqOggGetState(SqOggPtr * oggp)
{
  if(validate(oggp) == NULL) return SQ_OGG_ERROR;
  return oggp->ogg->state;
}
