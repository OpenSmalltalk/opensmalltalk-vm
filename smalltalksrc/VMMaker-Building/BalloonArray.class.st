"
BalloonArray keeps a shadow copy of its raw memory data in a Smalltalk array.  This allows support for C's inhomogeneous access, returning floats where Floats were stored, and negative ints where they were stored.  This ruse only works, of course where we have control over all the access.
"
Class {
	#name : #BalloonArray,
	#superclass : #CArray,
	#instVars : [
		'simArray',
		'simOffset'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'pointer arithmetic' }
BalloonArray >> += increment [

	super += increment.
	simOffset := simOffset + (increment / unitSize)
]

{ #category : #'pointer arithmetic' }
BalloonArray >> -= increment [

	super -= increment.
	simOffset := simOffset - (increment / unitSize)
]

{ #category : #'memory access' }
BalloonArray >> at: index [
	| value |
	value := simArray at: index + simOffset.
	"Debug only..."
	value ifNil:
		[self error: 'attempt to read an uninitialized field'.
		^ super at: index  "Maybe it was set in Squeak.  Return the raw value"].
	(self bitsOf: value) ~= (super at: index) ifTrue:
		[self error: 'inconsistent values: ', (self bitsOf: value) printString, ' vs ', (super at: index) printString].
	^value
]

{ #category : #'memory access' }
BalloonArray >> at: index put: value [

	super at: index put: (self bitsOf: value).
	^ simArray at: index + simOffset put: value.
	
]

{ #category : #'memory access' }
BalloonArray >> bitsOf: value [
	"Convert pos and neg ints and floats to 32-bit representations expected by C"

	value isInteger ifTrue:
		[value >= 0 ifTrue: [^ value].
		^ value + 16r80000000 + 16r80000000].
	value isFloat ifTrue:
		[^ value asIEEE32BitWord].
	self error: 'unexpected value for 32 bits'.
	^ 0
]

{ #category : #'memory access' }
BalloonArray >> floatAt: index [
	| value |
	value := self at: index.
	value isFloat ifFalse:
		[value = 0 ifTrue: [^ 0.0].
		self error: 'non-float was stored'.
		^ Float fromIEEE32Bit: value].
	^ value
]

{ #category : #'memory access' }
BalloonArray >> floatAt: index put: value [

	value isFloat
		ifFalse: [self error: 'inconsistent values'].
	^ self at: index put: value
]

{ #category : #'memory access' }
BalloonArray >> intAt: index [
	| value |
	value := self at: index.
	value isInteger
		ifFalse: [self error: 'inconsistent values'].
	^ value
]

{ #category : #'memory access' }
BalloonArray >> intAt: index put: value [

	value isInteger
		ifFalse: [self error: 'inconsistent values'].
	^ self at: index put: value
]

{ #category : #'memory access' }
BalloonArray >> setSimArray: anArray [
	simArray := anArray.
	"Now sync the contents of the simArray with the actual work buffer.
	 The issue here is that whether an element is an in teger or a float depends
	 on how the BalloonArrayPlugin accesses the workBuffer; hence we look at
	 the existing values in simArray to find that interpretation."
	simOffset ifNil:
		[simOffset := 1].
	0 to: anArray size - 1 do:
		[:i| 
		 anArray
			at: i + simOffset
			put: ((anArray at: i + simOffset) isFloat
					ifTrue: [(Float fromIEEE32Bit: (super at: i))]
					ifFalse: [super at: i])]
]
