"
I am used to simulate the indexed access to arrays during plugin simulation.
"
Class {
	#name : #CArrayAccessor,
	#superclass : #CObjectAccessor,
	#category : #'Slang-Types'
}

{ #category : #comparing }
CArrayAccessor >> < other [

	^ (object == other object) and: [offset < other offset].
]

{ #category : #comparing }
CArrayAccessor >> <= other [

	^ (object == other object) and: [offset <= other offset].
]

{ #category : #comparing }
CArrayAccessor >> > other [

	^ (object == other object) and: [offset > other offset].
]

{ #category : #comparing }
CArrayAccessor >> >= other [

	^ (object == other object) and: [offset >= other offset].
]

{ #category : #accessing }
CArrayAccessor >> at: index [
	^object at: index + offset + 1
]

{ #category : #accessing }
CArrayAccessor >> at: index ifAbsent: aBlock [
	"This is a simulation-time-only convenience..."
	^object at: index + offset + 1 ifAbsent: aBlock
]

{ #category : #accessing }
CArrayAccessor >> at: index put: value [
	^object at: index + offset + 1 put: value
]

{ #category : #accessing }
CArrayAccessor >> byteAt: index [
	^object byteAt: index + offset + 1
]

{ #category : #accessing }
CArrayAccessor >> cPtrAsOop [

	offset = 0 ifFalse: [self error: 'offset must be zero'].
	^object
]

{ #category : #accessing }
CArrayAccessor >> floatAt: index [ 
	^ (self at: index) isFloat
		ifTrue: [self at: index]
		ifFalse: [Float
				fromIEEE32Bit: (self at: index)]

]

{ #category : #accessing }
CArrayAccessor >> includes: anObject [

	^ object includes: anObject
]

{ #category : #accessing }
CArrayAccessor >> long32At: index [
	| idx |
	idx := (offset + index) // 4 + 1.
	"Note: This is a special hack for BitBlt."
	(idx = (object basicSize + 1)) ifTrue:[^0].
	^object basicAt: idx
]

{ #category : #accessing }
CArrayAccessor >> long32At: index put: value [
	^object basicAt: (offset + index) // 4 + 1 put: value
]

{ #category : #accessing }
CArrayAccessor >> longAt: index [
	| idx |
	idx := (offset + index) // 4 + 1.
	"Note: This is a special hack for BitBlt."
	(idx = (object basicSize + 1)) ifTrue:[^0].
	^object basicAt: idx
]

{ #category : #accessing }
CArrayAccessor >> longAt: index put: value [
	^object basicAt: (offset + index) // 4 + 1 put: value
]

{ #category : #accessing }
CArrayAccessor >> next [

	|val|
	val := self at: 0.
	offset := offset + 1.
	^val
]

{ #category : #accessing }
CArrayAccessor >> size [

	^object size
]
