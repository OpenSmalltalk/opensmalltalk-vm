Class {
	#name : #CogObjectRepresentationForSpur,
	#superclass : #CogObjectRepresentation,
	#instVars : [
		'ceScheduleScavengeTrampoline',
		'ceSmallActiveContextInMethodTrampoline',
		'ceSmallActiveContextInBlockTrampoline',
		'ceSmallActiveContextInFullBlockTrampoline',
		'ceLargeActiveContextInMethodTrampoline',
		'ceLargeActiveContextInBlockTrampoline',
		'ceLargeActiveContextInFullBlockTrampoline',
		'ceStoreCheckContextReceiverTrampoline',
		'ceStoreTrampolines',
		'ceNewHashTrampoline',
		'ceInlineNewHashTrampoline'
	],
	#classVars : [
		'CheckRememberedInTrampoline',
		'NumStoreTrampolines'
	],
	#pools : [
		'VMBytecodeConstants',
		'VMSqueakClassIndices'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogObjectRepresentationForSpur class >> declareCVarsIn: aCodeGen [
	"Deal wuth the fact that the number of trampolines depends on IMMUTABILITY
	 and that IMMUTABILITY can be defined at compile time.  Yes, this is a mess."
	| current values |
	current := InitializationOptions at: #IMMUTABILITY ifAbsent: nil.
	values := #(true false) collect:
				[:bool|
				 InitializationOptions at: #IMMUTABILITY put: bool.
				 self cogitClass initializeNumTrampolines.
				 (Cogit classPool at: #NumTrampolines) printString].
	current
		ifNil: [InitializationOptions removeKey: #IMMUTABILITY]
		ifNotNil: [InitializationOptions at: #IMMUTABILITY put: current].
	values first ~= values last ifTrue:
		[aCodeGen addConstantForBinding: #NumTrampolines -> ('(IMMUTABILITY ? ' , values first , ' : ' , values last , ')')].
	aCodeGen
		var: #ceStoreTrampolines
		declareC: ('#if IMMUTABILITY\sqInt ceStoreTrampolines[', NumStoreTrampolines printString, '];\#endif') withCRs
]

{ #category : #'class initialization' }
CogObjectRepresentationForSpur class >> initialize [
	"Number of trampolines for the combined IMMUTABILITY/store check instance variable store.
	 Trampolines from 0 to NumStoreTrampolines - 2 are dedicated to an inst var index, the last one is generic."
	NumStoreTrampolines := 5
]

{ #category : #initialization }
CogObjectRepresentationForSpur class >> initializeMiscConstants [
	CheckRememberedInTrampoline := InitializationOptions at: #CheckRememberedInTrampoline ifAbsent: [false]
]

{ #category : #accessing }
CogObjectRepresentationForSpur class >> numTrampolines [
	^super numTrampolines
		 + (SistaV1BytecodeSet
			ifTrue: [9] "(small,large)x(method,block,fullBlock) context creation,
						 ceNewHashTrampoline, ceStoreCheckContextReceiverTrampoline and ceScheduleScavengeTrampoline"
			ifFalse: [7] "(small,large)x(method,block) context creation, 
						 ceNewHashTrampoline, ceStoreCheckContextReceiverTrampoline and ceScheduleScavengeTrampoline")
		 + NumStoreTrampolines
		 + (SistaVM
			ifTrue: [1] "inline newHash"
			ifFalse: [0])
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> allYoungObjectsAgeInFullGC [
	^false
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> branchIf: reg instanceOfBehavior: classObj target: targetFixUp [
	"Generate a branch if reg is an instance of classObj, otherwise fall-
	 through. Cannot change the value of reg (may be used afterwards)."
	| classIndex jmp |
	<inline: true>
	<var: #targetFixUp type: #'AbstractInstruction *'>
	<var: #jmp type: #'AbstractInstruction *'>
	classIndex := objectMemory classTagForClass: classObj.
	classIndex = (objectMemory fetchClassTagOf: objectMemory falseObject)
		ifTrue: [ self branchIf: reg isOop: objectMemory falseObject target: targetFixUp ].
	classIndex = (objectMemory fetchClassTagOf: objectMemory trueObject)
		ifTrue: [ self branchIf: reg isOop: objectMemory trueObject target: targetFixUp ].
	classIndex = (objectMemory fetchClassTagOf: objectMemory nilObject)
		ifTrue: [ self branchIf: reg isOop: objectMemory nilObject target: targetFixUp ].
	(objectMemory isImmediateClass: classObj)
		ifTrue:
			[self branchIf: reg hasImmediateTag: classIndex target: targetFixUp ]
		ifFalse:
			[jmp := (self genJumpImmediate: reg) .
			 self genGetClassIndexOfNonImm: reg into: TempReg.
			 self genCmpClassIndex: classIndex R: TempReg.
			 cogit JumpZero: targetFixUp.
			jmp jmpTarget: cogit Label ].
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> branchIf: reg instanceOfBehaviors: arrayObj target: targetFixUp [
	"Generate a branch if reg is an instance of any of the classes in arrayObj,
	 otherwise fall-through. reg should not be edited."
	
	| allImmediate noneImmediate immediateMask numNonImmediates classObj |
	<var: #targetFixUp type: #'AbstractInstruction *'>
	
	"let me tell you all about it, let me falsify"
	allImmediate := true. noneImmediate := true. immediateMask := 0. numNonImmediates := 0.
	0 to: (objectMemory numSlotsOf: arrayObj) - 1 do:
		[:i|
		 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
		 (objectMemory isImmediateClass: classObj)
			ifTrue:
				[noneImmediate := false.
				 immediateMask := immediateMask + (objectMemory classTagForClass: classObj)]
			ifFalse:
				[allImmediate := false.
				 numNonImmediates := numNonImmediates + 1]].

	noneImmediate ifTrue: [ ^ self noneImmediateBranchIf: reg instanceOfBehaviors: arrayObj target: targetFixUp ].

	allImmediate ifTrue: [ ^ self allImmediate: immediateMask branchIf: reg instanceOfBehaviors: arrayObj target: targetFixUp ].

	^ self mixed: numNonImmediates branchIf: reg instanceOfBehaviors: arrayObj target: targetFixUp
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> branchIf: reg isNotOop:  oop target: targetFixUp [
	<var: #targetFixUp type: #'AbstractInstruction *'>
	<inline: true>
	cogit CmpCq: oop R: reg.
	cogit JumpNonZero: targetFixUp.
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> branchIf: reg isOop:  oop target: targetFixUp [
	<var: #targetFixUp type: #'AbstractInstruction *'>
	<inline: true>
	cogit CmpCq: oop R: reg.
	cogit JumpZero: targetFixUp.
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> branchIf: reg notInstanceOfBehavior: classObj target: targetFixUp [
	"Generate a branch if reg is an instance of classObj, otherwise fall-
	 through. Cannot change the value of reg (may be used afterwards)."
	| classIndex |
	<inline: true>
	<var: #targetFixUp type: #'AbstractInstruction *'>
	classIndex := objectMemory classTagForClass: classObj.
	classIndex = (objectMemory fetchClassTagOf: objectMemory falseObject)
		ifTrue: [ self branchIf: reg isNotOop: objectMemory falseObject target: targetFixUp ].
	classIndex = (objectMemory fetchClassTagOf: objectMemory trueObject)
		ifTrue: [ self branchIf: reg isNotOop:  objectMemory trueObject target: targetFixUp ].
	classIndex = (objectMemory fetchClassTagOf: objectMemory nilObject)
		ifTrue: [ self branchIf: reg isNotOop:  objectMemory nilObject target: targetFixUp ].
	(objectMemory isImmediateClass: classObj)
		ifTrue:
			[self branchIf: reg hasNotImmediateTag: classIndex target: targetFixUp ]
		ifFalse:
			[(self genJumpImmediate: reg) jmpTarget: targetFixUp.
			 self genGetClassIndexOfNonImm: reg into: TempReg.
			 self genCmpClassIndex: classIndex R: TempReg.
			 cogit JumpNonZero: targetFixUp ].
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> branchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	"Generate a branch if reg is an instance of any of the classes in arrayObj,
	 otherwise fall-through. reg should not be edited."
	
	| allImmediate noneImmediate immediateMask numNonImmediates classObj |
	<var: #targetFixUp type: #'AbstractInstruction *'>
	
	"let me tell you all about it, let me falsify"
	allImmediate := true. noneImmediate := true. immediateMask := 0. numNonImmediates := 0.
	0 to: (objectMemory numSlotsOf: arrayObj) - 1 do:
		[:i|
		 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
		 (objectMemory isImmediateClass: classObj)
			ifTrue:
				[noneImmediate := false.
				 immediateMask := immediateMask + (objectMemory classTagForClass: classObj)]
			ifFalse:
				[allImmediate := false.
				 numNonImmediates := numNonImmediates + 1]].

	noneImmediate ifTrue: [ ^ self noneImmediateBranchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp ].

	allImmediate ifTrue: [ ^ self allImmediate: immediateMask branchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp ].

	^ self mixed: numNonImmediates branchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> cacheTagIsMarked: cacheTag [
	"Answer if the cacheTag is not unmarked, i.e. answer true for compact class
	 indices and immediates; only answer false for unmarked objects.  In Spur
	 linked send cache tags are class indices so effectively they're always marked."
	^true
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> callStoreCheckTrampoline [
	cogit CallRT: ceStoreCheckTrampoline
]

{ #category : #testing }
CogObjectRepresentationForSpur >> canPinObjects [
	"Answer if the memory manager supports pinned objects."
	^true
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceLargeActiveContextInBlockTrampoline [
	<doNotGenerate>
	^ ceLargeActiveContextInBlockTrampoline
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceLargeActiveContextInBlockTrampoline: anInteger [ 
	<doNotGenerate>
	ceLargeActiveContextInBlockTrampoline := anInteger
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceLargeActiveContextInFullBlockTrampoline [
	<doNotGenerate>
	^ ceLargeActiveContextInFullBlockTrampoline
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceLargeActiveContextInFullBlockTrampoline: anInteger [ 
	<doNotGenerate>
	ceLargeActiveContextInFullBlockTrampoline := anInteger
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceLargeActiveContextInMethodTrampoline [
	<doNotGenerate>
	^ ceLargeActiveContextInMethodTrampoline
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceLargeActiveContextInMethodTrampoline: anInteger [ 
	<doNotGenerate>
	ceLargeActiveContextInMethodTrampoline := anInteger
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceScheduleScavengeTrampoline: anAddress [
	<doNotGenerate>
	ceScheduleScavengeTrampoline := anAddress
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceSmallActiveContextInBlockTrampoline [
	<doNotGenerate>
	^ ceSmallActiveContextInBlockTrampoline
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceSmallActiveContextInBlockTrampoline: anInteger [ 
	<doNotGenerate>
	ceSmallActiveContextInBlockTrampoline := anInteger
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceSmallActiveContextInFullBlockTrampoline [
	<doNotGenerate>
	^ ceSmallActiveContextInFullBlockTrampoline
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceSmallActiveContextInFullBlockTrampoline: anInteger [ 
	<doNotGenerate>
	ceSmallActiveContextInFullBlockTrampoline := anInteger
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceSmallActiveContextInMethodTrampoline [
	<doNotGenerate>
	^ ceSmallActiveContextInMethodTrampoline
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceSmallActiveContextInMethodTrampoline: anInteger [ 
	<doNotGenerate>
	ceSmallActiveContextInMethodTrampoline := anInteger
]

{ #category : #accessing }
CogObjectRepresentationForSpur >> ceStoreCheckTrampoline [
	
	^ ceStoreCheckTrampoline 
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> ceStoreTrampolines [

	^ ceStoreTrampolines
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> checkRememberedInTrampoline [
	<inline: true>
	^ CheckRememberedInTrampoline
]

{ #category : #'debug support' }
CogObjectRepresentationForSpur >> checkValidDerivedObjectReference: bodyAddress [
	^(objectMemory heapMapAtWord: (self pointerForOop: bodyAddress - objectMemory baseHeaderSize)) ~= 0
]

{ #category : #'debug support' }
CogObjectRepresentationForSpur >> checkValidOopReference: anOop [
	^(objectMemory isImmediate: anOop)
	   or: [(objectMemory heapMapAtWord: (self pointerForOop: anOop)) ~= 0]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> couldBeDerivedObject: bodyAddress [
	^self oop: bodyAddress - objectMemory baseHeaderSize isGreaterThanOrEqualTo: objectMemory startOfMemory
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> couldBeObject: literal [
	^(objectMemory isNonImmediate: literal)
	  and: [self oop: literal isGreaterThanOrEqualTo: objectMemory startOfMemory]
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> createsArraysInline [
	"Answer if the object representation allocates arrays inline.  By
	 default answer false. Better code can be generated when creating
	 arrays inline if values are /not/ flushed to the stack."
	^true
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> createsClosuresInline [
	"Answer if the object representation allocates closures inline.  By
	 default answer false. Better code can be generated when creating
	 closures inline if copied values are /not/ flushed to the stack."
	^true
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> ensureNoForwardedLiteralsIn: aMethodObj [
	"Ensure there are no forwarded literals in the argument."
	<doNotGenerate>
	objectMemory ensureNoForwardedLiteralsIn: aMethodObj
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> freeCounters: theCounters [
	<var: #theCounters type: #usqInt>
	<inline: true>
	<option: #SistaCogit>
	theCounters ~= 0 ifTrue:
		[objectMemory freeObject: theCounters - objectMemory baseHeaderSize]
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genActiveContextTrampolineLarge: isLarge inBlock: isInBlock called: aString [
	<var: #aString type: #'char *'>
	"Create a trampoline to answer the active context that will
	 answer it if a frame is already married, and create it otherwise.
	 Assume numArgs is in SendNumArgsReg and ClassReg is free."
	| startAddress |
	startAddress := cogit methodZoneBase.
	cogit zeroOpcodeIndex.
	self genGetActiveContextLarge: isLarge inBlock: isInBlock.
	cogit outputInstructionsForGeneratedRuntimeAt: startAddress.
	cogit recordGeneratedRunTime: aString address: startAddress.
	cogit recordRunTimeObjectReferences.
	^startAddress
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genAllocExternalAddressValue: valueReg into: resultReg scratchReg: scratch1 scratchReg: scratch2 [
	<returnTypeC: #'AbstractInstruction *'>
	| allocSize newExternalAddressHeader jumpFail |
	allocSize := objectMemory baseHeaderSize + objectMemory wordSize.
	newExternalAddressHeader := objectMemory
							headerForSlots: 1
							format: objectMemory firstByteFormat
							classIndex: objectMemory classExternalAddressIndex.
	cogit MoveAw: objectMemory freeStartAddress R: resultReg.
	cogit LoadEffectiveAddressMw: allocSize r: resultReg R: scratch1.
	cogit CmpCq: objectMemory getScavengeThreshold R: scratch1.
	jumpFail := cogit JumpAboveOrEqual: 0.
	cogit MoveR: scratch1 Aw: objectMemory freeStartAddress.
	self genStoreHeader: newExternalAddressHeader intoNewInstance: resultReg using: scratch1.
	cogit MoveR: valueReg Mw: objectMemory baseHeaderSize r: resultReg.
	^jumpFail
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genAllocFloatValue: dpreg into: resultReg scratchReg: scratch1 scratchReg: scratch2 [
	<returnTypeC: #'AbstractInstruction *'>
	| allocSize newFloatHeader jumpFail |
	<var: #jumpFail type: #'AbstractInstruction *'>
	allocSize := objectMemory baseHeaderSize + (objectMemory sizeof: #double).
	newFloatHeader := objectMemory
							headerForSlots: (self sizeof: #double) / objectMemory wordSize
							format: objectMemory firstLongFormat
							classIndex: ClassFloatCompactIndex.
	cogit MoveAw: objectMemory freeStartAddress R: resultReg.
	cogit LoadEffectiveAddressMw: allocSize r: resultReg R: scratch1.
	cogit CmpCq: objectMemory getScavengeThreshold R: scratch1.
	jumpFail := cogit JumpAboveOrEqual: 0.
	cogit MoveR: scratch1 Aw: objectMemory freeStartAddress.
	self genStoreHeader: newFloatHeader intoNewInstance: resultReg using: scratch1.
	cogit MoveRd: dpreg M64: objectMemory baseHeaderSize r: resultReg.
	^jumpFail
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genBoxedOrSmallFloat: floatOopReg scratchReg: scratchReg into: destReg [
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpImmediate type: #'AbstractInstruction *'>
	<var: #jumpFail type: #'AbstractInstruction *'>
	<var: #jumpFailClass type: #'AbstractInstruction *'>
	<var: #jumpMerge type: #'AbstractInstruction *'>	
	| jumpImmediate jumpFail jumpFailClass jumpMerge |
	
	"Must be pointer"
	jumpImmediate := self genJumpImmediate: floatOopReg.
	
	"Compare with the boxed float clas."
	self genGetCompactClassIndexNonImmOf: floatOopReg into: scratchReg.
	self genCmpClassFloatCompactIndexR: scratchReg.
	jumpFailClass := cogit JumpNonZero: 0.

	"Fetch the double from the boxed float."	
	self genGetDoubleValueOf: floatOopReg into: destReg.
	jumpMerge := cogit Jump: 0.

	jumpImmediate jmpTarget: (jumpFailClass jmpTarget: (jumpFail := cogit Jump: 0)).

	jumpMerge jmpTarget: cogit Label.
	^ jumpFail
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genCheckRememberedBitOf: objReg scratch: scratchReg [
	"Check the remembered bit of the object in objReg; answer the jump taken if the bit is already set.
	 Only need to fetch the byte containing it, which reduces the size of the mask constant."
	| rememberedBitByteOffset mask |
	rememberedBitByteOffset := cogit backEnd isBigEndian
									ifTrue: [objectMemory baseHeaderSize - 1 - (objectMemory rememberedBitShift // 8)]
									ifFalse:[objectMemory rememberedBitShift // 8].
	mask := 1 << (objectMemory rememberedBitShift \\ 8).
	cogit MoveMb: rememberedBitByteOffset r: objReg R: scratchReg.
	cogit TstCq: mask R: scratchReg.
	^cogit JumpNonZero: 0
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSpur >> genCmpClassIndex: classIndex R: reg [
	"It is safe to use a short comparison for the known classes; these will not
	 change with become, etc... But it's probably not safe to assume the hash of
	 some other class won't change over time, so to be sure of generating the
	 same size code over time, use a long comparison for unknown classes."
	classIndex < objectMemory classTablePageSize
		ifTrue: [cogit CmpCq: classIndex R: TempReg]
		ifFalse: [cogit CmpCw: classIndex R: TempReg]
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genConvertCharacterToCodeInReg: reg [ 
	cogit LogicalShiftRightCq: objectMemory numTagBits R: reg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genConvertIntegerToCharacterInReg: reg [
	cogit
		LogicalShiftLeftCq: objectMemory numTagBits R: reg;
		AddCq: objectMemory characterTag R: reg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genConvertSmallIntegerToCharacterInReg: reg [
	self subclassResponsibility
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> genCreateClosureAt: bcpc numArgs: numArgs numCopied: numCopied contextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock [
	"Create a closure with the given startpc, numArgs and numCopied
	 within a context with ctxtNumArgs, large if isLargeCtxt that is in a
	 block if isInBlock.  If numCopied > 0 pop those values off the stack."
	self genNoPopCreateClosureAt: bcpc
		numArgs: numArgs
		numCopied: numCopied
		contextNumArgs: ctxtNumArgs
		large: isLargeCtxt
		inBlock: isInBlock.
	1 to: numCopied do:
		[:i|
		cogit
			PopR: TempReg;
			MoveR: TempReg
				Mw: numCopied - i + ClosureFirstCopiedValueIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize
					r: ReceiverResultReg].
	^0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> genCreateFullClosure: compiledBlock numArgs: numArgs numCopied: numCopied ignoreContext: ignoreContext contextNumArgs: contextNumArgs large: contextIsLarge inBlock: contextIsBlock [
	"Create a full closure with the given values."
	| numSlots byteSize header skip |
	<var: #skip type: #'AbstractInstruction *'>

	"First get thisContext into ReceiverResultReg and thence in ClassReg."
	ignoreContext
		ifTrue: [ cogit genMoveNilR: ClassReg ]
		ifFalse: 
			[self genGetActiveContextNumArgs: contextNumArgs large: contextIsLarge inBlock: contextIsBlock.
			cogit MoveR: ReceiverResultReg R: ClassReg ].
	
	numSlots := FullClosureFirstCopiedValueIndex + numCopied.
	byteSize := objectMemory smallObjectBytesForSlots: numSlots.
	self assert: ClassFullBlockClosureCompactIndex ~= 0.
	header := objectMemory
					headerForSlots: numSlots
					format: objectMemory indexablePointersFormat
					classIndex: ClassFullBlockClosureCompactIndex.
	cogit MoveAw: objectMemory freeStartAddress R: ReceiverResultReg.
	self genStoreHeader: header intoNewInstance: ReceiverResultReg using: TempReg.
	cogit
		LoadEffectiveAddressMw: byteSize r: ReceiverResultReg R: TempReg;
		MoveR: TempReg Aw: objectMemory freeStartAddress;
		CmpCq: objectMemory getScavengeThreshold R: TempReg.
	skip := cogit JumpBelow: 0.
	cogit CallRT: ceScheduleScavengeTrampoline.
	skip jmpTarget: cogit Label.

	cogit
		MoveR: ClassReg Mw: ClosureOuterContextIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize r: ReceiverResultReg;
		genMoveConstant: compiledBlock R: TempReg;
		MoveR: TempReg Mw: ClosureStartPCIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize r: ReceiverResultReg;
		MoveCq: (objectMemory integerObjectOf: numArgs) R: TempReg;
		MoveR: TempReg Mw: ClosureNumArgsIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize r: ReceiverResultReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureObjInRegNotForwarded: reg scratchReg: scratch [
	"Make sure that the object in reg is not forwarded.  This routine assumes the object will
	 never be forwarded to an immediate, as it is used to unforward  literal variables (associations). 
	 Use the fact that isForwardedObjectClassIndexPun is a power of two to save an instruction."
	| loop ok |
	<var: #ok type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	self assert: reg ~= scratch.
	loop := cogit Label.
	"notionally
		self genGetClassIndexOfNonImm: reg into: scratch.
		cogit CmpCq: objectMemory isForwardedObjectClassIndexPun R: TempReg.
	 but the following is an instruction shorter:"
	cogit MoveMw: 0 r: reg R: scratch.
	cogit
		AndCq: objectMemory classIndexMask - objectMemory isForwardedObjectClassIndexPun
		R: scratch.
	ok := cogit JumpNonZero:  0.
	self genLoadSlot: 0 sourceReg: reg destReg: reg.
	cogit Jump: loop.
	ok jmpTarget: cogit Label.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch [
	^ self 
		genEnsureOopInRegNotForwarded: reg 
		scratchReg: scratch 
		jumpBackTo: cogit Label "label is just before the forwarder check"
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch ifForwarder: fwdJumpTarget ifNotForwarder: nonFwdJumpTargetOrZero [
	"Make sure that the oop in reg is not forwarded.  
	 Use the fact that isForwardedObjectClassIndexPun is a power of two to save an instruction."
	| imm ok finished |
	self assert: reg ~= scratch.
	imm := self genJumpImmediate: reg.
	"notionally
		self genGetClassIndexOfNonImm: reg into: scratch.
		cogit CmpCq: objectMemory isForwardedObjectClassIndexPun R: TempReg.
	 but the following is an instruction shorter:"
	cogit MoveMw: 0 r: reg R: scratch.
	cogit
		AndCq: objectMemory classIndexMask - objectMemory isForwardedObjectClassIndexPun
		R: scratch.
	ok := cogit JumpNonZero: 0.
	self genLoadSlot: 0 sourceReg: reg destReg: reg.
	cogit Jump: fwdJumpTarget.
	finished := nonFwdJumpTargetOrZero asUnsignedInteger = 0
					ifTrue: [cogit Label]
					ifFalse: [nonFwdJumpTargetOrZero].
	imm jmpTarget: (ok jmpTarget: finished).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch jumpBackTo: instruction [
	<var: #instruction type: #'AbstractInstruction *'>
	<inline: true>
	^ self 
		genEnsureOopInRegNotForwarded: reg 
		scratchReg: scratch 
		ifForwarder: instruction
		ifNotForwarder: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch updatingMw: offset r: baseReg [
	"Make sure that the oop in reg is not forwarded, and the field reg[offset] is updated
	 if the object in reg is forwarded.  Use the fact that isForwardedObjectClassIndexPun is
	 a power of two to save an instruction."
	| loop imm ok |
	<var: #ok type: #'AbstractInstruction *'>
	<var: #imm type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	self assert: (reg ~= scratch and: [baseReg ~= scratch]).
	loop := cogit Label.
	imm := self genJumpImmediate: reg.
	"notionally
		self genGetClassIndexOfNonImm: reg into: scratch.
		cogit CmpCq: objectMemory isForwardedObjectClassIndexPun R: TempReg.
	 but the following is an instruction shorter:"
	cogit MoveMw: 0 r: reg R: scratch.
	cogit
		AndCq: objectMemory classIndexMask - objectMemory isForwardedObjectClassIndexPun
		R: scratch.
	ok := cogit JumpNonZero:  0.
	self genLoadSlot: 0 sourceReg: reg destReg: reg.
	cogit MoveR: reg Mw: offset r: baseReg.
	cogit Jump: loop.
	ok jmpTarget: (imm jmpTarget: cogit Label).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genEnsureOopInRegNotForwarded: reg scratchReg: scratch updatingSlot: index in: objReg [
	"Make sure that the oop in reg is not forwarded, updating the slot in objReg with the value."
	| loop imm ok |
	<var: #ok type: #'AbstractInstruction *'>
	<var: #imm type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	"Open-code
		self genEnsureOopInRegNotForwarded: reg
			scratchReg: scratch
			updatingMw: index * objectMemory wordSize + objectMemory baseHeaderSize
			r: objReg.
	 to avoid calling the store check unless the receiver is forwarded."
	self assert: (reg ~= scratch and: [objReg ~= scratch]).
	loop := cogit Label.
	imm := self genJumpImmediate: reg.
	"notionally
		self genGetClassIndexOfNonImm: reg into: scratch.
		cogit CmpCq: objectMemory isForwardedObjectClassIndexPun R: TempReg.
	 but the following is an instruction shorter:"
	cogit MoveMw: 0 r: reg R: scratch.
	cogit
		AndCq: objectMemory classIndexMask - objectMemory isForwardedObjectClassIndexPun
		R: scratch.
	ok := cogit JumpNonZero:  0.
	self genLoadSlot: 0 sourceReg: reg destReg: reg.
	cogit MoveR: reg Mw: index * objectMemory wordSize + objectMemory baseHeaderSize r: objReg.

	"Check that we're meeting the contract of ceStoreCheckContextReceiverTrampoline."
	self assert: (reg = Arg0Reg and: [scratch = TempReg and: [objReg = ReceiverResultReg]]).
	cogit CallRT: ceStoreCheckContextReceiverTrampoline.

	cogit Jump: loop.
	ok jmpTarget: (imm jmpTarget: cogit Label).
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genFetchIndexRegister: indexReg from: tableObj into: destReg [
	"indexReg contains the 1-relative index of an element in tableObj."
	self subclassResponsibility
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genGetActiveContextLarge: isLarge inBlock: isInBlock [
	"Create a trampoline to answer the active context that will
	 answer it if a frame is already married, and create it otherwise.
	 Assume numArgs is in SendNumArgsReg and ClassReg is free."
	| header slotSize jumpSingle loopHead jumpNeedScavenge continuation exit |
	<var: #jumpNeedScavenge type: #'AbstractInstruction *'>
	<var: #continuation type: #'AbstractInstruction *'>
	<var: #jumpSingle type: #'AbstractInstruction *'>
	<var: #loopHead type: #'AbstractInstruction *'>
	<var: #exit type: #'AbstractInstruction *'>
	cogit "load the flag; stash it in both TempReg & ClassReg; do the compare (a prime candidated for use of AndCq:R:R:)"
		MoveMw: FoxMethod r: FPReg R: ClassReg;
		AndCq: MFMethodFlagHasContextFlag R: ClassReg R: TempReg.
	jumpSingle := cogit JumpZero: 0. "jump if flag bit not set"
	cogit "since the flag bit was set, get the context in the receiver reg and return"
		MoveMw: FoxThisContext r: FPReg R: ReceiverResultReg;
		RetN: 0.
	jumpSingle jmpTarget: cogit Label.

	"OK, it doesn't exist; instantiate and initialize it"
	"set the hasContext flag; See CoInterpreter class>>initializeFrameIndices"
	cogit
		OrCq: MFMethodFlagHasContextFlag R: ClassReg;
		MoveR: ClassReg Mw: FoxMethod r: FPReg.
	"now get the home CogMethod into ClassReg and save for post-instantiation."
	isInBlock caseOf: {
	[InFullBlock]	-> [cogit SubCq: 3 R: ClassReg]. "-3 is -(hasContext+isBlock) flags"
	[InVanillaBlock]	-> [cogit
							SubCq: 3 R: ClassReg; "-3 is -(hasContext+isBlock) flags"
							MoveM16: 0 r: ClassReg R: TempReg;
							SubR: TempReg R: ClassReg].
	[0]				-> [cogit SubCq: 1 R: ClassReg]. "-1 is hasContext flag" }.

	"instantiate the context..."
	slotSize := isLarge ifTrue: [LargeContextSlots] ifFalse: [SmallContextSlots].
	header := objectMemory
					headerForSlots: slotSize
					format: objectMemory indexablePointersFormat
					classIndex: ClassMethodContextCompactIndex.
	self flag: #endianness.
	cogit MoveAw: objectMemory freeStartAddress R: ReceiverResultReg.
	self genStoreHeader: header intoNewInstance: ReceiverResultReg using: TempReg.
	cogit
		MoveR: ReceiverResultReg R: TempReg;
		AddCq: (objectMemory smallObjectBytesForSlots: slotSize) R: TempReg;
		MoveR: TempReg Aw: objectMemory freeStartAddress;
		CmpCq: objectMemory getScavengeThreshold R: TempReg.
	jumpNeedScavenge := cogit JumpAboveOrEqual: 0.

	"Now initialize the fields of the context.  See CoInterpreter>>marryFrame:SP:copyTemps:"
	"sender gets frame pointer as a SmallInteger"
	continuation :=
	cogit MoveR: FPReg R: TempReg.
	self genSetSmallIntegerTagsIn: TempReg.
	cogit MoveR: TempReg Mw: objectMemory baseHeaderSize + (SenderIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"pc gets frame caller as a SmallInteger"
	cogit MoveMw: FoxSavedFP r: FPReg R: TempReg.
	self genSetSmallIntegerTagsIn: TempReg.
	cogit MoveR: TempReg Mw: objectMemory baseHeaderSize + (InstructionPointerIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"Set the method field, freeing up ClassReg again, and frame's context field,"
	cogit
		MoveMw: (cogit offset: CogMethod of: #methodObject) r: ClassReg R: TempReg;
		MoveR: TempReg Mw: objectMemory baseHeaderSize + (MethodIndex * objectMemory wordSize) r: ReceiverResultReg;
		MoveR: ReceiverResultReg Mw: FoxThisContext r: FPReg.

	"Now compute stack pointer; this is stackPointer (- 1 for return pc if a CISC) - framePointer - wordSize (1 each for saved pc, method, context, receiver) + 1 (1-relative) + numArgs"
	"TPR note - the code here is actually doing
	context stackPointer := ((((fp - sp) / wordSize) - [3|4]) + num args) asSmallInteger"
	cogit
		MoveR: FPReg R: TempReg;
		SubR: SPReg R: TempReg;
		LogicalShiftRightCq: self log2BytesPerWord R: TempReg;
		SubCq: (cogit backEnd hasLinkRegister ifTrue: [3] ifFalse: [4]) R: TempReg;
		AddR: SendNumArgsReg R: TempReg.
	self genConvertIntegerToSmallIntegerInReg: TempReg.
	cogit MoveR: TempReg Mw: objectMemory baseHeaderSize + (StackPointerIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"Set closureOrNil to either the stacked receiver or nil"
	isInBlock > 0
		ifTrue:
			[cogit
				MoveR: SendNumArgsReg R: TempReg;
				AddCq: 2 R: TempReg; "+2 for saved fp and saved pc"
				MoveXwr: TempReg R: FPReg R: TempReg]
		ifFalse:
			[cogit genMoveNilR: TempReg].
	cogit MoveR: TempReg Mw: objectMemory baseHeaderSize + (ClosureIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"Set the receiver"
	cogit
		MoveMw: FoxMFReceiver r: FPReg R: TempReg;
		MoveR: TempReg Mw: objectMemory baseHeaderSize + (ReceiverIndex * objectMemory bytesPerOop) r: ReceiverResultReg.

	"Now copy the arguments.  This is tricky because of the shortage of registers,.  ClassReg ranges
	 from 1 to numArgs (SendNumArgsReg), and from ReceiverIndex + 1 to ReceiverIndex + numArgs.
	 1 to: numArgs do:
		[:i|
		temp := longAt(FPReg + ((SendNumArgs - i + 2) * wordSize)). +2 for saved pc and savedfp
		longAtput(FPReg + FoxMFReceiver + (i * wordSize), temp)]"
	"TPR note: this is a prime candidate for passing off to the backend to do at least faintly optimal code"
	cogit MoveCq: 1 R: ClassReg.
	loopHead := cogit CmpR: SendNumArgsReg R: ClassReg.
	exit := cogit JumpGreater: 0.
	cogit
		MoveR: SendNumArgsReg R: TempReg;
		SubR: ClassReg R: TempReg;
		AddCq: 2 R: TempReg; "+2 for saved fp and saved pc"
		MoveXwr: TempReg R: FPReg R: TempReg;
		AddCq: ReceiverIndex + (objectMemory baseHeaderSize / objectMemory wordSize) R: ClassReg; "Now convert ClassReg from frame index to context index"
		MoveR: TempReg Xwr: ClassReg R: ReceiverResultReg;
		SubCq: ReceiverIndex + (objectMemory baseHeaderSize / objectMemory wordSize) - 1 R: ClassReg; "convert back adding 1 ;-)"
		Jump: loopHead.
	exit jmpTarget: cogit Label.

	"Finally nil or copy the non-argument temps.
	 ClassReg := FPReg + FoxMFReceiver.
	 SendNumArgsReg := SendNumArgsReg+ReceiverIndex.
	 [ClassReg := ClassReg - wordSize.
	  backEnd hasLinkRegister
			ifTrue: [ClassReg > SPReg]
			ifFalse: [ClassReg >= SPReg]] whileTrue:
		[receiver[SendNumArgsReg] := *ClassReg.
		 SendNumArgsReg := SendNumArgsReg + 1]]"
	coInterpreter marryFrameCopiesTemps ifFalse:
		[cogit MoveCq: objectMemory nilObject R: TempReg].
	cogit
		MoveR: FPReg R: ClassReg;
		AddCq: FoxMFReceiver R: ClassReg;
		AddCq: ReceiverIndex + 1 + (objectMemory baseHeaderSize / objectMemory wordSize) R: SendNumArgsReg.
	loopHead :=
	cogit SubCq: objectMemory wordSize R: ClassReg.
	cogit CmpR: SPReg R: ClassReg.
	"If on a CISC there's a retpc for the trampoline call on top of stack; if on a RISC there isn't."
	exit := cogit backEnd hasLinkRegister
				ifTrue: [cogit JumpBelow: 0]
				ifFalse: [cogit JumpBelowOrEqual: 0].
	coInterpreter marryFrameCopiesTemps ifTrue:
		[cogit MoveMw: 0 r: ClassReg R: TempReg].
	cogit
		MoveR: TempReg Xwr: SendNumArgsReg R: ReceiverResultReg;
		AddCq: 1 R: SendNumArgsReg;
		Jump: loopHead.
	exit jmpTarget: cogit Label.

	cogit RetN: 0.
	
	jumpNeedScavenge jmpTarget: cogit Label.
	cogit backEnd saveAndRestoreLinkRegAround:
		[cogit
			CallRT: ceScheduleScavengeTrampoline
			registersToBeSavedMask: (cogit registerMaskFor: ReceiverResultReg and: SendNumArgsReg and: ClassReg)].
	cogit Jump: continuation.
	^0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> genGetActiveContextNumArgs: numArgs large: isLargeContext inBlock: isInBlock [
	"Get the active context into ReceiverResultReg, creating it if necessary."
	| routine |
	routine := isLargeContext
				ifFalse: [isInBlock caseOf: {
						[0]				-> [ceSmallActiveContextInMethodTrampoline].
						[InVanillaBlock]	-> [ceSmallActiveContextInBlockTrampoline].
						[InFullBlock]	-> [ceSmallActiveContextInFullBlockTrampoline] }]
				ifTrue: [isInBlock caseOf: {
						[0]				-> [ceLargeActiveContextInMethodTrampoline].
						[InVanillaBlock]	-> [ceLargeActiveContextInBlockTrampoline].
						[InFullBlock]	-> [ceLargeActiveContextInFullBlockTrampoline] }].
	cogit
		MoveCq: numArgs R: SendNumArgsReg;
		CallRT: routine.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetBits: mask ofFormatByteOf: sourceReg into: destReg [
	self flag: #endianness.
	cogit MoveMb: 3 r: sourceReg R: destReg.
	cogit AndCq: mask R: destReg.	"formatReg := self formatOfHeader: destReg"
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetClassIndexOfNonImm: sourceReg into: destReg [
	"Fetch the instance's class index into destReg."

	cogit MoveMw: 0 r: sourceReg R: destReg.
	cogit AndCq: objectMemory classIndexMask R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetClassObjectOf: instReg into: destReg scratchReg: scratchReg instRegIsReceiver: instRegIsReceiver [
	"Fetch the instance's class into destReg.  If the instance is not the receiver and is forwarded, follow forwarding."
	| jumpIsImm jumpNotForwarded loop |
	<var: #jumpIsImm type: #'AbstractInstruction *'>
	<var: #jumpNotForwarded type: #'AbstractInstruction *'>
	<var: #loop type: #'AbstractInstruction *'>
	(instReg = destReg or: [instReg = scratchReg or: [destReg = scratchReg]]) ifTrue:
		[^BadRegisterSet].
	loop := cogit MoveR: instReg R: scratchReg.
	cogit AndCq: objectMemory tagMask R: scratchReg.
	jumpIsImm := cogit JumpNonZero: 0.
	self flag: #endianness.
	"Get least significant half of header word in destReg"
	cogit MoveMw: 0 r: instReg R: scratchReg.
	"mask off class index"
	cogit AndCq: objectMemory classIndexMask R: scratchReg.
	instRegIsReceiver ifFalse:
		["if it is forwarded..."
		cogit CmpCq: objectMemory isForwardedObjectClassIndexPun R: scratchReg.
		jumpNotForwarded := cogit JumpNonZero: 0.
		"...follow the forwarding pointer and loop to fetch its classIndex"
		cogit MoveMw: objectMemory baseHeaderSize r: instReg R: instReg.
		cogit Jump: loop.
		jumpNotForwarded jmpTarget: cogit Label].
	jumpIsImm jmpTarget:
	(cogit MoveR: scratchReg R: destReg).
	scratchReg = TempReg
		ifTrue:
			[cogit PushR: instReg.
			 self genGetClassObjectOfClassIndex: destReg into: instReg scratchReg: TempReg.
			 cogit MoveR: instReg R: destReg.
			 cogit PopR: instReg]
		ifFalse:
			[self genGetClassObjectOfClassIndex: destReg into: scratchReg scratchReg: TempReg.
			 cogit MoveR: scratchReg R: destReg].
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetClassObjectOfClassIndex: instReg into: destReg scratchReg: scratchReg [
	"Fetch the class object whose index is in instReg into destReg.
	 It is non-obvious, but the Cogit assumes loading a class does not involve
	 a runtime call, so do not call classAtIndex:"
	self assert: instReg ~= destReg.
	self assert: instReg ~= scratchReg.
	self assert: destReg ~= scratchReg.
	cogit
		MoveR: instReg R: scratchReg;
		LogicalShiftRightCq: objectMemory classTableMajorIndexShift R: scratchReg;
		LogicalShiftLeftCq: objectMemory shiftForWord R: scratchReg.
	self assert: (self shouldAnnotateObjectReference: objectMemory classTableRootObj) not.
	(cogit backEnd isWithinMwOffsetRange: objectMemory classTableRootObj + objectMemory baseHeaderSize)
		ifTrue: [cogit MoveMw: objectMemory classTableRootObj + objectMemory baseHeaderSize r: scratchReg R: destReg]
		ifFalse: [cogit
					AddCq: objectMemory classTableRootObj R: scratchReg;
					MoveMw: objectMemory baseHeaderSize r: scratchReg R: destReg].
	cogit
		MoveR: instReg R: scratchReg;
		AndCq: objectMemory classTableMinorIndexMask R: scratchReg;
		AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: scratchReg;
		MoveXwr: scratchReg R: destReg R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetClassTagOf: instReg into: destReg scratchReg: scratchReg [
	^self genGetInlineCacheClassTagFrom: instReg into: destReg forEntry: true
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetCompactClassIndexNonImmOf: instReg into: destReg [
	"Fetch the instance's class index into destReg."
	^self genGetClassIndexOfNonImm: instReg into: destReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetDoubleValueOf: srcReg into: destFPReg [ 
	cogit MoveM64: objectMemory baseHeaderSize r: srcReg Rd: destFPReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetFormatOf: srcReg into: destReg [
	"Get the format field of the object in srcReg into destReg.
	 srcReg may equal destReg."
	^self genGetBits: objectMemory formatMask ofFormatByteOf: srcReg into: destReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetFormatOf: sourceReg into: destReg leastSignificantHalfOfBaseHeaderIntoScratch: scratchRegOrNone [
	"Get the format of the object in sourceReg into destReg.  If scratchRegOrNone
	 is not NoReg, load at least the least significant 32-bits (64-bits in 64-bits) of the
	 header word, which contains the format, into scratchRegOrNone."
	scratchRegOrNone = NoReg
		ifTrue:
			[self flag: #endianness.
			 cogit MoveMb: 3 r: sourceReg R: destReg]
		ifFalse:
			[cogit MoveMw: 0 r: sourceReg R: destReg.
			 cogit MoveR: destReg R: scratchRegOrNone. "destReg := (at least) least significant half of self baseHeader: receiver"
			 cogit LogicalShiftRightCq: objectMemory formatShift R: destReg].
	cogit AndCq: objectMemory formatMask R: destReg.	"formatReg := self formatOfHeader: destReg"
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> genGetIdentityHash: rcvrReg resultReg: resultReg [
	<var: #jumpSet type: #'AbstractInstruction *'>
	| jumpSet |
	"ReceiverResultReg is required for the trampoline. We force the allocation,
	 and we have two path to avoid conflicts in ReceiverResultReg."
	cogit voidReceiverResultRegContainsSelf. 
	resultReg = ReceiverResultReg 
		ifTrue: 
			[cogit ssTop popToReg: rcvrReg.
			 self genGetHashFieldNonImmOf: rcvrReg asSmallIntegerInto: resultReg.
			 cogit CmpCq: ConstZero R: resultReg.
			 jumpSet := cogit JumpNonZero: 0.
			 cogit MoveR: rcvrReg R: resultReg.
			 cogit CallRT: ceInlineNewHashTrampoline]
		ifFalse: 
			[cogit ssTop popToReg: ReceiverResultReg.
		 	 self genGetHashFieldNonImmOf: ReceiverResultReg asSmallIntegerInto: resultReg.
			 cogit CmpCq: ConstZero R: resultReg.
			 jumpSet := cogit JumpNonZero: 0.
			 cogit CallRT: ceInlineNewHashTrampoline.
			 cogit MoveR: ReceiverResultReg R: resultReg].
	jumpSet jmpTarget: cogit Label
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSpur >> genGetInstanceOfByteClass: classObj into: destReg initializingIf: initializeInstance numBytes: numBytes [
	"Create an instance of classObj and assign it to destReg, initializing the instance
	 if initializeInstance is true with 0 This is for inline primitives.
	 Assume there is sufficient space in new space to complete the operation."
	| classIndex numSlots byteFormat |
	classIndex := objectMemory rawHashBitsOf: classObj.
	self flag: #duplication. "Duplicated byteFormatForNumBytes: and numSlotsForBytes:, might be worth adding api"
	numSlots := numBytes + (objectMemory wordSize - 1) // objectMemory wordSize.
	byteFormat := objectMemory firstByteFormat + (8 - numBytes bitAnd: objectMemory wordSize - 1).
	self assert: classIndex ~= 0.
	self genGetUninitializedInstanceWithClassIndex: classIndex numSlots: numSlots format: byteFormat into: destReg.
	(initializeInstance and: [numBytes > 0]) ifTrue: 
		[self genStoreValue: 0 instance: destReg numSlots: numSlots].
	^0
	
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSpur >> genGetInstanceOfPointerClass: classObj into: destReg initializingIf: initializeInstance numVariableSlots: varSlots [
	"Create an instance of classObj and assign it to destReg, initializing the instance
	 if initializeInstance is true with nil This is for inline primitives.
	 Assume there is sufficient space in new space to complete the operation."
	| classIndex classFormat totalNumSlots fixedSlots |
	classIndex := objectMemory rawHashBitsOf: classObj.
	classFormat := objectMemory formatOfClass: classObj.
	fixedSlots := objectMemory fixedFieldsOfClassFormat: classFormat.
	totalNumSlots := varSlots + fixedSlots.
	self assert: classIndex ~= 0.
	self genGetUninitializedInstanceWithClassIndex: classIndex numSlots: totalNumSlots format: (objectMemory instSpecOfClassFormat: classFormat) into: destReg.
	(initializeInstance and: [totalNumSlots > 0]) ifTrue: 
		[self genStoreValue: objectMemory nilObject instance: destReg numSlots: totalNumSlots].
	^0
	
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetNumBytesOf: srcReg into: destReg [
	"Get the size in byte-sized slots of the object in srcReg into destReg.
	 srcReg may equal destReg.
	 destReg <- numSlots << self shiftForWord - (fmt bitAnd: 3).
	 Assumes the object in srcReg has a byte format, i.e. 16 to 23 or 24 to 31 "
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetNumSlotsOf: srcReg into: destReg [
	"Get the size in word-sized slots of the object in srcReg into destReg.
	 srcReg may equal destReg."
	<var: #jmp type: #'AbstractInstruction *'>
	| jmp |
	self assert: srcReg ~= destReg.
	self genGetRawSlotSizeOfNonImm: srcReg into: destReg.
	cogit CmpCq: objectMemory numSlotsMask R: destReg.
	jmp := cogit JumpLess: 0.
	self genGetOverflowSlotsOf: srcReg into: destReg.
	jmp jmpTarget: cogit Label.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetOverflowSlotsOf: srcReg into: destReg [
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genGetRawSlotSizeOfNonImm: sourceReg into: destReg [
	"The raw numSlots field is the most significant byte of the 64-bit header word.
	 MoveMbrR zero-extends."
	cogit backEnd byteReadsZeroExtend ifFalse:
		[cogit MoveCq: 0 R: destReg].
	cogit MoveMb: 7 r: sourceReg R: destReg.
	^0
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSpur >> genGetUninitializedInstanceWithClassIndex: classIndex numSlots: numSlots format: format into: destReg [
	"Write in destReg the pointer to the object (adjusted based on header size)
	Can deal with large header but not with with old space allocation (max allocation size)"
	| overflowHeader header lowNumSlots |
	<var: #overflowHeader type: #usqLong>
	numSlots >= objectMemory fixedFieldsOfClassFormatMask ifTrue: [^UnimplementedOperation].
	cogit MoveAw: objectMemory freeStartAddress R: destReg.
	numSlots >= objectMemory numSlotsMask
		ifTrue: 
			[overflowHeader := numSlots + (objectMemory numSlotsMask << objectMemory numSlotsFullShift).
			 self genStoreHeader: overflowHeader intoNewInstance: destReg using: TempReg.
			 cogit AddCq: objectMemory baseHeaderSize R: destReg. "Allow to store base header at correct place and to use smallObjectBytes in the rest of the method"
			 lowNumSlots := objectMemory numSlotsMask]
		ifFalse: 
			[lowNumSlots := numSlots].	
	header := objectMemory
					headerForSlots: lowNumSlots
					format: format
					classIndex: classIndex.
	self genStoreHeader: header intoNewInstance: destReg using: TempReg.
	cogit
		LoadEffectiveAddressMw: (objectMemory objectBytesForSlots: numSlots) r: destReg R: TempReg;
		MoveR: TempReg Aw: objectMemory freeStartAddress.

	
]

{ #category : #'mapped inlined primitive support' }
CogObjectRepresentationForSpur >> genIfRequiredCheckRememberedBitOf: rr scratch: scratchReg [
	CheckRememberedInTrampoline ifFalse: 
		[^self genCheckRememberedBitOf: rr scratch: scratchReg]
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genInlinedIdenticalOrNotIfGuts: orNot [
	<inline: true>
	^ cogit genForwardersInlinedIdenticalOrNotIf: orNot
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpBaseHeaderImmutable: baseHeaderReg [
	"baseHeader holds at least the least significant 32 bits of the object"
	<returnTypeC: #'AbstractInstruction *'>
	<option: #IMMUTABILITY>
	<inline: true>
	cogit TstCq: objectMemory immutableBitMask R: baseHeaderReg.
	^ cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpBaseHeaderMutable: baseHeaderReg [
	"baseHeader holds at least the least significant 32 bits of the object"
	<returnTypeC: #'AbstractInstruction *'>
	<option: #IMMUTABILITY>
	<inline: true>
	cogit TstCq: objectMemory immutableBitMask R: baseHeaderReg.
	^ cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpCharacterInScratchReg: reg [ 
	cogit AndCq: objectMemory tagMask R: reg.
	cogit CmpCq: objectMemory characterTag R: reg.
	^cogit JumpZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpImmediate: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit TstCq: objectMemory tagMask R: aRegister.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpImmutable: sourceReg scratchReg: scratchReg [
	<returnTypeC: #'AbstractInstruction *'>
	<option: #IMMUTABILITY>
	cogit MoveMw: 0 r: sourceReg R: scratchReg. 
	^ self genJumpBaseHeaderImmutable: scratchReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpInOldSpace: reg [
	"Jump if reg is old."
	<inline: true>
	^cogit
		CmpCq: objectMemory storeCheckBoundary R: reg; "N.B. FLAGS := destReg - scratchReg"
		JumpAboveOrEqual: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpMutable: sourceReg scratchReg: scratchReg [
	<returnTypeC: #'AbstractInstruction *'>
	<option: #IMMUTABILITY>
	cogit MoveMw: 0 r: sourceReg R: scratchReg. 
	^ self genJumpBaseHeaderMutable: scratchReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpNotCharacterInScratchReg: reg [ 
	cogit AndCq: objectMemory tagMask R: reg.
	cogit CmpCq: objectMemory characterTag R: reg.
	^cogit JumpNonZero: 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genJumpNotImmediate: aRegister [
	<returnTypeC: #'AbstractInstruction *'>
	cogit TstCq: objectMemory tagMask R: aRegister.
	^cogit JumpZero: 0
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> genNewArrayOfSize: size initialized: initialized [
	"Generate a call to code that allocates a new Array of size.
	 The Array should be initialized with nils iff initialized is true.
	 The size arg is passed in SendNumArgsReg, the result
	 must come back in ReceiverResultReg."
	| header skip |
	<var: #skip type: #'AbstractInstruction *'>
	self assert: size < objectMemory numSlotsMask.
	header := objectMemory
					headerForSlots: size
					format: objectMemory arrayFormat
					classIndex: ClassArrayCompactIndex.
	cogit MoveAw: objectMemory freeStartAddress R: ReceiverResultReg.
	self genStoreHeader: header intoNewInstance: ReceiverResultReg using: TempReg.
	(initialized and: [size > 0]) ifTrue:
		[cogit genMoveConstant: objectMemory nilObject R: TempReg.
		 0 to: size - 1 do:
			[:i| cogit MoveR: TempReg
					Mw: i * objectMemory wordSize + objectMemory baseHeaderSize
					r: ReceiverResultReg]].
	cogit
		LoadEffectiveAddressMw: (objectMemory smallObjectBytesForSlots: size) r: ReceiverResultReg R: TempReg;
		MoveR: TempReg Aw: objectMemory freeStartAddress;
		CmpCq: objectMemory getScavengeThreshold R: TempReg.
	skip := cogit JumpBelow: 0.
	cogit CallRT: ceScheduleScavengeTrampoline.
	skip jmpTarget: cogit Label.
	^0
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genNewHashTrampoline: saveRegs called: name [
	"In non sista VM this is used only from the identityHash primitive, hence only the result of the trampoline, the hash, should be in ReceiverResultReg, other registers can just be ignored.
	In the sista VM, the inlined hash operation requires registers to be saved"
	<inline: true>
	^cogit
		genTrampolineFor: #ceNewHashOf:
		called: name
		numArgs: 1
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		arg: nil
		regsToSave: (saveRegs
						ifTrue: [CallerSavedRegisterMask bitClear: (cogit registerMaskFor: ReceiverResultReg)]
						ifFalse: [cogit emptyRegisterMask])
		pushLinkReg: true
		resultReg: ReceiverResultReg
		appendOpcodes: false
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> genNoPopCreateClosureAt: bcpc numArgs: numArgs numCopied: numCopied contextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock [
	"Create a closure with the given startpc, numArgs and numCopied
	 within a context with ctxtNumArgs, large if isLargeCtxt that is in a
	 block if isInBlock.  Do /not/ initialize the copied values."
	| numSlots byteSize header skip |
	<var: #skip type: #'AbstractInstruction *'>

	"First get thisContext into ReceiverResultRega and thence in ClassReg."
	self genGetActiveContextNumArgs: ctxtNumArgs large: isLargeCtxt inBlock: isInBlock.
	cogit MoveR: ReceiverResultReg R: ClassReg.

	numSlots := ClosureFirstCopiedValueIndex + numCopied.
	byteSize := objectMemory smallObjectBytesForSlots: numSlots.
	header := objectMemory
					headerForSlots: numSlots
					format: objectMemory indexablePointersFormat
					classIndex: ClassBlockClosureCompactIndex.
	cogit MoveAw: objectMemory freeStartAddress R: ReceiverResultReg.
	self genStoreHeader: header intoNewInstance: ReceiverResultReg using: TempReg.
	cogit
		LoadEffectiveAddressMw: byteSize r: ReceiverResultReg R: TempReg;
		MoveR: TempReg Aw: objectMemory freeStartAddress;
		CmpCq: objectMemory getScavengeThreshold R: TempReg.
	skip := cogit JumpBelow: 0.
	cogit CallRT: ceScheduleScavengeTrampoline.
	skip jmpTarget: cogit Label.

	cogit
		MoveR: ClassReg Mw: ClosureOuterContextIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize r: ReceiverResultReg;
		MoveCq: (objectMemory integerObjectOf: bcpc) R: TempReg;
		MoveR: TempReg Mw: ClosureStartPCIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize r: ReceiverResultReg;
		MoveCq: (objectMemory integerObjectOf: numArgs) R: TempReg;
		MoveR: TempReg Mw: ClosureNumArgsIndex * objectMemory bytesPerOop + objectMemory baseHeaderSize r: ReceiverResultReg.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveAsCharacter [
	| reg jumpNotInt jumpOutOfRange |
	<var: 'jumpNotInt' type: #'AbstractInstruction *'>
	<var: 'jumpOutOfRange' type: #'AbstractInstruction *'>
	cogit methodNumArgs = 0
		ifTrue: [reg := ReceiverResultReg]
		ifFalse:
			[cogit methodNumArgs > 1 ifTrue:
				[^UnimplementedPrimitive].
			 reg := Arg0Reg.
			 cogit genLoadArgAtDepth: 0 into: Arg0Reg.
			 jumpNotInt := self genJumpNotSmallInteger: reg scratchReg: TempReg].
	cogit MoveR: reg R: TempReg.
	self genConvertSmallIntegerToIntegerInReg: TempReg.
	jumpOutOfRange := self jumpNotCharacterUnsignedValueInRegister: TempReg.
	self genConvertSmallIntegerToCharacterInReg: reg.
	reg ~= ReceiverResultReg ifTrue:
		[cogit MoveR: reg R: ReceiverResultReg].
	cogit genPrimReturn.
	jumpOutOfRange jmpTarget: cogit Label.
	reg ~= ReceiverResultReg ifTrue:
		[jumpNotInt jmpTarget: jumpOutOfRange getJmpTarget].
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveAt [
	"Generate primitive 60, at: with unsigned access for pure bits classes."
	^self genPrimitiveAtSigned: false
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveAtPut [
	"Generate primitive 61, at:put: with unsigned access for pure bits classes."
	^self genPrimitiveAtPutSigned: false
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveIdenticalOrNotIf: orNot [
	| jumpCmp comp |
	<var: #jumpCmp type: #'AbstractInstruction *'>
	<var: #comp type: #'AbstractInstruction *'>
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	comp := cogit CmpR: Arg0Reg R: ReceiverResultReg.
	orNot
		ifTrue: 
			[ jumpCmp := cogit JumpZero: 0.
			self genEnsureOopInRegNotForwarded: Arg0Reg scratchReg: TempReg jumpBackTo: comp ]
		ifFalse: 
			[ jumpCmp := cogit JumpNonZero: 0 ].
	cogit genMoveTrueR: ReceiverResultReg.
	cogit genPrimReturn.
	jumpCmp jmpTarget: cogit Label.
	orNot ifFalse: 
		[ self genEnsureOopInRegNotForwarded: Arg0Reg scratchReg: TempReg jumpBackTo: comp ].
	cogit genMoveFalseR: ReceiverResultReg.
	cogit genPrimReturn.
	^UnfailingPrimitive

]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveIdentityHash [
	self subclassResponsibility
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveImmediateAsInteger [
	self subclassResponsibility
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveIntegerAt [
	"Generate primitive 164, at: with signed access for pure bits classes."
	^self genPrimitiveAtSigned: true
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveIntegerAtPut [
	"Generate primitive 165, at:put: with signed access for pure bits classes."
	^self genPrimitiveAtPutSigned: true
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoad: accessedElementByteSize fromBytesWith: aBlock [
	<inline: true>
	^ self genPrimitiveLoad: accessedElementByteSize fromBytesWith: aBlock needsToTrap: false
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoad: accessedElementByteSize fromBytesWith: aBlock needsToTrap: needsToTrap [
	<inline: true>
	| nSlotsOrBytesReg jumpBadIndex formatReg jumpIsPointers jumpOutOfBounds jumpSmaller jumpImmediate |
	nSlotsOrBytesReg := ClassReg.
	
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit MoveR: Arg0Reg R: Arg1Reg.

	jumpImmediate := self genJumpImmediate: ReceiverResultReg.
	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg1Reg.
	
	self genGetFormatOf: ReceiverResultReg
		into: (formatReg := SendNumArgsReg)
		leastSignificantHalfOfBaseHeaderIntoScratch: TempReg.

	self genGetNumSlotsOf: ReceiverResultReg into: nSlotsOrBytesReg.
	cogit CmpCq: objectMemory sixtyFourBitIndexableFormat R: formatReg.
	jumpIsPointers := cogit JumpBelow: 0.
	
	self genConvertDataFormat: formatReg numSlots: nSlotsOrBytesReg intoBytes: nSlotsOrBytesReg.
	
	cogit CmpCq: accessedElementByteSize R: nSlotsOrBytesReg.
	jumpSmaller := cogit JumpBelow: 0.

	"Subtract the accessed element count to make the register into an upper bound."
	accessedElementByteSize > 1 ifTrue: [ 
		cogit SubCq: accessedElementByteSize - 1 R: nSlotsOrBytesReg.
	].
	cogit CmpR: nSlotsOrBytesReg R: Arg1Reg.
	jumpOutOfBounds := cogit JumpAboveOrEqual: 0.
	
	"The index is in bounds, so compute the actual element pointer."
	cogit AddR: ReceiverResultReg R: Arg1Reg.
	cogit AddCq: objectMemory baseHeaderSize R: Arg1Reg.
	aBlock value: Arg1Reg.
	
	jumpImmediate jmpTarget:
	(jumpBadIndex jmpTarget:
	(jumpIsPointers jmpTarget:
	(jumpSmaller jmpTarget:
	(jumpOutOfBounds jmpTarget: cogit Label)))).
	^ needsToTrap ifTrue: [0] ifFalse: [CompletePrimitive]
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadBoolean8FromBytes [
	^ self genPrimitiveLoad: 1 fromBytesWith: [ :sourcePointer |
		| trueResultJump inst |
		cogit MoveMb: 0 r: sourcePointer R: ClassReg.
		cogit TstCq: 16rff R: ClassReg.
		trueResultJump := cogit JumpNonZero: 0.

		"False result"
		inst := cogit MoveCw: objectMemory falseObject R: ReceiverResultReg.
		cogit annotate: inst objRef: objectMemory falseObject.	
		cogit genPrimReturn.
		
		"True result"
		inst := trueResultJump jmpTarget: (cogit MoveCw: objectMemory trueObject R: ReceiverResultReg).
		cogit annotate: inst objRef: objectMemory trueObject.	
		cogit genPrimReturn.
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadBoolean8FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		| trueResultJump inst |
		cogit MoveMb: 0 r: sourcePointer R: ClassReg.
		cogit TstCq: 16rff R: ClassReg.
		trueResultJump := cogit JumpNonZero: 0.

		"False result"
		inst := cogit MoveCw: objectMemory falseObject R: ReceiverResultReg.
		cogit annotate: inst objRef: objectMemory falseObject.	
		cogit genPrimReturn.
		
		"True result"
		inst := trueResultJump jmpTarget: (cogit MoveCw: objectMemory trueObject R: ReceiverResultReg).
		cogit annotate: inst objRef: objectMemory trueObject.	
		cogit genPrimReturn.
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadChar16FromBytes [
	^ self genPrimitiveLoad: 2 fromBytesWith: [ :sourcePointer |
		cogit MoveM16: 0 r: sourcePointer R: ReceiverResultReg.
		cogit ZeroExtend16R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToCharacterInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadChar16FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		cogit MoveM16: 0 r: sourcePointer R: ReceiverResultReg.
		cogit ZeroExtend16R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToCharacterInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadChar32FromBytes [
	^ self genPrimitiveLoad: 4 fromBytesWith: [ :sourcePointer |
		BytesPerWord  = 4 ifTrue: [ 
			cogit MoveMw: 0 r: sourcePointer R: ReceiverResultReg.
		] ifFalse: [ 
			cogit MoveM32: 0 r: sourcePointer R: ReceiverResultReg.
			cogit ZeroExtend32R: ReceiverResultReg R: ReceiverResultReg.
		].
	
		self genConvertIntegerToCharacterInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadChar32FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		BytesPerWord  = 4 ifTrue: [ 
			cogit MoveMw: 0 r: sourcePointer R: ReceiverResultReg.
		] ifFalse: [ 
			cogit MoveM32: 0 r: sourcePointer R: ReceiverResultReg.
			cogit ZeroExtend32R: ReceiverResultReg R: ReceiverResultReg.
		].
	
		self genConvertIntegerToCharacterInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadChar8FromBytes [
	^ self genPrimitiveLoad: 1 fromBytesWith: [ :sourcePointer |
		cogit MoveMb: 0 r: sourcePointer R: ReceiverResultReg .
		cogit backEnd byteReadsZeroExtend ifFalse: [
			cogit ZeroExtend8R: ReceiverResultReg R: ReceiverResultReg
		].
	
		self genConvertIntegerToCharacterInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadChar8FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		cogit MoveMb: 0 r: sourcePointer R: ReceiverResultReg .
		cogit backEnd byteReadsZeroExtend ifFalse: [
			cogit ZeroExtend8R: ReceiverResultReg R: ReceiverResultReg
		].
	
		self genConvertIntegerToCharacterInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadFloat32FromBytes [
	^ self genPrimitiveLoad: 4 fromBytesWith: [ :sourcePointer |
		| jumpFailAlloc |
		cogit MoveM32: 0 r: sourcePointer Rs: DPFPReg0.
		cogit ConvertRs: DPFPReg0 Rd: DPFPReg0.

		jumpFailAlloc := self
						genAllocFloatValue: DPFPReg0
						into: SendNumArgsReg
						scratchReg: ClassReg
						scratchReg: TempReg.
		cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
		cogit genPrimReturn.
		
		jumpFailAlloc jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadFloat32FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		| jumpFailAlloc |
		cogit MoveM32: 0 r: sourcePointer Rs: DPFPReg0.
		cogit ConvertRs: DPFPReg0 Rd: DPFPReg0.

		jumpFailAlloc := self
						genAllocFloatValue: DPFPReg0
						into: SendNumArgsReg
						scratchReg: ClassReg
						scratchReg: TempReg.
		cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
		cogit genPrimReturn.
		
		jumpFailAlloc jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadFloat64FromBytes [
	^ self genPrimitiveLoad: 8 fromBytesWith: [ :sourcePointer |
		| jumpFailAlloc |
		cogit MoveM64: 0 r: sourcePointer Rd: DPFPReg0.
		jumpFailAlloc := self
						genAllocFloatValue: DPFPReg0
						into: SendNumArgsReg
						scratchReg: ClassReg
						scratchReg: TempReg.
		cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
		cogit genPrimReturn.
		
		jumpFailAlloc jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadFloat64FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		| jumpFailAlloc |
		cogit MoveM64: 0 r: sourcePointer Rd: DPFPReg0.
		jumpFailAlloc := self
						genAllocFloatValue: DPFPReg0
						into: SendNumArgsReg
						scratchReg: ClassReg
						scratchReg: TempReg.
		cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
		cogit genPrimReturn.
		
		jumpFailAlloc jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadFromExternalAddressWith: aBlock [
	<inline: true>
	^ self genPrimitiveLoadFromExternalAddressWith: aBlock needsToTrap: false
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadFromExternalAddressWith: aBlock needsToTrap: needsToTrap [
	<inline: true>
	| jumpBadIndex jumpImmediate jumpNonExternalAddress |

	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	cogit MoveR: Arg0Reg R: Arg1Reg.

	jumpImmediate := self genJumpImmediate: ReceiverResultReg.
	self genGetCompactClassIndexNonImmOf: ReceiverResultReg into: TempReg.
	cogit CmpCq: objectMemory classExternalAddressIndex R: TempReg.
	jumpNonExternalAddress := cogit JumpNonZero: 0.
	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg1Reg.
	
	"Fetch the pointer from the external address."
	cogit MoveMw: objectMemory baseHeaderSize r: ReceiverResultReg R: TempReg.

	"Add the pointer to the offfset"
	cogit AddR: TempReg R: Arg1Reg.
	aBlock value: Arg1Reg.
	
	jumpImmediate jmpTarget:
	(jumpBadIndex jmpTarget:
	(jumpNonExternalAddress jmpTarget: cogit Label)).
	^ needsToTrap ifTrue: [0] ifFalse: [CompletePrimitive]
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadInt16FromBytes [
	^ self genPrimitiveLoad: 2 fromBytesWith: [ :sourcePointer |
		cogit MoveM16: 0 r: sourcePointer R: ReceiverResultReg.
		cogit SignExtend16R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadInt16FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		cogit MoveM16: 0 r: sourcePointer R: ReceiverResultReg.
		cogit SignExtend16R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadInt8FromBytes [
	^ self genPrimitiveLoad: 1 fromBytesWith: [ :sourcePointer |
		cogit MoveMb: 0 r: sourcePointer R: ReceiverResultReg.
		cogit SignExtend8R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadInt8FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		cogit MoveMb: 0 r: sourcePointer R: ReceiverResultReg.
		cogit SignExtend8R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadPointerFromBytes [
	^ self genPrimitiveLoad: BytesPerWord fromBytesWith: [ :sourcePointer |
		| jumpFailAlloc |
		cogit MoveMw: 0 r: sourcePointer R: ClassReg.
		jumpFailAlloc := self genAllocExternalAddressValue: ClassReg into: SendNumArgsReg scratchReg: Extra0Reg scratchReg: TempReg.
			 cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
			 cogit genPrimReturn.
		cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
		cogit genPrimReturn.
		jumpFailAlloc jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadPointerFromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		| jumpFailAlloc |
		cogit MoveMw: 0 r: sourcePointer R: ClassReg.
		jumpFailAlloc := self genAllocExternalAddressValue: ClassReg into: SendNumArgsReg scratchReg: Extra0Reg scratchReg: TempReg.
			 cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
			 cogit genPrimReturn.
		cogit MoveR: SendNumArgsReg R: ReceiverResultReg.
		cogit genPrimReturn.
		jumpFailAlloc jmpTarget: cogit Label
	] needsToTrap: true.
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadUInt16FromBytes [
	^ self genPrimitiveLoad: 2 fromBytesWith: [ :sourcePointer |
		cogit MoveM16: 0 r: sourcePointer R: ReceiverResultReg.
		cogit ZeroExtend16R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadUInt16FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		cogit MoveM16: 0 r: sourcePointer R: ReceiverResultReg.
		cogit ZeroExtend16R: ReceiverResultReg R: ReceiverResultReg.
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadUInt8FromBytes [
	^ self genPrimitiveLoad: 1 fromBytesWith: [ :sourcePointer |
		cogit MoveMb: 0 r: sourcePointer R: ReceiverResultReg .
		cogit backEnd byteReadsZeroExtend ifFalse: [
			cogit ZeroExtend8R: ReceiverResultReg R: ReceiverResultReg
		].
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveLoadUInt8FromExternalAddress [
	^ self genPrimitiveLoadFromExternalAddressWith: [ :sourcePointer |
		cogit MoveMb: 0 r: sourcePointer R: ReceiverResultReg .
		cogit backEnd byteReadsZeroExtend ifFalse: [
			cogit ZeroExtend8R: ReceiverResultReg R: ReceiverResultReg
		].
	
		self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
		cogit genPrimReturn
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveObjectAt [
	| headerReg jumpBadIndex jumpBounds jumpNotHeaderIndex |
	<var: #jumpBounds type: #'AbstractInstruction *'>
	<var: #jumpBadIndex type: #'AbstractInstruction *'>
	<var: #jumpNotHeaderIndex type: #'AbstractInstruction *'>
	cogit genLoadArgAtDepth: 0 into: Arg0Reg.
	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genGetMethodHeaderOf: ReceiverResultReg into: (headerReg := Arg1Reg) scratch: TempReg.
	cogit CmpCq: (objectMemory integerObjectOf: 1) R: Arg0Reg.
	jumpNotHeaderIndex := cogit JumpNonZero: 0.
	cogit
		MoveR: headerReg R: ReceiverResultReg;
		genPrimReturn.
	jumpNotHeaderIndex jmpTarget: (cogit
		AndCq: (objectMemory integerObjectOf: coInterpreter alternateHeaderNumLiteralsMask) R: headerReg).
	cogit
		SubCq: (objectMemory integerObjectOf: 1) - objectMemory smallIntegerTag R: Arg0Reg;
		CmpR: headerReg R: Arg0Reg.
	jumpBounds := cogit JumpAbove: 0.

	self genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	cogit
		AddCq: objectMemory baseHeaderSize >> objectMemory shiftForWord R: Arg0Reg;
		MoveXwr: Arg0Reg R: ReceiverResultReg R: ReceiverResultReg;
		genPrimReturn.

	jumpBounds jmpTarget: (cogit
		AddCq: (objectMemory integerObjectOf: 1) - objectMemory smallIntegerTag R: Arg0Reg).
	jumpBadIndex jmpTarget: cogit Label.
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveSize [
	| jumpImm jumpNotIndexable jumpIsContext |
	"c.f. StackInterpreter>>stSizeOf: lengthOf:baseHeader:format: fixedFieldsOf:format:length:"
	<var: #jumpImm type: #'AbstractInstruction *'>
	<var: #jumpIsContext type: #'AbstractInstruction *'>
	<var: #jumpNotIndexable type: #'AbstractInstruction *'>
	jumpImm := self genJumpImmediate: ReceiverResultReg.
	self
		genGetSizeOf: ReceiverResultReg
		into: ClassReg
		formatReg: SendNumArgsReg
		scratchReg: TempReg
		abortJumpsInto: [:jnx :jic| jumpNotIndexable := jnx. jumpIsContext := jic].
	self genConvertIntegerToSmallIntegerInReg: ClassReg.
	cogit MoveR: ClassReg R: ReceiverResultReg.
	cogit genPrimReturn.
	jumpImm jmpTarget: (jumpNotIndexable jmpTarget: (jumpIsContext jmpTarget: cogit Label)).
	^CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStore: accessedElementByteSize intoBytesWith: aBlock [
	<inline: true>
	^ self genPrimitiveStore: accessedElementByteSize intoBytesWith: aBlock needsToTrap: false
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStore: accessedElementByteSize intoBytesWith: aBlock needsToTrap: needsToTrap [
	<inline: true>
	| nSlotsOrBytesReg jumpBadIndex formatReg jumpIsPointers jumpOutOfBounds jumpSmaller jumpImmediate destPointerRegister |
	nSlotsOrBytesReg := ClassReg.
	destPointerRegister := ClassReg.

	cogit genLoadArgAtDepth: 1 into: Arg0Reg.
	cogit genLoadArgAtDepth: 0 into: Arg1Reg.
	
	jumpImmediate := self genJumpImmediate: ReceiverResultReg.
	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	
	self genGetFormatOf: ReceiverResultReg
		into: (formatReg := SendNumArgsReg)
		leastSignificantHalfOfBaseHeaderIntoScratch: TempReg.

	self genGetNumSlotsOf: ReceiverResultReg into: nSlotsOrBytesReg.
	cogit CmpCq: objectMemory sixtyFourBitIndexableFormat R: formatReg.
	jumpIsPointers := cogit JumpBelow: 0.
	
	self genConvertDataFormat: formatReg numSlots: nSlotsOrBytesReg intoBytes: nSlotsOrBytesReg.
	
	cogit CmpCq: accessedElementByteSize R: nSlotsOrBytesReg.
	jumpSmaller := cogit JumpBelow: 0.

	"Subtract the accessed element count to make the register into an upper bound."
	accessedElementByteSize > 1 ifTrue: [ 
		cogit SubCq: accessedElementByteSize - 1 R: nSlotsOrBytesReg.
	].
	cogit CmpR: nSlotsOrBytesReg R: Arg0Reg.
	jumpOutOfBounds := cogit JumpAboveOrEqual: 0.
	
	"The index is in bounds, so compute the actual element pointer."
	cogit MoveR: Arg0Reg R: destPointerRegister.
	cogit AddR: ReceiverResultReg R: ClassReg.
	cogit AddCq: objectMemory baseHeaderSize R: ClassReg.
	aBlock value: destPointerRegister value: Arg1Reg.
	
	jumpIsPointers jmpTarget:
	(jumpSmaller jmpTarget:
	(jumpOutOfBounds jmpTarget: cogit Label)).

	"Restore the Arg0 into an oop."
	self genConvertIntegerToSmallIntegerInReg: Arg0Reg.
	
	jumpBadIndex jmpTarget: (jumpImmediate jmpTarget: cogit Label).
	^ needsToTrap ifTrue: [0] ifFalse: [CompletePrimitive]
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreBoolean8IntoBytes [
	^ self genPrimitiveStore: 1 intoBytesWith: [ :destPointer :valueOop |
		| jumpNotTrueObject jumpNotBooleanObject |
		cogit annotate: (cogit CmpCw: objectMemory trueObject R: valueOop) objRef: objectMemory trueObject.
		jumpNotTrueObject := cogit JumpNonZero: 0.

		"True object"
		cogit MoveR: valueOop R: ReceiverResultReg.
		cogit MoveCq: 1 R: TempReg.
		cogit MoveR: TempReg M8: 0 r: destPointer.
		cogit genPrimReturn.

		"False or not a boolean"
		jumpNotTrueObject jmpTarget: (cogit annotate: (cogit CmpCw: objectMemory falseObject R: valueOop) objRef: objectMemory falseObject).
		jumpNotBooleanObject := cogit JumpNonZero: 0.

		"False"
		cogit MoveR: valueOop R: ReceiverResultReg.
		cogit MoveCq: 0 R: TempReg.
		cogit MoveR: TempReg M8: 0 r: destPointer.
		cogit genPrimReturn.
		
		"Not boolean. Error."
		(jumpNotBooleanObject jmpTarget: cogit Label).
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreBoolean8IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNotTrueObject jumpNotBooleanObject |
		cogit annotate: (cogit CmpCw: objectMemory trueObject R: valueOop) objRef: objectMemory trueObject.
		jumpNotTrueObject := cogit JumpNonZero: 0.

		"True object"
		cogit MoveR: valueOop R: ReceiverResultReg.
		cogit MoveCq: 1 R: TempReg.
		cogit MoveR: TempReg M8: 0 r: destPointer.
		cogit genPrimReturn.

		"False or not a boolean"
		jumpNotTrueObject jmpTarget: (cogit annotate: (cogit CmpCw: objectMemory falseObject R: valueOop) objRef: objectMemory falseObject).
		jumpNotBooleanObject := cogit JumpNonZero: 0.

		"False"
		cogit MoveR: valueOop R: ReceiverResultReg.
		cogit MoveCq: 0 R: TempReg.
		cogit MoveR: TempReg M8: 0 r: destPointer.
		cogit genPrimReturn.
		
		"Not boolean. Error."
		(jumpNotBooleanObject jmpTarget: cogit Label).
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreChar16IntoBytes [
	^ self genPrimitiveStore: 2 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonCharacter |
		cogit MoveR: valueOop R: TempReg.
		jumpNonCharacter := self genJumpNotCharacterInScratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertCharacterToCodeInReg: valueOop.
		cogit MoveR: valueOop M16: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonCharacter jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreChar16IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonCharacter |
		cogit MoveR: valueOop R: TempReg.
		jumpNonCharacter := self genJumpNotCharacterInScratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertCharacterToCodeInReg: valueOop.
		cogit MoveR: valueOop M16: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonCharacter jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreChar32IntoBytes [
	^ self genPrimitiveStore: 4 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonCharacter |
		cogit MoveR: valueOop R: TempReg.
		jumpNonCharacter := self genJumpNotCharacterInScratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertCharacterToCodeInReg: valueOop.
		cogit MoveR: valueOop M32: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonCharacter jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreChar32IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonCharacter |
		cogit MoveR: valueOop R: TempReg.
		jumpNonCharacter := self genJumpNotCharacterInScratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertCharacterToCodeInReg: valueOop.
		cogit MoveR: valueOop M32: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonCharacter jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreChar8IntoBytes [
	^ self genPrimitiveStore: 1 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonCharacter |
		cogit MoveR: valueOop R: TempReg.
		jumpNonCharacter := self genJumpNotCharacterInScratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertCharacterToCodeInReg: valueOop.
		cogit MoveR: valueOop M8: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonCharacter jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreChar8IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonCharacter |
		cogit MoveR: valueOop R: TempReg.
		jumpNonCharacter := self genJumpNotCharacterInScratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertCharacterToCodeInReg: valueOop.
		cogit MoveR: valueOop M8: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonCharacter jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreFloat32IntoBytes [
	^ self genPrimitiveStore: 4 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonFloat |
		jumpNonFloat := self genBoxedOrSmallFloat: valueOop scratchReg: TempReg into: DPFPReg0.
		cogit ConvertRd: DPFPReg0 Rs: DPFPReg0.
		cogit MoveRs: DPFPReg0 M32: 0 r: destPointer.

		cogit MoveR: valueOop R: ReceiverResultReg.
		cogit genPrimReturn.
		
		jumpNonFloat jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreFloat32IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonFloat |
		jumpNonFloat := self genBoxedOrSmallFloat: valueOop scratchReg: TempReg into: DPFPReg0.
		cogit ConvertRd: DPFPReg0 Rs: DPFPReg0.
		cogit MoveRs: DPFPReg0 M32: 0 r: destPointer.

		cogit MoveR: valueOop R: ReceiverResultReg.
		cogit genPrimReturn.
		
		jumpNonFloat jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreFloat64IntoBytes [
	^ self genPrimitiveStore: 8 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonFloat |
		jumpNonFloat := self genBoxedOrSmallFloat: valueOop scratchReg: TempReg into: DPFPReg0.
		cogit MoveRd: DPFPReg0 M64: 0 r: destPointer.

		cogit MoveR: valueOop R: ReceiverResultReg.
		cogit genPrimReturn.
		
		jumpNonFloat jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreFloat64IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonFloat |
		jumpNonFloat := self genBoxedOrSmallFloat: valueOop scratchReg: TempReg into: DPFPReg0.
		cogit MoveRd: DPFPReg0 M64: 0 r: destPointer.

		cogit MoveR: valueOop R: ReceiverResultReg.
		cogit genPrimReturn.
		
		jumpNonFloat jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreInt16IntoBytes [
	^ self genPrimitiveStore: 2 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M16: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreInt16IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M16: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreInt8IntoBytes [
	^ self genPrimitiveStore: 1 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M8: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreInt8IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M8: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: cogit Label
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreIntoExternalAddressWith: aBlock [
	<inline: true>
	^ self genPrimitiveStoreIntoExternalAddressWith: aBlock needsToTrap: false
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreIntoExternalAddressWith: aBlock needsToTrap: needsToTrap [
	<inline: true>
	| jumpBadIndex jumpNonExternalAddress jumpImmediate destPointerRegister |
	destPointerRegister := ClassReg.

	cogit genLoadArgAtDepth: 1 into: Arg0Reg.
	cogit genLoadArgAtDepth: 0 into: Arg1Reg.
	
	jumpImmediate := self genJumpImmediate: ReceiverResultReg.
	self genGetCompactClassIndexNonImmOf: ReceiverResultReg into: TempReg.
	cogit CmpCq: objectMemory classExternalAddressIndex R: TempReg.
	jumpNonExternalAddress := cogit JumpNonZero: 0.
	jumpBadIndex := self genJumpNotSmallInteger: Arg0Reg scratchReg: TempReg.
	self genConvertSmallIntegerToIntegerInReg: Arg0Reg.
	
	"Fetch the pointer from the external address."
	cogit MoveMw: objectMemory baseHeaderSize r: ReceiverResultReg R: destPointerRegister.

	"Add the offfset to the pointer"
	cogit AddR: Arg0Reg R: destPointerRegister.
	aBlock value: destPointerRegister value: Arg1Reg.

	"Restore the Arg0 into an oop."
	self genConvertIntegerToSmallIntegerInReg: Arg0Reg.
	
	jumpNonExternalAddress jmpTarget: (jumpBadIndex jmpTarget: (jumpImmediate jmpTarget: cogit Label)).
	^ needsToTrap ifTrue: [0] ifFalse: [CompletePrimitive]
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStorePointerIntoBytes [
	^ self genPrimitiveStore: BytesPerWord intoBytesWith: [ :destPointer :valueOop |
		| jumpImmediate jumpNonExternalAddress |
		jumpImmediate := self genJumpImmediate: valueOop.
		self genGetCompactClassIndexNonImmOf: valueOop into: TempReg.
		cogit CmpCq: objectMemory classExternalAddressIndex R: TempReg.
		jumpNonExternalAddress := cogit JumpNonZero: 0.

		cogit MoveR: valueOop R: ReceiverResultReg.
		cogit MoveMw: objectMemory baseHeaderSize r: valueOop R: TempReg.
		cogit MoveR: TempReg Mw: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonExternalAddress jmpTarget: (jumpImmediate jmpTarget: cogit Label)
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStorePointerIntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpImmediate jumpNonExternalAddress |
		jumpImmediate := self genJumpImmediate: valueOop.
		self genGetCompactClassIndexNonImmOf: valueOop into: TempReg.
		cogit CmpCq: objectMemory classExternalAddressIndex R: TempReg.
		jumpNonExternalAddress := cogit JumpNonZero: 0.

		cogit MoveR: valueOop R: ReceiverResultReg.
		cogit MoveMw: objectMemory baseHeaderSize r: valueOop R: TempReg.
		cogit MoveR: TempReg Mw: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonExternalAddress jmpTarget: (jumpImmediate jmpTarget: cogit Label)
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreUInt16IntoBytes [
	^ self genPrimitiveStore: 2 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger jumpNegative |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit CmpCq: 0 R: valueOop.
		jumpNegative := cogit JumpLess: 0.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M16: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: (jumpNegative jmpTarget: cogit Label)
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreUInt16IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger jumpNegative |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit CmpCq: 0 R: valueOop.
		jumpNegative := cogit JumpLess: 0.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M16: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: (jumpNegative jmpTarget: cogit Label)
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreUInt8IntoBytes [
	^ self genPrimitiveStore: 1 intoBytesWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger jumpNegative |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit CmpCq: 0 R: valueOop.
		jumpNegative := cogit JumpLess: 0.
		
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M8: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: (jumpNegative jmpTarget: cogit Label)
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStoreUInt8IntoExternalAddress [
	^ self genPrimitiveStoreIntoExternalAddressWith: [ :destPointer :valueOop |
		| jumpNonSmallInteger jumpNegative |
		jumpNonSmallInteger := self genJumpNotSmallInteger: valueOop scratchReg: TempReg.
		cogit CmpCq: 0 R: valueOop.
		jumpNegative := cogit JumpLess: 0.
		
		cogit MoveR: valueOop R: ReceiverResultReg.
	
		self genConvertSmallIntegerToIntegerInReg: valueOop.
		cogit MoveR: valueOop M8: 0 r: destPointer.
		cogit genPrimReturn.
		
		jumpNonSmallInteger jmpTarget: (jumpNegative jmpTarget: cogit Label)
	].
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStringCompareWith [
	"primitiveCompareWith:"
	
	| instr jump jumpAbove jumpIncorrectFormat1 jumpIncorrectFormat2 jumpIncorrectFormat3 jumpIncorrectFormat4 jumpMidFailure jumpSuccess minSizeReg string1CharOrByteSizeReg string2CharOrByteSizeReg string1Reg string2Reg |
	
	<var: #jumpIncorrectFormat1 type: #'AbstractInstruction *'>
	<var: #jumpIncorrectFormat2 type: #'AbstractInstruction *'>
	<var: #jumpIncorrectFormat3 type: #'AbstractInstruction *'>
	<var: #jumpIncorrectFormat4 type: #'AbstractInstruction *'>
	<var: #jumpAbove type: #'AbstractInstruction *'>
	<var: #jumpSuccess type: #'AbstractInstruction *'>
	<var: #jump type: #'AbstractInstruction *'>
	<var: #jumpMidFailure type: #'AbstractInstruction *'>
	
	"I redefine those name to ease program comprehension"
	string1Reg := ReceiverResultReg.
	string2Reg := Arg0Reg.
	string1CharOrByteSizeReg := Arg1Reg.
	string2CharOrByteSizeReg := ClassReg.
	minSizeReg := SendNumArgsReg.
	
	"Load arguments in reg"
	cogit genLoadArgAtDepth: 0 into: string2Reg.
	
	"checks if string1 is a byteobject and get its size in bytes"
	self genGetFormatOf: string1Reg into: TempReg.
	cogit CmpCq: objectMemory firstByteFormat R: TempReg.
	jumpIncorrectFormat1 := cogit JumpLess: 0.
	cogit CmpCq: objectMemory firstCompiledMethodFormat R: TempReg.
	jumpIncorrectFormat2 := cogit JumpAboveOrEqual: 0.
		
	self genGetNumSlotsOf: string1Reg into: string1CharOrByteSizeReg.
	(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: string1CharOrByteSizeReg). 
	cogit AndCq: objectMemory wordSize - 1 R: TempReg R: TempReg. 
	cogit SubR: TempReg R: string1CharOrByteSizeReg. 
	
	"checks if string2 is a byteobject and get its size in bytes"
	self genGetFormatOf: string2Reg into: TempReg.
	cogit CmpCq: objectMemory firstByteFormat R: TempReg.
	jumpIncorrectFormat3 := cogit JumpLess: 0.
	cogit CmpCq: objectMemory firstCompiledMethodFormat R: TempReg.
	jumpIncorrectFormat4 := cogit JumpAboveOrEqual: 0.
		
	self genGetNumSlotsOf: string2Reg into: string2CharOrByteSizeReg.
	(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: string2CharOrByteSizeReg).
	cogit AndCq: objectMemory wordSize - 1 R: TempReg R: TempReg.
	cogit SubR: TempReg R: string2CharOrByteSizeReg.
	
	"Type and number of arguments are correct"
	"Compute the min"	 
	cogit CmpR: string1CharOrByteSizeReg R: string2CharOrByteSizeReg.
	jumpAbove := cogit JumpBelow: 0. 
	cogit MoveR: string1CharOrByteSizeReg R: minSizeReg. 
	jump := cogit Jump: 0. 
	jumpAbove jmpTarget: (cogit MoveR: string2CharOrByteSizeReg R: minSizeReg). 
	jump jmpTarget: (cogit CmpCq: 0 R: minSizeReg). 
	jumpSuccess := cogit JumpZero: 0. "if one of the string is empty, no need to go through the comparing loop"
	
	"Compare the bytes"
	cogit MoveCq: objectMemory baseHeaderSize  R: TempReg.
	cogit AddCq: objectMemory baseHeaderSize R: minSizeReg.
	
	instr := cogit MoveXbr: TempReg R: string1Reg R: string1CharOrByteSizeReg.
	cogit MoveXbr: TempReg R: string2Reg R: string2CharOrByteSizeReg.
	cogit SubR: string2CharOrByteSizeReg R: string1CharOrByteSizeReg. 
	jumpMidFailure := cogit JumpNonZero: 0. "the 2 compared characters are different, exit the loop"
	cogit AddCq: 1 R: TempReg.
	cogit CmpR: TempReg R: minSizeReg. 
	cogit JumpNonZero: instr.
	
	"all bytes from 1 to minSize are equal"
	self genGetNumBytesOf: string1Reg into: string1CharOrByteSizeReg.
	self genGetNumBytesOf: string2Reg into: string2CharOrByteSizeReg.
	jumpSuccess jmpTarget: (cogit SubR: string2CharOrByteSizeReg R: string1CharOrByteSizeReg).
	jumpMidFailure  jmpTarget: (cogit MoveR: string1CharOrByteSizeReg R: ReceiverResultReg).	
	self genConvertIntegerToSmallIntegerInReg: ReceiverResultReg.
	cogit genPrimReturn.
	
	jumpIncorrectFormat4 
		jmpTarget: (jumpIncorrectFormat3 
			jmpTarget: (jumpIncorrectFormat2 
				jmpTarget: (jumpIncorrectFormat1 jmpTarget: cogit Label))).
	
	^ CompletePrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> genPrimitiveStringReplace [
	"replaceFrom: start to: stop with: replacement startingAt: repStart. 
	
	The primitive in the JIT tries to deal with two pathological cases, copy of arrays and byteStrings,
	which often copies only a dozen of fields and where switching to the C runtime cost a lot.
	
	Based on heuristics on the method class, I generate a quick array path (typically for Array),
	a quick byteString path (typically for ByteString, ByteArray and LargeInteger) or no quick 
	path at all (Typically for Bitmap).
	
	The many tests to ensure that the primitive won't fail are not super optimised (multiple reloading
	or stack arguments in registers) but this is still good enough and worth it since we're avoiding 
	the Smalltalk to C stack switch. The tight copying loops are optimised. 
	
	It is possible to build a bigger version with the 2 different paths but I (Clement) believe this 
	is too big machine code wise to be worth it."
	
	|arrayReg startReg stopReg replReg repStartReg jumpNotSmi1 jumpNotSmi2 jumpNotSmi3 jumpImm jumpEmpty jumpImmutable jumpOutOfBounds1 jumpOutOfBounds2 jumpOutOfBounds3 jumpOutOfBounds4 jumpIncorrectFormat1 jumpIncorrectFormat2 jumpIncorrectFormat3 jumpIncorrectFormat4 result jmpDestYoung jmpAlreadyRemembered instr adjust|
	
	<var: #jumpImm type: #'AbstractInstruction *'>
	<var: #jumpEmpty type: #'AbstractInstruction *'>
	<var: #jumpNotSmi1 type: #'AbstractInstruction *'>
	<var: #jumpNotSmi2 type: #'AbstractInstruction *'>
	<var: #jumpNotSmi3 type: #'AbstractInstruction *'>
	<var: #jmpDestYoung type: #'AbstractInstruction *'>
	<var: #jumpImmutable type: #'AbstractInstruction *'>
	<var: #jumpOutOfBounds1 type: #'AbstractInstruction *'>
	<var: #jumpOutOfBounds2 type: #'AbstractInstruction *'>
	<var: #jumpOutOfBounds3 type: #'AbstractInstruction *'>
	<var: #jumpOutOfBounds4 type: #'AbstractInstruction *'>
	<var: #jumpIncorrectFormat1 type: #'AbstractInstruction *'>
	<var: #jumpIncorrectFormat2 type: #'AbstractInstruction *'>
	<var: #jumpIncorrectFormat3 type: #'AbstractInstruction *'>
	<var: #jumpIncorrectFormat4 type: #'AbstractInstruction *'>
	<var: #jmpAlreadyRemembered type: #'AbstractInstruction *'>

	"Can I generate a quick path for this method ?"
	((cogit seemsToBeInstantiating: objectMemory arrayFormat)
		or: [cogit seemsToBeInstantiating: objectMemory firstByteFormat]) ifFalse: [^UnimplementedPrimitive].

	"I redefine those name to ease program comprehension"
	arrayReg := ReceiverResultReg.
	startReg := Arg0Reg.
	stopReg := Arg1Reg.
	replReg := ClassReg.
	repStartReg := SendNumArgsReg.
	
	"Load arguments in reg"
	cogit genStackArgAt: 0 into: repStartReg.
	cogit genStackArgAt: 1 into: replReg.
	cogit genStackArgAt: 2 into: stopReg.
	cogit genStackArgAt: 3 into: startReg.

	"start,stop,repStart Smis or fail the primitive"
	jumpNotSmi1 := self genJumpNotSmallInteger: repStartReg scratchReg: TempReg.
	jumpNotSmi2 := self genJumpNotSmallInteger: stopReg scratchReg: TempReg.
	jumpNotSmi3 := self genJumpNotSmallInteger: startReg scratchReg: TempReg.
	"repl non immediate or fail the primitive"
	jumpImm := self genJumpImmediate: replReg.
	
	"if start>stop primitive success"
	cogit CmpR: startReg R: stopReg.
	jumpEmpty := cogit JumpLess: 0.
	
	"If receiver immutable fail the primitive "
	self
		cppIf: IMMUTABILITY
		ifTrue: [jumpImmutable := self genJumpImmutable: ReceiverResultReg scratchReg: TempReg].
		
	"0 >= start, fail"
	cogit CmpCq: (objectMemory integerObjectOf: 0) R: startReg.
	jumpOutOfBounds1 := cogit JumpLessOrEqual: 0.
	
	"0 >= replStart, fail"
	cogit CmpCq: (objectMemory integerObjectOf: 0) R: repStartReg.
	jumpOutOfBounds2 := cogit JumpLessOrEqual: 0.

	"--- Pointer object version ---"
	(cogit seemsToBeInstantiating: objectMemory arrayFormat) ifTrue:
		["Are they both array format ?"
		self genGetFormatOf: arrayReg into: TempReg.
		self genGetFormatOf: replReg into: startReg.
		cogit CmpCq: objectMemory arrayFormat R: startReg.
		jumpIncorrectFormat1 := cogit JumpNonZero: 0.
		cogit CmpCq: objectMemory arrayFormat R: TempReg.
		jumpIncorrectFormat2 := cogit JumpNonZero: 0.
	
		"Both objects are arrays,"
		self genGetNumSlotsOf: arrayReg into: TempReg.
		self genConvertSmallIntegerToIntegerInReg: stopReg.
	
		"arr size < stop"
		cogit CmpR: TempReg R: stopReg.
		jumpOutOfBounds3 := cogit JumpGreater: 0.
	
		"rep size < repStart - start + stop"
		self genGetNumSlotsOf: replReg into: TempReg.
		cogit genStackArgAt: 3 into: startReg.
		self genConvertSmallIntegerToIntegerInReg: startReg.
		self genConvertSmallIntegerToIntegerInReg: repStartReg.
		cogit SubR: startReg R: stopReg.
		cogit AddR: repStartReg R: stopReg.
		"stopReg: stop - start + repStart"
		cogit CmpR: TempReg R: stopReg.
		jumpOutOfBounds4 := cogit JumpGreater: 0.
	
		"Everything in bounds"
		"PossibleRemembered object"
		cogit MoveCw: objectMemory storeCheckBoundary R: TempReg.
		cogit CmpR: TempReg R: arrayReg.
		jmpDestYoung := cogit JumpBelow: 0.
		self checkRememberedInTrampoline ifFalse: 
			[jmpAlreadyRemembered := self genCheckRememberedBitOf: arrayReg scratch: TempReg].
		cogit backEnd saveAndRestoreLinkRegAround:
			[self callStoreCheckTrampoline].
		jmpDestYoung jmpTarget: cogit Label.
		self checkRememberedInTrampoline ifFalse: 
			[jmpAlreadyRemembered jmpTarget: cogit Label].
	
		"Copy the array"
		cogit genStackArgAt: 2 into: stopReg.
		self genConvertSmallIntegerToIntegerInReg: stopReg.
		"Shift replReg to read it with startReg offset"
		cogit SubR: startReg R: repStartReg. 
		cogit LogicalShiftLeftCq: objectMemory shiftForWord R: repStartReg.
		cogit AddR: repStartReg R: replReg. 
		"shift by baseHeaderSize and then move from 1 relative to zero relative"
		adjust := (objectMemory baseHeaderSize >> objectMemory shiftForWord) - 1. 
		adjust ~= 0 ifTrue: 
			[ cogit AddCq: adjust R: startReg. 
			  cogit AddCq: adjust R: stopReg ].
	
		"Tight copying loop"
		instr := cogit MoveXwr: startReg R: replReg R: TempReg.
		cogit MoveR: TempReg Xwr: startReg R: arrayReg.
		cogit AddCq: 1 R: startReg.
		cogit CmpR: startReg R: stopReg.
		cogit JumpAboveOrEqual: instr.
		
		jumpEmpty jmpTarget: cogit genPrimReturn.
	
		"CANNOT REACH by falling though"
	
		jumpIncorrectFormat1 jmpTarget: (jumpIncorrectFormat2 jmpTarget: cogit Label)].
	
	"--- Byte object version ---"
	(cogit seemsToBeInstantiating: objectMemory firstByteFormat) ifTrue:
		["Are they both byte array format ? CompiledMethod excluded"
		self genGetFormatOf: arrayReg into: TempReg.
		self genGetFormatOf: replReg into: repStartReg.
		cogit CmpCq: objectMemory firstByteFormat R: repStartReg.
		jumpIncorrectFormat1 := cogit JumpLess: 0.
		cogit CmpCq: objectMemory firstCompiledMethodFormat R: repStartReg.
		jumpIncorrectFormat2 := cogit JumpGreaterOrEqual: 0.
		cogit CmpCq: objectMemory firstByteFormat R: TempReg.
		jumpIncorrectFormat3 := cogit JumpLess: 0.
		cogit CmpCq: objectMemory firstCompiledMethodFormat R: TempReg.
		jumpIncorrectFormat4 := cogit JumpGreaterOrEqual: 0.
		
		"Both objects are byte arrays"
		self genGetNumSlotsOf: arrayReg into: startReg.
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: startReg).
		cogit AndCq: objectMemory wordSize - 1 R: TempReg R: TempReg.
		cogit SubR: TempReg R: startReg.
		self genConvertSmallIntegerToIntegerInReg: stopReg.
	
		"arr size < stop"
		cogit CmpR: startReg R: stopReg.
		jumpOutOfBounds3 := cogit JumpGreater: 0.
	
		"rep size < repStart - start + stop"
		cogit MoveR: repStartReg R: TempReg. "TempReg holds repl format"
		cogit genStackArgAt: 0 into: repStartReg.
		cogit genStackArgAt: 3 into: startReg.
		self genConvertSmallIntegerToIntegerInReg: startReg.
		self genConvertSmallIntegerToIntegerInReg: repStartReg.
		cogit SubR: startReg R: stopReg.
		cogit AddR: repStartReg R: stopReg.
		
		self genGetNumSlotsOf: replReg into: startReg.
		(cogit LogicalShiftLeftCq: objectMemory shiftForWord R: startReg).
		cogit AndCq: objectMemory wordSize - 1 R: TempReg R: TempReg.
		cogit SubR: TempReg R: startReg.
		
		"stopReg: stop - start + repStart"
		cogit CmpR: startReg R: stopReg.
		jumpOutOfBounds4 := cogit JumpGreater: 0.
	
		"Everything in bounds"
		"Copy the bytes"
		cogit genStackArgAt: 3 into: startReg.
		self genConvertSmallIntegerToIntegerInReg: startReg.
		cogit genStackArgAt: 2 into: stopReg.
		self genConvertSmallIntegerToIntegerInReg: stopReg.
		"Shift replReg to read it with startReg offset"
		cogit SubR: startReg R: repStartReg. 
		cogit AddR: repStartReg R: replReg. 
		"shift by baseHeaderSize and then move from 1 relative to zero relative"
		adjust := objectMemory baseHeaderSize - 1.
		adjust ~= 0 ifTrue: 
			[ cogit AddCq: adjust R: startReg. 
			  cogit AddCq: adjust R: stopReg.  ].
	
		"Tight copying loop"
		instr := cogit MoveXbr: startReg R: replReg R: TempReg.
		cogit MoveR: TempReg Xbr: startReg R: arrayReg.
		cogit AddCq: 1 R: startReg.
		cogit CmpR: startReg R: stopReg.
		cogit JumpAboveOrEqual: instr.
		
		jumpEmpty jmpTarget: cogit genPrimReturn.
	
		"CANNOT REACH by falling though"
	
		jumpIncorrectFormat4 
			jmpTarget: (jumpIncorrectFormat3 
				jmpTarget: (jumpIncorrectFormat2 
					jmpTarget: (jumpIncorrectFormat1 jmpTarget: cogit Label)))].

	(result := cogit compileInterpreterPrimitive) < 0 ifTrue: [^result].
	
	jumpImm 
		jmpTarget: (jumpNotSmi1
				jmpTarget: (jumpNotSmi2
						jmpTarget: (jumpNotSmi3 jmpTarget: cogit Label))).
	jumpOutOfBounds1 
		jmpTarget: (jumpOutOfBounds2 
			jmpTarget: (jumpOutOfBounds3 
				jmpTarget: (jumpOutOfBounds4 
					jmpTarget: jumpImm getJmpTarget))).
	self
		cppIf: IMMUTABILITY
		ifTrue: [jumpImmutable jmpTarget: jumpImm getJmpTarget].

	^ CompletePrimitive
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genRemoveCharacterTagsInScratchReg: scratchReg [
	cogit SubCq: objectMemory characterTag R: scratchReg
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genSetCharacterTagsIn: reg [
	cogit OrCq: objectMemory characterTag R: reg
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSpur >> genSetGCNeeded [
	<inline: true>
	cogit
		MoveCq: 1 R: TempReg;
		MoveR: TempReg Aw: objectMemory needGCFlagAddress
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genSetSmallIntegerTagsIn: scratchReg [
	cogit OrCq: 1 R: scratchReg.
	^0
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genStoreCheckContextReceiverTrampoline [
	"Create a trampoline to store-check the update of the receiver in a closure's
	 outerContext in compileBlockFrameBuild:."
	| startAddress |
	startAddress := cogit methodZoneBase.
	cogit zeroOpcodeIndex.
	self genStoreCheckReceiverReg: ReceiverResultReg valueReg: Arg0Reg scratchReg: TempReg inFrame: false.
	cogit RetN: 0.
	cogit outputInstructionsForGeneratedRuntimeAt: startAddress.
	cogit recordGeneratedRunTime: 'ceStoreCheckContextReceiver' address: startAddress.
	cogit recordRunTimeObjectReferences.
	^startAddress
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreCheckReceiverReg: destReg valueReg: valueReg scratchReg: scratchReg inFrame: inFrame [
	"Generate the code for a store check of valueReg into destReg."
	| jmpImmediate jmpDestYoung jmpSourceOld jmpAlreadyRemembered |
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	<var: #jmpDestYoung type: #'AbstractInstruction *'>
	<var: #jmpSourceOld type: #'AbstractInstruction *'>
	<var: #jmpAlreadyRemembered type: #'AbstractInstruction *'>
	"Is value stored an immediate?  If so we're done"
	jmpImmediate := self genJumpImmediate: valueReg.
	"Get the old/new boundary in scratchReg"
	cogit MoveCw: objectMemory storeCheckBoundary R: scratchReg.
	"Is target young?  If so we're done"
	cogit CmpR: scratchReg R: destReg. "N.B. FLAGS := destReg - scratchReg"
	jmpDestYoung := cogit JumpBelow: 0.
	"Is value stored old?  If so we're done."
	cogit CmpR: scratchReg R: valueReg. "N.B. FLAGS := valueReg - scratchReg"
	jmpSourceOld := cogit JumpAboveOrEqual: 0.
	"value is young and target is old.
	 Need to remember this only if the remembered bit is not already set."
	CheckRememberedInTrampoline ifFalse:
		[jmpAlreadyRemembered := self genCheckRememberedBitOf: destReg scratch: scratchReg].
	"Remembered bit is not set.  Call store check to insert dest into remembered table."
	self assert: destReg = ReceiverResultReg.
	cogit 
		evaluateTrampolineCallBlock: [cogit CallRT: ceStoreCheckTrampoline]
		protectLinkRegIfNot: inFrame.
	jmpImmediate jmpTarget:
	(jmpDestYoung jmpTarget:
	(jmpSourceOld jmpTarget:
		cogit Label)).
	CheckRememberedInTrampoline ifFalse:
		[jmpAlreadyRemembered jmpTarget: jmpSourceOld getJmpTarget].
	^0
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genStoreCheckTrampoline [
	| jumpSC |
	<var: #jumpSC type: #'AbstractInstruction *'>
	<inline: true>
	CheckRememberedInTrampoline ifTrue:
		[cogit zeroOpcodeIndex.
		 jumpSC := self genCheckRememberedBitOf: ReceiverResultReg scratch: cogit backEnd cResultRegister.
		 self assert: jumpSC opcode = JumpNonZero.
		 jumpSC opcode: JumpZero.
		 cogit RetN: 0.
		 jumpSC jmpTarget: cogit Label].
	^cogit
		genTrampolineFor: #remember:
		called: 'ceStoreCheckTrampoline'
		numArgs: 1
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		arg: nil
		regsToSave: (CallerSavedRegisterMask bitClear: (cogit registerMaskFor: ReceiverResultReg))
		pushLinkReg: true
		resultReg: cogit returnRegForStoreCheck
		appendOpcodes: CheckRememberedInTrampoline
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genStoreHeader: header intoNewInstance: rcvrReg using: scratchReg [
	"Generate the instructions to move the constant header into a new instance pointed to by rcvrReg."
	<inline: true>
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreSourceReg: sourceReg slotIndex: index destReg: destReg scratchReg: scratchReg inFrame: inFrame needsStoreCheck: needsStoreCheck [
	
	cogit genTraceStores.
	"do the store"
	cogit MoveR: sourceReg
		   Mw: index * objectMemory wordSize + objectMemory baseHeaderSize
		   r: destReg.
	"now the check. needStoreCheck is false if the JIT has figured out that the value stored does not need the check (immediate, nil, true, false)"
	needsStoreCheck ifTrue: 
		[ ^ self 
			genStoreCheckReceiverReg: destReg 
			valueReg: sourceReg 
			scratchReg: scratchReg 
			inFrame: inFrame ].
	^ 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreSourceReg: sourceReg slotIndex: index intoNewObjectInDestReg: destReg [
	"This method is used for unchecked stores in objects after their creation (typically, inlined creation of Array, closures and some temp vectors). 
	Currently there is no need to do the immutability check here"
	cogit MoveR: sourceReg
		   Mw: index * objectMemory wordSize + objectMemory baseHeaderSize
		   r: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreTrampolineCall: instVarIndex [
	<inline: true>
	self assert: IMMUTABILITY.
	instVarIndex >= (NumStoreTrampolines - 1)
		ifTrue: 
			[ cogit MoveCq: instVarIndex R: TempReg.
			  cogit CallRT: (ceStoreTrampolines at: NumStoreTrampolines - 1) ]
		ifFalse: 
			[ cogit CallRT: (ceStoreTrampolines at: instVarIndex) ].
	 cogit annotateBytecode: cogit Label
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> genStoreTrampolineCalled: trampolineName instVarIndex: instVarIndex [
	"Convention:
	- RcvrResultReg holds the object mutated.
	If immutability failure:
	- TempReg holds the instance variable index mutated 
		if instVarIndex > numDedicatedStoreTrampoline
	- ClassReg holds the value to store
	Registers are not lived across this trampoline as the 
	immutability failure may need new stack frames."
	
	| jumpSC jumpRC |
	<option: #IMMUTABILITY>
	<var: #trampolineName type: #'char *'>
	<var: #jumpSC type: #'AbstractInstruction *'>
	<var: #jumpRC type: #'AbstractInstruction *'>
	<inline: false>
	cogit zeroOpcodeIndex.
	"SendNumArgsReg is mutated but we don't care as register are not live across the trampoline.
	 There is no reason why registers cannot be saved over the remember: call, but since the
	 immutability check is a suspension point, registers cannot remain live."
	jumpSC := self genJumpMutable: ReceiverResultReg scratchReg: SendNumArgsReg.
	cogit
		compileTrampolineFor: #ceCannotAssignTo:withIndex:valueToAssign:
		numArgs: 3
		arg: ReceiverResultReg
		arg: (instVarIndex < (NumStoreTrampolines - 1)
				ifTrue: [cogit trampolineArgConstant: instVarIndex]
				ifFalse: [TempReg])
		arg: ClassReg
		arg: nil
		regsToSave: cogit emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg.
		
	"Store check"
	jumpSC jmpTarget: cogit Label.
	"If on 64-bits and doing the remembered bit test here, we can combine the tests to fetch the header once."
	CheckRememberedInTrampoline ifTrue:
		[objectMemory wordSize = 8
			ifTrue:
				[cogit TstCq: 1 << objectMemory rememberedBitShift R: SendNumArgsReg.
				 jumpRC := cogit JumpZero: 0.
				 cogit RetN: 0]
			ifFalse:
				[jumpRC := self genCheckRememberedBitOf: ReceiverResultReg scratch: SendNumArgsReg.
				 self assert: jumpRC opcode = JumpNonZero.
				 jumpRC opcode: JumpZero.
				 cogit RetN: 0].
		 jumpRC jmpTarget: cogit Label].
	^ cogit genTrampolineFor: #remember:
		called: trampolineName
		numArgs: 1
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		arg: nil
		regsToSave: cogit emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: true
]

{ #category : #'inline primitive support' }
CogObjectRepresentationForSpur >> genStoreValue: value instance: destReg numSlots: numSlots [ 
	"Store the value in the instance from field 1 to numSlots
	 Typically used for for inlined allocations, initializing objects with 0 or nil.
	 destReg is referencing the object (oop) and is restored at the end of this code.
	 If less than 8 fields, use a full unrolled initialization (up to 8 stores)
	 If more than 8 fields, use a duff device to initialize with a 8-vectorized loop."

	| slotsPerIteration constReg delta branch loopCount loop inst |
	numSlots <= (slotsPerIteration := 8) ifTrue: "slotsPerIteration must be even; see cogit SubCq: objectMemory bytesPerOop R: TempReg below"
		[cogit genMoveConstant: value R: TempReg.
		 0 to: numSlots - 1 do:
			[:i| cogit MoveR: TempReg
					Mw: i * objectMemory wordSize + objectMemory baseHeaderSize
					r: destReg].
		^0].
	
	constReg := cogit allocateRegNotConflictingWith: (cogit registerMaskFor: destReg).
	cogit genMoveConstant: value R: constReg.
	
	numSlots \\ slotsPerIteration ~= 0
		ifTrue: "delta maps the offset at the loop entryPoint onto destReg + objectMemory baseHeaderSize"
			[delta := (slotsPerIteration - (numSlots \\ slotsPerIteration) * objectMemory bytesPerOop) - objectMemory baseHeaderSize.
			 delta > 0 ifTrue: [cogit SubCq: delta R: destReg].
			 delta < 0 ifTrue: [cogit AddCq: delta negated R: destReg].
			 "now delta maps (loopCount * slotsPerIteration * objectMemory bytesPerOop) + objectMemory baseHeaderSize - delta to the start of the object"
			 delta := delta + objectMemory baseHeaderSize.
			 (objectMemory bytesPerOop < objectMemory baseHeaderSize
			  and: [numSlots \\ 2 = 1]) ifTrue: "if end of loop is not at start of next object, adjust loop limit in TempReg to point to last field filled."
				[cogit SubCq: objectMemory bytesPerOop R: TempReg].
			 branch := cogit Jump: 0]
		ifFalse:
			[delta := 0.
			 cogit AddCq: objectMemory baseHeaderSize R: destReg].
	"loopCount is number of times through the increment of destReg."
	loopCount := numSlots + slotsPerIteration - 1 // slotsPerIteration.
	self assert: loopCount > 1.
	loop := cogit Label.
	0 to: 7 do:
		[:i|
		inst := cogit MoveR: constReg Mw: i * objectMemory bytesPerOop r: destReg.
		slotsPerIteration - (numSlots \\ slotsPerIteration) = i ifTrue:
			[branch jmpTarget: inst]].
	cogit
		AddCq: slotsPerIteration * objectMemory bytesPerOop R: destReg;
		CmpR: TempReg R: destReg;
		JumpBelow: loop;
		SubCq: (loopCount * slotsPerIteration * objectMemory bytesPerOop) + objectMemory baseHeaderSize - delta R: destReg.
	^0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreWithImmutabilityAndStoreCheckSourceReg: sourceReg slotIndex: index destReg: destReg scratchReg: scratchReg needRestoreRcvr: needRestoreRcvr [ 
	"Store check code is duplicated to use a single trampoline"
	<option: #IMMUTABILITY>
	| immutableJump jmpImmediate jmpDestYoung jmpSourceOld jmpAlreadyRemembered |
	<var: #immutableJump type: #'AbstractInstruction *'>
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	<var: #jmpDestYoung type: #'AbstractInstruction *'>
	<var: #jmpSourceOld type: #'AbstractInstruction *'>
	<var: #jmpAlreadyRemembered type: #'AbstractInstruction *'>

	immutableJump := self genJumpImmutable: destReg scratchReg: scratchReg.
	
	cogit genTraceStores.
	
	"do the store"
	cogit MoveR: sourceReg
		   Mw: index * objectMemory wordSize + objectMemory baseHeaderSize
		   r: destReg.
	
	"store check"
	jmpImmediate := self genJumpImmediate: sourceReg.
	"Get the old/new boundary in scratchReg"
	cogit MoveCw: objectMemory storeCheckBoundary R: scratchReg.
	"Is target young?  If so we're done"
	cogit CmpR: scratchReg R: destReg. "N.B. FLAGS := destReg - scratchReg"
	jmpDestYoung := cogit JumpBelow: 0.
	"Is value stored old?  If so we're done."
	cogit CmpR: scratchReg R: sourceReg. "N.B. FLAGS := valueReg - scratchReg"
	jmpSourceOld := cogit JumpAboveOrEqual: 0.
	"value is young and target is old.
	 Need to remember this only if the remembered bit is not already set."
	CheckRememberedInTrampoline ifFalse:
		[jmpAlreadyRemembered := self genCheckRememberedBitOf: destReg scratch: scratchReg].
	"Set the inst var index for the benefit of the immutability check. The trampoline will
	 repeat the check to choose between the immutbality violation and the store check."
	immutableJump jmpTarget: cogit Label.
	self genStoreTrampolineCall: index.
	cogit voidReceiverOptStatus.
	needRestoreRcvr ifTrue:
		[cogit putSelfInReceiverResultReg].

	jmpImmediate jmpTarget:
	(jmpDestYoung jmpTarget:
	(jmpSourceOld jmpTarget:
		cogit Label)).
	CheckRememberedInTrampoline ifFalse:
		[jmpAlreadyRemembered jmpTarget: jmpSourceOld getJmpTarget].
	^ 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreWithImmutabilityButNoStoreCheckSourceReg: sourceReg slotIndex: index destReg: destReg scratchReg: scratchReg needRestoreRcvr: needRestoreRcvr [
	"Gen an immutability check with no store check (e.g. assigning an immediate literal)"
	<option: #IMMUTABILITY>
	<var: #mutableJump type: #'AbstractInstruction *'>
	<var: #immutabilityFailure type: #'AbstractInstruction *'>
	| immutabilityFailure mutableJump |
	
	"imm check has its own trampoline"
	mutableJump := self genJumpMutable: destReg scratchReg: scratchReg.
	self genStoreTrampolineCall: index.
	cogit voidReceiverOptStatus.
	needRestoreRcvr ifTrue:
		[cogit putSelfInReceiverResultReg].
	immutabilityFailure := cogit Jump: 0.
	mutableJump jmpTarget: cogit Label.

	cogit genTraceStores.
	
	"do the store"
	cogit MoveR: sourceReg
		   Mw: index * objectMemory wordSize + objectMemory baseHeaderSize
		   r: destReg.
		
	immutabilityFailure jmpTarget: cogit Label.

	^ 0
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> genStoreWithImmutabilityCheckSourceReg: sourceReg slotIndex: index destReg: destReg scratchReg: scratchReg needsStoreCheck: needsStoreCheck needRestoreRcvr: needRestoreRcvr [
	<option: #IMMUTABILITY>
	"We know there is a frame as immutability check requires a frame"
	"needRestoreRcvr has to be true to keep RcvrResultReg live with the receiver in it across the trampoline"
	
	"Trampoline convention..."
	self assert: destReg == ReceiverResultReg.
	self assert: scratchReg == TempReg.
  	self assert: sourceReg == ClassReg.
	
	"The two paths are very different as the trampoline is shared in 1 case so we split here"
	needsStoreCheck
		ifTrue: 
			[ self 
				genStoreWithImmutabilityAndStoreCheckSourceReg: sourceReg 
				slotIndex: index 
				destReg: destReg 
				scratchReg: scratchReg 
				needRestoreRcvr: needRestoreRcvr ]
		ifFalse: 
			[ self 
				genStoreWithImmutabilityButNoStoreCheckSourceReg: sourceReg 
				slotIndex: index 
				destReg: destReg 
				scratchReg: scratchReg 
				needRestoreRcvr: needRestoreRcvr ].
	^ 0
]

{ #category : #'mapped inlined primitive support' }
CogObjectRepresentationForSpur >> genVarIndexCallStoreTrampoline [	
	self assert: IMMUTABILITY.
	self cppIf: #IMMUTABILITY
		ifTrue: [cogit CallRT: (ceStoreTrampolines at: NumStoreTrampolines - 1).
				cogit annotateBytecode: cogit Label ].
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> generateObjectRepresentationTrampolines [
	"Do the store check.  Answer the argument for the benefit of the code generator;
	 ReceiverResultReg may be caller-saved and hence smashed by this call.  Answering
	 it allows the code generator to reload ReceiverResultReg cheaply.
	 In Spur the only thing we leave to the run-time is adding the receiver to the
	 remembered set and setting its isRemembered bit."
	self 
		cppIf: IMMUTABILITY
		ifTrue: 
			[self cCode: [] inSmalltalk:
				[ceStoreTrampolines := CArrayAccessor on: (Array new: NumStoreTrampolines)].
			 0 to: NumStoreTrampolines - 1 do:
				[:instVarIndex |
				 ceStoreTrampolines
					at: instVarIndex
					put: (self 
							genStoreTrampolineCalled: (cogit 
															trampolineName: 'ceStoreTrampoline' 
															numArgs: instVarIndex 
															limit: NumStoreTrampolines - 2) 
							instVarIndex: instVarIndex)]].
	ceNewHashTrampoline := self genNewHashTrampoline: false called: 'ceNewHash'.
	SistaVM ifTrue: [ceInlineNewHashTrampoline := self genNewHashTrampoline: true  called: 'ceInlineNewHash'].
	ceStoreCheckTrampoline := self genStoreCheckTrampoline.
	ceStoreCheckContextReceiverTrampoline := self genStoreCheckContextReceiverTrampoline.
	ceScheduleScavengeTrampoline := cogit
											genTrampolineFor: #ceScheduleScavenge
											called: 'ceScheduleScavengeTrampoline'
											regsToSave: CallerSavedRegisterMask.
	ceSmallActiveContextInMethodTrampoline := self genActiveContextTrampolineLarge: false inBlock: 0 called: 'ceSmallMethodContext'.
	ceSmallActiveContextInBlockTrampoline := self genActiveContextTrampolineLarge: false inBlock: InVanillaBlock called: 'ceSmallBlockContext'.
	SistaV1BytecodeSet ifTrue:
		[ceSmallActiveContextInFullBlockTrampoline := self genActiveContextTrampolineLarge: false inBlock: InFullBlock called: 'ceSmallFullBlockContext'].
	ceLargeActiveContextInMethodTrampoline := self genActiveContextTrampolineLarge: true inBlock: 0 called: 'ceLargeMethodContext'.
	ceLargeActiveContextInBlockTrampoline := self genActiveContextTrampolineLarge: true inBlock: InVanillaBlock called: 'ceLargeBlockContext'.
	SistaV1BytecodeSet ifTrue:
		[ceLargeActiveContextInFullBlockTrampoline := self genActiveContextTrampolineLarge: true inBlock: InFullBlock called: 'ceLargeFullBlockContext'].
]

{ #category : #'bytecode generator support' }
CogObjectRepresentationForSpur >> getActiveContextAllocatesInMachineCode [
	"Make sure SendNumArgsReg and ClassReg are available in addition to
	 ReceiverResultReg and TempReg in genGetActiveContextNumArgs:large:inBlock:."
	^true
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> getLiteralCountOf: methodReg plusOne: plusOne inBytes: inBytes into: litCountReg scratch: scratchReg [
	"Get the literal count of a CompiledMethod into headerReg, plus one if requested.
	  If inBytes is true, scale the count by the word size.  Deal with the possibility of
	 the method being cogged."
	self subclassResponsibility
]

{ #category : #testing }
CogObjectRepresentationForSpur >> hasSpurMemoryManagerAPI [
	^true
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> hasValidHeaderPostGC: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	^cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> initialize [

	<doNotGenerate>
	super initialize.
	
	ceStoreTrampolines := (CArrayAccessor on: (Array new: NumStoreTrampolines))
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> inlineCacheTagIsYoung: cacheTag [
	"Since all cache tags in Spur are class indices none of
	 them are young or have to be updated in a scavenge."
	^false
]

{ #category : #'in-line cacheing' }
CogObjectRepresentationForSpur >> inlineCacheTagsMayBeObjects [
	^false
]

{ #category : #'object representation' }
CogObjectRepresentationForSpur >> isSmallIntegerTagNonZero [
	^true
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> jumpNotCharacterUnsignedValueInRegister: reg [
	cogit CmpCq: 1 << self numCharacterBits - 1 R: reg.
	^cogit JumpAbove: 0
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> markAndTraceLiteral: literal [
	(self couldBeObject: literal) ifTrue:
		[self assert: (objectMemory addressCouldBeObj: literal).
		 objectMemory markAndTrace: literal]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> markAndTraceLiteral: literal in: cogMethod at: address [
	"Mark and trace a literal in a sqInt variable of cogMethod."
	<var: #cogMethod type: #'CogMethod *'>
	<var: #address type: #'sqInt *'>
	| objOop |
	(self couldBeObject: literal) ifFalse:
		[^self].
	self assert: (objectMemory addressCouldBeObj: literal).
	(objectMemory isForwarded: literal) ifFalse:
		[objectMemory markAndTrace: literal.
		 ^self].
	objOop := objectMemory followForwarded: literal.
	address at: 0 put: objOop.
	self markAndTraceUpdatedLiteral: objOop in: cogMethod
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> markAndTraceLiteral: literal in: cogMethodOrNil atpc: address [
	"Mark and trace a literal in a machine code instruction preceding address in cogMethodOrNil.
	 Answer if code was modified."
	<var: #cogMethodOrNil type: #'CogMethod *'>
	<var: #address type: #usqInt>
	| objOop |
	(self couldBeObject: literal) ifFalse:
		[^false].
	self assert: (objectMemory addressCouldBeObj: literal).
	(objectMemory isForwarded: literal) ifFalse:
		[objectMemory markAndTrace: literal.
		 ^false].
	objOop := objectMemory followForwarded: literal.
	cogit backEnd storeLiteral: objOop beforeFollowingAddress: address.
	self markAndTraceUpdatedLiteral: objOop in: cogMethodOrNil.
	^true
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> markAndTraceLiteralIfYoung: literal [
	((self couldBeObject: literal)
	 and: [objectMemory isYoungObject: literal]) ifTrue:
		[self assert: (objectMemory addressCouldBeObj: literal).
		 objectMemory markAndTrace: literal]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> markAndTraceUpdatedLiteral: objOop in: cogMethodOrNil [
	"Common code to mark a literal in cogMethod and add
	 the cogMethod to youngReferrers if the literal is young."
	<var: #cogMethodOrNil type: #'CogMethod *'>
	(objectMemory isNonImmediate: objOop) ifTrue:
		[(cogMethodOrNil notNil
		  and: [objectMemory isYoungObject: objOop]) ifTrue:
			[methodZone ensureInYoungReferrers: cogMethodOrNil].
		 objectMemory markAndTrace: objOop]
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> maybeCompileRetryOnPrimitiveFail: primIndex [
	"If primIndex has an accessorDepth and fails, or it is external and fails with PrimErrNoMemory,
	 call ceCheckAndMaybeRetryPrimitive if so  If ceCheck.... answers true, retry the primitive."
	| jmp |
	<var: #jmp type: #'AbstractInstruction *'>
	(coInterpreter accessorDepthForPrimitiveIndex: primIndex) >= 0
		ifTrue:
			[jmp := cogit
				MoveAw: coInterpreter primFailCodeAddress R: TempReg;
				CmpCq: 0 R: TempReg;
				JumpZero: 0]
		ifFalse:
			[coInterpreter primNumberExternalCall ~= primIndex ifTrue:
				[^0].
			 jmp := cogit
				MoveAw: coInterpreter primFailCodeAddress R: TempReg;
				CmpCq: PrimErrNoMemory R: TempReg;
				JumpNonZero: 0].
	cogit
		compileCallFor: #ceCheckAndMaybeRetryPrimitive:
		numArgs: 1
		arg: (cogit trampolineArgConstant: primIndex)
		arg: nil
		arg: nil
		arg: nil
		resultReg: TempReg
		regsToSave: cogit emptyRegisterMask.
	jmp jmpTarget: cogit Label.
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> maybeMarkCounters: theCounters [
	"In SIsta Spur counters are held on the heap in pinned objects which must be marked
	 to avoid them being garbage collected.  This is the hook through which that happens."
	<var: #theCounters type: #usqInt>
	<option: #SistaCogit>
	<inline: true>
	theCounters ~= 0 ifTrue:
		[objectMemory markAndTrace: theCounters - objectMemory baseHeaderSize]
]

{ #category : #compilation }
CogObjectRepresentationForSpur >> maybeNoteDescriptor: descriptor blockStart: blockStart [
	"Override to note inst var refs in blocks.  Used to avoid checking
	 for forwarded receivers in blocks that don't refer to inst vars."
	<var: #blockStart type: #'BlockStart *'>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	descriptor isInstVarRef ifTrue:
		[blockStart hasInstVarRef: true]
]

{ #category : #'method cacheing' }
CogObjectRepresentationForSpur >> maybeShiftClassTagRegisterForMethodCacheProbe: classTagReg [
	"Generate a shift of the register containing the class tag in a method cache probe.
	 c.f. SpurMemoryManager>>methodCacheHashOf:with:"

	cogit LogicalShiftLeftCq: 2 R: classTagReg.
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> mixed: numNonImmediates branchIf: reg instanceOfBehaviors: arrayObj target: targetFixUp [
	| jmpImmediate numCases classObj index jmp |
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	<var: #targetFixUp type: #'AbstractInstruction *'>
	<var: #jmp type: #'AbstractInstruction *'>
	numCases := objectMemory numSlotsOf: arrayObj.
	jmpImmediate := self genJumpImmediate: reg.
	
	"Rcvr is non immediate"
	self genGetClassIndexOfNonImm: reg into: TempReg.
	index := 0.
	0 to: numCases - 1 do:
		[:i|
			classObj := objectMemory fetchPointer: i ofObject: arrayObj.
			(objectMemory isImmediateClass: classObj) ifFalse: [
				self genCmpClassIndex: (objectMemory classTagForClass: classObj) R: TempReg.
				cogit JumpZero: targetFixUp.
				index := index + 1 ] ].
	jmp := cogit Jump: 0.
	
	"Rcvr is immediate"
	jmpImmediate jmpTarget: cogit Label.
	numCases - numNonImmediates "num Immediates allowed"
		caseOf:
		{[ 1 ] -> [ "1 immediate needs to jump. Find it and jump."
			0 to: numCases - 1 do:
				[ :j |
				classObj := objectMemory fetchPointer: j ofObject: arrayObj.
				(objectMemory isImmediateClass: classObj) ifTrue: [
					self branchIf: reg hasImmediateTag: (objectMemory classTagForClass: classObj) target: targetFixUp ] ] ] .
		[ 2 ] -> [ "2 immediates needs to jump"
				self branch2CasesIf: reg instanceOfBehaviors: arrayObj target: targetFixUp ] .
		[ 3 ] -> [ "all 3 needs to jump" self Jump: targetFixUp ] }.
	
	jmp jmpTarget: self Label.
	
	^ 0
		
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> mixed: numNonImmediates branchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	| jmpImmediate jumps label numCases classObj index |
	<var: #label type: #'AbstractInstruction *'>
	<var: #jmpImmediate type: #'AbstractInstruction *'>
	<var: #jumps type: #'AbstractInstruction **'>
	<var: #targetFixUp type: #'AbstractInstruction *'>
	numCases := objectMemory numSlotsOf: arrayObj.
	jmpImmediate := self genJumpImmediate: reg.
	
	"Rcvr is non immediate"
	jumps := self alloca: numNonImmediates type: (self cCode: [#'AbstractInstruction *'] inSmalltalk: [cogit backEnd class]).
	self genGetClassIndexOfNonImm: reg into: TempReg.
	index := 0.
	0 to: numCases - 1 do:
		[:i|
			classObj := objectMemory fetchPointer: i ofObject: arrayObj.
			(objectMemory isImmediateClass: classObj) ifFalse: [
				self genCmpClassIndex: (objectMemory classTagForClass: classObj) R: TempReg.
				jumps at: index put: (cogit JumpZero: 0).
				index := index + 1 ] ].
	cogit Jump: targetFixUp.
	
	"Rcvr is immediate"
	jmpImmediate jmpTarget: cogit Label.
	numCases - numNonImmediates "num Immediates allowed"
		caseOf:
		{[ 1 ] -> [ "1 immediate allowed. jump to targetFixUp if the rcvr is not this immediate"
			0 to: numCases - 1 do:
				[ :j |
				classObj := objectMemory fetchPointer: j ofObject: arrayObj.
				(objectMemory isImmediateClass: classObj) ifTrue: [
					self branchIf: reg hasNotImmediateTag: (objectMemory classTagForClass: classObj) target: targetFixUp ] ] ] .
		[ 2 ] -> [ "2 immediates allowed. On 32 bits nothing to do, all immediate are allowed, on 64 bits generates the jump to fixup for the third tag"
				self branch2CasesIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp ] .
		[ 3 ] -> [ "nothing to do, all immediates are allowed." ] }.
	
	label := self Label.
	0 to: numNonImmediates - 1 do: [:i |
		(jumps at: i) jmpTarget: label ].
	
	^ 0
		
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> noneImmediateBranchIf: reg instanceOfBehaviors: arrayObj target: targetFixUp [
	"All classes in arrayObj are not immediate"
	| classObj jmp |
	<var: #targetFixUp type: #'AbstractInstruction *'>
	<var: #jmp type: #'AbstractInstruction *'>
	jmp := self genJumpImmediate: reg.
	self genGetClassIndexOfNonImm: reg into: TempReg.
	0 to: (objectMemory numSlotsOf: arrayObj) - 1 do:
		[:i|
		 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
		 self genCmpClassIndex: (objectMemory classTagForClass: classObj) R: TempReg.
		cogit JumpZero: targetFixUp ].
	jmp jmpTarget: self Label.
	^0
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> noneImmediateBranchIf: reg notInstanceOfBehaviors: arrayObj target: targetFixUp [
	"All classes in arrayObj are not immediate"
	| label numJumps jumps classObj |
	<var: #label type: #'AbstractInstruction *'>
	<var: #jumps type: #'AbstractInstruction **'>
	<var: #targetFixUp type: #'AbstractInstruction *'>
	jumps := self alloca: (objectMemory numSlotsOf: arrayObj) type: (self cCode: [#'AbstractInstruction *'] inSmalltalk: [cogit backEnd class]).
	(self genJumpImmediate: reg) jmpTarget: targetFixUp.
	self genGetClassIndexOfNonImm: reg into: TempReg.
	0 to: (numJumps := objectMemory numSlotsOf: arrayObj) - 1 do:
		[:i|
		 classObj := objectMemory fetchPointer: i ofObject: arrayObj.
		 self genCmpClassIndex: (objectMemory classTagForClass: classObj) R: TempReg.
		jumps at: i put: (cogit JumpZero: 0) ].
	cogit Jump: targetFixUp.
	label := cogit Label.
	0 to: numJumps - 1 do: [:i |
		(jumps at: i) jmpTarget: label ].
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentationForSpur >> numCharacterBits [
	^30
]

{ #category : #'calling convention' }
CogObjectRepresentationForSpur >> numRegArgs [
	"Define how many register arguments a StackToRegisterMappingCogit can
	 and should use with the receiver.  The value must be 0, 1 or 2.  Note that a
	 SimpleStackBasedCogit always has 0 register args (although the receiver is
	 passed in a register).  The Spur object representation is simple enough that
	 implementing at:put: is straight-forward and hence 2 register args are worth
	 while.  The method must be inlined in CoInterpreter, and dead code eliminated
	 so that the register-popping enilopmarts such as enterRegisterArgCogMethod:-
	 at:receiver: do not have to be implemented in SimpleStackBasedCogit."
	<api>
	<option: #StackToRegisterMappingCogit>
	^2
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> remapObject: objOop [
	self assert: (objectMemory addressCouldBeObj: objOop).
	^(objectMemory shouldRemapObj: objOop)
		ifTrue: [objectMemory remapObj: objOop]
		ifFalse: [objOop]
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> remapOop: objOop [
	^(objectMemory shouldRemapOop: objOop)
		ifTrue: [objectMemory remapObj: objOop]
		ifFalse: [objOop]
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> resetCountersIn: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<api>
	<option: #SistaCogit>
	cogit fillInCounters: (self numCountersFor: cogMethod counters) atStartAddress: cogMethod counters
]

{ #category : #initialization }
CogObjectRepresentationForSpur >> setAllStoreTrampolinesWith: anAddress [ 
	
	<doNotGenerate>
	0 to: NumStoreTrampolines - 1 do:  [ :anIndex |
		ceStoreTrampolines at: anIndex put: anAddress]
]

{ #category : #'mapped inlined primitive support' }
CogObjectRepresentationForSpur >> setIfRequiredTargetOf: jumpRemembered toTargetOf: jmpImmediate [
	<inline: true> "To avoid typing..."
	CheckRememberedInTrampoline ifFalse:
		[jumpRemembered jmpTarget: jmpImmediate getJmpTarget].
]

{ #category : #'garbage collection' }
CogObjectRepresentationForSpur >> shouldAnnotateObjectReference: anOop [
	"Objects in newSpace or oldSpace except nil, true, false & classTableRootObj need to be annotated."
	^(objectMemory isNonImmediate: anOop)
	  and: [(self oop: anOop isGreaterThan: objectMemory classTableRootObj)
		or: [self oop: anOop isLessThan: objectMemory nilObject]]
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentationForSpur >> slotOffsetOfInstVarIndex: index [
	^index * objectMemory wordSize + objectMemory baseHeaderSize
]

{ #category : #testing }
CogObjectRepresentationForSpur >> smallIntegerIsOnlyImmediateType [
	^false
]

{ #category : #'sista support' }
CogObjectRepresentationForSpur >> valueOfAssociation: associationOop [
	| association |
	association := associationOop.
	(objectMemory isForwarded: association) ifTrue:
		[association := objectMemory followForwarded: association].
	^objectMemory fetchPointer: ValueIndex ofObject: association
]
