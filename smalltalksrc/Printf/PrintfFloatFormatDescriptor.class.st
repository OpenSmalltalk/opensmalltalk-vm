Class {
	#name : #PrintfFloatFormatDescriptor,
	#superclass : #PrintfNumberFormatDescriptor,
	#category : #Printf
}

{ #category : #rendering }
PrintfFloatFormatDescriptor >> applyOperator: object [ 
	"Number is the only valid class"

	| string |
	string := self zeroPaddedStringOfBase: (('aA' includes: operator)
												ifTrue: [16]
												ifFalse: [10])
				forFloat: object asFloat.
	string := string copyFrom: 1 to: ((string indexOf: $.) + (precision = 0
						ifTrue: [-1]
						ifFalse: [self precision]) min: string size).
	(Cased includes: operator) ifTrue:
		[string := operator isLowercase
					ifTrue: [string asLowercase]
					ifFalse: [string asUppercase]].
	(space and: [object asFloat >= 0]) ifTrue:
		[string := ' ' , string].
	^(width ~= 0 and: [string size > width])
		ifTrue: [String new: width withAll: $*]
		ifFalse: [string]
]

{ #category : #private }
PrintfFloatFormatDescriptor >> digits [
	^ width == 0 ifTrue: [7] ifFalse: [width]
]

{ #category : #private }
PrintfFloatFormatDescriptor >> precision [
	^ precision isNil ifTrue: [1] ifFalse: [precision]
]

{ #category : #private }
PrintfFloatFormatDescriptor >> stringLength [
	^ width
]

{ #category : #rendering }
PrintfFloatFormatDescriptor >> zeroPaddedStringOfBase: base forFloat: aFloat [ 
	| stream |
	stream := String new writeStream.
	aFloat printOn: stream base: base.
	stream next: self precision-1 put: $0.
	^stream contents
]
