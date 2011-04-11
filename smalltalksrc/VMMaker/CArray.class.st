"
For Simulating the Interpreter only.  Coercing an Integer to a pointer (eg. cCoerce:to: 'char *') returns a CArray.  A CArray responds to at: and at:put: by reading/writing from the memory of the interpreter that sent the cCoerce:to: message in the first place.  A CArray responds to arithmetic by returning the new address.  Since longAt: sends // to its given address this is where the CArray converts back to a Integer for the memory fetch to work.
"
Class {
	#name : #CArray,
	#superclass : #Object,
	#instVars : [
		'interpreter',
		'arrayBaseAddress',
		'ptrOffset',
		'unitSize'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'int arithmetic' }
CArray >> * n [

	^ self ptrAddress * n
]

{ #category : #'int arithmetic' }
CArray >> + n [

	^ self ptrAddress + n
]

{ #category : #'pointer arithmetic' }
CArray >> += increment [

	ptrOffset := ptrOffset + increment
]

{ #category : #'int arithmetic' }
CArray >> - n [

	^ self ptrAddress - n
]

{ #category : #'pointer arithmetic' }
CArray >> -= decrement [

	ptrOffset := ptrOffset - decrement
]

{ #category : #'int arithmetic' }
CArray >> // n [

	^ self ptrAddress // n
]

{ #category : #'int arithmetic' }
CArray >> << n [

	^ self ptrAddress bitShift: n
]

{ #category : #'int arithmetic' }
CArray >> >> n [

	^ self ptrAddress bitShift: 0 - n
]

{ #category : #converting }
CArray >> adaptToNumber: rcvr andSend: selector [

	^ rcvr perform: selector with: self asInteger
]

{ #category : #converting }
CArray >> asCArrayAccessor [

	^ (CArrayAccessor on: self)
			+= -1   "Defeat the +1 offset in the accessor"
]

{ #category : #converting }
CArray >> asInteger [

	^ self ptrAddress
]

{ #category : #accessing }
CArray >> at: offset [

	ptrOffset = 0 ifFalse: [self error: 'only expect base address to receive at: message'].
	unitSize = 1 ifTrue: [^ interpreter byteAt: arrayBaseAddress + offset].
	unitSize = 4 ifTrue: [^ interpreter long32At: arrayBaseAddress + (offset * 4)].
	self halt: 'Can''t handle unitSize ', unitSize printString

]

{ #category : #accessing }
CArray >> at: offset put: val [

	ptrOffset = 0 ifFalse: [self error: 'only expect base address to receive at:put: message'].
	unitSize = 1 ifTrue: [^ interpreter byteAt: arrayBaseAddress + offset put: val].
	unitSize = 4 ifTrue: [^ interpreter long32At: arrayBaseAddress + (offset * 4) put: val].
	self halt: 'Can''t handle unitSize ', unitSize printString

]

{ #category : #'int arithmetic' }
CArray >> bitAnd: n [

	^ self ptrAddress bitAnd: n
]

{ #category : #'int arithmetic' }
CArray >> bitOr: n [

	^ self ptrAddress bitOr: n
]

{ #category : #'int arithmetic' }
CArray >> bitShift: n [

	^ self ptrAddress bitShift: n
]

{ #category : #converting }
CArray >> coerceTo: cTypeString sim: interpreterSimulator [

	cTypeString = 'int' ifTrue: [^ self ptrAddress].
	cTypeString = 'float *' ifTrue: [^ self asCArrayAccessor asFloatAccessor].
	cTypeString = 'int *' ifTrue: [^ self asCArrayAccessor asIntAccessor].
	cTypeString = 'unsigned' ifTrue: [^ self ptrAddress].
	^ self
]

{ #category : #converting }
CArray >> doesNotUnderstand: message [

	^ self asInteger perform: message selector withArguments: message arguments
]

{ #category : #accessing }
CArray >> floatAt: index [
	^ Float fromIEEE32Bit: (self at: index)
]

{ #category : #accessing }
CArray >> floatAt: index put: value [
	^ self at: index put: value asIEEE32BitWord
]

{ #category : #accessing }
CArray >> intAt: index [
	^ (self at: index) signedIntFromLong
]

{ #category : #accessing }
CArray >> intAt: index put: signedInt [
	^ self at: index put: signedInt signedIntToLong
]

{ #category : #private }
CArray >> interpreter: interpreterSimulator address: arrayAddress unitSize: numBytes [

	interpreter := interpreterSimulator.
	arrayBaseAddress := arrayAddress.
	unitSize := numBytes.
	ptrOffset := 0.

]

{ #category : #private }
CArray >> ptrAddress [

	^ arrayBaseAddress + ptrOffset
]
