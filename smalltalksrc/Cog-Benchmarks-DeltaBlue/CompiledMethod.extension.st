Extension { #name : #CompiledMethod }

{ #category : #'*Cog-method prototypes' }
CompiledMethod class >> CompiledMethodclassOLDSQUEAKPROTOTYPEnewBytes: numberOfBytes trailerBytes: trailer nArgs: nArgs nTemps: nTemps nStack: stackSize nLits: nLits primitive: primitiveIndex [
	"Answer an instance of me. The header is specified by the message 
	 arguments. The remaining parts are not as yet determined."
	| method |
	nTemps > 63 ifTrue:
		[^self error: 'Cannot compile -- too many temporary variables'].	
	nLits > 65535 ifTrue:
		[^self error: 'Cannot compile -- too many literals'].

	 method := self newMethod: numberOfBytes + trailer size
					header:    (nArgs bitShift: 24)
							+ (nTemps bitShift: 18)
							+ ((nTemps + stackSize) > SmallFrame ifTrue: [1 bitShift: 17] ifFalse: [0])
							+ nLits
							+ (primitiveIndex > 0 ifTrue: [1 bitShift: 16] ifFalse: [0]).
	1 to: trailer size do:  "Copy the source code trailer to the end"
		[:i | method at: method size - trailer size + i put: (trailer at: i)].
	^method
]

{ #category : #'*Cog-method prototypes' }
CompiledMethod class >> CompiledMethodclassOLDSQUEAKPROTOTYPEnewBytes: numberOfBytes trailerBytes: trailer nArgs: nArgs nTemps: nTemps nStack: stackSize nLits: nLits primitive: primitiveIndex flag: flag [
	"Answer an instance of me. The header is specified by the message 
	 arguments. The remaining parts are not as yet determined."
	| method |
	nTemps > 63 ifTrue:
		[^self error: 'Cannot compile -- too many temporary variables'].	
	nLits > 65535 ifTrue:
		[^self error: 'Cannot compile -- too many literals'].

	 method := self newMethod: numberOfBytes + trailer size
					header:    (nArgs bitShift: 24)
							+ (nTemps bitShift: 18)
							+ ((nTemps + stackSize) > SmallFrame ifTrue: [1 bitShift: 17] ifFalse: [0])
							+ nLits
							+ (primitiveIndex > 0 ifTrue: [1 bitShift: 16] ifFalse: [0])
							+ (flag ifTrue: [1 bitShift: 29] ifFalse: [0]).
	1 to: trailer size do:  "Copy the source code trailer to the end"
		[:i | method at: method size - trailer size + i put: (trailer at: i)].
	^method
]

{ #category : #'*Cog-method prototypes' }
CompiledMethod class >> CompiledMethodclassPROTOTYPEnewBytes: numberOfBytes trailerBytes: trailer nArgs: nArgs nTemps: nTemps nStack: stackSize nLits: nLits primitive: primitiveIndex [
	"Answer an instance of me. The header is specified by the message 
	 arguments. The remaining parts are not as yet determined."
	nTemps > 63 ifTrue:
		[^self error: 'Cannot compile -- too many temporary variables'].	
	nLits > 65535 ifTrue:
		[^self error: 'Cannot compile -- too many literals'].

	^trailer
		createMethod: numberOfBytes
		class: self
		header:    (nArgs bitShift: 24)
				+ (nTemps bitShift: 18)
				+ ((nTemps + stackSize) > SmallFrame ifTrue: [1 bitShift: 17] ifFalse: [0])
				+ nLits
				+ (primitiveIndex > 0 ifTrue: [1 bitShift: 16] ifFalse: [0])
]

{ #category : #'*Cog-method prototypes' }
CompiledMethod class >> CompiledMethodclassPROTOTYPEnewBytes: numberOfBytes trailerBytes: trailer nArgs: nArgs nTemps: nTemps nStack: stackSize nLits: nLits primitive: primitiveIndex flag: flag [
	"Answer an instance of me. The header is specified by the message 
	 arguments. The remaining parts are not as yet determined."
	nTemps > 63 ifTrue:
		[^self error: 'Cannot compile -- too many temporary variables'].	
	nLits > 65535 ifTrue:
		[^self error: 'Cannot compile -- too many literals'].

	^trailer
		createMethod: numberOfBytes
		class: self
		header:    (nArgs bitShift: 24)
				+ (nTemps bitShift: 18)
				+ ((nTemps + stackSize) > SmallFrame ifTrue: [1 bitShift: 17] ifFalse: [0])
				+ nLits
				+ (primitiveIndex > 0 ifTrue: [1 bitShift: 16] ifFalse: [0])
				+ (flag ifTrue: [1 bitShift: 29] ifFalse: [0])
]
