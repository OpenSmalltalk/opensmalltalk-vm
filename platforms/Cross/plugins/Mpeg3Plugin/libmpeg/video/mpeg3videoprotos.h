#ifndef MPEG3VIDEOPROTOS_H
#define MPEG3VIDEOPROTOS_H

void mpeg3video_idct_conversion(short* block);
unsigned int mpeg3slice_showbits(mpeg3_slice_buffer_t *slice_buffer, int bits);

#endif
