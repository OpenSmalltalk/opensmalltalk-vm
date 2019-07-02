"
I am a fixup for a bytecode in the Cogit.  Currently fixups are for labels only.  To fixup jumps the cogit places fixups in the fixups array at indices that correspond to bytecodes that are the targets of jumps.  When the cogit encounters a bytecode with a fixup it assigns the fixup's target field to the first generated instruction for the bytecode.  Later when AbstractInstruction Jump* instructions attempt to compute their target they follow the indirection through the fixup to the actual target.
"
Class {
	#name : #CogBytecodeFixup,
	#superclass : #VMStructType,
	#instVars : [
		'targetInstruction',
		'instructionIndex',
		'bcpc'
	],
	#classVars : [
		'NeedsFixupFlag'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'simulation only' }
CogBytecodeFixup class >> byteSizeForSimulator: aVMClass [
	"Answer an approximation of the byte size of an AbstractInstruction struct.
	 This is for estimating the alloca in allocateOpcodes:bytecodes:ifFail:"
	^self instSize * (aVMClass sizeof: #'void *')
]

{ #category : #translation }
CogBytecodeFixup class >> filteredInstVarNames [
	"Override to eliminate bcpc,"
	^super filteredInstVarNames copyWithout: 'bcpc'
]

{ #category : #'instance creation' }
CogBytecodeFixup class >> for: aCogit [
	^self new
]

{ #category : #'class initialization' }
CogBytecodeFixup class >> initialize [
	"Initialize the fixup flags.  In this class we have only one flag, 1, which
	 means set the fixup to point to the first instruction for a particular bytecode.
	 A forward branch from one bytecode to a later one will set its jmpTarget to
	 a fixup.  later, in compileAbstractInstructionsFrom:to:, any fixup with its
	 targetInstruction set to NeedsFixupFlag will have its targetInstruction set
	 to the first bytecode of the sequence.  Later still, when code is generated
	 jumps follow fixups to eliminate the fixup and target the rigth instruction."
	NeedsFixupFlag := 1
]

{ #category : #translation }
CogBytecodeFixup class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"Enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a BytecodeFixup struct."
	"self withAllSubclasses collect: [:ea| ea typedef]"

	self filteredInstVarNames do:
		[:ivn|
		 aBinaryBlock
			value: ivn
			value: (ivn first ~= $# ifTrue:
						[ivn caseOf: {
							['targetInstruction']				-> [#'AbstractInstruction *'].
							['mergeSimStack']				-> [#'SimStackEntry *'].
							['instructionIndex']				-> [#'unsigned short'].
							['simStackPtr']					-> [#'unsigned char'].
							['simNativeStackPtr']			-> [#'short'].
							['simNativeStackSize']			-> [#'unsigned short'].
							['isTargetOfBackwardBranch']	-> [#char] }])]
]

{ #category : #translation }
CogBytecodeFixup class >> structTypeName [
	^'BytecodeFixup'
]

{ #category : #coercion }
CogBytecodeFixup >> asInteger [
	<doNotGenerate>
	^self
]

{ #category : #accessing }
CogBytecodeFixup >> bcpc [

	^ bcpc
]

{ #category : #accessing }
CogBytecodeFixup >> bcpc: anObject [

	^bcpc := anObject
]

{ #category : #converting }
CogBytecodeFixup >> becomeFixup [
	<inline: true>
	targetInstruction := self cCoerceSimple: NeedsFixupFlag to: #'AbstractInstruction *'
]

{ #category : #coercion }
CogBytecodeFixup >> cCoerceSimple: flagOrAbstractOp to: cType [
	<doNotGenerate>
	^ flagOrAbstractOp
]

{ #category : #'instance initialization' }
CogBytecodeFixup >> initialize [
	targetInstruction := 0
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

{ #category : #testing }
CogBytecodeFixup >> needsFixup [
	<inline: true>
	^ targetInstruction asInteger = NeedsFixupFlag
]

{ #category : #testing }
CogBytecodeFixup >> notAFixup [
	<inline: true>
	^ targetInstruction = 0
]

{ #category : #'debug printing' }
CogBytecodeFixup >> printStateOn: aStream [
	<doNotGenerate>
	targetInstruction ifNotNil:
		[aStream space; nextPut: $(; print: targetInstruction; nextPutAll: ' bc '; print: bcpc; nextPut: $)]
]

{ #category : #simulation }
CogBytecodeFixup >> recordBcpc: theBytecodePC [
	<inline: true>
	self cCode: '' inSmalltalk:
		[(bcpc isNil or: [bcpc = theBytecodePC])
			ifTrue: [bcpc := theBytecodePC]
			ifFalse:
				[bcpc := bcpc isInteger
							ifTrue: [{bcpc. theBytecodePC}]
							ifFalse:
								[(bcpc includes: theBytecodePC) ifTrue: [^self].
								 bcpc, {theBytecodePC}]]]
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
