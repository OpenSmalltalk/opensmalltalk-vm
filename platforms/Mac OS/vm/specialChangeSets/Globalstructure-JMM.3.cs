'From Squeak3.2gamma of 15 January 2002 [latest update: #4889] on 6 November 2002 at 5:54:58 pm'!
"Change Set:		Globalstructure-JMM
Date:			5 April 2002
Author:			John M McIntosh

Slang logic change to extrude global variables as a structure. This has performance implications on 
some platforms (better). Or is needed on some hardware because you don't have support for multiple globals"!

Object subclass: #CCodeGenerator
	instanceVariableNames: 'translationDict inlineList constants variables variableDeclarations methods variablesSetCache headerFiles pluginName extraDefs postProcesses isCPP pluginPrefix '
	classVariableNames: 'UseRightShiftForDivide '
	poolDictionaries: ''
	category: 'VMConstruction-Translation to C'!
CCodeGenerator subclass: #CCodeGeneratorGlobalStructure
	instanceVariableNames: 'globalVariables '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMConstruction-Translation to C'!
ObjectMemory subclass: #Interpreter
	instanceVariableNames: 'activeContext theHomeContext method receiver instructionPointer stackPointer localIP localSP localHomeContext messageSelector argumentCount newMethod currentBytecode successFlag primitiveIndex methodCache atCache lkupClass reclaimableContextCount nextPollTick nextWakeupTick lastTick interruptKeycode interruptPending semaphoresToSignalA semaphoresUseBufferA semaphoresToSignalCountA semaphoresToSignalB semaphoresToSignalCountB savedWindowSize fullScreenFlag deferDisplayUpdates pendingFinalizationSignals compilerInitialized compilerHooks extraVMMemory newNativeMethod methodClass receiverClass interpreterVersion obsoleteIndexedPrimitiveTable obsoleteNamedPrimitiveTable interpreterProxy showSurfaceFn interruptCheckCounterFeedBackReset interruptChecksEveryNms externalPrimitiveTable cntx val '
	classVariableNames: 'ActiveProcessIndex AtCacheEntries AtCacheFixedFields AtCacheFmt AtCacheMask AtCacheOop AtCacheSize AtCacheTotalSize AtPutBase BlockArgumentCountIndex BytecodeTable CacheProbeMax CallerIndex CharacterValueIndex CompilerHooksSize CrossedX DirBadPath DirEntryFound DirNoMoreEntries EndOfRun ExcessSignalsIndex FirstLinkIndex GenerateBrowserPlugin HeaderIndex HomeIndex InitialIPIndex InstanceSpecificationIndex InstructionPointerIndex JitterTable LastLinkIndex LiteralStart MaxExternalPrimitiveTableSize MaxPrimitiveIndex MessageArgumentsIndex MessageDictionaryIndex MessageLookupClassIndex MessageSelectorIndex MethodArrayIndex MethodCacheClass MethodCacheEntries MethodCacheEntrySize MethodCacheMask MethodCacheMethod MethodCacheNative MethodCachePrim MethodCacheSelector MethodCacheSize MethodIndex MillisecondClockMask MyListIndex NextLinkIndex PrimitiveExternalCallIndex PrimitiveTable PriorityIndex ProcessListsIndex ReceiverIndex SelectorStart SemaphoresToSignalSize SenderIndex StackPointerIndex StreamArrayIndex StreamIndexIndex StreamReadLimitIndex StreamWriteLimitIndex SuperclassIndex SuspendedContextIndex TempFrameStart ValueIndex XIndex YIndex '
	poolDictionaries: ''
	category: 'VMConstruction-Interpreter'!

!CCodeGenerator methodsFor: 'utilities' stamp: 'JMM 4/16/2002 22:39'!
returnPrefixFromVariable: aName
	^aName! !

