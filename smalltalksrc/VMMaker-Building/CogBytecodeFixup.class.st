"
I am a fixup for a bytecode in the Cojit.  Currently fixups are for labels only.  To fixup jumps the cogit places fixups in the fixups array at indices that correspond to bytecodes that are the targets of jumps.  When the cogit encounters a bytecode with a fixup it assigns the fixup's target field to the first generated instruction for the bytecode.  Later when AbstractInstruction Jump* instructions attempt to compute their target they follow the indirection throguh the fixup to the actual target.

In C I am a union of a target field and an index field.
"
Class {
	#name : #CogBytecodeFixup,
	#superclass : #VMStructType,
	#instVars : [
		'targetInstruction',
		'instructionIndex'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogBytecodeFixup class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a BytecodeFixup struct."

	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn = 'targetInstruction'
					ifTrue: [#'AbstractInstruction *']
					ifFalse:
						[#sqInt])]
]

{ #category : #translation }
CogBytecodeFixup class >> structTypeName [
	^self name allButFirst: 3 "Drop initial Cog"
]

{ #category : #coercion }
CogBytecodeFixup >> asInteger [
	<doNotGenerate>
	^self
]

{ #category : #accessing }
CogBytecodeFixup >> instructionIndex [
	"Answer the value of instructionIndex"

	^instructionIndex
]

{ #category : #accessing }
CogBytecodeFixup >> instructionIndex: anObject [
	"Set the value of instructionIndex"

	^instructionIndex := anObject
]

{ #category : #accessing }
CogBytecodeFixup >> targetInstruction [
	"Answer the value of targetInstruction"

	^ targetInstruction
]

{ #category : #accessing }
CogBytecodeFixup >> targetInstruction: anObject [
	"Set the value of targetInstruction"

	^targetInstruction := anObject
]
