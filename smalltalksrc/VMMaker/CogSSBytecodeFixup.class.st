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
		'simStackPtr'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'simulation support' }
CogSSBytecodeFixup >> asUnsignedInteger [
	<doNotGenerate>
	^self
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
CogSSBytecodeFixup >> simStackPtr [
	"Answer the value of simStackPtr"

	^ simStackPtr
]

{ #category : #accessing }
CogSSBytecodeFixup >> simStackPtr: anObject [
	"Set the value of simStackPtr"

	^simStackPtr := anObject
]
