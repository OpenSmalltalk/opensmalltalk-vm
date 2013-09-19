//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqRPCSound.c
// It provides Squeak with access to the RISC OS sound system as
// implemented by John Duffell's very neat SharedSoundBuffer/StreamManager
// modules.. Furthermore, my understanding of how to make use of John's modules
// relied on reading Andrew Sellors excellent code for !RDPClient.
// Thank you both.

#define SOUND_HEAP_MAX_SIZE 4096 * 1024
#define SOUND_DA_MAX_SIZE 4096 * 1024
#define SOUND_BLOCK_SIZE 32764
#define BYTESPERSAMPLE 4
#define BYTESFROMSAMPLES(numsample) (numsample * BYTESPERSAMPLE)
#define SOUND_BUFFER_SIZE(numsamples) (4* BYTESFROMSAMPLES(numsamples))

#ifndef SWI_XOS_Bit
#define SWI_XOS_Bit                     0x020000
#endif

#define SWI_SharedSoundBuffer_OpenStream 0x55FC0 /* Opens a stream */
#define SWI_SharedSoundBuffer_CloseStream 0x55FC1 /* Closes and stops a stream immediately */
#define SWI_SharedSoundBuffer_AddBlock 0x55FC2 /* Adds a block to a stream's queue */
#define SWI_SharedSoundBuffer_PollWord 0x55FC3 /* Sets up the buffer pollword */
#define SWI_SharedSoundBuffer_Volume 0x55FC4 /* Set the volume of output */
#define SWI_SharedSoundBuffer_SampleRate 0x55FC5 /* Set the sample rate */
#define SWI_SharedSoundBuffer_ReturnSSHandle 0x55FC6 /* Return the internal SharedSound handle */
#define SWI_SharedSoundBuffer_SetBuffer 0x55FC7 /* Set the stream buffer limit */
#define SWI_SharedSoundBuffer_BufferStats 0x52E08 /* Find out information about the buffer */
#define SWI_SharedSoundBuffer_Pause 0x55FC9 /* Pauses playback */
#define SWI_SharedSoundBuffer_StreamEnd 0x55FCA /* Closes a stream */
#define SWI_SharedSoundBuffer_Flush 0x55fcc
#define SWI_SharedSoundBuffer_BlockFilled 0x55fcd
#define SWI_SharedSoundBuffer_ReturnStreamHandle 0x55fce


#define SWI_StreamManager_OpenStream 0x57280
#define SWI_StreamManager_CloseStream 0x57281
#define SWI_StreamManager_AddBlock  0x57282
#define SWI_StreamManager_BlockFilled 0x57283
#define SWI_StreamManager_GetBlock  0x57284
#define SWI_StreamManager_FreeBlocks 0x57285
#define SWI_StreamManager_SrcPollWord 0x57286
#define SWI_StreamManager_SetBuffer 0x57287
#define SWI_StreamManager_BufferStats 0x57288
#define SWI_StreamManager_Mark      0x57289
#define SWI_StreamManager_Flush     0x5728a
#define SWI_StreamManager_DestPollWord 0x5728b
#define SWI_StreamManager_SetDALimits 0x5728c

