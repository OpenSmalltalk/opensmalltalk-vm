"
This work is a Squeak VM Plugin version of LibJPEG.

The following sentence applies to this class:
  ""This software is based in part on the work of the Independent JPEG Group"".

You can read more about it at www.ijg.org

In addition to the code generated from this class, the plugin uses the following files (from LibJPEG ver. 6b):

jerror.c
jcmarker.c
jdmarker.c
jctrans.c
jcparam.c
jdapimin.c
jcapimin.c
jidctred.c
jidctflt.c
jidctfst.c
jidctint.c
jccoefct.c
jdinput.c
jdmaster.c
jdcoefct.c
jdhuff.c
jdphuff.c
jcphuff.c
jchuff.c
jcomapi.c
jcinit.c
jcmaster.c
jdcolor.c
jdtrans.c
jmemmgr.c
jutils.c
jddctmgr.c
jcdctmgr.c
jquant2.c
jquant1.c
jmemnobs.c
jfdctint.c
jfdctfst.c
jfdctflt.c
jdsample.c
jdpostct.c
jdmerge.c
jdmainct.c
jdapistd.c
jcsample.c
jcprepct.c
jcmainct.c
jccolor.c
jcapistd.c
jversion.h
jpeglib.h
jdhuff.h
jchuff.h
jerror.h
jmorecfg.h
jmemsys.h
jpegint.h
jdct.h
jinclude.h


