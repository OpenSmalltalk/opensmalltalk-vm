'From Squeak3.2gamma of 15 January 2002 [latest update: #4823] on 17 April 2002 at 12:05:46 pm'!
"Change Set:		MoreInterpreterAccessors-JMM
Date:			16 April 2002
Author:			John M McIntosh

The VM needs a few more accessors/mutators for VM that are built using a global structure to allow platform specific code to access globals in a more indirect manner"!


!CCodeGenerator methodsFor: 'inlining' stamp: 'JMM 4/17/2002 12:02'!
pruneUnreachableMethods
	"Remove any methods that are not reachable. Retain methods needed by the BitBlt operation table, primitives, plug-ins, or interpreter support code."
 
	| retain |
	"Build a set of selectors for methods that should be output even though they have no apparent callers. Some of these are stored in tables for indirect lookup, some are called by the C support code or by primitives."
	retain _ BitBltSimulation opTable asSet.
	#(checkedLongAt: fullDisplayUpdate interpret printCallStack printAllStacks
	   readImageFromFile:HeapSize:StartingAt: success:
		"Windows needs the following two for startup and debug"
	   readableFormat: getCurrentBytecode
		"Jitter reuses all of these"
	   allocateChunk: characterForAscii:
	   findClassOfMethod:forReceiver: findSelectorOfMethod:forReceiver:
	   firstAccessibleObject loadInitialContext noteAsRoot:headerLoc:
	   nullCompilerHook
	   primitiveFloatAdd primitiveFloatDivide primitiveFloatMultiply
	   primitiveFloatSubtract primitiveFlushExternalPrimitives
	   setCompilerInitialized: splObj:
		"accessors needed for global structure support"
	   getFullScreenFlag getInterruptCheckCounter getInterruptKeycode getInterruptPending
	   getNextWakeupTick getSavedWindowSize setFullScreenFlag: setInterruptCheckCounter:
	   setInterruptKeycode: setInterruptPending: setNextWakeupTick: setSavedWindowSize:
	)
			do: [:sel | retain add: sel].
	InterpreterProxy organization categories do: [:cat |
		((cat ~= 'initialize') and: [cat ~= 'private']) ifTrue: [
			retain addAll: (InterpreterProxy organization listAtCategoryNamed: cat)]].

	"Remove all the unreachable methods that aren't retained for the reasons above."
	self unreachableMethods do: [:sel |
		(retain includes: sel) ifFalse: [
			methods removeKey: sel ifAbsent: []]].
! !


!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:02'!
getFullScreenFlag
	^fullScreenFlag! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:02'!
getInterruptCheckCounter
	^interruptCheckCounter! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:02'!
getInterruptKeycode
	^interruptKeycode! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:02'!
getInterruptPending
	^interruptPending! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:03'!
getNextWakeupTick
	^nextWakeupTick! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:03'!
getSavedWindowSize
	^savedWindowSize! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:44'!
setFullScreenFlag: value
	fullScreenFlag _ value! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:45'!
setInterruptCheckCounter: value
	interruptCheckCounter _ value! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:46'!
setInterruptKeycode: value
	interruptKeycode _ value! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:46'!
setInterruptPending: value
	interruptPending _ value! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:48'!
setNextWakeupTick: value
	nextWakeupTick _ value! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:47'!
setSavedWindowSize: value
	savedWindowSize _ value! !

