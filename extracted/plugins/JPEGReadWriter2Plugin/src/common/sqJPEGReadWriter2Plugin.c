/* sqJPEGReadWriter2Plugin.c
 *	Cross-platform interface to JPEG processing.
 *
 *	Author: Laura Perez Carrato
 *
 *	Copyright (c) 2013 3D Immersive Collaboration Consulting, LLC.
 *
 *	All rights reserved.
 *   
 *   This file is part of Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 */
#include "JPEGReadWriter2Plugin.h"
#include <stdlib.h> /* abs */

/*
 * For more info regarding what's being done here, download libjpeg 6b from
 * http://www.ijg.org/files/ and take a look at example.c
 */

void
primJPEGWriteImageonByteArrayformqualityprogressiveJPEGerrorMgrWriteScanlines(
    unsigned int width, 
    unsigned int height, 
    int nativeDepth,
    unsigned int* bitmap,
    char* jpegCompressStruct,
    char* jpegErrorMgr2Struct,
    int quality,
    int progressiveFlag, 
    unsigned int pixelsPerWord, 
    unsigned int wordsPerRow,
    char* destination,
    unsigned int* destinationSizePtr)
{
    j_compress_ptr pcinfo = (j_compress_ptr)jpegCompressStruct;
	error_ptr2 pjerr = (error_ptr2)jpegErrorMgr2Struct;

	pcinfo->err = jpeg_std_error(&pjerr->pub);
	pjerr->setjmp_buffer = (jmp_buf *) malloc(sizeof(jmp_buf));
	pjerr->pub.error_exit = error_exit;

	if (setjmp(*pjerr->setjmp_buffer)) {
		jpeg_destroy_compress(pcinfo);

		*destinationSizePtr = 0;
	}

	if (*destinationSizePtr) {
		jpeg_create_compress(pcinfo);
		jpeg_mem_dest(pcinfo, destination, destinationSizePtr);

		pcinfo->image_width = width;
		pcinfo->image_height = height;
		pcinfo->input_components = (abs(nativeDepth) != 8 ? 3 : 1);
		pcinfo->in_color_space = (abs(nativeDepth) != 8 ? JCS_RGB : JCS_GRAYSCALE);
		jpeg_set_defaults(pcinfo);
		if (quality > 0)
			jpeg_set_quality (pcinfo, quality, 1);
		if (progressiveFlag)
			jpeg_simple_progression(pcinfo);

		jpeg_start_compress(pcinfo, TRUE);

		unsigned int rowStride = wordsPerRow * pixelsPerWord * pcinfo->input_components;

		JSAMPARRAY buffer = (*(pcinfo->mem)->alloc_sarray)
			((j_common_ptr) pcinfo, JPOOL_IMAGE, rowStride, 1);

		while (pcinfo->next_scanline < pcinfo->image_height) {
		    unsigned int i;
		    unsigned int j;
			for(i = 0, j = 0; i < rowStride; i +=(pcinfo->input_components * pixelsPerWord), j++) {
				unsigned int bitmapWord = bitmap[pcinfo->next_scanline * wordsPerRow + j];

				switch (nativeDepth) {
					case 32:
					case -32:
						buffer[0][i] = (bitmapWord >> 16) & 255;
						buffer[0][i+1] = (bitmapWord >> 8) & 255;
						buffer[0][i+2] = bitmapWord & 255;
						break;
					case 16:
						buffer[0][i] = (bitmapWord >> 23) & 248;
						buffer[0][i+1] = (bitmapWord >> 18) & 248;
						buffer[0][i+2] = (bitmapWord >> 13) & 248;
						buffer[0][i+3] = (bitmapWord >> 7) & 248;
						buffer[0][i+4] = (bitmapWord >> 2) & 248;
						buffer[0][i+5] = (bitmapWord << 3) & 248;
						break;
					case -16:
						buffer[0][i] = (bitmapWord >> 7) & 248;
						buffer[0][i+1] = (bitmapWord >> 2) & 248;
						buffer[0][i+2] = (bitmapWord << 3) & 248;
						buffer[0][i+3] = (bitmapWord >> 23) & 248;
						buffer[0][i+4] = (bitmapWord >> 18) & 248;
						buffer[0][i+5] = (bitmapWord >> 13) & 248;
						break;
					case 8:
						buffer[0][i] = (bitmapWord >> 24) & 255;
						buffer[0][i+1] = (bitmapWord >> 16) & 255;
						buffer[0][i+2] = (bitmapWord >> 8) & 255;
						buffer[0][i+3] = bitmapWord & 255;
						break;
					case -8:
						buffer[0][i] = bitmapWord & 255;
						buffer[0][i+1] = (bitmapWord >> 8) & 255;
						buffer[0][i+2] = (bitmapWord >> 16) & 255;
						buffer[0][i+3] = (bitmapWord >> 24) & 255;
						break;
				}
			}

			(void) jpeg_write_scanlines(pcinfo, buffer, 1);
		}

		jpeg_finish_compress(pcinfo);
		jpeg_destroy_compress(pcinfo);
	}
	free(pjerr->setjmp_buffer);
}

