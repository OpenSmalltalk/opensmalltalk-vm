"
An ImageFileHeader represents the information in the header block of an image file, used by an interpreter VM. Subclasses may implement extensions for Cog or other header extensions.

Instance variables correspond to the fields in an image file header. An instance of ImageFileHeader may be created by reading from an image file, and an ImageFileHeader may be written to a file.

When stored to a file, the file header fields may be 32 or 64 bits in size, depending on the image format. The byte ordering of each field will be little endian or big endian, depending on the convention of the host platform. When reading from disk, endianness is inferred from the contents of the first data field.

To explore the file header of an image file:

  | fs |
  fs := (FileStream readOnlyFileNamed: Smalltalk imageName) binary.
  ([ImageFileHeader readFrom: fs] ensure: [fs close]) explore

"
Class {
	#name : #ImageFileHeader,
	#superclass : #Object,
	#instVars : [
		'imageFormat',
		'headerSize',
		'imageBytes',
		'startOfMemory',
		'specialObjectsOop',
		'lastHash',
		'screenSize',
		'imageHeaderFlags',
		'extraVMMemory'
	],
	#category : #'ImageFormat-Header'
}

{ #category : #'instance creation' }
ImageFileHeader class >> readFrom: aStream [

	^self readFrom: aStream startingAt: 0
]

{ #category : #'instance creation' }
ImageFileHeader class >> readFrom: aStream startingAt: imageOffset [

	^self basicNew readFrom: aStream startingAt: imageOffset
]

{ #category : #converting }
ImageFileHeader >> asByteArray [
	^ ByteArray
		streamContents: [:strm | self writeTo: strm littleEndian: Smalltalk isLittleEndian]
]

{ #category : #accessing }
ImageFileHeader >> extraVMMemory [

	^ extraVMMemory
]

{ #category : #accessing }
ImageFileHeader >> extraVMMemory: anObject [

	extraVMMemory := anObject
]

{ #category : #accessing }
ImageFileHeader >> headerSize [

	^ headerSize
]

{ #category : #accessing }
ImageFileHeader >> headerSize: anObject [

	headerSize := anObject
]

{ #category : #accessing }
ImageFileHeader >> imageBytes [

	^ imageBytes
]

{ #category : #accessing }
ImageFileHeader >> imageBytes: anObject [

	imageBytes := anObject
]

{ #category : #accessing }
ImageFileHeader >> imageFormat [

	^ imageFormat
]

{ #category : #accessing }
ImageFileHeader >> imageFormat: anObject [

	imageFormat := anObject
]

{ #category : #accessing }
ImageFileHeader >> imageHeaderFlags [

	^ imageHeaderFlags
]

{ #category : #accessing }
ImageFileHeader >> imageHeaderFlags: anObject [

	imageHeaderFlags := anObject
]

{ #category : #accessing }
ImageFileHeader >> lastHash [

	^ lastHash
]

{ #category : #accessing }
ImageFileHeader >> lastHash: anObject [

	lastHash := anObject
]

{ #category : #reading }
ImageFileHeader >> nextNumber: length from: aStream littleEndian: littleEnder [

	littleEnder
		ifTrue: [^aStream nextLittleEndianNumber: length]
		ifFalse: [^aStream nextNumber: length]
]

{ #category : #writing }
ImageFileHeader >> nextNumber: n put: v to: aStream littleEndian: littleEnder [

	littleEnder
		ifTrue: [^aStream nextLittleEndianNumber: n put: v]
		ifFalse: [^aStream nextNumber: n put: v]
]

{ #category : #printing }
ImageFileHeader >> printOn: aStream [

	super printOn: aStream.
	imageFormat ifNotNil: [
		aStream nextPutAll: ' for '.
		imageFormat printDescriptionOn: aStream]
]

{ #category : #reading }
ImageFileHeader >> readFieldsFrom: aStream startingAt: imageOffset headerWordSize: headerWordSize littleEndian: littleEndian [
	"Read data fields and answer number of bytes read"

	| remainder |
	headerSize := self nextNumber: headerWordSize from: aStream littleEndian: littleEndian.
	imageBytes := self nextNumber: headerWordSize from: aStream littleEndian: littleEndian.
	startOfMemory := self nextNumber: headerWordSize from: aStream littleEndian: littleEndian.
	specialObjectsOop := self nextNumber: headerWordSize from: aStream littleEndian: littleEndian.
	lastHash := self nextNumber: headerWordSize from: aStream littleEndian: littleEndian.
	self screenSize: (self nextNumber: headerWordSize from: aStream littleEndian: littleEndian).
	imageHeaderFlags := self nextNumber: headerWordSize from: aStream littleEndian: littleEndian.
	extraVMMemory := self nextNumber: headerWordSize from: aStream littleEndian: littleEndian.
	remainder := headerSize - (9 * imageFormat wordSize).
	self assert: remainder >= 0. "n.b. Mantis 7455 bug in original 64 bit image due to VMM error"
	^9 * imageFormat wordSize.

]

{ #category : #reading }
ImageFileHeader >> readFrom: aStream startingAt: imageOffset [

	| remainder bytesRead headerWordSize littleEndian |
	littleEndian := self readImageVersionFrom: aStream startingAt: imageOffset.
	headerWordSize := aStream position - imageOffset.
	bytesRead := self readFieldsFrom: aStream startingAt: imageOffset headerWordSize: headerWordSize littleEndian: littleEndian.
	remainder := headerSize - bytesRead.
	self assert: remainder >= 0. "n.b. Mantis 7455 bug in original 64 bit image due to VMM error"
	aStream next: (headerSize - bytesRead).

]

{ #category : #reading }
ImageFileHeader >> readImageVersionFrom: aStream startingAt: imageOffset [
	"Look for image format in the next 4 or 8 bytes and set imageFormat. Answer true
	if the header is written in little endian format."

	(aStream nextNumber: 4) caseOf:
		{
			[ 16r00001966 "6502" ] -> [ imageFormat := ImageFormat fromInteger: 6502. ^false ] .
			[ 16r66190000 "6502" ] -> [ imageFormat := ImageFormat fromInteger: 6502. ^true ] .
			[ 16r00001968 "6504" ] -> [ imageFormat := ImageFormat fromInteger: 6504. ^false ] .
			[ 16r68190000 "6504" ] -> [ imageFormat := ImageFormat fromInteger: 6504. ^true ] .
			[ 16r00001969 "6505" ] -> [ imageFormat := ImageFormat fromInteger: 6505. ^false ] .
			[ 16r69190000 "6505" ] -> [ imageFormat := ImageFormat fromInteger: 6505. ^true ] .
			[ 16rA0090100 "68000" ] -> [ imageFormat := ImageFormat fromInteger: 68000. aStream next: 4. ^true ] .
			[ 16rA2090100 "68002" ] -> [ imageFormat := ImageFormat fromInteger: 68002. aStream next: 4. ^true ] .
			[ 16rA3090100 "68003" ] -> [ imageFormat := ImageFormat fromInteger: 68003. aStream next: 4. ^true ] .
			[ 16r00000000 ] -> [
				(aStream nextNumber: 4) caseOf: {
					[ 16r000109A0 "68000" ] -> [ imageFormat := ImageFormat fromInteger: 68000. ^false ] .
					[ 16r000109A2 "68002" ] -> [ imageFormat := ImageFormat fromInteger: 68002. ^false ] .
					[ 16r000109A3 "68003" ] -> [ imageFormat := ImageFormat fromInteger: 68003. ^false ] .
				} otherwise: [self error: self asString , ' unrecognized format number']
			]
		} otherwise: [self error: self asString , ' unrecognized format number']
	
	"ImageFormat versionNumberByteArrays do: [:e |
		Transcript cr; show: e printString , ': ', (ImageFormat fromBytes: e) description]
	
#[0 0 25 102]: A 32-bit image with no closure support and no native platform float word order requirement (6502)
#[102 25 0 0]: A 32-bit image with no closure support and no native platform float word order requirement (6502)
#[0 0 25 104]: A 32-bit image with closure support and no native platform float word order requirement (6504)
#[104 25 0 0]: A 32-bit image with closure support and no native platform float word order requirement (6504)
#[0 0 0 0 0 1 9 160]: A 64-bit image with no closure support and no native platform float word order requirement (68000)
#[160 9 1 0 0 0 0 0]: A 64-bit image with no closure support and no native platform float word order requirement (68000)
#[0 0 0 0 0 1 9 162]: A 64-bit image with closure support and no native platform float word order requirement (68002)
#[162 9 1 0 0 0 0 0]: A 64-bit image with closure support and no native platform float word order requirement (68002)
#[0 0 25 105]: A 32-bit image with closure support and float words stored in native platform order (6505)
#[105 25 0 0]: A 32-bit image with closure support and float words stored in native platform order (6505)
#[0 0 0 0 0 1 9 163]: A 64-bit mage with closure support and float words stored in native platform order (68003)
#[163 9 1 0 0 0 0 0]: A 64-bit image with closure support and float words stored in native platform order (68003)
	
	"
	
]

{ #category : #accessing }
ImageFileHeader >> screenSize [
	"World extent at the time of image save, packed into 32 bit integer when
	saved to file header."

	"right=  windowBounds.x + ((unsigned)savedWindowSize >> 16);
	bottom= windowBounds.y + (savedWindowSize & 0xFFFF);"

	^ screenSize
]

{ #category : #accessing }
ImageFileHeader >> screenSize: anIntegerOrPoint [
	"World extent at the time of image save, packed into 32 bit integer when
	saved to file header."

	"right=  windowBounds.x + ((unsigned)savedWindowSize >> 16);
	bottom= windowBounds.y + (savedWindowSize & 0xFFFF);"

	anIntegerOrPoint isInteger
		ifTrue: [screenSize := ((anIntegerOrPoint >> 16) @ (anIntegerOrPoint bitAnd: 16rFFFF))]
		ifFalse: [screenSize := anIntegerOrPoint]

]

{ #category : #accessing }
ImageFileHeader >> specialObjectsOop [

	^ specialObjectsOop
]

{ #category : #accessing }
ImageFileHeader >> specialObjectsOop: anObject [

	specialObjectsOop := anObject
]

{ #category : #accessing }
ImageFileHeader >> startOfMemory [

	^ startOfMemory
]

{ #category : #accessing }
ImageFileHeader >> startOfMemory: anObject [

	startOfMemory := anObject
]

{ #category : #printing }
ImageFileHeader >> storeOn: aStream [ 
	"Append to the argument aStream a sequence of characters that is an 
	expression whose evaluation creates an object similar to the receiver."

	aStream nextPutAll: self class name;
		nextPutAll: ' new imageFormat: ('.
	imageFormat storeOn: aStream.

	aStream nextPutAll: '); headerSize: '.
	headerSize storeOn: aStream.

	aStream nextPutAll: '; imageBytes: '.
	imageBytes storeOn: aStream.

	aStream nextPutAll: '; startOfMemory: '.
	startOfMemory storeOn: aStream.

	aStream nextPutAll: '; specialObjectsOop: '.
	specialObjectsOop storeOn: aStream.

	aStream nextPutAll: '; lastHash: '.
	lastHash storeOn: aStream.
	
	aStream nextPutAll: '; screenSize: '.
	screenSize storeOn: aStream.
	
	aStream nextPutAll: '; imageHeaderFlags: '.
	imageHeaderFlags storeOn: aStream.
	
	aStream nextPutAll: '; extraVMMemory: '.
	extraVMMemory storeOn: aStream.
	

]

{ #category : #writing }
ImageFileHeader >> writeFieldsTo: aStream littleEndian: littleEnder headerWordSize: headerWordSize [
	"Write data fields and answer number of bytes written"

	self nextNumber: headerWordSize put: imageFormat asInteger to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize put: headerSize to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize put: imageBytes to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize put: startOfMemory to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize put: specialObjectsOop to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize put: lastHash to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize put: ((screenSize x) << 16 + (screenSize y)) to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize put: imageHeaderFlags to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize put: extraVMMemory to: aStream littleEndian: littleEnder.
	^9 * imageFormat wordSize.

]

{ #category : #writing }
ImageFileHeader >> writeTo: aStream littleEndian: littleEnder [

	| headerWordSize remainder bytesWritten |
	headerWordSize := imageFormat wordSize.
	bytesWritten := self writeFieldsTo: aStream littleEndian: littleEnder headerWordSize: headerWordSize.
	remainder := headerSize - bytesWritten.
	self assert: remainder >= 0. "n.b. Mantis 7455 bug in original 64 bit image due to VMM error"
	remainder timesRepeat: [aStream nextPut: 0].

]
