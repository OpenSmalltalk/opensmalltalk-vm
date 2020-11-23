"
For Simulating the Interpreter only.  Coercing an Integer to a pointer (eg. cCoerce:to: 'char *') returns a CArray.  A CArray responds to at: and at:put: by reading/writing from the memory of the interpreter that sent the cCoerce:to: message in the first place.  A CArray responds to arithmetic by returning the new address.  Since longAt: sends // to its given address this is where the CArray converts back to a Integer for the memory fetch to work.
"
Class {
	#name : #CArray,
	#superclass : #Object,
	#instVars : [
		'interpreter',
		'arrayBaseAddress',
		'ptrOffset',
		'unitSize'
	],
	#category : #'Slang-Types'
}

{ #category : #'int arithmetic' }
CArray >> + n [
	^self shallowCopy += (n * unitSize)
]

{ #category : #'pointer arithmetic' }
CArray >> += increment [

	ptrOffset := ptrOffset + increment
]

{ #category : #'int arithmetic' }
CArray >> - n [
	^self shallowCopy -= (n * unitSize)
]

{ #category : #'pointer arithmetic' }
CArray >> -= decrement [

	ptrOffset := ptrOffset - decrement
]

{ #category : #comparing }
CArray >> = anObject [
	^self species = anObject species
	  and: [(1 to: self class instSize) allSatisfy:
			[:i| (self instVarAt: i) = (anObject instVarAt: i)]]
]

{ #category : #converting }
CArray >> adaptToNumber: rcvr andSend: selector [

	^ rcvr perform: selector with: self asInteger
]

{ #category : #converting }
CArray >> asByteArray [
	"Answer a ByteArray containing the receivers contents"
	| size bytes base |
	size := interpreter byteSizeOf: self cPtrAsOop.
	bytes := ByteArray new: size.
	base := arrayBaseAddress + ptrOffset - 1.
	1 to: size do:
		[:index|
		bytes at: index put: (interpreter byteAt: base + index)].
	^bytes
]

{ #category : #converting }
CArray >> asCArrayAccessor [

	^ (CArrayAccessor on: self)
			+= -1   "Defeat the +1 offset in the accessor"
]

{ #category : #converting }
CArray >> asDoubleFloatAccessor [
	| accessor |
	CFloatArray adoptInstance: (accessor := self shallowCopy unitSize: 8).
	^accessor
]

{ #category : #converting }
CArray >> asInteger [

	^ self ptrAddress
]

{ #category : #converting }
CArray >> asSingleFloatAccessor [
	| accessor |
	CFloatArray adoptInstance: (accessor := self shallowCopy unitSize: 4).
	^accessor
]

{ #category : #accessing }
CArray >> at: offset [
	| address |
	address := unitSize * offset + self ptrAddress.
	^unitSize <= 2
		ifTrue:
			[unitSize = 1
				ifTrue: [interpreter byteAt: address]
				ifFalse: [interpreter shortAt: address]]
		ifFalse:
			[unitSize = 4
				ifTrue: [interpreter long32At: address]
				ifFalse: [interpreter long64At: address]]
]

{ #category : #accessing }
CArray >> at: offset put: val [
	| address |
	address := unitSize * offset + self ptrAddress.
	^unitSize <= 2
		ifTrue:
			[unitSize = 1
				ifTrue: [interpreter byteAt: address put: val]
				ifFalse: [interpreter shortAt: address put: val]]
		ifFalse:
			[unitSize = 4
				ifTrue: [interpreter long32At: address put: val]
				ifFalse: [interpreter long64At: address put: val]]
]

{ #category : #accessing }
CArray >> cPtrAsOop [
	ptrOffset = 0 ifFalse: [self error: 'offset must be zero'].
	^arrayBaseAddress - interpreter baseHeaderSize
]

{ #category : #converting }
CArray >> coerceTo: cTypeString sim: interpreterSimulator [

	^cTypeString caseOf: {
		['int']				-> [self ptrAddress].
		['float *']			-> [self asSingleFloatAccessor].
		['double *']			-> [self asDoubleFloatAccessor].
		['sqInt *']			-> [self shallowCopy unitSize: interpreter bytesPerOop; yourself].
		['unsigned int *']	-> [self shallowCopy unitSize: 4; yourself].
		['int *']				-> [self shallowCopy unitSize: 4; yourself].
		['char *']			-> [self shallowCopy unitSize: 1; yourself].
		['void *']			-> [self shallowCopy unitSize: 1; yourself].
		['void **']			-> [self shallowCopy unitSize: interpreter bytesPerOop; yourself].
		['unsigned char *']	-> [self shallowCopy unitSize: 1; yourself].
		['unsigned']		-> [self ptrAddress].
		['sqInt']				-> [self ptrAddress].
		['usqInt']			-> [self ptrAddress].
		['sqIntptr_t']		-> [self shallowCopy unitSize: interpreter bytesPerOop; yourself] }
]

{ #category : #converting }
CArray >> doesNotUnderstand: message [

	^ self asInteger perform: message selector withArguments: message arguments
]

{ #category : #accessing }
CArray >> floatAt: index [
	^ Float fromIEEE32Bit: (self at: index)
]

{ #category : #accessing }
CArray >> floatAt: index put: value [
	^ self at: index put: value asIEEE32BitWord
]

{ #category : #comparing }
CArray >> hash [
	^interpreter hash bitXor: arrayBaseAddress + ptrOffset + unitSize
]

{ #category : #accessing }
CArray >> intAt: index [
	^ (self at: index) signedIntFromLong
]

{ #category : #accessing }
CArray >> intAt: index put: signedInt [
	^ self at: index put: signedInt signedIntToLong
]

{ #category : #private }
CArray >> interpreter: interpreterSimulator address: arrayAddress unitSize: numBytes [

	interpreter := interpreterSimulator.
	arrayBaseAddress := arrayAddress.
	self unitSize: numBytes.
	ptrOffset := 0
]

{ #category : #testing }
CArray >> isCArray [
	"Answer a boolean indicating whether the receiver responds to the CArray interface"

	^true
]

{ #category : #accessing }
CArray >> overwriteContentsWith: aByteArray [
	| base size |
	self assert: (interpreter isWordsOrBytes: self cPtrAsOop).
	size := (interpreter byteSizeOf: self cPtrAsOop) min: aByteArray size.
	base := arrayBaseAddress + ptrOffset - 1.
	1 to: size do:
		[:index|
		interpreter byteAt: base + index put: (aByteArray at: index)]
]

{ #category : #private }
CArray >> ptrAddress [

	^ arrayBaseAddress + ptrOffset
]

{ #category : #accessing }
CArray >> unitSize [
	^unitSize
]

{ #category : #accessing }
CArray >> unitSize: n [
	(n isPowerOfTwo and: [n <= 8]) ifFalse:
		[self error: 'unitSize must be 1, 2, 4 or 8'].
	unitSize := n
]

{ #category : #accessing }
CArray >> unsignedIntAt: index [
	^self at: index
]

{ #category : #accessing }
CArray >> unsignedIntAt: index put: unsignedInt [
	^ self at: index put: unsignedInt
]
