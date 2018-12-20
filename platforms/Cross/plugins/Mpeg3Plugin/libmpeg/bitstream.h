#ifndef BITSTREAM_H
#define BITSTREAM_H

#include "mpeg3demux.h"

//                                    next bit in forward direction
//                                  next bit in reverse direction |
//                                                              v v
// | | | | | | | | | | | | | | | | | | | | | | | | | | |1|1|1|1|1|1| */
//                                                     ^         ^
//                                                     |         bit_number = 1
//                                                     bfr_size = 6

typedef struct
{
	unsigned MPEG3_INT32 bfr;  /* bfr = buffer for bits */
	int bit_number;   /* position of pointer in bfr */
	int bfr_size;    /* number of bits in bfr.  Should always be a multiple of 8 */
	void *file;    /* Mpeg2 file */
	mpeg3_demuxer_t *demuxer;   /* Mpeg2 demuxer */
/* If the input ptr is true, data is read from it instead of the demuxer. */
	unsigned char *input_ptr;
} mpeg3_bits_t;

unsigned int mpeg3demux_read_char_packet(mpeg3_demuxer_t *demuxer);
unsigned int mpeg3demux_read_prev_char_packet(mpeg3_demuxer_t *demuxer);

/* ======================================================================== */
/*                                 Entry Points */
/* ======================================================================== */

#define mpeg3bits_tell_percentage(stream) mpeg3demux_tell_percentage((stream)->demuxer)

#define mpeg3bits_packet_time(stream) mpeg3demux_current_time((stream)->demuxer)

#define mpeg3bits_time_offset(stream) mepg2demux_time_offset((stream)->demuxer)

#define mpeg3bits_error(stream) mpeg3demux_error((stream)->demuxer)

#define mpeg3bits_eof(stream) mpeg3demux_eof((stream)->demuxer)

#define mpeg3bits_bof(stream) mpeg3demux_bof((stream)->demuxer)

/* Read bytes backward from the file until the reverse_bits is full. */
static inline void mpeg3bits_fill_reverse_bits(mpeg3_bits_t* stream, int bits)
{
// Right justify
	while(stream->bit_number > 7)
	{
		stream->bfr >>= 8;
		stream->bfr_size -= 8;
		stream->bit_number -= 8;
	}

// Insert bytes before bfr_size
	while(stream->bfr_size - stream->bit_number < bits)
	{
		if(stream->input_ptr)
			stream->bfr |= (unsigned int)(*--stream->input_ptr) << stream->bfr_size;
		else
			stream->bfr |= (unsigned int)mpeg3demux_read_prev_char(stream->demuxer) << stream->bfr_size;
		stream->bfr_size += 8;
	}
}

/* Read bytes forward from the file until the forward_bits is full. */
static inline void mpeg3bits_fill_bits(mpeg3_bits_t* stream, int bits)
{
	while(stream->bit_number < bits)
	{
		stream->bfr <<= 8;
		if(stream->input_ptr)
		{
			stream->bfr |= *stream->input_ptr++;
		}
		else
		{
			stream->bfr |= mpeg3demux_read_char(stream->demuxer);
		}
		stream->bit_number += 8;
		stream->bfr_size += 8;
		if(stream->bfr_size > 32) stream->bfr_size = 32;
	}
}

/* Return 8 bits, advancing the file position. */
static inline unsigned int mpeg3bits_getbyte_noptr(mpeg3_bits_t* stream)
{
	if(stream->bit_number < 8)
	{
		stream->bfr <<= 8;
		if(stream->input_ptr)
			stream->bfr |= *stream->input_ptr++;
		else
			stream->bfr |= mpeg3demux_read_char(stream->demuxer);

		stream->bfr_size += 8;
		if(stream->bfr_size > 32) stream->bfr_size = 32;

		return (stream->bfr >> stream->bit_number) & 0xff;
	}
	return (stream->bfr >> (stream->bit_number -= 8)) & 0xff;
}

static inline unsigned int mpeg3bits_getbit_noptr(mpeg3_bits_t* stream)
{
	if(!stream->bit_number)
	{
		stream->bfr <<= 8;
		stream->bfr |= mpeg3demux_read_char(stream->demuxer);

		stream->bfr_size += 8;
		if(stream->bfr_size > 32) stream->bfr_size = 32;

		stream->bit_number = 7;

		return (stream->bfr >> 7) & 0x1;
	}
	return (stream->bfr >> (--stream->bit_number)) & (0x1);
}

/* Return n number of bits, advancing the file position. */
/* Use in place of flushbits */
static inline unsigned int mpeg3bits_getbits(mpeg3_bits_t* stream, int bits)
{
	if(bits <= 0) return 0;
	mpeg3bits_fill_bits(stream, bits);
	return (stream->bfr >> (stream->bit_number -= bits)) & (0xffffffff >> (32 - bits));
}

static inline unsigned int mpeg3bits_showbits24_noptr(mpeg3_bits_t* stream)
{
	while(stream->bit_number < 24)
	{
		stream->bfr <<= 8;
		stream->bfr |= mpeg3demux_read_char(stream->demuxer);
		stream->bit_number += 8;
		stream->bfr_size += 8;
		if(stream->bfr_size > 32) stream->bfr_size = 32;
	}
	return (stream->bfr >> (stream->bit_number - 24)) & 0xffffff;
}

static inline unsigned int mpeg3bits_showbits32_noptr(mpeg3_bits_t* stream)
{
	while(stream->bit_number < 32)
	{
		stream->bfr <<= 8;
		stream->bfr |= mpeg3demux_read_char(stream->demuxer);
		stream->bit_number += 8;
		stream->bfr_size += 8;
		if(stream->bfr_size > 32) stream->bfr_size = 32;
	}
	return stream->bfr;
}

static inline unsigned int mpeg3bits_showbits(mpeg3_bits_t* stream, int bits)
{
	mpeg3bits_fill_bits(stream, bits);
	return (stream->bfr >> (stream->bit_number - bits)) & (0xffffffff >> (32 - bits));
}

static inline unsigned int mpeg3bits_getbits_reverse(mpeg3_bits_t* stream, int bits)
{
	unsigned int result;
	mpeg3bits_fill_reverse_bits(stream, bits);
	result = (stream->bfr >> stream->bit_number) & (0xffffffff >> (32 - bits));
	stream->bit_number += bits;
	return result;
}

static inline unsigned int mpeg3bits_showbits_reverse(mpeg3_bits_t* stream, int bits)
{
	unsigned int result;
	mpeg3bits_fill_reverse_bits(stream, bits);
	result = (stream->bfr >> stream->bit_number) & (0xffffffff >> (32 - bits));
	return result;
}

#endif
