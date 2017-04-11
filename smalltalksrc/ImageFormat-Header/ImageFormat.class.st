"
ImageFormat represents the requirements of the image in terms of capabilities that must be supported by the virtual machine. The image format version is saved as an integer value in the header of an image file. When an image is loaded, the virtual machine checks the image format version to determine whether it is capable of supporting the requirements of that image.

The image format version value is treated as a bit map of size 32, derived from the 32-bit integer value saved in the image header. Bits in the bit map represent image format requirements. For example, if the image sets bit 15 to indicate that it requires some capability from the VM, then the VM can check bit 15 and decide whether it is able to satisfy that requirement.

The base image format numbers (6502, 6504, 68000, and 68002) utiliize 10 of the 32 available bits. The high order bit is reserved as an extension bit for future use. The remaining 21 bits are used to represent additional image format requirements. For example, the low order bit is used to indication that the image uses (and requires support for) the platform byte ordering implemented in the StackInterpreter (Cog) VM.

	""(ImageFormat fromFile: Smalltalk imageName) description""

"
Class {
	#name : #ImageFormat,
	#superclass : #Object,
	#instVars : [
		'wordSize',
		'requiresClosureSupport',
		'requiresNativeFloatWordOrder',
		'requiresSpurSupport',
		'requiresNewSpur64TagAssignment'
	],
	#classVars : [
		'BaseVersionMask',
		'BaseVersionNumbers',
		'CapabilitiesBitsMask',
		'KnownVersionNumbers',
		'PlatformByteOrderBit',
		'ReservedBitsMask',
		'SpurObjectBit'
	],
	#category : #'ImageFormat-Header'
}

