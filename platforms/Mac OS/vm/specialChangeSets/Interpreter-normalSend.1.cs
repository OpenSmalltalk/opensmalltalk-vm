'From Squeak3.2gamma of 15 January 2002 [latest update: #4823] on 17 April 2002 at 11:59:50 am'!

!Interpreter methodsFor: 'message sending' stamp: 'JMM 12/29/2001 16:01'!
normalSend
	"Send a message, starting lookup with the receiver's class."
	"Assume: messageSelector and argumentCount have been set, and that the receiver and arguments have been pushed onto the stack,"
	"Note: This method is inlined into the interpreter dispatch loop."

	| rcvr |
	self inline: true.
	self sharedCodeNamed: 'commonSend' inCase: 131.

	rcvr _ self internalStackValue: argumentCount.
	lkupClass _ self fetchClassOf: rcvr.
	receiverClass _ lkupClass.
	self internalFindNewMethod.
	self internalExecuteNewMethod.
	self fetchNextBytecode.
! !

