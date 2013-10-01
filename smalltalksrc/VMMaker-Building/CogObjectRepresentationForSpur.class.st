Class {
	#name : #CogObjectRepresentationForSpur,
	#superclass : #CogObjectRepresentation,
	#category : #'VMMaker-JIT'
}

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genLoadSlot: index sourceReg: sourceReg destReg: destReg [
	cogit
		MoveMw: index * objectMemory wordSize + objectMemory baseHeaderSize
		r: sourceReg
		R: destReg.
	^0
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genStoreCheckTrampoline [
	"Call ceStoreCheck: with the object stored into"
	^cogit
		genTrampolineFor: #ceStoreCheck:
		called: 'ceStoreCheckTrampoline'
		arg: ReceiverResultReg
		result: cogit returnRegForStoreCheck
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> getInlineCacheClassTagFrom: sourceReg into: destReg [
	"Extract the inline cache tag for the object in sourceReg into destReg. The inline cache tag
	 for a given object is the value loaded in inline caches to distinguish objects of different
	 classes.  In Spur this is either the tags for immediates, or the receiver's classIndex."
	^self subclassResponsibility
]

{ #category : #'object representation' }
CogObjectRepresentationForSpur >> isSmallIntegerTagNonZero [
	^true
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> shouldAnnotateObjectReference: anOop [
	"Objects in newSpace or oldSPace except nil, true & false need to be annotated."
	^(objectMemory isNonImmediate: anOop)
	  and: [(self oop: anOop isGreaterThan: objectMemory trueObject)
		or: [self oop: anOop isLessThan: objectMemory nilObject]]
]
