Class {
	#name : #CogObjectRepresentationForSpur,
	#superclass : #CogObjectRepresentation,
	#category : #'VMMaker-JIT'
}

{ #category : #'debug support' }
CogObjectRepresentationForSpur >> checkValidInlineCacheTag: classIndexOrTagPattern [
	^classIndexOrTagPattern <= objectMemory tagMask
	  or: [(objectMemory classAtIndex: classIndexOrTagPattern) notNil]
]

{ #category : #'debug support' }
CogObjectRepresentationForSpur >> checkValidObjectReference: anOop [
	^(objectMemory isImmediate: anOop)
	   or: [(objectMemory heapMapAtWord: (self pointerForOop: anOop)) ~= 0]
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genLoadSlot: index sourceReg: sourceReg destReg: destReg [
	cogit
		MoveMw: index * objectMemory wordSize + objectMemory baseHeaderSize
		r: sourceReg
		R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genRemoveSmallIntegerTagsInScratchReg: scratchReg [
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genSetSmallIntegerTagsIn: scratchReg [
	self subclassResponsibility
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
CogObjectRepresentationForSpur >> genStoreImmediateInSourceReg: sourceReg slotIndex: index destReg: destReg [
	cogit MoveR: sourceReg
		   Mw: index * objectMemory wordSize + objectMemory baseHeaderSize
		   r: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreSourceReg: sourceReg slotIndex: index destReg: destReg scratchReg: scratchReg [
	| jmpImmediate jmpDestYoung jmpSourceOld jmpAlreadyRemembered mask rememberedBitByteOffset |
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	<var: #jmpDestYoung type: #'AbstractInstruction *'>
	<var: #jmpSourceOld type: #'AbstractInstruction *'>
	<var: #jmpAlreadyRemembered type: #'AbstractInstruction *'>
	"do the store"
	cogit MoveR: sourceReg
		   Mw: index * objectMemory wordSize + objectMemory baseHeaderSize
		   r: destReg.
	"now the check.  Is value stored an integer?  If so we're done"
	cogit MoveR: sourceReg R: scratchReg.
	cogit AndCq: objectMemory tagMask R: scratchReg.
	jmpImmediate := cogit JumpNonZero: 0.
	"Get the old/new boundary in scratchReg"
	cogit MoveAw: objectMemory newSpaceLimitAddress R: scratchReg.
	"Is target young?  If so we're done"
	cogit CmpR: scratchReg R: destReg. "N.B. FLAGS := destReg - scratchReg"
	jmpDestYoung := cogit JumpBelow: 0.
	"Is value stored old?  If so we're done."
	cogit CmpR: scratchReg R: sourceReg. "N.B. FLAGS := sourceReg - scratchReg"
	jmpSourceOld := cogit JumpAboveOrEqual: 0.
	"value is young and target is old.
	 Need to remember this only if the remembered bit is not already set.
	 Test the remembered bit.  Only need to fetch the byte containing it,
	 which reduces the size of the mask constant."
	rememberedBitByteOffset := jmpSourceOld isBigEndian
									ifTrue: [objectMemory baseHeaderSize - 1 - (objectMemory rememberedBitShift // 8)]
									ifFalse:[objectMemory rememberedBitShift // 8].
	mask := 1 << (objectMemory rememberedBitShift \\ 8).
	cogit MoveMb: rememberedBitByteOffset r: destReg R: scratchReg.
	cogit AndCq: mask R: scratchReg.
	jmpAlreadyRemembered := cogit JumpNonZero: 0.
	"Remembered bit is not set.  Call store check to insert dest into remembered table."
	self assert: destReg == ReceiverResultReg.
	cogit CallRT: cogit ceStoreCheckTrampoline.
	jmpImmediate jmpTarget:
	(jmpDestYoung jmpTarget:
	(jmpSourceOld jmpTarget:
	(jmpAlreadyRemembered jmpTarget:
		cogit Label))).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> getInlineCacheClassTagFrom: sourceReg into: destReg [
	"Extract the inline cache tag for the object in sourceReg into destReg. The inline cache tag
	 for a given object is the value loaded in inline caches to distinguish objects of different
	 classes.  In Spur this is either the tags for immediates, or the receiver's classIndex."
	^self subclassResponsibility
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> hasValidHeaderPostGC: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	^cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSpur >> inlineCacheTagForInstance: oop [
	"c.f. getInlineCacheClassTagFrom:into:"
	(objectMemory isImmediate: oop) ifTrue:
		[(objectMemory isIntegerObject: oop) ifTrue:
			[^objectMemory integerObjectOf: 0]. "the SmallInteger tag"
		 ^oop bitAnd: objectMemory tagMask]. "the other tags"
	^objectMemory classIndexOf: oop
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSpur >> inlineCacheTagIsYoung: anInteger [
	"classIndices are not objects, heh, heh, heh..."
	^false
]

{ #category : #'object representation' }
CogObjectRepresentationForSpur >> isImmediate: oop [
	^objectMemory isImmediate: oop
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

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> slotOffsetOfInstVarIndex: index [
	^index * objectMemory wordSize + objectMemory baseHeaderSize
]
