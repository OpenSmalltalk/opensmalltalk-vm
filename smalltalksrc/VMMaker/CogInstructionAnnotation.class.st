"
I am an annotation for a specific generated instruction.  I add information such as ""this is an instruction corresponding to a bytecode pc"", ""this is an instruction containing an object reference"", etc.
"
Class {
	#name : #CogInstructionAnnotation,
	#superclass : #VMStructType,
	#instVars : [
		'annotation',
		'instruction'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'simulation only' }
CogInstructionAnnotation class >> byteSizeForSimulator: aVMClass [
	"Answer an approximation of the byte size of an AbstractInstruction struct.
	 This is for estimating the alloca in allocateOpcodes:bytecodes:ifFail:"
	^self instSize * (aVMClass sizeof: #'void *')
]

{ #category : #translation }
CogInstructionAnnotation class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a CogInstructionAnnotation struct."

	self allInstVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn = 'instruction'
					ifTrue: [#'AbstractInstruction *']
					ifFalse: [#sqInt])]
]

{ #category : #translation }
CogInstructionAnnotation class >> structTypeName [
	^self name allButFirst: 3 "Drop initial Cog"
]

{ #category : #accessing }
CogInstructionAnnotation >> annotation [
	"Answer the value of annotation"

	^ annotation
]

{ #category : #accessing }
CogInstructionAnnotation >> annotation: anObject [
	"Set the value of annotation"

	annotation := anObject
]

{ #category : #accessing }
CogInstructionAnnotation >> instruction [
	"Answer the value of instruction"
	<returnTypeC: #'AbstractInstruction *'>
	^instruction
]

{ #category : #accessing }
CogInstructionAnnotation >> instruction: anObject [
	"Set the value of instruction"

	instruction := anObject
]

{ #category : #printing }
CogInstructionAnnotation >> printStateOn: aStream [
	<doNotGenerate>
	annotation ifNotNil:
		[aStream
			space; nextPut: $(;
			nextPutAll: (Cogit annotationConstantNames at: annotation + 1);
			space; print: instruction; nextPut: $)]
]
