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

{ #category : #helper }
VMObjectLayoutTests >> objSizeWithNumberOfSlots: numberOfSlots [ 
	| objSize |
	"always have at least one slot for forwarders"
	numberOfSlots = 0 ifTrue: [ ^ objectHeaderSize + 8 ].
	
	objSize := numberOfSlots * wordSize.
	"we align to 8 bytes"
	objSize % 8 = 0 ifFalse: [ objSize := objSize + wordSize ].

	"extra header for big objects"	
	numberOfSlots > 254 ifTrue: [ objSize := objSize + objectHeaderSize ].
	^ objectHeaderSize + objSize
	
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
		objSize := self objSizeWithNumberOfSlots: slots.
		self assert: (memory slotSizeOf: objOop) equals: slots.
		self
			assert: (memory bytesInObject: objOop)
			equals: objSize ]
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectAlignment [
	| class objOop1 objOop2 instSpec |
	instSpec := 0.
	class := self installClassIntoClassTableWithInstSpec: instSpec instSize: 0.
	objOop1 := memory instantiateClass: class.
	objOop2 := memory instantiateClass: class.
	self assert: objOop1 \\ 8 equals: 0.
	self assert: objOop2 \\ 8 equals: 0
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectHeaderEncodesAmountOfSlots [
	| class objOop header |
	0 to: 254 do: [ :slots |
		class := self installClassIntoClassTableWithInstSpec: 1 instSize: slots.
		objOop := memory instantiateClass: class.
		header := memory long64At: objOop.
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
VMObjectLayoutTests >> testObjectHeaderEncodesObjecFormatForIndexableOpaqueLayout16Bit [
	| class objOop header classInstSpec instSpec bits maxSize |
	 "instSpec: 	12-15	= 16-bit indexable
			12 -> padding  0-bits
			13 -> padding  16-bits
			14 -> padding  32-bits
			15 -> padding  48-bits"
	bits := 16.
	instSpec := 12.
	class := self installClassIntoClassTableWithInstSpec: instSpec instSize: 0.
	maxSize := (wordSize * 8) / bits.
	1 to: maxSize do: [ :size |
		| padding |
		padding := (wordSize * 8) - (size * bits).
		objOop := memory instantiateClass: class indexableSize: size.
		classInstSpec := memory instSpecOfClass: class.
		header := memory longAt: objOop.
		self assert: (header >> 24 bitAnd: 16r1F) equals: classInstSpec + (padding / bits)
		] 
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectHeaderEncodesObjecFormatForIndexableOpaqueLayout32Bit [
	| class objOop header classInstSpec instSpec bits maxSize |
	 "instSpec: 	10-11	= 32-bit indexable
			10 -> padding  0-bits
			11 -> padding  32-bits"
	bits := 32.
	instSpec := 10.
	class := self installClassIntoClassTableWithInstSpec: instSpec instSize: 0.
	maxSize := (wordSize * 8) / bits.
	1 to: maxSize do: [ :size |
		| padding |
		padding := (wordSize * 8) - (size * bits).
		objOop := memory instantiateClass: class indexableSize: size.
		classInstSpec := memory instSpecOfClass: class.
		header := memory longAt:objOop.
		self assert: (header >> 24 bitAnd: 16r1F) equals: classInstSpec + (padding / bits)
		] 
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectHeaderEncodesObjecFormatForIndexableOpaqueLayout8Bit [
	| class objOop header classInstSpec instSpec bits maxSize |
	 "instSpec: 	16-23	= 8-bit indexable
			16 -> padding  0-bits
			17 -> padding  8-bits
			18 -> padding 16-bits
			19 -> padding 24-bits
			20 -> padding 32-bits
			21 -> padding 40-bits
			22 -> padding 48-bits
			23 -> padding 56-bits"
	bits := 8.
	instSpec := 16. "8-bit indexable"
	class := self installClassIntoClassTableWithInstSpec: instSpec instSize: 0.
	maxSize := wordSize .
	1 to: maxSize do: [ :size |
		| padding |
		padding := (wordSize * bits) - (size * bits).
		objOop := memory instantiateClass: class indexableSize: size.
		classInstSpec := memory instSpecOfClass: class.
		header := memory longAt:objOop.
		self assert: (header >> 24 bitAnd: 16r1F) equals: classInstSpec + (padding / bits)
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
VMObjectLayoutTests >> testObjectMinimumSize [
	| class objOop1 objOop2 instSpec |
	instSpec := 0.
	class := self installClassIntoClassTableWithInstSpec: instSpec instSize: 0.
	objOop1 := memory instantiateClass: class.
	objOop2 := memory instantiateClass: class.
	self assert: objOop2 - objOop1 equals: 16
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectWith0SlotsIsAreAlwaysAligned [
	| class slots obj1oop obj2oop |
	"objects always are allocated with at least one slots for forwarding"
	slots := 0.
	class := self installClassIntoClassTableWithInstSpec: 1 instSize: slots.
	obj1oop := memory instantiateClass: class.
	obj2oop := memory instantiateClass: class.
	self assert: obj2oop - obj1oop equals: objectHeaderSize + memory allocationUnit
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectWith0SlotsIsAreAlwaysWithAtLeastOneSlotsForForwarding [
	| class slots  oop |
	slots := 0.
	class := self installClassIntoClassTableWithInstSpec: 1 instSize: slots.
	oop := memory instantiateClass: class.
	self assert: (memory bytesInObject: oop) equals: objectHeaderSize + memory allocationUnit.
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
		equals: (self objSizeWithNumberOfSlots: slots).
	
]

{ #category : #tests }
VMObjectLayoutTests >> testObjectWithMoreThan254SlotsHasTwoHeaders [
	| class objOop header2 mask numSlots |
	mask := 16rFFFFFFFFFFFFFF.
	255 to: 265 do: [ :slots | 
		class := self
			installClassIntoClassTableWithInstSpec: 1
			instSize: slots.
		objOop := memory instantiateClass: class.
		header2 := memory long64At: objOop - objectHeaderSize.	"header before the main header"
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