void
primJPEGReadImagefromByteArrayonFormdoDitheringerrorMgrReadScanlines(
    char* jpegDecompressStruct,
    char* jpegErrorMgr2Struct,
    char* source,
    unsigned int sourceSize,
    int ditherFlag,
    unsigned int* bitmap,
    unsigned int pixelsPerWord,
    unsigned int wordsPerRow,
    int nativeDepth)
{
	j_decompress_ptr pcinfo = (j_decompress_ptr)jpegDecompressStruct;
	error_ptr2 pjerr = (error_ptr2)jpegErrorMgr2Struct;

	int ok = 1;
	pcinfo->err = jpeg_std_error(&pjerr->pub);
	pjerr->setjmp_buffer = (jmp_buf *) malloc(sizeof(jmp_buf));
	pjerr->pub.error_exit = error_exit;

	if (setjmp(*pjerr->setjmp_buffer)) {
		jpeg_destroy_decompress(pcinfo);
		ok = 0;
	}

	if (ok)
		ok = jpeg_mem_src_newLocationOfData(pcinfo, source, sourceSize);

	if (ok) {
		jpeg_start_decompress(pcinfo);

		int depth = abs(nativeDepth);

		unsigned int rowStride = pcinfo->output_width * pcinfo->output_components;

		JSAMPARRAY buffer = (*(pcinfo->mem)->alloc_sarray)
			((j_common_ptr) pcinfo, JPOOL_IMAGE, rowStride, 1);

		int redOffset1, redOffset2;
		int greenOffset1, greenOffset2;
		int blueOffset1, blueOffset2;

		if (pcinfo->out_color_components == 3) {
			redOffset1 = 0; redOffset2 = 3;
			greenOffset1 = 1; greenOffset2 = 4;
			blueOffset1 = 2; blueOffset2 = 5;
		}
		else {
			redOffset1 = 0; redOffset2 = 1;
			greenOffset1 = 0; greenOffset2 = 1;
			blueOffset1 = 0; blueOffset2 = 1; 
		}

		int grayOffset1 = 0;
		int grayOffset2 = 1;
		int grayOffset3 = 2;
		int grayOffset4 = 3;

		// Dither Matrix taken from Form>>orderedDither32To16, but rewritten for this method
		int ditherMatrix1[] = { 2, 0, 14, 12, 1, 3, 13, 15 };
		int ditherMatrix2[] = { 10, 8, 6, 4, 9, 11, 5, 7 };

		while (pcinfo->output_scanline < pcinfo->output_height) {
			(void) jpeg_read_scanlines(pcinfo, buffer, 1);

			unsigned int i;
			unsigned int j;

			for(i = 0, j = 0; i < rowStride; i +=(pcinfo->out_color_components * pixelsPerWord), j++) {
				unsigned int bitmapWord;

				switch (depth) {
					case 32: ;
						unsigned char red = buffer[0][i+redOffset1];
						unsigned char green = buffer[0][i+greenOffset1];
						unsigned char blue = buffer[0][i+blueOffset1];
						bitmapWord = (255 << 24) | (red << 16) | (green << 8) | blue;
						break;
					case 16: ;
						unsigned char red1 = buffer[0][i+redOffset1];
						unsigned char red2 = buffer[0][i+redOffset2];
						unsigned char green1 = buffer[0][i+greenOffset1];
						unsigned char green2 = buffer[0][i+greenOffset2];
						unsigned char blue1 = buffer[0][i+blueOffset1];
						unsigned char blue2 = buffer[0][i+blueOffset2];

						if (ditherFlag) {
							// Do 4x4 ordered dithering. Taken from Form>>orderedDither32To16
							int dmv1, dmv2, di, dmi, dmo; 
							dmv1 = ditherMatrix1[((pcinfo->output_scanline & 3) << 1) | (j&1)];
							dmv2 = ditherMatrix2[((pcinfo->output_scanline & 3) << 1) | (j&1)];
							di = (red1 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
							red1 = dmv1 < dmi ? dmo+1 : dmo;
							di = (green1 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
							green1 = dmv1 < dmi ? dmo+1 : dmo;
							di = (blue1 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
							blue1 = dmv1 < dmi ? dmo+1 : dmo;
							di = (red2 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
							red2 = dmv2 < dmi ? dmo+1 : dmo;
							di = (green2 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
							green2 = dmv2 < dmi ? dmo+1 : dmo;
							di = (blue2 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
							blue2 = dmv2 < dmi ? dmo+1 : dmo;
						}
						else {
							red1 = red1 >> 3;
							red2 = red2 >> 3;
							green1 = green1 >> 3;
							green2 = green2 >> 3;
							blue1 = blue1 >> 3;
							blue2 = blue2 >> 3;
						}

						switch (nativeDepth) {
							case 16:
								bitmapWord = 32768 | (red1 << 10) | (green1 << 5) | blue1;
								bitmapWord = (bitmapWord << 16) | 32768 | (red2 << 10) | (green2 << 5) | blue2;
								break;
							case -16:
								bitmapWord = 32768 | (red2 << 10) | (green2 << 5) | blue2;
								bitmapWord = (bitmapWord << 16) | 32768 | (red1 << 10) | (green1 << 5) | blue1;
								break;
						}

						break;
					case 8: ;
						unsigned char gray1 = buffer[0][i+grayOffset1];
						unsigned char gray2 = buffer[0][i+grayOffset2];
						unsigned char gray3 = buffer[0][i+grayOffset3];
						unsigned char gray4 = buffer[0][i+grayOffset4];
						switch (nativeDepth) {
							case 8:
								bitmapWord = gray1 << 24 | gray2 << 16 | gray3 << 8 | gray4;
								break;
							case -8:
								bitmapWord = gray4 << 24 | gray3 << 16 | gray2 << 8 | gray1;
								break;
						}
					break;
				}
				bitmap[((pcinfo->output_scanline - 1) * wordsPerRow) + j] = bitmapWord;
			}
		}
		jpeg_finish_decompress(pcinfo);
		jpeg_destroy_decompress(pcinfo);
	}
	free(pjerr->setjmp_buffer);
}

void
primJPEGReadHeaderfromByteArraysizeerrorMgrReadHeader(
    char* jpegDecompressStruct,
    char* source, 
    unsigned int sourceSize,
    char* jpegErrorMgr2Struct)
{
    j_decompress_ptr pcinfo = (j_decompress_ptr)jpegDecompressStruct;
	error_ptr2 pjerr = (error_ptr2)jpegErrorMgr2Struct;

	pcinfo->err = jpeg_std_error(&pjerr->pub);
	pjerr->setjmp_buffer = (jmp_buf *) malloc(sizeof(jmp_buf));
	pjerr->pub.error_exit = error_exit;

	if (setjmp(*pjerr->setjmp_buffer)) {
		jpeg_destroy_decompress(pcinfo);
		sourceSize = 0;
	}

	if (sourceSize) {
		jpeg_create_decompress(pcinfo);
		jpeg_mem_src(pcinfo, source, sourceSize);
		jpeg_read_header(pcinfo, TRUE);
	}
	free(pjerr->setjmp_buffer);
}
