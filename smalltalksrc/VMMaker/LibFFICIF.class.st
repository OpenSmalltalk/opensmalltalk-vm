Class {
	#name : #LibFFICIF,
	#superclass : #Object,
	#instVars : [
		'address',
		'argumentTypes',
		'returnType',
		'libFFI'
	],
	#category : #'VMMaker-FFI'
}

{ #category : #accessing }
LibFFICIF >> address [
	^ address
]

{ #category : #accessing }
LibFFICIF >> address: anInteger [ 
	address := anInteger
]

{ #category : #accessing }
LibFFICIF >> argumentTypes: aCollection [ 
	argumentTypes := aCollection
]

{ #category : #accessing }
LibFFICIF >> libFFI: aLibFFI [ 
	libFFI := aLibFFI
]

{ #category : #accessing }
LibFFICIF >> numberArguments [
	
	^ argumentTypes size
]

{ #category : #testing }
LibFFICIF >> parametersToSmalltalk: aCArrayAccessor [ 
	
	^ argumentTypes collect: [ :e | 1halt ].
]

{ #category : #accessing }
LibFFICIF >> returnType [

	^ returnType
]

{ #category : #accessing }
LibFFICIF >> returnType: aLibFFIType [ 
	returnType := aLibFFIType
]
