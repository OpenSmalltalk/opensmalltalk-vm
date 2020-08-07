Class {
	#name : #PrintfFormatDescriptor,
	#superclass : #Object,
	#instVars : [
		'flush',
		'width',
		'precision'
	],
	#classVars : [
		'Flags',
		'Operators'
	],
	#category : #Printf
}

{ #category : #'class initialization' }
PrintfFormatDescriptor class >> initialize [
	"PrintfFormatDescriptor initialize"
	Operators := Dictionary new.
	Operators at: $P put: #PrintStringFormatDescriptor.
	Operators at: $c put: #PrintfCharacterFormatDescriptor.
	Operators at: $s put: #PrintfStringFormatDescriptor.
	#($d $o $u $x $X $p)
		do: [:operator | Operators at: operator put: #PrintfNumberFormatDescriptor].
	#($e $E $f $g $G $a $A)
		do: [:operator | Operators at: operator put: #PrintfFloatFormatDescriptor].

	Flags := Dictionary new.
	Flags at: $- put: #leftFlush.
	Flags at: $+ put: #rightFlush.
	Flags at: $  put: #space.
	Flags at: $# put: #radix.
	Flags at: $0 put: #zero
]

{ #category : #'instance creation' }
PrintfFormatDescriptor class >> new [
	^ super new initialize
]

{ #category : #'instance creation' }
PrintfFormatDescriptor class >> newFrom: desc [
	| myself |
	myself := self new.
	myself perform: desc flush.
	myself width: desc width.
	myself precision: desc precision.
	^ myself
]

{ #category : #'instance creation' }
PrintfFormatDescriptor class >> scanFrom: stream [
	| desc |
	desc := self new.
	[Flags includesKey: stream peek]
		whileTrue: [desc := desc perform: (Flags at: stream next)].
	stream peek isDigit ifTrue: [desc width: (Integer readFrom: stream)].
	stream peek == $. ifTrue: [stream next. desc precision: (Integer readFrom: stream)].
	stream peek == $l ifTrue: [stream next].
	desc := desc operator: stream next.
	^ desc
]

{ #category : #rendering }
PrintfFormatDescriptor >> applyOperator: object [
	self subclassResponsibility
]

{ #category : #private }
PrintfFormatDescriptor >> flush [
	^ flush
]

{ #category : #'initialize-release' }
PrintfFormatDescriptor >> initialize [
	flush := #rightFlush.
	width := 0
]

{ #category : #scanning }
PrintfFormatDescriptor >> leftFlush [
	flush := #leftFlush
]

{ #category : #private }
PrintfFormatDescriptor >> operator: char [
	| myself |
	myself := (Smalltalk at: (Operators at: char)) newFrom: self.
	myself setOperator: char.
	^ myself
]

{ #category : #private }
PrintfFormatDescriptor >> padding [
	^ Character space
]

{ #category : #private }
PrintfFormatDescriptor >> precision [
	^ precision
]

{ #category : #private }
PrintfFormatDescriptor >> precision: anInteger [
	precision := anInteger
]

{ #category : #printing }
PrintfFormatDescriptor >> printOn: aStream [
	aStream nextPut: $%.
	flush == #leftFlush ifTrue: [aStream nextPut: $-]
]

{ #category : #printing }
PrintfFormatDescriptor >> printWidthOn: aStream [
	width ~= 0 ifTrue: [width printOn: aStream].
	precision isNil ifFalse: [aStream nextPut: $.. precision printOn: aStream]
]

{ #category : #scanning }
PrintfFormatDescriptor >> radix [
	^ (PrintfNumberFormatDescriptor newFrom: self) radix
]

{ #category : #rendering }
PrintfFormatDescriptor >> render: object [
	| string |
	string := self applyOperator: object.
	self stringLength ~= 0
		ifTrue: [ string := string copyFrom: 1 to: (self stringLength min: string size) ].
	width == 0
		ifTrue: [ ^ string ].
	^ (String new: width withAll: self padding)
		copyReplaceFrom: (self startIndexOfCopyReplaceWithStringSize: string size)
		to: (self stopIndexOfCopyReplaceWithStringSize: string size)
		with: string
]

{ #category : #scanning }
PrintfFormatDescriptor >> rightFlush [
	flush := #rightFlush
]

{ #category : #private }
PrintfFormatDescriptor >> setOperator: char [
]

{ #category : #scanning }
PrintfFormatDescriptor >> space [
	^ (PrintfNumberFormatDescriptor newFrom: self) space
]

{ #category : #rendering }
PrintfFormatDescriptor >> startIndexOfCopyReplaceWithStringSize: anInteger [

	|start|
	flush == #leftFlush ifTrue: [start := 1].
	flush == #rightFlush ifTrue: [start := width - anInteger + 1]. 
	^(start max: 1)

]

{ #category : #rendering }
PrintfFormatDescriptor >> stopIndexOfCopyReplaceWithStringSize: anInteger [

	| stop |
	flush == #leftFlush ifTrue: [stop := anInteger].
	flush == #rightFlush ifTrue: [stop := width]. 
	^stop min: width
]

{ #category : #private }
PrintfFormatDescriptor >> stringLength [
	^ precision isNil ifTrue: [0] ifFalse: [precision]
]

{ #category : #private }
PrintfFormatDescriptor >> width [
	^ width
]

{ #category : #private }
PrintfFormatDescriptor >> width: anInteger [
	width := anInteger
]

{ #category : #scanning }
PrintfFormatDescriptor >> zero [
	^ (PrintfNumberFormatDescriptor newFrom: self) zero
]
