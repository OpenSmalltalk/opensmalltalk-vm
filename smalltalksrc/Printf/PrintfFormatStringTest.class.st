Class {
	#name : #PrintfFormatStringTest,
	#superclass : #TestCase,
	#category : #Printf
}

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testFprintf [
	| stream expected |
	stream := String new writeStream.
	expected := 'Here is a long string "hello world" and the same shortened "hello w       " with left flush.\The new line has a number "42.0"\and a 0-padded limited precision one "0000042.12345".' withCRs.
	self assert: expected size equals: (stream f: 'Here is a %s string "%s" and the same shortened "%-14.7s" with left flush.\nThe new line has a number "%e"
and a 0-padded limited precision one "%013.5e".'
		printf: #('long' 'hello world' 'hello world' 42.0 42.1234567)).
	self assert: expected equals: stream contents
]

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testManyArguments [

	self assert: 'Here is a long string "hello world" and the same shortened "hello w       " with left flush.
The new line has a number "42.0" and a 0-padded limited precision one "0000042.12345".' equals: ('Here is a %s string "%s" and the same shortened "%-14.7s" with left flush.\nThe new line has a number "%e" and a 0-padded limited precision one "%013.5e".'
		printf: #('long' 'hello world' 'hello world' 42.0 42.1234567))
]

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testOneExponent [

	self assert: 'Here is a number "42.0".' equals: ('Here is a number "%e".' printf: 42.0).
]

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testOneExponentAndOneInteger [

	self assert: 'Here is a float "42.0" and an integer "42".' equals: ('Here is a float "%e" and an integer "%d".' printf: #(42.0 42)).
]

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testOneExponentWithLength [

	self assert: 'Here is a string "0000042.12345".' equals: ('Here is a string "%013.5e".' printf: 42.1234567).
]

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testOneInteger [

	self assert: 'Here is a number "42".' equals: ('Here is a number "%d".' printf: 42).
]

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testOneIntegerWithLength [

	self assert: 'Here is a string "0000042".' equals: ('Here is a string "%07.7d".' printf: 42).
]

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testOnePrintPointer [

	self assert: 'Here is a pointer "0x12345678".' equals: ('Here is a pointer "%p".' printf: 16r12345678)
]

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testOnePrintString [

	self assert: 'Here is a point "3@4".' equals: ('Here is a point "%P".' printf: 3@4)
]

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testOneString [

	self assert: 'Here is a string "hello world".' equals: ('Here is a string "%s".' printf: 'hello world')
]

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testOneStringWithLength [

	self assert:  'Here is a string "hello world" and another shortened "hello w       ".' equals: ('Here is a string "%s" and another shortened "%-14.7s".' printf: #('hello world' 'hello world'))
]

{ #category : #'as yet unclassified' }
PrintfFormatStringTest >> testReturnValue [

	self assert: 6+8 equals: ((PrintfFormatString new setFormat: 'hello %ld') printf: {12345678})
]
