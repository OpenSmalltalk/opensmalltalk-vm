"
A CogSSBytecodeFixup extends CogBytecodeFixup with state to merge the stack at control-flow joins.  At a join the code generator must ensure that the stack is spilled to the same point along both branches and that the simStackPtr is correct.

Instance Variables
	simStackPtr:		<Integer>

simStackPtr
	- the simStackPtr at the jump to this fixup.  It should either agree with the incoming fixup if control continues, or replace the simStackPtr if contrl doesn't continue (the incomming control flow ended with a return)
"
Class {
	#name : #CogSSBytecodeFixup,
	#superclass : #CogBytecodeFixup,
	#instVars : [
		'simStackPtr',
		'simNativeStackPtr',
		'simNativeStackSize'
	],
	#classVars : [
		'NeedsMergeFixupFlag',
		'NeedsNonMergeFixupFlag',
		'UnknownSimStackPtrFlag'
	],
	#category : #'VMMaker-JIT'
}

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
	self assert: NeedsNonMergeFixupFlag < NeedsMergeFixupFlag.

	UnknownSimStackPtrFlag := -2
]

{ #category : #'simulation support' }
CogSSBytecodeFixup >> asUnsignedInteger [
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

{ #category : #testing }
CogSSBytecodeFixup >> isBackwardBranchFixup [
	<inline: true>
	^ simStackPtr = UnknownSimStackPtrFlag
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
		[aStream space; print: simStackPtr].
	aStream nextPut: $)
]

{ #category : #accessing }
CogSSBytecodeFixup >> reinitialize [
	<inline: true>
	targetInstruction := 0.
	simStackPtr := 0.
	self cppIf: LowcodeVM ifTrue: [
		simNativeStackPtr := 0.
	]
]

{ #category : #accessing }
CogSSBytecodeFixup >> setIsBackwardBranchFixup [
	<inline: true>
	simStackPtr := UnknownSimStackPtrFlag.
	self cppIf: LowcodeVM ifTrue: [ 
		simNativeStackPtr := UnknownSimStackPtrFlag.
		simNativeStackSize := 0.
	]

]

{ #category : #accessing }
CogSSBytecodeFixup >> simNativeStackPtr [
	"Answer the value of simStackPtr"

	^ simNativeStackPtr
]

{ #category : #accessing }
CogSSBytecodeFixup >> simNativeStackPtr: anObject [
	"Set the value of simStackPtr"

	^simNativeStackPtr := anObject
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
