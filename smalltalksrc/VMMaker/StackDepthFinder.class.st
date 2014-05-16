Class {
	#name : #StackDepthFinder,
	#superclass : #InstructionStream,
	#instVars : [
		'stackp',
		'joins'
	],
	#category : #'VMMaker-Support'
}

{ #category : #decoding }
StackDepthFinder >> alternateInterpretNextInstructionFor: client [
	joins at: pc put: stackp.
	^super alternateInterpretNextInstructionFor: client
]

{ #category : #'instruction decoding' }
StackDepthFinder >> blockReturnTop [
	"Return Top Of Stack bytecode."
	self drop.
	self resetStackAfterBranchOrReturn
]

{ #category : #'instruction decoding' }
StackDepthFinder >> callPrimitive: primitiveIndex [
	"Call Primitive bytecode.  Effectively a no-op."
]

{ #category : #accessing }
StackDepthFinder >> containsMismatchedJoin [
	| end |
	end := self method endPC.
	[[self pc <= end]
		whileTrue:
			[((joins at: pc) notNil and: [stackp ~= (joins at: pc)]) ifTrue: [^true].
			 self interpretNextInstructionFor: self]]
		on: Notification
		do: [:ex|
			ex tag == #'bad join' ifTrue: [^true].
			ex pass].
	^false

	"StackDepthFinder methodDict values collect: [:m| (StackDepthFinder on: m) stackPointers]"
	"StackDepthFinder methodDict values select: [:m| (StackDepthFinder on: m) containsMismatchedJoin]"

	"| jumpers |
	 jumpers := CompiledMethod allInstances select:
						[:cm| | is |
						is := InstructionStream on: cm.
						is scanFor: [:ign| is willJump]].
	(jumpers select: [:cm| (StackDepthFinder on: cm) containsMismatchedJoin])
			asSortedCollection: [:cm1 :cm2| cm1 endPC <= cm2 endPC]"

	"| jumpers |
	 jumpers := CompiledMethod allInstances select:
						[:cm| | is |
						is := InstructionStream on: cm.
						is scanFor: [:ign| is willJump]].
	(jumpers reject: [:cm| (StackDepthFinder on: cm) containsMismatchedJoin])
			asSortedCollection: [:cm1 :cm2| cm1 endPC <= cm2 endPC]"

	"| jumpers result |
	 jumpers := CompiledMethod allInstances select:
						[:cm| | is |
						is := InstructionStream on: cm.
						is scanFor: [:ign| is willJump]].
	result := (jumpers select: [:cm| (StackDepthFinder on: cm) containsMismatchedJoin])
				asSortedCollection: [:cm1 :cm2| cm1 endPC <= cm2 endPC].
	 SystemNavigation new browseMessageList: (result collect: [:ea| ea methodReference]) name: 'mismatched joins'.
	 result"
]

{ #category : #'instruction decoding' }
StackDepthFinder >> doDup [
	"Duplicate Top Of Stack bytecode."
	self push
]

{ #category : #'stack depth' }
StackDepthFinder >> doJump: delta [
	delta < 0
		ifTrue:
			[(joins at: pc + delta) ~= stackp ifTrue: [(Notification new tag: #'bad join'; signal)]]
		ifFalse:
			[joins at: pc + delta put: stackp]
]

{ #category : #'instruction decoding' }
StackDepthFinder >> doPop [
	"Remove Top Of Stack bytecode."
	self drop
]

{ #category : #'stack depth' }
StackDepthFinder >> drop [
	stackp := stackp - 1
]

{ #category : #'stack depth' }
StackDepthFinder >> drop: n [
	stackp := stackp - n
]

{ #category : #decoding }
StackDepthFinder >> interpretNextInstructionFor: client [
	joins at: pc put: stackp.
	^super interpretNextInstructionFor: client
]

{ #category : #accessing }
StackDepthFinder >> joins [
	^joins
]

{ #category : #'instruction decoding' }
StackDepthFinder >> jump: delta [
	"Unconditional Jump bytecode."
	self doJump: delta.
	self resetStackAfterBranchOrReturn
]

{ #category : #'instruction decoding' }
StackDepthFinder >> jump: delta if: condition [ 
	"Conditional Jump bytecode."
	self drop.
	self doJump: delta
]

{ #category : #private }
StackDepthFinder >> method: method pc: startpc [
	super method: method pc: startpc.
	joins := Array new: method endPC.
	stackp := method numTemps
]

{ #category : #'instruction decoding' }
StackDepthFinder >> methodReturnConstant: value [ 
	"Return Constant bytecode."
	self resetStackAfterBranchOrReturn
]

{ #category : #'instruction decoding' }
StackDepthFinder >> methodReturnReceiver [
	"Return Self bytecode."
	self resetStackAfterBranchOrReturn
]

{ #category : #'instruction decoding' }
StackDepthFinder >> methodReturnTop [
	"Return Top Of Stack bytecode."
	self drop.
	self resetStackAfterBranchOrReturn
]

{ #category : #'instruction decoding' }
StackDepthFinder >> popIntoLiteralVariable: anAssociation [ 
	"Remove Top Of Stack And Store Into Literal Variable bytecode."
	self drop
]

{ #category : #'instruction decoding' }
StackDepthFinder >> popIntoReceiverVariable: offset [ 
	"Remove Top Of Stack And Store Into Instance Variable bytecode."
	self drop
]

{ #category : #'instruction decoding' }
StackDepthFinder >> popIntoRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex [
	"Remove Top Of Stack And Store Into Offset of Temp Vector bytecode."
	self drop
]

{ #category : #'instruction decoding' }
StackDepthFinder >> popIntoTemporaryVariable: offset [ 
	"Remove Top Of Stack And Store Into Temporary Variable bytecode."
	self drop
]

{ #category : #'stack depth' }
StackDepthFinder >> push [
	stackp := stackp + 1
]

{ #category : #'stack depth' }
StackDepthFinder >> push: n [
	stackp := stackp + n
]

{ #category : #'instruction decoding' }
StackDepthFinder >> pushActiveContext [
	"Push Active Context On Top Of Its Own Stack bytecode."
	self push
]

{ #category : #'instruction decoding' }
StackDepthFinder >> pushClosureCopyNumCopiedValues: numCopied numArgs: numArgs blockSize: blockSize [
	"Push Closure bytecode."
	numCopied = 0
		ifTrue: [self push]
		ifFalse: [numCopied > 1 ifTrue:
					[self drop: numCopied - 1]].
	self doJump: blockSize.
	stackp := numCopied + numArgs
]

{ #category : #'instruction decoding' }
StackDepthFinder >> pushConsArrayWithElements: numElements [
	"Push Cons Array of size numElements popping numElements items from the stack into the array bytecode."
	self drop: numElements - 1
]

{ #category : #'instruction decoding' }
StackDepthFinder >> pushConstant: value [
	"Push Constant, value, on Top Of Stack bytecode."
	self push
]

{ #category : #'instruction decoding' }
StackDepthFinder >> pushLiteralVariable: anAssociation [
	"Push Contents Of anAssociation On Top Of Stack bytecode."
	self push
]

{ #category : #'instruction decoding' }
StackDepthFinder >> pushNewArrayOfSize: numElements [ 
	"Push New Array of size numElements bytecode."
	self push
]

{ #category : #'instruction decoding' }
StackDepthFinder >> pushReceiver [
	"Push Active Context's Receiver on Top Of Stack bytecode."
	self push
]

{ #category : #'instruction decoding' }
StackDepthFinder >> pushReceiverVariable: offset [
	"Push Contents Of the Receiver's Instance Variable Whose Index 
	is the argument, offset, On Top Of Stack bytecode."
	self push
]

{ #category : #'instruction decoding' }
StackDepthFinder >> pushRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex [
	"Push Contents at Offset in Temp Vector bytecode."
	self push
]

{ #category : #'instruction decoding' }
StackDepthFinder >> pushTemporaryVariable: offset [
	"Push Contents Of Temporary Variable Whose Index Is the 
	argument, offset, On Top Of Stack bytecode."
	self push
]

{ #category : #'stack depth' }
StackDepthFinder >> resetStackAfterBranchOrReturn [
	pc <= joins size ifTrue:
		[(joins at: pc) ifNil:
			["We would like to raise an error here, but we can't because the bytecode
			  compiler doesn't remove dead code.  e.g. the following doesn't reach ^nil
			  but is legal Smalltalk:
				self foo
					ifTrue: [^self bar]
					ifFalse: [^self baz].
				^nil"
				^self].
		 stackp := joins at: pc]
]

{ #category : #'instruction decoding' }
StackDepthFinder >> send: selector super: supered numArgs: numArgs [
	"Send Message With Selector, selector, bytecode. The argument, 
	supered, indicates whether the receiver of the message is specified with 
	'super' in the source method. The arguments of the message are found in 
	the top numArguments locations on the stack and the receiver just 
	below them."
	self drop: numArgs
]

{ #category : #accessing }
StackDepthFinder >> stackPointerAt: aPC [ 
	[pc < aPC] whileTrue:
		[self interpretNextInstructionFor: self].
	^pc = aPC ifTrue: [stackp]
]

{ #category : #accessing }
StackDepthFinder >> stackPointers [
	"Collect the stack depth for each bytecode in the method.
	 For the convenience of clients, write the stack depth for extended bytecodes
	 to the bytecode pc, as well as the bytecocdes' extensions' pcs."
	| method encoderClass stackPointers end |
	stackPointers :=  Array new: (end := (method := self method) endPC).
	encoderClass := method encoderClass.
	[pc <= end] whileTrue:
		[stackPointers at: pc put: stackp.
		 encoderClass extensionsAt: pc in: method into:
			[:extA :extB :delta|
			delta > 0 ifTrue:
				[stackPointers at: pc + delta put: stackp]].
		 self interpretNextInstructionFor: self].
	^stackPointers
]

{ #category : #accessing }
StackDepthFinder >> stackp [
	^stackp
]

{ #category : #'instruction decoding' }
StackDepthFinder >> storeIntoLiteralVariable: anAssociation [ 
	"Store Top Of Stack Into Literal Variable Of Method bytecode."

]

{ #category : #'instruction decoding' }
StackDepthFinder >> storeIntoReceiverVariable: offset [ 
	"Store Top Of Stack Into Instance Variable Of Method bytecode."

]

{ #category : #'instruction decoding' }
StackDepthFinder >> storeIntoRemoteTemp: remoteTempIndex inVectorAt: tempVectorIndex [
	"Store Top Of Stack And Store Into Offset of Temp Vector bytecode."
]

{ #category : #'instruction decoding' }
StackDepthFinder >> storeIntoTemporaryVariable: offset [ 
	"Store Top Of Stack Into Temporary Variable Of Method bytecode."

]