!CCodeGenerator methodsFor: 'C code generator' stamp: 'ar 4/7/2002 18:25'!
emitCVariablesOn: aStream
	"Store the global variable declarations on the given stream."
	| varString |
	aStream nextPutAll: '/*** Variables ***/'; cr.
	variables asSortedCollection do: [ :var |
		varString _ var asString.
		(self isGeneratingPluginCode) ifTrue:[
			varString = 'interpreterProxy' ifTrue:[
				"quite special..."
				aStream cr; nextPutAll: '#ifdef SQUEAK_BUILTIN_PLUGIN'.
				aStream cr; nextPutAll: 'extern'.
				aStream cr; nextPutAll: '#endif'; cr.
			] ifFalse:[aStream nextPutAll:'static '].
		].
		(variableDeclarations includesKey: varString) ifTrue: [
			aStream nextPutAll: (variableDeclarations at: varString), ';'; cr.
		] ifFalse: [
			"default variable declaration"
			aStream nextPutAll: 'int ', varString, ';'; cr.
		].
	].
	aStream cr.! !


!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'JMM 4/16/2002 22:38'!
buildSortedVariablesCollection
	"Build sorted vars, cheat do an allinstances to get the variables node, then consolidate in a bag
	however I want to special case the arrays to put last in the structure
	end result will be sorted collection based on static usage, perhaps cache lines will like this!!"

	| globalNames sorted |
	
	globalNames _  TVariableNode allInstances select: [:e | self globalVariables includes: e name].
	globalNames _ globalNames collect: [:e | e name].
	globalNames _ globalNames reject: [:e | variableDeclarations includesKey: e].
	globalNames _ globalNames asBag.
	variableDeclarations keysDo: 
		[:e | globalNames add: e withOccurrences: 0].
	sorted _ SortedCollection sortBlock: 
		[:a :b | (globalNames occurrencesOf: a) > (globalNames occurrencesOf: b)].
	sorted addAll: variables.
	^sorted! !

!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'JMM 5/9/2002 14:09'!
emitCVariablesOn: aStream
	"Store the global variable declarations on the given stream.
	break logic into vars for structure and vars for non-structure"
	| varString structure nonstruct target |

	structure _ WriteStream on: (String new: 32768).
	nonstruct _ WriteStream on: (String new: 32768).
	aStream nextPutAll: '/*** Variables ***/'; cr.
	structure nextPutAll: 'struct foo {'; cr.
	self buildSortedVariablesCollection do: [ :var |
		varString _ var asString.
		target _ (self placeInStructure: var) 
			ifTrue: [structure]
			ifFalse: [nonstruct].
		(self isGeneratingPluginCode) ifTrue:[
			varString = 'interpreterProxy' ifTrue:[
				"quite special..."
				aStream cr; nextPutAll: '#ifdef SQUEAK_BUILTIN_PLUGIN'.
				aStream cr; nextPutAll: 'extern'.
				aStream cr; nextPutAll: '#endif'; cr.
			] ifFalse:[aStream nextPutAll:'static '].
		].
		(variableDeclarations includesKey: varString) ifTrue: [
			target nextPutAll: (variableDeclarations at: varString), ';'; cr.
		] ifFalse: [
			"default variable declaration"
			target nextPutAll: 'int ', varString, ';'; cr.
		].
	].
	structure nextPutAll: ' } fum;';cr.
	structure nextPutAll: 'struct foo * foo = &fum;';cr;cr.
	aStream nextPutAll: structure contents.
	aStream nextPutAll: nonstruct contents.
	aStream cr.! !

!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'JMM 4/16/2002 22:45'!
globalVariables
	"First time we get called we get the global variables into a set"
	globalVariables ifNil: 
		[globalVariables _ Set withAll: variables].
	^globalVariables! !

