Class {
	#name : #VMObjectLayoutTests,
	#superclass : #VMInterpreterTests,
	#category : #'VMMakerTests-ObjectLayoutTests'
}

{ #category : #helpers }
VMObjectLayoutTests >> formatFromInstSpec: instSpecInt instSize: instSizeInt [ 		
	"A class format is composed by"
	"<5 bits inst spec><16 bits inst size>"
	^ instSpecInt << 16 + instSizeInt
]

{ #category : #helpers }
VMObjectLayoutTests >> installClassIntoClassTableWithInstSpec: aFormatInt instSize: aSizeInt [ 
	| class |
	class := self
		newClassInOldSpaceWithSlots: aSizeInt
		instSpec: aFormatInt.
	memory ensureBehaviorHash: class.	
	^class	
]

{ #category : #tests }
VMObjectLayoutTests >> testCharacterIsImmediate [
	| char |
	char := memory characterObjectOf: $a asInteger.
	self assert: (memory isImmediate: char).
	self assert: (memory fetchClassTagOf: char) equals: 2
]

{ #category : #tests }
VMObjectLayoutTests >> testHeaderOfObjectEncodesTheCorrectAmountOfSlots [
	| class objOop |
	0 to: 254 do: [ :slots | 
		| objSize |
		class := self
			installClassIntoClassTableWithInstSpec: 1
			instSize: slots.
		objOop := memory instantiateClass: class.
		objSize := slots + 1 max: 2 "header".
		self assert: (memory slotSizeOf: objOop) equals: slots.
		self
			assert: (memory bytesInObject: objOop)
			equals: objSize * memory wordSize ]
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectHeaderEncodesAmountOfSlots [
	| class objOop header |
	0 to: 254 do: [ :slots |
		class := self installClassIntoClassTableWithInstSpec: 1 instSize: slots.
		objOop := memory instantiateClass: class.
		header := memory longAt: objOop.
		self assert: (header >> 56 bitAnd: 16rFF) equals: slots
	]
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectHeaderEncodesClassIndex [
	| class objOop header classIndex |
	0 to: 10 do: [ :slots |
		class := self installClassIntoClassTableWithInstSpec: 1 instSize: 0.
		objOop := memory instantiateClass: class.
		classIndex := memory rawHashBitsOf: class.
		header := memory longAt:objOop.
		memory fetchClassTagOf: objOop.
		self assert: (header bitAnd: 16r3FFFFF) equals: classIndex
	]
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectHeaderEncodesObjecFormatForFixedLayout [
	| class objOop header classInstSpec |
	 "instSpec: 
		0 = 0 sized objects (UndefinedObject True False et al)
		1 = non-indexable objects with inst vars (Point et al)"	
	0 to: 1 do: [ :instSpec |
		class := self installClassIntoClassTableWithInstSpec: instSpec instSize: 0.
		objOop := memory instantiateClass: class.
		classInstSpec := memory instSpecOfClass: class.
		header := memory longAt:objOop.
		self assert: (header >> 24 bitAnd: 16r1F) equals: classInstSpec
	]
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectHeaderEncodesObjecFormatForIndexableOpaqueLayout8Bit [
	| class objOop header classInstSpec instSpec |
	 "instSpec: 	16-23	= 8-bit indexable
			16 -> padding  0-bits
			17 -> padding  8-bits
			18 -> padding 16-bits
			19 -> padding 24-bits
			20 -> padding 32-bits
			21 -> padding 40-bits
			22 -> padding 48-bits
			23 -> padding 56-bits"
	instSpec := 16.
	class := self installClassIntoClassTableWithInstSpec: instSpec instSize: 0.
	8 to: 15 do: [ :size |
		| padding |
		padding := (64 - size).
		objOop := memory instantiateClass: class indexableSize: size.
		classInstSpec := memory instSpecOfClass: class.
		header := memory longAt:objOop.
		self assert: (header >> 24 bitAnd: 16r1F) equals: classInstSpec + (padding % 8)
		] 
	
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectHeaderEncodesObjecFormatForIndexablePointerLayout [
	| class objOop header classInstSpec instSpec |
	instSpec := 2. "instSpec for indexable objects with no inst vars (Array et al)"	
	class := self installClassIntoClassTableWithInstSpec: instSpec instSize: 0.
	1 to: 10 do: [ :size |
		objOop := memory instantiateClass: class indexableSize: size.
		classInstSpec := memory instSpecOfClass: class.
		header := memory longAt:objOop.
		self assert: (header >> 24 bitAnd: 16r1F) equals: classInstSpec
	]
	
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectWith0SlotsIsSavedIn2Words [
	| class slots obj1oop obj2oop |
	"objects always are allocated with at least one slots for forwarding"
	slots := 0.
	class := self installClassIntoClassTableWithInstSpec: 1 instSize: slots.
	obj1oop := memory instantiateClass: class.
	obj2oop := memory instantiateClass: class.
	self assert: (memory bytesInObject: obj1oop) equals: memory wordSize * 2.
	self assert: (memory slotSizeOf: obj1oop) equals: slots.
	self assert: (memory slotSizeOf: obj2oop) equals: slots.
	self assert: obj2oop - obj1oop equals: memory wordSize * 2
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectWithMoreThan254SlotsHasTheCorrectSize [
	| class objOop slots |
	slots := 255.
	class := self
		installClassIntoClassTableWithInstSpec: 1
		instSize: slots.
	objOop := memory instantiateClass: class.
	self assert: (memory slotSizeOf: objOop) equals: slots.
	self
		assert: (memory bytesInObject: objOop)
		equals: (slots + 2 "headers") * memory wordSize.
	
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectWithMoreThan254SlotsHasTwoHeaders [
	| class objOop header2 mask numSlots |
	mask := memory wordSize = 8
		ifTrue: [ 16rFFFFFFFFFFFFFF ]
		ifFalse: [ 16rFFFFFF ].
	255 to: 265 do: [ :slots | 
		class := self
			installClassIntoClassTableWithInstSpec: 1
			instSize: slots.
		objOop := memory instantiateClass: class.
		header2 := memory longAt: objOop - self wordSize.	"header before the main header"
		numSlots := header2 bitAnd: mask.
		self assert: numSlots equals: slots ]
]

{ #category : #tests }
VMObjectLayoutTests >> testSmallIntegerIsImmediate [
	| int |
	int := memory integerObjectOf: 42.
	self assert: (memory isImmediate: int).
	self assert: (memory fetchClassTagOf: int) equals: 1
]

{ #category : #tests }
VMObjectLayoutTests >> testVariableObjectWithInstVarsHasTheRightSize [
	| class objOop fixedFieldsSize indexableSize |
	indexableSize := 12.
	fixedFieldsSize := 5.
	class := self
		installClassIntoClassTableWithInstSpec: 3
		instSize: fixedFieldsSize.
	objOop := memory instantiateClass: class indexableSize: indexableSize.
	self assert: (memory slotSizeOf: objOop) equals: fixedFieldsSize + indexableSize
]
