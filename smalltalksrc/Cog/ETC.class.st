"
I am a quick-hack type-checker (Eliot's Type Checker) that answers a dictionary of receiver to selector sets for a given method.
"
Class {
	#name : #ETC,
	#superclass : #InstructionClient,
	#instVars : [
		'scanner',
		'blockEnd',
		'joinOffsets',
		'sends',
		'contextStack',
		'currentContext',
		'blockEndStack',
		'topIsVector'
	],
	#category : #'Cog-Scripts'
}

{ #category : #utilities }
ETC class >> sendsForMethod: aMethod [
	^(self new setMethod: aMethod) sends
]

{ #category : #utilities }
ETC class >> sendsToInstVar: instVarName in: class [
	"Answer all selectors sent to instVarName in class's methods"
	| idx ref selectors |
	idx := class instVarIndexFor: instVarName ifAbsent: [^Set new].
	ref := {#inst. idx}.
	selectors := Set new.
	class methodsDo:
		[:m| selectors addAll: ((self sendsForMethod: m) at: ref ifAbsent: [#()])].
	^selectors
]

{ #category : #'instruction decoding' }
ETC >> blockReturnTop [
	"Return Top Of Stack bytecode."
	currentContext pop.
	scanner pc < blockEnd
		ifTrue: [self doJoin]
		ifFalse: [currentContext := contextStack removeLast.
				blockEnd := blockEndStack removeLast]
]

{ #category : #'instruction decoding' }
ETC >> doDup [
	currentContext doDup
]

{ #category : #private }
ETC >> doJoin [
	scanner pc < blockEnd ifTrue:
		[currentContext instVarNamed: 'stackp' put: (joinOffsets at: scanner pc)]
]

{ #category : #'instruction decoding' }
ETC >> doPop [
	currentContext doPop
]

{ #category : #'instruction decoding' }
ETC >> jump: offset [
	"Unconditional Jump bytecode."
	offset > 0 ifTrue:
		[joinOffsets at: scanner pc + offset put: currentContext stackPtr.
		 self doJoin]
]

{ #category : #'instruction decoding' }
ETC >> jump: offset if: condition [ 
	"Conditional Jump bytecode."
	currentContext pop.
	offset > 0 ifTrue:
		[joinOffsets at: scanner pc + offset put: currentContext stackPtr]
]

{ #category : #'instruction decoding' }
ETC >> methodReturnConstant: value [
	currentContext isExecutingBlock
		ifTrue: [currentContext push: value.
				self blockReturnTop]
		ifFalse: [self doJoin]
]

{ #category : #'instruction decoding' }
ETC >> methodReturnReceiver [
	currentContext isExecutingBlock
		ifTrue: [self pushReceiver.
				self blockReturnTop]
		ifFalse: [self doJoin]
]

{ #category : #'instruction decoding' }
ETC >> methodReturnTop [
	currentContext isExecutingBlock
		ifTrue: [self blockReturnTop]
		ifFalse: [currentContext pop.
				self doJoin]
]

{ #category : #'instruction decoding' }
ETC >> popIntoLiteralVariable: anAssociation [
	currentContext pop
]

{ #category : #'instruction decoding' }
ETC >> popIntoReceiverVariable: offset [
	currentContext pop
]

{ #category : #'instruction decoding' }
ETC >> popIntoRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex [
	currentContext pop
]

{ #category : #'instruction decoding' }
ETC >> popIntoTemporaryVariable: offset [
	| vector |
	topIsVector
		ifTrue:
			[vector := currentContext top.
			 1 to: vector size do:
				[:i|
				vector
					at: i
					put: 'remote ', i printString,
						' @ ', (offset + 1) printString,
						' in ', currentContext startpc printString].
			 currentContext popIntoTemporaryVariable: offset]
		ifFalse:
			[currentContext pop]
]

{ #category : #'instruction decoding' }
ETC >> pushActiveContext [
	currentContext pushActiveContext
]

{ #category : #'instruction decoding' }
ETC >> pushClosureCopyNumCopiedValues: numCopied numArgs: numArgs blockSize: blockSize [
	"Push Closure bytecode.  Either compute the end of the block if this is
	 the block we're analysing, or skip it, adjusting the stack as appropriate."
	| blockClosure j |
	blockEndStack addLast: blockEnd.
	blockEnd := scanner pc + blockSize.
	contextStack addLast: currentContext.
	currentContext
		pc: scanner pc;
		pushClosureCopyNumCopiedValues: numCopied numArgs: numArgs blockSize: blockSize.
	blockClosure := currentContext top.
	currentContext := blockClosure asContext.
	1 to: numArgs do:
		[:i| currentContext push: 'blkarg', i printString].
	1 to: numCopied do:
		[:i| currentContext push: (blockClosure at: i)].
	j := numArgs + numCopied.
	[scanner willPushNil] whileTrue:
		[scanner interpretNextInstructionFor: self.
		 currentContext at: currentContext stackPtr put: 'blktmp', (j := j + 1) printString]

	"ETC sendsForMethod: (ETC compiledMethodAt: #pushClosureCopyNumCopiedValues:numArgs:blockSize:)"
]

{ #category : #'instruction decoding' }
ETC >> pushConsArrayWithElements: numElements [
	currentContext pushConsArrayWithElements: numElements
]

{ #category : #'instruction decoding' }
ETC >> pushConstant: value [
	currentContext pushConstant: value
]

{ #category : #'instruction decoding' }
ETC >> pushLiteralVariable: anAssociation [
	currentContext push: anAssociation
]

{ #category : #'instruction decoding' }
ETC >> pushNewArrayOfSize: numElements [
	currentContext pushNewArrayOfSize: numElements.
	scanner willStorePop ifTrue:
		[topIsVector := true.
		 scanner interpretNextInstructionFor: self.
		 topIsVector := false]
]

{ #category : #'instruction decoding' }
ETC >> pushReceiver [
	currentContext push: #self
]

{ #category : #'instruction decoding' }
ETC >> pushReceiverVariable: offset [
	currentContext push: {#inst. offset + 1}
]

{ #category : #'instruction decoding' }
ETC >> pushRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex [
	currentContext pushRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex
]

{ #category : #'instruction decoding' }
ETC >> pushTemporaryVariable: offset [
	currentContext pushTemporaryVariable: offset
]

{ #category : #'instruction decoding' }
ETC >> send: selector super: supered numArgs: numArgs [
	numArgs timesRepeat: [currentContext pop].
	currentContext pop ifNotNil:
		[:top|
		((top isArray and: [top size = 2 and: [top first == #inst]])
		 or: [top == #self]) ifTrue:
			[(sends at: top ifAbsentPut: [Set new]) add: selector]].
	currentContext push: 'send ', selector
]

{ #category : #results }
ETC >> sends [
	[scanner atEnd] whileFalse:
		[scanner interpretNextInstructionFor: self].
	^sends
]

{ #category : #'initialize-release' }
ETC >> setMethod: aCompiledMethod [
	scanner := InstructionStream new method: aCompiledMethod pc: aCompiledMethod initialPC.
	contextStack := OrderedCollection new.
	currentContext := Context
						sender: nil
						receiver: nil
						method: aCompiledMethod
						arguments: ((1 to: aCompiledMethod numArgs) collect:
										[:i| 'arg', i printString]).
	aCompiledMethod numArgs + 1 to: aCompiledMethod numTemps do:
		[:i| currentContext at: i put: 'tmp', (i - aCompiledMethod numArgs) printString].
	sends := Dictionary new.
	joinOffsets := Dictionary new.
	blockEndStack := OrderedCollection new.
	blockEnd := aCompiledMethod endPC.
	topIsVector := false
]
