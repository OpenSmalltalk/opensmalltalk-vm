"
A FullBlockClosure is a closure that can be indepdendent of any outerContext if desired.  It has its own method (currently reusing the startpc inst var) and its own receiver.  outerContext can be either a MethodContext/Context or nil.

Instance Variables
	receiver:		<Object>

Here's an example (a chunk designed to be typed into the spurreader image with this class filed in, e.g. in the simulator), circa early 2016 for creating the recursive nfib example (|nfib|nfib:=nil.nfib:=[:n|n<=1ifTrue:[1]ifFalse:[(nfib value:n-1)+(nfib value:n-2)+1]].(1to:12)collect:nfib) using FullBlockClosure:

(| method closure |
method := (AssemblerMethod new
	methodClass: Object;
	selector: #nfib:;
	numArgs: 1;
	numTemps: 2;
	literal: #ifTrue:ifFalse:;
	pushTemporaryVariable: 0;
	pushSpecialConstant: 1;
	send: #<= super: false numArgs: 1;
	jump: 'L1' if: false;
	pushSpecialConstant: 1;
	jump: 'L2';
	label: 'L1';
	pushRemoteTemp: 0 inVectorAt: 1;
	pushTemporaryVariable: 0;
	pushSpecialConstant: 1;
	send: #- super: false numArgs: 1;
	send: #value: super: false numArgs: 1;
	pushRemoteTemp: 0 inVectorAt: 1;
	pushTemporaryVariable: 0;
	pushSpecialConstant: 2;
	send: #- super: false numArgs: 1;
	send: #value: super: false numArgs: 1;
	send: #+ super: false numArgs: 1;
	pushSpecialConstant: 1;
	send: #+ super: false numArgs: 1;
	label: 'L2';
	blockReturnTop;
	yourself) assemble.
closure := FullBlockClosure new: 1.
closure
	outerContext: nil;
	compiledBlock: method;
	numArgs: 1;
	receiver: nil.
closure at: 1 put: (Array with: closure).
(1 to: 12) collect: closure!)

Here is a second example:
(| methodBlock outerMethod closure |
methodBlock := (AssemblerMethod new
	methodClass: Object;
	selector: #inblock2;
	numTemps: 1;
	pushTemporaryVariable: 0;
	blockReturnTop;
	yourself) assemble.
outerMethod := (AssemblerMethod new
	encoder: EncoderForSistaV1 new;
	methodClass: Object;
	selector: #foo;
	literal: methodBlock;
	pushSpecialConstant: 1;
	pushFullClosure: 0 numCopied: 1;
	methodReturnTop;
	yourself) assemble.
closure := #rcvr withArgs: #() executeMethod: outerMethod.
{closure at: 1 . closure receiver . closure value} !)
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
