Class {
	#name : #VMMachineCodeFrameBuilderForTest,
	#superclass : #Object,
	#instVars : [
		'test',
		'returnAddress',
		'receiver',
		'arguments',
		'temporaries',
		'spouseContext',
		'method'
	],
	#category : #VMMakerTests
}

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> arguments [
	^ arguments
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> arguments: anObject [
	arguments := anObject
]

{ #category : #building }
VMMachineCodeFrameBuilderForTest >> buildFrame [

	| methodAddress |
	test createFramelessCallFrom: returnAddress receiver: receiver arguments: arguments.
	test machineSimulator hasLinkRegister 
		ifTrue: [ test pushAddress: returnAddress ].

	"These are pushed when activating the method"	
	test pushAddress: test machineSimulator framePointerRegisterValue.
	test machineSimulator framePointerRegisterValue: test machineSimulator smalltalkStackPointerRegisterValue.

	"Method can be nil or a cog method.
	If nil, put a nil address.
	Otherwise, use the address of the cog method"
	methodAddress := method
		ifNil: [ test memory nilObject ]
		ifNotNil: [ method address ].
		
	test pushAddress: (methodAddress bitOr: (self hasSpouseContext ifTrue: [1] ifFalse: [0])). "method"
	test pushAddress: (self hasSpouseContext
		ifTrue: [ spouseContext ]
		ifFalse: [ test memory nilObject ]). "context"

	test pushAddress: receiver.

	temporaries do: [ :aTemporary | test pushAddress: aTemporary ].
	
	test cogit needsFrame: true.
]

{ #category : #testing }
VMMachineCodeFrameBuilderForTest >> hasSpouseContext [

	^ spouseContext notNil
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> initializeWithTest: aTest [
	
	self test: aTest.
	receiver := test memory nilObject.
	returnAddress := test callerAddress.
	arguments := #().
	temporaries := #().
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> method [
	^ method
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> method: anObject [
	method := anObject
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> receiver [
	^ receiver
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> receiver: anObject [
	receiver := anObject
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> returnAddress [
	^ returnAddress
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> returnAddress: anObject [
	returnAddress := anObject
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> spouseContext [
	^ spouseContext
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> spouseContext: aContextOop [
	
	spouseContext := aContextOop
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> temporaries [
	^ temporaries
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> temporaries: anObject [
	temporaries := anObject
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> test [
	^ test
]

{ #category : #accessing }
VMMachineCodeFrameBuilderForTest >> test: anObject [
	test := anObject
]
