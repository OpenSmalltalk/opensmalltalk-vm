Class {
	#name : #VMCompiledMethodProxy,
	#superclass : #VMObjectProxy,
	#category : #'VMMaker-Support'
}

{ #category : #accessing }
VMCompiledMethodProxy >> at: index [
	^(index between: 1 and: (objectMemory byteLengthOf: oop))
		ifTrue: [objectMemory fetchByte: index - 1 ofObject: oop]
		ifFalse: [self errorSubscriptBounds: index]
]

{ #category : #accessing }
VMCompiledMethodProxy >> endPC [
	"Answer the index of the last bytecode."
	^(coInterpreter cogit endPCOf: oop) + 1
]

{ #category : #literals }
VMCompiledMethodProxy >> header [
	^objectMemory integerValueOf: (coInterpreter headerOf: oop)
]

{ #category : #accessing }
VMCompiledMethodProxy >> initialPC [
	"Answer the program counter for the receiver's first bytecode."

	^(coInterpreter startPCOfMethod: oop) + 1
]

{ #category : #literals }
VMCompiledMethodProxy >> literalAt: index [ 
	^VMObjectProxy new
		for: (coInterpreter literal: index - 1 ofMethod: oop)
		coInterpreter: coInterpreter
		objectMemory: objectMemory
]

{ #category : #accessing }
VMCompiledMethodProxy >> numArgs [
	"Answer the argument count of the receiver."
	
	^coInterpreter argumentCountOf: oop
]

{ #category : #accessing }
VMCompiledMethodProxy >> numLiterals [
	"Answer the number of literals used by the receiver."
	
	^coInterpreter literalCountOf: oop
]

{ #category : #accessing }
VMCompiledMethodProxy >> numTemps [
	^coInterpreter tempCountOf: oop
]

{ #category : #accessing }
VMCompiledMethodProxy >> size [
	^objectMemory byteLengthOf: oop
]

{ #category : #accessing }
VMCompiledMethodProxy >> usesAlternateBytecodeSet [

	^coInterpreter headerIndicatesAlternateBytecodeSet: self header
]
