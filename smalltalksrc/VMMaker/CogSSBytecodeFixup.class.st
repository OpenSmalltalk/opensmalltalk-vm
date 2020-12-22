"
A CogSSBytecodeFixup extends CogBytecodeFixup with state to merge the stack at control-flow joins.  At a join the code generator must ensure that the stack is spilled to the same point along both branches and that the simStackPtr is correct.

Instance Variables
	simStackPtr:					<Integer>
	isTargetOfBackwardBranch:		<Boolean>

simStackPtr
	- the simStackPtr at the jump to this fixup.  It should either agree with the incoming fixup if control continues, or replace the simStackPtr if control doesn't continue (the incoming control flow ended with a return)

isTargetOfBackwardBranch:
	- if true the fixup is the target of some backward branch
"
Class {
	#name : #CogSSBytecodeFixup,
	#superclass : #CogBytecodeFixup,
	#instVars : [
		'simStackPtr',
		'isTargetOfBackwardBranch',
		'simNativeStackPtr',
		'simNativeStackSize'
	],
	#classVars : [
		'NeedsMergeFixupFlag',
		'NeedsNonMergeFixupFlag'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'simulation only' }
CogSSBytecodeFixup class >> byteSizeForSimulator: aVMClass [
	"Answer an approximation of the byte size of an AbstractInstruction struct.
	 This is for estimating the alloca in allocateOpcodes:bytecodes:ifFail:
	 self withAllSubclasses collect: [:ea| { ea byteSizeForSimulator: ea basicNew. ea typedef}]"
	^(self instSize - 2) * (aVMClass sizeof: #'void *')
]

{ #category : #translation }
CogSSBytecodeFixup class >> filteredInstVarNames [
	"Override to add ifdef LowcodeVM around the native stack info, and to put
	 char vars before short vars.
	 self typedef"
	| vars |
	vars := super filteredInstVarNames asOrderedCollection.
	vars
		remove: 'instructionIndex';
			add: 'instructionIndex' afterIndex: (vars indexOf: 'simStackPtr');
		remove: 'isTargetOfBackwardBranch';
			add: 'isTargetOfBackwardBranch' afterIndex: (vars indexOf: 'simStackPtr').
	^vars
]

{ #category : #'class initialization' }
CogSSBytecodeFixup class >> initialize [
	"Initialize the fixup flags.  In this class we have two states.  A fixup is a bytecode
	 being targeted by a branch, and a jump can target the fixup before the byetcode
	 is generated.  A non-merge fixup is that for a bytecode that follows a return instruction.
	 There is no control flow merge from the preceding instruction for this kind of fixup.
	 A merge fixup is that for a bytecode where control flow arrives from both the preceding
	 instruction and a branch.  When compileAbstractInstructionsFrom:to: finds a merge
	 fixup, it must both set the targetInstruction and merge the stack/register state of the
	 control flow from the preceding instruction with the stack/register state from the branch.
	 Later still, when code is generated jumps follow fixups to eliminate the fixup and target
	 the right instruction."
	NeedsNonMergeFixupFlag := 1.
	NeedsMergeFixupFlag := 2.
	self assert: NeedsNonMergeFixupFlag < NeedsMergeFixupFlag
]

{ #category : #'simulation support' }
CogSSBytecodeFixup >> asIntegerPtr [
	<doNotGenerate>
	^self
]

{ #category : #'simulation support' }
CogSSBytecodeFixup >> asUnsignedInteger [
	<doNotGenerate>
	^self
]

{ #category : #'simulation support' }
CogSSBytecodeFixup >> asUnsignedIntegerPtr [
	<doNotGenerate>
	^self
]

{ #category : #converting }
CogSSBytecodeFixup >> becomeMergeFixup [
	<inline: true>
	targetInstruction := self cCoerceSimple: NeedsMergeFixupFlag to: #'AbstractInstruction *'
]

{ #category : #converting }
CogSSBytecodeFixup >> becomeNonMergeFixup [
	<inline: true>
	targetInstruction := self cCoerceSimple: NeedsNonMergeFixupFlag to: #'AbstractInstruction *'
]

{ #category : #'instance initialization' }
CogSSBytecodeFixup >> initialize [
	targetInstruction := 0.
	isTargetOfBackwardBranch := false
]

{ #category : #testing }
CogSSBytecodeFixup >> isBackwardBranchFixup [
	^isTargetOfBackwardBranch
]

{ #category : #testing }
CogSSBytecodeFixup >> isMergeFixup [
	<inline: true>
	^ targetInstruction asUnsignedInteger = NeedsMergeFixupFlag
]

{ #category : #testing }
CogSSBytecodeFixup >> isMergeFixupOrIsFixedUp [
	<inline: true>
	^ targetInstruction asUnsignedInteger >= NeedsMergeFixupFlag
]

{ #category : #testing }
CogSSBytecodeFixup >> isNonMergeFixup [
	<inline: true>
	^ targetInstruction asUnsignedInteger = NeedsNonMergeFixupFlag
]

{ #category : #testing }
CogSSBytecodeFixup >> isNonMergeFixupOrNotAFixup [
	<inline: true>
	^ targetInstruction asUnsignedInteger <= NeedsNonMergeFixupFlag
]

{ #category : #testing }
CogSSBytecodeFixup >> isTargetOfBackwardBranch [
	^isTargetOfBackwardBranch
]

{ #category : #testing }
CogSSBytecodeFixup >> needsFixup [
	<inline: true>
	^ targetInstruction asUnsignedInteger between: NeedsNonMergeFixupFlag and: NeedsMergeFixupFlag
]

{ #category : #testing }
CogSSBytecodeFixup >> needsFixupOrIsFixedUp [
	<inline: true>
	^ targetInstruction asUnsignedInteger > 0
]

{ #category : #testing }
CogSSBytecodeFixup >> notYetFixedUp [
	<inline: true>
	^ targetInstruction asUnsignedInteger <= NeedsMergeFixupFlag
]

{ #category : #'debug printing' }
CogSSBytecodeFixup >> printStateOn: aStream [
	<doNotGenerate>
	(targetInstruction isNil and: [simStackPtr isNil]) ifTrue:
		[^self].
	aStream space; nextPut: $(.
	targetInstruction ifNotNil:
		[aStream space; print: targetInstruction].
	simStackPtr ifNotNil:
		[aStream nextPutAll: ' sp '; print: simStackPtr].
	bcpc ifNotNil:
		[aStream nextPutAll: ' bc '; print: bcpc].
	aStream nextPut: $)
]

{ #category : #accessing }
CogSSBytecodeFixup >> reinitialize [
	<inline: true>
	targetInstruction := simStackPtr := 0.
]

{ #category : #accessing }
CogSSBytecodeFixup >> setIsBackwardBranchFixup [
	<inline: true>
	isTargetOfBackwardBranch := true
]

{ #category : #accessing }
CogSSBytecodeFixup >> simNativeStackSize [
	"Answer the value of simStackPtr"

	^ simNativeStackSize
]

{ #category : #accessing }
CogSSBytecodeFixup >> simNativeStackSize: anObject [
	"Set the value of simStackPtr"

	^simNativeStackSize := anObject
]

{ #category : #accessing }
CogSSBytecodeFixup >> simStackPtr [
	"Answer the value of simStackPtr"

	^ simStackPtr
]

{ #category : #accessing }
CogSSBytecodeFixup >> simStackPtr: anObject [
	"Set the value of simStackPtr"

	^simStackPtr := anObject
]
