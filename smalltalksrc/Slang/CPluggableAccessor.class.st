"
This class adds generalized block parameter access to C objects for vm simulation
"
Class {
	#name : #CPluggableAccessor,
	#superclass : #CArrayAccessor,
	#instVars : [
		'readBlock',
		'writeBlock',
		'objectSize'
	],
	#category : #'Slang-Types'
}

{ #category : #coercion }
CPluggableAccessor >> asInteger [
	^self
]

{ #category : #accessing }
CPluggableAccessor >> at: index [
	^readBlock value: object value: index + offset + 1
]

{ #category : #accessing }
CPluggableAccessor >> at: index put: value [
	^writeBlock value: object value: index + offset + 1 value: value
]

{ #category : #initialize }
CPluggableAccessor >> atBlock: rBlock atPutBlock: wBlock [
	readBlock := rBlock.
	writeBlock := wBlock
]

{ #category : #initialize }
CPluggableAccessor >> objectSize: n [
	objectSize := n
]

{ #category : #printing }
CPluggableAccessor >> printOn: aStream [
	super printOn: aStream.
	(object isNil and: [readBlock notNil or: [writeBlock notNil]]) ifTrue:
		[[aStream nextPutAll: ' in '; print: (readBlock home tempAt: 2) home]
			on: Error
			do: [:ex| ]]
]

{ #category : #accessing }
CPluggableAccessor >> size [
	^objectSize ifNil: [super size]
]
