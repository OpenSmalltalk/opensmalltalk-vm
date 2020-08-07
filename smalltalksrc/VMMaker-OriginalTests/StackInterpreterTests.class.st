Class {
	#name : #StackInterpreterTests,
	#superclass : #TestCase,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #tests }
StackInterpreterTests >> testImmediateFloats [
	"self new testImmediateFloats"
	| vm smm smallFloatOop |
	vm := StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur64BitMemoryManager).
	smm := vm objectMemory.
	#(0.0 -0.0 1.0e38 -1.0e38 1.0e-38 -1.0e-38 2.0 -2.0) do:
		[:f| | sfo |
		vm initPrimCall.
		self shouldnt: [sfo := smm smallFloatObjectOf: f] raise: Error.
		self assert: (smm smallFloatValueOf: sfo) equals: f.
		self assert: ((smm exponentOfSmallFloat: sfo) between: -126 and: 127)].
	{Float nan. Float infinity. Float negativeInfinity. 1.0e-39. 1.0e39. 5.8774717541114375e-39. 6.80564733841877e38 } do:
		[:f| self deny: (smm isSmallFloatValue: f)].
	vm initPrimCall.
	smallFloatOop := smm smallFloatTag + (1 << (smm smallFloatMantissaBits + smm numTagBits)).
	self shouldnt: [smm floatValueOf: smallFloatOop] raise: Error.
	self deny: vm failed.
	self assert: (smm isSmallFloatValue: (smm floatValueOf: smallFloatOop)).
	self assert: (smm floatObjectOf: (smm floatValueOf: smallFloatOop)) equals: smallFloatOop.
	vm initPrimCall.
	smallFloatOop := ((1 bitShift: 64) - 1 bitClear: (1 bitShift: smm numTagBits + 1) - 1) + smm smallFloatTag.
	self shouldnt: [smm floatValueOf: smallFloatOop] raise: Error.
	self deny: vm failed.
	self assert: (smm isSmallFloatValue: (smm floatValueOf: smallFloatOop)).
	self assert: (smm floatObjectOf: (smm floatValueOf: smallFloatOop)) equals: smallFloatOop
]

{ #category : #tests }
StackInterpreterTests >> testPointerTaggingDetagging [
	"Test the adding/removal of SmallInteger tags to memory adresses used in
	 StackInterpreter and StackInterpreterSimulator for married context management."

	"StackInterpreterTests new testPointerTaggingDetagging"

	{ StackInterpreterSimulatorLSB new. "StackInterpreterSimulatorMSB new" } do: "Need to add MSB soon"
		[:sis|
		({ sis objectMemory minSmallInteger. sis objectMemory minSmallInteger / 2. -1024. -4. -8.
		    sis objectMemory maxSmallInteger - 1. sis objectMemory maxSmallInteger // 2. 4. 8} collect:
			[:n| n bitClear: sis objectMemory tagMask]) do:
				[:n| | tagged untagged |
				self assert: (n bitAnd: sis objectMemory tagMask) = 0.
				self assert: (sis objectMemory isNonIntegerObject: n).
				tagged := sis withSmallIntegerTags: n.
				untagged := sis withoutSmallIntegerTags: tagged.
				self assert: (sis objectMemory isIntegerObject: tagged).
				self assert: untagged = n]]
]
