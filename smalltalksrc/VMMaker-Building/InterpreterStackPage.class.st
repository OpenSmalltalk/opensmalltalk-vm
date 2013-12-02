"
I am a class that helps organize the StackInterpreter's collection of stack pages.  I represent the control block for a single stack page in the collection of stack pages represented by an InterpreterStackPages instance.
"
Class {
	#name : #InterpreterStackPage,
	#superclass : #VMStructType,
	#instVars : [
		'stackLimit',
		'headSP',
		'headFP',
		'baseFP',
		'baseAddress',
		'realStackLimit',
		'lastAddress',
		'trace',
		'nextPage',
		'prevPage'
	],
	#pools : [
		'VMBasicConstants',
		'VMSqueakV3BytecodeConstants'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
InterpreterStackPage class >> alignedByteSize [
	^self surrogateClass alignedByteSize
]

{ #category : #translation }
InterpreterStackPage class >> alignedByteSizeOf: anObject forClient: aVMClass [
	^self surrogateClass alignedByteSize
]

{ #category : #translation }
InterpreterStackPage class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a StackPage struct."

	self allInstVarNames do:
		[:ivn|
		ivn ~= 'stackPagesMemory' ifTrue:
			[aBinaryBlock
				value: ivn
				value: (ivn = 'trace'
						ifTrue: [#int]
						ifFalse:
							[(ivn endsWith: 'Page')
								ifTrue: ['struct _StackPage *']
								ifFalse: [#'char *']])]]
]

{ #category : #translation }
InterpreterStackPage class >> structTypeName [
	^'StackPage' "Drop initial Cog or Interpreter"
]

{ #category : #'simulation only' }
InterpreterStackPage class >> surrogateClass [
	^BytesPerWord = 4
		ifTrue: [CogStackPageSurrogate32]
		ifFalse: [CogStackPageSurrogate64]
]

{ #category : #'simulation only' }
InterpreterStackPage >> address [
	<doNotGenerate>
	^baseAddress
]

{ #category : #testing }
InterpreterStackPage >> addressIsInPage: address [
	<var: #address type: #'char *'>
	"For assert-checking"
	^lastAddress < address and: [address < baseAddress]
]

{ #category : #accessing }
InterpreterStackPage >> baseAddress [
	^baseAddress
]

{ #category : #accessing }
InterpreterStackPage >> baseAddress: anAddress [
	^baseAddress := anAddress
]

{ #category : #accessing }
InterpreterStackPage >> baseFP [
	"Answer the value of baseFP"

	^ baseFP
]

{ #category : #accessing }
InterpreterStackPage >> baseFP: pointer [ "<Integer>"
	"Set the value of baseFP"
	self assert: (pointer = 0 or: [pointer < baseAddress and: [realStackLimit < pointer]]).
	^baseFP := pointer
]

{ #category : #accessing }
InterpreterStackPage >> headFP [
	"Answer the value of headFP"

	^headFP
]

{ #category : #accessing }
InterpreterStackPage >> headFP: pointer [ "<Integer>"
	"Set the value of headFP"
	"N.B.  This assert is run in simulation only because headFP:
	 becomes a simple field assignment in the C code."
	self assert: (pointer = 0 or: [pointer < baseAddress and: [realStackLimit - (LargeContextSize / 2) <= pointer]]).
	^headFP := pointer
]

{ #category : #accessing }
InterpreterStackPage >> headSP [
	"Answer the value of headSP"

	^headSP
]

{ #category : #accessing }
InterpreterStackPage >> headSP: pointer [ "<Integer>"
	"Set the value of headSP"
	"N.B.  This assert is run in simulation only because headFP:
	 becomes a simple field assignment in the C code."
	self assert: (pointer = 0 or: [pointer < baseAddress and: [realStackLimit - LargeContextSize <= pointer]]).
	^headSP := pointer
]

{ #category : #testing }
InterpreterStackPage >> isFree [
	^baseFP = 0
]

{ #category : #accessing }
InterpreterStackPage >> lastAddress [
	^lastAddress
]

{ #category : #accessing }
InterpreterStackPage >> lastAddress: anAddress [
	^lastAddress := anAddress
]

{ #category : #accessing }
InterpreterStackPage >> nextPage [
	"Answer the value of nextPage"

	^ nextPage
]

{ #category : #accessing }
InterpreterStackPage >> nextPage: anObject [
	"Set the value of nextPage"

	^nextPage := anObject
]

{ #category : #accessing }
InterpreterStackPage >> prevPage [
	"Answer the value of prevPage"

	^ prevPage
]

{ #category : #accessing }
InterpreterStackPage >> prevPage: anObject [
	"Set the value of prevPage"

	^prevPage := anObject
]

{ #category : #printing }
InterpreterStackPage >> printOn: aStream [
	<doNotGenerate>
	super printOn: aStream.
	aStream nextPut: $@; print: baseAddress; space.
	self isFree
		ifTrue: [aStream nextPutAll: 'free']
		ifFalse: [aStream print: baseFP; nextPutAll: '<->'; print: headFP; space; nextPutAll: 'trace '; print: trace]
]

{ #category : #accessing }
InterpreterStackPage >> realStackLimit [
	"Answer the value of realStackLimit"

	^ realStackLimit
]

{ #category : #accessing }
InterpreterStackPage >> realStackLimit: anObject [
	"Set the value of realStackLimit"

	^realStackLimit := anObject
]

{ #category : #accessing }
InterpreterStackPage >> stackLimit [
	"Answer the value of stackLimit"

	^ stackLimit
]

{ #category : #accessing }
InterpreterStackPage >> stackLimit: anObject [
	"Set the value of stackLimit"

	^stackLimit := anObject
]

{ #category : #accessing }
InterpreterStackPage >> trace [
	"Answer the page's trace state.
	 0 = untraced.  1 = should be traced. 2 = has been traced.
	-1 = invalid (for assertions)"
	^trace
]

{ #category : #accessing }
InterpreterStackPage >> trace: anInteger [
	"Set the page's trace state.
	 0 = untraced.  1 = should be traced. 2 = has been traced.
	-1 = invalid (for assertions)"
	^trace := anInteger
]