{ #category : #utility }
ImageFormat class >> allVersionNumberByteArrays [
	"All known version numbers expressed as byte arrays of size 4 and 8 in little
	endian and big endian byte ordering."

	"ImageFormat allVersionNumberByteArrays"

	| byteArrays |
	byteArrays := OrderedCollection new.
	KnownVersionNumbers do: [:version |
		byteArrays add: ((WriteStream on: (ByteArray new: 4)) nextNumber: 4 put: version; yourself) contents.
		byteArrays add: ((WriteStream on: (ByteArray new: 8)) nextNumber: 8 put: version; yourself) contents.
		byteArrays add: ((WriteStream on: (ByteArray new: 4)) nextLittleEndianNumber: 4 put: version; yourself) contents.
		byteArrays add: ((WriteStream on: (ByteArray new: 8)) nextLittleEndianNumber: 8 put: version; yourself) contents].
	^byteArrays
]

{ #category : #'initialize-release' }
ImageFormat class >> availableBits [
	"Bits available for use as capability bits. Reserve high order bit as the
	extension bit, to be set true if additional bits are required in the future."
	
	"ImageFormat availableBits printStringBase: 2"

	| mask |
	mask := 0.
	self bitAssignments doWithIndex: [ :e :i |
		mask := mask bitAt: i put: (e isNil ifTrue: [ 1 ] ifFalse: [ 0 ])].
	^ mask

]

{ #category : #'image formats' }
ImageFormat class >> baseVersionMask [
	"Mask the bits associated with base format number exclusive of capability bits"

	"ImageFormat baseVersionMask printStringBase: 2"

	^ BaseVersionNumbers
		inject: 0
		into: [:accum :e | accum bitOr: e]

]

{ #category : #'image formats' }
ImageFormat class >> baseVersionNumbers [
	"The well-known image format versions for basic 32 and 64 bit images,
	including images that require closure bytecode support. These base
	format numbers my be modified by application of various capability bits
	representing additional requirements that the image expects to be
	supported by the virtual machine."

	^#(6502 6504 68000 68002)

]

{ #category : #'initialize-release' }
ImageFormat class >> bitAssignments [

	"ImageFormat bitAssignments
		doWithIndex: [ :e :i | Transcript cr; show: 'bit ', i asString, ' is ', (e ifNil: ['unused'])]"

	| bits |
	bits := Array new: 32.
		"If bit 1 is set, the high and low order 32-bit words of a Float are stored in
		platform word order. If bit 1 is not set, big-endian word order is used for Float
		regardless of the platform." 
	bits at: 1 put: 'the use platform float word order bit (Cog and StackInterpreter)'.
	bits at: 2 put: 'used in base version numbers'.
	bits at: 3 put: 'used in base version numbers'.
	bits at: 4 put: 'used in base version numbers'.
	bits at: 5 put: 'the Spur object format bit'.
	bits at: 6 put: 'used in base version numbers'.
	bits at: 7 put: 'used in base version numbers'.
	bits at: 8 put: 'used in base version numbers'.
	bits at: 9 put: 'used in base version numbers'.
	bits at: 10 put: nil.	"unassigned bit available for future image formats"
	bits at: 11 put: nil.	"unassigned bit available for future image formats"
	bits at: 12 put: 'used in base version numbers'.
	bits at: 13 put: 'used in base version numbers'.
	bits at: 14 put: nil.	"unassigned bit available for future image formats"
	bits at: 15 put: nil.	"unassigned bit available for future image formats"
	bits at: 16 put: nil.	"unassigned bit available for future image formats"
	bits at: 17 put: 'used in base version numbers'.
	bits at: 18 put: nil.	"unassigned bit available for future image formats"
	bits at: 19 put: nil.	"unassigned bit available for future image formats"
	bits at: 20 put: nil.	"unassigned bit available for future image formats"
	bits at: 21 put: nil.	"unassigned bit available for future image formats"
	bits at: 22 put: nil.	"unassigned bit available for future image formats"
	bits at: 23 put: nil.	"unassigned bit available for future image formats"
	bits at: 24 put: nil.	"unassigned bit available for future image formats"
	bits at: 25 put: nil.	"unassigned bit available for future image formats"
	bits at: 26 put: nil.	"unassigned bit available for future image formats"
	bits at: 27 put: nil.	"unassigned bit available for future image formats"
	bits at: 28 put: nil.	"unassigned bit available for future image formats"
	bits at: 29 put: nil.	"unassigned bit available for future image formats"
	bits at: 30 put: nil.	"unassigned bit available for future image formats"
	bits at: 31 put: nil.	"unassigned bit available for future image formats"
		"If bit 32 is set, additional image format information will be stored in one or
		more additional words. Currently this is unused, and bit 32 is always zero."
	bits at: 32 put: 'the extension bit (reserved for future use)'.
	^bits

]

{ #category : #'image formats' }
ImageFormat class >> bitsInUse [
	"Answer a mask of the bits used by all known version format numbers"

	"Transcript cr; show: (ImageFormat bitsInUse printStringBase: 2)"

	| mask |
	mask := 0.
	self bitAssignments doWithIndex: [ :e :i |
		mask := mask bitAt: i put: (e notNil ifTrue: [ 1 ] ifFalse: [ 0 ])].
	^ mask

]

{ #category : #'image formats' }
ImageFormat class >> capabilitiesBitsMask [
	"Bits currently used as capability bits."
	
	"ImageFormat capabilitiesBitsMask printStringBase: 2"

	^ (0 bitAt: PlatformByteOrderBit put: 1)
		bitAt: SpurObjectBit put: 1

]

{ #category : #ckformat }
ImageFormat class >> createCkFormatProgram [
	"Create ckformat source file in the default directory"

	"ImageFormat createCkFormatProgram"

	^self storeCkFormatOnFile: 'ckformat.c' 
]

{ #category : #'instance creation' }
ImageFormat class >> default [
	"The original Squeak image format number"

	^ self wordSize: 4
]

{ #category : #'instance creation' }
ImageFormat class >> fromBytes: bytes [
	^ self fromStream: (ReadStream on: bytes)

]

{ #category : #'instance creation' }
ImageFormat class >> fromFile: imageFile [
	"Answer a new instance from a saved image file. The image format number
	is saved in the first 4 or 8 bytes of the file. Word size and byte ordering are
	dependent on the image and platform that saved the file, and must be decoded
	to obtain the image format."

	"ImageFormat fromFile: Smalltalk imageName"

	| f |
	f := (FileStream oldFileNamed: imageFile) ifNil: [FileStream readOnlyFileNamed: imageFile].
	f ifNotNil: [ | imageFormat |
		[f binary.
		imageFormat := self fromStream: f]
			ensure: [f close].
		^imageFormat].
	^self error: 'could not open ', imageFile

]

{ #category : #'instance creation' }
ImageFormat class >> fromInteger: anInteger [
	"Answer a new instance from an integer, typically obtained from an
	image file header."

	^ self new fromInteger: anInteger
]

{ #category : #'instance creation' }
ImageFormat class >> fromStream: stream [
	"Answer a new instance from a saved image file stream. Word size and byte ordering
	are dependent on the image and platform that saved the file, and must be decoded
	to obtain the image format. There may be a 512 byte offset, also."

	{ 0 . 512 } do: [:offset | | num |
		[stream position: offset.
		num := stream nextNumber: 4.  "try 32 bit big endian format"
		^ self fromInteger: num]
			on: Error
			do: [[stream position: offset.
				num := stream nextLittleEndianNumber: 4. "try 32 bit little endian format"
				^ self fromInteger: num]
				on: Error
				do: [[stream position: offset.
					num := stream nextNumber: 8. "try 64 bit big endian format"
					^ self fromInteger: num]
					on: Error
					do: [[stream position: offset.
						num := stream nextLittleEndianNumber: 8. "try 64 bit little endian format"
						^ self fromInteger: num]
						on: Error
						do: ["nothing. fall through for possible second round."]]]]].
	self error: 'unrecognized image format'
]

{ #category : #ckformat }
ImageFormat class >> generateCkFormatProgram: programName on: stream [
	"Generate source code for an image format version reader. The program
	is intended for testing image file format from a unix shell script such that
	the shell script can decide what VM to run based on image requirements."

	| formatNumber |
	stream nextPutAll: '/* ', programName, ': Print the image format number on standard output */'; cr;
			nextPutAll: '/* for use in a shell script to test image format requirements. */'; cr;
			nextPutAll: '/* A non-zero return status code indicates failure. */'; cr; cr;
			nextPutAll: '/* Usage: ', programName, ' imageFileName */'; cr; cr;
			nextPutAll: '/* --- DO NOT EDIT THIS FILE --- */'; cr;
			nextPutAll: '/* --- Automatically generated from class ', self name, ' ', DateAndTime now asString, '--- */'; cr;
			nextPutAll: '/* --- Source code is in package ImageFormat in the VMMaker repository --- */'; cr;
			nextPutAll: '/* --- DO NOT EDIT THIS FILE --- */'; cr; cr;
			nextPutAll: '#include <stdio.h>'; cr;
			nextPutAll: '#include <stdlib.h>'; cr;
			nextPutAll: '#include <string.h>'; cr; cr;
			nextPutAll: 'main(int argc, char **argv) {'; cr;
			tab; nextPutAll: 'FILE *f;'; cr;
			tab; nextPutAll: 'unsigned char buf[8];'; cr;		
			tab; nextPutAll: 'int formatNumber;'; cr;		
			tab; nextPutAll: 'unsigned char c;'; cr;		
			tab; nextPutAll: 'int match;'; cr;		
			tab; nextPutAll: 'if (argc != 2) {'; cr;
			tab; tab; nextPutAll: 'printf("usage: ', programName,  ' imageFileName\n");'; cr;
			tab; tab; nextPutAll: 'exit(1);'; cr;
			tab; nextPutAll: '}'; cr;
			tab; nextPutAll: 'f = fopen(argv[1], "r");'; cr;
			tab; nextPutAll: 'if (f == NULL) {'; cr;
			tab; tab; nextPutAll: 'perror(argv[1]);'; cr;
			tab; tab; nextPutAll: 'exit(2);'; cr;
			tab; nextPutAll: '}'; cr.
	{ 0. 512 } do: [:offset |
		stream
			tab; nextPutAll: 'if(fseek(f, '; nextPutAll: offset asString; nextPutAll: 'L, SEEK_SET) != 0) {';cr;
			tab; tab; nextPutAll: 'fprintf(stderr, "cannot go to pos %d in %s\n", '; nextPutAll: offset asString; nextPutAll: ', argv[1]);'; cr;
			tab; tab; nextPutAll: 'exit(3);'; cr;
			tab; nextPutAll: '}'; cr;
			tab; nextPutAll: 'if (fread(buf, 1, 8, f) < 8) {'; cr;
			tab; tab; nextPutAll: 'fprintf(stderr, "cannot read %s\n", argv[1]);'; cr;
			tab; tab; nextPutAll: 'exit(3);'; cr;
			tab; nextPutAll: '}'; cr.
		self versionNumberByteArrays withIndexDo: [ :v :tag | | b |
			formatNumber := (self fromBytes: v) asInteger.
			b := 'b_', formatNumber asString, '_', tag asString.
			stream tab; nextPutAll: '{'; cr; tab; nextPutAll: 'unsigned char ', b, '[', v size asString, ']= { '.
			v inject: true into: [:first : elem |
				first ifFalse: [stream nextPutAll: ', '].
				stream nextPutAll: elem asString.
				false].
			stream nextPutAll: '};'; cr;
					tab; nextPutAll: 'if (strncmp(buf, ', b, ', ', v size asString, ') == 0) {'; cr;
					tab; tab; nextPutAll: 'printf("%d\n", ', formatNumber, ');'; cr;
					tab; tab; nextPutAll: 'exit(0);'; cr;
					tab; nextPutAll: '}'; cr; tab; nextPutAll: '}'; cr]].
	stream tab; nextPutAll: 'printf("0\n"); /* print an invalid format number */';cr;
			tab; nextPutAll: 'exit (-1); /* not found, exit with error code */'; cr;
			nextPutAll: '}'; cr

]

{ #category : #'initialize-release' }
ImageFormat class >> initialize [
	"ImageFormat initialize"

	PlatformByteOrderBit := 1.
	SpurObjectBit := 5.
	BaseVersionNumbers := self baseVersionNumbers.
	BaseVersionMask := self baseVersionMask.
	CapabilitiesBitsMask := self capabilitiesBitsMask.
	ReservedBitsMask := self availableBits.
	KnownVersionNumbers := self knownVersionNumbers.

]

{ #category : #'initialize-release' }
ImageFormat class >> knownVersionNumbers [
	"Version numbers currently in use or likely to be used (e.g. 64-bit Cog formats)"

	"ImageFormat knownVersionNumbers collect: [:e | (ImageFormat fromInteger: e) description]"

	^ self baseVersionNumbers, "the original four variants"
		{
			6505 .	"Cog and StackVM"
			68003 .	"Cog and StackVM running 64-bit image"
			6521 .	"Spur 32 bit object memory"
			68019 .	"Spur 64 bit object memory (early)"
			68021 .	"Spur 64 bit object memory"
				" ... add others here as bits are allocated to represent requirements of other image formats"
		}

]

{ #category : #ckformat }
ImageFormat class >> storeCkFormatOnFile: fileName [
	"Store source code for an image format version reader in a file. The program
	is intended for testing image file format from a unix shell script such that
	the shell script can decide what VM to run based on image requirements."

	| f |
	f := CrLfFileStream newFileNamed: fileName.
	[self generateCkFormatProgram: 'ckformat' on: f]
		ensure: [f ifNotNil: [f close]].
	^fileName
]

{ #category : #ckformat }
ImageFormat class >> storeCkstatusOnFile: fileName [
	"Deprecated 07-Dec-2012, use storeCkFormatOnFile:"
	^self storeCkFormatOnFile: fileName

]

{ #category : #'instance creation' }
ImageFormat class >> thisImageFileFormat [
	"The image format read from the header of the file from which the current
	image was loaded. This may be different from the current format if the VM
	has modified the image at load time or in the course of running the image."

	"ImageFormat thisImageFileFormat description"

	^self fromFile: Smalltalk imageName

]

{ #category : #'unix magic file entries' }
ImageFormat class >> unixMagicFileEntries [
	"Answer a string that can be appended to /etc/magic on a Unix system to support the file(1) utility"

	"ImageFormat unixMagicFileEntries"

	" | fs |
	fs := FileStream newFileNamed: 'magic'.
	[ fs nextPutAll: ImageFormat unixMagicFileEntries ]
		ensure: [ fs close ] "

	^String streamContents: [:s |
		s nextPutAll: '# Smalltalk image file formats'; lf.
		KnownVersionNumbers do: [ :num | | fmt |
			#( 'le' 'be' ) do: [ :endian |
				fmt := self fromInteger: num.
				(fmt is64Bit and: [ endian = 'be' ])
					ifTrue: [ s nextPut: $4 ]
					ifFalse: [ s nextPut: $0 ].
				s tab;
				nextPutAll: endian;
				nextPutAll: 'long';
				tab;
				nextPutAll: num asString;
				tab;
				nextPutAll: 'Smalltalk '.
				fmt printTerseDescriptionOn: s.
				s lf
			]
		].
		s lf.
	]
]

{ #category : #utility }
ImageFormat class >> versionDescriptions [

	"ImageFormat versionDescriptions"
	"ImageFormat versionDescriptions do: [:e | Transcript cr; show: e]"

	^ Dictionary
		withAll: (KnownVersionNumbers
				collect: [:e | e -> (self fromInteger: e) description])
]

{ #category : #utility }
ImageFormat class >> versionNumberByteArrays [
	"All byte array expressions of known version numbers. These are the possible values
	that may appear in the first 4 or 8 bytes of a saved image file. A 64 bit image saves
	its image format number as a 64 bit value in the file header, and a 32 bit image saves
	its image format as a 32 bit value. The value may be stored in little endian or big endian
	byte ordering depending on the host platform."

	"ImageFormat versionNumberByteArrays do: [:e |
		Transcript cr; show: e printString , ': ', (ImageFormat fromBytes: e) description]"

	^self allVersionNumberByteArrays select: [:e |
		e size = (self fromBytes: e) wordSize]

]

{ #category : #'instance creation' }
ImageFormat class >> wordSize: bytesPerWord [
	bytesPerWord = 4
		ifTrue: [^self new fromInteger: 6502].
	bytesPerWord = 8
		ifTrue: [^self new fromInteger: 68000].
	self error: 'unsupported word size ', bytesPerWord
]

{ #category : #'instance creation' }
ImageFormat class >> wordSize: bytesPerWord closures: aBoolean [

	^(self wordSize: bytesPerWord) setClosureSupportRequirement: aBoolean

]

{ #category : #'instance creation' }
ImageFormat class >> wordSize: bytesPerWord cog: cogRequired [

	^(self wordSize: bytesPerWord)
		setClosureSupportRequirement: cogRequired;
		setCogSupportRequirement: cogRequired

]

{ #category : #'instance creation' }
ImageFormat class >> wordSize: bytesPerWord spur: spurRequired [
	"Answer a Spur image format, or default to Cog if Spur is not specified"

	| update64 |
	update64 := bytesPerWord == 8. "The 64 bit Spur image has an updated version"
	^self wordSize: bytesPerWord spur: spurRequired requiresNewSpur64TagAssignment: update64
]

{ #category : #'instance creation' }
ImageFormat class >> wordSize: bytesPerWord spur: spurRequired requiresNewSpur64TagAssignment: newSpur64 [
	"Answer a Spur image format, or default to Cog if Spur is not specified"

	^(self wordSize: bytesPerWord)
		setClosureSupportRequirement: true;
		setCogSupportRequirement: true;
		setSpurSupportRequirement: spurRequired;
		setRequiresNewSpur64TagAssignmentRequirement: newSpur64

]

{ #category : #converting }
ImageFormat >> asInteger [
	"Answer an integer representation of this image format suitable for storage
	in an image file header. The stored value in the file header will be used when
	loading the image from the snapshot file."

	| val |
	val := wordSize = 4
		ifTrue: [6502]
		ifFalse: [68000].
	self requiresClosureSupport ifTrue: [val := val + 2].
	self requiresNativeFloatWordOrder ifTrue: [val := val + 1].
	self requiresSpurSupport ifTrue: [val := val + 2r10000].
	self requiresNewSpur64TagAssignment ifTrue: [val := val + 2].
	^val

]

{ #category : #private }
ImageFormat >> baseVersionBits [
	"Answer the bits associated with base format number exclusive of capability bits"

	^self baseVersionBitsOf: self asInteger

]

{ #category : #private }
ImageFormat >> baseVersionBitsOf: anInteger [
	"Answer the bits of anInteger associated with base format number exclusive
	of capability bits"

	^ anInteger bitAnd: BaseVersionMask
]

{ #category : #printing }
ImageFormat >> description [

	"(ImageFormat fromInteger: 6502) description"

	^String streamContents: [:s | self printDescriptionOn: s]

]

{ #category : #'initialize-release' }
ImageFormat >> fromInteger: anInteger [
	"Initialize a new instance from anInteger obtained from an image file header."

	| baseVersion capabilitiesBits |
	(anInteger bitAnd: ReservedBitsMask) ~= 0
		ifTrue: [self error: 'invalid format number ', anInteger printString].
	baseVersion := self  baseVersionBitsOf: anInteger.
	((baseVersion = 6504 or: [baseVersion = 68002]) or: [baseVersion = 68004])
		ifTrue: [requiresClosureSupport := true].
	(baseVersion = 6502 or: [baseVersion = 6504])
		ifTrue: [wordSize := 4]
		ifFalse: [((baseVersion = 68000 or: [baseVersion = 68002]) or: [baseVersion = 68004])
			ifTrue: [wordSize := 8.
					baseVersion = 68004
						ifTrue: [self setRequiresNewSpur64TagAssignmentRequirement: true]]
			ifFalse: [self error: 'invalid format number ', anInteger printString]].
	capabilitiesBits := anInteger bitAnd: CapabilitiesBitsMask.
	(capabilitiesBits bitAt: PlatformByteOrderBit) = 1
		ifTrue: [requiresNativeFloatWordOrder := true.
			requiresClosureSupport
				ifFalse: [self error: 'Images requiring platform byte order also require closure support (Cog)'].
			capabilitiesBits := capabilitiesBits bitAt: PlatformByteOrderBit put: 0].
	(capabilitiesBits bitAt: SpurObjectBit) = 1
		ifTrue: [requiresSpurSupport := true.
			requiresClosureSupport
				ifFalse: [self error: 'Images requiring Spur also require closure support'].
			requiresNativeFloatWordOrder
				ifFalse: [self error: 'Images requiring Spur also require native float word order support'].
			capabilitiesBits := capabilitiesBits bitAt: SpurObjectBit put: 0].
	"add additional capability bit handling here"
	capabilitiesBits == 0
		ifFalse: [self error: 'invalid format number ', anInteger printString]
	

]

{ #category : #'initialize-release' }
ImageFormat >> initialize [
	requiresClosureSupport := false.
	requiresNativeFloatWordOrder := false.
	requiresSpurSupport := false.
	requiresNewSpur64TagAssignment := false.
]

{ #category : #testing }
ImageFormat >> is32Bit [
	"True if the image uses 4 byte object memory words and 4 byte object pointers."
	^wordSize = 4
]

{ #category : #testing }
ImageFormat >> is64Bit [
	"True if the image uses 8 byte object memory words and 8 byte object pointers."
	^wordSize = 8
]

{ #category : #private }
ImageFormat >> isValidVersionNumber [
	"True if the version number uses a known base version number and does not
	use any reserved bits. Used only for unit tests, by definition this must always
	be true."

	^(BaseVersionNumbers includes: self baseVersionBits)
		and: [(self asInteger bitAnd: ReservedBitsMask) = 0]
]

{ #category : #printing }
ImageFormat >> printDescriptionOn: stream [

	stream nextPutAll: 'a ';
		nextPutAll: (wordSize * 8) asString;
		nextPutAll: '-bit ';
		nextPutAll: (self requiresSpurSupport
			ifTrue: [ 'Spur' ]
			ifFalse: [ 'V3' ]);
		nextPutAll: ' image with '.
	self requiresClosureSupport ifFalse: [stream nextPutAll: 'no '].
	stream nextPutAll: 'closure support and '.
	self requiresNativeFloatWordOrder
		ifTrue: [stream nextPutAll: 'float words stored in native platform order']
		ifFalse: [stream nextPutAll: 'no native platform float word order requirement'].
	self requiresSpurSupport
		ifTrue: [stream nextPutAll: ' using Spur object format'.
			(self is64Bit and: [self requiresNewSpur64TagAssignment not])
				ifTrue: [stream nextPutAll: ' (obsolete)']].
	stream nextPutAll: ' (';
		nextPutAll: self asInteger asString;
		nextPut: $).
	^ stream

]

{ #category : #printing }
ImageFormat >> printOn: aStream [

	aStream nextPutAll: 'ImageFormat fromInteger: ', self asInteger asString

]

{ #category : #printing }
ImageFormat >> printTerseDescriptionOn: stream [
	"Shortened description as may be required for unix magic file entries"

	stream 
		nextPutAll: 'image ';
		nextPutAll: (self requiresSpurSupport
			ifTrue: [ 'Spur ' ]
			ifFalse: [ 'V3 ' ]);
		nextPutAll: (wordSize * 8) asString;
		nextPutAll: '-bit '.
	self requiresClosureSupport ifFalse: [stream nextPutAll: 'no '].
	stream nextPutAll: 'closure '.
	self requiresNativeFloatWordOrder
		ifTrue: [stream nextPutAll: 'native float']
		ifFalse: [stream nextPutAll: 'no native float'].
	stream nextPutAll: ' (';
		nextPutAll: self asInteger asString;
		nextPut: $).
	^ stream

]

{ #category : #testing }
ImageFormat >> requiresClosureSupport [
	"True if this image contains closure bytecodes that must be supported by
	the virtual machine."
	^requiresClosureSupport
]

{ #category : #testing }
ImageFormat >> requiresNativeFloatWordOrder [
	"True if this image requires a Cog VM (stack VM possibly including a Cog jitter)"
	^requiresNativeFloatWordOrder
]

{ #category : #testing }
ImageFormat >> requiresNewSpur64TagAssignment [
	"True if this is a 64 bit Spur image with immediate tag assigments redefined as of
	VMMaker.oscog-eem.1722"
	^requiresNewSpur64TagAssignment
]

{ #category : #testing }
ImageFormat >> requiresSpurSupport [
	"True if this image uses the Spur object format."
	^requiresSpurSupport
]

{ #category : #'initialize-release' }
ImageFormat >> setClosureSupportRequirement: aBoolean [
	"If true, the image expects the virtual machine to be able to provide support
	for closure bytecodes that are present in the image. If false, the image does
	not require this support, although the virtual machine is free to provide it."

	requiresClosureSupport := aBoolean

]

{ #category : #'initialize-release' }
ImageFormat >> setCogSupportRequirement: aBoolean [
	"If true, the image expects the virtual machine to be able to provide Cog
	support, either in the form of a Stack VM or a Cog VM. If false, the image does
	not require this support, although the virtual machine is free to provide it."

	aBoolean ifTrue: [requiresClosureSupport := true]. "required in all Cog images"
	self setNativeFloatWordOrderRequirement: aBoolean

]

{ #category : #'initialize-release' }
ImageFormat >> setNativeFloatWordOrderRequirement: aBoolean [
	"If true, certain objects are implemented in native platform word order. On
	a little endian platform, access to the two words of a 64 bit float object is
	more efficient if the words are stored in native word order. On a big endian
	platform, platform word order is the same as object memory word order and
	this setting has no effect.
	
	The StackInterpreter and Cog make use of this for performance reasons."

	requiresNativeFloatWordOrder := aBoolean

]

{ #category : #'initialize-release' }
ImageFormat >> setRequiresNewSpur64TagAssignmentRequirement: aBoolean [
	"Applicable only to 64-bit Spur images. If true, the updated tag assignment
	definitions are required. Earlier Spur 64 bit images use tag assignment for
	immediates that conflict with the Spur 32 bit image definition. "

	requiresNewSpur64TagAssignment := aBoolean

]

{ #category : #'initialize-release' }
ImageFormat >> setSpurSupportRequirement: aBoolean [
	"If true, the image expects the virtual machine to be able to provide support
	for the Spur object format. If false, the image does not require this support,
	although the virtual machine is free to provide it."

	requiresSpurSupport := aBoolean

]

{ #category : #printing }
ImageFormat >> storeOn: aStream [ 
	"Append to the argument aStream a sequence of characters that is an 
	expression whose evaluation creates an object similar to the receiver."

	aStream nextPutAll: self class name;
		nextPutAll: ' fromInteger: ';
		nextPutAll: self asInteger asString
]

{ #category : #accessing }
ImageFormat >> wordSize [
	^ wordSize
]
