Class {
	#name : #CogObjectRepresentationFor64BitSpur,
	#superclass : #CogObjectRepresentationForSpur,
	#category : #'VMMaker-JIT'
}

{ #category : #accessing }
CogObjectRepresentationFor64BitSpur class >> defaultObjectMemoryClass [
	"For in-image compilation.  Spur64BitCoMemoryManager is as yet undefined."
	^Smalltalk classNamed: #Spur64BitCoMemoryManager
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genFetchIndexRegister: indexReg from: tableObj into: destReg [
	"indexReg contains the 1-relative index of an element in tableObj.
	 Since BaseHeaderSize = BytesPerOop we can use it as a
	 zero-relative index from the beginning of the object."
	self assert: indexReg ~= destReg.
	cogit annotate: (cogit MoveCw: tableObj R: destReg) objRef: tableObj.
	cogit MoveXwr: indexReg R: destReg R: destReg.
	^0
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor64BitSpur >> inlineCacheTagForInstance: oop [
	"c.f. getInlineCacheClassTagFrom:into:"
	^(objectMemory isImmediate: oop)
		ifTrue: [oop bitAnd: objectMemory tagMask]
		ifFalse: [objectMemory classIndexOf: oop]
]

{ #category : #initialization }
CogObjectRepresentationFor64BitSpur >> log2BytesPerWord [
	^3
]
