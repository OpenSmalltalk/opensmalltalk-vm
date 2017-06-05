Class {
	#name : #StackInterpreterTests,
	#superclass : #TestCase,
	#category : 'VMMaker-Tests'
}

{ #category : #tests }
StackInterpreterTests >> testByteMemoryAccess [
	"self new testByteMemoryAccess"
	| om |
	om := NewCoObjectMemorySimulator new allocateMemoryOfSize: 16.
	om byteAt: 0 put: 16r11.
	om byteAt: 1 put: 16r22.
	om byteAt: 2 put: 16r33.
	om byteAt: 3 put: 16r44.
	self assert: (om longAt: 0) equals: 16r44332211.
	self assert: (om byteAt: 0) equals: 16r11.
	self assert: (om byteAt: 1) equals: 16r22.
	self assert: (om byteAt: 2) equals: 16r33.
	self assert: (om byteAt: 3) equals: 16r44.
	om := Spur32BitMMLECoSimulator new allocateMemoryOfSize: 16.
	om byteAt: 0 put: 16r11.
	om byteAt: 1 put: 16r22.
	om byteAt: 2 put: 16r33.
	om byteAt: 3 put: 16r44.
	self assert: (om longAt: 0) equals: 16r44332211.
	self assert: (om byteAt: 0) equals: 16r11.
	self assert: (om byteAt: 1) equals: 16r22.
	self assert: (om byteAt: 2) equals: 16r33.
	self assert: (om byteAt: 3) equals: 16r44.
	om := Spur64BitMMLECoSimulator new allocateMemoryOfSize: 32.
	om byteAt: 0 put: 16r11.
	om byteAt: 1 put: 16r22.
	om byteAt: 2 put: 16r33.
	om byteAt: 3 put: 16r44.
	om byteAt: 4 put: 16r55.
	om byteAt: 5 put: 16r66.
	om byteAt: 6 put: 16r77.
	om byteAt: 7 put: 16r88.
	self assert: (om longAt: 0) equals: 16r8877665544332211.
	self assert: (om byteAt: 0) equals: 16r11.
	self assert: (om byteAt: 1) equals: 16r22.
	self assert: (om byteAt: 2) equals: 16r33.
	self assert: (om byteAt: 3) equals: 16r44.
	self assert: (om byteAt: 4) equals: 16r55.
	self assert: (om byteAt: 5) equals: 16r66.
	self assert: (om byteAt: 6) equals: 16r77.
	self assert: (om byteAt: 7) equals: 16r88.
	(Smalltalk classNamed: #DoubleWordArray) ifNotNil:
		[om := Spur64BitMMLECoSimulatorFor64Bits new allocateMemoryOfSize: 32.
		 om byteAt: 0 put: 16r11.
		 om byteAt: 1 put: 16r22.
		 om byteAt: 2 put: 16r33.
		 om byteAt: 3 put: 16r44.
		 om byteAt: 4 put: 16r55.
		 om byteAt: 5 put: 16r66.
		 om byteAt: 6 put: 16r77.
		 om byteAt: 7 put: 16r88.
		 self assert: (om longAt: 0) equals: 16r8877665544332211.
		 self assert: (om byteAt: 0) equals: 16r11.
		 self assert: (om byteAt: 1) equals: 16r22.
		 self assert: (om byteAt: 2) equals: 16r33.
		 self assert: (om byteAt: 3) equals: 16r44.
		 self assert: (om byteAt: 4) equals: 16r55.
		 self assert: (om byteAt: 5) equals: 16r66.
		 self assert: (om byteAt: 6) equals: 16r77.
		 self assert: (om byteAt: 7) equals: 16r88]
]

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

{ #category : #tests }
StackInterpreterTests >> testShortMemoryAccess [
	"self new testShortMemoryAccess"
	| om |
	om := NewCoObjectMemorySimulator new allocateMemoryOfSize: 16.
	om shortAt: 0 put: 16r2211.
	om shortAt: 2 put: 16r4433.
	self assert: (om longAt: 0) equals: 16r44332211.
	self assert: (om shortAt: 0) equals: 16r2211.
	self assert: (om shortAt: 2) equals: 16r4433.
	om := Spur32BitMMLECoSimulator new allocateMemoryOfSize: 16.
	om shortAt: 0 put: 16r2211.
	om shortAt: 2 put: 16r4433.
	self assert: (om longAt: 0) equals: 16r44332211.
	self assert: (om shortAt: 0) equals: 16r2211.
	self assert: (om shortAt: 2) equals: 16r4433.
	om := Spur64BitMMLECoSimulator new allocateMemoryOfSize: 32.
	om shortAt: 0 put: 16r2211.
	om shortAt: 2 put: 16r4433.
	om shortAt: 4 put: 16r6655.
	om shortAt: 6 put: 16r8877.
	self assert: (om longAt: 0) equals: 16r8877665544332211.
	self assert: (om shortAt: 0) equals: 16r2211.
	self assert: (om shortAt: 2) equals: 16r4433.
	self assert: (om shortAt: 4) equals: 16r6655.
	self assert: (om shortAt: 6) equals: 16r8877.
	(Smalltalk classNamed: #DoubleWordArray) ifNotNil:
		[om := Spur64BitMMLECoSimulatorFor64Bits new allocateMemoryOfSize: 32.
		 om shortAt: 0 put: 16r2211.
		 om shortAt: 2 put: 16r4433.
		 om shortAt: 4 put: 16r6655.
		 om shortAt: 6 put: 16r8877.
		 self assert: (om longAt: 0) equals: 16r8877665544332211.
		 self assert: (om shortAt: 0) equals: 16r2211.
		 self assert: (om shortAt: 2) equals: 16r4433.
		 self assert: (om shortAt: 4) equals: 16r6655.
		 self assert: (om shortAt: 6) equals: 16r8877]
]

{ #category : #tests }
StackInterpreterTests >> testUnalignedMemoryAccess [
	"self new testUnalignedMemoryAccess"
	| om |
	om := NewCoObjectMemorySimulator new allocateMemoryOfSize: 16.
	om unalignedLongAt: 1 put: 16r11223344.
	self assert: (om unalignedLongAt: 0) equals: 16r22334400.
	self assert: (om unalignedLongAt: 4) equals: 16r11.
	self assert: (om unalignedLongAt: 1) equals: 16r11223344.
	om longAt: 0 put: 16rAAAAAAAA.
	om longAt: 4 put: 16rAAAAAAAA.
	om unalignedLongAt: 1 put: 16r11223344.
	self assert: (om unalignedLongAt: 0) equals: 16r223344AA.
	self assert: (om unalignedLongAt: 4) equals: 16rAAAAAA11.
	self assert: (om unalignedLongAt: 1) equals: 16r11223344.
	om := Spur32BitMMLECoSimulator new allocateMemoryOfSize: 16.
	om unalignedLongAt: 3 put: 16r11223344.
	self assert: (om unalignedLongAt: 0) equals: 16r44000000.
	self assert: (om unalignedLongAt: 4) equals: 16r112233.
	self assert: (om unalignedLongAt: 3) equals: 16r11223344.
	om longAt: 0 put: 16rAAAAAAAA.
	om longAt: 4 put: 16rAAAAAAAA.
	om unalignedLongAt: 3 put: 16r11223344.
	self assert: (om unalignedLongAt: 0) equals: 16r44AAAAAA.
	self assert: (om unalignedLongAt: 4) equals: 16rAA112233.
	self assert: (om unalignedLongAt: 3) equals: 16r11223344.
	om := Spur64BitMMLECoSimulator new allocateMemoryOfSize: 32.
	om unalignedLongAt: 3 put: 16r1122334455667788.
	self assert: (om unalignedLongAt: 0) equals: 16r4455667788000000.
	self assert: (om unalignedLongAt: 8) equals: 16r112233.
	self assert: (om unalignedLongAt: 3) equals: 16r1122334455667788.
	om longAt: 0 put: 16rAAAAAAAAAAAAAAAA.
	om longAt: 8 put: 16rAAAAAAAAAAAAAAAA.
	om unalignedLongAt: 3 put: 16r1122334455667788.
	self assert: (om unalignedLongAt: 0) equals: 16r4455667788AAAAAA.
	self assert: (om unalignedLongAt: 8) equals: 16rAAAAAAAAAA112233.
	self assert: (om unalignedLongAt: 3) equals: 16r1122334455667788.
	(Smalltalk classNamed: #DoubleWordArray) ifNotNil:
		[om := Spur64BitMMLECoSimulatorFor64Bits new allocateMemoryOfSize: 32.
		 om unalignedLongAt: 3 put: 16r1122334455667788.
		 self assert: (om unalignedLongAt: 0) equals: 16r4455667788000000.
		 self assert: (om unalignedLongAt: 8) equals: 16r112233.
		 self assert: (om unalignedLongAt: 3) equals: 16r1122334455667788.
		 om longAt: 0 put: 16rAAAAAAAAAAAAAAAA.
		 om longAt: 8 put: 16rAAAAAAAAAAAAAAAA.
		 om unalignedLongAt: 3 put: 16r1122334455667788.
		 self assert: (om unalignedLongAt: 0) equals: 16r4455667788AAAAAA.
		 self assert: (om unalignedLongAt: 8) equals: 16rAAAAAAAAAA112233.
		 self assert: (om unalignedLongAt: 3) equals: 16r1122334455667788]
]
