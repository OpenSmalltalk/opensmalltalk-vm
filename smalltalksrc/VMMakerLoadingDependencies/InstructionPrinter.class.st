"
My instances can print the object code of a CompiledMethod in symbolic format. They print into an instance variable, stream, and uses oldPC to determine how many bytes to print in the listing. The variable method  is used to hold the method being printed.
"
Class {
	#name : #InstructionPrinter,
	#superclass : #InstructionClient,
	#instVars : [
		'method',
		'scanner',
		'stream',
		'oldPC',
		'innerIndents',
		'indent',
		'printPC',
		'indentSpanOfFollowingJump'
	],
	#category : #VMMakerLoadingDependencies
}

{ #category : #printing }
InstructionPrinter class >> on: aMethod [
	^self new method: aMethod.
	
]

{ #category : #printing }
InstructionPrinter class >> printClass: class [ 
	"Create a file whose name is the argument followed by '.bytes'. Store on 
	the file the symbolic form of the compiled methods of the class."
	| file |
	file := FileStream newFileNamed: class name , '.bytes'.
	class selectorsAndMethodsDo: 
		[:sel :m | 
		file cr; nextPutAll: sel; cr.
		(self on: m) printInstructionsOn: file].
	file close
	"InstructionPrinter printClass: Parser."

]

{ #category : #'instruction decoding' }
InstructionPrinter >> blockReturnConstant: value [ 
	"Print the Return Constant From Block bytecode."

	self print: 'blockReturn: ', value printString
]

{ #category : #'instruction decoding' }
InstructionPrinter >> blockReturnTop [
	"Print the Return Top Of Stack bytecode."

	self print: 'blockReturn'
]

{ #category : #'instruction decoding' }
InstructionPrinter >> callPrimitive: index [
	"Print the callPrimitive bytecode."

	self print: 'callPrimitive: ' , index printString
]

{ #category : #'instruction decoding' }
InstructionPrinter >> directedSuperSend: selector "<Symbol>" numArgs: numArgs [ "<SmallInteger>"
	self print: 'directedSuperSend: ' , (self stringForSelector: selector numArgs: numArgs)
]

{ #category : #'instruction decoding' }
InstructionPrinter >> doDup [
	"Print the Duplicate Top Of Stack bytecode."

	self print: 'dup'
]

{ #category : #'instruction decoding' }
InstructionPrinter >> doPop [
	"Print the Remove Top Of Stack bytecode."

	self print: 'pop'
]

{ #category : #accessing }
InstructionPrinter >> indent [

	^ indent ifNil: [0]
]

{ #category : #'initialize-release' }
InstructionPrinter >> indent: numTabs [

	indent := numTabs
]

{ #category : #'instruction decoding' }
InstructionPrinter >> jump: offset [
	"Print the Unconditional Jump bytecode."

	self print: 'jumpTo: ' , (scanner pc + offset) printString.
	indentSpanOfFollowingJump ifTrue:
		[indentSpanOfFollowingJump := false.
		 innerIndents atAll: (scanner pc to: scanner pc + offset - 1) put: (innerIndents at: scanner pc - 1) + 1]
]

{ #category : #'instruction decoding' }
InstructionPrinter >> jump: offset if: condition [ 
	"Print the Conditional Jump bytecode."

	self print: 
		(condition
			ifTrue: ['jumpTrue: ']
			ifFalse: ['jumpFalse: '])
			, (scanner pc + offset) printString
]

{ #category : #accessing }
InstructionPrinter >> method [
	^method.
]

{ #category : #accessing }
InstructionPrinter >> method: aMethod [
	method :=  aMethod.
	printPC := true.
	indentSpanOfFollowingJump := false
]

{ #category : #'instruction decoding' }
InstructionPrinter >> methodReturnConstant: value [ 
	"Print the Return Constant bytecode."

	self print: 'return: ' , value printString
]

{ #category : #'instruction decoding' }
InstructionPrinter >> methodReturnReceiver [
	"Print the Return Self bytecode."

	self print: 'returnSelf'
]

{ #category : #'instruction decoding' }
InstructionPrinter >> methodReturnTop [
	"Print the Return Top Of Stack bytecode."

	self print: 'returnTop'
]

{ #category : #'instruction decoding' }
InstructionPrinter >> popIntoLiteralVariable: anAssociation [ 
	"Print the Remove Top Of Stack And Store Into Literal Variable bytecode."

	self print: 'popIntoLit: ' , anAssociation key
]

{ #category : #'instruction decoding' }
InstructionPrinter >> popIntoReceiverVariable: offset [ 
	"Print the Remove Top Of Stack And Store Into Instance Variable 
	bytecode."

	self print: 'popIntoRcvr: ' , offset printString
]

{ #category : #'instruction decoding' }
InstructionPrinter >> popIntoRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex [
	self print: 'popIntoTemp: ', remoteTempIndex printString, ' inVectorAt: ', tempVectorIndex printString
]

{ #category : #'instruction decoding' }
InstructionPrinter >> popIntoTemporaryVariable: offset [ 
	"Print the Remove Top Of Stack And Store Into Temporary Variable 
	bytecode."

	self print: 'popIntoTemp: ' , offset printString
]

{ #category : #printing }
InstructionPrinter >> print: instruction [ 
	"Append to the receiver a description of the bytecode, instruction." 

	| code |
	stream tab: self indent.
	printPC ifTrue: [stream print: oldPC; space].
	stream tab: (innerIndents at: oldPC).
	stream nextPut: $<.
	oldPC to: scanner pc - 1 do: 
		[:i | 
		code := (method at: i) radix: 16.
		stream nextPut: 
			(code size < 2
				ifTrue: [$0]
				ifFalse: [code at: 1]).
		stream nextPut: code last; space].
	stream skip: -1.
	stream nextPut: $>.
	stream space.
	stream nextPutAll: instruction.
	stream cr.
	oldPC := scanner pc.
	"(InstructionPrinter compiledMethodAt: #print:) symbolic."

]

{ #category : #'initialize-release' }
InstructionPrinter >> printInstructionsOn: aStream [ 
	"Append to the stream, aStream, a description of each bytecode in the
	 instruction stream."
	
	| end |
	stream := aStream.
	scanner := InstructionStream on: method.
	end := method endPC.
	oldPC := scanner pc.
	innerIndents := Array new: end withAll: 0.
	[scanner pc <= end] whileTrue:
		[scanner interpretNextInstructionFor: self]
]

{ #category : #'initialize-release' }
InstructionPrinter >> printInstructionsOn: aStream do: aBlock [
	"Append to the stream, aStream, a description of each bytecode in the
	 instruction stream. Evaluate aBlock with the receiver, the scanner and
	 the stream after each instruction."

	| end |
	stream := aStream.
	scanner := InstructionStream on: method.
	end := method endPC.
	oldPC := scanner pc.
	innerIndents := Array new: end withAll: 0.
	[scanner pc <= end] whileTrue:
		[scanner interpretNextInstructionFor: self.
		 aBlock value: self value: scanner value: stream]
]

{ #category : #accessing }
InstructionPrinter >> printPC [
	^printPC
]

{ #category : #accessing }
InstructionPrinter >> printPC: aBoolean [
	printPC := aBoolean
]

{ #category : #'instruction decoding' }
InstructionPrinter >> pushActiveContext [
	"Print the Push Active Context On Top Of Its Own Stack bytecode."

	self print: 'pushThisContext: '
]

{ #category : #'instruction decoding' }
InstructionPrinter >> pushClosureCopyNumCopiedValues: numCopied numArgs: numArgs blockSize: blockSize [
	self print: 'closureNumCopied: ', numCopied printString
			, ' numArgs: ', numArgs printString
			, ' bytes ', scanner pc printString
			, ' to ', (scanner pc + blockSize - 1) printString.
	innerIndents
		atAll: (scanner pc to: scanner pc + blockSize - 1)
		put: (innerIndents at: scanner pc - 1) + 1
]

{ #category : #'instruction decoding' }
InstructionPrinter >> pushConsArrayWithElements: numElements [ 
	self print: 'pop ', numElements printString, ' into (Array new: ', numElements printString, ')'
]

{ #category : #'instruction decoding' }
InstructionPrinter >> pushConstant: obj [
	"Print the Push Constant, obj, on Top Of Stack bytecode."

	self print: (String streamContents:
				[:s |
				s nextPutAll: 'pushConstant: '.
				obj isVariableBinding
					ifTrue:
						[obj key
							ifNotNil: [s nextPutAll: '##'; nextPutAll: obj key]
							ifNil: [s nextPutAll: '###'; nextPutAll: obj value soleInstance name]]
					ifFalse:
						[obj isClosure
							ifTrue: [s nextPutAll: obj sourceString]
							ifFalse: [obj printOn: s]]]).

	obj isCompiledMethod ifTrue:
		[obj longPrintOn: stream indent: self indent + 2.
		^self]
]

{ #category : #printing }
InstructionPrinter >> pushFullClosure: aCompiledBlock numCopied: numCopied [
	| literalIndex |
	literalIndex := method literals identityIndexOf: aCompiledBlock.
	literalIndex = 0
		ifTrue:
			[self print: 'closureNumCopied: ', numCopied printString
				, ' numArgs: ', aCompiledBlock numArgs printString]
		ifFalse:
			[self print: 'pushFullClosure: (self literalAt: ', literalIndex printString,
						') numCopied: ', numCopied printString,
						' "numArgs: ', aCompiledBlock numArgs printString, '"']
]

{ #category : #'instruction decoding' }
InstructionPrinter >> pushLiteralVariable: anAssociation [
	"Print the Push Value Of anAssociation On Top Of Stack bytecode."

	self print: 'pushLitVar: ' , (anAssociation printStringLimitedTo: 64)
]

{ #category : #'instruction decoding' }
InstructionPrinter >> pushNewArrayOfSize: numElements [ 
	self print: 'push: (Array new: ', numElements printString, ')'
]

{ #category : #'instruction decoding' }
InstructionPrinter >> pushReceiver [
	"Print the Push Active Context's Receiver on Top Of Stack bytecode."

	self print: 'self'
]

{ #category : #'instruction decoding' }
InstructionPrinter >> pushReceiverVariable: offset [
	"Print the Push Contents Of the Receiver's Instance Variable Whose Index 
	is the argument, offset, On Top Of Stack bytecode."

	self print: 'pushRcvr: ' , offset printString
]

{ #category : #'instruction decoding' }
InstructionPrinter >> pushRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex [ 
	self print: 'pushTemp: ', remoteTempIndex printString, ' inVectorAt: ', tempVectorIndex printString
]

{ #category : #'instruction decoding' }
InstructionPrinter >> pushTemporaryVariable: offset [
	"Print the Push Contents Of Temporary Variable Whose Index Is the 
	argument, offset, On Top Of Stack bytecode."

	self print: 'pushTemp: ' , offset printString
]

{ #category : #'instruction decoding' }
InstructionPrinter >> send: selector super: supered numArgs: numArgs [
	"Print the Send Message With Selector, selector, bytecode. The argument, 
	supered, indicates whether the receiver of the message is specified with 
	'super' in the source method. The arguments of the message are found in 
	the top numArguments locations on the stack and the receiver just 
	below them."

	self print: (supered
				ifTrue: ['superSend: ']
				ifFalse: ['send: '])
			, (self stringForSelector: selector numArgs: numArgs)
]

{ #category : #'instruction decoding' }
InstructionPrinter >> storeIntoLiteralVariable: anAssociation [ 
	"Print the Store Top Of Stack Into Literal Variable Of Method bytecode."

	self print: 'storeIntoLit: ' , anAssociation key
]

{ #category : #'instruction decoding' }
InstructionPrinter >> storeIntoReceiverVariable: offset [ 
	"Print the Store Top Of Stack Into Instance Variable Of Method bytecode."

	self print: 'storeIntoRcvr: ' , offset printString
]

{ #category : #'instruction decoding' }
InstructionPrinter >> storeIntoRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex [ 
	self print: 'storeIntoTemp: ', remoteTempIndex printString, ' inVectorAt: ', tempVectorIndex printString
]

{ #category : #'instruction decoding' }
InstructionPrinter >> storeIntoTemporaryVariable: offset [ 
	"Print the Store Top Of Stack Into Temporary Variable Of Method 
	bytecode."

	self print: 'storeIntoTemp: ' , offset printString
]

{ #category : #printing }
InstructionPrinter >> stringForSelector: selector numArgs: numArgs [
	^(selector isSymbol and: [selector numArgs = numArgs])
		ifTrue: [selector]
		ifFalse: [selector printString
				, (numArgs = 1
					ifTrue: [' (1 arg)']
					ifFalse: [' (', numArgs printString, ' args)'])]
]

{ #category : #'instruction decoding' }
InstructionPrinter >> trapIfNotInstanceOf: behaviorOrArrayOfBehavior [
	"If the top of stack is not an instance of either the argument, or, if the argument is an Array,
	  any of the elements of the argument, send the class trap message to the current context."
	self print: 'trapIfNotInstanceOf: ', behaviorOrArrayOfBehavior printString
]
