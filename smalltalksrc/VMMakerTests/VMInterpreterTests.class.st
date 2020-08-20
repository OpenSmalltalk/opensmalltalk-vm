Class {
	#name : #VMInterpreterTests,
	#superclass : #VMSpurMemoryManagerTest,
	#pools : [
		'VMObjectIndices'
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

{ #category : #creating }
VMInterpreterTests >> newMethodWithArguments: anInteger [ 
		
	| method methodHeader bytes |

	"Create a bytecode compiled method object containing the given literal at the given index"
 	bytes := #[1 2 3 4 5 6 7 8 9 0].
	method := self
		newOldSpaceObjectWithSlots: 0 "# of literals" + 1 "one extra for the header" + (bytes size // memory wordSize)
		format: (memory compiledMethodFormatForNumBytes: bytes size)
		classIndex: 16r10.
	methodHeader := (anInteger "nArgs" bitShift: 24)
						+ (0 "nTemps" bitShift: 18)
						+ (0 "small frame")
						+ 0 "number of literaps"
						+ 0 "primitive".
	memory storePointer: 0 ofObject: method withValue: (memory integerObjectOf: methodHeader).
	memory storeByte: 8 ofObject: method withValue: (bytes at: 1).

	^ method
]

{ #category : #tests }
VMInterpreterTests >> setSmallIntegerClassIntoClassTable [

	| class |
	class := self
		newClassInOldSpaceWithSlots: 0
		format: memory forwardedFormat.
	memory setHashBitsOf: class to: memory smallIntegerTag.
	memory
		storePointer: memory smallIntegerTag
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
	interpreter := memory interpreter.
		
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
