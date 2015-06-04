"
I am a record of a block, the address of the fake header, the association between the bytecode startpc and the machine code start label, and the block's relevant metrics.
"
Class {
	#name : #CogBlockStart,
	#superclass : #VMStructType,
	#instVars : [
		'fakeHeader',
		'fillInstruction',
		'numArgs',
		'numCopied',
		'numInitialNils',
		'startpc',
		'entryLabel',
		'stackCheckLabel',
		'span',
		'hasInstVarRef'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogBlockStart class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a BlockStart struct."

	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['entryLabel']		-> [#'AbstractInstruction *'].
						['fakeHeader']		-> [#'AbstractInstruction *'].
						['fillInstruction']	-> [#'AbstractInstruction *'].
						['stackCheckLabel']	-> [#'AbstractInstruction *'] }
					otherwise:
						[#sqInt])]
]

{ #category : #translation }
CogBlockStart class >> structTypeName [
	^self name allButFirst: 3 "Drop initial Cog"
]

{ #category : #accessing }
CogBlockStart >> entryLabel [
	"Answer the value of entryLabel"

	^ entryLabel
]

{ #category : #accessing }
CogBlockStart >> entryLabel: anObject [
	"Set the value of entryLabel"

	^entryLabel := anObject
]

{ #category : #accessing }
CogBlockStart >> fakeHeader [
	"Answer the value of fakeHeader"
	<returnTypeC: #'AbstractInstruction *'>
	^fakeHeader
]

{ #category : #accessing }
CogBlockStart >> fakeHeader: anObject [
	"Set the value of fakeHeader"

	^fakeHeader := anObject
]

{ #category : #accessing }
CogBlockStart >> fillInstruction [
	"Answer the value of fillInstruction"
	<returnTypeC: #'AbstractInstruction *'>
	^fillInstruction
]

{ #category : #accessing }
CogBlockStart >> fillInstruction: anObject [
	"Set the value of fillInstruction"

	^fillInstruction := anObject
]

{ #category : #accessing }
CogBlockStart >> hasInstVarRef [

	^ hasInstVarRef
]

{ #category : #accessing }
CogBlockStart >> hasInstVarRef: anObject [

	^hasInstVarRef := anObject
]

{ #category : #accessing }
CogBlockStart >> numArgs [
	"Answer the value of numArgs"

	^ numArgs
]

{ #category : #accessing }
CogBlockStart >> numArgs: anObject [
	"Set the value of numArgs"

	^numArgs := anObject
]

{ #category : #accessing }
CogBlockStart >> numCopied [
	"Answer the value of numCopied"

	^ numCopied
]

{ #category : #accessing }
CogBlockStart >> numCopied: anObject [
	"Set the value of numCopied"

	^numCopied := anObject
]

{ #category : #accessing }
CogBlockStart >> numInitialNils [
	"Answer the value of numInitialNils"

	^ numInitialNils
]

{ #category : #accessing }
CogBlockStart >> numInitialNils: anObject [
	"Set the value of numInitialNils"

	^numInitialNils := anObject
]

{ #category : #printing }
CogBlockStart >> printStateOn: aStream [
	<doNotGenerate> "Smalltalk-side only"
	aStream
		space; nextPut: $(;
		nextPutAll: 'numArgs: '; print: numArgs;
		nextPutAll: ' numCopied: '; print: numCopied;
		nextPutAll: ' numInitialNils: '; print: numInitialNils;
		nextPutAll: ' hasInstVarRef: '; print: hasInstVarRef;
		nextPutAll: ' startpc: '; print: startpc;
		nextPutAll: ' span: '; print: span;
		nextPut: $)
]

{ #category : #accessing }
CogBlockStart >> span [
	"Answer the value of span"

	^ span
]

{ #category : #accessing }
CogBlockStart >> span: anObject [
	"Set the value of span"

	^span := anObject
]

{ #category : #accessing }
CogBlockStart >> stackCheckLabel [
	"Answer the value of stackCheckLabel"
	<returnTypeC: #'AbstractInstruction *'>
	^stackCheckLabel
]

{ #category : #accessing }
CogBlockStart >> stackCheckLabel: anObject [
	"Set the value of stackCheckLabel"

	^stackCheckLabel := anObject
]

{ #category : #accessing }
CogBlockStart >> startpc [
	"Answer the value of startpc"

	^ startpc
]

{ #category : #accessing }
CogBlockStart >> startpc: anObject [
	"Set the value of startpc"

	^startpc := anObject
]
