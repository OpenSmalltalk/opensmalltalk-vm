Class {
	#name : #CogStackPage,
	#superclass : #InterpreterStackPage,
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogStackPage class >> alignedByteSize [
	^self surrogateClass alignedByteSize
]

{ #category : #'simulation only' }
CogStackPage class >> surrogateClass [
	^BytesPerWord = 4
		ifTrue: [CogStackPageSurrogate32]
		ifFalse: [CogStackPageSurrogate64]
]
