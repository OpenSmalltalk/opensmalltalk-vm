'From Squeak3.2gamma of 15 January 2002 [latest update: #4823] on 17 April 2002 at 12:00:04 pm'!
"Change Set:		CheckInterruptsMoreOften-JMM
Date:			16 April 2002
Author:			John M McIntosh

Ask the mac VM, and perhaps other VMs to check for interrupts every 3ms versus 5ms. This gives better accuracy for Delay"!


!Interpreter methodsFor: 'initialization' stamp: 'JMM 4/16/2002 13:37'!
initializeInterpreter: bytesToShift
	"Initialize Interpreter state before starting execution of a new image."

	interpreterProxy _ self sqGetInterpreterProxy.
	self initializeObjectMemory: bytesToShift.
	self initCompilerHooks.
	self flushExternalPrimitives.

	activeContext	_ nilObj.
	theHomeContext	_ nilObj.
	method			_ nilObj.
	receiver		_ nilObj.
	messageSelector	_ nilObj.
	newMethod		_ nilObj.
	methodClass		_ nilObj.
	lkupClass		_ nilObj.
	receiverClass	_ nilObj.
	newNativeMethod		_ nilObj.

	self flushMethodCache.
	self loadInitialContext.
	interruptCheckCounter _ 0.
	interruptCheckCounterFeedBackReset _ 1000.
	interruptChecksEveryNms _ 3.
	nextPollTick _ 0.
	nextWakeupTick _ 0.
	lastTick _ 0.
	interruptKeycode _ 2094.  "cmd-."
	interruptPending _ false.
	semaphoresUseBufferA _ true.
	semaphoresToSignalCountA _ 0.
	semaphoresToSignalCountB _ 0.
	deferDisplayUpdates _ false.
	pendingFinalizationSignals _ 0.
! !

