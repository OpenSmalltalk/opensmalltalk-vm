"
Answer the set of temporary variables that are read before they are written.
"
Class {
	#name : #ReadBeforeWrittenVisitor,
	#superclass : #ParseNodeVisitor,
	#instVars : [
		'readBeforeWritten',
		'written'
	],
	#category : #'Cog-Scripts'
}

{ #category : #accessing }
ReadBeforeWrittenVisitor >> readBeforeWritten [
	^readBeforeWritten ifNil: [IdentitySet new]
]

{ #category : #visiting }
ReadBeforeWrittenVisitor >> visitAssignmentNode: anAssignmentNode [
	anAssignmentNode value accept: self.
	anAssignmentNode variable isTemp
		ifTrue:
			[written ifNil: [written := IdentitySet new].
			 written add: anAssignmentNode variable]
		ifFalse:
			[anAssignmentNode variable accept: self]
]

{ #category : #visiting }
ReadBeforeWrittenVisitor >> visitBlockNode: aBlockNode [
	| savedWritten |
	savedWritten := written copy.
	super visitBlockNode: aBlockNode.
	written := savedWritten
]

{ #category : #visiting }
ReadBeforeWrittenVisitor >> visitTempVariableNode: aTempVariableNode [
	(aTempVariableNode isArg
	 or: [written notNil
		and: [written includes: aTempVariableNode]]) ifTrue:
		[^self].
	readBeforeWritten ifNil:
		[readBeforeWritten := IdentitySet new].
	readBeforeWritten add: aTempVariableNode
]
