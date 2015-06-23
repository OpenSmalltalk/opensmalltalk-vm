Class {
	#name : #CogObjectRepresentationFor64BitSpur,
	#superclass : #CogObjectRepresentationForSpur,
	#category : #'VMMaker-JIT'
}

{ #category : #'accessing class hierarchy' }
CogObjectRepresentationFor64BitSpur class >> defaultObjectMemoryClass [
	"For in-image compilation.  Spur64BitCoMemoryManager is as yet undefined."
	^Smalltalk classNamed: #Spur64BitCoMemoryManager
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> allImmediate: immediateMask branchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	| incorrectTag tag1 tag2 |
	<var: #targetFixUp type: #'AbstractInstruction *'>
	(self genJumpNotImmediate: reg) jmpTarget: targetFixUp. 
	immediateMask = objectMemory tagMask ifFalse: 
		[ "TempReg holds the rcvr tag"
		"In this case one immediate tag out of the three is not present in arrayObj. 
		We look for it, and generate a jump to the fixup if the rcvr tag matches"
		tag1 := objectMemory classTagForClass: (objectMemory fetchPointer: 0 ofObject: arrayObj).
		tag2 := objectMemory classTagForClass: (objectMemory fetchPointer: 1 ofObject: arrayObj).
		incorrectTag :=  self fetchImmediateTagOtherThanTag1: tag1 tag2: tag2.
		cogit CmpCq: incorrectTag R: TempReg.
		cogit JumpZero: targetFixUp ].
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> allocateCounters: nCounters [
	"On Spur allocate the counters on the heap as pinned objects.
	 Each counter occupies 32-bits.  The number of counters can
	 be derived from the number of slots in the obj."
	<inline: true>
	| objOop |
	objOop := objectMemory allocatePinnedSlots: nCounters + 1 // 2.
	^objOop
		ifNil: [0]
		ifNotNil: [objOop + objectMemory baseHeaderSize]
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> branch2CasesIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	"Only 2 immediate type allowed out of the three. Look for the third and jump to target fixup if it's the third.
	TempReg currently holds the rcvr tag and the receiver is immediate."
	
	| incorrectTag classObj tag1 tag2 |
	< inline: true>		
	
	"look for the 2 allowed tags"
	0 to: (objectMemory numSlotsOf: arrayObj) - 1 do:
		[:i|
		 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
		 (objectMemory isImmediateClass: classObj)
			ifTrue: [ tag1
				ifNil: [tag1 := objectMemory classTagForClass: classObj ]
				ifNotNil: [tag2 := objectMemory classTagForClass: classObj ] ] ].
	
	incorrectTag := self fetchImmediateTagOtherThanTag1: tag1 tag2: tag2.
	cogit CmpCq: incorrectTag R: TempReg.
	cogit JumpZero: targetFixUp.
	
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> branchIf: reg hasNotImmediateTag: classIndex target: targetFixUp [
	| jmpImmediate|
	<inline: true>
	cogit MoveR: reg R: TempReg.
	classIndex = objectMemory smallIntegerTag ifTrue:
		[jmpImmediate := self genJumpNotSmallIntegerInScratchReg: TempReg].
	classIndex = objectMemory characterTag ifTrue:
		[jmpImmediate := self genJumpNotCharacterInScratchReg: TempReg].
	classIndex = objectMemory smallFloatTag ifTrue:
		[jmpImmediate := self genJumpNotSmallFloatInScratchReg: TempReg].
	jmpImmediate jmpTarget: targetFixUp
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> fetchImmediateTagOtherThanTag1: tag1 tag2: tag2 [
	"Answers the immediate tag which is not tag1 nor tag2, usually Character."
	<inline: true>
	(tag1 = objectMemory characterTag or: [ tag2 = objectMemory characterTag ]) ifFalse: 
		[ ^ objectMemory characterTag ].
	(tag1 = objectMemory smallIntegerTag or: [ tag2 = objectMemory smallIntegerTag ]) ifFalse: 
		[ ^ objectMemory smallIntegerTag ].
	^ objectMemory smallFloatTag
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genFetchIndexRegister: indexReg from: tableObj into: destReg [
	"indexReg contains the 1-relative index of an element in tableObj.
	 Since BaseHeaderSize = BytesPerOop we can use it as a
	 zero-relative index from the beginning of the object."
	self assert: indexReg ~= destReg.
	cogit genMoveConstant: tableObj R: destReg.
	cogit MoveXwr: indexReg R: destReg R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpNotSmallInteger: reg scratchReg: scratch [
	"Generate a compare and branch to test if aRegister contains other than a SmallInteger.
	 Answer the jump.  Override since scratch is needed."
	cogit AndCq: objectMemory tagMask R: reg R: scratch.
	cogit CmpCq: objectMemory smallIntegerTag R: scratch.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor64BitSpur >> genJumpSmallInteger: reg scratchReg: scratch [
	"Generate a compare and branch to test if aRegister contains a SmallInteger.
	 Answer the jump.  Override since scratch is needed."
	cogit AndCq: objectMemory tagMask R: reg R: scratch.
	cogit CmpCq: objectMemory smallIntegerTag R: scratch.
	^cogit JumpZero: 0
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor64BitSpur >> illegalClassTag [
	<inline: true>
	^0
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor64BitSpur >> inlineCacheTagForClass: classOop [
	"Answer the relevant inline cache tag for a class.
	 c.f. inlineCacheTagForInstance:"
	^objectMemory classTagForClass: classOop
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationFor64BitSpur >> inlineCacheTagForInstance: oop [
	"Answer the relevant inline cache tag for an instance.
	 c.f. getInlineCacheClassTagFrom:into: & inlineCacheTagForClass:"
	^(objectMemory isImmediate: oop)
		ifTrue: [oop bitAnd: objectMemory tagMask]
		ifFalse: [objectMemory classIndexOf: oop]
]

{ #category : #initialization }
CogObjectRepresentationFor64BitSpur >> log2BytesPerWord [
	^3
]

{ #category : #'sista support' }
CogObjectRepresentationFor64BitSpur >> numCountersFor: theCounters [
	<var: #theCounters type: #usqInt>
	| objOop |
	theCounters = 0 ifTrue:
		[^0].
	objOop := theCounters - objectMemory baseHeaderSize.
	^2 * (objectMemory numSlotsOf: objOop)
]

{ #category : #'debug support' }
CogObjectRepresentationFor64BitSpur >> validInlineCacheTag: classIndexOrTagPattern [
	"The three valid tag patterns are 1 (SmallInteger), 2 (Character) and 3 (SmallFloat64)."
	^(classIndexOrTagPattern >= 1
	  and: [classIndexOrTagPattern <= 3])
	  or: [(objectMemory classAtIndex: classIndexOrTagPattern) notNil]
]
