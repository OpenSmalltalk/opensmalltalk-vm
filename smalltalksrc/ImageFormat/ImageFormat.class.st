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
		'requiresPlatformByteOrder',
		'requiresCogSupport'
	],
	#classVars : [
		'BaseVersionMask',
		'BaseVersionNumbers',
		'CapabilitiesBitsMask',
		'KnownVersionNumbers',
		'PlatformByteOrderBit',
		'ReservedBitsMask'
	],
	#category : #ImageFormat
}

{ #category : #'initialize-release' }
ImageFormat class >> baseVersionMask [
	"Mask the bits associated with base format number exclusive of capability bits"

	"ImageFormat baseVersionMask printStringBase: 2"

	^ BaseVersionNumbers
		inject: 0
		into: [:accum :e | accum bitOr: e]

]

{ #category : #'initialize-release' }
ImageFormat class >> baseVersionNumbers [
	"The well-known image format versions for basic 32 and 64 bit images,
	including images that require closure bytecode support. These base
	format numbers my be modified by application of various capability bits
	representing additional requirements that the image expects to be
	supported by the virtual machine."

	^#(6502 6504 68000 68002)

]

{ #category : #'image formats' }
ImageFormat class >> bitsInUse [
	"Answer a mask of the bits used by all known version format numbers"

	"Transcript cr; show: (ImageFormat bitsInUse printStringBase: 2)"

	^ self baseVersionMask bitOr: self capabilitiesBitsMask
]

{ #category : #'initialize-release' }
ImageFormat class >> capabilitiesBitsMask [
	"Bits currently used as capability bits."
	
	"ImageFormat capabilitiesBitsMask printStringBase: 2"

	^PlatformByteOrderBit "only one so far"

]

{ #category : #'instance creation' }
ImageFormat class >> default [
	"The original Squeak image format number"

	^ self wordSize: 4
]

{ #category : #'instance creation' }
ImageFormat class >> fromFile: imageFile [
	"Answer a new instance from a saved image file. The image format number
	is saved in the first 4 or 8 bytes of the file. Word size and byte ordering are
	dependent on the image and platform that saved the file, and must be decoded
	to obtain the image format."

	"ImageFormat fromFile: Smalltalk imageName"

	| f formatNumberBytes rs num |
	f := FileStream fileNamed: imageFile.
	f binary.
	[formatNumberBytes := f next: 8]
		ensure: [f close].
	rs := ReadStream on: formatNumberBytes.
	num := rs nextNumber: 8. "try 64 bit big endian format"
	[^ self fromInteger: num]
		on: Error
		do: [rs position: 0.
			num := rs nextLittleEndianNumber: 8. "try 64 bit little endian format"
			^ self fromInteger: num]
			on: Error
			do: [rs position: 0.
				num := rs nextNumber: 4.  "try 32 bit big endian format"
				^ self fromInteger: num]
				on: Error
				do: [rs position: 0.
					num := rs nextLittleEndianNumber: 4. "try 32 bit little endian format"
					^ self fromInteger: num].
	self error: 'unrecognized image format'
]

{ #category : #'instance creation' }
ImageFormat class >> fromInteger: anInteger [
	"Answer a new instance from an integer, typically obtained from an
	image file header."

	^ self new fromInteger: anInteger
]

{ #category : #'initialize-release' }
ImageFormat class >> initialize [
	"ImageFormat initialize"

	BaseVersionNumbers := self baseVersionNumbers.
	BaseVersionMask := self baseVersionMask.
	CapabilitiesBitsMask := self capabilitiesBitsMask.
	ReservedBitsMask := self reservedBitsMask.
	KnownVersionNumbers := self knownVersionNumbers.
	PlatformByteOrderBit := 1
]

{ #category : #'initialize-release' }
ImageFormat class >> knownVersionNumbers [
	"Version number currently in use or likely to be used (e.g. 64-bit Cog formats)"

	"ImageFormat knownVersionNumbers collect: [:e | (ImageFormat fromInteger: e) description]"

	^ #(6502 6504 6505 68000 68002 68003)
]

{ #category : #'initialize-release' }
ImageFormat class >> reservedBitsMask [
	"Bits available for use as capability bits. Reserve high order bit as the
	extension bit, to be set true if additional bits are required in the future."
	
	"ImageFormat reservedBitsMask printStringBase: 2"

	^(16rFFFFFFFF bitXor: BaseVersionMask)
		bitAt: PlatformByteOrderBit put: 0

]

{ #category : #'image formats' }
ImageFormat class >> versionDescriptions [

	"ImageFormat versionDescriptions"
	"ImageFormat versionDescriptions do: [:e | Transcript cr; show: e]"

	^ Dictionary
		withAll: (KnownVersionNumbers
				collect: [:e | e -> (self fromInteger: e) description])
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
	self requiresPlatformByteOrder ifTrue: [val := val + 1].
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
	(baseVersion = 6504 or: [baseVersion = 68002])
		ifTrue: [requiresClosureSupport := true].
	(baseVersion = 6502 or: [baseVersion = 6504])
		ifTrue: [wordSize := 4]
		ifFalse: [(baseVersion = 68000 or: [baseVersion = 68002])
			ifTrue: [wordSize := 8]
			ifFalse: [self error: 'invalid format number ', anInteger printString]].
	capabilitiesBits := anInteger bitAnd: CapabilitiesBitsMask.
	(capabilitiesBits bitAt: PlatformByteOrderBit) = 1
		ifTrue: [requiresPlatformByteOrder := true.
			requiresClosureSupport
				ifFalse: [self error: 'Images requiring platform byte order also require closure support (Cog)'].
			capabilitiesBits := capabilitiesBits bitAt: PlatformByteOrderBit put: 0].
	"add additional capability bit handling here"
	capabilitiesBits == 0
		ifFalse: [self error: 'invalid format number ', anInteger printString]
	

]

{ #category : #'initialize-release' }
ImageFormat >> initialize [
	requiresClosureSupport := false.
	requiresPlatformByteOrder := false
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

		stream nextPutAll: 'A ';
			nextPutAll: (wordSize * 8) asString;
			nextPutAll: '-bit image with '.
		self requiresClosureSupport ifFalse: [stream nextPutAll: 'no '].
		stream nextPutAll: 'closure support and '.
		self requiresPlatformByteOrder ifFalse: [stream nextPutAll: 'no '].
		stream nextPutAll: 'Cog byte reversal'.
		stream nextPutAll: ' (';
			nextPutAll: self asInteger asString;
			nextPut: $).
		^ stream

]

{ #category : #printing }
ImageFormat >> printOn: aStream [

	aStream nextPutAll: 'ImageFormat fromInteger: ', self asInteger asString

]

{ #category : #testing }
ImageFormat >> requiresClosureSupport [
	"True if this image contains closure bytecodes that must be supported by
	the virtual machine."
	^requiresClosureSupport
]

{ #category : #testing }
ImageFormat >> requiresPlatformByteOrder [
	"True if this image requires a Cog VM (stack VM possibly including a Cog jitter)"
	^requiresPlatformByteOrder
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
	self setPlatformByteOrderRequirement: aBoolean

]

{ #category : #'initialize-release' }
ImageFormat >> setPlatformByteOrderRequirement: aBoolean [
	"If true, certain object are implemented in native platform byte order.
	The StackInterpreter and Cog make use of this for performance reasons."

	requiresPlatformByteOrder := aBoolean

]

{ #category : #accessing }
ImageFormat >> wordSize [
	^ wordSize
]
