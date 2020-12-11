Class {
	#name : #VMLookUpTest,
	#superclass : #VMInterpreterTests,
	#instVars : [
		'methodOop',
		'selectorOop',
		'receiver',
		'methodDictionary',
		'arrayOfMethods',
		'receiverClass'
	],
	#pools : [
		'VMBasicConstants',
		'VMBytecodeConstants'
	],
	#category : #'VMMakerTests-InterpreterTests'
}

{ #category : #tests }
VMLookUpTest >> setArrayClassIntoClassTable [
	| aClass |
	aClass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: Array instSpec.
	memory setHashBitsOf: aClass to: ClassArrayCompactIndex.
	memory
		storePointer: ClassArrayCompactIndex
		ofObject: memory classTableFirstPage
		withValue: aClass
]

{ #category : #tests }
VMLookUpTest >> setMessageClassIntoClassTable [
	| aClass |
	aClass := self
		newClassInOldSpaceWithSlots: MessageSend allSlots size 
		instSpec: MessageSend instSpec.
	memory setHashBitsOf: aClass to: ClassMessageCompactIndex.
	memory
		storePointer: ClassMessageCompactIndex
		ofObject: memory classTableFirstPage
		withValue: aClass
]

{ #category : #running }
VMLookUpTest >> setUp [
	
	"taken from VMSimpleStackBasedCogitBytecodeTest >> #setup"
	| newMethod ctx page processorOopAssociation processorOop processorListArray processorListPriority1 processorListPriority2 |
	super setUp.

	"Create the root context with a valid method"
	"Let's create a method with enough size. It should have at least a literal (4 or 8 bytes depending the word size) and some bytecodes, so we can put the IP inside the method"
	newMethod := methodBuilder newMethod buildMethod.
	
	"The context has 5 (in 32 bits) or 9 (in 64 bits) as initial IP, as method has at least one literal"
	ctx := self newSmallContextReceiver: memory nilObject method: newMethod arguments: #() temporaries: #() ip: self wordSize + 1.
	
	page := interpreter makeBaseFrameFor: ctx.
	interpreter setStackPointersFromPage: page.
	interpreter setStackPageAndLimit: page.
	
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
	methodOop := methodBuilder newMethod buildMethod.
	selectorOop := memory integerObjectOf: 42.
	receiver := memory integerObjectOf: 56.
	receiverClass := self setSmallIntegerClassIntoClassTable
]

{ #category : #tests }
VMLookUpTest >> testInstallSmallIntegerClassIntoClassTable [
	"We set a smallInteger class into the classTable"

	receiverClass := self setSmallIntegerClassIntoClassTable.
	self
		assert: (memory fetchClassOf: (memory integerObjectOf: 17))
		equals: receiverClass
]

{ #category : #tests }
VMLookUpTest >> testLookUpFindsMethodInClass [
	
	| aMethodDictionary |
	self setUpClassAndMethod.	
	self setUpMethodDictionaryIn: receiverClass.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: receiverClass.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter messageSelector: selectorOop.
	interpreter lookupMethodInClass: receiverClass.
	self assert: interpreter newMethod equals: methodOop
]

{ #category : #tests }
VMLookUpTest >> testLookUpFindsMethodInSuperclass [

	| superclass superclassMethodDictionary |
	self setUpClassAndMethod.
	self setArrayClassIntoClassTable.
	self setMessageClassIntoClassTable.
	self setUpMethodDictionaryIn: receiverClass.
	
	superclass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: memory arrayFormat.
	self setUpMethodDictionaryIn: superclass.	
	superclassMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: superclass. 
	memory storePointer: SuperclassIndex ofObject: receiverClass  withValue: superclass.	
	
	self installSelector: selectorOop method: methodOop inMethodDictionary: superclassMethodDictionary.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter setBreakSelector: nil.
	interpreter messageSelector: selectorOop.
	interpreter lookupMethodInClass: receiverClass.
	self assert: interpreter newMethod equals: methodOop
]

{ #category : #tests }
VMLookUpTest >> testLookUpInDefiningClassCreatesANewEntryInCache [

	| aMethodDictionary |
	self setUpClassAndMethod.	
	self setUpMethodDictionaryIn: receiverClass.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: receiverClass.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter messageSelector: selectorOop.
	interpreter findNewMethodInClassTag: memory smallIntegerTag.
	self assert: (interpreter lookupInMethodCacheSel: selectorOop classTag:memory smallIntegerTag).
]

{ #category : #tests }
VMLookUpTest >> testLookUpInFindsCannotInterpretCreatesANewEntryInCache [

	| nonExistingSelector cannotInterpretMethodOop cannotInterpretSelectorOop superclass superclassMethodDictionary |
	self setUpClassAndMethod.
	self setArrayClassIntoClassTable.
	self setMessageClassIntoClassTable.
	
	superclass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: memory arrayFormat.
	self setUpMethodDictionaryIn: superclass.	
	superclassMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: superclass. 
	memory storePointer: SuperclassIndex ofObject: receiverClass  withValue: superclass.	
	
	cannotInterpretMethodOop := methodBuilder newMethod buildMethod.
	cannotInterpretSelectorOop := self newString: 'CannotInterpret'. 
	self installSelector: cannotInterpretSelectorOop method: cannotInterpretMethodOop inMethodDictionary: superclassMethodDictionary.
	
	memory splObj: SelectorCannotInterpret  put: cannotInterpretSelectorOop.
	
	nonExistingSelector:= memory integerObjectOf: 41.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter setBreakSelector: nil.
	interpreter messageSelector: nonExistingSelector.
	interpreter findNewMethodInClassTag: memory smallIntegerTag.
	self assert: (interpreter lookupInMethodCacheSel: cannotInterpretSelectorOop classTag:memory smallIntegerTag).
]

{ #category : #tests }
VMLookUpTest >> testLookUpInFindsDNUCreatesANewEntryInCache [

	| nonExistingSelector dnuMethodOop dnuSelectorOop aMethodDictionary |
	self setUpClassAndMethod.
	self setArrayClassIntoClassTable.
	self setMessageClassIntoClassTable.
	self setUpMethodDictionaryIn: receiverClass.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: receiverClass.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.
	
	dnuMethodOop := methodBuilder newMethod buildMethod.
	dnuSelectorOop := self newString: 'DNU'. 
	self installSelector: dnuSelectorOop method: dnuMethodOop inMethodDictionary: aMethodDictionary.
	
	memory splObj: SelectorDoesNotUnderstand  put: dnuSelectorOop.
	
	nonExistingSelector:= memory integerObjectOf: 41.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter setBreakSelector: nil.
	interpreter messageSelector: nonExistingSelector.
	interpreter findNewMethodInClassTag: memory smallIntegerTag.
	self assert: (interpreter lookupInMethodCacheSel: dnuSelectorOop classTag:memory smallIntegerTag).
]

{ #category : #tests }
VMLookUpTest >> testLookUpInSuperclassCreatesANewEntryInCache [

	| superclass superclassMethodDictionary |
	self setUpClassAndMethod.	
	self setUpMethodDictionaryIn: receiverClass.
	
	superclass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: memory arrayFormat.
	self setUpMethodDictionaryIn: superclass.	
	superclassMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: superclass. 
	memory storePointer: SuperclassIndex ofObject: receiverClass  withValue: superclass.	
	
	self installSelector: selectorOop method: methodOop inMethodDictionary: superclassMethodDictionary.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter messageSelector: selectorOop.
	interpreter findNewMethodInClassTag: memory smallIntegerTag.
	self assert: (interpreter lookupInMethodCacheSel: selectorOop classTag:memory smallIntegerTag).
]

{ #category : #tests }
VMLookUpTest >> testLookUpNonExistingCannotInterpretAnswersDNUMethod [

	| nonExistingSelector superclass superclassMethodDictionary dnuMethodOop dnuSelectorOop |
	self setUpClassAndMethod.
	self setArrayClassIntoClassTable.
	self setMessageClassIntoClassTable.
	
	superclass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: memory arrayFormat.
	self setUpMethodDictionaryIn: superclass.	
	superclassMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: superclass. 
	memory storePointer: SuperclassIndex ofObject: receiverClass withValue: superclass.	
	
	dnuMethodOop := methodBuilder newMethod buildMethod.
	dnuSelectorOop := self newString: 'DNU'. 
	self installSelector: dnuSelectorOop method: dnuMethodOop inMethodDictionary: superclassMethodDictionary.
	
	memory splObj: SelectorDoesNotUnderstand  put: dnuSelectorOop.
	
	nonExistingSelector:= memory integerObjectOf: 41.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter setBreakSelector: nil.
	interpreter messageSelector: nonExistingSelector.
	interpreter lookupMethodInClass: receiverClass.
	self assert: interpreter newMethod equals: dnuMethodOop.
]

{ #category : #tests }
VMLookUpTest >> testLookUpNonExistingDNUThrowsRecursivelyDoesNotUnderstand [

	| nonExistingSelector aMethodDictionary |
	self setUpClassAndMethod.
	self setArrayClassIntoClassTable.
	self setMessageClassIntoClassTable.
	self setUpMethodDictionaryIn: receiverClass.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: receiverClass.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.

	
	nonExistingSelector:= memory integerObjectOf: 41.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter setBreakSelector: nil.
	interpreter messageSelector: nonExistingSelector.
	"DoesNotUnderStand is no there so infinite recursion of DNU"
	self should: [interpreter lookupMethodInClass: receiverClass] raise: Error.
]

{ #category : #tests }
VMLookUpTest >> testLookUpNonExistingSelectorAnswersDNUMethod [

	| nonExistingSelector dnuMethodOop dnuSelectorOop aMethodDictionary |
	self setUpClassAndMethod.
	self setArrayClassIntoClassTable.
	self setMessageClassIntoClassTable.
	self setUpMethodDictionaryIn: receiverClass.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: receiverClass.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.
	
	dnuMethodOop := methodBuilder newMethod buildMethod.
	dnuSelectorOop := self newString: 'DNU'. 
	self installSelector: dnuSelectorOop method: dnuMethodOop inMethodDictionary: aMethodDictionary.
	
	memory splObj: SelectorDoesNotUnderstand  put: dnuSelectorOop.
	
	nonExistingSelector:= memory integerObjectOf: 41.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter setBreakSelector: nil.
	interpreter messageSelector: nonExistingSelector.
	interpreter lookupMethodInClass: receiverClass.
	self assert: interpreter newMethod equals: dnuMethodOop.
]

{ #category : #tests }
VMLookUpTest >> testLookUpWithNilMethodDictionaryFindsCannotInterpret [

	| nonExistingSelector cannotInterpretMethodOop cannotInterpretSelectorOop superclass superclassMethodDictionary |
	self setUpClassAndMethod.
	self setArrayClassIntoClassTable.
	self setMessageClassIntoClassTable.
	
	superclass := self
		newClassInOldSpaceWithSlots: 0
		instSpec: memory arrayFormat.
	self setUpMethodDictionaryIn: superclass.	
	superclassMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: superclass. 
	memory storePointer: SuperclassIndex ofObject: receiverClass  withValue: superclass.	
	
	cannotInterpretMethodOop := methodBuilder newMethod buildMethod.
	cannotInterpretSelectorOop := self newString: 'CannotInterpret'. 
	self installSelector: cannotInterpretSelectorOop method: cannotInterpretMethodOop inMethodDictionary: superclassMethodDictionary.
	
	memory splObj: SelectorCannotInterpret  put: cannotInterpretSelectorOop.
	
	nonExistingSelector:= memory integerObjectOf: 41.
	
	interpreter methodDictLinearSearchLimit: 3.
	interpreter setBreakSelector: nil.
	interpreter messageSelector: nonExistingSelector.
	interpreter lookupMethodInClass: receiverClass.
	self assert: interpreter newMethod equals: cannotInterpretMethodOop.
]

{ #category : #tests }
VMLookUpTest >> testPrimitivePerformCreatesCorrectFrame [
	| aMethodDictionary receiverOop frame |	
	"Primitive perform sets everything up (frame, instruction pointer..) so next interpret loop will execute the first bytecode."
	"(1) the Instruction Pointer is set to be just before the bytecode to execute, so fetchNextBytecode will fetch the first bytecode ( #justActivateNewMethod: )"

	self setUpClassAndMethod.	
	self setUpMethodDictionaryIn: receiverClass.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: receiverClass.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.
	interpreter methodDictLinearSearchLimit: 3.

	receiverOop := memory integerObjectOf: 41."random number"	
	interpreter push: receiverOop.
	interpreter push: selectorOop.
	interpreter argumentCount: 1.
	interpreter primitivePerform.
	
	interpreter internalizeIPandSP.
	frame := VMStackFrame newFramePointer: (interpreter framePointer) withInterpreter: interpreter.
	self assert: frame receiver equals: receiverOop.
 	self assert: frame method equals: methodOop.
	"self assert: frame arguments equals: 0." "<- we could add it when implemented in VMFrame"

]

{ #category : #tests }
VMLookUpTest >> testPrimitivePerformExecutes [
	| aMethodDictionary receiverOop |
	self setUpClassAndMethod.	
	self setUpMethodDictionaryIn: receiverClass.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: receiverClass.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.
	interpreter methodDictLinearSearchLimit: 3.

	receiverOop := memory integerObjectOf: 41."random number"	
	interpreter push: receiverOop.
	interpreter push: selectorOop.
	interpreter argumentCount: 1." seems to be the offset from the stack top."
	interpreter primitivePerform.
	
	self assert: interpreter stackTop equals: receiverOop
]

{ #category : #tests }
VMLookUpTest >> testPrimitivePerformFindsMethodOop [
	| aMethodDictionary receiverOop |
	self setUpClassAndMethod.	
	self setUpMethodDictionaryIn: receiverClass.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: receiverClass.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.
	interpreter methodDictLinearSearchLimit: 3.

	receiverOop := memory integerObjectOf: 41."random number"	
	interpreter push: receiverOop.
	interpreter push: selectorOop.
	interpreter argumentCount: 1.
	interpreter primitivePerform.
	
	self assert: interpreter newMethod equals: methodOop.
	self assert: interpreter instructionPointer equals: methodOop + objectHeaderSize + wordSize - 1 "+ header object + header of compiledMethod - (1)"
 	
	"(1) the Instruction Pointer is set to be just before the bytecode to execute, so fetchNextBytecode will fetch the first bytecode ( #justActivateNewMethod: )"
]

{ #category : #tests }
VMLookUpTest >> testPrimitivePerformSetsIPBeforeFirstBytecode [
	| aMethodDictionary receiverOop |	
	"Primitive perform sets everything up (frame, instruction pointer..) so next interpret loop will execute the first bytecode."
	"(1) the Instruction Pointer is set to be just before the bytecode to execute, so fetchNextBytecode will fetch the first bytecode ( #justActivateNewMethod: )"

	self setUpClassAndMethod.	
	self setUpMethodDictionaryIn: receiverClass.
	aMethodDictionary := memory fetchPointer: MethodDictionaryIndex ofObject: receiverClass.
	self installSelector: selectorOop method: methodOop  inMethodDictionary: aMethodDictionary.
	interpreter methodDictLinearSearchLimit: 3.

	receiverOop := memory integerObjectOf: 41."random number"	
	interpreter push: receiverOop.
	interpreter push: selectorOop.
	interpreter argumentCount: 1.
	interpreter primitivePerform.
	
	"Minus one because it's *before* first bytecode"
	self assert: interpreter instructionPointer 
		equals: (methodBuilder bytecodeAt: 1 forMethod: methodOop) - 1.

]
