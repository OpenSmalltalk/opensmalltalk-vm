Class {
	#name : #CogSimpleStackPage,
	#superclass : #InterpreterStackPage,
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogSimpleStackPage class >> alignedByteSize [
	^self surrogateClass alignedByteSize
]

{ #category : #'simulation only' }
CogSimpleStackPage class >> surrogateClass [
	^BytesPerWord = 4
		ifTrue: [CogSimpleStackPageSurrogate32]
		ifFalse: [CogSimpleStackPageSurrogate64]
]
