Extension { #name : #String }

{ #category : #'*cmakevmmaker-extensions' }
String >> nameFormat: aDictionary [ 
	"format the receiver with aDictionary 
	 
	simplest example:  
	'foo {name} bar' format: {'name'->value}. 
	"
	| result stream |
	result := String new writeStream.
	stream := self readStream.

	[stream atEnd]
		whileFalse: [| currentChar | 
			currentChar := stream next.
			currentChar == ${
				ifTrue: [| expression | 
					expression := self getEnclosedExpressionFrom: stream.
					result nextPutAll: (aDictionary at: expression ifAbsent: [ 'UNDEFINED' ]) asString ]
				ifFalse: [
					currentChar == $\
						ifTrue: [
							stream atEnd
								ifFalse: [result nextPut: stream next]]
						ifFalse: [result nextPut: currentChar]]].

	^ result contents
]
