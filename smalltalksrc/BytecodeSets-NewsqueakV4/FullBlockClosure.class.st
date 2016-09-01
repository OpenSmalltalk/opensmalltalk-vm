"
I contain a sequence of operations. I am defined by Smalltalk expressions inside square brackets. I permit to defer the enclosed operations until I execute a variant of #value. I can have my own arguments and temporaries as a regular method, but I am also able to use external variables: my enclosing method or block temporaries, arguments and receiver.

examples :
[ 1 + 2 ] value
[ :arg | 
	| temp | 
	temp := arg. 
	temp ] value: 5
[ ^ 5 ] value

My return value corresponds to my final expression. A non local return (^) has the same effect as if I did not exist: it returns from my enclosing method, even if I'm nested in other blocks. 

Implementation:

A FullBlockClosure is a closure that can be independent of any outerContext if desired.  It has its own method (currently reusing the startpc inst var) and its own receiver.  outerContext can be either a MethodContext/Context or nil.

This closure design, implemented by Eliot Miranda and Clement Bera along the sista work aims to simplify the block closure model while enhacing its capabilities. It allows lazy compilation of closures and fast machine code dispatch in Cog's JIT, while allowing inlining of methods and blocks to be independent from their enclosing blocks.

At closure creation time, the bytecode specifies:
- the compiledBlock/compiledMethod to execute when executing this block's code (in the literal frame)
- if the receiver is the current receiver or a receiver passed on stack before the copied values.
- if the closure needs an outerContext. outerContexts are used for non local returns and debugging. Blocks with non local returns have to set their outerContext. For other blocks (97% of blocks), it's a trade-off between performance and debuggability.

Instance Variables
	outerContext:			<Context/MethodContext|nil> 
	compiledBlock(startpc) <CompiledMethod/CompiledBlock>
	numArgs				<SmallInteger> 
	receiver:				<Object>

"
Class {
	#name : #FullBlockClosure,
	#superclass : #BlockClosure,
	#type : #variable,
	#instVars : [
		'receiver'
	],
	#category : #'BytecodeSets-SistaV1'
}

