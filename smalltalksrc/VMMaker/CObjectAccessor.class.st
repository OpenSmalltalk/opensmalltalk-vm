"
I am used to simulate the indexed access to any object during plugin simulation.
"
Class {
	#name : #CObjectAccessor,
	#superclass : #Object,
	#instVars : [
		'object',
		'offset'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'instance creation' }
CObjectAccessor class >> on: anObject [
	^self new setObject: anObject
]

{ #category : #'pointer arithmetic' }
CObjectAccessor >> + increment [
	^self clone += increment
]

{ #category : #'pointer arithmetic' }
CObjectAccessor >> += increment [
	offset _ offset + increment
]

{ #category : #'pointer arithmetic' }
CObjectAccessor >> - decrement [
	^self clone -= decrement
]

{ #category : #'pointer arithmetic' }
CObjectAccessor >> -= decrement [
	offset _ offset - decrement
]

{ #category : #converting }
CObjectAccessor >> asOop: aClass [

	(aClass ccgCanConvertFrom: object)
		ifFalse: [^self error: 'incompatible object for autocoercion'].
	^object
]

{ #category : #converting }
CObjectAccessor >> asPluggableAccessor: accessorArray [
	^((CPluggableAccessor on: object) += offset)
		readBlock: accessorArray first
		writeBlock: accessorArray last
]

{ #category : #accessing }
CObjectAccessor >> at: index [
	^object instVarAt: index + offset + 1
]

{ #category : #accessing }
CObjectAccessor >> at: index put: value [
	^object instVarAt: index + offset + 1 put: value
]

{ #category : #converting }
CObjectAccessor >> coerceTo: cTypeString sim: interpreterSimulator [

	^ self
]

{ #category : #private }
CObjectAccessor >> getObject [
	^object
]

{ #category : #accessing }
CObjectAccessor >> object [

	^ object
]

{ #category : #accessing }
CObjectAccessor >> offset [

	^ offset

]

{ #category : #printing }
CObjectAccessor >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll:' on: ';
		print: object.
]

{ #category : #printing }
CObjectAccessor >> printOnStream: aStream [
	super printOnStream: aStream.
	aStream
		print:' on: ';
		write: object.
]

{ #category : #private }
CObjectAccessor >> setObject: anObject [
	object _ anObject.
	offset _ 0.
]