!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'JMM 4/17/2002 16:15'!
placeInStructure: var
	"See if we should put this array into a structure
	This has hard coded vars, should go somewhere else!!
	The variables listed are hardcoded as C in the interpreter thus they don't get resolved via TVariableNode logic
	Also Lets igore variables that have special defintions that require initialization, 
	and the function def which has problems"

	| check |
	check _ variableDeclarations at: var ifAbsent: [''].
	(check includes: $=) ifTrue: [^false].
	(check includes: $() ifTrue: [^false].
	(check includes: $[) ifTrue: [^false].
	(#( 'showSurfaceFn' 'memory' 'extraVMMemory' 'interpreterProxy') includes: var) ifTrue: [^false].
	^true.
	! !

!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'JMM 4/16/2002 22:39'!
returnPrefixFromVariable: aName
	^((self globalVariables includes: aName) and: [self placeInStructure: aName])
		ifTrue: ['foo->',aName]
		ifFalse: [aName]! !


!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:05'!
returnFalse

	cntx _ self sender.
	val _ falseObj.
	self returnValueTo.! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:04'!
returnNil

	cntx _ self sender.
	val _ nilObj.
	self returnValueTo.
! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:04'!
returnReceiver

	cntx _ self sender.
	val _ receiver.
	self returnValueTo.! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:05'!
returnTopFromBlock
	"Return to the caller of the method containing the block."

	cntx _ self caller.  "Note: caller, not sender!!"
	val _ self internalStackTop.
	self returnValueTo.! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:04'!
returnTopFromMethod

	cntx _ self sender.
	val _ self internalStackTop.
	self returnValueTo.! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:05'!
returnTrue

	cntx _ self sender.
	val _ trueObj.
	self returnValueTo.! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:16'!
returnValueTo
	"Note: Assumed to be inlined into the dispatch loop."

	| nilOop thisCntx contextOfCaller localCntx localVal|
	self inline: true.
	self sharedCodeNamed: 'commonReturn' inCase: 120.

	nilOop _ nilObj. "keep in a register"
	thisCntx _ activeContext.
	localCntx _ cntx.
	localVal _ val.

	"make sure we can return to the given context"
	((localCntx = nilOop) or:
	 [(self fetchPointer: InstructionPointerIndex ofObject: localCntx) = nilOop]) ifTrue: [
		"error: sender's instruction pointer or context is nil; cannot return"
		^self internalCannotReturn: localVal].

	"If this return is not to our immediate predecessor (i.e. from a method to its sender, or from a block to its caller), scan the stack for the first unwind marked context and inform this context and let it deal with it. This provides a chance for ensure unwinding to occur."
	thisCntx _ self fetchPointer: SenderIndex ofObject: activeContext.

	"Just possibly a faster test would be to compare the homeContext and activeContext - they are of course different for blocks. Thus we might be able to optimise a touch by having a different returnTo for the blockreteurn (since we know that must return to caller) and then if active ~= home we must be doing a non-local return. I think. Maybe."
	[thisCntx = localCntx] whileFalse: [
		thisCntx = nilObj ifTrue:[
			"error: sender's instruction pointer or context is nil; cannot return"
			^self internalCannotReturn: localVal].
		"Climb up stack towards localCntx. Break out to a send of #aboutToReturn:through: if an unwind marked context is found"
		(self isUnwindMarked: thisCntx) ifTrue:[
			"context is marked; break out"
			^self internalAboutToReturn: localVal through: thisCntx].
		thisCntx _ self fetchPointer: SenderIndex ofObject: thisCntx.
 ].

	"If we get here there is no unwind to worry about. Simply terminate the stack up to the localCntx - often just the sender of the method"
	thisCntx _ activeContext.
	[thisCntx = localCntx]
		whileFalse:
		["climb up stack to localCntx"
		contextOfCaller _ self fetchPointer: SenderIndex ofObject: thisCntx.

		"zap exited contexts so any future attempted use will be caught"
		self storePointerUnchecked: SenderIndex ofObject: thisCntx withValue: nilOop.
		self storePointerUnchecked: InstructionPointerIndex ofObject: thisCntx withValue: nilOop.
		reclaimableContextCount > 0 ifTrue:
			["try to recycle this context"
			reclaimableContextCount _ reclaimableContextCount - 1.
			self recycleContextIfPossible: thisCntx].
		thisCntx _ contextOfCaller].

	activeContext _ thisCntx.
	(thisCntx < youngStart) ifTrue: [ self beRootIfOld: thisCntx ].

	self internalFetchContextRegisters: thisCntx.  "updates local IP and SP"
	self fetchNextBytecode.
	self internalPush: localVal.
! !


!Interpreter class methodsFor: 'translation' stamp: 'JMM 4/16/2002 22:32'!
translateInDirectory: directory doInlining: inlineFlag forBrowserPlugin: pluginFlag
	^self translateInDirectory: directory doInlining: inlineFlag forBrowserPlugin: pluginFlag forGlobalStructure: false! !

!Interpreter class methodsFor: 'translation' stamp: 'JMM 5/9/2002 14:21'!
translateInDirectory: directory doInlining: inlineFlag forBrowserPlugin: pluginFlag forGlobalStructure: globalStructureFlag
	"Translate the Smalltalk description of the virtual machine into C. If inlineFlag is true, small method bodies are inlined to reduce procedure call overhead. On the PPC, this results in a factor of three speedup with only 30% increase in code size. If pluginFlag is true, generate code for an interpreter that runs as a browser plugin (Netscape or IE)."
	"Note: The pluginFlag is meaningless on Windows and Unix. On these platforms Squeak runs as it's own process and doesn't need any special attention from the VMs point of view. Meaning that NONE of the required additional functions will be supported. In other words, the pluginFlag is not needed and not supported."
	"The forGlobalStructure flag if true uses a different CCodeGenerator to build globals as a pointer to a structure, some RISC based platforms PPC for example 
them make better assembler"

	"Return the list of exports for this module"

	| doInlining cg fileName tStamp fstat |
	tStamp _ { Interpreter. ObjectMemory} inject: 0 into: [:tS :cl|
		tS _ tS max: cl timeStamp].

	"don't translate if the file is newer than my timeStamp"
	fileName _ 'interp.c'.
	fstat _ directory entryAt: fileName ifAbsent:[nil].
	fstat ifNotNil:[tStamp < fstat modificationTime ifTrue:[^nil]].


	doInlining _ inlineFlag.
	pluginFlag ifTrue: [doInlining _ true].  "must inline when generating browser plugin"
	Interpreter initialize.
	ObjectMemory initialize.
	GenerateBrowserPlugin  _ pluginFlag.
	cg _ globalStructureFlag 
		ifTrue: [CCodeGeneratorGlobalStructure new initialize]
		ifFalse: [CCodeGenerator new initialize].
	cg addClass: Interpreter.
	cg addClass: ObjectMemory.
	Interpreter declareCVarsIn: cg.
	ObjectMemory declareCVarsIn: cg.

	cg storeCodeOnFile: (directory fullNameFor: fileName) doInlining: doInlining! !


!MacOSPowerPCOS9VMMaker methodsFor: 'generate sources' stamp: 'JMM 5/9/2002 14:21'!
generateInterpreterFile
	"generate the main 'interp.c' file for the interpreter and the list of 
	export statments"
	Interpreter
				translateInDirectory: self coreVMDirectory
				doInlining: inline
				forBrowserPlugin: forBrowser
				forGlobalStructure: true.
! !


!TVariableNode methodsFor: 'as yet unclassified' stamp: 'JMM 4/5/2002 14:14'!
emitCCodeOn: aStream level: level generator: aCodeGen

	name = 'nil'
		ifTrue: [ aStream nextPutAll: (aCodeGen cLiteralFor: nil) ]
		ifFalse: [ aStream nextPutAll: (aCodeGen returnPrefixFromVariable: name) ].! !

Interpreter removeSelector: #returnValue:to:!