{ #category : #private }
FullBlockClosure >> asContextWithSender: aContext [
	"Inner private support method for evaluation.  Do not use unless you know what you're doing."

	^(MethodContext newForMethod: self compiledBlock)
		setSender: aContext
		receiver: self receiver
		method: self compiledBlock
		closure: self
		startpc: self startpc;
		privRefresh
]

{ #category : #accessing }
FullBlockClosure >> compiledBlock [
	"To be able to inherit from BlockClosure"
	^ startpc
]

{ #category : #accessing }
FullBlockClosure >> compiledBlock: aCompiledMethod [
	"To be able to inherit from BlockClosure"
	startpc := aCompiledMethod
]

{ #category : #accessing }
FullBlockClosure >> home [
	^ outerContext ifNotNil: [ outerContext home ]
]

{ #category : #accessing }
FullBlockClosure >> method [
	^ self compiledBlock
]

{ #category : #accessing }
FullBlockClosure >> numArgs: n [
	numArgs := n
]

{ #category : #accessing }
FullBlockClosure >> numTemps [
	^ self compiledBlock numTemps
]

{ #category : #accessing }
FullBlockClosure >> outerContext: ctxt [
	outerContext := ctxt
]

{ #category : #accessing }
FullBlockClosure >> receiver [
	^ receiver
]

{ #category : #accessing }
FullBlockClosure >> receiver: anObject [
	receiver := anObject
]

{ #category : #accessing }
FullBlockClosure >> startpc [
	^ self compiledBlock initialPC
]

{ #category : #evaluating }
FullBlockClosure >> value [
	"Activate the receiver, creating a closure activation (MethodContext)
	 whose closure is the receiver and whose caller is the sender of this
	 message. Supply the copied values to the activation as its copied
	 temps. Primitive. Essential."
	<primitive: 207>
	| newContext |
	numArgs ~= 0 ifTrue:
		[self numArgsError: 0].
	false
		ifTrue: "Old code to simulate the closure value primitive on VMs that lack it."
			[newContext := self asContextWithSender: thisContext sender.
			thisContext privSender: newContext]
		ifFalse: [self primitiveFailed]
]

{ #category : #evaluating }
FullBlockClosure >> value: firstArg [
	"Activate the receiver, creating a closure activation (MethodContext)
	 whose closure is the receiver and whose caller is the sender of this
	 message. Supply the argument and copied values to the activation
	 as its argument and copied temps. Primitive. Essential."
	<primitive: 207>
	| newContext |
	numArgs ~= 1 ifTrue:
		[self numArgsError: 1].
	false
		ifTrue: "Old code to simulate the closure value primitive on VMs that lack it."
			[newContext := self asContextWithSender: thisContext sender.
			newContext at: 1 put: firstArg.
			thisContext privSender: newContext]
		ifFalse: [self primitiveFailed]
]

{ #category : #evaluating }
FullBlockClosure >> value: firstArg value: secondArg [
	"Activate the receiver, creating a closure activation (MethodContext)
	 whose closure is the receiver and whose caller is the sender of this
	 message. Supply the arguments and copied values to the activation
	 as its arguments and copied temps. Primitive. Essential."
	<primitive: 207>
	| newContext |
	numArgs ~= 2 ifTrue:
		[self numArgsError: 2].
	false
		ifTrue: "Old code to simulate the closure value primitive on VMs that lack it."
			[newContext := self asContextWithSender: thisContext sender.
			newContext at: 1 put: firstArg.
			newContext at: 2 put: secondArg.
			thisContext privSender: newContext]
		ifFalse: [self primitiveFailed]
]

{ #category : #evaluating }
FullBlockClosure >> value: firstArg value: secondArg value: thirdArg [
	"Activate the receiver, creating a closure activation (MethodContext)
	 whose closure is the receiver and whose caller is the sender of this
	 message. Supply the arguments and copied values to the activation
	 as its arguments and copied temps. Primitive. Essential."
	<primitive: 207>
	| newContext |
	numArgs ~= 3 ifTrue:
		[self numArgsError: 3].
	false
		ifTrue: "Old code to simulate the closure value primitive on VMs that lack it."
			[newContext := self asContextWithSender: thisContext sender.
			newContext at: 1 put: firstArg.
			newContext at: 2 put: secondArg.
			newContext at: 3 put: thirdArg.
			thisContext privSender: newContext]
		ifFalse: [self primitiveFailed]
]

{ #category : #evaluating }
FullBlockClosure >> value: firstArg value: secondArg value: thirdArg value: fourthArg [
	"Activate the receiver, creating a closure activation (MethodContext)
	 whose closure is the receiver and whose caller is the sender of this
	 message. Supply the arguments and copied values to the activation
	 as its arguments and copied temps. Primitive. Essential."
	<primitive: 207>
	| newContext |
	numArgs ~= 4 ifTrue:
		[self numArgsError: 4].
	false
		ifTrue: "Old code to simulate the closure value primitive on VMs that lack it."
			[newContext := self asContextWithSender: thisContext sender.
			newContext at: 1 put: firstArg.
			newContext at: 2 put: secondArg.
			newContext at: 3 put: thirdArg.
			newContext at: 4 put: fourthArg.
			thisContext privSender: newContext]
		ifFalse: [self primitiveFailed]
]

{ #category : #evaluating }
FullBlockClosure >> valueNoContextSwitch [
	"An exact copy of BlockClosure>>value except that this version will not preempt
	 the current process on block activation if a higher-priority process is runnable.
	 Primitive. Essential."
	<primitive: 209>
	numArgs ~= 0 ifTrue:
		[self numArgsError: 0].
	self primitiveFailed
]

{ #category : #evaluating }
FullBlockClosure >> valueNoContextSwitch: anArg [
	"An exact copy of BlockClosure>>value: except that this version will not preempt
	 the current process on block activation if a higher-priority process is runnable.
	 Primitive. Essential."
	<primitive: 209>
	numArgs ~= 1 ifTrue:
		[self numArgsError: 1].
	self primitiveFailed
]

{ #category : #evaluating }
FullBlockClosure >> valueWithArguments: anArray [
	"Activate the receiver, creating a closure activation (MethodContext)
	 whose closure is the receiver and whose caller is the sender of this
	 message. Supply the arguments in an anArray and copied values to
	 the activation as its arguments and copied temps. Primitive. Essential."
	<primitive: 208>
	| newContext |
	numArgs ~= anArray size ifTrue:
		[self numArgsError: anArray size].
	false
		ifTrue: "Old code to simulate the closure value primitive on VMs that lack it."
			[newContext := self asContextWithSender: thisContext sender.
			1 to: numArgs do:
				[:i| newContext at: i put: (anArray at: i)].
			thisContext privSender: newContext]
		ifFalse: [self primitiveFailed]
]
