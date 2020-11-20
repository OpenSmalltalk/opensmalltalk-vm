"
I am used to simulate the indexed access to any object during plugin simulation.
"
Class {
	#name : #CObjectAccessor,
	#superclass : #Object,
	#instVars : [
		'object',
		'offset'
	],
	#category : #'Slang-Types'
}

{ #category : #accessing }
CObjectAccessor class >> alignedByteSizeOf: aCObjectAccessor forClient: aVMClass [
	"Hack; this only works if the object is actually bytes."
	^aCObjectAccessor object size
]

{ #category : #'instance creation' }
CObjectAccessor class >> on: anObject [
	^self new setObject: anObject
]

{ #category : #'pointer arithmetic' }
CObjectAccessor >> + increment [
	^self shallowCopy += increment
]

{ #category : #'pointer arithmetic' }
CObjectAccessor >> += increment [
	offset := offset + increment
]

{ #category : #'pointer arithmetic' }
CObjectAccessor >> - decrement [
	^self shallowCopy -= decrement
]

{ #category : #'pointer arithmetic' }
CObjectAccessor >> -= decrement [
	offset := offset - decrement
]

{ #category : #converting }
CObjectAccessor >> asDoubleAccessor [

	^ self asPluggableAccessor
		atBlock: [:obj :index | obj doubleAt: index]
		atPutBlock: [:obj :index :value | obj doubleAt: index put: value]
]

{ #category : #converting }
CObjectAccessor >> asFloatAccessor [

	^ self asPluggableAccessor
		atBlock: [:obj :index | obj floatAt: index]
		atPutBlock: [:obj :index :value | obj floatAt: index put: value]
]

{ #category : #converting }
CObjectAccessor >> asIntAccessor [

	^ self asPluggableAccessor
		atBlock: [:obj :index | obj intAt: index]
		atPutBlock: [:obj :index :value | obj intAt: index put: value]
]

{ #category : #transformation }
CObjectAccessor >> asIntAccessorOfSize: byteSize signed: isSigned [ 

	^ self asPluggableAccessor
		atBlock: [:obj :index | obj integerAt: index size: byteSize signed: isSigned ]
		atPutBlock: [:obj :index :value | obj integerAt: index put: value size: byteSize signed: isSigned ]
]

{ #category : #converting }
CObjectAccessor >> asInteger [

	^ self
]

{ #category : #converting }
CObjectAccessor >> asOop: aClass [

	(aClass ccgCanConvertFrom: object)
		ifFalse: [^self error: 'incompatible object for autocoercion'].
	^object
]

{ #category : #converting }
CObjectAccessor >> asPluggableAccessor [
	^ (CPluggableAccessor on: object) += offset
]

{ #category : #converting }
CObjectAccessor >> asPluggableAccessor: accessorArray [
	^((CPluggableAccessor on: object) += offset)
		atBlock: accessorArray first
		atPutBlock: accessorArray last
]

{ #category : #converting }
CObjectAccessor >> asPointerAccessor: wordSize [

	^ self asPluggableAccessor
		atBlock: [ :obj :index | obj integerAt: index size: wordSize signed: false ]
		atPutBlock: [ :obj :index :value | obj integerAt: index put: value size: wordSize signed: false ]
]

{ #category : #accessing }
CObjectAccessor >> at: index [
	^object instVarAt: index + offset + 1
]

{ #category : #accessing }
CObjectAccessor >> at: index put: value [
	^object instVarAt: index + offset + 1 put: value
]

{ #category : #converting }
CObjectAccessor >> coerceTo: cTypeString sim: interpreterSimulator [

	cTypeString caseOf: {
		[#'float *']			-> [^self asFloatAccessor].
		[#'double *']		-> [^self asDoubleAccessor].
		[#'int *']			-> [^self asIntAccessor].
		[#'void **']			-> [^self asPointerAccessor: interpreterSimulator objectMemory wordSize].
		[#'int8_t *']		-> [^self asIntAccessorOfSize: 1 signed: true ].
		[#'uint8_t *']		-> [^self asIntAccessorOfSize: 1 signed: false ].
		[#'char *']		-> [^self asIntAccessorOfSize: 1 signed: false ].
		[#'int16_t *']		-> [^self asIntAccessorOfSize: 2 signed: true ].
		[#'uint16_t *']		-> [^self asIntAccessorOfSize: 2 signed: false ].
		[#'int32_t *']		-> [^self asIntAccessorOfSize: 4 signed: true ].
		[#'uint32_t *']		-> [^self asIntAccessorOfSize: 4 signed: false ].
		[#'int64_t *']		-> [^self asIntAccessorOfSize: 8 signed: true ].
		[#'uint64_t *']		-> [^self asIntAccessorOfSize: 8 signed: false ].
		['sqInputEvent*']	-> [^self] }
		otherwise: [self halt].
	^ self
]

{ #category : #accessing }
CObjectAccessor >> first [
	^self at: 0
]

{ #category : #private }
CObjectAccessor >> getObject [
	^object
]

{ #category : #testing }
CObjectAccessor >> isCArray [
	"Answer a boolean indicating whether the receiver responds to the CArray interface"

	^true
]

{ #category : #accessing }
CObjectAccessor >> isCObjectAccessor [

	^ true
]

{ #category : #'initialize-release' }
CObjectAccessor >> memory: anObject offset: baseIndex [
	object := anObject.
	offset := baseIndex
]

{ #category : #accessing }
CObjectAccessor >> object [

	^ object
]

{ #category : #accessing }
CObjectAccessor >> offset [

	^ offset

]

{ #category : #printing }
CObjectAccessor >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll:' on: ';
		print: object.
]

{ #category : #private }
CObjectAccessor >> setObject: anObject [
	object := anObject.
	offset := 0.
]
