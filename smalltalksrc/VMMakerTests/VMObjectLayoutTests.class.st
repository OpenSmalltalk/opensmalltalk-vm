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
	"objects always are allocated with at least one slots for forwarding"
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
VMObjectLayoutTests >> testSmallIntegerIsImmediate [
	| int |
	int := memory integerObjectOf: 42.
	self assert: (memory isImmediate: int).
	self assert: (memory fetchClassTagOf: int) equals: 1
]
