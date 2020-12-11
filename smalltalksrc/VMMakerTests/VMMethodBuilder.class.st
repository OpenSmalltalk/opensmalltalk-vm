Class {
	#name : #VMMethodBuilder,
	#superclass : #VMAbstractBuilder,
	#instVars : [
		'literals',
		'numberOfArguments',
		'numberOfTemporaries',
		'bytecodes',
		'isSmall',
		'isPrimitive',
		'method',
		'slotSize'
	],
	#category : #'VMMakerTests-Builders'
}

{ #category : #building }
VMMethodBuilder >> buildMethod [
	self instantiateMethod.
	self fillMethod.
	^ method
]

{ #category : #building }
VMMethodBuilder >> buildMethodHeader [

	^ (numberOfArguments bitShift: 24)
		+ (numberOfTemporaries bitShift: 18) 
		+ (isSmall ifTrue: [ 0 ] ifFalse: [ 1 bitShift: 17 ])
		+ literals size 
		+ (isPrimitive asBit << 16)
]

{ #category : #helper }
VMMethodBuilder >> bytecodeAt: anIndex forMethod: aMethodOop [
	| methodHeader |
	"1 based"
	methodHeader := memory methodHeaderOf: aMethodOop.

	^ (interpreter initialIPForHeader: methodHeader method: aMethodOop) + anIndex - 1.

]

{ #category : #accessing }
VMMethodBuilder >> bytecodes [
	^ bytecodes
]

{ #category : #accessing }
VMMethodBuilder >> bytecodes: anObject [
	bytecodes := anObject
]

{ #category : #constants }
VMMethodBuilder >> compiledMethodClassIndex [
	^ 16
]

{ #category : #filling }
VMMethodBuilder >> fillFromPharoMethod: aCompiledMethod [ 

	self newMethod.
	self numberOfTemporaries: aCompiledMethod numTemps.
	self numberOfArguments: aCompiledMethod numArgs.
	self bytecodes: aCompiledMethod bytecode.
	self isPrimitive: aCompiledMethod isPrimitive.
	self fillLiteralsFromPharo: aCompiledMethod allLiterals 
]

{ #category : #filling }
VMMethodBuilder >> fillLiteralsFromPharo: pharoLiterals [ 

	literals := pharoLiterals collectWithIndex: [ :aLiteral :anIndex | | value |

		"I Skip the last 2 literals (selector/additional, association)"
		anIndex < (pharoLiterals size - 1)
			ifTrue: [ aLiteral forMemory: memory. ]
			ifFalse: [ memory nilObject ]].
]

{ #category : #filling }
VMMethodBuilder >> fillMethod [
	self putHeaderInMethod.
	self putLiteralInMethod.
	self putBytecodesInMethod.
]

{ #category : #initialization }
VMMethodBuilder >> initialize [
	bytecodes := #[1 2 3 4 5 6 7 8 9 0].
	literals := OrderedCollection new. 
	isSmall := true.
	isPrimitive := false.
	numberOfArguments := 0.
	numberOfTemporaries := 0.
	
	"We reuse initialize to reset the builder, so we nil those objects"
	method := nil.
	slotSize := nil.
]

{ #category : #building }
VMMethodBuilder >> instantiateMethod [
	slotSize := literals size 
			+ (bytecodes size / memory wordSize) ceiling
			+ 1 "method header".
	method := 
		memory allocateSlotsInOldSpace: slotSize
		format: (memory compiledMethodFormatForNumBytes: bytecodes size)
		classIndex: self compiledMethodClassIndex.
	
	method ifNotNil: [ memory fillObj: method numSlots: slotSize with: memory nilObject ].
]

{ #category : #accessing }
VMMethodBuilder >> isPrimitive [
	^ isPrimitive
]

{ #category : #accessing }
VMMethodBuilder >> isPrimitive: anObject [
	isPrimitive := anObject
]

{ #category : #accessing }
VMMethodBuilder >> isSmall [
	^ isSmall
]

{ #category : #accessing }
VMMethodBuilder >> isSmall: anObject [
	isSmall := anObject
]

{ #category : #constants }
VMMethodBuilder >> literalAt: anIndex put: anOop [
	self collection: literals at: anIndex put: anOop
]

{ #category : #accessing }
VMMethodBuilder >> literals [
	^ literals
]

{ #category : #accessing }
VMMethodBuilder >> literals: anObject [
	literals := anObject
]

{ #category : #accessing }
VMMethodBuilder >> method [
	^ method
]

{ #category : #building }
VMMethodBuilder >> newMethod [
	self initialize.
]

{ #category : #accessing }
VMMethodBuilder >> numberOfArguments [
	^ numberOfArguments
]

{ #category : #accessing }
VMMethodBuilder >> numberOfArguments: anObject [
	numberOfArguments := anObject
]

{ #category : #accessing }
VMMethodBuilder >> numberOfTemporaries [
	^ numberOfTemporaries
]

{ #category : #accessing }
VMMethodBuilder >> numberOfTemporaries: anObject [
	numberOfTemporaries := anObject
]

{ #category : #filling }
VMMethodBuilder >> putBytecodesInMethod [
	bytecodes doWithIndex:[ :aBytecode :anIndex | 
		memory storeByte: 
			(memory wordSize "First word is the header"
			+ (literals size * memory wordSize) "bytecodes are stored after literals"
			+ anIndex
			- 1) "0 based"
			ofObject: method 
			withValue: aBytecode
		]
]

{ #category : #filling }
VMMethodBuilder >> putHeaderInMethod [
	memory storePointer: 0 
		ofObject: method
		withValue: (memory integerObjectOf: self buildMethodHeader)

]

{ #category : #filling }
VMMethodBuilder >> putLiteralInMethod [
	"the vm is 0 based, but anIndex will take the values 1 --- n,
	and the 0 indexed element is the header so it's okay."
	literals doWithIndex: [ :aLiteral :anIndex |
		memory
			storePointer: anIndex
			ofObject: method
			withValue: aLiteral.		
		 ]

]

{ #category : #accessing }
VMMethodBuilder >> slotSize [
	"Do not set by hand !"
	^ slotSize
]
