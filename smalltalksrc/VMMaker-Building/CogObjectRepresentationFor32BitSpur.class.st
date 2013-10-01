Class {
	#name : #CogObjectRepresentationFor32BitSpur,
	#superclass : #CogObjectRepresentationForSpur,
	#category : #'VMMaker-JIT'
}

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genGetClassTagOf: instReg into: destReg scratchReg: scratchReg [
	^self getInlineCacheClassTagFrom: instReg into: destReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genJumpNotSmallIntegerInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: 1 R: aRegister.
	^cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> genJumpSmallIntegerInScratchReg: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit AndCq: 1 R: aRegister.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationFor32BitSpur >> getInlineCacheClassTagFrom: sourceReg into: destReg [
	"Extract the inline cache tag for the object in sourceReg into destReg. The inline
	 cache tag for a given object is the value loaded in inline caches to distinguish objects
	 of different classes.  In Spur this is either the tags for immediates, (with 1 & 3 collapsed
	 to 1 for SmallIntegers), or the receiver's classIndex.  Generate something like this:
		Limm:
			andl $0x1, rDest
			j Lcmp
		Lentry:
			movl rSource, rDest
			andl $0x3, rDest
			jnz Limm
			movl 0x4(%edx), rDest
			andl $0x3fffff, rDest
		Lcmp
	"
	| immLabel entryLabel jumpCompare |
	<var: #immLabel type: #'AbstractInstruction *'>
	<var: #entryLabel type: #'AbstractInstruction *'>
	<var: #jumpCompare type: #'AbstractInstruction *'>
	cogit AlignmentNops: BytesPerWord.
	immLabel := cogit Label.
	cogit AndCq: 1 R: destReg.
	jumpCompare := cogit Jump: 0.
	cogit AlignmentNops: BytesPerWord.
	entryLabel := cogit Label.
	cogit MoveR: sourceReg R: destReg.
	cogit AndCq: objectMemory tagMask R: destReg.
	cogit JumpNonZero: immLabel.
	self flag: #endianness.
	"Get least significant half of header word in destReg"
	cogit MoveMw: 0 r: sourceReg R: destReg.
	cogit AndCq: objectMemory classIndexMask R: destReg.
	jumpCompare jmpTarget: cogit Label.
	^entryLabel
]
