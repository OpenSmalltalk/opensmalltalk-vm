Class {
	#name : #VMFrameBuilderForTest,
	#superclass : #Object,
	#instVars : [
		'test',
		'method',
		'context',
		'receiver',
		'args',
		'stack'
	],
	#category : #VMMakerTests
}

{ #category : #accessing }
VMFrameBuilderForTest >> args [
	^ args
]

{ #category : #accessing }
VMFrameBuilderForTest >> args: anObject [
	args := anObject
]

{ #category : #building }
VMFrameBuilderForTest >> buildFrame [
	^ test
		makeBaseFrameWithMethod: method
		context: context
		receiver: receiver
		args: args
		andStack: stack
]

{ #category : #accessing }
VMFrameBuilderForTest >> context [
	^ context
]

{ #category : #accessing }
VMFrameBuilderForTest >> context: anObject [
	context := anObject
]

{ #category : #initialization }
VMFrameBuilderForTest >> initializeForTest: aVMByteCodesTest [ 
	test := aVMByteCodesTest.
	method := test memory nilObject.
	context := test memory nilObject.
	receiver := test memory nilObject.
	args := OrderedCollection new.
	stack := OrderedCollection new.
]

{ #category : #accessing }
VMFrameBuilderForTest >> method [
	^ method
]

{ #category : #accessing }
VMFrameBuilderForTest >> method: anObject [
	method := anObject
]

{ #category : #accessing }
VMFrameBuilderForTest >> receiver [
	^ receiver
]

{ #category : #accessing }
VMFrameBuilderForTest >> receiver: anObject [
	receiver := anObject
]

{ #category : #accessing }
VMFrameBuilderForTest >> stack [
	^ stack
]

{ #category : #accessing }
VMFrameBuilderForTest >> stack: anObject [
	stack := anObject
]

{ #category : #accessing }
VMFrameBuilderForTest >> test [
	^ test
]

{ #category : #accessing }
VMFrameBuilderForTest >> test: anObject [
	test := anObject
]
