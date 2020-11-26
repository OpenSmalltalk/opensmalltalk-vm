"
A CFloatArray is a subclass of CArray that provides access via C float or double values
"
Class {
	#name : #CFloatArray,
	#superclass : #CArray,
	#category : #'Slang-Types'
}

{ #category : #converting }
CFloatArray >> asNonFloatAccessor [
	| accessor |
	CArray adoptInstance: (accessor := self shallowCopy unitSize: 8).
	^accessor
]

{ #category : #accessing }
CFloatArray >> at: offset [
	| address |
	address := unitSize * offset + self ptrAddress.
	^unitSize >= 4
		ifTrue:
			[unitSize = 4
				ifTrue: [Float fromIEEE32Bit: (interpreter long32At: address)]
				ifFalse: [Float fromIEEE64BitWord: (interpreter long64At: address)]]
		ifFalse:
			[self error: 'unitSize must be 4 or 8']
]

{ #category : #accessing }
CFloatArray >> at: offset put: val [
	| address |
	address := unitSize * offset + self ptrAddress.
	^unitSize >= 4
		ifTrue:
			[unitSize = 4
				ifTrue: [interpreter long32At: address put: (val isFloat ifTrue: [val asIEEE32BitWord] ifFalse: [val])]
				ifFalse: [interpreter long64At: address put: (val isFloat ifTrue: [val asIEEE64BitWord] ifFalse: [val])]]
		ifFalse:
			[self error: 'unitSize must be 4 or 8']
]

{ #category : #converting }
CFloatArray >> coerceTo: cTypeString sim: interpreterSimulator [

	^cTypeString caseOf: {
		['float *']	-> [self shallowCopy unitSize: 4; yourself].
		['double *']	-> [self shallowCopy unitSize: 8; yourself] }
		otherwise: [self asNonFloatAccessor coerceTo: cTypeString sim: interpreterSimulator]
]
