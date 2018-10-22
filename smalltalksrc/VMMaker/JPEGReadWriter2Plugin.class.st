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

{ #category : #simulation }
JPEGReadWriter2Plugin class >> simulatorClass [
	^SmartSyntaxPluginSimulator
]

{ #category : #'plugin support' }
JPEGReadWriter2Plugin >> compressStructSize [
	<inline: #always>
	^self
		cCode: [self sizeof: #'struct jpeg_compress_struct']
		inSmalltalk: [JPEGReadWriter2 new primJPEGCompressStructSize]
]

{ #category : #'plugin support' }
JPEGReadWriter2Plugin >> decompressStructSize [
	<inline: #always>
	^self
		cCode: [self sizeof: #'struct jpeg_decompress_struct']
		inSmalltalk: [JPEGReadWriter2 new primJPEGDecompressStructSize]
]

{ #category : #'plugin support' }
JPEGReadWriter2Plugin >> errorMgr2StructSize [
	<inline: #always>
	^self
		cCode: [self sizeof: #'struct error_mgr2']
		inSmalltalk: [JPEGReadWriter2 new primJPEGErrorMgr2StructSize]
]

{ #category : #simulation }
JPEGReadWriter2Plugin >> evaluateIfFailed: aBlock [
	"Evaluate aBlock, catching primtiive failure, and failing if so.
	 Answer if evaluating aBlock caused primitive failure."
	<doNotGenerate>
	aBlock
		on: Error
		do: [:ex|
			((ex signalerContext selector beginsWith: #primitiveFailed) "e.g. could be error: sent from primitiveFailed:"
			 or: [ex signalerContext sender selector beginsWith: #primitiveFailed]) ifFalse:
				[ex pass].
			interpreterProxy primitiveFail.
			^true].
	^false
]

{ #category : #'plugin support' }
JPEGReadWriter2Plugin >> isValidCompressionStruct: aByteArray [
	<inline: #always>
	^(interpreterProxy byteSizeOf: aByteArray cPtrAsOop) >= self compressStructSize
]

{ #category : #'plugin support' }
JPEGReadWriter2Plugin >> isValidDecompressionStruct: aByteArray [
	<inline: #always>
	^(interpreterProxy byteSizeOf: aByteArray cPtrAsOop) >= self decompressStructSize
]

{ #category : #'plugin support' }
JPEGReadWriter2Plugin >> isValidErrorMessageStruct: aByteArray [
	<inline: #always>
	^(interpreterProxy byteSizeOf: aByteArray cPtrAsOop) >= self errorMgr2StructSize
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primImageHeight: aJPEGDecompressStruct [
	<export: true>
	self primitive: 'primImageHeight' parameters: #(ByteArray).

	"Various parameter checks"
	(self isValidDecompressionStruct: aJPEGDecompressStruct) ifFalse:
		[^interpreterProxy primitiveFail].

	^(self
		cCode: '((j_decompress_ptr)aJPEGDecompressStruct)->image_height'
		inSmalltalk: [JPEGReadWriter2 new primImageHeight: aJPEGDecompressStruct asByteArray])
			asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primImageNumComponents: aJPEGDecompressStruct [
	<export: true>
	self primitive: 'primImageNumComponents' parameters: #(ByteArray).

	"Various parameter checks"
	(self isValidDecompressionStruct: aJPEGDecompressStruct) ifFalse:
		[^interpreterProxy primitiveFail].

	^(self
		cCode: '((j_decompress_ptr)aJPEGDecompressStruct)->num_components'
		inSmalltalk: [JPEGReadWriter2 new primImageNumComponents: aJPEGDecompressStruct asByteArray])
			asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primImageWidth: aJPEGDecompressStruct [
	<export: true>
	self primitive: 'primImageWidth' parameters: #(ByteArray).

	"Various parameter checks"
	(self isValidDecompressionStruct: aJPEGDecompressStruct) ifFalse:
		[^interpreterProxy primitiveFail].

	^(self
		cCode: '((j_decompress_ptr)aJPEGDecompressStruct)->image_width'
		inSmalltalk: [JPEGReadWriter2 new primImageWidth: aJPEGDecompressStruct asByteArray])
			asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGCompressStructSize [
	<export: true>
	self primitive: #primJPEGCompressStructSize parameters: #().

	^self compressStructSize asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGDecompressStructSize [
	<export: true>
	self primitive: #primJPEGDecompressStructSize parameters: #().

	^self decompressStructSize asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGErrorMgr2StructSize [
	<export: true>
	self primitive: #primJPEGErrorMgr2StructSize parameters: #().

	^self errorMgr2StructSize asOop: SmallInteger
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGPluginIsPresent [
	<export: true>
	self primitive: #primJPEGPluginIsPresent parameters: #().

	^(self cCode: [true] inSmalltalk: [JPEGReadWriter2 primJPEGPluginIsPresent]) asOop: Boolean
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGReadHeader: aJPEGDecompressStruct fromByteArray: source errorMgr: aJPEGErrorMgr2Struct [
	<export: true>
	
	| sourceSize |
	self
		primitive: 'primJPEGReadHeaderfromByteArrayerrorMgr'
		parameters: #(ByteArray ByteArray ByteArray).

	"Various parameter checks"
	((self isValidDecompressionStruct: aJPEGDecompressStruct)
	 and: [self isValidErrorMessageStruct: aJPEGErrorMgr2Struct]) ifFalse:
		[^interpreterProxy primitiveFail].
	
	sourceSize := interpreterProxy byteSizeOf: source cPtrAsOop.
	sourceSize > 0 ifTrue:
		[self primJPEGReadHeader: aJPEGDecompressStruct
			fromByteArray: source
			size: sourceSize
			errorMgrReadHeader: aJPEGErrorMgr2Struct]
]

{ #category : #simulation }
JPEGReadWriter2Plugin >> primJPEGReadHeader: jpegDecompressStruct fromByteArray: source size: sourceSize errorMgrReadHeader: jpegErrorMgr2Struct [
	"void primJPEGReadHeaderfromByteArraysizeerrorMgrReadHeader(
			char* jpegDecompressStruct,
			char* source,
			unsigned int sourceSize,
			char* jpegErrorMgr2Struct)"
	<doNotGenerate>
	| decompressStruct errorStruct sourceBytes |
	sourceBytes := source asByteArray.
	self assert: sourceBytes size >= sourceSize.
	decompressStruct := jpegDecompressStruct asByteArray.
	errorStruct := jpegErrorMgr2Struct asByteArray.
	(self evaluateIfFailed:
		[JPEGReadWriter2 new
			primJPEGReadHeader: decompressStruct
			fromByteArray: sourceBytes
			errorMgr: errorStruct]) ifTrue: [^nil].
	jpegDecompressStruct overwriteContentsWith: decompressStruct.
	jpegErrorMgr2Struct overwriteContentsWith: errorStruct.
	source overwriteContentsWith: sourceBytes.
	^nil
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primJPEGReadImage: aJPEGDecompressStruct fromByteArray: source onForm: form doDithering: ditherFlag errorMgr: aJPEGErrorMgr2Struct [
	<export: true>
	| formBitmap formNativeDepth formDepth formWidth formHeight pixelsPerWord formPitch formBitmapSizeInBytes sourceSize formBitmapOOP formComponentBitSize formComponents wordsPerRow |
	<var: #formBitmap type: #'unsigned int *'>

	self
		primitive: 'primJPEGReadImagefromByteArrayonFormdoDitheringerrorMgr'
		parameters: #(ByteArray ByteArray Form Boolean ByteArray).

	formBitmapOOP := interpreterProxy fetchPointer: 0 ofObject: form. 
	formNativeDepth := interpreterProxy fetchInteger: 3 ofObject: form.
	formWidth := interpreterProxy fetchInteger: 1 ofObject: form.
	formHeight := interpreterProxy fetchInteger: 2 ofObject: form.
	formDepth := formNativeDepth abs.
	
	"Various parameter checks"
	((self isValidDecompressionStruct: aJPEGDecompressStruct)
	 and: [self isValidErrorMessageStruct: aJPEGErrorMgr2Struct]) ifFalse:
		[^interpreterProxy primitiveFail].
	
	formComponents := formDepth ~= 8 ifTrue: [4] ifFalse: [1].
	formComponentBitSize := formDepth ~= 16 ifTrue: [8] ifFalse: [4].
	pixelsPerWord := 32 // (formComponents * formComponentBitSize).
	wordsPerRow := (formWidth + pixelsPerWord - 1) // pixelsPerWord.
	formPitch := formWidth + (pixelsPerWord-1) // pixelsPerWord * 4.
	formBitmapSizeInBytes := interpreterProxy byteSizeOf: formBitmapOOP.
	
	interpreterProxy success: 
		((interpreterProxy isWordsOrBytes: formBitmapOOP)
		 and: [formBitmapSizeInBytes >= (formPitch * formHeight)]).
	interpreterProxy failed ifTrue: [^nil].
	
	sourceSize := interpreterProxy stSizeOf: (interpreterProxy stackValue: 3).
	
	interpreterProxy success: (sourceSize ~= 0).
	interpreterProxy failed ifTrue: [^nil].
	
	formBitmap := interpreterProxy firstIndexableField: formBitmapOOP.
	
	self primJPEGReadImagefromByteArrayonFormdoDitheringerrorMgrReadScanlines: aJPEGDecompressStruct
																			    		_: aJPEGErrorMgr2Struct
																					_: source
																			    		_: sourceSize
																			    		_: ditherFlag
																			    		_: formBitmap
																			   		_: pixelsPerWord
																			   		_: wordsPerRow
																			    		_: formNativeDepth
]

{ #category : #simulation }
JPEGReadWriter2Plugin >> primJPEGReadImagefromByteArrayonFormdoDitheringerrorMgrReadScanlines: jpegDecompressStruct _: jpegErrorMgr2Struct _: source _: sourceSize _: ditherFlag _: formBitmap _: pixelsPerWord _: wordsPerRow _: formNativeDepth [
	"void primJPEGReadImagefromByteArrayonFormdoDitheringerrorMgrReadScanlines(
		    char* jpegDecompressStruct,
		    char* jpegErrorMgr2Struct,
		    char* source,
		    unsigned int sourceSize,
		    int ditherFlag,
		    unsigned int* bitmap,
		    unsigned int pixelsPerWord,
		    unsigned int wordsPerRow,
		    int nativeDepth)"
	<doNotGenerate>
	| sourceBytes decompressStruct errorStruct form |
	sourceBytes := source asByteArray.
	decompressStruct := jpegDecompressStruct asByteArray.
	errorStruct := jpegErrorMgr2Struct asByteArray.
	(self evaluateIfFailed:
		[| slave height |
		 slave := JPEGReadWriter2 new.
		 height := slave primImageWidth: decompressStruct. "cheating ;-)"
		 form := Form extent: wordsPerRow * pixelsPerWord @ height depth: formNativeDepth.
		 slave
			primJPEGReadImage: decompressStruct
			fromByteArray: sourceBytes
			onForm: form
			doDithering: true
			errorMgr: errorStruct]) ifTrue: [^nil].
	jpegDecompressStruct overwriteContentsWith: decompressStruct.
	jpegErrorMgr2Struct overwriteContentsWith: errorStruct.
	source overwriteContentsWith: sourceBytes. "could happen..."
	ByteArray adoptInstance: form bits.
	formBitmap overwriteContentsWith: form bits.
	^nil
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
	((self isValidCompressionStruct: aJPEGCompressStruct)
	 and: [self isValidErrorMessageStruct: aJPEGErrorMgr2Struct]) ifFalse:
		[^interpreterProxy primitiveFail].

	
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
	destinationSize > 0 ifTrue:
		[self primJPEGWriteImageonByteArrayformqualityprogressiveJPEGerrorMgrWriteScanlines: formWidth
																								_: formHeight
																								_: formNativeDepth
																								_: formBitmap
																								_: aJPEGCompressStruct
																								_: aJPEGErrorMgr2Struct
																								_: quality
																								_: progressiveFlag
																								_: pixelsPerWord
																								_: wordsPerRow
																								_: destination
																								_: (self addressOf: destinationSize put: [:v| destinationSize := v])].
	
	^destinationSize asOop: SmallInteger
]

{ #category : #simulation }
JPEGReadWriter2Plugin >> primJPEGWriteImageonByteArrayformqualityprogressiveJPEGerrorMgrWriteScanlines: width _: height _: nativeDepth _: bitmap _: jpegCompressStruct _: jpegErrorMgr2Struct _: quality _: progressiveFlag _: pixelsPerWord _: wordsPerRow _: destination _: destinationSizePtr [
	"void primJPEGWriteImageonByteArrayformqualityprogressiveJPEGerrorMgrWriteScanlines(
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
			unsigned int* destinationSizePtr)"
	<doNotGenerate>
	| bits form compressStruct errorStruct destinationBytes destinationSize |
	bits := bitmap asByteArray.
	Bitmap adoptInstance: bits.
	form := Form extent: width @ height depth: nativeDepth bits: bits.
	compressStruct := jpegCompressStruct asByteArray.
	errorStruct := jpegErrorMgr2Struct asByteArray.
	destinationBytes := destination asByteArray.
	(self evaluateIfFailed:
		[destinationSize :=JPEGReadWriter2 new
			primJPEGWriteImage: compressStruct
			onByteArray: destinationBytes
			form: form
			quality: quality
			progressiveJPEG: progressiveFlag
			errorMgr: errorStruct]) ifTrue: [^nil].
	jpegCompressStruct overwriteContentsWith: compressStruct.
	jpegErrorMgr2Struct overwriteContentsWith: errorStruct.
	destination overwriteContentsWith: destinationBytes.
	destinationSizePtr at: 0 put: destinationSize.
	^nil
]

{ #category : #primitives }
JPEGReadWriter2Plugin >> primSupports8BitGrayscaleJPEGs [
	<export: true>
	self
		primitive: 'primSupports8BitGrayscaleJPEGs'
		parameters: #().
	^ true asOop: Boolean
]
