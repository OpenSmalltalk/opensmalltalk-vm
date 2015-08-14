"
I am a class that helps organize the StackInterpreter's collection of stack pages.  I represent the control block for a single stack page in the collection of stack pages represented by an InterpreterStackPages or CoInterpreterStackPages instance.
"
Class {
	#name : #CogStackPage,
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
		'VMBytecodeConstants'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
CogStackPage class >> alignedByteSize [
	^self surrogateClass alignedByteSize
]

{ #category : #translation }
CogStackPage class >> alignedByteSizeOf: anObject forClient: aVMClass [
	^self surrogateClass alignedByteSize
]

{ #category : #translation }
CogStackPage class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
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
CogStackPage class >> structTypeName [
	^'StackPage' "Drop initial Cog or Interpreter"
]

{ #category : #'simulation only' }
CogStackPage class >> surrogateClass [
	^BytesPerWord = 4
		ifTrue: [CogStackPageSurrogate32]
		ifFalse: [CogStackPageSurrogate64]
]

{ #category : #'simulation only' }
CogStackPage >> address [
	<doNotGenerate>
	^baseAddress
]

{ #category : #testing }
CogStackPage >> addressIsInPage: address [
	<var: #address type: #'char *'>
	"For assert-checking"
	^lastAddress < address and: [address < baseAddress]
]

{ #category : #accessing }
CogStackPage >> baseAddress [
	^baseAddress
]

{ #category : #accessing }
CogStackPage >> baseAddress: anAddress [
	^baseAddress := anAddress
]

{ #category : #accessing }
CogStackPage >> baseFP [
	"Answer the value of baseFP"

	^ baseFP
]

{ #category : #accessing }
CogStackPage >> baseFP: pointer [ "<Integer>"
	"Set the value of baseFP"
	self assert: (pointer = 0 or: [pointer < baseAddress and: [realStackLimit < pointer]]).
	^baseFP := pointer
]

{ #category : #accessing }
CogStackPage >> headFP [
	"Answer the value of headFP"

	^headFP
]

{ #category : #accessing }
CogStackPage >> headFP: pointer [ "<Integer>"
	"Set the value of headFP"
	^headFP := pointer
]

{ #category : #accessing }
CogStackPage >> headSP [
	"Answer the value of headSP"

	^headSP
]

{ #category : #accessing }
CogStackPage >> headSP: pointer [ "<Integer>"
	"Set the value of headSP"
	^headSP := pointer
]

{ #category : #testing }
CogStackPage >> isFree [
	^baseFP = 0
]

{ #category : #accessing }
CogStackPage >> lastAddress [
	^lastAddress
]

{ #category : #accessing }
CogStackPage >> lastAddress: anAddress [
	^lastAddress := anAddress
]

{ #category : #accessing }
CogStackPage >> nextPage [
	"Answer the value of nextPage"

	^ nextPage
]

{ #category : #accessing }
CogStackPage >> nextPage: anObject [
	"Set the value of nextPage"

	^nextPage := anObject
]

{ #category : #accessing }
CogStackPage >> prevPage [
	"Answer the value of prevPage"

	^ prevPage
]

{ #category : #accessing }
CogStackPage >> prevPage: anObject [
	"Set the value of prevPage"

	^prevPage := anObject
]

{ #category : #printing }
CogStackPage >> printOn: aStream [
	<doNotGenerate>
	super printOn: aStream.
	aStream nextPut: $@; print: baseAddress; space.
	self isFree
		ifTrue: [aStream nextPutAll: 'free']
		ifFalse: [aStream print: baseFP; nextPutAll: '<->'; print: headFP; space; nextPutAll: 'trace '; print: trace]
]

{ #category : #accessing }
CogStackPage >> realStackLimit [
	"Answer the value of realStackLimit"

	^ realStackLimit
]

{ #category : #accessing }
CogStackPage >> realStackLimit: anObject [
	"Set the value of realStackLimit"

	^realStackLimit := anObject
]

{ #category : #accessing }
CogStackPage >> stackLimit [
	"Answer the value of stackLimit"

	^ stackLimit
]

{ #category : #accessing }
CogStackPage >> stackLimit: anObject [
	"Set the value of stackLimit"

	^stackLimit := anObject
]

{ #category : #accessing }
CogStackPage >> trace [
	"Answer the page's trace state.
	 0 = untraced.  1 = should be traced. 2 = has been traced.
	-1 = invalid (for assertions)"
	^trace
]

{ #category : #accessing }
CogStackPage >> trace: anInteger [
	"Set the page's trace state.
	 0 = untraced.  1 = should be traced. 2 = has been traced.
	-1 = invalid (for assertions)"
	^trace := anInteger
]
