Class {
	#name : #StackInterpreterTests,
	#superclass : #TestCase,
	#category : #'VMMaker-Tests'
}

{ #category : #tests }
StackInterpreterTests >> testPointerTaggingDetagging [
	"Test the adding/removal of SmallInteger tags to memory adresses used in
	 StackInterpreter and StackInterpreterSimulator for married context management."

	"StackInterpreterTests new testPointerTaggingDetagging"

	{ StackInterpreterSimulatorLSB new. "StackInterpreterSimulatorMSB new" } do: "Need to add MSB soon"
		[:sis|
		({ SmallInteger minVal. SmallInteger minVal / 2. -1024. -4.
		    SmallInteger maxVal - 1. SmallInteger maxVal // 2. 4 } collect:
			[:n| n bitAnd: -4]) do:
				[:n| | tagged untagged |
				self assert: n \\ 4 = 0.
				self assert: (sis objectMemory isNonIntegerObject: n).
				tagged := sis withSmallIntegerTags: n.
				untagged := sis withoutSmallIntegerTags: tagged.
				self assert: (sis objectMemory isIntegerObject: tagged).
				self assert: untagged = n]]
]

{ #category : #tests }
StackInterpreterTests >> testUnalignedMemoryAccess [
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
	om := NewCoObjectMemorySimulator new allocateMemoryOfSize: 16.
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
]
