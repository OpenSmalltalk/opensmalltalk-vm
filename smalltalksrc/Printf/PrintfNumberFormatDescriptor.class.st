Class {
	#name : #PrintfNumberFormatDescriptor,
	#superclass : #PrintfFormatDescriptor,
	#instVars : [
		'operator',
		'padding',
		'radix',
		'space'
	],
	#classVars : [
		'Base',
		'Cased',
		'Radix'
	],
	#category : #Printf
}

{ #category : #'class initialization' }
PrintfNumberFormatDescriptor class >> initialize [
	"PrintfNumberFormatDescriptor initialize"
	Base := Dictionary newFromPairs: #(	$d 10
											$o 8
											$p 16
											$u 10
											$x 16
											$X 16).

	Radix := Dictionary newFromPairs: #(	$d ''
											$o '0'
											$p '0x'
											$u ''
											$x '0x'
											$X '0X').

	Cased := 'AaEeFfGgXx'
]

{ #category : #'instance creation' }
PrintfNumberFormatDescriptor class >> newFrom: desc [
	desc class == self ifTrue: [^ desc].
	^ (super newFrom: desc) setPadding: desc padding
]

{ #category : #rendering }
PrintfNumberFormatDescriptor >> applyOperator: object [ 
	"Character and Number are the only valid classes"

	| number string |
	object ifNil: [^'-'].
	number := object asInteger.
	string := number printStringBase: self base.
	(radix or: [operator == $p]) ifTrue: [string := self radixString , string].
	(Cased includes: operator) ifTrue:
		[string := operator isLowercase
					ifTrue: [string asLowercase]
					ifFalse: [string asUppercase]].
	(space and: [operator == $d and: [number < 0]]) ifTrue:
		[string := ' ' , string].
	^ (width ~= 0 and: [string size > self stringLength])
		ifTrue: [String new: width withAll: $*]
		ifFalse: [string]
]

{ #category : #private }
PrintfNumberFormatDescriptor >> base [
	^ Base at: operator
]

{ #category : #'initialize-release' }
PrintfNumberFormatDescriptor >> initialize [
	super initialize.
	padding := $ .
	radix := false.
	space := false
]

{ #category : #private }
PrintfNumberFormatDescriptor >> padding [
	^ padding
]

{ #category : #printing }
PrintfNumberFormatDescriptor >> printOn: aStream [
	super printOn: aStream.
	padding == $0 ifTrue: [aStream nextPut: $0].
	radix ifTrue: [aStream nextPut: $#].
	space ifTrue: [aStream nextPut: $ ].
	self printWidthOn: aStream.
	aStream nextPut: operator
]

{ #category : #scanning }
PrintfNumberFormatDescriptor >> radix [
	radix := true
]

{ #category : #private }
PrintfNumberFormatDescriptor >> radixString [
	^ Radix at: operator
]

{ #category : #private }
PrintfNumberFormatDescriptor >> setOperator: char [
	operator := char
]

{ #category : #private }
PrintfNumberFormatDescriptor >> setPadding: paddingChar [
	padding := paddingChar
]

{ #category : #scanning }
PrintfNumberFormatDescriptor >> space [
	space := true
]

{ #category : #private }
PrintfNumberFormatDescriptor >> stringLength [
	^precision isNil
		ifTrue: [SmallInteger maxVal]
		ifFalse: [precision]
]

{ #category : #scanning }
PrintfNumberFormatDescriptor >> zero [
	padding := $0
]