"
Class {
	#name : #JPEGReadWriter2Plugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
JPEGReadWriter2Plugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
JPEGReadWriter2Plugin class >> requiresCrossPlatformFiles [
	"default is ok for most, any plugin needing cross platform files must say so"
	^true
]

{ #category : #translation }
JPEGReadWriter2Plugin class >> requiresPlatformFiles [
	"default is ok for most, any plugin needing platform specific files must say so"
	^true
]

{ #category : #'initialize-release' }
JPEGReadWriter2Plugin >> initialiseModule [

	<export: true>
	^true
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primImageHeight: aJPEGDecompressStruct [

	<export: true>

	self
		primitive: 'primImageHeight'
		parameters: #(ByteArray).

	"Various parameter checks"
	self cCode: '
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(0))) >= (sizeof(struct jpeg_decompress_struct))); 
		if (interpreterProxy->failed()) return null;
	' inSmalltalk: [].

	^(self cCode: '((j_decompress_ptr)aJPEGDecompressStruct)->image_height' inSmalltalk: [0])
		 asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primImageWidth: aJPEGDecompressStruct [

	<export: true>

	self
		primitive: 'primImageWidth'
		parameters: #(ByteArray).

	"Various parameter checks"
	self cCode: '
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(0))) >= (sizeof(struct jpeg_decompress_struct))); 
		if (interpreterProxy->failed()) return null;
	' inSmalltalk: [].

	^(self cCode: '((j_decompress_ptr)aJPEGDecompressStruct)->image_width' inSmalltalk: [0])
		asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGCompressStructSize [
	<export: true>

	self
		primitive: 'primJPEGCompressStructSize'
		parameters: #().

	^(self cCode: 'sizeof(struct jpeg_compress_struct)' inSmalltalk: [0])
		asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGDecompressStructSize [
	<export: true>

	self
		primitive: 'primJPEGDecompressStructSize'
		parameters: #().

	^(self cCode: 'sizeof(struct jpeg_decompress_struct)' inSmalltalk: [0])
		asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGErrorMgr2StructSize [
	<export: true>
	self
		primitive: 'primJPEGErrorMgr2StructSize'
		parameters: #().

	^(self cCode: 'sizeof(struct error_mgr2)' inSmalltalk: [0])
		asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGPluginIsPresent [
	<export: true>
	self
		primitive: 'primJPEGPluginIsPresent'
		parameters: #().
	^true asOop: Boolean
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGReadHeader: aJPEGDecompressStruct fromByteArray: source errorMgr: aJPEGErrorMgr2Struct [

	| pcinfo pjerr sourceSize |
	<export: true>
	<var: #pcinfo type: 'j_decompress_ptr '>
	<var: #pjerr type: 'error_ptr2 '>
	self
		primitive: 'primJPEGReadHeaderfromByteArrayerrorMgr'
		parameters: #(ByteArray ByteArray ByteArray).
 

		pcinfo := nil. pjerr := nil. sourceSize := nil.
		pcinfo. pjerr. sourceSize.

	"Various parameter checks"
	self cCode: '
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(2))) >= (sizeof(struct jpeg_decompress_struct)));
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(0))) >= (sizeof(struct error_mgr2))); 
		if (interpreterProxy->failed()) return null;
	' inSmalltalk: [].

	self cCode: '
		sourceSize = interpreterProxy->stSizeOf(interpreterProxy->stackValue(1));
		pcinfo = (j_decompress_ptr)aJPEGDecompressStruct;
		pjerr = (error_ptr2)aJPEGErrorMgr2Struct;
		if (sourceSize) {
			pcinfo->err = jpeg_std_error(&pjerr->pub);
			pjerr->pub.error_exit = error_exit;
			if (setjmp(pjerr->setjmp_buffer)) {
				jpeg_destroy_decompress(pcinfo);
				sourceSize = 0;
			}
			if (sourceSize) {
				jpeg_create_decompress(pcinfo);
				jpeg_mem_src(pcinfo, source, sourceSize);
				jpeg_read_header(pcinfo, TRUE);
			}
		}
	' inSmalltalk: [].
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGReadImage: aJPEGDecompressStruct fromByteArray: source onForm: form doDithering: ditherFlag errorMgr: aJPEGErrorMgr2Struct [

	| pcinfo pjerr buffer rowStride formBits formDepth i j formPix ok rOff gOff bOff rOff2 gOff2 bOff2 formWidth formHeight pixPerWord formPitch formBitsSize sourceSize r1 r2 g1 g2 b1 b2 formBitsOops dmv1 dmv2 di dmi dmo |
	<export: true>
	<var: #pcinfo type: 'j_decompress_ptr '>
	<var: #pjerr type: 'error_ptr2 '>
	<var: #buffer type: 'JSAMPARRAY '>
	<var: #formBits type: 'unsigned * '>

	self
		primitive: 'primJPEGReadImagefromByteArrayonFormdoDitheringerrorMgr'
		parameters: #(ByteArray ByteArray Form Boolean ByteArray).

	"Avoid warnings when saving method"
	 pcinfo := nil. pjerr := nil. buffer := nil. rowStride := nil.
		formDepth := nil. formBits := nil. i := nil. j := nil. formPix := nil.
		ok := nil. rOff := nil. gOff := nil. bOff := nil. rOff2 := nil. gOff2 := nil. bOff2 := nil. sourceSize := nil.
		r1 := nil. r2 := nil. g1 := nil. g2 := nil. b1 := nil. b2 := nil.
		dmv1 := nil. dmv2 := nil. di := nil. dmi := nil. dmo := nil.
		pcinfo. pjerr. buffer. rowStride. formBits. formDepth. i. j. formPix. ok.
		rOff. gOff. bOff. rOff2. gOff2. bOff2. sourceSize.
		r1. r2. g1.g2. b1. b2. dmv1. dmv2. di. dmi. dmo.

	formBitsOops := interpreterProxy fetchPointer: 0 ofObject: form.
	formDepth := interpreterProxy fetchInteger: 3 ofObject: form.

	"Various parameter checks"
	self cCode: '
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(4))) >= (sizeof(struct jpeg_decompress_struct)));
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(0))) >= (sizeof(struct error_mgr2))); 
		if (interpreterProxy->failed()) return null;
	' inSmalltalk: [].
	formWidth := (self cCode: '((j_decompress_ptr)aJPEGDecompressStruct)->image_width' inSmalltalk: [0]).
	formHeight := (self cCode: '((j_decompress_ptr)aJPEGDecompressStruct)->image_height' inSmalltalk: [0]).
	pixPerWord := 32 // formDepth.
	formPitch := formWidth + (pixPerWord-1) // pixPerWord * 4.
	formBitsSize := interpreterProxy byteSizeOf: formBitsOops.
	interpreterProxy success: 
		((interpreterProxy isWordsOrBytes: formBitsOops)
			and: [formBitsSize = (formPitch * formHeight)]).
	interpreterProxy failed ifTrue: [^ nil].
	formBits := interpreterProxy firstIndexableField: formBitsOops.

	self cCode: '
		sourceSize = interpreterProxy->stSizeOf(interpreterProxy->stackValue(3));
		if (sourceSize == 0) {
			interpreterProxy->success(false);
			return null;
		}
		pcinfo = (j_decompress_ptr)aJPEGDecompressStruct;
		pjerr = (error_ptr2)aJPEGErrorMgr2Struct;
		pcinfo->err = jpeg_std_error(&pjerr->pub);
		pjerr->pub.error_exit = error_exit;
		ok = 1;
		if (setjmp(pjerr->setjmp_buffer)) {
			jpeg_destroy_decompress(pcinfo);
			ok = 0;
		}
		if (ok) {
			ok = jpeg_mem_src_newLocationOfData(pcinfo, source, sourceSize);
			if (ok) {
				/* Dither Matrix taken from Form>>orderedDither32To16, but rewritten for this method. */
				int ditherMatrix1[] = { 2, 0, 14, 12, 1, 3, 13, 15 };
				int ditherMatrix2[] = { 10, 8, 6, 4, 9, 11, 5, 7 };
 				jpeg_start_decompress(pcinfo);
				rowStride = pcinfo->output_width * pcinfo->output_components;
				if (pcinfo->out_color_components == 3) {
					rOff = 0; gOff = 1; bOff = 2;
					rOff2 = 3; gOff2 = 4; bOff2 = 5;
				} else {
					rOff = 0; gOff = 0; bOff = 0;
					rOff2 = 1; gOff2 = 1; bOff2 = 1;
				}
				/* Make a one-row-high sample array that will go away when done with image */
				buffer = (*(pcinfo->mem)->alloc_sarray)
					((j_common_ptr) pcinfo, JPOOL_IMAGE, rowStride, 1);

				/* Step 6: while (scan lines remain to be read) */
				/*           jpeg_read_scanlines(...); */

				/* Here we use the library state variable cinfo.output_scanline as the
				 * loop counter, so that we dont have to keep track ourselves.
				 */
				while (pcinfo->output_scanline < pcinfo->output_height) {
					/* jpeg_read_scanlines expects an array of pointers to scanlines.
					 * Here the array is only one element long, but you could ask for
					 * more than one scanline at a time if thats more convenient.
					 */
					(void) jpeg_read_scanlines(pcinfo, buffer, 1);

					switch (formDepth) {
						case 32:
							for(i = 0, j = 0; i < rowStride; i +=(pcinfo->out_color_components), j++) {
								formPix = (255 << 24) | (buffer[0][i+rOff] << 16) | (buffer[0][i+gOff] << 8) | buffer[0][i+bOff];
								if (formPix == 0) formPix = 1;
								formBits [ ((pcinfo->output_scanline - 1) * (pcinfo->image_width)) + j ] = formPix;
							}
							break;

						case 16:
							for(i = 0, j = 0; i < rowStride; i +=(pcinfo->out_color_components*2), j++) {
								r1 = buffer[0][i+rOff];
								r2 = buffer[0][i+rOff2];
								g1 = buffer[0][i+gOff];
								g2 = buffer[0][i+gOff2];
								b1 = buffer[0][i+bOff];
								b2 = buffer[0][i+bOff2];

								if (!ditherFlag) {
									r1 = r1 >> 3;
									r2 = r2 >> 3;
									g1 = g1 >> 3;
									g2 = g2 >> 3;
									b1 = b1 >> 3;
									b2 = b2 >> 3;
								} else {
									/* Do 4x4 ordered dithering. Taken from Form>>orderedDither32To16 */
									dmv1 = ditherMatrix1[ ((pcinfo->output_scanline & 3 )<< 1) | (j&1) ];
									dmv2 = ditherMatrix2[ ((pcinfo->output_scanline & 3 )<< 1) | (j&1) ];

									di = (r1 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv1 < dmi) { r1 = dmo+1; } else { r1 = dmo; };
									di = (g1 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv1 < dmi) { g1 = dmo+1; } else { g1 = dmo; };
									di = (b1 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv1 < dmi) { b1 = dmo+1; } else { b1 = dmo; };

									di = (r2 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv2 < dmi) { r2 = dmo+1; } else { r2 = dmo; };
									di = (g2 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv2 < dmi) { g2 = dmo+1; } else { g2 = dmo; };
									di = (b2 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv2 < dmi) { b2 = dmo+1; } else { b2 = dmo; };
								}

								formPix = (r1 << 10) | (g1 << 5) | b1;
								if (!formPix) formPix = 1;
								formPix = (formPix << 16) | (r2 << 10) | (g2 << 5) | b2;
								if (!(formPix & 65535)) formPix = formPix | 1;
								formBits [ ((pcinfo->output_scanline - 1) * (pcinfo->image_width)) / 2 + j ] = formPix;
							}
							break;
					}
				}
				jpeg_finish_decompress(pcinfo);
			}
			jpeg_destroy_decompress(pcinfo);
		}
	' inSmalltalk: [].
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGWriteImage: aJPEGCompressStruct onByteArray: destination form: form quality: quality progressiveJPEG: progressiveFlag errorMgr: aJPEGErrorMgr2Struct [

	| pcinfo pjerr buffer rowStride formBits formWidth formHeight formDepth i j formPix destinationSize pixPerWord formPitch formBitsSize formBitsOops |
	<export: true>
	<var: #pcinfo type: 'j_compress_ptr '>
	<var: #pjerr type: 'error_ptr2 '>
	<var: #buffer type: 'JSAMPARRAY '>
	<var: #formBits type: 'unsigned * '>
	<var: #destinationSize type: 'unsigned int'>

	self
		primitive: 'primJPEGWriteImageonByteArrayformqualityprogressiveJPEGerrorMgr'
		parameters: #(ByteArray ByteArray Form SmallInteger Boolean ByteArray).

	pcinfo := nil. pjerr := nil. buffer :=nil. rowStride := nil. formBits := nil. 
	formWidth := nil. formHeight := nil. formDepth := nil. i := nil. j := nil. formPix := nil. destinationSize := nil.
	pcinfo. pjerr. buffer. rowStride. formBits. formWidth. formHeight. formDepth. i. j. formPix. destinationSize.

	formBitsOops := interpreterProxy fetchPointer: 0 ofObject: form.
	formWidth := interpreterProxy fetchInteger: 1 ofObject: form.
	formHeight := interpreterProxy fetchInteger: 2 ofObject: form.
	formDepth := interpreterProxy fetchInteger: 3 ofObject: form.

	"Various parameter checks"
	self cCode: '
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(5))) >= (sizeof(struct jpeg_compress_struct)));
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(0))) >= (sizeof(struct error_mgr2))); 
		if (interpreterProxy->failed()) return null;
	' inSmalltalk: [].
	pixPerWord := 32 // formDepth.
	formPitch := formWidth + (pixPerWord-1) // pixPerWord * 4.
	formBitsSize := interpreterProxy byteSizeOf: formBitsOops.
	interpreterProxy success: 
		((interpreterProxy isWordsOrBytes: formBitsOops)
			and: [formBitsSize = (formPitch * formHeight)]).
	interpreterProxy failed ifTrue: [^ nil].
	formBits := interpreterProxy firstIndexableField: formBitsOops.
	self cCode: '
		destinationSize = interpreterProxy->stSizeOf(interpreterProxy->stackValue(4));
		pcinfo = (j_compress_ptr)aJPEGCompressStruct;
		pjerr = (error_ptr2)aJPEGErrorMgr2Struct;
		if (destinationSize) {
			pcinfo->err = jpeg_std_error(&pjerr->pub);
			pjerr->pub.error_exit = error_exit;
			if (setjmp(pjerr->setjmp_buffer)) {
				jpeg_destroy_compress(pcinfo);
				destinationSize = 0;
			}
			if (destinationSize) {
				jpeg_create_compress(pcinfo);
				jpeg_mem_dest(pcinfo, destination, &destinationSize);
				pcinfo->image_width = formWidth;
				pcinfo->image_height = formHeight;
				pcinfo->input_components = 3;
				pcinfo->in_color_space = JCS_RGB;
				jpeg_set_defaults(pcinfo);
				if (quality > 0)
					jpeg_set_quality (pcinfo, quality, 1);
				if (progressiveFlag)
					jpeg_simple_progression(pcinfo);
				jpeg_start_compress(pcinfo, TRUE);
				rowStride = formWidth * 3;

				/* Make a one-row-high sample array that will go away 
				  when done with image */
				buffer = (*(pcinfo->mem)->alloc_sarray)
					((j_common_ptr) pcinfo, JPOOL_IMAGE, rowStride, 1);

				while (pcinfo->next_scanline < pcinfo->image_height) {
					switch (formDepth) {
						case 32:
							for(i = 0, j = 0; i < rowStride; i +=3, j++) {
								formPix = formBits [ ((pcinfo->next_scanline) * formWidth) + j ];
								buffer[0][i] = (formPix >> 16) & 255;
								buffer[0][i+1] = (formPix >> 8) & 255;
								buffer[0][i+2] = formPix & 255;
							}
							break;
						case 16:
							for(i = 0, j = 0; i < rowStride; i +=6, j++) {
								formPix = formBits [ ((pcinfo->next_scanline) * formWidth) / 2 + j ];
								buffer[0][i] = (formPix >> 23) & 248;
								buffer[0][i+1] = (formPix >> 18) & 248;
								buffer[0][i+2] = (formPix >> 13) & 248;
								buffer[0][i+3] = (formPix >> 7) & 248;
								buffer[0][i+4] = (formPix >> 2) & 248;
								buffer[0][i+5] = (formPix << 3) & 248;
							}
							break;
					}
					(void) jpeg_write_scanlines(pcinfo, buffer, 1);

				}
				jpeg_finish_compress(pcinfo);
				jpeg_destroy_compress(pcinfo);
			}
		}
	' inSmalltalk: [].
	^(self cCode: 'destinationSize' inSmalltalk: [0])
		asOop: SmallInteger
]

{ #category : #'initialize-release' }
JPEGReadWriter2Plugin >> shutdownModule [

	<export: true>
	^true
]
