Class {
	#name : #VMMTGenerationTests,
	#superclass : #TestCase,
	#instVars : [
		'vm'
	],
	#category : #'VMMakerCompatibilityForPharo6-Tests'
}

{ #category : #tests }
VMMTGenerationTests >> generate: aSelector [
	| codeGenerator |
	codeGenerator := CCodeGenerator new.
	codeGenerator vmClass: StackInterpreterMT.
	codeGenerator addClass: StackInterpreter.
	codeGenerator addClass: StackInterpreterMT.
	codeGenerator addClass: SpurMemoryManager.
	codeGenerator inferTypesForImplicitlyTypedVariablesAndMethods.
	codeGenerator doInlining: true.
		
	^ codeGenerator cCodeForMethod: aSelector
]

{ #category : #tests }
VMMTGenerationTests >> testGenerateActiveProcess [

	| result |
	result := self generate: #activeProcess.
	
	self assert: (self withoutComments: result) equals: (self withoutComments: '

/*	Answer the current activeProcess. */
/*	useful for VM debugging */

	/* StackInterpreter>>#activeProcess */
sqInt
activeProcess(void)
{
    sqInt objOop;
    sqInt objOop1;

	/* begin fetchPointer:ofObject: */
	objOop1 = longAt((specialObjectsOop + BaseHeaderSize) + (((sqInt)((usqInt)(SchedulerAssociation) << (shiftForWord())))));
	objOop = longAt((objOop1 + BaseHeaderSize) + (((sqInt)((usqInt)(ValueIndex) << (shiftForWord())))));
	return longAt((objOop + BaseHeaderSize) + (((sqInt)((usqInt)(ActiveProcessIndex) << (shiftForWord())))));
}
')
]

{ #category : #tests }
VMMTGenerationTests >> withoutComments: aString [

	^ Character cr join: (aString lines reject: [ :l | | trimmed |
		trimmed := l trimBoth.
		trimmed isEmpty or: [trimmed beginsWith: '/*'] ])
]
