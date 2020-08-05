Class {
	#name : #VMLookUpTest,
	#superclass : #VMInterpreterTests,
	#instVars : [
		'methodOop',
		'selectorOop',
		'receiver',
		'class',
		'methodDictionary',
		'arrayOfMethods'
	],
	#pools : [
		'VMBasicConstants',
		'VMBytecodeConstants',
		'VMObjectIndices'
	],
	#category : #'VMMakerTests-InterpreterTests'
}

{ #category : #tests }
VMLookUpTest >> setSmallIntegerClassIntoClassTable [
	class := self
		newClassInOldSpaceWithSlots: 0
		format: memory forwardedFormat.
	memory setHashBitsOf: class to: memory smallIntegerTag.
	memory
		storePointer: memory smallIntegerTag
		ofObject: memory classTableFirstPage
		withValue: class
]

{ #category : #tests }
VMLookUpTest >> testInstallSmallIntegerClassIntoClassTable [
	"We set a smallInteger class into the classTable"

	self setSmallIntegerClassIntoClassTable.
	self
		assert: (memory fetchClassOf: (memory integerObjectOf: 17))
		equals: class
]

{ #category : #tests }
VMLookUpTest >> testLookUpInDefiningClassCreatesANewEntryInCache [

	methodOop := self newMethodWithBytecodes: #[1 2 3 4 5 6 7 8 9].
	selectorOop := memory integerObjectOf: 42.
	receiver := memory integerObjectOf: 56.
	class := self newClassInOldSpaceWithSlots: 0 format: memory forwardedFormat.
	self setSmallIntegerClassIntoClassTable.
	"2 instances variables the array of methods and the tally
	and 12 entries to put elemetns of the collection"
	methodDictionary := self newObjectWithSlots: 2 + 12 format: MethodDictionary instSpec classIndex: memory arrayClassIndexPun.
	arrayOfMethods := self newObjectWithSlots: 12 format: Array instSpec classIndex: memory arrayClassIndexPun.
	
	memory storePointer: MethodDictionaryIndex ofObject: class withValue:  methodDictionary.
	memory storePointer: MethodArrayIndex ofObject: methodDictionary withValue:  arrayOfMethods.
	memory storePointer: (memory methodDictionaryHash: selectorOop mask: 11) + 2 ofObject: methodDictionary withValue: selectorOop.
	memory storePointer: (memory methodDictionaryHash: selectorOop mask: 11) ofObject: arrayOfMethods withValue: methodOop.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter messageSelector: selectorOop.
	interpreter findNewMethodInClassTag: memory smallIntegerTag.
	self assert: (interpreter lookupInMethodCacheSel: selectorOop  classTag:memory smallIntegerTag).
]

{ #category : #tests }
VMLookUpTest >> testLookUpInDefiningClassLeavesTheFoundMethodInNewMethodVariable [

	methodOop := self newMethodWithBytecodes: #[1 2 3 4 5 6 7 8 9].
	selectorOop := memory integerObjectOf: 42.
	receiver := memory integerObjectOf: 56.
	class := self newClassInOldSpaceWithSlots: 0 format: memory forwardedFormat.
	self setSmallIntegerClassIntoClassTable.
	"2 instances variables the array of methods and the tally
	and 12 entries to put elemetns of the collection"
	methodDictionary := self newObjectWithSlots: 2 + 12 format: MethodDictionary instSpec classIndex: memory arrayClassIndexPun.
	arrayOfMethods := self newObjectWithSlots: 12 format: Array instSpec classIndex: memory arrayClassIndexPun.
	
	memory storePointer: MethodDictionaryIndex ofObject: class withValue:  methodDictionary.
	memory storePointer: MethodArrayIndex ofObject: methodDictionary withValue:  arrayOfMethods.
	memory storePointer: (memory methodDictionaryHash: selectorOop mask: 11) + 2 ofObject: methodDictionary withValue: selectorOop.
	memory storePointer: (memory methodDictionaryHash: selectorOop mask: 11) ofObject: arrayOfMethods withValue: methodOop.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter messageSelector: selectorOop.
	interpreter lookupMethodInClass: class.
	self assert: interpreter newMethod equals: methodOop.
]
