"
CogImageFileHeader is an extension of ImageFileHeader with additional fields that are used by Cog and Stack VMs. Some of the additional fields are encoded as short short integers, which are 16 bits when the header word size is 32, and 32 bits when the header word size is 64. All current Cog VMs use 32 bit word size with 16 bit short integer fields.
"
Class {
	#name : #CogImageFileHeader,
	#superclass : #ImageFileHeader,
	#instVars : [
		'desiredNumStackPages',
		'unknownShortOrCodeSizeInKs',
		'desiredEdenBytes',
		'maxExtSemTabSizeSet'
	],
	#category : #'ImageFormat-Header'
}

{ #category : #accessing }
CogImageFileHeader >> desiredEdenBytes [

	^ desiredEdenBytes
]

{ #category : #accessing }
CogImageFileHeader >> desiredEdenBytes: anInteger [

	desiredEdenBytes := anInteger
]

{ #category : #accessing }
CogImageFileHeader >> desiredNumStackPages [

	^ desiredNumStackPages
]

{ #category : #accessing }
CogImageFileHeader >> desiredNumStackPages: anInteger [

	desiredNumStackPages := anInteger
]

{ #category : #accessing }
CogImageFileHeader >> maxExtSemTabSizeSet [

	^ maxExtSemTabSizeSet
]

{ #category : #accessing }
CogImageFileHeader >> maxExtSemTabSizeSet: anInteger [

	maxExtSemTabSizeSet := anInteger
]

{ #category : #reading }
CogImageFileHeader >> readFieldsFrom: aStream startingAt: imageOffset headerWordSize: headerWordSize littleEndian: littleEndian [
	"Read data fields and answer number of bytes read"

	| remainder bytesRead |
	bytesRead := super readFieldsFrom: aStream startingAt: imageOffset headerWordSize: headerWordSize littleEndian: littleEndian.
	desiredNumStackPages := self nextNumber: headerWordSize / 2 from: aStream littleEndian: littleEndian.
	unknownShortOrCodeSizeInKs := self nextNumber: headerWordSize / 2 from: aStream littleEndian: littleEndian.
	desiredEdenBytes := self nextNumber: headerWordSize from: aStream littleEndian: littleEndian.
	maxExtSemTabSizeSet := self nextNumber: headerWordSize / 2 from: aStream littleEndian: littleEndian.
	self nextNumber: headerWordSize / 2 from: aStream littleEndian: littleEndian.
	remainder := headerSize - (12 * imageFormat wordSize).
	self assert: remainder >= 0. "n.b. Mantis 7455 bug in original 64 bit image due to VMM error"
	^3 * imageFormat wordSize + bytesRead.

]

{ #category : #printing }
CogImageFileHeader >> storeOn: aStream [ 
	"Append to the argument aStream a sequence of characters that is an 
	expression whose evaluation creates an object similar to the receiver."

	super storeOn: aStream.

	aStream nextPutAll: '; desiredNumStackPages: '.
	desiredNumStackPages storeOn: aStream.

	aStream nextPutAll: '; unknownShortOrCodeSizeInKs: '.
	unknownShortOrCodeSizeInKs storeOn: aStream.

	aStream nextPutAll: '; desiredEdenBytes: '.
	desiredEdenBytes storeOn: aStream.

	aStream nextPutAll: '; maxExtSemTabSizeSet: '.
	maxExtSemTabSizeSet storeOn: aStream.

]

{ #category : #accessing }
CogImageFileHeader >> unknownShortOrCodeSizeInKs [

	^ unknownShortOrCodeSizeInKs
]

{ #category : #accessing }
CogImageFileHeader >> unknownShortOrCodeSizeInKs: anInteger [

	unknownShortOrCodeSizeInKs := anInteger
]

{ #category : #writing }
CogImageFileHeader >> writeFieldsTo: aStream littleEndian: littleEnder headerWordSize: headerWordSize [
	"Write data fields and answer number of bytes written"

	| bytesWritten |
	bytesWritten := super writeFieldsTo: aStream littleEndian: littleEnder headerWordSize: headerWordSize.
	self nextNumber: headerWordSize / 2 put: desiredNumStackPages to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize / 2 put: unknownShortOrCodeSizeInKs to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize put: desiredEdenBytes to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize / 2 put: maxExtSemTabSizeSet to: aStream littleEndian: littleEnder.
	self nextNumber: headerWordSize / 2 put: 0 to: aStream littleEndian: littleEnder.
	^3 * imageFormat wordSize + bytesWritten.

]
