'From Squeak3.6beta of ''4 July 2003'' [latest update: #5373] on 7 August 2003 at 2:27:37 pm'!
"Change Set:		SlightlyFasterActivate-JMM
Date:			6 August 2003
Author:			johnmci@smalltalkconsulting.com

Alter activateNewMethod to simplify common subexpressions for the compiler and to simplify the two for loops so gcc can produce better assembler. This results in a 2% faster send/sec rate for powerpc"!


!Interpreter methodsFor: 'message sending' stamp: 'JMM 8/6/2003 09:48'!
activateNewMethod
	| newContext methodHeader initialIP tempCount nilOop where |
	methodHeader _ self headerOf: newMethod.
	newContext _ self allocateOrRecycleContext: (methodHeader bitAnd: LargeContextBit).

	initialIP _ ((LiteralStart + (self literalCountOfHeader: methodHeader)) * 4) + 1.
	tempCount _ (methodHeader >> 19) bitAnd: 16r3F.

	"Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores."

	where _  (self cCoerce: newContext to: 'char *') + BaseHeaderSize.
	self longAt: where + (SenderIndex << 2) put: activeContext.
	self longAt: where + (InstructionPointerIndex << 2) put: (self integerObjectOf: initialIP).
	self longAt: where + (StackPointerIndex << 2) put: (self integerObjectOf: tempCount).
	self longAt: where + (MethodIndex << 2) put: newMethod.

	"Copy the reciever and arguments..."
	0 to: argumentCount do:
		[:i | self longAt: where + ((ReceiverIndex+i) << 2) put: (self stackValue: argumentCount-i)].

	"clear remaining temps to nil in case it has been recycled"
	nilOop _ nilObj.
	argumentCount+1+ReceiverIndex to: tempCount+ReceiverIndex do:
		[:i | self longAt: where + (i << 2) put: nilOop].

	self pop: argumentCount + 1.
	reclaimableContextCount _ reclaimableContextCount + 1.
	self newActiveContext: newContext.! !

!Interpreter methodsFor: 'message sending' stamp: 'JMM 8/7/2003 14:27'!
internalActivateNewMethod
	| methodHeader newContext tempCount argCount2 needsLarge where |
	self inline: true.

	methodHeader _ self headerOf: newMethod.
	needsLarge _ methodHeader bitAnd: LargeContextBit.
	(needsLarge = 0 and: [freeContexts ~= NilContext])
		ifTrue: [newContext _ freeContexts.
				freeContexts _ self fetchPointer: 0 ofObject: newContext]
		ifFalse: ["Slower call for large contexts or empty free list"
				self externalizeIPandSP.
				newContext _ self allocateOrRecycleContext: needsLarge.
				self internalizeIPandSP].
	tempCount _ (methodHeader >> 19) bitAnd: 16r3F.

	"Assume: newContext will be recorded as a root if necessary by the
	 call to newActiveContext: below, so we can use unchecked stores."
	where _  (self cCoerce: newContext to: 'char *') + BaseHeaderSize.
	self longAt: where + (SenderIndex << 2) put: activeContext.
	self longAt: where + (InstructionPointerIndex << 2) put: (self integerObjectOf:
			(((LiteralStart + (self literalCountOfHeader: methodHeader)) * 4) + 1)).
	self longAt: where + (StackPointerIndex << 2) put: (self integerObjectOf: tempCount).
	self longAt: where + (MethodIndex << 2) put: newMethod.

	"Copy the reciever and arguments..."
	argCount2 _ argumentCount.
	0 to: argCount2 do:
		[:i | self longAt: where + ((ReceiverIndex+i) << 2) put: (self internalStackValue: argCount2-i)].

	"clear remaining temps to nil in case it has been recycled"
	methodHeader _ nilObj.  "methodHeader here used just as faster (register?) temp"
	argCount2+1+ReceiverIndex to: tempCount+ReceiverIndex do:
		[:i | self longAt: where + (i << 2) put: methodHeader].

	self internalPop: argCount2 + 1.
	reclaimableContextCount _ reclaimableContextCount + 1.
	self internalNewActiveContext: newContext.
 ! !

