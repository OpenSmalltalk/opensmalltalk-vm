"
Format description 
	syntax: %{flags}{width}{precision}{long}<operator> 
	
	flags 
		-		left flush 
		+		right flush 
		space	non-negative number are preceeded by a blank 
		#		display integer with a radix indicator (0=octal, 0x=hex, float have .) 
		0		0 is used as left padding character for numbers 
	width		minimum field width (rest is padded) 
	.precision	maximum field width or trailing digits 
	long		ignored 
	operator 
		c		display object as character 
		d		display as integer 
		e,E		float in scientific notation 
		f		display as float 
		g,G		display as f or e,E using least amount of space 
		o		display as octal value 
		s		display as string 
		u		display as unsigned 
		x,X		display as hex value 
	
"
Class {
	#name : #PrintfFormatString,
	#superclass : #Object,
	#instVars : [
		'format',
		'string',
		'outputStream'
	],
	#category : #Printf
}

{ #category : #examples }
PrintfFormatString class >> examples [
	self inform: ('Here is a string "%s".' printf: 'hello world').
	self inform: ('Here is a string "%s" and another shortened "%-14.7s".'
		printf: #('hello world' 'hello world')).

	self inform: ('Here is a number "%d".' printf: 42).
	self inform: ('Here is a string "%07.7d".' printf: 42).

	self inform: ('Here is a number "%e".' printf: 42.0).
	self inform: ('Here is a float "%e" and an integer "%d".' printf: #(42.0 42)).
	self inform: ('Here is a string "%013.5e".' printf: 42.1234567).

	self inform: ('Here is a %s string "%s" and the same shortened "%-14.7s" with left flush.\nThe new line has a number "%e" and a 0-padded limited precision one "%013.5e".'
		printf: ((Array with: 'long' with: 'hello world' with: 'hello world' with: 42.0) copyWith: 42.1234567)).
]

{ #category : #printf }
PrintfFormatString >> << object [ 
	"Render object according to next format descriptor in format. 
	Append it to string"
	"Format description 
	syntax: %{flags}{width}{precision}{long}<operator> 
	
	flags 
		-		left flush 
		+		right flush 
		space	non-negative number are preceeded by a blank 
		#		display integer with a radix indicator (0=octal, 0x=hex, float have .) 
		0		0 is used as left padding character for numbers 
	width		minimum field width (rest is padded) 
	.precision	maximum field width or trailing digits 
	long		ignored 
	operator 
		c		display object as character 
		d		display as integer 
		e,E		float in scientific notation 
		f		display as float 
		g,G		display as f or e,E using least amount of space 
		o		display as octal value 
		s		display as string 
		u		display as unsigned 
		x,X		display as hex value 
	"

	outputStream nextPutAll: string next.
	outputStream nextPutAll: (format next render: object).
	format atEnd ifTrue: 
		[format reset.
		outputStream nextPutAll: string next.
		string reset].
	^self string
]

{ #category : #private }
PrintfFormatString >> collectFormatDescriptorsAndStrings: formatStream [
	format := ReadWriteStream on: (Array new: 10).
	string := ReadWriteStream on: (Array new: 10).
	["copy actual formatstrings to format"
	 string nextPut: (self scanStringFrom: formatStream).
	 formatStream atEnd ifTrue:
		[self reset.
		 ^self].
	 "copy any nonformating text to string"
	 format nextPut: (PrintfFormatDescriptor scanFrom: formatStream)] repeat
]

{ #category : #printf }
PrintfFormatString >> f: aStream printf: arguments [
	"inst var string holds all text contained in the formatstring. %f blabla %d"
	| position savedStream |
	"inst var format is a stream of FormatDescriptors"
	self reset.
	savedStream := outputStream.
	outputStream := aStream.
	position := aStream position.
	[self process: arguments]
		ensure: [outputStream := savedStream].
	aStream flush.
	^aStream position - position
]

{ #category : #printf }
PrintfFormatString >> printf: arguments [
	"inst var string holds all text contained in the formatstring. %f blabla %d"

	"inst var format is a stream of FormatDescriptors"
	self reset.
	self process: arguments.
	^outputStream position
]

{ #category : #private }
PrintfFormatString >> process: arguments [
 	arguments asArgumentArrayForFormatString do: 
		[:object | 
		"put any text from the format string into outputStream"
		outputStream nextPutAll: string next. 
		 "get next FormatDescriptor from format and render object as specified"
		format atEnd ifFalse: [outputStream nextPutAll: (format next render: object)]].
        "any remainder is string, if so append to outputStream"
        string atEnd ifFalse: [outputStream nextPutAll: string next]
]

{ #category : #private }
PrintfFormatString >> reset [
        format reset.
        string reset.
        outputStream reset
]

{ #category : #private }
PrintfFormatString >> scanStringFrom: aStream [ 
	| newString |
	newString := (String new: 40) writeStream.
	[aStream atEnd]
		whileFalse: 
			[| next | 
			next := aStream next.
			next == $% ifTrue: [^newString contents].
			next == $\
				ifTrue: 
					[next := aStream next.
					next == $n ifTrue: [next := Character cr].
					next == $t ifTrue: [next := Character tab]].
			newString nextPut: next].
	^newString contents
]

{ #category : #'initialize-release' }
PrintfFormatString >> setFormat: aString [
	| formatStream |
	"copy actual formatstrings to format"
	"copy any nonformating text to string"
	outputStream := (String new: 20) writeStream.
	formatStream := ((aString copyReplaceAll: '\n' with: (String with: Character cr))
		copyReplaceAll: '\t'
		with: (String with: Character tab)) readStream.
	self collectFormatDescriptorsAndStrings: formatStream
]

{ #category : #printf }
PrintfFormatString >> string [
	^outputStream contents
]
