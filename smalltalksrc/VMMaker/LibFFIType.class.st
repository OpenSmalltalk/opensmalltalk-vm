Class {
	#name : #LibFFIType,
	#superclass : #Object,
	#instVars : [
		'type',
		'size',
		'libFFI'
	],
	#pools : [
		'LibFFIConstants'
	],
	#category : #'VMMaker-FFI'
}

{ #category : #'type constants' }
LibFFIType class >> type: aType size: aSize on: aLibFFI [

	^ self new
		type: aType;
		size: aSize;
		libFFI: aLibFFI;
		yourself
]

{ #category : #testing }
LibFFIType >> fromSmalltalk: aNumber putInto: aCArrayAccessor [
	[ type ]
		caseOf: {([ FFI_TYPE_FLOAT ] -> [ |floatHolder| 
			floatHolder := libFFI interpreter cCoerce: aCArrayAccessor to: #'float *'.
			floatHolder at: 0 put: aNumber
			])}
		otherwise: [ self halt ]
]

{ #category : #accessing }
LibFFIType >> libFFI: aLibFFI [ 
	libFFI := aLibFFI
]

{ #category : #accessing }
LibFFIType >> size [
	^ size
]

{ #category : #accessing }
LibFFIType >> size: anObject [
	size := anObject
]

{ #category : #accessing }
LibFFIType >> type [
	^ type
]

{ #category : #accessing }
LibFFIType >> type: anObject [
	type := anObject
]
