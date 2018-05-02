Class {
	#name : #CogStackPageSurrogate,
	#superclass : #Object,
	#instVars : [
		'address',
		'stackPages',
		'memory',
		'zoneBase',
		'zoneLimit'
	],
	#category : 'VMMaker-JITSimulation'
}

{ #category : #comparing }
CogStackPageSurrogate >> = aThing [
	^aThing class = self class
	and: [aThing address = address]
]

{ #category : #accessing }
CogStackPageSurrogate >> address [
	^address
]

{ #category : #'instance initialization' }
CogStackPageSurrogate >> address: theAddress simulator: aCoInterpreterSimulator zoneBase: base zoneLimit: limit [
	address := theAddress.
	stackPages := aCoInterpreterSimulator stackPages.
	memory := aCoInterpreterSimulator memory.
	zoneBase := base.
	zoneLimit := limit
]

{ #category : #testing }
CogStackPageSurrogate >> addressIsInPage: address [
	"For assert-checking"
	^self lastAddress < address and: [address < self baseAddress]
]

{ #category : #accessing }
CogStackPageSurrogate >> asInteger [
	^address
]

{ #category : #accessing }
CogStackPageSurrogate >> asIntegerPtr [
	^address
]

{ #category : #accessing }
CogStackPageSurrogate >> asUnsignedInteger [
	^address
]

{ #category : #accessing }
CogStackPageSurrogate >> asUnsignedIntegerPtr [
	^address
]

{ #category : #comparing }
CogStackPageSurrogate >> hash [
	^address hash
]

{ #category : #testing }
CogStackPageSurrogate >> isFree [
	^self baseFP = 0
]

{ #category : #printing }
CogStackPageSurrogate >> printOn: aStream [
	super printOn: aStream.
	aStream nextPut: $@; print: address; nextPut: $/.
	address printOn: aStream base: 16
]
