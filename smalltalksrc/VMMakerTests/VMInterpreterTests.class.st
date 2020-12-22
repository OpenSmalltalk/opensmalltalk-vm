Class {
	#name : #VMInterpreterTests,
	#superclass : #VMSpurMemoryManagerTest,
	#pools : [
		'VMObjectIndices',
		'VMSqueakClassIndices'
	],
	#category : #'VMMakerTests-InterpreterTests'
}

{ #category : #tests }
VMInterpreterTests >> installSelector: aSelectorOop method: aMethodOop inMethodDictionary: aMethodDictionary [
	
	| anArrayOfMethods |
	anArrayOfMethods := memory fetchPointer: MethodArrayIndex ofObject: aMethodDictionary.
	memory
		storePointer: (memory methodDictionaryHash: aSelectorOop mask: 11) + 2
		ofObject: aMethodDictionary
		withValue: aSelectorOop.
	memory
		storePointer: (memory methodDictionaryHash: aSelectorOop mask: 11)
		ofObject: anArrayOfMethods
		withValue: aMethodOop
]

{ #category : #tests }
VMInterpreterTests >> setSmallIntegerClassIntoClassTable [

	| class |
	"install the class in both 1 and 3 index of class table
	see SpurMemoryManager >> fetchClassOf: for more informations"
	class := self
		newClassInOldSpaceWithSlots: 0
		instSpec: memory forwardedFormat.
	memory setHashBitsOf: class to: memory smallIntegerTag.

	memory
		storePointer: memory smallIntegerTag
		ofObject: memory classTableFirstPage
		withValue: class.
	
	memory
		storePointer: 3
		ofObject: memory classTableFirstPage
		withValue: class.
	^class
	
]

{ #category : #running }
VMInterpreterTests >> setUp [
	
	"taken from VMSimpleStackBasedCogitBytecodeTest >> #setup"
	super setUp.
	
	memory nilObject: (self newObjectWithSlots: 0).
	memory trueObject: (self newObjectWithSlots: 0).
	memory falseObject: (self newObjectWithSlots: 0).
	
	"We don't access its contents, but we need it to be after nil, true and false"
	memory hiddenRootsObject: (self newObjectWithSlots: 0).
		
	self initializeOldSpaceForScavenger.

	


]

{ #category : #tests }
VMInterpreterTests >> setUpMethodDictionaryIn: aClass [
	"2 instances variables the array of methods and the tally
	and 12 entries to put elemetns of the collection"
	
	| aMethodDictionary anArrayOfMethods |
	aMethodDictionary := self
		newObjectWithSlots: 2 + 12
		format: MethodDictionary instSpec
		classIndex: memory arrayClassIndexPun.
	anArrayOfMethods := self
		newObjectWithSlots: 12
		format: Array instSpec
		classIndex: memory arrayClassIndexPun.
	memory
		storePointer: MethodDictionaryIndex
		ofObject: aClass
		withValue: aMethodDictionary.
	memory
		storePointer: MethodArrayIndex
		ofObject: aMethodDictionary
		withValue: anArrayOfMethods.
		
	

]
