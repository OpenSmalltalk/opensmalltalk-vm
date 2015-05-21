Extension { #name : #ArrayedCollection }

{ #category : #'*VMMaker-plugin generation' }
ArrayedCollection class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	self instSize > 0 ifTrue: 
		[self error: 'cannot auto-coerce arrays with named instance variables'].
	^cg generateCoerceToObjectFromPtr: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
ArrayedCollection class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg 
		generateCoerceToPtr: (self ccgDeclareCForVar: '')
		fromObject: aNode on: aStream
]

{ #category : #'*VMMaker-simulated image growing' }
ArrayedCollection >> copyGrownBy: n [
	"Create a new collection containing all the elements from aCollection."

	^ (self class new: self size + n) replaceFrom: 1 to: self size with: self
]
