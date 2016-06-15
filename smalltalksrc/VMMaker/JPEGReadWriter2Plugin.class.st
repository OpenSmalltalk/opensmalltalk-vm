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
	#category : #'VMMaker-Plugins'
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
JPEGReadWriter2Plugin >> primImageNumComponents: aJPEGDecompressStruct [

	<export: true>

	self
		primitive: 'primImageNumComponents'
		parameters: #(ByteArray).

	"Various parameter checks"
	self cCode: '
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(0))) >= (sizeof(struct jpeg_decompress_struct))); 
		if (interpreterProxy->failed()) return null;
	' inSmalltalk: [].

	^(self cCode: '((j_decompress_ptr)aJPEGDecompressStruct)->num_components' inSmalltalk: [0])
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
	
	| sourceSize |
	
	<export: true>
	
	self
		primitive: 'primJPEGReadHeaderfromByteArrayerrorMgr'
		parameters: #(ByteArray ByteArray ByteArray).

	"Various parameter checks"
	interpreterProxy success: 
		(self cCode: 'interpreterProxy->stSizeOf(interpreterProxy->stackValue(2)) >= (sizeof(struct jpeg_decompress_struct))' inSmalltalk: []).
	interpreterProxy success:
		(self cCode: 'interpreterProxy->stSizeOf(interpreterProxy->stackValue(0)) >= (sizeof(struct error_mgr2))' inSmalltalk: []).
	interpreterProxy failed ifTrue: [ ^ nil ].
	
	sourceSize := interpreterProxy stSizeOf: (interpreterProxy stackValue: 1).
	sourceSize > 0 ifTrue:
		[self primJPEGReadHeader: aJPEGDecompressStruct
			fromByteArray: source
			size: sourceSize
			errorMgrReadHeader: aJPEGErrorMgr2Struct]
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGReadImage: aJPEGDecompressStruct fromByteArray: source onForm: form doDithering: ditherFlag errorMgr: aJPEGErrorMgr2Struct [

	| formBitmap formNativeDepth formDepth formWidth formHeight pixelsPerWord formPitch formBitmapSizeInBytes sourceSize formBitmapOOP formComponentBitSize formComponents wordsPerRow |
	<export: true>
	<var: #formBitmap type: 'unsigned int*'>

	self
		primitive: 'primJPEGReadImagefromByteArrayonFormdoDitheringerrorMgr'
		parameters: #(ByteArray ByteArray Form Boolean ByteArray).

	formBitmapOOP := interpreterProxy fetchPointer: 0 ofObject: form. 
	formNativeDepth := interpreterProxy fetchInteger: 3 ofObject: form.
	formWidth := interpreterProxy fetchInteger: 1 ofObject: form.
	formHeight := interpreterProxy fetchInteger: 2 ofObject: form.
	formDepth := formNativeDepth abs.
	
	"Various parameter checks"
	interpreterProxy success:
		(self cCode: 'interpreterProxy->stSizeOf(interpreterProxy->stackValue(4)) >= (sizeof(struct jpeg_decompress_struct))' inSmalltalk: []).
	interpreterProxy success:
		(self cCode: 'interpreterProxy->stSizeOf(interpreterProxy->stackValue(0)) >= (sizeof(struct error_mgr2))' inSmalltalk: []).
	interpreterProxy failed ifTrue: [ ^ nil ].
	
	formComponents := formDepth ~= 8 ifTrue: [4] ifFalse: [1].
	formComponentBitSize := formDepth ~= 16 ifTrue: [8] ifFalse: [4].
	pixelsPerWord := 32 // (formComponents * formComponentBitSize).
	wordsPerRow := (formWidth + pixelsPerWord - 1) // pixelsPerWord.
	formPitch := formWidth + (pixelsPerWord-1) // pixelsPerWord * 4.
	formBitmapSizeInBytes := interpreterProxy byteSizeOf: formBitmapOOP.
	
	interpreterProxy success: 
		((interpreterProxy isWordsOrBytes: formBitmapOOP) and: 
		[formBitmapSizeInBytes >= (formPitch * formHeight)]).
	interpreterProxy failed ifTrue: [^ nil].
	
	sourceSize := interpreterProxy stSizeOf: (interpreterProxy stackValue: 3).
	
	interpreterProxy success: (sourceSize ~= 0).
	interpreterProxy failed ifTrue: [  ^ nil ].
	
	formBitmap := interpreterProxy firstIndexableField: formBitmapOOP.
	
	self 
		cCode: 'primJPEGReadImagefromByteArrayonFormdoDitheringerrorMgrReadScanlines(
			aJPEGDecompressStruct,
    			aJPEGErrorMgr2Struct,
			source,
    			sourceSize,
    			ditherFlag,
    			formBitmap,
   			pixelsPerWord,
   			wordsPerRow,
    			formNativeDepth);'
		inSmalltalk: [].
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGWriteImage: aJPEGCompressStruct onByteArray: destination form: form quality: quality progressiveJPEG: progressiveFlag errorMgr: aJPEGErrorMgr2Struct [

	| formBitmap formWidth formHeight formNativeDepth formDepth destinationSize pixelsPerWord wordsPerRow formPitch formBitmapSizeInBytes formBitmapOOP formComponentBitSize formComponents |
	<export: true>
	<var: #formBitmap type: 'unsigned int *'> 
	<var: #destinationSize type: 'unsigned int'>

	self
		primitive: 'primJPEGWriteImageonByteArrayformqualityprogressiveJPEGerrorMgr'
		parameters: #(ByteArray ByteArray Form SmallInteger Boolean ByteArray).

	formBitmapOOP := interpreterProxy fetchPointer: 0 ofObject: form.
	formWidth := interpreterProxy fetchInteger: 1 ofObject: form.
	formHeight := interpreterProxy fetchInteger: 2 ofObject: form.
	formNativeDepth := interpreterProxy fetchInteger: 3 ofObject: form.
	formDepth := formNativeDepth abs.

	"Various parameter checks"
	interpreterProxy success:
		(self cCode: 'interpreterProxy->stSizeOf(interpreterProxy->stackValue(5)) >= (sizeof(struct jpeg_compress_struct))' inSmalltalk: []).
	interpreterProxy success: 
		(self cCode: 'interpreterProxy->stSizeOf(interpreterProxy->stackValue(0)) >= (sizeof(struct error_mgr2))' inSmalltalk: []).
	interpreterProxy failed ifTrue: [ ^ nil ].
	
	formComponents := formDepth ~= 8 ifTrue: [4] ifFalse: [1].
	formComponentBitSize := formDepth ~= 16 ifTrue: [8] ifFalse: [4].
	pixelsPerWord := 32 // (formComponents * formComponentBitSize).
	wordsPerRow := (formWidth + pixelsPerWord - 1) // pixelsPerWord.
	formPitch := wordsPerRow * 4.
	formBitmapSizeInBytes := interpreterProxy byteSizeOf: formBitmapOOP.
	interpreterProxy success: 
		((interpreterProxy isWordsOrBytes: formBitmapOOP) and: 
		[formBitmapSizeInBytes >= (formPitch * formHeight)]).
	interpreterProxy failed ifTrue: [ ^ nil ].
	
	formBitmap := interpreterProxy firstIndexableField: formBitmapOOP.
	destinationSize := interpreterProxy stSizeOf: (interpreterProxy stackValue: 4).
	(destinationSize = 0) 
		ifFalse: [ self 
			cCode: ' primJPEGWriteImageonByteArrayformqualityprogressiveJPEGerrorMgrWriteScanlines(
				formWidth, 
				formHeight, 
				formNativeDepth, 
				formBitmap, 
				aJPEGCompressStruct,
				aJPEGErrorMgr2Struct,
				quality,
				progressiveFlag,
				pixelsPerWord, 
				wordsPerRow, 
				destination,
				&destinationSize);'
			inSmalltalk: []].
	
	^(self cCode: 'destinationSize' inSmalltalk: [0])
		asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primSupports8BitGrayscaleJPEGs [
	<export: true>
	self
		primitive: 'primSupports8BitGrayscaleJPEGs'
		parameters: #().
	^ true asOop: Boolean
]

{ #category : #'initialize-release' }
JPEGReadWriter2Plugin >> shutdownModule [

	<export: true>
	^true
]
