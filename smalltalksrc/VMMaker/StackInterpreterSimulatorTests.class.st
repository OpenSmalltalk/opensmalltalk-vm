Class {
	#name : #StackInterpreterSimulatorTests,
	#superclass : #TestCase,
	#category : 'VMMaker-Tests'
}

{ #category : #tests }
StackInterpreterSimulatorTests >> testEmptySimulatorCanCloneSimulation [
	self shouldnt:
			[(StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager))
				cloneSimulation cloneSimulation]
		raise: Error
]

{ #category : #tests }
StackInterpreterSimulatorTests >> testEmptySimulatorCloneCanLoadImage [
	self shouldnt:
			[(StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager))
				cloneSimulation
					openOn: SpurImageTestResource imageNameForTests extraMemory: 0]
		raise: Error
]

{ #category : #tests }
StackInterpreterSimulatorTests >> testHackBits [
	"Test that the hackBits plumbing, used for display update in the
	 simulated ioShow:D:i:s:p:l:a:y:, works for the underlying memory classes."
	| mem32 mem64 disp32 disp64 hack32 hack64 |
	mem32 := LittleEndianBitmap new: 65536 / 4.
	mem64 := DoubleWordArray new: 65536 / 8.
	1 to: 65536 by: 8 do:
		[:i|
		mem32
			unsignedLong64At: i
			put: ((i // 8) even
					ifTrue: [16r5555555555555555]
					ifFalse: [16rAAAAAAAAAAAAAAAA]).
		mem64
			unsignedLong64At: i
			put: ((i // 8) even
					ifTrue: [16r5555555555555555]
					ifFalse: [16rAAAAAAAAAAAAAAAA])].
	self assert: (mem32 copy changeClassTo: ByteArray) = (mem64 copy changeClassTo: ByteArray).
	hack32 := Form new hackBits: mem32.
	hack64 := Form new hackBits: mem64.
	disp32 := Form new hackBits: (ByteArray new: 65536).
	disp64 := Form new hackBits: (ByteArray new: 65536).
	disp32
		copy: (0 @ 0 extent: 4 @ (65536 / 4))
		from: 0 @ 0
		in: hack32
		rule: Form over.
	disp64
		copy: (0 @ 0 extent: 4 @ (65536 / 4))
		from: 0 @ 0
		in: hack64
		rule: Form over.
	1 to: 65536 by: 8 do:
		[:i|
		self assert: ((i // 8) even
						ifTrue: [16r5555555555555555]
						ifFalse: [16rAAAAAAAAAAAAAAAA])
			equals: (disp32 bits unsignedLong64At: i).
		self assert: ((i // 8) even
						ifTrue: [16r5555555555555555]
						ifFalse: [16rAAAAAAAAAAAAAAAA])
			equals: (disp64 bits unsignedLong64At: i)]
	
]

{ #category : #tests }
StackInterpreterSimulatorTests >> testSimulatorCanReloadImage [
	self shouldnt:
			[(StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager))
				openOn: SpurImageTestResource imageNameForTests extraMemory: 0;
				openOn: SpurImageTestResource imageNameForTests extraMemory: 0]
		raise: Error
]
