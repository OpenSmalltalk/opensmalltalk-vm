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
		'VMObjectIndices',
		'VMSqueakClassIndices'
	],
	#category : #'VMMakerTests-InterpreterTests'
}

{ #category : #tests }
VMLookUpTest >> installSelector: aSelectorOop method: aMethodOop inMethodDictionary: aMethodDictionary [
	
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
VMLookUpTest >> setArrayClassIntoClassTable [
	class := self
		newClassInOldSpaceWithSlots: 0
		format: Array instSpec.
	memory setHashBitsOf: class to: ClassArrayCompactIndex.
	memory
		storePointer: ClassArrayCompactIndex
		ofObject: memory classTableFirstPage
		withValue: class
]

{ #category : #tests }
VMLookUpTest >> setMessageClassIntoClassTable [
	class := self
		newClassInOldSpaceWithSlots: MessageSend allSlots size 
		format: MessageSend instSpec.
	memory setHashBitsOf: class to: ClassMessageCompactIndex.
	memory
		storePointer: ClassMessageCompactIndex
		ofObject: memory classTableFirstPage
		withValue: class
]

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

{ #category : #running }
VMLookUpTest >> setUp [
	
	"taken from VMSimpleStackBasedCogitBytecodeTest >> #setup"
	| newMethod ctx page processorOopAssociation processorOop processorListArray processorListPriority1 processorListPriority2 |
	super setUp.

	"Create the root context with a valid method"
	"Let's create a method with enough size. It should have at least a literal (4 or 8 bytes depending the word size) and some bytecodes, so we can put the IP inside the method"
	newMethod := self newMethodWithBytecodes: #[ 1 2 3 4 5 6 7 8 9 0 ].
	
	"The context has 5 (in 32 bits) or 9 (in 64 bits) as initial IP, as method has at least one literal"
	ctx := self newSmallContextReceiver: memory nilObject method: newMethod arguments: #() temporaries: #() ip: self wordSize + 1.
	
	page := interpreter makeBaseFrameFor: ctx.
	interpreter setStackPointersFromPage: page.
	
	
	"The ScheduleAssocation should be initialized to a valid Processor object"
	processorOopAssociation := self newObjectWithSlots: 2.
	processorOop := self newObjectWithSlots: 2.
	processorListArray := self newObjectWithSlots: 2.
	
	processorListPriority1 := self newObjectWithSlots: 2.
	processorListPriority2 := self newObjectWithSlots: 2.
	
	memory storePointer: 0 ofObject: processorListArray withValue: processorListPriority1. 
	memory storePointer: 1 ofObject: processorListArray withValue: processorListPriority2.
	
	memory splObj: SchedulerAssociation put: processorOopAssociation.
	memory storePointer: ValueIndex ofObject: processorOopAssociation withValue: processorOop.
	memory storePointer: ProcessListsIndex ofObject: processorOop withValue: processorListArray.
	memory lastHash: 1.

	interpreter setBreakSelector: nil.

]

{ #category : #tests }
VMLookUpTest >> setUpClassAndMethod [
	methodOop := self newMethodWithBytecodes: #[1 2 3 4 5 6 7 8 9].
	selectorOop := memory integerObjectOf: 42.
	receiver := memory integerObjectOf: 56.
	class := self
		newClassInOldSpaceWithSlots: 0
		format: memory forwardedFormat.
	self setSmallIntegerClassIntoClassTable
]

{ #category : #tests }
VMLookUpTest >> setUpMethodDictionaryIn: aClass [
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

{ #category : #tests }
VMLookUpTest >> testInstallSmallIntegerClassIntoClassTable [
	"We set a smallInteger class into the classTable"

	self setSmallIntegerClassIntoClassTable.
	self
		assert: (memory fetchClassOf: (memory integerObjectOf: 17))
		equals: class
]

{ #category : #tests }
VMLookUpTest >> testLookUpFindsMethodInSuperclass [

	| superclass superclassMethodDictionary |
	self setUpClassAndMethod.
	self setArrayClassIntoClassTable.
	self setMessageClassIntoClassTable.
	self setUpMethodDictionaryIn: class.
	
	superclass := self
		newClassInOldSpaceWithSlots: 0
		format: memory arrayFormat.
	self setUpMethodDictionaryIn: superclass.	
	superclassMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: superclass. 
	memory storePointer: SuperclassIndex ofObject: class  withValue: superclass.	
	
	self installSelector: selectorOop method: methodOop inMethodDictionary: superclassMethodDictionary.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter messageSelector: selectorOop.
	interpreter lookupMethodInClass: class.
	self assert: interpreter newMethod equals: methodOop .
]

{ #category : #tests }
VMLookUpTest >> testLookUpInDefiningClassCreatesANewEntryInCache [

	self setUpClassAndMethod.	
	self setUpMethodDictionaryIn: class.
	
	methodDictionary := memory
		fetchPointer: MethodDictionaryIndex
		ofObject: class.
		
	self installSelector: selectorOop method: methodOop inMethodDictionary: methodDictionary.	
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter messageSelector: selectorOop.
	interpreter findNewMethodInClassTag: memory smallIntegerTag.
	self assert: (interpreter lookupInMethodCacheSel: selectorOop classTag:memory smallIntegerTag).
]

{ #category : #tests }
VMLookUpTest >> testLookUpInDefiningClassLeavesTheFoundMethodInNewMethodVariable [
	
	| aMethodDictionary |
	self setUpClassAndMethod.	
	self setUpMethodDictionaryIn: class.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: class.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter messageSelector: selectorOop.
	interpreter lookupMethodInClass: class.
	self assert: interpreter newMethod equals: methodOop
]

{ #category : #tests }
VMLookUpTest >> testLookUpNonExistingSelectorFindsDNUMethod [

	| nonExistingSelector dnuMethodOop dnuSelectorOop aMethodDictionary |
	self setUpClassAndMethod.
	self setArrayClassIntoClassTable.
	self setMessageClassIntoClassTable.
	self setUpMethodDictionaryIn: class.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: class.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.
	
	dnuMethodOop := self newMethodWithBytecodes: #[1 2 3 4 5 6 7 8 9].
	dnuSelectorOop := self newString: 'DNU'. 
	self installSelector: dnuSelectorOop method: dnuMethodOop inMethodDictionary: aMethodDictionary.
	
	memory splObj: SelectorDoesNotUnderstand  put: dnuSelectorOop.
	
	nonExistingSelector:= memory integerObjectOf: 41.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter messageSelector: nonExistingSelector.
	interpreter lookupMethodInClass: class.
	self assert: interpreter newMethod equals: dnuMethodOop.
]

{ #category : #tests }
VMLookUpTest >> testLookUpNonExistingSelectorThrowsRecursivelyDoesNotUnderstand [

	| nonExistingSelector aMethodDictionary |
	self setUpClassAndMethod.
	self setArrayClassIntoClassTable.
	self setMessageClassIntoClassTable.
	self setUpMethodDictionaryIn: class.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: class.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.

	
	nonExistingSelector:= memory integerObjectOf: 41.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter messageSelector: nonExistingSelector.
	"DoesNotUnderStand is no there so infinite recursion of DNU"
	self should: [interpreter lookupMethodInClass: class] raise: Error.
]

{ #category : #tests }
VMLookUpTest >> testLookUpWithNilMethodDictionaryFindsCannotInterpret [

	| nonExistingSelector cannotInterpretMethodOop cannotInterpretSelectorOop superclass superclassMethodDictionary |
	self setUpClassAndMethod.
	self setArrayClassIntoClassTable.
	self setMessageClassIntoClassTable.
	
	superclass := self
		newClassInOldSpaceWithSlots: 0
		format: memory arrayFormat.
	self setUpMethodDictionaryIn: superclass.	
	superclassMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: superclass. 
	memory storePointer: SuperclassIndex ofObject: class  withValue: superclass.	
	
	cannotInterpretMethodOop := self newMethodWithBytecodes: #[1 2 3 4 5 6 7 8 9].
	cannotInterpretSelectorOop := self newString: 'CannotInterpret'. 
	self installSelector: cannotInterpretSelectorOop method: cannotInterpretMethodOop inMethodDictionary: superclassMethodDictionary.
	
	memory splObj: SelectorDoesNotUnderstand  put: cannotInterpretSelectorOop.
	
	nonExistingSelector:= memory integerObjectOf: 41.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter messageSelector: nonExistingSelector.
	interpreter lookupMethodInClass: class.
	self assert: interpreter newMethod equals: cannotInterpretMethodOop.
]
