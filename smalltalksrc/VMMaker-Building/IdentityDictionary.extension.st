Extension { #name : #IdentityDictionary }

{ #category : #'*VMMaker-accessing' }
IdentityDictionary >> keyAtNonIdentityValue: value [
	"Answer the key that is the external name for the argument, value. If 
	 there is none, answer the result of evaluating exceptionBlock.
	 Use =, not ==, so strings like 'this' can be found."
 
	^self keyAtNonIdentityValue: value ifAbsent: [self errorValueNotFound]
]

{ #category : #'*VMMaker-accessing' }
IdentityDictionary >> keyAtNonIdentityValue: value ifAbsent: exceptionBlock [
	"Answer the key that is the external name for the argument, value. If 
	 there is none, answer the result of evaluating exceptionBlock.
	 Use =, not ==, so strings like 'this' can be found."
 
	self associationsDo: 
		[:association | value = association value ifTrue: [^association key]].
	^exceptionBlock value
]
