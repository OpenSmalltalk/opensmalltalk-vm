Extension { #name : #Float }

{ #category : #'*VMMaker-Cog tests' }
Float >> asIEEE64BitWord [
	^((self basicAt: 1) bitShift: 32) + (self basicAt: 2)
]

{ #category : #'*VMMaker-interpreter simulator' }
Float >> asUnsignedInteger [
	self assert: self >= 0.
	"C conversion from float/double to integer is by dropping the fractional part"
	^self truncated
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccg: cg generateCoerceToOopFrom: aNode on: aStream [
	"N.B.  The is used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToFloatObjectFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccg: cg generateCoerceToValueFrom: aNode on: aStream [
	"N.B.  The could be used both for generation and simulation so answer the result (for interpretation)"
	^cg generateCoerceToFloatValueFrom: aNode on: aStream
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asFloatValueFrom: anInteger
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccgCanConvertFrom: anObject [

	^anObject isFloat
]

{ #category : #'*VMMaker-plugin generation' }
Float class >> ccgDeclareCForVar: aSymbolOrString [

	^'double ', aSymbolOrString
]

{ #category : #'*VMMaker-instance creation' }
Float class >> fromIEEE64BitWord: anInteger [
	| value |
	value := self basicNew: 2.
	value
		basicAt: 1 put: (anInteger bitShift: -32);
		basicAt: 2 put: (anInteger bitAnd: 16rFFFFFFFF).
	^value isFinite
		ifTrue: [value * 1.0] "reduce to SmallFloat64 if possible"
		ifFalse: [value]

	"[| r |
	 r := Random new.
	 100000 timesRepeat:
		[| h l f |
		h := (r next * 16r100000000) rounded bitAnd: 16rFFFFFFFF.
		l := (r next * 16r100000000) rounded bitAnd: 16rFFFFFFFF.
		f := Float fromIEEE64BitWord: (h bitShift: 32) + l.
		self assert: h = (f basicAt: 1).
		self assert: l = (f basicAt: 2)]] timeToRun"
]
