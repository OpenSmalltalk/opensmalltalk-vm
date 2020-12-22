"
I am the code generator for the Cog VM.  My job is to produce machine code versions of methods for faster execution and to manage inline caches for faster send performance.  I can be tested in the current image using my class-side in-image compilation facilities.  e.g. try

	StackToRegisterMappingCogit genAndDis: (Integer >> #benchFib)

I have concrete subclasses that implement different levels of optimization:
	SimpleStackBasedCogit is the simplest code generator.

	StackToRegisterMappingCogit is the current production code generator  It defers pushing operands
	to the stack until necessary and implements a register-based calling convention for low-arity sends.

	SistaCogit is an experimental code generator with support for counting
	conditional branches, intended to support adaptive optimization.

	RegisterAllocatingCogit is an experimental code generator with support for allocating temporary variables
	to registers. It is inended to serve as the superclass to SistaCogit once it is working.

	SistaRegisterAllocatingCogit and SistaCogitClone are temporary classes that allow testing a clone of
	SistaCogit that inherits from RegisterAllocatingCogit.  Once things work these will be merged and
	will replace SistaCogit.

coInterpreter <CoInterpreterSimulator>
	the VM's interpreter with which I cooperate
methodZoneManager <CogMethodZoneManager>
	the manager of the machine code zone
objectRepresentation <CogObjectRepresentation>
	the object used to generate object accesses
processor <BochsIA32Alien|?>
	the simulator that executes the IA32/x86 machine code I generate when simulating execution in Smalltalk
simulatedTrampolines <Dictionary of Integer -> MessageSend>
	the dictionary mapping trap jump addresses to run-time routines used to warp from simulated machine code in to the Smalltalk run-time.
simulatedVariableGetters <Dictionary of Integer -> MessageSend>
	the dictionary mapping trap read addresses to variables in run-time objects used to allow simulated machine code to read variables in the Smalltalk run-time.
simulatedVariableSetters <Dictionary of Integer -> MessageSend>
	the dictionary mapping trap write addresses to variables in run-time objects used to allow simulated machine code to write variables in the Smalltalk run-time.
printRegisters printInstructions clickConfirm <Boolean>
	flags controlling debug printing and code simulation
breakPC <Integer>
	machine code pc breakpoint
cFramePointer cStackPointer <Integer>
	the variables representing the C stack & frame pointers, which must change on FFI callback and return
selectorOop <sqInt>
	the oop of the methodObj being compiled
methodObj <sqInt>
	the bytecode method being compiled
initialPC endPC <Integer>
	the start and end pcs of the methodObj being compiled
methodOrBlockNumArgs <Integer>
	argument count of current method or block being compiled
needsFrame <Boolean>
	whether methodObj or block needs a frame to execute
primitiveIndex <Integer>
	primitive index of current method being compiled
methodLabel <CogAbstractOpcode>
	label for the method header
blockEntryLabel <CogAbstractOpcode>
	label for the start of the block dispatch code
stackOverflowCall <CogAbstractOpcode>
	label for the call of ceStackOverflow in the method prolog
sendMissCall <CogAbstractOpcode>
	label for the call of ceSICMiss in the method prolog
entryOffset <Integer>
	offset of method entry code from start (header) of method
entry <CogAbstractOpcode>
	label for the first instruction of the method entry code
noCheckEntryOffset <Integer>
	offset of the start of a method proper (after the method entry code) from start (header) of method
noCheckEntry <CogAbstractOpcode>
	label for the first instruction of start of a method proper
fixups <Array of <AbstractOpcode Label | nil>>
	the labels for forward jumps that will be fixed up when reaching the relevant bytecode.  fixups has one element per byte in methodObj's bytecode; initialPC maps to fixups[0].
abstractOpcodes <Array of <AbstractOpcode>>
	the code generated when compiling methodObj
byte0 byte1 byte2 byte3 <Integer>
	individual bytes of current bytecode being compiled in methodObj
bytecodePointer <Integer>
	bytecode pc (same as Smalltalk) of the current bytecode being compiled
opcodeIndex <Integer>
	the index of the next free entry in abstractOpcodes (this code is translated into C where OrderedCollection et al do not exist)
numAbstractOpcodes <Integer>
	the number of elements in abstractOpcocdes
blockStarts <Array of <BlockStart>>
	the starts of blocks in the current method
blockCount
	the index into blockStarts as they are being noted, and hence eventually the total number of blocks in the current method
labelCounter <Integer>
	a nicety for numbering labels not needed in the production system but probably not expensive enough to worry about
ceStackOverflowTrampoline <Integer>
ceSend0ArgsTrampoline <Integer>
ceSend1ArgsTrampoline <Integer>
ceSend2ArgsTrampoline <Integer>
ceSendNArgsTrampoline <Integer>
ceSendSuper0ArgsTrampoline <Integer>
ceSendSuper1ArgsTrampoline <Integer>
ceSendSuper2ArgsTrampoline <Integer>
ceSendSuperNArgsTrampoline <Integer>
ceSICMissTrampoline <Integer>
ceCPICMissTrampoline <Integer>
ceStoreCheckTrampoline <Integer>
ceReturnToInterpreterTrampoline <Integer>
ceBaseFrameReturnTrampoline <Integer>
ceSendMustBeBooleanTrampoline <Integer>
ceClosureCopyTrampoline <Integer>
	the various trampolines (system-call-like jumps from machine code to the run-time).
	See Cogit>>generateTrampolines for the mapping from trampoline to run-time
	routine and then read the run-time routine for a funcitonal description.
ceEnterCogCodePopReceiverReg <Integer>
	the enilopmart (jump from run-time to machine-code)
methodZoneBase <Integer>

"
Class {
	#name : #Cogit,
	#superclass : #CogClass,
	#instVars : [
		'coInterpreter',
		'objectMemory',
		'objectRepresentation',
		'processor',
		'threadManager',
		'methodZone',
		'methodZoneBase',
		'codeBase',
		'minValidCallAddress',
		'lastNInstructions',
		'simulatedAddresses',
		'simulatedTrampolines',
		'simulatedVariableGetters',
		'simulatedVariableSetters',
		'printRegisters',
		'printInstructions',
		'compilationTrace',
		'clickConfirm',
		'breakPC',
		'breakBlock',
		'singleStep',
		'guardPageSize',
		'traceFlags',
		'traceStores',
		'breakMethod',
		'methodObj',
		'enumeratingCogMethod',
		'methodHeader',
		'initialPC',
		'endPC',
		'methodOrBlockNumArgs',
		'inBlock',
		'needsFrame',
		'hasYoungReferent',
		'primitiveIndex',
		'backEnd',
		'literalsManager',
		'postCompileHook',
		'methodLabel',
		'stackCheckLabel',
		'blockEntryLabel',
		'blockEntryNoContextSwitch',
		'blockNoContextSwitchOffset',
		'stackOverflowCall',
		'sendMiss',
		'missOffset',
		'entryPointMask',
		'checkedEntryAlignment',
		'uncheckedEntryAlignment',
		'cmEntryOffset',
		'entry',
		'cmNoCheckEntryOffset',
		'noCheckEntry',
		'fullBlockEntry',
		'cbEntryOffset',
		'fullBlockNoContextSwitchEntry',
		'cbNoSwitchEntryOffset',
		'picMNUAbort',
		'picInterpretAbort',
		'endCPICCase0',
		'endCPICCase1',
		'firstCPICCaseOffset',
		'cPICCaseSize',
		'cPICEndSize',
		'closedPICSize',
		'openPICSize',
		'fixups',
		'abstractOpcodes',
		'generatorTable',
		'byte0',
		'byte1',
		'byte2',
		'byte3',
		'bytecodePC',
		'bytecodeSetOffset',
		'opcodeIndex',
		'numAbstractOpcodes',
		'blockStarts',
		'blockCount',
		'labelCounter',
		'cStackAlignment',
		'expectedSPAlignment',
		'expectedFPAlignment',
		'codeModified',
		'maxLitIndex',
		'ceMethodAbortTrampoline',
		'cePICAbortTrampoline',
		'ceCheckForInterruptTrampoline',
		'ceCPICMissTrampoline',
		'ceReturnToInterpreterTrampoline',
		'ceBaseFrameReturnTrampoline',
		'ceReapAndResetErrorCodeTrampoline',
		'ceSendMustBeBooleanAddTrueTrampoline',
		'ceSendMustBeBooleanAddFalseTrampoline',
		'ceCannotResumeTrampoline',
		'ceEnterCogCodePopReceiverReg',
		'ceCallCogCodePopReceiverReg',
		'ceCallCogCodePopReceiverAndClassRegs',
		'cePrimReturnEnterCogCode',
		'cePrimReturnEnterCogCodeProfiling',
		'ceNonLocalReturnTrampoline',
		'ceFetchContextInstVarTrampoline',
		'ceStoreContextInstVarTrampoline',
		'ceEnclosingObjectTrampoline',
		'ceFlushICache',
		'ceCheckFeaturesFunction',
		'ceTraceLinkedSendTrampoline',
		'ceTraceBlockActivationTrampoline',
		'ceTraceStoreTrampoline',
		'ceGetFP',
		'ceGetSP',
		'ceCaptureCStackPointers',
		'ordinarySendTrampolines',
		'superSendTrampolines',
		'directedSuperSendTrampolines',
		'directedSuperBindingSendTrampolines',
		'dynamicSuperSendTrampolines',
		'outerSendTrampolines',
		'selfSendTrampolines',
		'firstSend',
		'lastSend',
		'realCEEnterCogCodePopReceiverReg',
		'realCECallCogCodePopReceiverReg',
		'realCECallCogCodePopReceiverAndClassRegs',
		'trampolineTableIndex',
		'trampolineAddresses',
		'objectReferencesInRuntime',
		'runtimeObjectRefIndex',
		'cFramePointerInUse',
		'debugPrimCallStackOffset',
		'ceTryLockVMOwner',
		'ceUnlockVMOwner',
		'extA',
		'extB',
		'numExtB',
		'tempOop',
		'numIRCs',
		'indexOfIRC',
		'theIRCs',
		'receiverTags',
		'implicitReceiverSendTrampolines',
		'cogMethodSurrogateClass',
		'cogBlockMethodSurrogateClass',
		'CStackPointer',
		'CFramePointer',
		'cPICPrototype',
		'cPICEndOfCodeOffset',
		'cPICEndOfCodeLabel',
		'ceMallocTrampoline',
		'ceFreeTrampoline',
		'debugBytecodePointers',
		'debugOpcodeIndices',
		'disassemblingMethod',
		'cogConstituentIndex',
		'directedSendUsesBinding',
		'simulateFPInUse'
	],
	#classVars : [
		'AltBlockCreationBytecodeSize',
		'AltFirstSpecialSelector',
		'AltNSSendIsPCAnnotated',
		'AltNumSpecialSelectors',
		'AnnotationConstantNames',
		'AnnotationShift',
		'AnnotationsWithBytecodePCs',
		'BlockCreationBytecodeSize',
		'Debug',
		'DisplacementMask',
		'DisplacementX2N',
		'EagerInstructionDecoration',
		'FirstAnnotation',
		'FirstSpecialSelector',
		'HasBytecodePC',
		'IsAbsPCReference',
		'IsAnnotationExtension',
		'IsDirectedSuperBindingSend',
		'IsDirectedSuperSend',
		'IsDisplacementX2N',
		'IsNSDynamicSuperSend',
		'IsNSImplicitReceiverSend',
		'IsNSSelfSend',
		'IsNSSendCall',
		'IsObjectReference',
		'IsRelativeCall',
		'IsSendCall',
		'IsSuperSend',
		'MapEnd',
		'MaxCPICCases',
		'MaxCompiledPrimitiveIndex',
		'MaxStackAllocSize',
		'MaxX2NDisplacement',
		'NSCClassTagIndex',
		'NSCEnclosingObjectIndex',
		'NSCNumArgsIndex',
		'NSCSelectorIndex',
		'NSCTargetIndex',
		'NSSendIsPCAnnotated',
		'NumObjRefsInRuntime',
		'NumOopsPerNSC',
		'NumSpecialSelectors',
		'NumTrampolines',
		'ProcessorClass',
		'RRRName'
	],
	#pools : [
		'CogAbstractRegisters',
		'CogCompilationConstants',
		'CogMethodConstants',
		'CogRTLOpcodes',
		'VMBasicConstants',
		'VMBytecodeConstants',
		'VMObjectIndices',
		'VMStackFrameOffsets'
	],
	#classInstVars : [
		'generatorTable',
		'primitiveTable'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
Cogit class >> activeCompilerClass [
	^InitializationOptions
		at: #CogCompilerClass
		ifPresent: [:compilerClassName| Smalltalk classNamed: compilerClassName]
		ifAbsent:
			[(CogAbstractInstruction subclasses detect:
				[:compilerClass|
				 compilerClass ISA == (InitializationOptions at: #ISA ifAbsent: [#IA32])]) defaultCompilerClass]
]

{ #category : #translation }
Cogit class >> additionalHeadersDo: aBinaryBlock [
	"Evaluate aBinaryBlock with the names and contents of
	 any additional header files that need to be generated."

	aBinaryBlock
		value: 'cogmethod.h'
		value: CogMethod cogMethodHeader
]

{ #category : #translation }
Cogit class >> additionalSelectorTables [
	^self tableFunctions
]

{ #category : #translation }
Cogit class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	ProcessorClass ifNil:
		[Cogit initializeMiscConstants].
	^(self activeCompilerClass withAllSuperclasses copyUpThrough: CogAbstractInstruction),
	  {	CogMethodZone.
		CogBlockStart.
		CogBytecodeDescriptor.
		CogBytecodeFixup.
		CogPrimitiveDescriptor.
		CogBlockMethod.
		CogMethod.
		self activeCompilerClass literalsManagerClass},
	((InitializationOptions at: #SistaVM ifAbsent: [false])
		ifTrue: [{SistaMethodZone}]
		ifFalse: [#()])
]

{ #category : #'class initialization' }
Cogit class >> annotationConstantNames [
	"for printing..."
	^AnnotationConstantNames
]

{ #category : #translation }
Cogit class >> apiExportHeaderName [
	^'cogit.h'
]

{ #category : #'in-image compilation support' }
Cogit class >> asOptionsDictionary: optionsDictionaryOrArray [
	optionsDictionaryOrArray isArray ifTrue:
		[| dict |
		dict := Dictionary new.
		self assert: optionsDictionaryOrArray size even.
		1 to: optionsDictionaryOrArray size by: 2 do:
			[:i| | key |
			key := optionsDictionaryOrArray at: i.
			self assert: key isSymbol.
			dict at: key put: (optionsDictionaryOrArray at: i + 1)].
		^dict].
	^optionsDictionaryOrArray
]

{ #category : #documentation }
Cogit class >> assumptions [
	"Byte architecture; no 9-bit bit bytes etc.

	 Stacks grow down.  No support for HPPA.

	 No delay slots.  No support for SPARC.

	 Relative jumps.

	 All long conditional branches are of the same size.

	 All long unconditional branches are of the same size.

	 All MoveCwRs are of the same size.

	 A long jump and a call have the same displacement layout so both can be labelled with IsRelativeCall.

	 A PushCw and a MoveCwR have the same constant layout so both can be labelled with IsObjectReference or IsMethodReference.

	 64k of code per method more than enough"
]

{ #category : #'in-image compilation support' }
Cogit class >> attemptToComputeInstVarNamesFor: aCompiledMethod [
	(aCompiledMethod methodClass instSize > 0) ifTrue:
		[InitializationOptions
			at: #instVarNames
			put: (aCompiledMethod methodClass allInstVarNames)]
]

{ #category : #'in-image compilation support' }
Cogit class >> attemptToComputeTempNamesFor: aCompiledMethod [
	(aCompiledMethod respondsTo: #tempNames) ifTrue:
		[| schematicTemps blocks |
		 schematicTemps := aCompiledMethod methodNode schematicTempNamesString.
		 blocks := aCompiledMethod embeddedBlockClosures.
		 InitializationOptions
			at: #tempNames
			put: (Dictionary newFrom: {aCompiledMethod initialPC -> (self decomposeSchematicTemps: (schematicTemps copyUpTo: $[))},
				(blocks
					ifEmpty: [#()]
					ifNotEmpty:
						[aCompiledMethod embeddedBlockClosures
							with: (schematicTemps first = $[
									ifTrue: [schematicTemps piecesCutWhere: [:a :b| b = $[]]
									ifFalse: [(schematicTemps piecesCutWhere: [:a :b| b = $[]) allButFirst])
							collect: [:c :s| c startpc -> (self decomposeSchematicTemps: (s copyWithoutAll: '[]'))]]))]
]

{ #category : #'accessing class hierarchy' }
Cogit class >> chooseCogitClass [
	^Smalltalk at: ([:choices| choices at: (UIManager default chooseFrom: choices) ifAbsent: [^nil]]
						value: (Cogit allSubclasses collect: [:ea| ea  name]) sorted)
]

{ #category : #'in-image compilation' }
Cogit class >> cog: aCompiledMethod [
	^self cog: aCompiledMethod options: #()
]

{ #category : #'in-image compilation' }
Cogit class >> cog: aCompiledMethod options: optionsArray [
	^self cog: aCompiledMethod selectorOrNumCopied: aCompiledMethod selector options: optionsArray
]

{ #category : #'in-image compilation' }
Cogit class >> cog: aCompiledMethod selector: aSelector [
	^self cog: aCompiledMethod selectorOrNumCopied: aSelector options: #()
]

{ #category : #'in-image compilation' }
Cogit class >> cog: aCompiledMethod selectorOrNumCopied: selectorOrNumCopied options: optionsDictionaryOrArray [
	"StackToRegisterMappingCogit cog: (Integer >> #benchFib) selector: #benchFib options: #(COGMTVM false)"
	| cogit coInterpreter |
	cogit := self initializedInstanceForTests: optionsDictionaryOrArray.
	coInterpreter := cogit coInterpreter.
	self attemptToComputeTempNamesFor: aCompiledMethod.
	self attemptToComputeInstVarNamesFor: aCompiledMethod.
	^{ coInterpreter.
		cogit.
		selectorOrNumCopied isInteger
			ifTrue: [ cogit cogFullBlockMethod: (coInterpreter oopForObject: aCompiledMethod) numCopied: selectorOrNumCopied ]
			ifFalse: [ cogit cog: (coInterpreter oopForObject: aCompiledMethod) selector: (coInterpreter oopForObject: selectorOrNumCopied) ] }
]

{ #category : #documentation }
Cogit class >> cogToBytecodeMethodMapping [
	"When first written the VM maintained a one-to-one mapping between bytecoded methods and cog methods.
	The map is implemented with a direct reference form the methodObject field of a CogMethod to the bytecoded
	method and by setting the header word of the bytecoded method to the CogMethod.  Newspeak forced a change
	in this since Newspeak shares anonymous (nil methodClassAssociation) accessors (setters and getters) amongst
	classes and mixins throughout the system (i.e. these accessors are in dictionaries under selector keys that don't
	match the accessor methods' selectors).  But the inline cacheing relinking/un;linking machinery depends on
	CogMethods having the correct selector, since to unlink/relink the selector is fetched from the inline cache's
	target method.  So the VM has been modified to not insist on a one-to-one mapping.  Instead, when a bytecoded
	method is to be used with a different selector it is attached to the new CogMethod.

	This choice means that CogMethods do refer to a valid bytecoded method, but the bytecoded method might
	not necessarily refer back to a CogMethod referring to it.  So when CogMethods are freed care must be taken
	to reset the bytecoded method's header if it is referring to the freed CogMethod."
]

{ #category : #translation }
Cogit class >> declareCVarsIn: aCCodeGenerator [
	#(	'coInterpreter' 'objectMemory' 'methodZone' 'objectRepresentation'
		'cogBlockMethodSurrogateClass' 'cogMethodSurrogateClass' 'threadManager' 'processor' 'lastNInstructions' 'simulatedAddresses'
		'simulatedTrampolines' 'simulatedVariableGetters' 'simulatedVariableSetters'
		'printRegisters' 'printInstructions' 'clickConfirm' 'singleStep') do:
			[:simulationVariableNotNeededForRealVM|
			aCCodeGenerator removeVariable: simulationVariableNotNeededForRealVM].
	#(	'selfSendTrampolines' 'dynamicSuperSendTrampolines'
			'implicitReceiverSendTrampolines' 'outerSendTrampolines'
			'ceEnclosingObjectTrampoline' 'numIRCs' 'indexOfIRC' 'theIRCs') do:
				[:variableNotNeededInNormalVM|
				aCCodeGenerator removeVariable: variableNotNeededInNormalVM].
	aCCodeGenerator removeConstant: #COGMTVM. "this should be defined at compile time"
	aCCodeGenerator
		addHeaderFile:'<stddef.h>'; "for e.g. offsetof"
		addHeaderFile:'"sqCogStackAlignment.h"';
		addHeaderFile:'"dispdbg.h"'; "must precede cointerp.h & cogit.h otherwise NoDbgRegParms gets screwed up"
		addHeaderFile:'"cogmethod.h"'.
	aCCodeGenerator
		addHeaderFile:'#if COGMTVM';
		addHeaderFile:'"cointerpmt.h"';
		addHeaderFile:'#else';
		addHeaderFile:'"cointerp.h"';
		addHeaderFile:'#endif';
		addHeaderFile:'"cogit.h"';
		addHeaderFile:'<stdint.h>'.
	aCCodeGenerator
		var: #ceGetFP
			declareC: 'usqIntptr_t (*ceGetFP)(void)';
		var: #ceGetSP
			declareC: 'usqIntptr_t (*ceGetSP)(void)';
		var: #ceCaptureCStackPointers
			declareC: 'void (*ceCaptureCStackPointers)(void)';
		var: #ceEnterCogCodePopReceiverReg
			declareC: 'void (*ceEnterCogCodePopReceiverReg)(void)';
		var: #realCEEnterCogCodePopReceiverReg
			declareC: 'void (*realCEEnterCogCodePopReceiverReg)(void)';
		var: #ceCallCogCodePopReceiverReg
			declareC: 'void (*ceCallCogCodePopReceiverReg)(void)';
		var: #realCECallCogCodePopReceiverReg
			declareC: 'void (*realCECallCogCodePopReceiverReg)(void)';
		var: #ceCallCogCodePopReceiverAndClassRegs
			declareC: 'void (*ceCallCogCodePopReceiverAndClassRegs)(void)';
		var: #realCECallCogCodePopReceiverAndClassRegs
			declareC: 'void (*realCECallCogCodePopReceiverAndClassRegs)(void)';
		var: #ceFlushICache
			declareC: 'static void (*ceFlushICache)(usqIntptr_t from, usqIntptr_t to)';
		var: #ceCheckFeaturesFunction
			declareC: 'static usqIntptr_t (*ceCheckFeaturesFunction)(void)';
		var: #ceTryLockVMOwner
			declareC: 'usqIntptr_t (*ceTryLockVMOwner)(void)';
		var: #ceUnlockVMOwner
			declareC: 'void (*ceUnlockVMOwner)(void)';
		var: #postCompileHook
			declareC: 'void (*postCompileHook)(CogMethod *)';
		var: #openPICList declareC: 'CogMethod *openPICList = 0';
		var: #maxMethodBefore type: #'CogBlockMethod *';
		var: 'enumeratingCogMethod' type: #'CogMethod *'.
	aCCodeGenerator
		declareVar: 'aMethodLabel' type: #'AbstractInstruction'; "Has to come lexicographically before backEnd & methodLabel"
		var: #backEnd declareC: 'AbstractInstruction * const backEnd = &aMethodLabel';
		var: #methodLabel declareC: 'AbstractInstruction * const methodLabel = &aMethodLabel'.
	self declareC: #(abstractOpcodes stackCheckLabel
					blockEntryLabel blockEntryNoContextSwitch
					stackOverflowCall sendMiss
					entry noCheckEntry selfSendEntry dynSuperEntry
					fullBlockNoContextSwitchEntry fullBlockEntry
					picMNUAbort picInterpretAbort  endCPICCase0 endCPICCase1 cPICEndOfCodeLabel)
			as: #'AbstractInstruction *'
				in: aCCodeGenerator.
	aCCodeGenerator
		declareVar: #blockStarts type: #'BlockStart *';
		declareVar: #fixups type: #'BytecodeFixup *'.
	aCCodeGenerator
		var: #ordinarySendTrampolines
			declareC: 'sqInt ordinarySendTrampolines[NumSendTrampolines]';
		var: #superSendTrampolines
			declareC: 'sqInt superSendTrampolines[NumSendTrampolines]'.
	BytecodeSetHasDirectedSuperSend ifTrue:
		[aCCodeGenerator
			var: #directedSuperSendTrampolines
				declareC: 'sqInt directedSuperSendTrampolines[NumSendTrampolines]';
			var: #directedSuperBindingSendTrampolines
				declareC: 'sqInt directedSuperBindingSendTrampolines[NumSendTrampolines]'].
	aCCodeGenerator
		var: #trampolineAddresses
			declareC: 'static char *trampolineAddresses[NumTrampolines*2]';
		var: #objectReferencesInRuntime
			declareC: 'static usqInt objectReferencesInRuntime[NumObjRefsInRuntime+1]';
		var: #labelCounter
			type: #int;
		var: #traceFlags
			declareC: 'int traceFlags = 8 /* prim trace log on by default */';
		var: #cStackAlignment
			declareC: 'const int cStackAlignment = STACK_ALIGN_BYTES'.
	aCCodeGenerator
		declareVar: #CFramePointer type: #'void *';
		declareVar: #CStackPointer type: #'void *';
		declareVar: #minValidCallAddress type: #'usqIntptr_t';
		declareVar: #debugPrimCallStackOffset type: #'usqIntptr_t'.
	aCCodeGenerator vmClass generatorTable ifNotNil:
		[:bytecodeGenTable|
		aCCodeGenerator
			var: #generatorTable
				declareC: 'static BytecodeDescriptor generatorTable[', bytecodeGenTable size printString, ']',
							(self tableInitializerFor: bytecodeGenTable
								in: aCCodeGenerator)].
	"In C the abstract opcode names clash with the Smalltak generator syntactic sugar.
	 Most of the syntactic sugar is inlined, but alas some remains.  Rename the syntactic
	 sugar to avoid the clash."
	(self organization listAtCategoryNamed: #'abstract instructions') do:
		[:s|
		aCCodeGenerator addSelectorTranslation: s to: 'g', (aCCodeGenerator cFunctionNameFor: s)].
	aCCodeGenerator addSelectorTranslation: #halt: to: 'haltmsg'
]

{ #category : #'in-image compilation support' }
Cogit class >> decomposeSchematicTemps: aString [
	^Array streamContents:
		[:ws| | rs |
		rs := aString readStream.
		[rs atEnd] whileFalse:
			[ws nextPut: (rs peek = $(
						ifTrue: [[rs upThrough: $)]
									on: MessageNotUnderstood
									do: [:ex| (rs upTo: $)), ')']]
						ifFalse: [rs upTo: Character space])]]
]

{ #category : #'C translation' }
Cogit class >> defineAtCompileTime: anObject [
	"Override to define at translation time those variables that need to
	 be defined at compile time only in plugins, but not in the main VM,
	 because the VM generated is specific to these varables."
	anObject isSymbol ifFalse:
		[^false].
	(#(STACKVM COGVM COGMTVM SPURVM) includes: anObject) ifTrue:
		[^false].
	^VMBasicConstants namesDefinedAtCompileTime includes: anObject
]

{ #category : #translation }
Cogit class >> doInlining [
	"inline only those methods that are marked with <inline: true>"
	^#asSpecifiedOrQuick
]

{ #category : #'in-image compilation' }
Cogit class >> genAndDis: methodOrDoitString [
	^self genAndDis: methodOrDoitString options: #()
]

{ #category : #'in-image compilation' }
Cogit class >> genAndDis: compiledBlock numCopied: numCopied options: optionsDictionaryOrArray [
	| tuple |
	tuple := self cog: compiledBlock selectorOrNumCopied: numCopied options: optionsDictionaryOrArray.
	tuple second disassembleMethod: tuple last.
	^tuple
]

{ #category : #'in-image compilation' }
Cogit class >> genAndDis: methodOrDoitString options: optionsDictionaryOrArray [
	| tuple |
	methodOrDoitString isCompiledCode ifFalse:
		[^self
			genAndDis: (Compiler new
							compiledMethodFor: methodOrDoitString
							in: nil
							to: nil
							notifying: nil
							ifFail: nil
							logged: false)
			 options: optionsDictionaryOrArray].
	tuple := self cog: methodOrDoitString
				selectorOrNumCopied: (methodOrDoitString isCompiledBlock
											ifTrue: [methodOrDoitString numCopiedValues]
											ifFalse: [methodOrDoitString selector])
				options: optionsDictionaryOrArray.
	tuple second disassembleMethod: tuple last.
	^tuple
]

{ #category : #'in-image compilation' }
Cogit class >> genAndDisPICoptions: optionsDictionaryOrArray [
	"StackToRegisterMappingCogit genAndDisPICoptions: #(ISA ARMv5 CogCompilerClass CogOutOfLineLiteralsARMCompiler)"
	| cogit |
	cogit := self initializedInstanceForTests: optionsDictionaryOrArray.
	cogit disassembleFrom: cogit cPICPrototype + (cogit sizeof: CogMethod) to: cogit cPICPrototype + cogit closedPICSize
]

{ #category : #translation }
Cogit class >> generateCodeStringForCogitDotC [
	"Generate a skeletal cogit.c that includes the relevant cogitFOO.c
	 for the appropriate subclasses of CogAbstractInstruction.
	 self generateCodeStringForCogitDotC"
	 
	| string insertPosition abis defaultDef |
	abis := OrderedCollection new.
	string := String streamContents:
		[:s|
		 s nextPutAll: '/* Automatically generated by\	' withCRs.
		 s nextPutAll: (CCodeGenerator monticelloDescriptionFor: self).
		 s cr; nextPutAll: ' */'.
		 s cr; cr; nextPut: $#.
		 insertPosition := s position.
		 self translateableInstructionSubclassesAndInstalledOptionsDo:
			[:class | | abi |
			 s nextPutAll: 'if '.
			 (abi := InitializationOptions at: #ABI ifAbsent: []) ifNotNil:
				[s nextPutAll: (abis addLast: abi); nextPutAll: ' && ('].
			 class identifyingPredefinedMacros
				do: [:predefinedMacro| s nextPutAll: 'defined('; nextPutAll: predefinedMacro; nextPut: $)]
				separatedBy: [s nextPutAll: ' || '].
			 abi ifNotNil: [s nextPut: $)].
			 s cr; cr; nextPutAll: '#	include "'; nextPutAll: class moduleName; nextPutAll: '.c"'.
			 s cr; cr; nextPutAll: '#el'].
		 s nextPutAll: 'se'.
		 #(	'As yet no Cogit implementation appears to exist for your platform.'
			'Consider implementing it, starting by adding a subclass of CogAbstractInstruction.') do:
			[:msg| s cr; nextPutAll: '#	error '; nextPutAll: msg].
		 s cr; nextPutAll: '#endif'; cr].
	abis isEmpty ifTrue:
		[^string].
	defaultDef := String streamContents:
		[:s|
		s nextPutAll: '#if !'.
		abis do: [:abi| s nextPutAll: abi] separatedBy: [s nextPutAll: ' && !'].
		s cr; nextPutAll: '# define '; nextPutAll: abis first; nextPutAll: ' 1'; cr.
		s nextPutAll: '#endif'; cr; cr].
	^string copyReplaceFrom: insertPosition to: insertPosition - 1 with: defaultDef
]

{ #category : #accessing }
Cogit class >> generatorTable [
	^generatorTable
]

{ #category : #'class initialization' }
Cogit class >> generatorTableFrom: anArray [
	| blockCreationBytecodeSize |
	generatorTable := CArrayAccessor on: (Array new: 256).
	anArray do:
		[:tuple| | descriptor |
		(descriptor := CogBytecodeDescriptor new)
						numBytes: tuple first;
						generator: tuple fourth;
						isReturn: (tuple includes: #return);
						hasUnsafeJump: (tuple includes: #hasUnsafeJump);
						isMapped: ((tuple includes: #isMappedIfImmutability)
										ifTrue: [self bindingOf: #IMMUTABILITY]
										ifFalse: [tuple includes: #isMapped]);
						isMappedInBlock: (tuple includes: #isMappedInBlock);
						isBlockCreation: (tuple includes: #block);
						spanFunction: (((tuple includes: #block) or: [(tuple includes: #branch)]) ifTrue:
										[tuple detect: [:thing| thing isSymbol and: [thing numArgs = 4]]]);
						isBranchTrue: (tuple includes: #isBranchTrue);
						isBranchFalse: (tuple includes: #isBranchFalse);
						isExtension: (tuple includes: #extension);
						isInstVarRef: (tuple includes: #isInstVarRef);	"for Spur"
						is1ByteInstVarStore: (tuple includes: #is1ByteInstVarStore);	"for Spur"
						yourself.
		"As a hack to cut down on descriptor flags, use opcode to tag unusedBytecode for scanning.
		 Currently descriptors are exactly 16 bytes with all 8 flag bits used.
		As another hack to eliminate a test in scanMethod mark unknowns as extensions."
		descriptor generator == #unknownBytecode ifTrue:
			[descriptor opcode: Nop; isExtension: true].
		descriptor isBlockCreation ifTrue:
			[blockCreationBytecodeSize
				ifNil: [blockCreationBytecodeSize := descriptor numBytes]
				ifNotNil: [self assert: blockCreationBytecodeSize = descriptor numBytes]].
		tuple do:
			[:thing|
			thing isSymbol ifTrue:
				[(thing beginsWith: #needsFrame) ifTrue:
					[descriptor needsFrameFunction: thing].
				 (CogRTLOpcodes classPool at: thing ifAbsent: []) ifNotNil:
					[:opcode| descriptor opcode: opcode]]].
		tuple last isInteger
			ifTrue: [descriptor stackDelta: tuple last]
			ifFalse:
				[descriptor needsFrameFunction ifNotNil:
					[self error: 'frameless block bytecodes must specify a stack delta']].
		tuple second to: tuple third do:
			[:index|
			generatorTable at: index put: descriptor]].
	BlockCreationBytecodeSize := blockCreationBytecodeSize.
	^generatorTable
]

{ #category : #accessing }
Cogit class >> guardPageSize [
	^1024
]

{ #category : #translation }
Cogit class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #'class initialization' }
Cogit class >> initializeAnnotationConstants [
	"These form the method map for a cog method.  The map defines which addresses
	 in a machine code method are ones with important functions, such as being a send
	 site or being a reference to a heap object.  Each annotated instruction has a byte
	 in the map, and each byte in the map has two parts.  In the least signficant bits are
	 a distance in codeGranularity units from the start of the method or the previous
	 map entry, except for the IsAnnotationExtension type.  In the most signficant bits
	 are the type of annotation at the point reached.  A null byte ends the map.  The
	 first mapped location is a distance from the cmNoCheckEntryOffset.

	 The map occurs at the end of a method (*), in reverse, so that its start is found
	 by adding the method's block size.  If the distance between two mapped
	 instructions will not fit in the displacement field then one or more displacement
	 entries are placed in the map to bridge the gap.  There is a * 32 displacement
	 units type for spanning large gaps.  The displacements are in codeGranularity
	 units so that processors like e.g. ARM, with 4-byte instructions, do not have overly
	 large maps.  In [practice maps are very compact, but they should be as quick to
	 navigate as possible, and hence be as compact as possible.

	 There is only one kind of call annotation that serves for all calls from machine
	 code. There are several kinds of call, sends, super sends, calls of the generated
	 run-time, and direct calls of primitive functions in the interpreter.  These need
	 different treatment at different times.  For example, when the send cache is
	 flushed or the method zone is shrunk some sends must be unlinked and some
	 sends must be relocated.  But to be able to parse bytecoded methods and match
	 their pcs with corresponding machine code pcs the map needs to differentiate
	 between sends and run-time calls. 

	 Sends can be distinguished from run-time or direct primitive calls based on address;
	 only sends have their target between methodZoneBase and methodZone freeStart.
	 We used to distinguish normal sends from super sends based on alignment of
	 entry-point, because normal sends link to the checked entry-point, whereas super sends
	 link to the unchecked entry-point, and both entry points have different alignments.
	 But now we use the IsAnnotationExtension to label sends other than normal sends.
	 For these ``exotic'' sends there is both an IsAnnotationExtension annotation and an
	 IsSendCall annotation.

	 While run-time calls can be distinguished from direct primitive calls on the basis
	 of address there is no need to do so.  They are merely calls to locations that
	 don't move during method zone compaction.

	 Absolute PC references are used for method references and counter references.
	 These are references from within a particular method to absolute pcs in that same
	 method that must be relocated when the method moves."
	"self initializeAnnotationConstants"

	AnnotationShift := 5.
	IsDisplacementX2N := 0.	"N.B. A 0 byte ends the map"
	IsAnnotationExtension := 1.	"Used to extend IsSendCall with different codes for exotic send types."
	IsObjectReference := 2.
	IsAbsPCReference := 3.
	IsRelativeCall := 4.
	HasBytecodePC := 5.
	IsSendCall := 7.
	"These are formed by combining IsSendCall and IsAnnotationExtension annotations."
	IsSuperSend := 8.
	IsDirectedSuperSend := BytecodeSetHasDirectedSuperSend ifTrue: [9].
	IsDirectedSuperBindingSend := BytecodeSetHasDirectedSuperSend ifTrue: [10].

	DisplacementMask := (1 << AnnotationShift) - 1.
	DisplacementX2N := IsDisplacementX2N << AnnotationShift.
	FirstAnnotation := IsObjectReference << AnnotationShift.
	MaxX2NDisplacement := DisplacementMask << AnnotationShift.

	MapEnd := 0.

	AnnotationConstantNames := #(	IsDisplacementX2N
										IsAnnotationExtension
										IsObjectReference
										IsAbsPCReference
										IsRelativeCall
										HasBytecodePC
										IsNSSendCall
										IsSendCall
										IsSuperSend
										IsDirectedSuperSend
										IsDirectedSuperBindingSend
										IsNSSelfSend
										IsNSDynamicSuperSend
										IsNSImplicitReceiverSend).
	AnnotationsWithBytecodePCs := #(HasBytecodePC
										IsNSSendCall
										IsSendCall
										IsSuperSend
										IsDirectedSuperSend
										IsDirectedSuperBindingSend
										IsNSSelfSend
										IsNSDynamicSuperSend
										IsNSImplicitReceiverSend),
										{'IsRelativeCall:\HasBytecodePC' withCRs}
]

{ #category : #'class initialization' }
Cogit class >> initializeBytecodeTable [
	"SimpleStackBasedCogit initializeBytecodeTableWith: Dictionary new"
	"StackToRegisterMappingCogit initializeBytecodeTableWith: Dictionary new"

	| initializer |
	BytecodeSetHasDirectedSuperSend := BytecodeSetHasExtensions := false.
	initializer := InitializationOptions
					at: #bytecodeTableInitializer
					ifAbsent:
						[MULTIPLEBYTECODESETS
									ifTrue: [#initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid]
									ifFalse: [#initializeBytecodeTableForSqueakV3PlusClosures]].
	"Now make sure all classes in the hierarchy have initialized to the same bytecode table."
	(self withAllSuperclasses copyUpTo: Cogit) reverseDo: "i.e. exclude Cogit"
		[:cogitClass|
		 cogitClass perform: initializer]
]

{ #category : #'class initialization' }
Cogit class >> initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid [
	"SimpleStackBasedCogit initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid"
	"StackToRegisterMappingCogit initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid"

	| v3Table v1Table |
	"N.B. Must do it backwards to evaluate AltBlockCreationBytecodeSize & BlockCreationBytecodeSize et al correctly."
	self initializeBytecodeTableForSistaV1.
	v1Table := generatorTable.
	AltBlockCreationBytecodeSize := BlockCreationBytecodeSize.
	AltFirstSpecialSelector := FirstSpecialSelector.
	AltNumSpecialSelectors := NumSpecialSelectors.
	self initializeBytecodeTableForSqueakV3PlusClosures.
	BytecodeSetHasExtensions := true.
	v3Table := generatorTable.
	generatorTable := CArrayAccessor on: v3Table object, v1Table object
]

{ #category : #'class initialization' }
Cogit class >> initializeCogMethodConstants [
	CMOpenPIC := 1 + (CMClosedPIC := 1 + (CMBlock := 1 + (CMMethod := 1 + (CMFree := 1))))
]

{ #category : #'class initialization' }
Cogit class >> initializeErrorCodes [
	"External errors, returned to or from cog:selector:"
	NotFullyInitialized := -1.
	InsufficientCodeSpace := -2.
	MethodTooBig := -4.
	YoungSelectorInPIC := -5.
	EncounteredUnknownBytecode := -6.
	UnimplementedPrimitive := -7.
	ShouldNotJIT := -8.
	MaxNegativeErrorCode := ShouldNotJIT.
	"Internal errors returned by generator routines to other generator routines"
	BadRegisterSet := 1.
	UnimplementedOperation := 2.
	"Internal successes answered by CogObjectRepresentation to JIT, etc"
	UnfailingPrimitive := 3. "Answered by a primitive generator for a primitive that will never fail"
	CompletePrimitive := 4 "Answered by a primitive generator that does not bneed to fall back on the interpreter primitive except for an error code."
]

{ #category : #'class initialization' }
Cogit class >> initializeMiscConstants [
	super initializeMiscConstants.
	Debug := InitializationOptions at: #Debug ifAbsent: [false].
	(InitializationOptions includesKey: #EagerInstructionDecoration)
		ifTrue:
			[EagerInstructionDecoration := InitializationOptions at: #EagerInstructionDecoration]
		ifFalse:
			[EagerInstructionDecoration ifNil:
				[EagerInstructionDecoration := false]]. "speeds up single stepping but could lose fidelity"

	ProcessorClass := InitializationOptions at: #ProcessorClass ifAbsentPut: [ UnicornProcessor ].
	CogCompilerClass := self activeCompilerClass.
	(CogCompilerClass withAllSuperclasses copyUpTo: CogAbstractInstruction) reverseDo:
		[:compilerClass| compilerClass initialize; initializeAbstractRegisters].
	self objectMemoryClass objectRepresentationClass initializeMiscConstants.
	"Our criterion for which methods to JIT is literal count.  The default value is 60 literals or less."
	MaxLiteralCountForCompile := InitializationOptions at: #MaxLiteralCountForCompile ifAbsent: [60].
	"we special-case 0, 1 & 2 argument sends, N is numArgs >= 3"
	NumSendTrampolines := 4.
	"Currently not even the ceImplicitReceiverTrampoline contains object references."
	NumObjRefsInRuntime := 0.
	"6 is a fine number for the max number of PCI entries.  8 is too large."
	MaxCPICCases := 6.

	"One variable defines whether in a block and whether in a vanilla or full block."
	InVanillaBlock := 1.
	InFullBlock := 2.

	"Max size to alloca when compiling.
	 Mac OS X 10.6.8 segfaults approaching 8Mb.
	 Linux 2.6.9 segfaults above 11Mb.
	 WIndows XP segfaults approaching 2Mb."
	MaxStackAllocSize := 1024 * 1024 * 3 / 2 
]

{ #category : #'class initialization' }
Cogit class >> initializeNumTrampolines [
	NumTrampolines := self numTrampolines
						+ self objectRepresentationClass numTrampolines
						+ (BytecodeSetHasDirectedSuperSend ifTrue: [NumSendTrampolines * 2] ifFalse: [0])
]

{ #category : #'class initialization' }
Cogit class >> initializePrimitiveTable [
	self initializePrimitiveTableForSqueak
]

{ #category : #'class initialization' }
Cogit class >> initializeWithOptions: optionsDictionary [
	super initializeWithOptions: optionsDictionary.
	self initializeMiscConstants. "must precede other initialization."
	self initializeErrorCodes.
	self initializeCogMethodConstants.
	self initializeAnnotationConstants.
	self initializeBytecodeTable.
	self initializeNumTrampolines.
	self initializePrimitiveTable
]

{ #category : #'in-image compilation support' }
Cogit class >> initializedInstanceForTests: optionsDictionaryOrArray [
	"Answer an instance of a Cogit suitable for running tests that has initialized
	 its method zone (generated trampolines etc)"
	| cogit coInterpreter |
	cogit := self instanceForTests: optionsDictionaryOrArray.
	coInterpreter := CurrentImageCoInterpreterFacade forCogit: cogit.
	[cogit
		setInterpreter: coInterpreter;
		singleStep: true;
		initializeCodeZoneFrom: 1024 upTo: coInterpreter memory size.
	 cogit methodZone freeStart: (cogit methodZone freeStart roundUpTo: 1024)]
		on: Notification
		do: [:ex|
			(ex messageText beginsWith: 'cannot find receiver for') ifTrue:
				[ex resume: coInterpreter].
			ex pass].
	^cogit
]

{ #category : #'in-image compilation support' }
Cogit class >> instanceForTests: optionsDictionaryOrArray [
	"Initialize all the relevant classes from the options and answer a new instance of me."
	| initOptions |
	initOptions := self asOptionsDictionary: optionsDictionaryOrArray.
	CoInterpreter initializeWithOptions: initOptions.
	CoInterpreter objectMemoryClass initializeWithOptions: initOptions.
	self initializeWithOptions: initOptions.
	^self new
]

{ #category : #translation }
Cogit class >> isAcceptableAncilliaryClass: aClass [
	^aClass ~~ CogSSBytecodeFixup
]

{ #category : #translation }
Cogit class >> isCogitClass [
	^true
]

{ #category : #translation }
Cogit class >> isNonArgumentImplicitReceiverVariableName: aString [
	^#('cogit' 'coInterpreter'
		'methodZone' 'literalsManager'
		'objectMemory' 'objectRepresentation' 'manager') includes: aString
]

{ #category : #'in-image compilation support' }
Cogit class >> isSistaMessage: aMessageOrSelector unimplementedIn: aClass [
	| selector |
	selector := aMessageOrSelector selector.
	^(InstructionClient includesSelector: selector)
	   and: [(aClass includesSelector: selector) not]
]

{ #category : #accessing }
Cogit class >> maxNegativeErrorCode [
	^MaxNegativeErrorCode
]

{ #category : #'accessing class hierarchy' }
Cogit class >> methodZoneClass [
	^CogMethodZone
]

{ #category : #translation }
Cogit class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM
	 support code.  include cePositive32BitIntegerTrampoline as a hack to prevent it being inlined (it is
	 only used outside of Cogit by the object representation).  Include CFramePointer CStackPointer as
	 a hack to get them declared at all."
	^#(	'ceBaseFrameReturnTrampoline' #ceCaptureCStackPointers 'ceCheckForInterruptTrampoline'
		ceEnterCogCodePopReceiverReg realCEEnterCogCodePopReceiverReg
		ceCallCogCodePopReceiverReg realCECallCogCodePopReceiverReg
		ceCallCogCodePopReceiverAndClassRegs realCECallCogCodePopReceiverAndClassRegs
		'ceReturnToInterpreterTrampoline' 'ceCannotResumeTrampoline'
		ceTryLockVMOwner ceUnlockVMOwner
		'cmEntryOffset' 'cmNoCheckEntryOffset' 'cmDynSuperEntryOffset' 'cmSelfSendEntryOffset'
		'missOffset' 'cbEntryOffset' 'cbNoSwitchEntryOffset' 'blockNoContextSwitchOffset' breakPC
		CFramePointer CStackPointer 'cFramePointerInUse' ceGetFP ceGetSP
		traceFlags 'traceStores' debugPrimCallStackOffset)
			includes: var
]

{ #category : #translation }
Cogit class >> namesOfVariablesToLocalize [
	^#()
]

{ #category : #documentation }
Cogit class >> notesAndQueries [
	"Mitigating cost of bytecode to machinecode pc mapping.
		HPS's scheme is to allow contexts to contain machine-code pcs in the form of negative pc values.
		This is reified at the image level and relevant accessors must check before accessing the pc.

		We hide a similar scheme entirely within the VM.  When a spouse context of a machine-code
		frame is divorced we set its pc to the negative machine-code pc.  All accesses to the instruction
		pointer of a stable context are checked (in instVar:ofContext: and externalInstVar:ofContext:).
		If the value is negative we look for, and if not found, compile the context's method and map the
		negative pc.

		The downside of this scheme is on snapshot having to trawl through the entire image looking for
		single contexts with negative pcs and mapping them to proper bytecode pcs.  But this is a minor
		inconvenience since we scan anyway to divorce or widow married contexts."
]

{ #category : #accessing }
Cogit class >> numTrampolines [
	^39 "31 + 4 each for self and super sends"
		+ (COGMTVM ifTrue: [ 2 ] ifFalse: [ 0 ])

	"self withAllSubclasses collect: [:c| {c. (c instVarNames select: [:ea| ea beginsWith: 'ce']) size}]"
]

{ #category : #translation }
Cogit class >> preGenerationHook: aCCodeGenerator [
	"Perform any last-minute changes to the code generator immediately
	 before it performs code analysis and generation.  In this case, make
	 all non-exported methods private."
	aCCodeGenerator selectorsAndMethodsDo:
		[:s :m|
		m isAPIMethod
			ifTrue: [m static: false]
			ifFalse:
				[m export ifFalse:
					[m static: true]]]
]

{ #category : #accessing }
Cogit class >> primitiveTable [
	^primitiveTable
]

{ #category : #translation }
Cogit class >> processorSpecificSourceFileName [
	^self activeCompilerClass moduleName, '.c'
]

{ #category : #translation }
Cogit class >> requiredMethodNames: options [
	"self requiredMethodNames"
	^self tableFunctions
]

{ #category : #documentation }
Cogit class >> runtime [
	"Generated machine code makes use of a number of run-time routines for support, for executing certain primitives,
	 and for event handling.  These run-time entry points all begin with ce, for ``code entry''.  They are called from
	 trampolines whose job it is to a) switch from the Smalltalk stack to the C stack (because run-time routines are C
	 code in the CoInterpreter or Cogit and run on the C stack, whereas machine code runs on the Smalltalk stack), and
	 b) to marshall the register parameters that trampol,ines take into what ever the platform's ABI requires.
	 See the method trampolines for more info on trampoilines.

	 Here's a doit to collect the signatures of the current run-time routines
 
		(((CoInterpreter selectors select: [:ea| (ea beginsWith: 'ce') and: [ea third isUppercase]]) ,
		(SistaStackToRegisterMappingCogit allSelectors select: [:ea| (ea beginsWith: 'ce') and: [ea third isUppercase]]) asArray) sort collect:
			[:s| | m |
			m := CoInterpreter compiledMethodAt: s ifAbsent: [(SistaStackToRegisterMappingCogit whichClassIncludesSelector: s) >> s].
			s numArgs = 0
				ifTrue: [s asString]
				ifFalse:
					[(String streamContents:
						[:str|
						s keywords with: (CoInterpreter newParser parseParameterNames: m getSource) do:
							[:k :p| str nextPutAll: k; space; nextPutAll: p; nextPutAll: ' (Reg) ']]) allButLast]])


	Run-time:
		ceActivateFailingPrimitiveMethod: aPrimitiveMethod (SendNumArgsReg)
		ceActiveContext => ReceiverResultReg
		ceBaseFrameReturn: returnValue (ReceiverResultReg)
		ceBaseFrameReturnPC
		ceCPICMiss: cPIC (ClassReg) receiver: receiver (ReceiverResultReg)
		ceCall0ArgsPIC
		ceCall1ArgsPIC
		ceCall2ArgsPIC
		ceCannotResume
		ceCannotResumePC
		ceCaptureCStackPointers
		ceCheckFeatures
		ceCheckForAndFollowForwardedPrimitiveState
		ceCheckForInterrupts
		ceCheckProfileTick
		ceClosureCopyDescriptor: descriptor (SendNumArgsReg) => ReceiverResultReg
		ceContext: maybeContext (ReceiverResultReg) instVar: slotIndex (SendNumArgsReg) => ReceiverResultReg
		ceContext: maybeMarriedContext (ReceiverResultReg) instVar: slotIndex (SendNumArgsReg) value: anOop (ClassReg) => ReceiverResultReg
		ceCounterTripped: condition (TempReg)
		ceDynamicSuperSend: cacheAddress (SendNumArgsReg) receiver: methodReceiver (ReceiverResultReg)
		ceEnclosingObjectAt: level (SendNumArgsReg) => ReceiverResultReg
		ceImplicitReceiverSend: cacheAddress (SendNumArgsReg) receiver: methodReceiver (ReceiverResultReg)
		ceInterpretMethodFromPIC: aMethodObj (SendNumArgsReg) receiver: rcvr (ReceiverResultReg)
		ceMNUFromPICMNUMethod: aMethodObj (SendNumArgsReg) receiver: rcvr (ReceiverResultReg)
		ceNewArraySlotSize: slotSize (SendNumArgsReg) => ReceiverResultReg
		ceNonLocalReturn: returnValue (ReceiverResultReg)
		ceOuterSend: cacheAddress (SendNumArgsReg) receiver: methodReceiver (ReceiverResultReg)
		ceReturnToInterpreter: anOop (ReceiverResultReg)
		ceReturnToInterpreterPC
		ceSICMiss: receiver (ReceiverResultReg)
		ceScheduleScavenge
		ceSelfSend: cacheAddress (SendNumArgsReg) receiver: methodReceiver (ReceiverResultReg)
		ceSend: selector (ClassReg) above: startAssociationArg (TempReg) to: rcvr (ReceiverResultReg) numArgs: numArgs (n)
		ceSend: selector (ClassReg) super: superNormalBar (n) to: rcvr (ReceiverResultReg) numArgs: numArgs (n)
		ceSendFromInLineCacheMiss: cogMethodOrPIC (SendNumArgsReg)
		ceSendMustBeBoolean: anObject (TempReg)
		ceSistaTrap
		ceStackOverflow: contextSwitchIfNotNil (SendNumArgsReg)
		ceTraceBlockActivation
		ceTraceLinkedSend: theReceiver (ReceiverResultReg)
		ceTraceStoreOf: aValue (ClassReg) into: anObject (ReceiverResultReg)
		positive32BitIntegerFor: integerValue (ReceiverResultReg) => TempReg

	Enilopmarts:
		ceCallCogCodePopReceiverAndClassRegs
		ceCallCogCodePopReceiverArg0Regs
		ceCallCogCodePopReceiverArg1Arg0Regs
		ceCallCogCodePopReceiverReg
		ceEnterCogCodePopReceiverReg

	Simulation only
		ceShortCutTraceBlockActivation: aProcessorSimulationTrap
		ceShortCutTraceLinkedSend: aProcessorSimulationTrap
		ceShortCutTraceStore: aProcessorSimulationTrap

	Misnamed:
		ceSendAbort:to:numArgs: not a code entry.  Used by ceCannotResume, ceSendMustBeBoolean et al to execute their sends"
]

{ #category : #translation }
Cogit class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around mutliple definitions.  Sometimes a type has been defined in an include."
	^({ CogBlockMethod. CogMethod. SistaCogMethod } includes: aStructClass) not
]

{ #category : #translation }
Cogit class >> sourceFileName [
	^'cogit.c'
]

{ #category : #translation }
Cogit class >> specialValueForConstant: constantName default: defaultValue [
	constantName = 'Debug' ifTrue: [^'DEBUGVM'].
	^CoInterpreter specialValueForConstant: constantName default: defaultValue
]

{ #category : #tests }
Cogit class >> structureOfACogMethod [
	"A CogMethod is the machine code for executable code in the Cog VM, and in the simulator these are
	 instances of CogMethod.  In actuality they are structures in memory in the CogMethodZone..  There
	 are four real kinds, defined by the cmType field, free space: CMFree, methods: CMMethod, closed
	 PICs: CMClosedPIC (finite polymorphic inline caches with up to 6 entries), and open PICs: CMOpenPIC
	 (infinite megamorphicinline caches that probe the first-level method lookup cache).  There is a fifth
	 kind of method, which is merely a header, for blocks: CMBlock, one which exists only within CMMethods,
	 and exist only to allow block activations to refer to something that looks like a CogMethod.

	 The blockSize field in a CogMethod is the size in bytes of the entire method, including the header.
	 Methods are aligned to an 8 byte boundary in the CogMethodZone.  The size is used to iterate over
	 the methods in the zone.

	 Follwing the header is the abort and entry code.  Starting immediately after the header is the call to
	 the abort routine called when either a send fails or a stack limit check fails.  Following that is the
	 checked entry point that checks the receiver is of the right class, and this code ends in the unchecked
	 entry point.  Following this is either primitive code, followed by frame building code, or frame-building
	 code, or, for frameless methods, the code for the frameless method.  Following that is the code for the
	 method.  If the method contains blocks  then followng the method code will be a CMBlock header,
	 followed by code for the block, for each block, and following this will be the block dispatch code,
	 which is indexed by the blockEntryOffset field in the CogMethod.

	 Following either the return in the method, or the block dispatch, is the method map, the meta data which
	 identifies interesting points in the machine code.  The map starts at the end of the structure and is read
	 backwards towards the last instruftion of the method, and is terminated by a null byte.  So the blockSize
	 is used to find the start of the map.  The map reveals where object references, sends and pc-mapping
	 points exist in the machine code.  The map is parsed when garbage collecting to find and update object
	 references, and when unlinking sends for method cache flushing, and to convert between bytecode and
	 machine code pcs by scanning both bytecode and machine code looking for matching points in the map."
]

{ #category : #translation }
Cogit class >> tableFunctions [
	"self tableFunctions"
	self cogitClass ~= self ifTrue: [^Set new].
	generatorTable ifNil:
		[^Set new].
	^Set new
		addAll: (generatorTable object
					collect: [:ea| ea generator]);
		addAll: (generatorTable object
					select: [:ea| ea spanFunction notNil]
					thenCollect: [:ea| ea spanFunction]);
		addAll: (generatorTable object
					select: [:ea| ea needsFrameFunction notNil]
					thenCollect: [:ea| ea needsFrameFunction]);
		addAll: (primitiveTable object
					select: [:ea| ea notNil and: [ea primitiveGenerator notNil]]
					thenCollect: [:ea| ea primitiveGenerator]);
		asSortedCollection: [:a :b| a caseInsensitiveLessOrEqual: b]
]

{ #category : #translation }
Cogit class >> tableInitializerFor: aTable in: aCCodeGenerator [
	^String streamContents:
		[:s|
		s nextPutAll: ' = {'.
		aTable object
			do: [:gt|
				s crtab.
				gt printCInitializerOn: s in: aCCodeGenerator]
			separatedBy: [s nextPut: $,].
		s cr; nextPut: $}]
]

{ #category : #tests }
Cogit class >> testPCMappingFor: aCompiledMethod [
	^self testPCMappingFor: aCompiledMethod options: #()
]

{ #category : #tests }
Cogit class >> testPCMappingFor: aCompiledMethod options: optionsDictionaryOrArray [
	| tuple |
	tuple := self cog: aCompiledMethod selectorOrNumCopied: aCompiledMethod selector options: optionsDictionaryOrArray.
	tuple second testPCMappingForCompiledMethod: aCompiledMethod cogMethod: tuple last
]

{ #category : #tests }
Cogit class >> testPCMappingSelect: aBlock [
	"Test pc mapping both ways using the methods in the current image"
	self testPCMappingSelect: aBlock options: #()
]

{ #category : #tests }
Cogit class >> testPCMappingSelect: aBlock options: optionsDictionaryOrArray [
	"Test pc mapping both ways using a selection of the methods in the current image."
	| cogit coInterpreter n |
	cogit := self initializedInstanceForTests: optionsDictionaryOrArray.
	coInterpreter := cogit coInterpreter.
	n := -1.
	SystemNavigation new allSelect:
		[:m| | cm |
		(m isQuick not
		 and: [aBlock value: m]) ifTrue:
			[(n := n + 1) \\ 10 = 0 ifTrue: [Transcript nextPut: $.; flush].
			 cm := cogit
						cog: (coInterpreter oopForObject: m)
						selector: (coInterpreter oopForObject: m selector).
			  cm ifNil:
				[cogit methodZone clearCogCompiledCode.
				 coInterpreter initializeObjectMap.
				 cm := cogit
							cog: (coInterpreter oopForObject: m)
							selector: (coInterpreter oopForObject: m selector).
				cm ifNil: [Transcript show: 'After 1 Cog compiled code compaction, still not able to generate the cog method...' ] ].
			  cm ifNotNil:
				[cogit testPCMappingForCompiledMethod: m cogMethod: cm]].
		 false]
]

{ #category : #documentation }
Cogit class >> trampolines [
	"Trampolines are called from machine-code for a number of tasks (e.g. doing an unlinked send,
	 creating a closure, doing a non-local return, etc, etc.
	 Some trampolines save their return pc on the Smalltalk stack, and some pop it into instructionPointer,
	 depending on whether the trampoline always returns or whether control might transfer elsewhere,
	 or depending on whether the callee run-time routine expects to see a normal Smalltalk stack.  This
	 documents which trampolines do what and why.

ceSend0Args .. ceSendNArgs, ceSuperSend0Args..ceSuperSendNArgs
	return pc left on stack because it is the return pc of the send and must be there

ceMethodAbort, cePICAbort
	return pc left on stack because it is used to locate the failing send target method/PIC of a linked send

ceClosureCopyTrampoline
	return pc left on stack because ceClosureCopy:... always returns directly

cePushActiveContextTrampoline
	return pc left on stack because cePushActiveContext always returns directly

ceNonLocalReturnTrampoline
	pops return pc into instructionPointer

ceBaseFrameReturnTrampoline
	this is returned-to and never called; i.e. it is the return pc of a base machine-code frame

ceCreateNewArrayTrampoline
	return pc left on stack because ceNewArraySlotSize always returns directly

ceSendMustBeBooleanTrampoline
	return pc left on stack because it is the return pc of the send and must be there

ceCheckForInterruptsTrampoline
	pops return pc into instructionPointer

ceCPICMissTrampoline
	return pc left on stack because it is used to locate the failing send target PIC of a linked send

ceSendFromInLineCacheMissTrampoline
	not used, but its address is used as a key in the simulator.  An open PIC calls ceSendFromInLineCacheMiss
	after it has switched from the Smalltalk to the C stack (an inline trampoline) hence there is no return pc
	left on the Smalltalk stack (except that of the send that invoked the open PIC).

ceStoreCheckTrampoline
	return pc left on stack because ceStoreCheck always returns directly

ceFetchContextInstVarTrampoline
	return pc left on stack because ceContextInstVar always returns directly.
	ceContextInstVar manages popping the pc into instructionPointer if necessary.

ceStoreContextInstVarTrampoline
	return pc left on stack because ceContextInstVarvalue always returns directly.
	ceContextInstVarvalue manages popping the pc into instructionPointer if necessary.

cePositive32BitIntegerTrampoline
	return pc left on stack because cePositive32BitInteger always returns directly
	
ceReturnToInterpreterTrampoline
	this is returned-to and never called; i.e. it is the return pc of a machine-code frame with an interpreted callee

ceResendCannotReturnTrampoline
	this is returned-to and never called; it is the pc for a machine-code frame which has been returned from

ceEnterCogCodePopReceiverReg
	this is an enilopmart and not called from machine code

cePrimReturnEnterCogCode
	this is an enilopmart and not called from machine code

ceTraceLinkedSendTrampoline
	return pc left on stack because ceTraceLinkedSend always returns directly

ceTraceBlockActivationTrampoline
	return pc left on stack because ceTraceBlockActivation always returns directly

ceTraceStoreTrampoline
	return pc left on stack because ceTraceStore always returns directly"
]

{ #category : #translation }
Cogit class >> translateableInstructionSubclassesAndInstalledOptionsDo: aBlock [
	"Evaluate aBlock with the translateable subclass and its options installed, being careful to clean-up afterwards."
	CogAbstractInstruction translateableSubclassesAndOptions do:
		[:pair|
		[:class :options| | toRemove |
		 toRemove := Set new.
		 options pairsDo:
			[:key :value|
			 (InitializationOptions includesKey: key) ifFalse:
				[toRemove add: key].
			 InitializationOptions at: key put: value].
		 aBlock value: class.
		 toRemove do: [:key| InitializationOptions removeKey: key]]
			valueWithArguments: pair]
]

{ #category : #translation }
Cogit class >> typeForSelf [
	^#implicit
]

{ #category : #'abstract instructions' }
Cogit >> AddCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AddCqR quickConstant: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> AddCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AddCwR literal: wordConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> AddR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AddRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> AddRd: dpreg1 Rd: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AddRdRd operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> AddRs: dpreg1 Rs: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AddRsRs operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> AddcCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AddcCqR quickConstant: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> AddcR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AddcRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> AlignmentNops: alignment [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AlignmentNops operand: alignment
]

{ #category : #'abstract instructions' }
Cogit >> AndCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AndCqR quickConstant: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> AndCq: quickConstant R: srcReg R: destReg [
	<inline: false>
	<returnTypeC: #'AbstractInstruction *'>
	| first |
	<var: 'first' type: #'AbstractInstruction *'>
	backEnd hasThreeAddressArithmetic ifTrue:
		[^self gen: AndCqRR quickConstant: quickConstant operand: srcReg operand: destReg].
	srcReg = destReg ifTrue:
		[^self gen: AndCqR quickConstant: quickConstant operand: destReg.].
	first := self gen: MoveRR operand: srcReg operand: destReg.
	self gen: AndCqR quickConstant: quickConstant operand: destReg.
	^first
]

{ #category : #'abstract instructions' }
Cogit >> AndCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AndCwR literal: wordConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> AndR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AndRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> ArithmeticShiftRightCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: ArithmeticShiftRightCqR operand: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> ArithmeticShiftRightR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: ArithmeticShiftRightRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> Call: callTarget [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: Call operand: callTarget
]

{ #category : #'abstract instructions' }
Cogit >> CallFull: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: CallFull literal: jumpTarget
]

{ #category : #'method map' }
Cogit >> CallFullRT: callTarget [
	"Big assumption here that calls and jumps look the same as regards their displacement.
	 This works on at least x86, ARM and x86_64.
	 CallFull is intended to be for calls anywhere in our address space.
	 See also Call which calls within our *code* space"
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^backEnd fullCallsAreRelative
		ifTrue: [self annotateCall: (self CallFull: callTarget)]
		ifFalse: [self CallFull: callTarget]
]

{ #category : #'compile abstract instructions' }
Cogit >> CallFullRT: callTarget registersToBeSavedMask: registersToBeSaved [
	<returnTypeC: #'AbstractInstruction *'>
	| callerSavedRegsToBeSaved lastInst reg registersToBePushed |
	<var: 'lastInst' type: #'AbstractInstruction *'>
	callerSavedRegsToBeSaved := CallerSavedRegisterMask bitAnd: registersToBeSaved.

	backEnd canPushPopMultipleRegisters
		ifTrue: [backEnd genPushRegisterMask: callerSavedRegsToBeSaved]
		ifFalse:
			[registersToBePushed := callerSavedRegsToBeSaved.
			 reg := 0.
			 [registersToBePushed ~= 0] whileTrue:
				[(registersToBePushed anyMask: 1) ifTrue:
					[self PushR: reg].
				 reg := reg + 1.
				 registersToBePushed := registersToBePushed >>> 1]].

	lastInst := self CallFullRT: callTarget.

	backEnd canPushPopMultipleRegisters
		ifTrue: [^backEnd genPopRegisterMask: callerSavedRegsToBeSaved]
		ifFalse:
			[[reg > 0] whileTrue:
				[reg := reg - 1.
				(callerSavedRegsToBeSaved anyMask: 1 << reg) ifTrue:
					[lastInst := self PopR: reg]].

			 ^lastInst]
]

{ #category : #'abstract instructions' }
Cogit >> CallR: callTarget [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: CallR operand: callTarget
]

{ #category : #'method map' }
Cogit >> CallRT: callTarget [
	"Big assumption here that calls and jumps look the same as regards their displacement.
	 This works on at least x86, ARM and x86_64."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self annotateCall: (self Call: callTarget)
]

{ #category : #'compile abstract instructions' }
Cogit >> CallRT: callTarget registersToBeSavedMask: registersToBeSaved [
	<returnTypeC: #'AbstractInstruction *'>
	| callerSavedRegsToBeSaved lastInst reg registersToBePushed |
	<var: 'lastInst' type: #'AbstractInstruction *'>
	callerSavedRegsToBeSaved := CallerSavedRegisterMask bitAnd: registersToBeSaved.

	backEnd canPushPopMultipleRegisters
		ifTrue: [backEnd genPushRegisterMask: callerSavedRegsToBeSaved]
		ifFalse:
			[registersToBePushed := callerSavedRegsToBeSaved.
			 reg := 0.
			 [registersToBePushed ~= 0] whileTrue:
				[(registersToBePushed anyMask: 1) ifTrue:
					[self PushR: reg].
				 reg := reg + 1.
				 registersToBePushed := registersToBePushed >>> 1]].

	lastInst := self CallRT: callTarget.

	backEnd canPushPopMultipleRegisters
		ifTrue: [^backEnd genPopRegisterMask: callerSavedRegsToBeSaved]
		ifFalse:
			[[reg > 0] whileTrue:
				[reg := reg - 1.
				(callerSavedRegsToBeSaved anyMask: 1 << reg) ifTrue:
					[lastInst := self PopR: reg]].

			 ^lastInst]
]

{ #category : #'abstract instructions' }
Cogit >> CmpC32: wordConstant R: reg [
	"Generate a CmpC32R instruction to compare a 32-bit constant with a
	 register.  If this is a 32-bit platform, simply generate a CmpCwR instruction,
	 to avoid needless duplication in the 32-bit code generators.."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self
		gen: (objectMemory wordSize = 8
				ifTrue: [CmpC32R]
				ifFalse: [CmpCwR])
		literal: wordConstant
		operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> CmpCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: CmpCqR quickConstant: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> CmpCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: CmpCwR literal: wordConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> CmpR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: CmpRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> CmpRd: dpreg1 Rd: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: CmpRdRd operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> CmpRs: dpreg1 Rs: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: CmpRsRs operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> ConvertR: reg1 Rd: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: ConvertRRd operand: reg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> ConvertR: reg1 Rs: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: ConvertRRs operand: reg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> ConvertRd: reg1 R: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: ConvertRdR operand: reg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> ConvertRd: reg1 Rs: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: ConvertRdRs operand: reg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> ConvertRs: reg1 R: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: ConvertRsR operand: reg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> ConvertRs: reg1 Rd: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: ConvertRsRd operand: reg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> DivR: rDivisor R: rDividend Quo: rQuotient Rem: rRemainder [
	"Division is a little weird on some processors.  Defer to the backEnd
	 to allow it to generate any special code it may need to."
	<returnTypeC: #'AbstractInstruction *'>
	<inline: false>
	backEnd genDivR: rDivisor R: rDividend Quo: rQuotient Rem: rRemainder.
	^self abstractInstructionAt: opcodeIndex - 1
]

{ #category : #'abstract instructions' }
Cogit >> DivRd: dpreg1 Rd: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: DivRdRd operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> DivRs: dpreg1 Rs: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: DivRsRs operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> Fill32: value [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: Fill32 operand: value
]

{ #category : #'abstract instructions' }
Cogit >> Jump: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: Jump operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpAbove: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpAbove operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpAboveOrEqual: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpAboveOrEqual operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpBelow: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpBelow operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpBelowOrEqual: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpBelowOrEqual operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpCarry: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpCarry operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpFPEqual: jumpTarget [
	"Floating-point jumps are a little weird on some processors.  Defer to
	 the backEnd to allow it to generate any special code it may need to."
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	<inline: false>
	^backEnd genJumpFPEqual: jumpTarget
]

{ #category : #'abstract instructions' }
Cogit >> JumpFPGreater: jumpTarget [
	"Floating-point jumps are a little weird on some processors.  Defer to
	 the backEnd to allow it to generate any special code it may need to."
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	<inline: false>
	^backEnd genJumpFPGreater: jumpTarget
]

{ #category : #'abstract instructions' }
Cogit >> JumpFPGreaterOrEqual: jumpTarget [
	"Floating-point jumps are a little weird on some processors.  Defer to
	 the backEnd to allow it to generate any special code it may need to."
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	<inline: false>
	^backEnd genJumpFPGreaterOrEqual: jumpTarget
]

{ #category : #'abstract instructions' }
Cogit >> JumpFPLess: jumpTarget [
	"Floating-point jumps are a little weird on some processors.  Defer to
	 the backEnd to allow it to generate any special code it may need to."
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	<inline: false>
	^backEnd genJumpFPLess: jumpTarget
]

{ #category : #'abstract instructions' }
Cogit >> JumpFPLessOrEqual: jumpTarget [
	"Floating-point jumps are a little weird on some processors.  Defer to
	 the backEnd to allow it to generate any special code it may need to."
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	<inline: false>
	^backEnd genJumpFPLessOrEqual: jumpTarget
]

{ #category : #'abstract instructions' }
Cogit >> JumpFPNotEqual: jumpTarget [
	"Floating-point jumps are a little weird on some processors.  Defer to
	 the backEnd to allow it to generate any special code it may need to."
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	<inline: false>
	^backEnd genJumpFPNotEqual: jumpTarget
]

{ #category : #'abstract instructions' }
Cogit >> JumpFull: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: JumpFull literal: jumpTarget asInteger
]

{ #category : #'method map' }
Cogit >> JumpFullRT: callTarget [
	"Big assumption here that calls and jumps look the same as regards their displacement.
	 This works on at least x86, ARM and x86_64.
	 JumpFull is intended to be for jumps anywhere in our address space.
	 See also JumpLong et al. which jump within our *code* space"
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^backEnd fullCallsAreRelative
		ifTrue: [self annotateCall: (self JumpFull: callTarget)]
		ifFalse: [self JumpFull: callTarget]
]

{ #category : #'abstract instructions' }
Cogit >> JumpGreater: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpGreater operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpGreaterOrEqual: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpGreaterOrEqual operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpLess: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpLess operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpLessOrEqual: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpLessOrEqual operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpLong: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: JumpLong operand: jumpTarget
]

{ #category : #'abstract instructions' }
Cogit >> JumpLongNonZero: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self genConditionalBranch: JumpLongNonZero operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpLongZero: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self genConditionalBranch: JumpLongZero operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpMultiplyOverflow: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^ backEnd genJumpMultiplyOverflow: jumpTarget
]

{ #category : #'abstract instructions' }
Cogit >> JumpNegative: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpNegative operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpNoCarry: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpNoCarry operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpNoOverflow: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpNoOverflow operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpNonNegative: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpNonNegative operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpNonZero: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpNonZero operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpOverflow: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpOverflow operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpR: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: JumpR operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> JumpZero: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self genConditionalBranch: JumpZero operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> Label [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: Label operand: (labelCounter := labelCounter + 1) operand: bytecodePC
]

{ #category : #'abstract instructions' }
Cogit >> LoadEffectiveAddressMw: offset r: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: LoadEffectiveAddressMwrR quickConstant: offset operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> LogicalShiftLeftCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: LogicalShiftLeftCqR operand: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> LogicalShiftLeftR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: LogicalShiftLeftRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> LogicalShiftRightCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: LogicalShiftRightCqR operand: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> LogicalShiftRightR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: LogicalShiftRightRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> MoveA32: address R: reg [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: (objectMemory wordSize = 8
					ifTrue: [MoveA32R]
					ifFalse: [MoveAwR])
		literal: address
		operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> MoveAb: address R: reg [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveAbR literal: address operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> MoveAw: address R: reg [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveAwR literal: address operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> MoveC32: wordConstant R: reg [
	"Generate a MoveC32R instruction to move a 32-bit constant into a register.
	 If this is a 32-bit platform, simply generate a MoveCwR instruction, to avoid
	 needless duplication in the 32-bit code generators.."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self
		gen: (objectMemory wordSize = 8
				ifTrue: [MoveC32R]
				ifFalse: [MoveCwR])
		literal: wordConstant
		operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> MoveCf32: constantFloat32 Rs: register [
	<inline: true>
	<var: #constantFloat32 type: #float>
	<returnTypeC: #'AbstractInstruction *'>
	^ backEnd genMoveCf32: constantFloat32 Rs: register
]

{ #category : #'abstract instructions' }
Cogit >> MoveCf64: constantFloat64 Rd: register [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #constantFloat64 type: #double>
	^ backEnd genMoveCf64: constantFloat64 Rd: register
]

{ #category : #'abstract instructions' }
Cogit >> MoveCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveCqR quickConstant: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> MoveCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveCwR literal: wordConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> MoveM16: offset r: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveM16rR quickConstant: offset operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveM32: offset r: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveM32rR quickConstant: offset operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveM32: offset r: baseReg Rs: destDPReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveM32rRs quickConstant: offset operand: baseReg operand: destDPReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveM64: offset r: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	self assert: BytesPerWord = 8.
	^self MoveMw: offset r: baseReg R: destReg

]

{ #category : #'abstract instructions' }
Cogit >> MoveM64: offset r: baseReg Rd: destDPReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveM64rRd quickConstant: offset operand: baseReg operand: destDPReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveM8: offset r: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveM8rR quickConstant: offset operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveMb: offset r: baseReg R: destReg [
	"N.B.  This instruction is guaranteed to zero-extend the byte into destReg."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveMbrR quickConstant: offset operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveMw: offset r: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveMwrR quickConstant: offset operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MovePatcheableC32: wordConstant R: reg [
	"Generate a MoveC32R instruction to move a 32-bit constant into a register.
	 If the backEnd is using out-of-line literals then those for inline caches cannot be shared,
	 and this method ensures the instruction has its own unique label.  If the backEnd is using
	 in-line literals then the literal is unique anyway and this is equivalent to MoveC32:R:.
	 If this is a 32-bit platform, simply generate a MoveCwR instruction, to avoid
	 needless duplication in the 32-bit code generators.."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	"If we are in 64 bits, we use indexes, so are already encoded as unique literals in the instruction.
	Otherwise, they will be selector references that must be stored as literals"
	
	^literalsManager
		uniqueLiteral: wordConstant
		forInstruction: (self gen: MovePatcheableC32R operand: wordConstant operand: reg)
	"^ (objectMemory wordSize = 8) ifTrue: [ 
		self
			gen: MoveC32R
			operand: wordConstant
			operand: reg
	] ifFalse: [ 
		self
			gen: MoveCwR
			uniqueLiteral: wordConstant
			operand: reg ]"
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: reg A32: address [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: (objectMemory wordSize = 8
					ifTrue: [MoveRA32]
					ifFalse: [MoveRAw])
		operand: reg
		literal: address
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: reg Ab: address [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRAb operand: reg literal: address
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: reg Aw: address [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRAw operand: reg literal: address
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: srcReg M16: offset r: baseReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRM16r operand: srcReg quickConstant: offset operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: sourceReg M32: offset r: baseReg [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRM32r operand: sourceReg quickConstant: offset operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: sourceReg M64: offset r: baseReg [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	self assert: BytesPerWord = 8.
	^self MoveR: sourceReg Mw: offset r: baseReg 
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: sourceReg M8: offset r: baseReg [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRM8r operand: sourceReg quickConstant: offset operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: sourceReg Mb: offset r: baseReg [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRMbr operand: sourceReg quickConstant: offset operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: sourceReg Mw: offset r: baseReg [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRMwr operand: sourceReg quickConstant: offset operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: srcReg Rd: destDPReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	self assert: objectMemory wordSize = 8.
	^self gen: MoveRRd operand: srcReg operand: destDPReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: sourceReg X32r: indexReg R: baseReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRX32rR operand: sourceReg operand: indexReg operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: srcReg Xbr: indexReg R: baseReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRXbrR operand: srcReg operand: indexReg operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: sourceReg Xwr: indexReg R: baseReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRXwrR operand: sourceReg operand: indexReg operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveRd: sourceDPReg M64: offset r: baseReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRdM64r operand: sourceDPReg quickConstant: offset operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveRd: srcDPReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	self assert: objectMemory wordSize = 8.
	^self gen: MoveRdR operand: srcDPReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveRd: dpreg1 Rd: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRdRd operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> MoveRs: sourceDPReg M32: offset r: baseReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRsM32r operand: sourceDPReg quickConstant: offset operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveRs: dpreg1 Rs: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRsRs operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> MoveUniqueCw: wordConstant R: reg [
	"If the backEnd is using out-of-line literals then those for inline caches cannot be shared, and
	 this method ensures the instruction has its own unique label.  If the backEnd is using
	 in-line literals then the literal is unique anyway and this is equivalent to MoveCw:R:"
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveCwR uniqueLiteral: wordConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> MoveX32r: indexReg R: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveX32rRR operand: indexReg operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveXbr: indexReg R: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveXbrRR operand: indexReg operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveXwr: indexReg R: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveXwrRR operand: indexReg operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MulR: reg1 R: reg2 [
	"Multiplication is a little weird on some processors.  Defer to the backEnd
	 to allow it to generate any special code it may need to."
	<inline: true>
	^backEnd genMulR: reg1 R: reg2
]

{ #category : #'abstract instructions' }
Cogit >> MulRd: dpreg1 Rd: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MulRdRd operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> MulRs: dpreg1 Rs: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MulRsRs operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> NegateR: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: NegateR operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> Nop [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: Nop
]

{ #category : #'abstract instructions' }
Cogit >> NotR: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: NotR operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> OrCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: OrCqR quickConstant: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> OrCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: OrCwR literal: wordConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> OrR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: OrRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> PopR: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: PopR operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> PopRd: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^ backEnd genPopRd: reg
]

{ #category : #'abstract instructions' }
Cogit >> PopRs: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^ backEnd genPopRs: reg
]

{ #category : #'abstract instructions' }
Cogit >> PrefetchAw: address [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: PrefetchAw literal: address
]

{ #category : #'abstract instructions' }
Cogit >> PushC64: constant64Bits [
	<inline: true>
	<var: #constant64Bits type: #sqLong>
	<returnTypeC: #'AbstractInstruction *'>
	^ backEnd genPushC64: constant64Bits
]

{ #category : #'abstract instructions' }
Cogit >> PushCq: wordConstant [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: PushCq quickConstant: wordConstant
]

{ #category : #'abstract instructions' }
Cogit >> PushCw: wordConstant [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: PushCw literal: wordConstant
]

{ #category : #'abstract instructions' }
Cogit >> PushR: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: PushR operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> PushRd: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^ backEnd genPushRd: reg
]

{ #category : #'abstract instructions' }
Cogit >> PushRs: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^ backEnd genPushRs: reg
]

{ #category : #'abstract instructions' }
Cogit >> RetN: offset [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: RetN operand: offset
]

{ #category : #'abstract instructions' }
Cogit >> RotateLeftCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: RotateLeftCqR operand: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> RotateRightCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: RotateRightCqR operand: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> SignExtend16R: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	backEnd canSignExtend
		ifTrue: [^self gen: SignExtend16RR operand: reg1 operand: reg2]
		ifFalse:
			[| first |
			 reg1 = reg2
				ifTrue:
					[first := self LogicalShiftLeftCq: BytesPerWord * 8 - 16 R: reg1]
				ifFalse:
					[first := self MoveR: reg1 R: reg2.
					 self LogicalShiftLeftCq: BytesPerWord * 8 - 16 R: reg1].
			self ArithmeticShiftRightCq: BytesPerWord * 8 - 16 R: reg2.
			^first]
]

{ #category : #'abstract instructions' }
Cogit >> SignExtend32R: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	backEnd canSignExtend
		ifTrue: [^self gen: SignExtend32RR operand: reg1 operand: reg2]
		ifFalse:
			[| first |
			 reg1 = reg2
				ifTrue:
					[first := self LogicalShiftLeftCq: 32 R: reg1]
				ifFalse:
					[first := self MoveR: reg1 R: reg2.
					 self LogicalShiftLeftCq: 32 R: reg1].
			self ArithmeticShiftRightCq: 32 R: reg2.
			^first]
]

{ #category : #'abstract instructions' }
Cogit >> SignExtend8R: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	backEnd canSignExtend
		ifTrue: [^self gen: SignExtend8RR operand: reg1 operand: reg2]
		ifFalse:
			[| first |
			 reg1 = reg2
				ifTrue:
					[first := self LogicalShiftLeftCq: BytesPerWord * 8 - 8 R: reg1]
				ifFalse:
					[first := self MoveR: reg1 R: reg2.
					 self LogicalShiftLeftCq: BytesPerWord * 8 - 8 R: reg1].
			self ArithmeticShiftRightCq: BytesPerWord * 8 - 8 R: reg2.
			^first]
]

{ #category : #'abstract instructions' }
Cogit >> SqrtRd: dpreg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SqrtRd operand: dpreg
]

{ #category : #'abstract instructions' }
Cogit >> SqrtRs: dpreg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SqrtRs operand: dpreg
]

{ #category : #'abstract instructions' }
Cogit >> Stop [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: Stop
]

{ #category : #'abstract instructions' }
Cogit >> SubCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SubCqR quickConstant: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> SubCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SubCwR literal: wordConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> SubR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SubRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> SubRd: dpreg1 Rd: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SubRdRd operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> SubRs: dpreg1 Rs: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SubRsRs operand: dpreg1 operand: dpreg2
]

{ #category : #'abstract instructions' }
Cogit >> SubbCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SubbCqR quickConstant: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> SubbR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SubbRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> SwapR: regA R: regB Scratch: regTmp [
	<returnTypeC: #'AbstractInstruction *'>
	^backEnd genSwapR: regA R: regB Scratch: regTmp
]

{ #category : #'abstract instructions' }
Cogit >> TstCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: TstCqR quickConstant: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> XorCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: XorCwR literal: wordConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> XorR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: XorRR operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> XorRd: reg1 Rd: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: XorRdRd operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> XorRs: reg1 Rs: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: XorRsRs operand: reg1 operand: reg2
]

{ #category : #'abstract instructions' }
Cogit >> ZeroExtend16R: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	backEnd canZeroExtend
		ifTrue: [^self gen: ZeroExtend16RR operand: reg1 operand: reg2]
		ifFalse:
			[| first |
			 reg1 = reg2
				ifTrue:
					[first := self LogicalShiftLeftCq: BytesPerWord * 8 - 16 R: reg1]
				ifFalse:
					[first := self MoveR: reg1 R: reg2.
					 self LogicalShiftLeftCq: BytesPerWord * 8 - 16 R: reg1].
			self LogicalShiftRightCq: BytesPerWord * 8 - 16 R: reg2.
			^first]
]

{ #category : #'abstract instructions' }
Cogit >> ZeroExtend32R: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	backEnd canZeroExtend
		ifTrue: [^self gen: ZeroExtend32RR operand: reg1 operand: reg2]
		ifFalse:
			[| first |
			 reg1 = reg2
				ifTrue:
					[first := self LogicalShiftLeftCq: 32 R: reg1]
				ifFalse:
					[first := self MoveR: reg1 R: reg2.
					 self LogicalShiftLeftCq: 32 R: reg1].
			self LogicalShiftRightCq: 32 R: reg2.
			^first]
]

{ #category : #'abstract instructions' }
Cogit >> ZeroExtend8R: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	backEnd canZeroExtend
		ifTrue: [^self gen: ZeroExtend8RR operand: reg1 operand: reg2]
		ifFalse:
			[| first |
			 reg1 = reg2
				ifTrue:
					[first := self LogicalShiftLeftCq: BytesPerWord * 8 - 8 R: reg1]
				ifFalse:
					[first := self MoveR: reg1 R: reg2.
					 self LogicalShiftLeftCq: BytesPerWord * 8 - 8 R: reg1].
			self LogicalShiftRightCq: BytesPerWord * 8 - 8 R: reg2.
			^first]
]

{ #category : #'in-line cacheing' }
Cogit >> abortOffset [
	<api>
	^missOffset
]

{ #category : #testing }
Cogit >> abstractInstruction: theAbstractInstruction follows: anAbstractInstruction [
	<var: #theAbstractInstruction type: #'AbstractInstruction *'>
	<var: #anAbstractInstruction  type: #'AbstractInstruction *'>
	^theAbstractInstruction > anAbstractInstruction
]

{ #category : #'compile abstract instructions' }
Cogit >> abstractInstructionAt: index [
	<cmacro: '(index) (&abstractOpcodes[index])'>
	<returnTypeC: #'AbstractInstruction *'>
	((debugOpcodeIndices includes: index)
	 and: [breakMethod isNil or: [methodObj = breakMethod]]) ifTrue:
		[self halt].
	^abstractOpcodes at: index
]

{ #category : #accessing }
Cogit >> abstractOpcodes [
	"For CogAbstractInstruction>>#>, which in turn is for Cogit>>abstractInstruction:follows:"
	<doNotGenerate>
	^abstractOpcodes
]

{ #category : #'jit - api' }
Cogit >> addAllToYoungReferrers [
	<doNotGenerate>
	methodZone addAllToYoungReferrers
]

{ #category : #'compile abstract instructions' }
Cogit >> addBlockStartAt: bcpc numArgs: numArgs numCopied: numCopied span: span [
	"Add a blockStart for an embedded block.  For a binary tree walk block dispatch
	 blocks must be compiled in pc/depth-first order but are scanned in breadth-first
	 order, so do an insertion sort (which of course is really a bubble sort because we
	 have to move everything higher to make room)."
	<returnTypeC: #'BlockStart *'>
	| i blockStart |
	<var: #blockStart type: #'BlockStart *'>
	blockCount > 0
		ifTrue:
			[i := blockCount - 1.
			 [blockStart := self addressOf: (blockStarts at: i).
			   blockStart startpc > bcpc
			   and: [i > 0]] whileTrue:
				[i := i - 1].
			 blockCount to: i + 1 by: -1 do:
				[:j|
				blockStarts at: j put: (blockStarts at: j - 1)].
			blockStart := self cCode: [self addressOf: (blockStarts at: i + 1)]
								inSmalltalk: [blockStarts at: i + 1 put: CogBlockStart new]]
		ifFalse:
			[blockStart := self cCode: [self addressOf: (blockStarts at: blockCount)]
								inSmalltalk: [blockStarts at: blockCount put: CogBlockStart new]].
	blockCount := blockCount + 1.
	blockStart
		startpc: bcpc;
		numArgs: numArgs;
		numCopied: numCopied;
		stackCheckLabel: nil;
		hasInstVarRef: false;
		span: span.
	^blockStart
]

{ #category : #'compile abstract instructions' }
Cogit >> addCleanBlockStarts [
	1 to: (objectMemory literalCountOf: methodObj) do:
		[:i| | lit |
		lit := coInterpreter fetchPointer: i ofObject: methodObj.
		(coInterpreter startPCOrNilOfLiteral: lit in: methodObj) ifNotNil:
			[:startPCOrNil|
			 maxLitIndex := maxLitIndex max: i.
			 self addBlockStartAt: startPCOrNil - 1 "1-rel => 0-rel"
				numArgs: (coInterpreter argumentCountOfClosure: lit)
				numCopied: (coInterpreter copiedValueCountOfClosure: lit)
				span: (self spanForCleanBlockStartingAt: startPCOrNil - 1)]]
]

{ #category : #debugging }
Cogit >> addCogMethodsToHeapMap [
	<api>
	"Perform an integrity/leak check using the heapMap.
	 Set a bit at each cog method's header."	
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod ifTrue:
			[coInterpreter heapMapAtWord: cogMethod Put: 1].
		cogMethod := methodZone methodAfter: cogMethod]
]

{ #category : #'method map' }
Cogit >> addToMap: annotation instruction: instruction byte: byte at: address for: mcpc [
	<inline: true>
	objectMemory byteAt: address put: byte.
	self cCode: [] inSmalltalk:
		[| s bytecode |
		(compilationTrace anyMask: 64) ifTrue:
			[(s := coInterpreter transcript)
				ensureCr;
				print: annotation; nextPut: $/; nextPutAll: byte hex; space;
				nextPutAll: address hex; space; nextPutAll: mcpc hex; space;
				nextPutAll: (AnnotationConstantNames detect: [:name| (Cogit classPool at: name ifAbsent: []) = annotation]); cr; flush.
			 (instruction notNil
			  and: [instruction bcpc isInteger]) ifTrue:
				[s tab; print: instruction bcpc; nextPut: $/.
				 instruction bcpc printOn: s base: 16.
				 s space.
				 instruction printStateOn: s.
				 s space.
				 bytecode := objectMemory fetchByte: instruction bcpc ofObject: methodObj.
				 bytecode := bytecode + (self bytecodeSetOffsetForHeader: methodHeader).
				 (self generatorAt: bytecode) printStateOn: s.
				 s cr; flush]]]
]

{ #category : #testing }
Cogit >> addressIsInCodeZone: address [
	<inline: true>
	^address asUnsignedInteger >= codeBase
	  and: [address < methodZone zoneEnd]
]

{ #category : #testing }
Cogit >> addressIsInCurrentCompilation: address [
	<inline: true>
	^address asUnsignedInteger >= methodLabel address
	  and: [address asUnsignedInteger < methodZone youngReferrers]
]

{ #category : #testing }
Cogit >> addressIsInFixups: address [
	<var: #address type: #'BytecodeFixup *'>
	^self cCode: '(BytecodeFixup *)address >= fixups && (BytecodeFixup *)address < (fixups + numAbstractOpcodes)'
		inSmalltalk:
			[fixups notNil
			 and: [(fixups object identityIndexOf: address) between: 1 and: numAbstractOpcodes]]
]

{ #category : #testing }
Cogit >> addressIsInInstructions: address [
	<var: #address type: #'AbstractInstruction *'>
	^self cCode: '!((usqInt)(address) & BytesPerWord-1) \
				&& (address) >= &abstractOpcodes[0] \
				&& (address) < &abstractOpcodes[opcodeIndex]'
		inSmalltalk: [(abstractOpcodes object identityIndexOf: address) between: 1 and: opcodeIndex]
]

{ #category : #'in-line cacheing' }
Cogit >> addressOfEndOfCase: n inCPIC: cPIC [ 
	"calculate the end of the n'th case statement - which is complicated because we have case 1 right at the top of our CPIC and then build up from the last one. Yes I know this sounds strange, but trust me - I'm an Engineer, we do things backwards all the emit"

	<var: #cPIC type: #'CogMethod *'>
	self assert: (n >= 1and: [n <= MaxCPICCases]).
	^n = 1
		ifTrue: [cPIC asInteger + firstCPICCaseOffset]
		ifFalse: [cPIC asInteger + firstCPICCaseOffset + (MaxCPICCases + 1 - n * cPICCaseSize)]
]

{ #category : #accessing }
Cogit >> addressSpaceMask [
	<doNotGenerate>
	"Quad-byte-align, because the ARM requires 4-byte aligned jump & call targets."
	^((1 << (8 * objectMemory wordSize)) - 1) bitAnd: -4
]

{ #category : #'generate machine code' }
Cogit >> alignUptoRoutineBoundary: anAddress [ 
	^anAddress + 7 bitClear: 7
]

{ #category : #accessing }
Cogit >> allButTopBitOfAddressSpaceMask [
	<doNotGenerate>
	"Quad-byte-align, because the ARM requires 4-byte aligned jump & call targets."
	^((1 << (8 * objectMemory wordSize - 1)) - 1) bitAnd: -4
]

{ #category : #disassembly }
Cogit >> allCogMethodsFor: cogMethod [
	<doNotGenerate>
	| blockEntry end methods pc |
	cogMethod isInteger ifTrue: [^self allCogMethodsFor: (self cogMethodSurrogateAt: cogMethod)].
	cogMethod cmType = CMBlock ifTrue:
		[^self allCogMethodsFor: cogMethod cmHomeMethod].
	(cogMethod cmType ~= CMMethod
	 or: [cogMethod blockEntryOffset = 0]) ifTrue:
		[^{cogMethod}].

	methods := OrderedCollection with: cogMethod.
	pc := blockEntry := cogMethod blockEntryOffset + cogMethod asInteger.
	end := (self mapEndFor: cogMethod) - 1.
	[pc < end] whileTrue:
		[| targetpc |
		 targetpc := blockEntry.
		 (backEnd isJumpAt: pc) ifTrue:
			[targetpc := backEnd jumpTargetPCAt: pc.
			 targetpc < blockEntry ifTrue:
				[methods add: (self cCoerceSimple: targetpc - (self sizeof: CogBlockMethod) to: #'CogBlockMethod *')]].
		 pc := pc + (backEnd instructionSizeAt: pc)].
	^methods sort
]

{ #category : #'garbage collection' }
Cogit >> allMachineCodeObjectReferencesValid [
	"Check that all methods have valid selectors, and that all linked sends are to valid targets and have valid cache tags"
	| ok cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	ok := true.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType ~= CMFree ifTrue:
			[(self asserta: (objectRepresentation checkValidOopReference: cogMethod selector)) ifFalse:
				[ok := false].
			 (self asserta: (self cogMethodDoesntLookKosher: cogMethod) = 0) ifFalse:
				[ok := false]].
		(cogMethod cmType = CMMethod
		 or: [cogMethod cmType = CMOpenPIC]) ifTrue:
			[(self asserta: ((self mapFor: cogMethod
								 performUntil: #checkIfValidOopRefAndTarget:pc:cogMethod:
								 arg: cogMethod asInteger) = 0)) ifFalse:
				[ok := false]].
		(cogMethod cmType = CMMethod
		 and: [SistaVM
		 and: [objectRepresentation canPinObjects]]) ifTrue:
			[(SistaVM and: [cogMethod counters ~= 0]) ifTrue:
				[(self asserta: (objectRepresentation checkValidDerivedObjectReference: cogMethod counters)) ifFalse:
					[ok := false]]].
		cogMethod cmType = CMClosedPIC ifTrue:
			[(self asserta: (self noTargetsFreeInClosedPIC: cogMethod)) ifFalse:
				[ok := false]].
		cogMethod := methodZone methodAfter: cogMethod].
	^ok
]

{ #category : #'garbage collection' }
Cogit >> allMethodsHaveCorrectHeader [
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod ifTrue:
			[(objectRepresentation hasValidHeaderPostGC: cogMethod) ifFalse:
				[^false]].
		 cogMethod := methodZone methodAfter: cogMethod].
	^true
]

{ #category : #initialization }
Cogit >> allocateBlockStarts: numBlocks [
	"Allocate the structures used to manage block compilation.  This
	 needs to be a macro since the structures are alloca'ed (stack
	 allocated) to ensure their being freed when compilation is done."
	<cmacro: '(numBlocks) do { \
		blockStarts = (numBlocks) ? alloca(sizeof(BlockStart) * (numBlocks)) : 0; \
} while (0)'>
	blockStarts := numBlocks > 0 ifTrue:
					[CArrayAccessor on:
						((1 to: numBlocks) collect:
							[:ign| CogBlockStart new])]
]

{ #category : #initialization }
Cogit >> allocateOpcodes: numberOfAbstractOpcodes bytecodes: numberOfBytecodes [
	"Allocate the various arrays needed to compile abstract instructions.
	 Notionally we only need as many fixups as there are bytecodes.  But we
	 reuse fixups to record pc-dependent instructions in generateInstructionsAt:
	 and so need at least as many as there are abstract opcodes.

	 This *must* be inlined since the arrays are alloca'ed (stack allocated)
	 so that they are freed when compilation is done.

	 N.B. We do one single alloca to save embarrassing C optimizers that
	 generate incorrect code as both gcc and the intel compiler do on x86."
	<inline: true>
	numAbstractOpcodes := numberOfAbstractOpcodes.
	self
		cCode:
			[| opcodeSize fixupSize|
			 opcodeSize := (self sizeof: CogAbstractInstruction) * numAbstractOpcodes.
			 fixupSize := (self sizeof: CogBytecodeFixup) * numAbstractOpcodes.
			 abstractOpcodes := self alloca: opcodeSize + fixupSize.
			 self b: abstractOpcodes zero: opcodeSize + fixupSize.
			 fixups := (abstractOpcodes asUnsignedInteger + opcodeSize) asVoidPointer]
		inSmalltalk:
			[abstractOpcodes := CArrayAccessor on:
									 ((1 to: numAbstractOpcodes) collect: [:ign| CogCompilerClass for: self]).
			 fixups := CArrayAccessor on:
						((1 to: numAbstractOpcodes) collect: [:ign| self bytecodeFixupClass for: self])].
	self zeroOpcodeIndexForNewOpcodes.
	labelCounter := 0
]

{ #category : #initialization }
Cogit >> allocateOpcodes: numberOfAbstractOpcodes bytecodes: numberOfBytecodes ifFail: failBlock [
	"Allocate the various arrays needed to compile abstract instructions, failing if the size
	 needed is considered too high.  Notionally we only need as many fixups as there are
	 bytecodes.  But we reuse fixups to record pc-dependent instructions in
	 generateInstructionsAt: and so need at least as many as there are abstract opcodes.

	 This *must* be inlined since the arrays are alloca'ed (stack allocated)
	 so that they are freed when compilation is done.

	 N.B. We do one single alloca to save embarrassing C optimizers that
	 generate incorrect code as both gcc and the intel compiler do on x86."
	<inline: true>
	| opcodeBytes fixupBytes allocBytes |
	numAbstractOpcodes := numberOfAbstractOpcodes.
	opcodeBytes := (self sizeof: CogAbstractInstruction) * numAbstractOpcodes.
	fixupBytes := (self sizeof: CogBytecodeFixup) * numAbstractOpcodes.
	allocBytes := opcodeBytes + fixupBytes.
	"Document the fact that the MaxStackAllocSize ensures that the number of abstract
	 opcodes fits in a 16 bit integer (e.g. CogBytecodeFixup's instructionIndex)."
	self assert: (self sizeof: CogAbstractInstruction) + (self sizeof: CogBytecodeFixup) * 49152 > MaxStackAllocSize.
	allocBytes > MaxStackAllocSize ifTrue:
		[^failBlock value].
	self
		cCode:
			[abstractOpcodes := self alloca: allocBytes.
			 self b: abstractOpcodes zero: allocBytes.
			 fixups := (abstractOpcodes asUnsignedInteger + opcodeBytes) asVoidPointer]
		inSmalltalk:
			[abstractOpcodes := CArrayAccessor on:
									 ((1 to: numAbstractOpcodes) collect: [:ign| CogCompilerClass for: self]).
			 fixups := CArrayAccessor on:
						((1 to: numAbstractOpcodes) collect: [:ign| self bytecodeFixupClass for: self])].
	self zeroOpcodeIndexForNewOpcodes.
	labelCounter := 0
]

{ #category : #'in-line cacheing' }
Cogit >> allowEarlyOpenPICPromotion [
	<inline: true>
	^ true
]

{ #category : #'method map' }
Cogit >> annotate: abstractInstruction objRef: anOop [
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	(objectRepresentation shouldAnnotateObjectReference: anOop) ifTrue:
		[(objectMemory isYoungObject: anOop) ifTrue:
			[hasYoungReferent := true].
		 abstractInstruction annotation: IsObjectReference].
	^abstractInstruction
]

{ #category : #'method map' }
Cogit >> annotateAbsolutePCRef: abstractInstruction [
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	abstractInstruction annotation: IsAbsPCReference.
	^abstractInstruction
]

{ #category : #'method map' }
Cogit >> annotateBytecode: abstractInstruction [
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	abstractInstruction annotation: HasBytecodePC.
	^abstractInstruction
]

{ #category : #'method map' }
Cogit >> annotateCall: abstractInstruction [
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	abstractInstruction annotation: IsRelativeCall.
	^abstractInstruction
]

{ #category : #'method map' }
Cogit >> annotationForMcpc: mcpc in: cogHomeMethod [
	"Answer the annotation for mcpc in cogHomeMethod's map, or 0 if no entry exists."
	<var: #cogHomeMethod type: #'CogMethod *'>
	| mapLocation mapByte annotation |
	mapLocation := self findMapLocationForMcpc: mcpc inMethod: cogHomeMethod.
	mapLocation = 0 ifTrue:
		[^0].
	mapByte := objectMemory byteAt: mapLocation.
	annotation := mapByte >> AnnotationShift.
	annotation = IsSendCall ifTrue:
		[mapByte := objectMemory byteAt: mapLocation - 1.
		 mapByte >> AnnotationShift = IsAnnotationExtension ifTrue:
			[annotation := annotation + (mapByte bitAnd: DisplacementMask)]].
	^annotation
]

{ #category : #'in-line cacheing' }
Cogit >> annotationIsForUncheckedEntryPoint: annotation [
	<inline: true>
	^annotation = IsSuperSend
	  or: [BytecodeSetHasDirectedSuperSend
		  and: [annotation
					between: IsDirectedSuperSend
					and: IsDirectedSuperBindingSend]]
]

{ #category : #'simulation only' }
Cogit >> assertCStackWellAligned [
	"Check alignment of the C stack.  This is a simulation only facsimilie.
	 See platforms/Cross/vm/sqCogStackAlignment.h for the real code."
	<doNotGenerate>
	self assert: processor sp \\ cStackAlignment = expectedSPAlignment.
	self assert: processor fp \\ cStackAlignment = expectedFPAlignment
]

{ #category : #'compile abstract instructions' }
Cogit >> assertExtsAreConsumed: descriptor [
	 "extended bytecodes must consume their extensions"
	 <inline: true>
	 descriptor isExtension ifFalse:
		[self assert: (extA = 0 and: [extB = 0 and: [numExtB = 0]])].
]

{ #category : #debugging }
Cogit >> assertSaneJumpTarget: jumpTarget [
	<var: #jumpTarget type: #'AbstractInstruction *'>

	self assert: (closedPICSize isNil "don't whinge when producing the PIC prototypes"
			or: [openPICSize isNil
			or: [(self addressIsInInstructions: jumpTarget)
			or: [(jumpTarget asUnsignedInteger
					between: codeBase
					and: methodZone limitZony asInteger + (closedPICSize max: openPICSize))]]])
]

{ #category : #'trampoline support' }
Cogit >> backEnd [
	<cmacro: '() backEnd'>
	^backEnd
]

{ #category : #accessing }
Cogit >> backend [
	<doNotGenerate>
	^ backEnd
]

{ #category : #'tests-method map' }
Cogit >> bcpcsAndDescriptorsFor: aMethod bsOffset: bsOffset do: quaternaryBlock [
	"Evaluate quaternaryBlock with the pc, byte, descriptor and numExtensions for
	 all the bytecodes in aMethod.  Evaluate with byte, descriptor and numExtensions
	 nil for the initialPC of the mehtod and any blocks within it."
	<doNotGenerate>
	| nExts byte descriptor endpc latestContinuation pc primIdx |
	((primIdx := coInterpreter primitiveIndexOf: aMethod) > 0
	and: [coInterpreter isQuickPrimitiveIndex: primIdx]) ifTrue:
		[^self].
	latestContinuation := pc := coInterpreter startPCOfMethod: aMethod.
	quaternaryBlock value: pc value: nil value: nil value: 0. "stackCheck/entry pc"
	primIdx > 0 ifTrue:
		[pc := pc + (self deltaToSkipPrimAndErrorStoreIn: aMethod
							header: (coInterpreter methodHeaderOf: aMethod))].
	nExts := 0.
	endpc := objectMemory numBytesOf: aMethod.
	[pc <= endpc] whileTrue:
		[byte := objectMemory fetchByte: pc ofObject: aMethod.
		descriptor := self generatorAt: byte + bsOffset.
		descriptor isExtension ifFalse:
			[quaternaryBlock value: pc value: byte value: descriptor value: nExts].
		(descriptor isReturn
		 and: [pc >= latestContinuation]) ifTrue:
			[endpc := pc].
		(descriptor isBranch
		 or: [descriptor isBlockCreation]) ifTrue:
			[| targetPC |
			 descriptor isBlockCreation ifTrue:
				[quaternaryBlock value: pc + descriptor numBytes value: nil value: nil value: 0]. "stackCheck/entry pc"
			 targetPC := self latestContinuationPCFor: descriptor at: pc exts: nExts in: aMethod.
			 self assert: targetPC < endpc.
			 latestContinuation := latestContinuation max: targetPC].
		pc := pc + descriptor numBytes.
		nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]]
]

{ #category : #'tests-method map' }
Cogit >> bcpcsDescriptorsAndStartpcsFor: aMethod bsOffset: bsOffset do: quinternaryBlock [
	"Evaluate quinternaryBlock with the pc, byte, descriptor and numExtensions for
	 all the bytecodes in aMethod.  Evaluate with byte, descriptor and numExtensions
	 nil for the initialPC of the mehtod and any blocks within it."
	<doNotGenerate>
	| nExts byte descriptor endpc latestContinuation pc primIdx blockEndPCs startpcs |
	((primIdx := coInterpreter primitiveIndexOf: aMethod) > 0
	and: [coInterpreter isQuickPrimitiveIndex: primIdx]) ifTrue:
		[^self].
	latestContinuation := pc := coInterpreter startPCOfMethod: aMethod.
	startpcs := OrderedCollection with: pc.
	blockEndPCs := OrderedCollection with: (objectMemory numBytesOf: aMethod).
	quinternaryBlock value: pc value: nil value: nil value: 0 value: pc. "stackCheck/entry pc"
	primIdx > 0 ifTrue:
		[pc := pc + (self deltaToSkipPrimAndErrorStoreIn: aMethod
							header: (objectMemory methodHeaderOf: aMethod))].
	nExts := 0.
	endpc := objectMemory numBytesOf: aMethod.
	[pc <= endpc] whileTrue:
		[byte := objectMemory fetchByte: pc ofObject: aMethod.
		descriptor := self generatorAt: byte + bsOffset.
		descriptor isExtension ifFalse:
			[quinternaryBlock value: pc value: byte value: descriptor value: nExts value: startpcs last].
		descriptor isReturn ifTrue:
			[pc >= latestContinuation ifTrue:
				[endpc := pc]].
		(descriptor isBranch
		 or: [descriptor isBlockCreation]) ifTrue:
			[| targetPC |
			 targetPC := self latestContinuationPCFor: descriptor at: pc exts: nExts in: aMethod.
			 descriptor isBlockCreation ifTrue:
				[quinternaryBlock value: (startpcs addLast: pc + descriptor numBytes) value: nil value: nil value: 0 value: startpcs last.
				 blockEndPCs addLast: targetPC]. "stackCheck/entry pc"
			 self assert: targetPC < endpc.
			 latestContinuation := latestContinuation max: targetPC].
		descriptor isReturn ifTrue:
			[pc + descriptor numBytes >= blockEndPCs last ifTrue:
				[blockEndPCs removeLast.
				 startpcs removeLast]].
		pc := pc + descriptor numBytes.
		nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]]
]

{ #category : #accessing }
Cogit >> blockAlignment [
	"Block method headers must be aligned on the correct boundary, just like non-block method headers.
	 This is because the CoInterpreter encodes flags in the least significant three bits of the method field."
	<api>
	<cmacro: '() 8'>
	self assert: (methodZone roundUpLength: 1) = 8.
	^8
]

{ #category : #'method map' }
Cogit >> blockCreationBytecodeSizeForHeader: aMethodHeader [
	<inline: true>
	^self cppIf: MULTIPLEBYTECODESETS
		ifTrue:
			[(objectMemory headerIndicatesAlternateBytecodeSet: aMethodHeader)
				ifTrue: [AltBlockCreationBytecodeSize]
				ifFalse: [BlockCreationBytecodeSize]]
		ifFalse: [BlockCreationBytecodeSize]
]

{ #category : #disassembly }
Cogit >> blockDispatchFor: cogMethod perform: quaternaryFunction arg: arg [
	"Evaluate quaternaryFunction with the block start mcpc, prev pc in block
	 dispatch, current pc in block dispatch and the supplied arg for each entry
	 in the block dispatch.  If the function answers non-zero answer the value
	 it answered. Used for disassembling blockDispatch."
	<doNotGenerate>
	| pc prevpc blockEntry end targetpc result |
	cogMethod blockEntryOffset = 0 ifTrue:
		[^nil].
	blockEntry := cogMethod blockEntryOffset + cogMethod asInteger.
	prevpc := pc := blockEntry.
	end := (self mapEndFor: cogMethod) - 1.
	[pc < end] whileTrue:
		[(backEnd isJumpAt: pc)
			ifTrue:
				[targetpc := backEnd jumpTargetPCAt: pc.
				 pc := pc + (backEnd instructionSizeAt: pc).
				 targetpc < blockEntry ifTrue:
					[result := self perform: quaternaryFunction
								with: targetpc
								with: prevpc
								with: pc
								with: arg.
					 result ~= 0 ifTrue:
						[^result].
					 prevpc := pc]]
			ifFalse:
				[pc := pc + (backEnd instructionSizeAt: pc)]].
	^0
]

{ #category : #'method map' }
Cogit >> blockDispatchTargetsFor: cogMethod perform: binaryFunction arg: arg [
	"Evaluate binaryFunction with the block start mcpc and supplied arg for each
	 entry in the block dispatch.  If the function answers non-zero answer the value
	 it answered.  Used to update back-references to the home method in compaction."
	<var: #cogMethod type: #'CogMethod *'>
	<var: #binaryFunction declareC: 'usqInt (*binaryFunction)(sqInt mcpc, sqInt arg)'>
	| pc blockEntry end targetpc result |
	cogMethod blockEntryOffset = 0 ifTrue:
		[^nil].
	blockEntry := cogMethod blockEntryOffset + cogMethod asInteger.
	pc := blockEntry.
	end := (self mapEndFor: cogMethod) - 1.
	[pc < end] whileTrue:
		[(backEnd isJumpAt: pc) ifTrue:
			[targetpc := backEnd jumpTargetPCAt: pc.
			 targetpc < blockEntry ifTrue:
				[result := self perform: binaryFunction
							with: targetpc
							with: arg.
				 result ~= 0 ifTrue:
					[^result]]].
		pc := pc + (backEnd instructionSizeAt: pc)].
	^0
]

{ #category : #'compile abstract instructions' }
Cogit >> blockStartAt: index [
	<cmacro: '(index) (&blockStarts[index])'>
	"hack set startpc for printSimStack:toDepth:spillBase:on:"
	self maybeNoteStartpcFor: (blockStarts at: index).
	^blockStarts at: index
]

{ #category : #disassembly }
Cogit >> blockStartPcsIn: aMethod [
	"Answer the start bytecopde pcs in a method in compilation order, i.e. depth-first.
	 Blocks must occur in pc/depth-first order for binary tree block dispatch to work."
	| startpcs pc latestContinuation end descriptor byte bsOffset nExts |
	<doNotGenerate>
	startpcs := OrderedCollection new.
	startpcs add: (pc := latestContinuation := coInterpreter startPCOfMethod: aMethod).
	end := objectMemory numBytesOf: aMethod.
	bsOffset := self bytecodeSetOffsetFor: aMethod.
	nExts := 0.
	[pc <= end] whileTrue:
		[byte := objectMemory fetchByte: pc ofObject: aMethod.
		 descriptor := self generatorAt: byte + bsOffset.
		 (descriptor isReturn
		  and: [pc >= latestContinuation]) ifTrue:
			[end := pc].
		 (descriptor isBranch
		  or: [descriptor isBlockCreation]) ifTrue:
			[| targetPC |
			 targetPC := self latestContinuationPCFor: descriptor at: pc exts: nExts in: aMethod.
			 latestContinuation := latestContinuation max: targetPC].
		 pc := pc + descriptor numBytes.
		 descriptor isBlockCreation ifTrue:
			[startpcs add: pc].
		 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]].
	^startpcs
]

{ #category : #'simulation only' }
Cogit >> breakAt: address [
	((breakPC isBreakpointFor: address)
	 and: [breakBlock shouldStopIfAtPC: address]) ifTrue:
		[coInterpreter changed: #byteCountText.
		 self halt: 'machine code breakpoint at ', address]
]

{ #category : #'simulation only' }
Cogit >> breakBlock [
	<doNotGenerate>
	^breakBlock
]

{ #category : #'simulation only' }
Cogit >> breakBlock: aBlock [
	<doNotGenerate>
	breakBlock := aBlock.
	breakPC ifNil: [breakPC := true].
	singleStep := singleStep or: [breakPC singleStepRequiredToTriggerIn: self]
]

{ #category : #'simulation only' }
Cogit >> breakMethod [
	<doNotGenerate>
	^breakMethod
]

{ #category : #debugging }
Cogit >> breakOnImplicitReceiver [
	<api>
	<cmacro: '() (traceFlags & 64)'>
	^(traceFlags bitAnd: 64) ~= 0
]

{ #category : #'simulation only' }
Cogit >> breakPC [
	<doNotGenerate>
	^breakPC
]

{ #category : #'simulation only' }
Cogit >> breakPC: anAddressArrayOrNil [
	<doNotGenerate>
	breakPC := anAddressArrayOrNil.
	singleStep := singleStep or: [anAddressArrayOrNil singleStepRequiredToTriggerIn: self]
]

{ #category : #accessing }
Cogit >> byte1: anInteger [
	<doNotGenerate>
	byte1 := anInteger
]

{ #category : #'simulation only' }
Cogit >> bytecodeFixupClass [
	self subclassResponsibility
]

{ #category : #'method map' }
Cogit >> bytecodePCFor: mcpc startBcpc: startbcpc in: cogMethod [
	"Answer the zero-relative bytecode pc matching the machine code pc argument in
	 cogMethod, given the start of the bytecodes for cogMethod's block or method object."
	<api>
	<var: #cogMethod type: #'CogBlockMethod *'>
	^self
		mapFor: cogMethod
		bcpc: startbcpc
		performUntil: #find:IsBackwardBranch:Mcpc:Bcpc:MatchingMcpc:
		arg: mcpc asVoidPointer
]

{ #category : #initialization }
Cogit >> bytecodeSetOffsetFor: aMethodObj [
	<inline: true>
	^self
		cppIf: MULTIPLEBYTECODESETS
		ifTrue:
			[(coInterpreter methodUsesAlternateBytecodeSet: aMethodObj)
				ifTrue: [256]
				ifFalse: [0]]
		ifFalse: [0]
]

{ #category : #initialization }
Cogit >> bytecodeSetOffsetForHeader: aMethodHeader [
	<inline: true>
	^self
		cppIf: MULTIPLEBYTECODESETS
		ifTrue:
			[(objectMemory headerIndicatesAlternateBytecodeSet: aMethodHeader)
				ifTrue: [256]
				ifFalse: [0]]
		ifFalse: [0]
]

{ #category : #'simulation only' }
Cogit >> cCoerce: value to: cTypeString [
	"Type coercion. For translation a cast will be emmitted. When running in Smalltalk
	  answer a suitable wrapper for correct indexing."
	<doNotGenerate>
	^value
		ifNil: [value]
		ifNotNil: [value coerceTo: cTypeString sim: objectMemory]
]

{ #category : #'translation support' }
Cogit >> cCoerceSimple: value to: cTypeString [
	<doNotGenerate>
	cTypeString last == $* ifTrue:
		[cTypeString == #'CogMethod *' ifTrue:
			[^(value isInteger and: [value < 0])
				ifTrue: [value] "it's an error code; leave it be"
				ifFalse: [self cogMethodSurrogateAt: value asUnsignedInteger]].
		cTypeString == #'CogBlockMethod *' ifTrue:
			[^self cogBlockMethodSurrogateAt: value asUnsignedInteger].
		(cTypeString == #'AbstractInstruction *'
		 and: [value isBehavior]) ifTrue:
			[^CogCompilerClass].
		cTypeString == #'StackPage *' ifTrue:
			[^coInterpreter stackPages surrogateAtAddress: value]].
	^super cCoerceSimple: value to: cTypeString
]

{ #category : #'trampoline support' }
Cogit >> cFramePointerAddress [
	<cmacro: '() ((usqIntptr_t)&CFramePointer)'>
	^(backEnd wantsNearAddressFor: #CFramePointer)
		ifTrue: [self simulatedReadWriteVariableAddress: #getCFramePointer in: self]
		ifFalse: [coInterpreter inMemoryCFramePointerAddress]
]

{ #category : #'in-line cacheing' }
Cogit >> cPIC: cPIC HasTarget: targetMethod [
	"Are any of the jumps from this CPIC to targetMethod?"
	<var: #cPIC type: #'CogMethod *'>
	<var: #targetMethod type: #'CogMethod *'>
	| pc target |
	target := targetMethod asUnsignedInteger + cmNoCheckEntryOffset.
	pc := cPIC asInteger + firstCPICCaseOffset.
	"Since this is a fast test doing simple compares we don't need to care that some
	cases have nonsense addresses in there. Just zip on through."
	"First jump is unconditional; subsequent ones are conditional"
	target = (backEnd jumpLongTargetBeforeFollowingAddress: pc) ifTrue:
		[^true].
	2 to: MaxCPICCases do:
		[:i|
		pc := pc + cPICCaseSize.
		target = (backEnd jumpLongConditionalTargetBeforeFollowingAddress: pc) ifTrue:
			[^true]].
	^false
]

{ #category : #'in-line cacheing' }
Cogit >> cPICCompactAndIsNowEmpty: cPIC [
	"Scan the CPIC for target methods that have been freed and eliminate them.
	 Since the first entry cannot be eliminated, answer that the PIC should be
	 freed if the first entry is to a free target.  Answer if the PIC is now empty or should be freed."
	<var: #cPIC type: #'CogMethod *'>
	| pc entryPoint targetMethod targets tags methods used |
	<var: #targetMethod	type: #'CogMethod *'>
	<var: #tags			declareC: 'int tags[MaxCPICCases]'>
	<var: #targets			declareC: 'sqInt targets[MaxCPICCases]'>
	<var: #methods		declareC: 'sqInt methods[MaxCPICCases]'>
	self cCode: [] inSmalltalk:
		[tags := CArrayAccessor on: (Array new: MaxCPICCases).
		 targets := CArrayAccessor on: (Array new: MaxCPICCases).
		 methods := CArrayAccessor on: (Array new: MaxCPICCases)].
	used := 0.
	1 to: cPIC cPICNumCases do:
		[:i| | valid |
		 pc := self addressOfEndOfCase: i inCPIC: cPIC.
		 entryPoint := i = 1
						ifTrue: [backEnd jumpLongTargetBeforeFollowingAddress: pc]
						ifFalse: [backEnd jumpLongConditionalTargetBeforeFollowingAddress: pc].
		 valid := true.
		 "Collect all target triples except for triples whose entry-point is a freed method"
		 (cPIC containsAddress: entryPoint) ifFalse:
			[targetMethod := self cCoerceSimple: entryPoint - cmNoCheckEntryOffset to: #'CogMethod *'.
			 self assert: (targetMethod cmType = CMMethod or: [targetMethod cmType = CMFree]).
			 targetMethod cmType = CMFree ifTrue:
				[i = 1 ifTrue: [^true]. "cannot filter out the first entry cuz classTag is at pont of send."
				 valid := false]].
		 valid ifTrue:
			[tags at: used put: (i > 1 ifTrue: [backEnd literal32BeforeFollowingAddress: pc - backEnd jumpLongConditionalByteSize]).
			 targets at: used put: entryPoint.
			 methods at: used put: (backEnd literalBeforeFollowingAddress: pc - (i = 1
																				ifTrue: [backEnd jumpLongByteSize]
																				ifFalse: [backEnd jumpLongConditionalByteSize + backEnd cmpC32RTempByteSize])).
			 used := used + 1]].
	used = cPIC cPICNumCases ifTrue:
		[^false].
	used = 0 ifTrue:
		[^true].
	cPIC cPICNumCases: used.
	used = 1 ifTrue:
		[pc := self addressOfEndOfCase: 2 inCPIC: cPIC.
		 self rewriteCPIC: cPIC caseJumpTo: pc.
		 ^false].
	"the first entry cannot change..."
	1 to: used - 1 do:
		[:i|
		 pc := self addressOfEndOfCase: i + 1 inCPIC: cPIC.
		 self rewriteCPICCaseAt: pc tag: (tags at: i) objRef: (methods at: i) target: (targets at: i)].

	"finally, rewrite the jump 3 instr  before firstCPICCaseOffset to jump to the beginning of this new case"
	self rewriteCPIC: cPIC caseJumpTo: pc - cPICCaseSize.
	^false
]

{ #category : #'in-line cacheing' }
Cogit >> cPICHasForwardedClass: cPIC [ 
	"The first case in a CPIC doesn't have a class reference so we need only step over actually usd subsequent cases."
	| pc |
	<var: #cPIC type: #'CogMethod *'>
	"start by finding the address of the topmost case, the cPICNumCases'th one"
	pc := (self addressOfEndOfCase: cPIC cPICNumCases inCPIC: cPIC)
				- backEnd jumpLongConditionalByteSize.
	2 to: cPIC cPICNumCases do: 
			[:i |  | classIndex |
			classIndex := backEnd literal32BeforeFollowingAddress: pc.
			(objectMemory isForwardedClassIndex: classIndex)
				ifTrue: [^ true].
			"since we started at the top, we can just add the case size each time to move on to the next case"
			pc := pc + cPICCaseSize].
	^ false
]

{ #category : #'in-line cacheing' }
Cogit >> cPICHasFreedTargets: cPIC [
	"scan the CPIC for target methods that have been freed. "
	<var: #cPIC type: #'CogMethod *'>
	| pc entryPoint targetMethod |
	<var: #targetMethod type: #'CogMethod *'>

	1 to: cPIC cPICNumCases do:
		[:i|
		pc := self addressOfEndOfCase: i inCPIC: cPIC.
		entryPoint := i = 1
						ifTrue: [backEnd jumpLongTargetBeforeFollowingAddress: pc]
						ifFalse: [backEnd jumpLongConditionalTargetBeforeFollowingAddress: pc].
		"Find target from jump.  Ignore jumps to the interpret and MNU calls within this PIC"
		(cPIC containsAddress: entryPoint) ifFalse:
			[targetMethod := self cCoerceSimple: entryPoint - cmNoCheckEntryOffset to: #'CogMethod *'.
			 self assert: (targetMethod cmType = CMMethod or: [targetMethod cmType = CMFree]).
			 targetMethod cmType = CMFree ifTrue:
				[^true]]].
	^false
]

{ #category : #accessing }
Cogit >> cPICPrototype [
	"For Cogit clas>>#genAndDisPICoptions:"
	<doNotGenerate>
	^cPICPrototype
]

{ #category : #'in-line cacheing' }
Cogit >> cPICPrototypeCaseOffset [
	"Whimsey; we want 16rCA5E10 + cPICPrototypeCaseOffset to be somewhere in the middle of the zone."
	<inline: true>
	^methodZoneBase + methodZone youngReferrers / 2 - 16rCA5E10
]

{ #category : #'trampoline support' }
Cogit >> cStackPointerAddress [
	<cmacro: '() ((usqIntptr_t)&CStackPointer)'>
	^(backEnd wantsNearAddressFor: #CStackPointer)
		ifTrue: [self simulatedReadWriteVariableAddress: #getCStackPointer in: self]
		ifFalse: [coInterpreter inMemoryCStackPointerAddress]
]

{ #category : #debugging }
Cogit >> callCogCodePopReceiver [
	"This is a static version of ceCallCogCodePopReceiverReg
	 for break-pointing when debugging in C."
	<api>
	<inline: false>
	"This exists only for break-pointing."
	self cCode: [self realCECallCogCodePopReceiverReg]
		inSmalltalk: [self ceCallCogCodePopReceiverReg].
	"(and this exists only to reference Debug)"
	Debug ifFalse: [self error: 'what??']
]

{ #category : #debugging }
Cogit >> callCogCodePopReceiverAndClassRegs [
	"This is a static version of ceCallCogCodePopReceiverAndClassRegs
	 for break-pointing when debugging in C."
	<api>
	<inline: false>
	"This exists only for break-pointing."
	self cCode: [self realCECallCogCodePopReceiverAndClassRegs]
		inSmalltalk: [self ceCallCogCodePopReceiverAndClassRegs]
]

{ #category : #accessing }
Cogit >> ceBaseFrameReturnPC [
	<api>
	<cmacro: '() ceBaseFrameReturnTrampoline'>
	^ceBaseFrameReturnTrampoline
]

{ #category : #accessing }
Cogit >> ceBaseFrameReturnTrampoline: anInteger [ 

	<doNotGenerate>
	
	ceBaseFrameReturnTrampoline := anInteger
]

{ #category : #'in-line cacheing' }
Cogit >> ceCPICMiss: cPIC receiver: receiver [
	"Code entry closed PIC miss.  A send has fallen
	 through a closed (finite) polymorphic inline cache.
	 Either extend it or patch the send site to an open PIC.
	 The stack looks like:
			receiver
			args
	  sp=>	sender return address"
	<var: #cPIC type: #'CogMethod *'>
	<api>
	| outerReturn newTargetMethodOrNil errorSelectorOrNil cacheTag result |
	self cCode: ''
		inSmalltalk:
			[cPIC isInteger ifTrue:
				[^self ceCPICMiss: (self cogMethodSurrogateAt: cPIC) receiver: receiver]].
	(objectMemory isOopForwarded: receiver) ifTrue:
		[^coInterpreter ceSendFromInLineCacheMiss: cPIC].
	outerReturn := coInterpreter stackTop.
	self deny: (backEnd inlineCacheTagAt: outerReturn) = self picAbortDiscriminatorValue. 
	cPIC cPICNumCases < MaxCPICCases
		ifTrue:
			[self lookup: cPIC selector
				for: receiver
				methodAndErrorSelectorInto:
					[:method :errsel|
					newTargetMethodOrNil := method.
					errorSelectorOrNil := errsel]]
		ifFalse: [newTargetMethodOrNil := errorSelectorOrNil := nil].
	"We assume lookupAndCog:for: will *not* reclaim the method zone"
	self assert: outerReturn = coInterpreter stackTop.
	cacheTag := objectRepresentation inlineCacheTagForInstance: receiver.
	(cPIC cPICNumCases >= MaxCPICCases
	 or: [(errorSelectorOrNil notNil and: [errorSelectorOrNil ~= SelectorDoesNotUnderstand])
	 or: [(objectRepresentation inlineCacheTagIsYoung: cacheTag)
	 or: [newTargetMethodOrNil isNil
	 or: [objectMemory isYoung: newTargetMethodOrNil]]]]) ifTrue:
		[result := self patchToOpenPICFor: cPIC selector
					numArgs: cPIC cmNumArgs
					receiver: receiver.
		 self assert: result not. "If patchToOpenPICFor:.. returns we're out of code memory"
		 ^coInterpreter ceSendFromInLineCacheMiss: cPIC].
	"Now extend the PIC with the new case."
	self cogExtendPIC: cPIC
		CaseNMethod: newTargetMethodOrNil
		tag: cacheTag
		isMNUCase: errorSelectorOrNil = SelectorDoesNotUnderstand.
	"Jump back into the pic at its entry in case this is an MNU."
	coInterpreter
		executeCogPIC: cPIC
		fromLinkedSendWithReceiver: receiver
		andCacheTag: (backEnd inlineCacheTagAt: outerReturn).
	"NOTREACHED"
	^nil
]

{ #category : #accessing }
Cogit >> ceCPICMissTrampoline [
	<doNotGenerate>
	^ ceCPICMissTrampoline
]

{ #category : #'simulation only' }
Cogit >> ceCallCogCodePopReceiverAndClassRegs [
	<api: 'extern void (*ceCallCogCodePopReceiverAndClassRegs)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceCallCogCodePopReceiverAndClassRegs numArgs: 2
]

{ #category : #'simulation only' }
Cogit >> ceCallCogCodePopReceiverReg [
	<api: 'extern void (*ceCallCogCodePopReceiverReg)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceCallCogCodePopReceiverReg numArgs: 1
]

{ #category : #accessing }
Cogit >> ceCannotResumePC [
	<api>
	<cmacro: '() ((usqInt)ceCannotResumeTrampoline)'>
	<returnTypeC: #usqInt> "for Slang"
	^ceCannotResumeTrampoline
]

{ #category : #'jit - api' }
Cogit >> ceCaptureCStackPointers [
	<api: 'extern void (*ceCaptureCStackPointers)()'>
	<doNotGenerate>

	processor machineSimulator baseRegisterValue: self varBaseAddress.
	self simulateLeafCallOf: ceCaptureCStackPointers
]

{ #category : #testing }
Cogit >> ceCheckFeatures [
	<cmacro: '() ceCheckFeaturesFunction()'>
	^self simulateLeafCallOf: ceCheckFeaturesFunction
]

{ #category : #accessing }
Cogit >> ceCheckForInterruptTrampoline: anInteger [ 
	<doNotGenerate>

	ceCheckForInterruptTrampoline := anInteger
]

{ #category : #'as yet unclassified' }
Cogit >> ceDereferenceSelectorIndex [
	
	<doNotGenerate>
	^ objectRepresentation selectorIndexDereferenceRoutine
]

{ #category : #'as yet unclassified' }
Cogit >> ceDereferenceSelectorIndex: anInteger [ 
	
	<doNotGenerate>
	objectRepresentation selectorIndexDereferenceRoutine: anInteger
]

{ #category : #'simulation only' }
Cogit >> ceEnterCogCodePopReceiverReg [
	<api: 'extern void (*ceEnterCogCodePopReceiverReg)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceEnterCogCodePopReceiverReg numArgs: 1
]

{ #category : #'simulation only' }
Cogit >> ceEnterCogCodePopReceiverRegEnilopmart [
	<doNotGenerate>
	^ ceEnterCogCodePopReceiverReg
]

{ #category : #'trampoline support' }
Cogit >> ceFree: pointer [
	<api>
	<var: #pointer type: #'void*'>
	self free: pointer
]

{ #category : #accessing }
Cogit >> ceLargeActiveContextInBlockTrampoline [

	<doNotGenerate>
	^ objectRepresentation ceLargeActiveContextInBlockTrampoline
]

{ #category : #accessing }
Cogit >> ceLargeActiveContextInBlockTrampoline: anAddress [

	<doNotGenerate>
	objectRepresentation ceLargeActiveContextInBlockTrampoline: anAddress
]

{ #category : #accessing }
Cogit >> ceLargeActiveContextInFullBlockTrampoline [

	<doNotGenerate>
	^ objectRepresentation ceLargeActiveContextInFullBlockTrampoline
]

{ #category : #accessing }
Cogit >> ceLargeActiveContextInFullBlockTrampoline: anAddress [

	<doNotGenerate>
	objectRepresentation ceLargeActiveContextInFullBlockTrampoline: anAddress
]

{ #category : #accessing }
Cogit >> ceLargeActiveContextInMethodTrampoline [
	<doNotGenerate>
	^ objectRepresentation ceLargeActiveContextInMethodTrampoline
]

{ #category : #accessing }
Cogit >> ceLargeActiveContextInMethodTrampoline: anAddress [

	<doNotGenerate>
	objectRepresentation ceLargeActiveContextInMethodTrampoline: anAddress
]

{ #category : #'trampoline support' }
Cogit >> ceMalloc: size [
	<api>
	<var: #size type: #'size_t'>
	<returnTypeC: #'void*'>
	^ self malloc: size
]

{ #category : #accessing }
Cogit >> ceMethodAbortTrampoline [
	<doNotGenerate>
	^ ceMethodAbortTrampoline
]

{ #category : #accessing }
Cogit >> ceMethodAbortTrampoline: anInteger [ 
	<doNotGenerate>
	ceMethodAbortTrampoline := anInteger
]

{ #category : #accessing }
Cogit >> cePICAbortTrampoline [
	<doNotGenerate>
	^ cePICAbortTrampoline
]

{ #category : #accessing }
Cogit >> cePICAbortTrampoline: anInteger [ 
	<doNotGenerate>
	cePICAbortTrampoline := anInteger
]

{ #category : #accessing }
Cogit >> ceReturnToInterpreterPC [
	<api>
	<cmacro: '() ((usqInt)ceReturnToInterpreterTrampoline)'>
	<returnTypeC: #usqInt> "for Slang"
	^ceReturnToInterpreterTrampoline
]

{ #category : #'in-line cacheing' }
Cogit >> ceSICMiss: receiver [
	"An in-line cache check in a method has failed.  The failing entry check has jumped
	 to the ceMethodAbort abort call at the start of the method which has called this routine.
	 If possible allocate a closed PIC for the current and existing classes.
	 The stack looks like:
			receiver
			args
			sender return address
	  sp=>	ceMethodAbort call return address
	 So we can find the method that did the failing entry check at
		ceMethodAbort call return address - missOffset
	 and we can find the send site from the outer return address."
	<api>
	| pic innerReturn outerReturn entryPoint targetMethod newTargetMethodOrNil errorSelectorOrNil cacheTag extent result |
	<var: #pic type: #'CogMethod *'>
	<var: #targetMethod type: #'CogMethod *'>
	"Whether we can relink to a PIC or not we need to pop off the inner return and identify the target method."
	innerReturn := coInterpreter popStack asUnsignedInteger.
	targetMethod := self cCoerceSimple: innerReturn - missOffset to: #'CogMethod *'.
	(objectMemory isOopForwarded: receiver) ifTrue:
		[^coInterpreter ceSendFromInLineCacheMiss: targetMethod].
	outerReturn := coInterpreter stackTop asUnsignedInteger.
	self assert: (outerReturn between: methodZoneBase and: methodZone freeStart).
	entryPoint := backEnd callTargetFromReturnAddress: outerReturn.

	self assert: targetMethod selector ~= objectMemory nilObject.
	self assert: targetMethod asInteger + cmEntryOffset = entryPoint.

	self lookup: targetMethod selector
		for: receiver
		methodAndErrorSelectorInto:
			[:method :errsel|
			newTargetMethodOrNil := method.
			errorSelectorOrNil := errsel].
	"We assume lookupAndCog:for: will *not* reclaim the method zone"
	self assert: outerReturn = coInterpreter stackTop.
	cacheTag := objectRepresentation inlineCacheTagForInstance: receiver.
	((errorSelectorOrNil notNil and: [errorSelectorOrNil ~= SelectorDoesNotUnderstand])
	 or: [(objectRepresentation inlineCacheTagIsYoung: cacheTag)
	 or: [(backEnd inlineCacheTagAt: outerReturn) = self picAbortDiscriminatorValue
	 or: [newTargetMethodOrNil isNil
	 or: [objectMemory isYoung: newTargetMethodOrNil]]]]) ifTrue:
		[result := self patchToOpenPICFor: targetMethod selector
					numArgs: targetMethod cmNumArgs
					receiver: receiver.
		 self assert: result not. "If patchToOpenPICFor:.. returns we're out of code memory"
		 ^coInterpreter ceSendFromInLineCacheMiss: targetMethod].
	"See if an Open PIC is already available."
	pic := methodZone openPICWithSelector: targetMethod selector.
	(pic isNil or: [self allowEarlyOpenPICPromotion not]) ifTrue:
		["otherwise attempt to create a closed PIC for the two cases."
		 pic := self cogPICSelector: targetMethod selector
					numArgs: targetMethod cmNumArgs
					Case0Method: targetMethod
					Case1Method: newTargetMethodOrNil
					tag: cacheTag
					isMNUCase: errorSelectorOrNil = SelectorDoesNotUnderstand.
		 (pic asInteger between: MaxNegativeErrorCode and: -1) ifTrue:
			["For some reason the PIC couldn't be generated, most likely a lack of code memory.
			  Continue as if this is an unlinked send."
			 pic asInteger = InsufficientCodeSpace ifTrue:
				[coInterpreter callForCogCompiledCodeCompaction].
			^coInterpreter ceSendFromInLineCacheMiss: targetMethod].
		 processor flushICacheFrom: pic asUnsignedInteger to: pic asUnsignedInteger + closedPICSize].
	"Relink the send site to the pic.  If to an open PIC then reset the cache tag to the selector,
	 for the benefit of the cacheTag assert check in checkIfValidOopRef:pc:cogMethod: et al."
	extent := pic cmType = CMOpenPIC
				ifTrue:
					[backEnd
						rewriteInlineCacheAt: outerReturn
						tag: (self inlineCacheValueForSelector: targetMethod selector
								  in: coInterpreter mframeHomeMethodExport
								  at: outerReturn)
						target: pic asInteger + cmEntryOffset]
				ifFalse:
					[backEnd
						rewriteCallAt: outerReturn
						target: pic asInteger + cmEntryOffset].
	processor flushICacheFrom: outerReturn asUnsignedInteger - extent to: outerReturn asUnsignedInteger.
	"Jump back into the pic at its entry in case this is an MNU (newTargetMethodOrNil is nil)"
	coInterpreter
		executeCogPIC: pic
		fromLinkedSendWithReceiver: receiver
		andCacheTag: (backEnd inlineCacheTagAt: outerReturn).
	"NOTREACHED"
	^nil
]

{ #category : #accessing }
Cogit >> ceScheduleScavengeTrampoline: anInteger [ 

	objectRepresentation 	ceScheduleScavengeTrampoline: anInteger
]

{ #category : #accessing }
Cogit >> ceSendMustBeBooleanAddFalseTrampoline: anInteger [

	<doNotGenerate>

	ceSendMustBeBooleanAddFalseTrampoline := anInteger
]

{ #category : #accessing }
Cogit >> ceSendMustBeBooleanAddTrueTrampoline: anInteger [ 

	<doNotGenerate>
	
	ceSendMustBeBooleanAddTrueTrampoline :=	anInteger

]

{ #category : #accessing }
Cogit >> ceSmallActiveContextInBlockTrampoline [

	<doNotGenerate>
	^ objectRepresentation ceSmallActiveContextInBlockTrampoline
]

{ #category : #accessing }
Cogit >> ceSmallActiveContextInBlockTrampoline: anAddress [

	<doNotGenerate>
	objectRepresentation ceSmallActiveContextInBlockTrampoline: anAddress
]

{ #category : #accessing }
Cogit >> ceSmallActiveContextInFullBlockTrampoline [

	<doNotGenerate>
	^ objectRepresentation ceSmallActiveContextInFullBlockTrampoline
]

{ #category : #accessing }
Cogit >> ceSmallActiveContextInFullBlockTrampoline: anAddress [

	<doNotGenerate>
	objectRepresentation ceSmallActiveContextInFullBlockTrampoline: anAddress
]

{ #category : #accessing }
Cogit >> ceSmallActiveContextInMethodTrampoline [
	<doNotGenerate>
	^ objectRepresentation ceSmallActiveContextInMethodTrampoline
]

{ #category : #accessing }
Cogit >> ceSmallActiveContextInMethodTrampoline: anAddress [

	<doNotGenerate>
	objectRepresentation ceSmallActiveContextInMethodTrampoline: anAddress
]

{ #category : #accessing }
Cogit >> ceStoreCheckTrampoline: anAddress [ 
	
	self objectRepresentation ceStoreCheckTrampoline: anAddress


]

{ #category : #debugging }
Cogit >> checkAssertsEnabledInCogit [
	<api>
	| assertsAreEnabledInCogit |
	assertsAreEnabledInCogit := false.
	self assert: assertsAreEnabledInCogit
]

{ #category : #initialization }
Cogit >> checkCFramePointerInUse [
	| currentCSP result |
	
	"Check if the CFramePointer is in use.
	Different C compilers can choose to not use the frame pointers to delimit stack frames, and use instead the frame pointer as a general purpose register.
	This function implements a rough heuristic to determine if the FP is used as a frame delimiter or not.
	
	This function is meant to work as follows:
	 - the caller should call ceCaptureCStackPointers capturing the FP and SP of the caller.
	 - then the caller calls this function that will in turn also call ceCaptureCStackPointers to capture the FP and SP.
	
	If the FP moved between the two calls, and the FP captured the second time is between the previous one and the new SP, this means the compiler probably generated code to update the FP.
	"
	
	self simulationOnly: [
		"Simulate what the C compiler should have introduced on each call"
		processor pushWord: 16rBEEF "Fake caller address".
		simulateFPInUse ifTrue: [
			processor pushWord: processor fp.
			processor fp: processor sp.
		].
	].
	
	currentCSP := self getCStackPointer.
	self ceCaptureCStackPointers.
	self assert: self getCStackPointer < currentCSP.
	
	result := self getCFramePointer >= self getCStackPointer
		and: [ self getCFramePointer <= currentCSP ].
	
	self simulationOnly: [
		"Simulate what the C compiler should have introduced on return"
		simulateFPInUse ifTrue: [
			processor sp: processor fp.
			processor fp: processor popWord.
		].
		processor popWord "Fake caller address".
	].

	^ result
]

{ #category : #debugging }
Cogit >> checkEnoughOpcodes [
	<inline: true>
	opcodeIndex > numAbstractOpcodes ifTrue:
		[self error: 'Cog JIT internal error. Too many abstract opcodes.  Num opcodes heuristic is too optimistic.']
]

{ #category : #'garbage collection' }
Cogit >> checkIfValidOopRef: annotation pc: mcpc cogMethod: cogMethod [
	"Check for a valid object reference, if any, at a map entry.  Answer a code unique to each error for debugging."
	<var: #mcpc type: #'char *'>
	annotation = IsObjectReference ifTrue:
		[| literal |
		 literal := literalsManager fetchLiteralAtAnnotatedAddress: mcpc asUnsignedInteger using: backEnd.
		 (objectRepresentation checkValidOopReference: literal) ifFalse:
			[coInterpreter print: 'object ref leak in CM '; printHex: cogMethod asInteger; print: ' @ '; printHex: mcpc asInteger; cr.
			^1]].

	(self isPureSendAnnotation: annotation) ifTrue:
		[| entryPoint selectorOrCacheTag offset |
		 entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint <= methodZoneBase
			ifTrue:
				[offset := entryPoint]
			ifFalse:
				[self
					offsetAndSendTableFor: entryPoint
					annotation: annotation
					into: [:off :table| offset := off]].
		 selectorOrCacheTag := backEnd inlineCacheTagAt: mcpc asInteger.
		 (entryPoint > methodZoneBase
		  and: [offset ~= cmNoCheckEntryOffset
		  and: [(self cCoerceSimple: entryPoint - offset to: #'CogMethod *') cmType ~= CMOpenPIC]])
			ifTrue: "linked non-super send, cacheTag is a cacheTag"
				[(objectRepresentation validInlineCacheTag: selectorOrCacheTag) ifFalse:
					[coInterpreter print: 'cache tag leak in CM '; printHex: cogMethod asInteger; print: ' @ '; printHex: mcpc asInteger; cr.
					^1]]
			ifFalse: "unlinked send or super send; cacheTag is a selector unless 64-bit, in which case it is an index."
				[(self inlineCacheTagsAreIndexes
				  or: [objectRepresentation checkValidOopReference: selectorOrCacheTag]) ifFalse:
					[coInterpreter print: 'selector leak in CM '; printHex: cogMethod asInteger; print: ' @ '; printHex: mcpc asInteger; cr.
					^1]]].
	^0 "keep scanning"
]

{ #category : #'garbage collection' }
Cogit >> checkIfValidOopRefAndTarget: annotation pc: mcpc cogMethod: cogMethod [
	"Check for a valid object reference, if any, at a map entry.  Answer a code unique to each error for debugging."
	<var: #mcpc type: #'char *'>
	| literal entryPoint |
	annotation = IsObjectReference ifTrue:
		[literal := literalsManager fetchLiteralAtAnnotatedAddress: mcpc asUnsignedInteger using: backEnd.
		 (self asserta: (objectRepresentation checkValidOopReference: literal)) ifFalse:
			[^1].
		((objectRepresentation couldBeObject: literal)
		 and: [objectMemory isReallyYoungObject: literal]) ifTrue:
			[(self asserta: (self cCoerceSimple: cogMethod to: #'CogMethod *') cmRefersToYoung) ifFalse:
				[^2]]].

	(self isPureSendAnnotation: annotation) ifTrue:
		[(self asserta: (self cCoerceSimple: cogMethod to: #'CogMethod *') cmType = CMMethod) ifFalse:
			[^3].
		 self entryCacheTagAndCouldBeObjectAt: mcpc annotation: annotation into:
			[:entryPt :cacheTag :tagCouldBeObject|
			entryPoint := entryPt.
			tagCouldBeObject
				ifTrue:
					[(objectRepresentation couldBeObject: cacheTag)
						ifTrue:
							[(self asserta: (objectRepresentation checkValidOopReference: cacheTag)) ifFalse:
								[^4]]
						ifFalse:
							[(self asserta: (objectRepresentation validInlineCacheTag: cacheTag)) ifFalse:
								[^5]].
					((objectRepresentation couldBeObject: cacheTag)
					 and: [objectMemory isReallyYoungObject: cacheTag]) ifTrue:
						[(self asserta: (self cCoerceSimple: cogMethod to: #'CogMethod *') cmRefersToYoung) ifFalse:
							[^6]]]
				ifFalse:
					[(self inlineCacheTagsAreIndexes
					  and: [self entryPointTagIsSelector: entryPoint])
						ifTrue:
							[cacheTag signedIntFromLong < 0
								ifTrue:
									[cacheTag signedIntFromLong negated > NumSpecialSelectors ifTrue:
										[^7]]
								ifFalse:
									[cacheTag >= (objectMemory literalCountOf: enumeratingCogMethod methodObject) ifTrue:
										[^8]]]
						ifFalse:
							[(self asserta: (objectRepresentation validInlineCacheTag: cacheTag)) ifFalse:
								[^9]]]].
		entryPoint > methodZoneBase ifTrue:
			["It's a linked send; find which kind."
			 self targetMethodAndSendTableFor: entryPoint annotation: annotation into:
					[:targetMethod :sendTable|
					 (self asserta: (targetMethod cmType = CMMethod
								   or: [targetMethod cmType = CMClosedPIC
								   or: [targetMethod cmType = CMOpenPIC]])) ifFalse:
						[^10]]]].
	^0 "keep scanning"
]

{ #category : #debugging }
Cogit >> checkIntegrityOfObjectReferencesInCode: gcModes [
	<api>
	"Answer if all references to objects in machine-code are valid."	
	| cogMethod ok count |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	ok := true.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType ~= CMFree ifTrue:
			[cogMethod cmRefersToYoung ifTrue:
				[(count := methodZone occurrencesInYoungReferrers: cogMethod) ~= 1 ifTrue:
					[coInterpreter print: 'young referrer CM '; printHex: cogMethod asInteger.
					 count = 0
						ifTrue: [coInterpreter print: ' is not in youngReferrers'; cr]
						ifFalse: [coInterpreter print: ' is in youngReferrers '; printNum: count; print: ' times!'; cr].
					 ok := false]].
			 (objectRepresentation checkValidOopReference: cogMethod selector) ifFalse:
				[coInterpreter print: 'object leak in CM '; printHex: cogMethod asInteger; print: ' selector'; cr.
				 ok := false].
			 cogMethod cmType = CMMethod
				ifTrue:
					[self assert: cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod.
					 (objectRepresentation checkValidObjectReference: cogMethod methodObject) ifFalse:
						[coInterpreter print: 'object leak in CM '; printHex: cogMethod asInteger; print: ' methodObject'; cr.
						 ok := false].
					 (objectMemory isOopCompiledMethod: cogMethod methodObject) ifFalse:
						[coInterpreter print: 'non-method in CM '; printHex: cogMethod asInteger; print: ' methodObject'; cr.
						 ok := false].
					 (self mapFor: cogMethod
						 performUntil: #checkIfValidOopRef:pc:cogMethod:
						 arg: cogMethod asInteger) ~= 0
							ifTrue: [ok := false].
					 (objectRepresentation hasSpurMemoryManagerAPI
					  or: [gcModes anyMask: GCModeNewSpace]) ifTrue:
						[(((objectMemory isYoungObject: cogMethod methodObject)
						    or: [objectMemory isYoung: cogMethod selector])
						   and: [cogMethod cmRefersToYoung not]) ifTrue:
							[coInterpreter print: 'CM '; printHex: cogMethod asInteger; print: ' refers to young but not marked as such'; cr.
							 ok := false]]]
				ifFalse:
					[cogMethod cmType = CMClosedPIC
						ifTrue:
							[(self checkValidObjectReferencesInClosedPIC: cogMethod) ifFalse:
								[ok := false]]
						ifFalse:
							[cogMethod cmType = CMOpenPIC
								ifTrue:
									[(self mapFor: cogMethod
										performUntil: #checkIfValidOopRef:pc:cogMethod:
										arg: cogMethod asInteger) ~= 0
											ifTrue: [ok := false]]]]].
		cogMethod := methodZone methodAfter: cogMethod].
	^ok
]

{ #category : #'garbage collection' }
Cogit >> checkMaybeObjRefInClosedPIC: maybeObject [
	maybeObject = 0 ifTrue:
		[^true].
	(objectRepresentation couldBeObject: maybeObject) ifFalse:
		[^true].
	^objectRepresentation checkValidObjectReference: maybeObject
]

{ #category : #debugging }
Cogit >> checkStackDepthOnSend [
	<doNotGenerate>
	^(traceFlags bitAnd: 128) ~= 0
]

{ #category : #'garbage collection' }
Cogit >> checkValidObjectReferencesInClosedPIC: cPIC [
	<var: #cPIC type: #'CogMethod *'>
	| ok pc |
	ok := true.
	pc := cPIC asInteger + firstCPICCaseOffset.
	
	"first we check the obj ref at the beginning of the CPIC"
	(self checkMaybeObjRefInClosedPIC: (backEnd literalBeforeFollowingAddress: pc - backEnd jumpLongByteSize)) ifFalse:
		[self print: 'object leak in CPIC '; printHex: cPIC asInteger;
			print: ' @ '; printHex: pc - backEnd jumpLongByteSize; cr.
		 ok := false].
	
	"Next we step over each case that is in use. We find the end address of the cPICNumCases'th case and can then just step forward by the case size thereafter"
	pc := self addressOfEndOfCase: cPIC cPICNumCases inCPIC: cPIC.
	
	"For each case we check any object reference at the end address - sizeof(conditional instruction) and then increment the end address by case size"
	2 to: cPIC cPICNumCases do:
		[:i|
		(self inlineCacheTagsAreIndexes not
		 and: [objectRepresentation inlineCacheTagsMayBeObjects]) ifTrue:
			[(self checkMaybeObjRefInClosedPIC: (backEnd literal32BeforeFollowingAddress: pc - backEnd jumpLongConditionalByteSize)) ifFalse:
				[self print: 'object leak in CPIC '; printHex: cPIC asInteger;
					print: ' @ '; printHex: pc - backEnd jumpLongConditionalByteSize - backEnd loadLiteralByteSize; cr.
				 ok := false]].
		(self checkMaybeObjRefInClosedPIC: (backEnd literalBeforeFollowingAddress: pc - backEnd jumpLongConditionalByteSize - backEnd cmpC32RTempByteSize)) ifFalse:
			[self print: 'object leak in CPIC '; printHex: cPIC asInteger;
				print: ' @ '; printHex: pc - backEnd jumpLongConditionalByteSize; cr.
			 ok := false].
		pc := pc + cPICCaseSize].
	^ok
]

{ #category : #'profiling primitives' }
Cogit >> cleanUpFailingCogCodeConstituents: cogMethodArg [
	<var: #cogMethodArg type: #'CogMethod *'>
	<inline: #never> "i.e. this should never be called, so keep it out of the main path."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := cogMethodArg.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMClosedPIC ifTrue:
			[cogMethod methodObject: 0].
		cogMethod := methodZone methodAfter: cogMethod].
	"would like to assert this, but it requires the leak checked be run :-(
		self assert: self allMachineCodeObjectReferencesValid."
	coInterpreter popRemappableOop.
	^nil
]

{ #category : #'garbage collection' }
Cogit >> closedPICRefersToUnmarkedObject: cPIC [
	"Answer if the ClosedPIC refers to any unmarked objects or freed/freeable target methods,
	 applying markAndTraceOrFreeCogMethod:firstVisit: to those targets to determine if freed/freeable."
	<var: #cPIC type: #'CogMethod *'>
	| pc object |
	((objectMemory isImmediate: cPIC selector)
	or: [objectMemory isMarked: cPIC selector]) ifFalse:
		[^true].

	"First jump is unconditional; subsequent ones are conditional."
	"Check the potential method oop for the first case only.
	 Inline cache tags for the 1st case are at the send site."
	pc := self addressOfEndOfCase: 1 inCPIC: cPIC.
	(objectRepresentation couldBeObject: (object := backEnd literalBeforeFollowingAddress: pc - backEnd jumpLongByteSize)) ifTrue:
		[(objectMemory isMarked: object) ifFalse:
			[^true]].

	"Check the first target"
	(self markAndTraceOrFreePICTarget: (backEnd jumpLongTargetBeforeFollowingAddress: pc) in: cPIC) ifTrue:
		[^true].

	2 to: cPIC cPICNumCases do:
		[:i| 
		pc := self addressOfEndOfCase: i inCPIC: cPIC.
		(self inlineCacheTagsAreIndexes not
		 and: [objectRepresentation inlineCacheTagsMayBeObjects
		 and: [objectRepresentation couldBeObject: (object := backEnd literal32BeforeFollowingAddress: pc - backEnd jumpLongConditionalByteSize)]]) ifTrue:
			[(objectMemory isMarked: object) ifFalse:
				[^true]].
		"Check the potential method oop for subsequent cases."
		(objectRepresentation couldBeObject: (object := backEnd literalBeforeFollowingAddress: pc - backEnd jumpLongConditionalByteSize - backEnd cmpC32RTempByteSize)) ifTrue:
			[(objectMemory isMarked: object) ifFalse:
				[^true]].
		"Check subsequent targets"
		(self markAndTraceOrFreePICTarget: (backEnd jumpLongConditionalTargetBeforeFollowingAddress: pc) in: cPIC) ifTrue:
			[^true]].

	^false
]

{ #category : #accessing }
Cogit >> closedPICSize [
	"For Cogit clas>>#genAndDisPICoptions:"
	<doNotGenerate>
	^closedPICSize
]

{ #category : #accessing }
Cogit >> coInterpreter [
	<doNotGenerate>
	^coInterpreter
]

{ #category : #debugging }
Cogit >> codeEntryFor: address [
	<api>
	<returnTypeC: #'char *'>
	<var: #address type: #'char *'>
	0 to: trampolineTableIndex - 3 by: 2 do:
		[:i|
		(address between: (trampolineAddresses at: i + 1)
				and: (trampolineAddresses at: i + 3) - 1) ifTrue:
			[^trampolineAddresses at: i + 1]].
	^nil
]

{ #category : #debugging }
Cogit >> codeEntryNameFor: address [
	<api>
	<returnTypeC: #'char *'>
	<var: #address type: #'char *'>
	0 to: trampolineTableIndex - 3 by: 2 do:
		[:i|
		(address between: (trampolineAddresses at: i + 1)
				and: (trampolineAddresses at: i + 3) - 1) ifTrue:
			[^trampolineAddresses at: i]].
	^nil
]

{ #category : #disassembly }
Cogit >> codeRangesFor: cogMethod [
	"Answer a sequence of ranges of code for the main method and all of the blocks in a CogMethod.
	 N.B.  These are in order of block dispatch, _not_ necessarily address order in the method."
	<doNotGenerate>
	| pc end blockEntry starts |
	cogMethod cmType = CMClosedPIC ifTrue:
		[end := cogMethod asInteger + cPICEndOfCodeOffset - backEnd jumpLongByteSize.
		 ^{ CogCodeRange
				from: cogMethod asInteger + (self sizeof: CogMethod)
				to: end
				cogMethod: cogMethod
				startpc: nil }].
	end := (self mapEndFor: cogMethod) - 1.
	cogMethod blockEntryOffset = 0 ifTrue:
		[^{ CogCodeRange
				from: cogMethod asInteger + (self sizeof: CogMethod)
				to: end
				cogMethod: cogMethod
				startpc: (cogMethod cmType ~= CMOpenPIC ifTrue:
							[coInterpreter startPCOfMethodHeader: cogMethod methodHeader]) }].
	pc := blockEntry := cogMethod blockEntryOffset + cogMethod asInteger.
	starts := OrderedCollection with: cogMethod.
	[pc < end] whileTrue:
		[| targetpc |
		 targetpc := blockEntry.
		 (backEnd isJumpAt: pc) ifTrue:
			[targetpc := backEnd jumpTargetPCAt: pc.
			 targetpc < blockEntry ifTrue:
				[starts add: (self cCoerceSimple: targetpc - (self sizeof: CogBlockMethod) to: #'CogBlockMethod *')]].
		 pc := pc + (backEnd instructionSizeAt: pc)].
	starts := starts asSortedCollection.
	^(1 to: starts size + 1) collect:
		[:i| | cogSubMethod nextpc |
		i <= starts size
			ifTrue:
				[cogSubMethod := starts at: i.
				 nextpc := i < starts size ifTrue: [(starts at: i + 1) address] ifFalse: [blockEntry].
				 CogCodeRange
					from: cogSubMethod address + (self sizeof: cogSubMethod)
					to: nextpc - 1
					cogMethod: cogSubMethod
					startpc: (i = 1
								ifTrue: [coInterpreter startPCOfMethodHeader: cogMethod methodHeader]
								ifFalse: [cogSubMethod startpc])]
			ifFalse:
				[CogCodeRange
					from: blockEntry
					to: end]]
]

{ #category : #'jit - api' }
Cogit >> cog: aMethodObj selector: aSelectorOop [
	"Attempt to produce a machine code method for the bytecode method
	 object aMethodObj.  N.B. If there is no code memory available do *NOT*
	 attempt to reclaim the method zone.  Certain clients (e.g. ceSICMiss:)
	 depend on the zone remaining constant across method generation."
	<api>
	<returnTypeC: #'CogMethod *'>
	| selector cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	(self exclude: aMethodObj selector: aSelectorOop) ifTrue:
		[^nil].
	
	self deny: (coInterpreter methodHasCogMethod: aMethodObj).
	self deny: (objectMemory isOopCompiledMethod: (coInterpreter ultimateLiteralOf: aMethodObj)).

	selector := aSelectorOop = objectMemory nilObject
					ifTrue: [coInterpreter maybeSelectorOfMethod: aMethodObj]
					ifFalse: [aSelectorOop].
	"coInterpreter stringOf: selector"
	selector ifNotNil:
		[coInterpreter
			compilationBreak: selector
			point: (objectMemory lengthOf: selector)
			isMNUCase: false].
	aMethodObj = breakMethod ifTrue: [self halt: 'Compilation of breakMethod'].

	"If the generators for the alternate bytecode set are missing then interpret."
	(coInterpreter methodUsesAlternateBytecodeSet: aMethodObj)
		ifTrue:
			[(self numElementsIn: generatorTable) <= 256 ifTrue:
				[^nil].
			 bytecodeSetOffset := 256]
		ifFalse:
			[bytecodeSetOffset := 0].
	objectRepresentation ensureNoForwardedLiteralsIn: aMethodObj.
	methodObj := aMethodObj.
	methodHeader := objectMemory methodHeaderOf: aMethodObj.
	receiverTags := objectMemory receiverTagBitsForMethod: methodObj.
	cogMethod := self compileCogMethod: aSelectorOop.
	(cogMethod asInteger between: MaxNegativeErrorCode and: -1) ifTrue:
		[cogMethod asInteger = InsufficientCodeSpace ifTrue:
			[coInterpreter callForCogCompiledCodeCompaction].
		 self maybeFreeCounters.
		 "Right now no errors should be reported, so nothing more to do."
		 "self reportError: (self cCoerceSimple: cogMethod to: #sqInt)."
		 ^nil].
	"self cCode: ''
		inSmalltalk:
			[coInterpreter printCogMethod: cogMethod.
			 ""coInterpreter symbolicMethod: aMethodObj.""
			 self assertValidMethodMap: cogMethod."
			 "self disassembleMethod: cogMethod."
			 "printInstructions := clickConfirm := true""]."
	^cogMethod
]

{ #category : #'simulation only' }
Cogit >> cogBlockMethodSurrogateAt: address [
	<doNotGenerate>
	self assert: (address bitAnd: objectMemory wordSize - 1) = 0.
	^cogBlockMethodSurrogateClass new
		at: address
		objectMemory: objectMemory
		cogit: self
]

{ #category : #'simulation only' }
Cogit >> cogBlockMethodSurrogateClass [
	<doNotGenerate>
	^cogBlockMethodSurrogateClass
]

{ #category : #disassembly }
Cogit >> cogCodeBase [
	<api>
	^codeBase
]

{ #category : #accessing }
Cogit >> cogCodeBase: anInteger [ 
	<doNotGenerate>
	codeBase := anInteger
	
]

{ #category : #'profiling primitives' }
Cogit >> cogCodeConstituents: withDetails [
	"Answer the contents of the code zone as an array of pair-wise element, address in ascending address order.
	 Answer a string for a runtime routine or abstract label (beginning, end, etc), a CompiledMethod for a CMMethod,
	 or a selector (presumably a Symbol) for a PIC.
	 If withDetails is true
		- answer machine-code to bytecode pc mapping information for methods
		- answer class, target pair information for closed PIC
	 N.B. Since the class tag for the first case of a closed PIC is stored at the send site, it must be collected
		  by scanning methods (see collectCogConstituentFor:Annotation:Mcpc:Bcpc:Method:).  Since closed PICs
		  are never shared they always come after the method that references them, so we don't need an extra pass
		  to collect the first case class tags, which are (temporarily) assigned to each closed PIC's methodObject field.
		  But we do need to reset the methodObject fields to zero.  This is done in createPICData:, unless memory
		  runs out, in which case it is done by cleanUpFailingCogCodeConstituents:."
	<api>
	| count cogMethod constituents label value |
	<var: #cogMethod type: #'CogMethod *'>
	count := trampolineTableIndex / 2 + 3. "+ 3 for start, freeStart and end"
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType ~= CMFree ifTrue:
			[count := count + 1].
		cogMethod := methodZone methodAfter: cogMethod].
	constituents := coInterpreter instantiateClass: coInterpreter classArray indexableSize: count * 2.
	constituents ifNil:
		[^constituents].
	coInterpreter pushRemappableOop: constituents.
	((label := objectMemory stringForCString: 'CogCode') isNil
	 or: [(value := self positiveMachineIntegerFor: codeBase) isNil]) ifTrue:
		[coInterpreter popRemappableOop.
		 ^nil].
	coInterpreter
		storePointerUnchecked: 0 ofObject: (self maybeTopRemapped: constituents) withValue: label;
		storePointerUnchecked: 1 ofObject: (self maybeTopRemapped: constituents) withValue: value.
	0 to: trampolineTableIndex - 1 by: 2 do:
		[:i|
		((label := objectMemory stringForCString: (trampolineAddresses at: i)) isNil
		 or: [(value := self positiveMachineIntegerFor: (trampolineAddresses at: i + 1) asUnsignedInteger) isNil]) ifTrue:
			[coInterpreter popRemappableOop.
			 ^nil].
		coInterpreter
			storePointerUnchecked: 2 + i ofObject: (self maybeTopRemapped: constituents) withValue: label;
			storePointerUnchecked: 3 + i ofObject: (self maybeTopRemapped: constituents) withValue: value].
	count := trampolineTableIndex + 2.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType ~= CMFree ifTrue:
			[| profileData |
			 profileData := self profileDataFor: cogMethod withDetails: withDetails.
			 profileData ifNil: [^self cleanUpFailingCogCodeConstituents: cogMethod].
			 coInterpreter
				storePointerUnchecked: count
				ofObject: (self maybeTopRemapped: constituents)
				withValue: profileData.
			value := withDetails
						ifTrue: [self collectCogMethodConstituent: cogMethod]
						ifFalse: [self positiveMachineIntegerFor: cogMethod asUnsignedInteger].
			value ifNil: [^self cleanUpFailingCogCodeConstituents: cogMethod].
			coInterpreter
						storePointerUnchecked: count + 1
						ofObject: (self maybeTopRemapped: constituents)
						withValue: value.
			 count := count + 2].
		cogMethod := methodZone methodAfter: cogMethod].
	((label := objectMemory stringForCString: 'CCFree') isNil
	 or: [(value := self positiveMachineIntegerFor: methodZone zoneFree) isNil]) ifTrue:
		[coInterpreter popRemappableOop.
		 ^nil].
	coInterpreter
		storePointerUnchecked: count ofObject: (self maybeTopRemapped: constituents) withValue: label;
		storePointerUnchecked: count + 1 ofObject: (self maybeTopRemapped: constituents) withValue: value.
	((label := objectMemory stringForCString: 'CCEnd') isNil
	 or: [(value := self positiveMachineIntegerFor: methodZone zoneEnd) isNil]) ifTrue:
		[coInterpreter popRemappableOop.
		 ^nil].
	coInterpreter
		storePointerUnchecked: count + 2 ofObject: (self maybeTopRemapped: constituents) withValue: label;
		storePointerUnchecked: count + 3 ofObject: (self maybeTopRemapped: constituents) withValue: value.
	constituents := coInterpreter popRemappableOop.
	coInterpreter beRootIfOld: constituents.
	"would like to assert this, but it requires the leak checked be run :-(
		self assert: self allMachineCodeObjectReferencesValid."
	^constituents
]

{ #category : #'in-line cacheing' }
Cogit >> cogExtendPIC: cPIC CaseNMethod: caseNMethod tag: caseNTag isMNUCase: isMNUCase [
	"Extend the cPIC with the supplied case.  If caseNMethod is cogged dispatch direct to
	 its unchecked entry-point.  If caseNMethod is not cogged, jump to the fast interpreter
	 dispatch, and if isMNUCase then dispatch to fast MNU invocation and mark the cPIC as
	 having the MNU case for cache flushing."
 	<var: #cPIC type: #'CogMethod *'>
	| operand target address |

	coInterpreter
		compilationBreak: cPIC selector
		point: (objectMemory numBytesOf: cPIC selector)
		isMNUCase: isMNUCase.

	self assert: (objectRepresentation inlineCacheTagIsYoung: caseNTag) not.
	"Caller patches to open pic if caseNMethod is young."
	self assert: (caseNMethod notNil and: [(objectMemory isYoung: caseNMethod) not]).
	(isMNUCase not and: [coInterpreter methodHasCogMethod: caseNMethod])
		ifTrue: "this isn't an MNU and we have an already cogged method to jump to"
			[operand := 0.
			 target := (coInterpreter cogMethodOf: caseNMethod) asInteger + cmNoCheckEntryOffset]
		ifFalse: 
			[operand := caseNMethod.
			 isMNUCase
				ifTrue: "this is an MNU so tag the CPIC header and setup a jump to the MNUAbort"
					[cPIC cpicHasMNUCase: true.
					 target := cPIC asInteger + (self sizeof: CogMethod)]
				ifFalse: "setup a jump to the interpretAborth so we can cog the target method"
					[target := cPIC asInteger + self picInterpretAbortOffset]].

	"find the end address of the new case"
	address := self addressOfEndOfCase: cPIC cPICNumCases +1 inCPIC: cPIC.
	
	self rewriteCPICCaseAt: address tag: caseNTag objRef: operand target: target.

	"finally, rewrite the jump 3 instr  before firstCPICCaseOffset to jump to the beginning of this new case"
	self rewriteCPIC: cPIC caseJumpTo: address - cPICCaseSize. 

	processor flushICacheFrom: cPIC asUnsignedInteger to: cPIC asUnsignedInteger + closedPICSize.
	"update the header flag for the number of cases"
	cPIC cPICNumCases: cPIC cPICNumCases + 1.
	^0
]

{ #category : #'jit - api' }
Cogit >> cogFullBlockMethod: aMethodObj numCopied: numCopied [
	"Attempt to produce a machine code method for the bytecode method
	 object aMethodObj.  N.B. If there is no code memory available do *NOT*
	 attempt to reclaim the method zone.  Certain clients (e.g. ceSICMiss:)
	 depend on the zone remaining constant across method generation."
	<api>
	<option: #SistaV1BytecodeSet>
	<returnTypeC: #'CogMethod *'>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	(self exclude: aMethodObj) ifTrue:
		[^nil].
	self deny: (coInterpreter methodHasCogMethod: aMethodObj).
	self assert: (objectMemory isOopCompiledMethod: (coInterpreter ultimateLiteralOf: aMethodObj)).
	aMethodObj = breakMethod ifTrue: [self halt: 'Compilation of breakMethod'].
	"If the generators for the alternate bytecode set are missing then interpret."
	(coInterpreter methodUsesAlternateBytecodeSet: aMethodObj)
		ifTrue:
			[(self numElementsIn: generatorTable) <= 256 ifTrue:
				[^nil].
			 bytecodeSetOffset := 256]
		ifFalse:
			[bytecodeSetOffset := 0].
	objectRepresentation ensureNoForwardedLiteralsIn: aMethodObj.
	methodObj := aMethodObj.
	methodHeader := objectMemory methodHeaderOf: aMethodObj.
	receiverTags := objectMemory receiverTagBitsForMethod: methodObj.
	cogMethod := self compileCogFullBlockMethod: numCopied.
	(cogMethod asInteger between: MaxNegativeErrorCode and: -1) ifTrue:
		[cogMethod asInteger = InsufficientCodeSpace ifTrue:
			[coInterpreter callForCogCompiledCodeCompaction].
		 self maybeFreeCounters.
		 "Right now no errors should be reported, so nothing more to do."
		 "self reportError: (self cCoerceSimple: cogMethod to: #sqInt)."
		 ^nil].
	"self cCode: ''
		inSmalltalk:
			[coInterpreter printCogMethod: cogMethod.
			 ""coInterpreter symbolicMethod: aMethodObj.""
			 self assertValidMethodMap: cogMethod."
			 "self disassembleMethod: cogMethod."
			 "printInstructions := clickConfirm := true""]."
	^cogMethod
]

{ #category : #'in-line cacheing' }
Cogit >> cogMNUPICSelector: selector receiver: rcvr methodOperand: methodOperand numArgs: numArgs [
	<api>
	"Attempt to create a one-case PIC for an MNU.
	 The tag for the case is at the send site and so doesn't need to be generated."
	<returnTypeC: #'CogMethod *'>
	| startAddress |
	((objectMemory isYoung: selector)
	 or: [(objectRepresentation inlineCacheTagForInstance: rcvr) = self picAbortDiscriminatorValue]) ifTrue:
		[^0].
	coInterpreter
		compilationBreak: selector
		point: (objectMemory numBytesOf: selector)
		isMNUCase: true.
	self assert: endCPICCase0 notNil.
	"get memory in the code zone for the CPIC; if that fails we return an error code for the sender to use to work out how to blow up"
	startAddress := methodZone allocate: closedPICSize.
	startAddress = 0 ifTrue:
		[coInterpreter callForCogCompiledCodeCompaction.
		 ^0].

	"memcpy the prototype across to our allocated space; because anything else would be silly"
	objectMemory
		memcpy: (self cCoerceSimple: startAddress to: #'CogMethod *')
		_: (self cCoerceSimple: cPICPrototype to: #'CogMethod *')
		_: closedPICSize.
	
	self configureMNUCPIC: (self cCoerceSimple: startAddress to: #'CogMethod *')
		methodOperand: methodOperand
		numArgs: numArgs
		delta: startAddress - cPICPrototype.

	^self
		fillInCPICHeader: (self cCoerceSimple: startAddress to: #'CogMethod *')
		numArgs: numArgs
		numCases: 1
		hasMNUCase: true
		selector: selector 
]

{ #category : #debugging }
Cogit >> cogMethodDoesntLookKosher: cogMethod [
	"Check that the header fields onf a non-free method are consistent with
	 the type. Answer 0 if it is ok, otherwise answer a code for the error."
	<api>
	<inline: false>
	<var: #cogMethod type: #'CogMethod *'>
	((cogMethod blockSize bitAnd: objectMemory wordSize - 1) ~= 0
	 or: [cogMethod blockSize < (self sizeof: CogMethod)
	 or: [cogMethod blockSize >= 32768]]) ifTrue:
		[^1].

	cogMethod cmType = CMFree ifTrue: [^2].

	cogMethod cmType = CMMethod ifTrue:
		[(objectMemory isIntegerObject: cogMethod methodHeader) ifFalse:
			[^11].
		 (objectRepresentation couldBeObject: cogMethod methodObject) ifFalse:
			[^12].
		 (cogMethod stackCheckOffset > 0
		  and: [cogMethod stackCheckOffset < cmNoCheckEntryOffset]) ifTrue:
			[^13].
		 (SistaVM
		  and: [objectRepresentation canPinObjects
		  and: [cogMethod counters ~= 0]]) ifTrue:
			[(objectRepresentation couldBeDerivedObject: cogMethod counters) ifFalse:
				[^14]].
		 ^0].

	cogMethod cmType = CMOpenPIC ifTrue:
		[cogMethod blockSize ~= openPICSize ifTrue:
			[^21].
		 cogMethod methodHeader ~= 0 ifTrue:
			[^22].
		 "Check the nextOpenPIC link unless we're compacting"
		 cogMethod objectHeader >= 0 ifTrue:
			[(cogMethod methodObject = 0
			  or: [methodZone compactionInProgress
			  or: [cogMethod methodObject = (methodZone methodFor: cogMethod methodObject) asUnsignedInteger]]) ifFalse:
				[^23]].
		 cogMethod stackCheckOffset ~= 0 ifTrue:
			[^24].
		 ^0].

	cogMethod cmType = CMClosedPIC ifTrue:
		[cogMethod blockSize ~= closedPICSize ifTrue:
			[^31].
		 (cogMethod cPICNumCases between: 1 and: MaxCPICCases) ifFalse:
			[^32].
		 cogMethod methodHeader ~= 0 ifTrue:
			[^33].
		 cogMethod methodObject ~= 0 ifTrue:
			[^34].
		 ^0].

	^9
]

{ #category : #'simulation only' }
Cogit >> cogMethodOrBlockSurrogateAt: address [
	<doNotGenerate>
	| surrogate |
	surrogate := self cogMethodSurrogateAt: address.
	^surrogate cmType = CMBlock
		ifTrue: [self cogBlockMethodSurrogateAt: address]
		ifFalse: [surrogate]
]

{ #category : #'simulation only' }
Cogit >> cogMethodSurrogateAt: address [
	<doNotGenerate>
	self assert: (address < 0 or: [(address bitAnd: objectMemory wordSize - 1) = 0]).
	^cogMethodSurrogateClass new
		at: address
		objectMemory: objectMemory
		cogit: self
]

{ #category : #'simulation only' }
Cogit >> cogMethodSurrogateClass [
	<doNotGenerate>
	^cogMethodSurrogateClass
]

{ #category : #'in-line cacheing' }
Cogit >> cogOpenPICSelector: selector numArgs: numArgs [
	"Create an Open PIC.  Temporarily create a direct call of ceSendFromOpenPIC:.
	 Should become a probe of the first-level method lookup cache followed by a
	 call of ceSendFromOpenPIC: if the probe fails."
	<returnTypeC: #'CogMethod *'>
	| startAddress codeSize mapSize end |
	coInterpreter
		compilationBreak: selector
		point: (objectMemory numBytesOf: selector)
		isMNUCase: false.
	startAddress := methodZone allocate: openPICSize.
	startAddress = 0 ifTrue:
		[^self cCoerceSimple: InsufficientCodeSpace to: #'CogMethod *'].
	methodLabel
		address: startAddress;
		dependent: nil.
	"stack allocate the various collections so that they
	 are effectively garbage collected on return."
	self allocateOpcodes: 100 bytecodes: 0.
	self compileOpenPIC: selector numArgs: numArgs.
	self computeMaximumSizes.
	methodLabel concretizeAt: startAddress.
	codeSize := self generateInstructionsAt: startAddress + (self sizeof: CogMethod).
	mapSize := self generateMapAt: startAddress + openPICSize - 1 start: startAddress + cmNoCheckEntryOffset.
	self assert: entry address - startAddress = cmEntryOffset.
	self assert: (methodZone roundUpLength: (self sizeof: CogMethod) + codeSize) + (methodZone roundUpLength: mapSize) <= openPICSize.
	end := self outputInstructionsAt: startAddress + (self sizeof: CogMethod).
	^self
		fillInOPICHeader: (self cCoerceSimple: startAddress to: #'CogMethod *')
		numArgs: numArgs
		selector: selector 
]

{ #category : #'in-line cacheing' }
Cogit >> cogPICSelector: selector numArgs: numArgs Case0Method: case0CogMethod Case1Method: case1MethodOrNil tag: case1Tag isMNUCase: isMNUCase [
	"Attempt to create a two-case PIC for case0CogMethod and  case1Method,case1Tag.
	 The tag for case0CogMethod is at the send site and so doesn't need to be generated.
	 case1Method may be any of
		- a Cog method; link to its unchecked entry-point
		- a CompiledMethod; link to ceInterpretMethodFromPIC:
		- a CompiledMethod; link to ceMNUFromPICMNUMethod:receiver:"
	<var: #case0CogMethod type: #'CogMethod *'>
	<returnTypeC: #'CogMethod *'>
	| startAddress |
	(objectMemory isYoung: selector) ifTrue:
		[^self cCoerceSimple: YoungSelectorInPIC to: #'CogMethod *'].
	coInterpreter
		compilationBreak: selector
		point: (objectMemory numBytesOf: selector)
		isMNUCase: isMNUCase.
	
	"get memory in the code zone for the CPIC; if that fails we return an error code for the sender to use to work out how to blow up"
	startAddress := methodZone allocate: closedPICSize.
	startAddress = 0 ifTrue:
		[^self cCoerceSimple: InsufficientCodeSpace to: #'CogMethod *'].

	"memcpy the prototype across to our allocated space; because anything else would be silly"
	objectMemory
		memcpy: (self cCoerceSimple: startAddress to: #'CogMethod *')
		_: (self cCoerceSimple: cPICPrototype to: #'CogMethod *')
		_: closedPICSize.
	
	self configureCPIC: (self cCoerceSimple: startAddress to: #'CogMethod *')
		Case0: case0CogMethod
		Case1Method: case1MethodOrNil
		tag: case1Tag
		isMNUCase: isMNUCase
		numArgs: numArgs
		delta: startAddress - cPICPrototype .

	^self
		fillInCPICHeader: (self cCoerceSimple: startAddress to: #'CogMethod *')
		numArgs: numArgs
		numCases: 2
		hasMNUCase: isMNUCase
		selector: selector 
]

{ #category : #'simulation only' }
Cogit >> cogit [
	"This is for the sizeof: CogMethod hook that allows different cogit classes to use differet CogMethod variants."
	<doNotGenerate>
	^self
]

{ #category : #'jit - api' }
Cogit >> cogitPostGCAction: gcMode [
	<api>
	(gcMode = GCModeFull
	 and: [objectRepresentation allYoungObjectsAgeInFullGC]) ifTrue:
		[methodZone voidYoungReferrersPostTenureAll].
	self cppIf: SPURVM ifTrue:
		[gcMode = GCModeBecome ifTrue:
			[methodZone followForwardedLiteralsInOpenPICList]].
	"Post-GC update every full method's objectHeader to whatever it needs to be"
	self assert: self allMethodsHaveCorrectHeader.
	"The youngReferrers should be correct after a GC since that is the point at which it is
	 pruned.  But at other times false positives or free methods on the list are acceptable."
	self assert: ((gcMode noMask: GCModeFull+GCModeNewSpace) or: [methodZone kosherYoungReferrers])
]

{ #category : #'multi-threading' }
Cogit >> cogitTryLockVMOwner [
	<api>
		"ceTryLockVMOwner does an atomic swap of the lock with 1 and
		 then subtracts 1from lock's value.  So if the result is 0 the lock was
		 already held.  Anything else (in fact -1) implies we hold the lock."
	<cmacro: '() (ceTryLockVMOwner() != 0)'>
	^(self simulateLeafCallOf: ceTryLockVMOwner) ~= 0
]

{ #category : #'multi-threading' }
Cogit >> cogitUnlockVMOwner [
	<api>
	<cmacro: '() ceUnlockVMOwner()'>
	^self simulateLeafCallOf: ceUnlockVMOwner
]

{ #category : #'profiling primitives' }
Cogit >> collectCogConstituentFor: descriptor Annotation: isBackwardBranchAndAnnotation Mcpc: mcpc Bcpc: bcpc Method: cogMethodArg [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #mcpc type: #'char *'>
	<var: #cogMethodArg type: #'void *'>
	<var: #targetMethod type: #'CogMethod *'>
	| address entryPoint |
	descriptor ifNil: [^0].
	descriptor isMapped ifFalse: [^0].
	address := self positiveMachineIntegerFor: mcpc.
	address ifNil: [^PrimErrNoMemory]. "This cannot trigger a GC but fails if not enough space in Eden,"
	"Assumes we write the values into topRemappableOop"
	coInterpreter
		storePointerUnchecked: cogConstituentIndex
		ofObject: coInterpreter topRemappableOop
		withValue: address.
	coInterpreter
		storePointerUnchecked: cogConstituentIndex + 1
		ofObject: coInterpreter topRemappableOop
		withValue: (objectMemory integerObjectOf: bcpc).
	cogConstituentIndex := cogConstituentIndex + 2.

	"Collect any first case classTags for closed PICs."
	((isBackwardBranchAndAnnotation noMask: 1)
	 and: [self isSendAnnotation: isBackwardBranchAndAnnotation >> 1]) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase ifTrue: "send is linked"
			[self targetMethodAndSendTableFor: entryPoint annotation: isBackwardBranchAndAnnotation >> 1 into:
				[:targetMethod :sendTable|
				  targetMethod cmType = CMClosedPIC ifTrue:
					[targetMethod methodObject: (objectRepresentation classForInlineCacheTag: (backEnd inlineCacheTagAt: mcpc))]]]].
	^0
]

{ #category : #'profiling primitives' }
Cogit >> collectCogMethodConstituent: cogMethod [
	"Answer a description of the mapping between machine code pointers and bytecode pointers for the Cog Method.
	 First value is the address of the cog method.
	 Following values are pairs of machine code pc and bytecode pc"
	<var: #cogMethod type: #'CogMethod *'>
	<var: #cogBlockMethod type: #'CogBlockMethod *'>
	| cm nSlots errCode cogBlockMethod address data |
	(cogMethod cmType = CMMethod) 
		ifFalse: [^self positiveMachineIntegerFor: cogMethod asUnsignedInteger ].
	cogBlockMethod := self cCoerceSimple: cogMethod to: #'CogBlockMethod *'.
	cogBlockMethod stackCheckOffset = 0 "isFrameless ?"
		ifTrue: [^self positiveMachineIntegerFor: cogMethod asUnsignedInteger].
	cm := cogMethod methodObject.
	nSlots := ((objectMemory byteSizeOf: cm) - (coInterpreter startPCOfMethod: cm)) * 2 + objectMemory minSlotsForShortening + 1."+1 for first address"
	data := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: nSlots.
	data ifNil: [^nil].
	coInterpreter pushRemappableOop: data.
	"The iteration assumes the object is the top remappable oop"
	address := (self positiveMachineIntegerFor: cogMethod asUnsignedInteger).
	address ifNil: [coInterpreter popRemappableOop. ^nil].
	coInterpreter
		storePointerUnchecked: 0
		ofObject: coInterpreter topRemappableOop
		withValue: address.
	cogConstituentIndex := 1.
	errCode := self
		mapFor: cogBlockMethod
		bcpc: (coInterpreter startPCOfMethod: cogMethod methodObject)
		performUntil: #collectCogConstituentFor:Annotation:Mcpc:Bcpc:Method:
		arg: cogMethod asVoidPointer.
	errCode ~= 0 ifTrue: [coInterpreter popRemappableOop. ^nil].
	cogConstituentIndex < nSlots ifTrue:
		[objectMemory shorten: coInterpreter topRemappableOop toIndexableSize: cogConstituentIndex].
	^coInterpreter popRemappableOop.
]

{ #category : #disassembly }
Cogit >> collectMapEntry: annotation address: mcpc into: aDictionary [
	<doNotGenerate>
	aDictionary
		at: mcpc
		ifPresent:
			[:extant|
			aDictionary
				at: mcpc
				put: extant, ':\' withCRs, (self class annotationConstantNames at: annotation + 1)]
		ifAbsent: [ aDictionary at: mcpc put: (self class annotationConstantNames at: annotation + 1)].
	^0
]

{ #category : #'jit - api' }
Cogit >> compactCogCompiledCode [
	<api>
	self assert: self noCogMethodsMaximallyMarked.
	coInterpreter markActiveMethodsAndReferents.
	methodZone freeOlderMethodsForCompaction.
	self compactPICsWithFreedTargets.
	methodZone planCompaction.
	coInterpreter updateStackZoneReferencesToCompiledCodePreCompaction.
	methodZone relocateMethodsPreCompaction.
	methodZone compactCompiledCode.
	self assert: self allMethodsHaveCorrectHeader.
	self assert: methodZone kosherYoungReferrers.
	backEnd stopsFrom: methodZone freeStart to: methodZone youngReferrers - 1.
	processor
		flushICacheFrom: methodZoneBase asUnsignedInteger
		to: methodZone youngReferrers asUnsignedInteger
]

{ #category : #compaction }
Cogit >> compactPICsWithFreedTargets [
	| cogMethod count |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	count := 0.
	[cogMethod < methodZone limitZony] whileTrue:
		[(cogMethod cmType = CMClosedPIC
		  and: [self cPICCompactAndIsNowEmpty: cogMethod]) ifTrue:
			[cogMethod cmType: CMFree].
		 cogMethod := methodZone methodAfter: cogMethod.
		 count := count + 1].
	self assert: count = methodZone numMethods
]

{ #category : #'simulation only' }
Cogit >> compilationTrace [
	^compilationTrace
]

{ #category : #'simulation only' }
Cogit >> compilationTrace: anInteger [
	"  1 = method/block compilation
	   2 = bytecode descriptor.
	   4 = simStack & optStatus
	   8 = spill
	 16 = merge
	 32 = fixup
	 64 = map"
	compilationTrace := anInteger
]

{ #category : #'compile abstract instructions' }
Cogit >> compileAbort [
	"The start of a CogMethod has a call to a run-time abort routine that either
	 handles an in-line cache failure or a stack overflow.  The routine selects the
	 path depending on ReceiverResultReg; if zero it takes the stack overflow
	 path; if nonzero the in-line cache miss path.  Neither of these paths returns.
	 The abort routine must be called;  In the callee the method is located by
	 adding the relevant offset to the return address of the call.

	 N.B. This code must match that in compilePICAbort: so that the offset of the
	 return address of the call is the same in methods and closed PICs."
	<returnTypeC: #'AbstractInstruction *'>
	stackOverflowCall := self MoveCq: 0 R: ReceiverResultReg.
	backEnd hasLinkRegister
		ifTrue:
			["If there is a link register it must be saved (pushed onto the stack) before it
			  is smashed by the abort call, and hence needs to be manually handled here"
			 sendMiss := self PushR: LinkReg.
			 ^self Call: (self methodAbortTrampolineFor: methodOrBlockNumArgs)]
		ifFalse:
			[^sendMiss := self Call: (self methodAbortTrampolineFor: methodOrBlockNumArgs)]
]

{ #category : #'compile abstract instructions' }
Cogit >> compileAbstractInstructionsFrom: start through: end [
	"Loop over bytecodes, dispatching to the generator for each bytecode, handling fixups in due course."
	| nextOpcodeIndex descriptor fixup result nExts |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #fixup type: #'BytecodeFixup *'>
	bytecodePC := start.
	nExts := result := 0.
	descriptor := nil.
	[self maybeHaltIfDebugPC.
	 descriptor := self loadBytesAndGetDescriptor.
	 nextOpcodeIndex := opcodeIndex.
	 result := self perform: descriptor generator.
	 self assertExtsAreConsumed: descriptor.
	 fixup := self fixupAt: bytecodePC.
	 self patchFixupTargetIfNeeded: fixup nextOpcodeIndex: nextOpcodeIndex.
	 self maybeDumpLiterals: descriptor.
	 bytecodePC := self nextBytecodePCFor: descriptor exts: nExts.
	 result = 0 and: [bytecodePC <= end]]
		whileTrue:
			[nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]].
	self checkEnoughOpcodes.
	^result
]

{ #category : #'compile abstract instructions' }
Cogit >> compileBlockDispatchFrom: lowBlockStartIndex to: highBlockStartIndex [
	<var: #blockStart type: #'BlockStart *'>
	<var: #jmp type: #'AbstractInstruction *'>
	| blockStart halfWay jmp |
	lowBlockStartIndex = highBlockStartIndex ifTrue:
		[blockStart := self blockStartAt: lowBlockStartIndex.
		 self Jump: blockStart entryLabel.
		^nil].
	halfWay := highBlockStartIndex + lowBlockStartIndex // 2.
	self assert: (halfWay between: lowBlockStartIndex and: highBlockStartIndex).
	blockStart := self blockStartAt: halfWay.
	"N.B. FLAGS := TempReg - startpc"
	self CmpCq: (objectMemory integerObjectOf: blockStart startpc + 1) R: TempReg.
	lowBlockStartIndex = halfWay ifTrue:
		[self JumpLessOrEqual: blockStart entryLabel.
		 self compileBlockDispatchFrom: halfWay + 1 to: highBlockStartIndex.
		 ^nil].
	halfWay + 1 = highBlockStartIndex ifTrue:
		[blockStart := self blockStartAt: highBlockStartIndex.
		 self JumpGreater: blockStart entryLabel.
		 ^self compileBlockDispatchFrom: lowBlockStartIndex to: halfWay].
	jmp := self JumpGreater: 0.
	self compileBlockDispatchFrom: lowBlockStartIndex to: halfWay.
	halfWay = highBlockStartIndex
		ifTrue:
			[blockStart := self blockStartAt: highBlockStartIndex.
			 jmp jmpTarget: blockStart entryLabel]
		ifFalse:
			[jmp jmpTarget: self Label.
			 self compileBlockDispatchFrom: halfWay + 1 to: highBlockStartIndex]
]

{ #category : #'compile abstract instructions' }
Cogit >> compileBlockEntry: blockStart [
	"Compile a block's entry.  This looks like a dummy CogBlockMethod header (for frame parsing)
	 followed by either a frame build, if a frame is required, or nothing.  The CogMethodHeader's
	 objectHeader field is a back pointer to the method, but this can't be filled in until code generation."
	<var: #blockStart type: #'BlockStart *'>
	self AlignmentNops: self blockAlignment.
	blockStart fakeHeader: self Label.
	(self sizeof: CogBlockMethod) caseOf:
		{ [8]					"ObjectMemory"
			->	[self Fill32: 0.		"gets filled in later with the homeOffset and startpc"
				 self Fill32: 0].		"gets filled in later with numArgs et al"
		   [12]					"Spur 32-bit"
			->	[self Fill32: 0.		"gets filled in later with the homeOffset and startpc"
				 self Fill32: 0.		"is left fallow"
				 self Fill32: 0].		"gets filled in later with numArgs et al"
		   [16]					"Spur 64-bit"
			->	[self Fill32: 0.		"gets filled in later with the homeOffset and startpc"
				 self Fill32: 0.		"is left fallow"
				 self Fill32: 0.		"gets filled in later with numArgs et al"
				 self Fill32: 0].
		}.
	blockStart entryLabel: self Label.
	needsFrame
		ifTrue:
			[self compileBlockFrameBuild: blockStart.
			 self recordBlockTrace ifTrue:
				[self CallRT: ceTraceBlockActivationTrampoline]]
		ifFalse:
			[self compileBlockFramelessEntry: blockStart]
]

{ #category : #'compile abstract instructions' }
Cogit >> compileBlockFramelessEntry: blockStart [
	self subclassResponsibility
]

{ #category : #'in-line cacheing' }
Cogit >> compileCPICEntry [
	<returnTypeC: #'AbstractInstruction *'>
	"Compile the cache tag computation and the first comparison.  Answer the address of that comparison."
	entry := objectRepresentation genGetInlineCacheClassTagFrom: ReceiverResultReg into: TempReg forEntry: true.
	self CmpR: ClassReg R: TempReg.
	^self JumpNonZero: 0
]

{ #category : #initialization }
Cogit >> compileCallFor: aRoutine numArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 floatResultReg: resultRegOrNone regsToSave: regMask [
	"Generate a call to aRoutine with up to 4 arguments.  If resultRegOrNone is not
	 NoReg assign the C result to resultRegOrNone.  If saveRegs, save all registers.
	 Hack: a negative arg value indicates an abstract register, a non-negative value
	 indicates a constant."
	<var: #aRoutine type: #'void *'>
	<inline: false>
	| regsToSave |
	regsToSave := resultRegOrNone = NoReg
						ifTrue: [regMask]
						ifFalse: [regMask bitClear: (self registerMaskFor: resultRegOrNone)].
	cStackAlignment > objectMemory wordSize ifTrue:
		[backEnd
			genAlignCStackSavingRegisters: regsToSave
			numArgs: numArgs
			wordAlignment: cStackAlignment / objectMemory wordSize].
	backEnd
		genSaveRegs: regsToSave;
		genMarshallNArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3.
	self CallFullRT: (self cCode: [aRoutine asUnsignedInteger]
						inSmalltalk: [self simulatedTrampolineFor: aRoutine]).
	resultRegOrNone ~= NoReg ifTrue:
		[backEnd cFloatResultToRd: resultRegOrNone].
	 backEnd genRemoveNArgsFromStack: numArgs.
	backEnd genRestoreRegs: regsToSave
]

{ #category : #initialization }
Cogit >> compileCallFor: aRoutine numArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 resultReg: resultRegOrNone regsToSave: regMask [
	"Generate a call to aRoutine with up to 4 arguments.  If resultRegOrNone is not
	 NoReg assign the C result to resultRegOrNone.  If saveRegs, save all registers.
	 Hack: a negative arg value indicates an abstract register, a non-negative value
	 indicates a constant."
	<var: #aRoutine type: #'void *'>
	<inline: false>
	| regsToSave |
	regsToSave := resultRegOrNone = NoReg
						ifTrue: [regMask]
						ifFalse: [regMask bitClear: (self registerMaskFor: resultRegOrNone)].
	cStackAlignment > objectMemory wordSize ifTrue:
		[backEnd
			genAlignCStackSavingRegisters: regsToSave
			numArgs: numArgs
			wordAlignment: cStackAlignment / objectMemory wordSize].
	backEnd
		genSaveRegs: regsToSave;
		genMarshallNArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3.
	self CallFullRT: (self cCode: [aRoutine asUnsignedInteger]
						inSmalltalk: [self simulatedTrampolineFor: aRoutine]).
	resultRegOrNone ~= NoReg ifTrue:
		[backEnd genWriteCResultIntoReg: resultRegOrNone].
	backEnd genRemoveNArgsFromStack: numArgs.
	backEnd genRestoreRegs: regsToSave
]

{ #category : #initialization }
Cogit >> compileCallFor: aRoutine numArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 resultReg: resultRegOrNone resultReg: resultReg2OrNone regsToSave: regMask [
	"Generate a call to aRoutine with up to 4 arguments.  If resultRegOrNone is not
	 NoReg assign the C result to resultRegOrNone.  If saveRegs, save all registers.
	 Hack: a negative arg value indicates an abstract register, a non-negative value
	 indicates a constant."
	<var: #aRoutine type: #'void *'>
	<inline: false>
	| regsToSave |
	regsToSave := resultRegOrNone = NoReg
						ifTrue: [regMask]
						ifFalse: [regMask bitClear: (self registerMaskFor: resultRegOrNone)].
	cStackAlignment > objectMemory wordSize ifTrue:
		[backEnd
			genAlignCStackSavingRegisters: regsToSave
			numArgs: numArgs
			wordAlignment: cStackAlignment / objectMemory wordSize].
	backEnd
		genSaveRegs: regsToSave;
		genMarshallNArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3.
	self CallFullRT: (self cCode: [aRoutine asUnsignedInteger]
						inSmalltalk: [self simulatedTrampolineFor: aRoutine]).
	resultRegOrNone ~= NoReg ifTrue:
		[backEnd genWriteCResultIntoReg: resultRegOrNone].
	resultReg2OrNone ~= NoReg ifTrue:
		[backEnd genWriteCSecondResultIntoReg: resultReg2OrNone].
	backEnd genRemoveNArgsFromStack: numArgs.
	backEnd genRestoreRegs: regsToSave
]

{ #category : #'in-line cacheing' }
Cogit >> compileClosedPICPrototype [
	"Compile the abstract instructions for a full closed PIC, used to generate the chunk of code
	 which is copied to form each closed PIC.  A Closed Polymorphic Inline Cache is a small jump
	 table used to optimize sends with a limited degree of polymorphism (currently up to 6 cases).
	 We call it closed because it deals only with a finite number of cases, as opposed to an Open PIC.
	 When a monomorphic linked send (a send with a single case, linking direct to the checked entry
	 point of a CogMethod) fails a class check, the Cogit attempts to create a two-entry PIC that will
	 handle jumping to the original target for the original class and the relevant target for the new
	 class.  This jump table will be extended on subsequent failures up to a limit (6).

	 We avoid extending CPICs to Open PICs by linking the send site to an Open PIC if one already
	 exists with the send's selector, a good policy since measurements show that sends of mega-
	 morphic selectors usually become megamorphic at all send sites.  Hence the Open PIC list.

	 A CPIC also optimizes MNUs and interpret-only methods.  Each case can load SendNumArgs with
	 the oop of a method, or will load SendNumArgs with 0 if not.  MNUs are optimized by jumping to
	 the mnuAbort in the CPIC, which calls code that creates the Message, thereby avoiding looking up
	 the original message which will not be found, and either looks up doesNotUnderstand: or directly
	 activates the method loaded into SendNumArgs, hence avoiding looking up doesNotUnderstand:.
	 Interpret-only methods are handled by jumping to the picInterpretAbort, which enters the
	 interpreter activating the method loaded in SendNumArgs.

	 CPICs look like the following, where rClass is set at the original send site for the 1st case, and #Foo
	 is some constant, either an oop, a class tag or an instruction address.

		rTemp := (rRecever bitAnd: TagMask) = 0 ifTrue: [rReceiver class] ifFalse: [rRecever bitAnd: TagMask].
		rTemp = rClass ifFalse:
			[self goto: #Label].
		rSendNumArgs := #MethodForCase1Or0.
		self goto: #TargetForCase1.
	 #Label
		rTemp = #ClassTagForCase6 ifTrue:
			[rSendNumArgs := #MethodForCase6Or0.
			 self goto: #TargetForCase6].
		...cases 5, 4 & 3
		rTemp = #ClassTagForCase2 ifTrue:
			[rSendNumArgs := #MethodForCase2Or0.
			 self goto: #TargetForCase2].
		self goto: #CPICMissTrampoline
		literals (if out-of-line literals)

	 where we short-cut as many cases as needed by making the self goto: #Label skip as many cases
	 as needed."
	<inline: true>
	| numArgs jumpNext |
	<var: #jumpNext type: #'AbstractInstruction *'>
	self compilePICAbort: (numArgs := 0). "Will get rewritten to appropriate arity when configuring."
	jumpNext := self compileCPICEntry.
	"At the end of the entry code we need to jump to the first case code, which is actually the last chunk.
	 On each entension we must update this jump to move back one case."
	self MoveUniqueCw: self firstPrototypeMethodOop R: SendNumArgsReg.
	self JumpLong: self cPICPrototypeCaseOffset + 16rCA5E10.
	endCPICCase0 := self Label.
	1 to: MaxCPICCases - 1 do:
		[:h|
		h = (MaxCPICCases - 1) ifTrue:
			[jumpNext jmpTarget: self Label]. "this is where we jump to for the first case"
		self MoveUniqueCw: self subsequentPrototypeMethodOop + h R: SendNumArgsReg.
		"16rBABE1F15+h is the class tag for the Nth case"
		self CmpC32: 16rBABE1F15+h R: TempReg.
		self JumpLongZero: self cPICPrototypeCaseOffset + 16rCA5E10 + (h * 16).
		h = 1 ifTrue:
			[endCPICCase1 := self Label]].
	self MoveCw: methodLabel address R: ClassReg.
	self JumpLong: (self cPICMissTrampolineFor: numArgs).	"Will get rewritten to appropriate arity when configuring."
	cPICEndOfCodeLabel := self Label.
	literalsManager dumpLiterals: false.
	^0
]

{ #category : #'compile abstract instructions' }
Cogit >> compileCogFullBlockMethod: numCopied [
	<returnTypeC: #'CogMethod *'>
	<option: #SistaV1BytecodeSet>
	| numBytecodes numBlocks numCleanBlocks result |
	hasYoungReferent := (objectMemory isYoungObject: methodObj).
	methodOrBlockNumArgs := coInterpreter argumentCountOf: methodObj.
	inBlock := InFullBlock.
	postCompileHook := nil.
	maxLitIndex := -1.
	self assert: (coInterpreter primitiveIndexOf: methodObj) = 0.
	initialPC := coInterpreter startPCOfMethod: methodObj.
	"initial estimate.  Actual endPC is determined in scanMethod."
	endPC := objectMemory numBytesOf: methodObj.
	numBytecodes := endPC - initialPC + 1.
	primitiveIndex := 0.
	self allocateOpcodes: (numBytecodes + 10) * self estimateOfAbstractOpcodesPerBytecodes
		bytecodes: numBytecodes
		ifFail: [^coInterpreter cCoerceSimple: MethodTooBig to: #'CogMethod *'].
	self flag: #TODO. "currently copiedValue access implies frameful method, this is suboptimal"
	(numBlocks := self scanMethod) < 0 ifTrue:
		[^coInterpreter cCoerceSimple: numBlocks to: #'CogMethod *'].
	self assert: numBlocks = 0. "blocks in full blocks are full blocks, they are not inlined."
	numCleanBlocks := self scanForCleanBlocks.
	self assert: numCleanBlocks = 0. "blocks in full blocks are full blocks, they are not inlined."
	self allocateBlockStarts: numBlocks + numCleanBlocks.
	blockCount := 0.
	numCleanBlocks > 0 ifTrue:
		[self addCleanBlockStarts].
	(self maybeAllocAndInitCounters) ifFalse: "Inaccurate error code, but it'll do.  This will likely never fail."
		[^coInterpreter cCoerceSimple: InsufficientCodeSpace to: #'CogMethod *'].

	blockEntryLabel := nil.
	methodLabel dependent: nil.
	(result := self compileEntireFullBlockMethod: numCopied) < 0 ifTrue:
		[^coInterpreter cCoerceSimple: result to: #'CogMethod *'].
	^self generateCogFullBlock
]

{ #category : #'compile abstract instructions' }
Cogit >> compileCogMethod: selector [
	<returnTypeC: #'CogMethod *'>
	| numBytecodes numBlocks numCleanBlocks result extra |
	hasYoungReferent := (objectMemory isYoungObject: methodObj)
						  or: [objectMemory isYoung: selector].
	methodOrBlockNumArgs := coInterpreter argumentCountOf: methodObj.
	inBlock := 0.
	postCompileHook := nil.
	maxLitIndex := -1.
	extra := ((primitiveIndex := coInterpreter primitiveIndexOf: methodObj) > 0
			and: [(coInterpreter isQuickPrimitiveIndex: primitiveIndex) not])
				ifTrue: [30]
				ifFalse: [10].
	initialPC := coInterpreter startPCOfMethod: methodObj.
	"initial estimate.  Actual endPC is determined in scanMethod."
	endPC := (coInterpreter isQuickPrimitiveIndex: primitiveIndex)
					ifTrue: [initialPC - 1]
					ifFalse: [objectMemory numBytesOf: methodObj].
	numBytecodes := endPC - initialPC + 1.
	self allocateOpcodes: (numBytecodes + extra) * self estimateOfAbstractOpcodesPerBytecodes
		bytecodes: numBytecodes
		ifFail: [^coInterpreter cCoerceSimple: MethodTooBig to: #'CogMethod *'].
	(numBlocks := self scanMethod) < 0 ifTrue:
		[^coInterpreter cCoerceSimple: numBlocks to: #'CogMethod *'].
	numCleanBlocks := self scanForCleanBlocks.
	self methodFoundInvalidPostScan ifTrue:
		[^coInterpreter cCoerceSimple: ShouldNotJIT to: #'CogMethod *'].
	self allocateBlockStarts: numBlocks + numCleanBlocks.
	blockCount := 0.
	numCleanBlocks > 0 ifTrue:
		[self addCleanBlockStarts].
	(self maybeAllocAndInitCounters) ifFalse: "Inaccurate error code, but it'll do.  This will likely never fail."
		[^coInterpreter cCoerceSimple: InsufficientCodeSpace to: #'CogMethod *'].
	
	blockEntryLabel := nil.
	methodLabel dependent: nil.
	(result := self compileEntireMethod) < 0 ifTrue:
		[^coInterpreter cCoerceSimple: result to: #'CogMethod *'].
	^self generateCogMethod: selector
]

{ #category : #'compile abstract instructions' }
Cogit >> compileEntireFullBlockMethod: numCopied [
	"Compile the abstract instructions for the entire full block method."
	<option: #SistaV1BytecodeSet>
	| result |
	self preenMethodLabel.
	self compileFullBlockEntry.

	"Frame build"
	self compileFullBlockMethodFrameBuild: numCopied.
	"Method body"
	(result := self compileMethodBody) < 0 ifTrue:
		[^result].
	self assert: blockCount = 0.
	^0
]

{ #category : #'compile abstract instructions' }
Cogit >> compileEntireMethod [
	"Compile the abstract instructions for the entire method, including blocks."
	| result |
	self preenMethodLabel.
	self compileAbort.
	self compileEntry.
	(result := self compilePrimitive) < 0 ifTrue:
		[^result].
	self compileFrameBuild.
	(result := self compileMethodBody) < 0 ifTrue:
		[^result].
	blockCount = 0 ifTrue:
		[^0].
	(result := self compileBlockBodies) < 0 ifTrue:
		[^result].
	^self compileBlockDispatch
]

{ #category : #'compile abstract instructions' }
Cogit >> compileEntry [
	"The entry code to a method checks that the class of the current receiver matches
	 that in the inline cache.  Other non-obvious elements are that its alignment must be
	 different from the alignment of the noCheckEntry so that the method map machinery
	 can distinguish normal and super sends (super sends bind to the noCheckEntry)."

	entry := objectRepresentation genGetInlineCacheClassTagFrom: ReceiverResultReg into: TempReg forEntry: true.
	self CmpR: ClassReg R: TempReg.
	self JumpNonZero: sendMiss.
	noCheckEntry := self Label.
	self compileSendTrace ifTrue:
		[backEnd saveAndRestoreLinkRegAround:
			[self CallRT: ceTraceLinkedSendTrampoline]]
]

{ #category : #'compile abstract instructions' }
Cogit >> compileFrameBuild [
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
Cogit >> compileFullBlockEntry [
	<option: #SistaV1BytecodeSet>
	"Compile the abstract instructions for the entire method, including blocks."
	| jumpNoContextSwitch |

	"Abort for stack overflow on full block activation (no inline cache miss possible).
	 The flag is SendNumArgsReg."
	stackOverflowCall := self MoveCq: 0 R: ReceiverResultReg.
	backEnd hasLinkRegister ifTrue: [self PushR: LinkReg].
	"Since the only case in which this is called is the
	 stack overflow case we can reuse the trampoline."
	self Call: (self methodAbortTrampolineFor: methodOrBlockNumArgs).

	"Entries"
	"No context switch entry"
	fullBlockNoContextSwitchEntry := self MoveCq: 0 R: SendNumArgsReg.
	jumpNoContextSwitch := self Jump: 0.

	self AlignmentNops: (objectMemory wordSize max: 8).
	"Context switch entry (use ReceiverResultReg as a non-zero value; it's shorter)."
	fullBlockEntry := self MoveR: ReceiverResultReg R: SendNumArgsReg.
	jumpNoContextSwitch jmpTarget: self Label.

	^0
]

{ #category : #'compile abstract instructions' }
Cogit >> compileMethodBody [
	"Compile the top-level method body."
	<inline: true>
	endPC < initialPC ifTrue: [^0]. "quick primitives"
	"When compiling, skip any initial CallPrimitive and optional StorePrimErrCode bytecodes.
	 These are dealt with in compileFrameBuild."
	^self compileAbstractInstructionsFrom: initialPC
										+ (self deltaToSkipPrimAndErrorStoreIn: methodObj
												header: methodHeader)
		through: endPC
]

{ #category : #'in-line cacheing' }
Cogit >> compileOpenPIC: selector numArgs: numArgs [
	"Compile the code for an open PIC.  Perform a probe of the first-level method
	 lookup cache followed by a call of ceSendFromOpenPIC: if the probe fails.
	 Since open PICs replicate the CoInterpreter's first-level method cache lookup
	 this is a subclass responsibility."
	self subclassResponsibility
]

{ #category : #'in-line cacheing' }
Cogit >> compilePICAbort: numArgs [
	"The start of a PIC has a call to a run-time abort routine that either handles a dispatch to an
	 interpreted method or a dispatch of an MNU case.  The routine selects the path by testing
	 ClassReg, which holds the inline cache tag; if equal to the picAbortDiscriminatorValue (zero)
	 it takes the MNU path; if nonzero the dispatch to interpreter path.  Neither of these paths
	 returns. The abort routine must be called;  In the callee the PIC is located by adding the
	 relevant offset to the return address of the call.

	 N.B. This code must match that in compileAbort so that the offset of the return address of
	 the call is the same in methods and closed PICs."
	picMNUAbort := self MoveCq: self picAbortDiscriminatorValue R: ClassReg.
	backEnd hasLinkRegister
		ifTrue:
			["If there is a link register it must be saved (pushed onto the stack) before it
			  is smashed by the abort call, and hence needs to be manually handled here".
			 picInterpretAbort := self PushR: LinkReg.
			 self Call: (self picAbortTrampolineFor: numArgs)]
		ifFalse:
			[picInterpretAbort := self Call: (self picAbortTrampolineFor: numArgs)].
	^0
]

{ #category : #debugging }
Cogit >> compileSendTrace [
	"2 is trace sends; 256+2 is traceLinkedSends, so one can trace just unlinked sends using 2"
	<cmacro: '() ((traceFlags & 258) == 258)'>
	^traceFlags allMask: 256 + 2
]

{ #category : #initialization }
Cogit >> compileTrampolineFor: aRoutine numArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 regsToSave: regMask pushLinkReg: pushLinkReg floatResultReg: resultRegOrNone [
	"Generate a trampoline with up to four arguments.  Generate either a call or a jump to aRoutine
	 as requested by callJumpBar.  If generating a call and resultRegOrNone is not NoReg pass the C
	 result back in resultRegOrNone.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<inline: false>
	self genSmalltalkToCStackSwitch: pushLinkReg.
	self
		compileCallFor: aRoutine
		numArgs: numArgs
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		floatResultReg: resultRegOrNone
		regsToSave: regMask.
	backEnd genLoadStackPointers.
	(pushLinkReg and: [backEnd hasLinkRegister])
		ifTrue:
			[backEnd hasPCRegister
				ifTrue: [self PopR: PCReg]
				ifFalse: [self PopR: LinkReg. 
						self RetN: 0]]
		ifFalse: [self RetN: 0]
]

{ #category : #initialization }
Cogit >> compileTrampolineFor: aRoutine numArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 regsToSave: regMask pushLinkReg: pushLinkReg resultReg: resultRegOrNone [
	"Generate a trampoline with up to four arguments.  Generate either a call or a jump to aRoutine
	 as requested by callJumpBar.  If generating a call and resultRegOrNone is not NoReg pass the C
	 result back in resultRegOrNone.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<inline: false>
	self genSmalltalkToCStackSwitch: pushLinkReg.
	self
		compileCallFor: aRoutine
		numArgs: numArgs
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		resultReg: resultRegOrNone
		regsToSave: regMask.
	backEnd genLoadStackPointers.
	(pushLinkReg and: [backEnd hasLinkRegister])
		ifTrue:
			[backEnd hasPCRegister
				ifTrue: [self PopR: PCReg]
				ifFalse: [self PopR: LinkReg. 
						self RetN: 0]]
		ifFalse: [self RetN: 0]
]

{ #category : #initialization }
Cogit >> compileTrampolineFor: aRoutine numArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 regsToSave: regMask pushLinkReg: pushLinkReg resultReg: resultRegOrNone resultReg: resultReg2OrNone [
	"Generate a trampoline with up to four arguments.  Generate either a call or a jump to aRoutine
	 as requested by callJumpBar.  If generating a call and resultRegOrNone is not NoReg pass the C
	 result back in resultRegOrNone.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<inline: false>
	self genSmalltalkToCStackSwitch: pushLinkReg.
	self
		compileCallFor: aRoutine
		numArgs: numArgs
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		resultReg: resultRegOrNone
		resultReg: resultReg2OrNone
		regsToSave: regMask.
	backEnd genLoadStackPointers.
	(pushLinkReg and: [backEnd hasLinkRegister])
		ifTrue:
			[backEnd hasPCRegister
				ifTrue: [self PopR: PCReg]
				ifFalse: [self PopR: LinkReg. 
						self RetN: 0]]
		ifFalse: [self RetN: 0]
]

{ #category : #initialization }
Cogit >> computeEntryOffsets [
	"Generate the entry code for a method to determine cmEntryOffset and cmNoCheckEntryOffset.  We
	 need cmNoCheckEntryOffset up front to be able to generate the map starting from cmNoCheckEntryOffset"
	"stack allocate the various collections so that they
	 are effectively garbage collected on return."
	| sendMissCall |
	<var: 'sendMissCall' type: #'AbstractInstruction *'>
	self allocateOpcodes: 24 bytecodes: 0.
	methodOrBlockNumArgs := 0.
	sendMissCall := self compileAbort.
	self compileEntry.
	self computeMaximumSizes.
	self generateInstructionsAt: methodZoneBase + (self sizeof: CogMethod).
	cmEntryOffset := entry address - methodZoneBase.
	cmNoCheckEntryOffset := noCheckEntry address - methodZoneBase.
	missOffset := sendMissCall address + sendMissCall machineCodeSize - methodZoneBase.
	entryPointMask := objectMemory wordSize - 1.
	[(cmEntryOffset bitAnd: entryPointMask) = (cmNoCheckEntryOffset bitAnd: entryPointMask)] whileTrue:
		[entryPointMask := entryPointMask + entryPointMask + 1].
	entryPointMask >= (methodZone roundUpLength: 1) ifTrue:
		[self error: 'cannot differentiate checked and unchecked entry-points with current cog method alignment'].
	checkedEntryAlignment := cmEntryOffset bitAnd: entryPointMask.
	uncheckedEntryAlignment := cmNoCheckEntryOffset bitAnd: entryPointMask.
	self assert: checkedEntryAlignment ~= uncheckedEntryAlignment
]

{ #category : #initialization }
Cogit >> computeFullBlockEntryOffsets [
	"Generate the entry code for a method to determine cmEntryOffset and cmNoCheckEntryOffset.  We
	 need cmNoCheckEntryOffset up front to be able to generate the map starting from cmNoCheckEntryOffset"
	"stack allocate the various collections so that they
	 are effectively garbage collected on return."
	SistaV1BytecodeSet ifTrue:
		[self allocateOpcodes: 24 bytecodes: 0.
		 methodOrBlockNumArgs := 0.
		 self compileFullBlockEntry.
		 self computeMaximumSizes.
		 self generateInstructionsAt: methodZoneBase + (self sizeof: CogMethod).
		 cbEntryOffset := fullBlockEntry address - methodZoneBase.
		 cbNoSwitchEntryOffset := fullBlockNoContextSwitchEntry address - methodZoneBase]
]

{ #category : #'generate machine code' }
Cogit >> computeMaximumSizes [
	"This pass assigns maximum sizes to all abstract instructions and eliminates jump fixups.
	 It hence assigns the maximum address an instruction will occur at which allows the next
	 pass to conservatively size jumps."
	<inline: false>
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	| relativeAddress |
	literalsManager dumpLiterals: false.
	relativeAddress := 0.
	0 to: opcodeIndex - 1 do:
		[:i| | abstractInstruction |
		abstractInstruction := self abstractInstructionAt: i.
		abstractInstruction
			address: relativeAddress;
			maxSize: abstractInstruction computeMaximumSize.
		relativeAddress := relativeAddress + abstractInstruction maxSize]
]

{ #category : #'in-line cacheing' }
Cogit >> configureCPIC: cPIC Case0: case0CogMethod Case1Method: case1Method tag: case1Tag isMNUCase: isMNUCase numArgs: numArgs delta: addrDelta [
	"Configure a copy of the prototype CPIC for a two-case PIC for 
	case0CogMethod and
	case1Method
	case1Tag.
	 The tag for case0CogMethod is at the send site and so doesn't need to be generated.
	 case1Method may be any of
		- a Cog method; jump to its unchecked entry-point
		- a CompiledMethod; jump to the ceInterpretFromPIC trampoline
		- nil; call ceMNUFromPIC
	addDelta is the address change from the prototype to the new CPIC location, needed
	because the loading of the CPIC label at the end may use a literal instead of a pc relative load."
	"self disassembleFrom: cPIC asInteger + (self sizeof: CogMethod) to: cPIC asInteger + closedPICSize"
	<var: #cPIC type: #'CogMethod *'>
	<var: #case0CogMethod type: #'CogMethod *'>
	| operand targetEntry caseEndAddress |
	self assert: case1Method notNil.

	"adjust the call at missOffset, the ceAbortXArgs"
	backEnd rewriteCallAt: cPIC asInteger + missOffset target: (self picAbortTrampolineFor: numArgs).
	
	self assert: (objectRepresentation inlineCacheTagIsYoung: case1Tag) not.
	(isMNUCase not
	 and: [coInterpreter methodHasCogMethod: case1Method])
		ifTrue:
			[operand := 0.
			 targetEntry := (coInterpreter cogMethodOf: case1Method) asInteger + cmNoCheckEntryOffset]
		ifFalse: "We do not scavenge PICs, hence we cannot cache the MNU method if it is in new space."
			[operand := (case1Method isNil or: [objectMemory isYoungObject: case1Method])
							ifTrue: [0]
							ifFalse: [case1Method].
			 targetEntry := case1Method ifNil: [cPIC asInteger + (self sizeof: CogMethod)] ifNotNil: [cPIC asInteger + self picInterpretAbortOffset]].

	"set the jump to the case0 method"
	backEnd rewriteJumpLongAt: cPIC asInteger + firstCPICCaseOffset target: case0CogMethod asInteger + cmNoCheckEntryOffset.

	caseEndAddress := self addressOfEndOfCase: 2 inCPIC: cPIC.

	"update the cpic case"
	self
		rewriteCPICCaseAt: caseEndAddress
		tag: case1Tag
		objRef: operand
		target: (isMNUCase ifTrue: [cPIC asInteger + (self sizeof: CogMethod)] ifFalse: [targetEntry]) asInteger.

	"update the loading of the CPIC address"
	backEnd relocateMethodReferenceBeforeAddress: cPIC asInteger + cPICEndOfCodeOffset - backEnd jumpLongByteSize by: addrDelta.

	"write the final desperate jump to cePICMissXArgs"
	backEnd rewriteJumpLongAt: cPIC asInteger + cPICEndOfCodeOffset target: (self cPICMissTrampolineFor: numArgs).
	^0
	"self disassembleFrom: cPIC + (self sizeof: CogMethod) to: cPIC + closedPICSize - 1."
]

{ #category : #'in-line cacheing' }
Cogit >> configureMNUCPIC: cPIC methodOperand: methodOperand numArgs: numArgs delta: addrDelta [
	"Configure a copy of the prototype CPIC for a one-case MNU CPIC that calls ceMNUFromPIC for
	 case0Tag The tag for case0 is at the send site and so doesn't need to be generated.
	 addDelta is the address change from the prototype to the new CPIC location, needed
	 because the loading of the CPIC label at the end may be a literal instead of a pc-relative load."
	<var: #cPIC type: #'CogMethod *'>
	| operand |

	"adjust the jump at missOffset, the ceAbortXArgs"
	backEnd rewriteCallAt: cPIC asInteger + missOffset target: (self picAbortTrampolineFor: numArgs).
	
	"We do not scavenge PICs, hence we cannot cache the MNU method if it is in new space."
	operand := (methodOperand isNil or: [objectMemory isYoungObject: methodOperand])
					ifTrue: [0]
					ifFalse: [methodOperand].
	"set the jump to the case0 method"
	backEnd rewriteJumpLongAt: cPIC asInteger + firstCPICCaseOffset target: cPIC asInteger + (self sizeof: CogMethod) .

	backEnd storeLiteral: operand beforeFollowingAddress: cPIC asInteger + firstCPICCaseOffset - backEnd jumpLongByteSize.

	"rewrite the final desperate jump to cePICMissXArgs"
	backEnd rewriteJumpLongAt: cPIC asInteger + cPICEndOfCodeOffset target: (self cPICMissTrampolineFor: numArgs).	

	"update the loading of the CPIC label address"
	backEnd relocateMethodReferenceBeforeAddress: cPIC asInteger + cPICEndOfCodeOffset - backEnd jumpLongByteSize by: addrDelta.

	"finally, rewrite the jump 3 instr before firstCPICCaseOffset to jump to the end of case 2, missing the actual case"
	self rewriteCPIC: cPIC caseJumpTo: (self addressOfEndOfCase: 2 inCPIC: cPIC). 

	^0
]

{ #category : #printing }
Cogit >> cr [
	<cmacro: '() putchar(''\n'')'>
	coInterpreter transcript cr; flush
]

{ #category : #'profiling primitives' }
Cogit >> createCPICData: cPIC [
	"Answer an Array of the PIC's selector, followed by class and targetMethod/doesNotUnderstand: for each entry in the PIC."
	<var: #cPIC type: #'CogMethod *'>
	| picData |
	<var: #targetMethod type: #'CogMethod *'>
	self assert: (cPIC methodObject = 0 or: [objectMemory addressCouldBeOop: cPIC methodObject]).
	picData := objectMemory instantiateClass: objectMemory classArray indexableSize: cPIC cPICNumCases * 2 + 1.
	picData ifNil: [^picData].
      objectMemory storePointerUnchecked: 0 ofObject: picData withValue: cPIC selector.
	1 to: cPIC cPICNumCases do:
		[:i| | pc entryPoint target targetMethod class |
		pc := self addressOfEndOfCase: i inCPIC: cPIC.
		i = 1
			ifTrue:
				[class := cPIC methodObject. "first case may have been collected and stored here by collectCogConstituentFor:Annotation:Mcpc:Bcpc:Method:"
				 class = 0 ifTrue: [class := objectMemory nilObject]. "cPIC is unreferenced; likely evolved to OpenPIC"
				 entryPoint := backEnd jumpLongTargetBeforeFollowingAddress: pc]
			ifFalse:
				[class := objectRepresentation classForInlineCacheTag:
							(backEnd literal32BeforeFollowingAddress: pc - backEnd jumpLongConditionalByteSize).
				 entryPoint := backEnd jumpLongConditionalTargetBeforeFollowingAddress: pc].
		"Find target from jump.  A jump to the MNU entry-point should collect #doesNotUnderstand:"
		(cPIC containsAddress: entryPoint)
			ifTrue:
				[target := objectMemory splObj: SelectorDoesNotUnderstand]
			ifFalse:
				[targetMethod := self cCoerceSimple: entryPoint - cmNoCheckEntryOffset to: #'CogMethod *'.
				 self assert: targetMethod cmType = CMMethod.
				 target := targetMethod methodObject].
		objectMemory
			storePointerUnchecked: i * 2 - 1 ofObject: picData withValue: class;
			storePointerUnchecked: i * 2 ofObject: picData withValue: target].
	objectMemory beRootIfOld: picData.
	cPIC methodObject: 0. "restore invariant."
	^picData
]

{ #category : #accessing }
Cogit >> defaultCogCodeSize [
	"Return the default number of bytes to allocate for native code at startup.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<api>
	^backEnd getDefaultCogCodeSize
]

{ #category : #'compile abstract instructions' }
Cogit >> deltaToSkipPrimAndErrorStoreIn: aMethodObj header: aMethodHeader [
	"Answer the number of bytecodes to skip to get to the first bytecode
	 past the primitive call and any store of the error code."
	^(self methodUsesPrimitiveErrorCode: aMethodObj header: aMethodHeader)
		ifTrue: [(coInterpreter sizeOfCallPrimitiveBytecode: aMethodHeader)
			  + (coInterpreter sizeOfLongStoreTempBytecode: aMethodHeader)]
		ifFalse: [0]
]

{ #category : #disassembly }
Cogit >> disassemble: targetmcpc from: startpc to: endpc arg: aStream [
	<doNotGenerate>
	| startbcpc |
	self disassembleFrom: startpc to: endpc - 1 labels: Dictionary new on: aStream.
	startbcpc := (self cCoerceSimple: targetmcpc - (self sizeof: CogBlockMethod) to: #'CogBlockMethod *') startpc.
	aStream nextPutAll: 'block startpc: '.
	startbcpc printOn: aStream base: 16.
	aStream nextPut: $/.
	(objectMemory integerObjectOf: startbcpc) printOn: aStream base: 16.
	aStream cr; flush.
	^0
]

{ #category : #disassembly }
Cogit >> disassembleCodeAt: pc [
	<doNotGenerate>
	(pc between: (trampolineAddresses at: 1) and: methodZoneBase - 1) ifTrue:
		[^self disassembleTrampolineFor: pc].
	self disassembleMethodFor: pc
]

{ #category : #disassembly }
Cogit >> disassembleFrom: startAddress to: endAddress [
	<doNotGenerate>
	self disassembleFrom: startAddress to: endAddress labels: Dictionary new on: coInterpreter transcript
]

{ #category : #disassembly }
Cogit >> disassembleFrom: startAddress to: endAddress labels: labelDictionary on: aStream [
	<doNotGenerate>
	| previousTVP |
	aStream ensureCr.
	previousTVP := processor class printTempNames.
	processor class
		printTempNames: (self class initializationOptions includesKey: #tempNames);
		setReceiverResultReg: ((self class initializationOptions includesKey: #instVarNames) ifTrue:
									[ReceiverResultReg]).
	[processor
		disassembleFrom: startAddress
		to: endAddress
		in: coInterpreter memory
		for: self
		labels: labelDictionary
		on: aStream] ensure:
			[processor class
				printTempNames: previousTVP;
				setReceiverResultReg: nil].
	aStream flush
]

{ #category : #disassembly }
Cogit >> disassembleMethod: surrogateOrAddress [
	<doNotGenerate>
	self disassembleMethod: surrogateOrAddress on: coInterpreter transcript
]

{ #category : #disassembly }
Cogit >> disassembleMethod: surrogateOrAddress on: aStream [
	<doNotGenerate>
	| cogMethod mapEntries codeRanges |
	cogMethod := surrogateOrAddress isInteger
								ifTrue: [self cogMethodSurrogateAt: surrogateOrAddress]
								ifFalse: [surrogateOrAddress].
	cogMethod cmType = CMBlock ifTrue:
		[^self disassembleMethod: cogMethod cmHomeMethod on: aStream].
	(disassemblingMethod isNil
	 and: [self class initializationOptions at: #relativeAddressDisassembly ifAbsent: [false]]) ifTrue:
		[^[disassemblingMethod := cogMethod.
		    self disassembleMethod: surrogateOrAddress on: aStream] ensure:
			[disassemblingMethod := nil]].
	self printMethodHeader: cogMethod on: aStream.

	mapEntries := Dictionary new.
	(cogMethod cmType = CMMethod and: [cogMethod cmIsFullBlock]) ifFalse:
		[mapEntries at: cogMethod asInteger + cmEntryOffset put: 'entry'].
	
	cogMethod cmType = CMMethod ifTrue:
		[cogMethod cmIsFullBlock
			ifTrue: [mapEntries at: cogMethod asInteger + cbNoSwitchEntryOffset put: 'noSwitchEntry']
			ifFalse: [mapEntries at: cogMethod asInteger + cmNoCheckEntryOffset put: 'noCheckEntry']].

	cogMethod cmType = CMClosedPIC
		ifTrue:
			[mapEntries at: cogMethod asInteger + firstCPICCaseOffset put: 'ClosedPICCase0'.
			 1 to: MaxCPICCases - 1 do:
				[:i|
				mapEntries
					at: cogMethod asInteger + firstCPICCaseOffset + (i * cPICCaseSize)
					put: 'ClosedPICCase', i printString]]
		ifFalse:
			[self mapFor: cogMethod
				performUntil: #collectMapEntry:address:into:
				arg: mapEntries].

	"This would all be far more elegant and simple if we used blocks.
	 But there are no blocks in C and the basic enumerators here need
	 to be used in the real VM.  Apologies."
	(codeRanges := self codeRangesFor: cogMethod) do:
		[:range|
		(cogMethod cmType = CMMethod) ifTrue:
			[mapEntries keysAndValuesDo:
				[:mcpc :label| | bcpc selectorOrNone |
				(((range includes: mcpc) or: [range last + 1 = mcpc])
				 and: [(AnnotationsWithBytecodePCs includes: label)
				 and: [range cogMethod stackCheckOffset > 0]]) ifTrue:
					[bcpc := self bytecodePCFor: mcpc startBcpc: range startpc in: range cogMethod.
					 bcpc ~= 0 ifTrue:
						[label = #IsSendCall
							ifTrue:
								[selectorOrNone := (self selectorForSendAt: mcpc annotation: IsSendCall in: cogMethod methodObject).
								 (selectorOrNone isInteger and: [objectMemory addressCouldBeOop: selectorOrNone]) ifTrue:
									[selectorOrNone := objectMemory stringOf: selectorOrNone].
								selectorOrNone := ' ', selectorOrNone]
							ifFalse: [selectorOrNone := ''].
						 mapEntries
							at: mcpc
							put: label, selectorOrNone, ' bc ', bcpc printString, '/', (bcpc + 1) printString]]]].
		(cogMethod blockEntryOffset ~= 0
		 and: [range first = (cogMethod blockEntryOffset + cogMethod asInteger)])
			ifTrue:
				[aStream nextPutAll: 'blockEntry:'; cr.
				 self blockDispatchFor: cogMethod
					perform: #disassemble:from:to:arg:
					arg: aStream]
			ifFalse:
				[range first > (cogMethod address + cmNoCheckEntryOffset) ifTrue:
					[self printMethodHeader: range cogMethod
						on: aStream].
				self maybeNoteStartpcFor: range.
				self disassembleFrom: range first to: range last labels: mapEntries on: aStream]].
	aStream nextPutAll: 'startpc: '; print: codeRanges first startpc; cr.
	(cogMethod cmType = CMMethod
	 or: [cogMethod cmType = CMOpenPIC]) ifTrue:
		[[self mapFor: cogMethod
			performUntil: #printMapEntry:mcpc:args:
			arg: { aStream. codeRanges. cogMethod }]
			on: AssertionFailure
			do: [:ex|
				ex primitiveChangeClassTo: ResumableVMError basicNew. ":) :) :)"
				ex resume: nil]].
	^cogMethod
]

{ #category : #disassembly }
Cogit >> disassembleMethodFor: pc [
	<doNotGenerate>
	| method |
	method := methodZone methodFor: pc.
	(method isNil or: [method isZero]) ifTrue:
		[self error: 'not a method'].
	self disassembleMethod: method
]

{ #category : #disassembly }
Cogit >> disassembleTrampolineFor: pc [
	<doNotGenerate>
	| limit |
	limit := methodZoneBase - 1.
	pc > methodZoneBase ifTrue: [^self].
	trampolineTableIndex - 1 to: 0 by: -2 do:
		[:i| | addr |
		pc >= (addr := (trampolineAddresses at: i) asInteger) ifTrue:
			[^self disassembleFrom: addr to: limit].
		limit := addr - 1]
]

{ #category : #debugging }
Cogit >> disassembleTrampolineTable [
	<doNotGenerate>
	0 to: trampolineTableIndex - 1 by: 2 do:
		[:i|
		self disassembleTrampolineFor: (trampolineAddresses at: i + 1) asInteger.
		coInterpreter transcript cr]
]

{ #category : #'simulation only' }
Cogit >> doesNotUnderstand: aMessage [
	(aMessage selector beginsWith: 'print') ifTrue:
		[(coInterpreter respondsTo: aMessage selector) ifTrue:
			[^aMessage lookupClass: nil; sentTo: coInterpreter].
		(methodZone respondsTo: aMessage selector) ifTrue:
			[^aMessage lookupClass: nil; sentTo: methodZone].
		(objectMemory respondsTo: aMessage selector) ifTrue:
			[^aMessage lookupClass: nil; sentTo: objectMemory]].
	^super doesNotUnderstand: aMessage
]

{ #category : #'register management' }
Cogit >> emptyRegisterMask [
	<inline: true>
	^0
]

{ #category : #'compiled methods' }
Cogit >> endPCOf: aMethod [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	| pc end latestContinuation descriptor prim distance targetPC byte bsOffset nExts |
	pc := latestContinuation := coInterpreter startPCOfMethod: aMethod.
	(prim := coInterpreter primitiveIndexOf: aMethod) > 0 ifTrue:
		[(coInterpreter isQuickPrimitiveIndex: prim) ifTrue:
			[^pc - 1]].
	bsOffset := self bytecodeSetOffsetFor: aMethod.
	nExts := 0.
	end := objectMemory numBytesOf: aMethod.
	[pc <= end] whileTrue:
		[byte := objectMemory fetchByte: pc ofObject: aMethod.
		descriptor := self generatorAt: byte + bsOffset.
		(descriptor isReturn
		 and: [pc >= latestContinuation]) ifTrue:
			[end := pc].
		(descriptor isBranch or: [descriptor isBlockCreation]) 
			ifTrue:
				[distance := self spanFor: descriptor at: pc exts: nExts in: aMethod.
			 	targetPC := pc + descriptor numBytes + distance.
			 	latestContinuation := latestContinuation max: targetPC.
			 	descriptor isBlockCreation ifTrue:
					[pc := pc + distance]]
			ifFalse: 
				[latestContinuation := self maybeUnsafeJumpContinuation: latestContinuation at: pc for: descriptor in: aMethod].
		nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0].
		pc := pc + descriptor numBytes].
	^end
]

{ #category : #'compile abstract instructions' }
Cogit >> ensureFixupAt: targetPC [
	"Make sure there's a flagged fixup at the target pc in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	<returnTypeC: #'BytecodeFixup *'>
	| fixup |
	<var: #fixup type: #'BytecodeFixup *'>
	fixup := self fixupAt: targetPC.
	fixup notAFixup ifTrue:
		[fixup becomeFixup].
	fixup recordBcpc: bytecodePC.
	^fixup
]

{ #category : #debugging }
Cogit >> enterCogCodePopReceiver [
	"This is a static version of ceEnterCogCodePopReceiverReg
	 for break-pointing when debugging in C."
	<api>
	<inline: false>
	"This exists only for break-pointing."
	self cCode: [self realCEEnterCogCodePopReceiverReg]
		inSmalltalk: [self ceEnterCogCodePopReceiverReg].
	"(and this exists only to reference Debug)"
	Debug ifFalse: [self error: 'what??']
]

{ #category : #'in-line cacheing' }
Cogit >> entryCacheTagAndCouldBeObjectAt: mcpc annotation: annotation into: trinaryBlock [
	"Evaluate trinaryBlock with the entryPoint, inline cache tag and whether the cache
	 tag could be an object, for the send at mcpc with annotation annotation."
	<inline: true>
	| cacheTag entryPoint tagCouldBeObj |
	cacheTag := backEnd inlineCacheTagAt: mcpc asInteger.
	entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
	"in-line cache tags are the selectors of sends if sends are unlinked,
	 the selectors of super sends (entry offset = cmNoCheckEntryOffset),
	 the selectors of open PIC sends (entry offset = cmEntryOffset, target is an Open PIC)
	 or in-line cache tags (classes, class indices, immediate bit patterns, etc).
	 Note that selectors can be immediate so there is no guarantee that they
	 are markable/remappable objects."
	tagCouldBeObj := self inlineCacheTagsAreIndexes not
						and: [objectRepresentation inlineCacheTagsMayBeObjects
							or: [self entryPointTagIsSelector: entryPoint]].
	trinaryBlock
		value: entryPoint
		value: cacheTag
		value: tagCouldBeObj
]

{ #category : #accessing }
Cogit >> entryOffset [
	<api>
	<cmacro>
	^cmEntryOffset
]

{ #category : #'in-line cacheing' }
Cogit >> entryPointTagIsSelector: entryPoint [
	"Answer if the entryPoint's tag is expected to be a selector reference, as opposed to a class tag."
	^entryPoint < methodZoneBase
	 or: [(entryPoint bitAnd: entryPointMask) = uncheckedEntryAlignment
	 or: [(entryPoint bitAnd: entryPointMask) = checkedEntryAlignment
		and: [(self cCoerceSimple: entryPoint - cmEntryOffset to: #'CogMethod *') cmType = CMOpenPIC]]]
]

{ #category : #accessing }
Cogit >> estimateOfAbstractOpcodesPerBytecodes [
	<inline: true>
	^ 10
]

{ #category : #'simulation only' }
Cogit >> exclude: aMethodObj [
	"For debugging, allow excluding methods based on selector or methodClass.  Answer if the mehtod should be excluded."
	<inline: true>
	self cCode: [] inSmalltalk: "for debugging, allow excluding methods based on selector or methodClass"
		[self class initializationOptions
			at: #DoNotJIT
			ifPresent:
				[:excluded| 
				(excluded anySatisfy: [:exclude| aMethodObj = exclude]) ifTrue:
					[coInterpreter transcript
						ensureCr; nextPutAll: 'EXCLUDING ';
						nextPutAll: aMethodObj; nextPutAll: ' (compiled block)';
						cr; flush.
					 ^true]].
		 (compilationTrace anyMask: 1) ifTrue:
			[| methodClass |
			 methodClass := coInterpreter nameOfClass: (coInterpreter methodClassOf: aMethodObj).
			 coInterpreter transcript
				ensureCr;
				nextPutAll: 'compiling compiled block in ';
				nextPutAll: methodClass;
				cr; flush]].
	^false
]

{ #category : #'simulation only' }
Cogit >> exclude: aMethodObj selector: aSelectorOop [
	"For debugging, allow excluding methods based on selector or methodClass.  Answer if the mehtod should be excluded."
	<inline: true>
	self cCode: [] inSmalltalk:
		[| methodClass selector |
		 self class initializationOptions
			at: #DoNotJIT
			ifPresent:
				[:excluded|
				methodClass := coInterpreter nameOfClass: (coInterpreter methodClassOf: aMethodObj).
				selector := coInterpreter stringOf: aSelectorOop.
				(excluded anySatisfy: [:exclude| selector = exclude or: [methodClass = exclude]]) ifTrue:
					[coInterpreter transcript
						ensureCr; nextPutAll: 'EXCLUDING ';
						nextPutAll: methodClass; nextPutAll: '>>#'; nextPutAll: selector;
						cr; flush.
					 ^true]].
		 (compilationTrace anyMask: 1) ifTrue:
			[methodClass := coInterpreter nameOfClass: (coInterpreter methodClassOf: aMethodObj).
			 selector := coInterpreter stringOf: aSelectorOop.
			 selector isEmpty ifTrue:
				[selector := coInterpreter stringOf: (coInterpreter maybeSelectorOfMethod: aMethodObj)].
			 coInterpreter transcript
				ensureCr; nextPutAll: 'compiling ';
				nextPutAll: methodClass; nextPutAll: '>>#'; nextPutAll: selector;
				cr; flush]].
	^false
]

{ #category : #'in-line cacheing' }
Cogit >> expectedClosedPICPrototype: cPIC [
	"Use asserts to check if the ClosedPICPrototype is as expected from compileClosedPICPrototype,
	 and can be updated as required via rewriteCPICCaseAt:tag:objRef:target:.  If all asserts pass, answer
	 0, otherwise answer a bit mask identifying all the errors."
	"self disassembleFrom: methodZoneBase + (self sizeof: CogMethod) to: methodZoneBase + closedPICSize"
	<var: #cPIC type: #'CogMethod *'>
	| pc errors object classTag entryPoint |
	errors := 0.
	pc := cPIC asUnsignedInteger + firstCPICCaseOffset.
	"First jump is unconditional; subsequent ones are conditional"
	object := backEnd literalBeforeFollowingAddress: pc - backEnd jumpLongByteSize.
	(self asserta: object = self firstPrototypeMethodOop) ifFalse:
		[errors := 1].

	entryPoint := backEnd jumpLongTargetBeforeFollowingAddress: pc.
	(self asserta: entryPoint = (self cPICPrototypeCaseOffset + 16rCA5E10)) ifFalse:
		[errors := errors + 2].

	1 to: MaxCPICCases - 1 do:
		[:i | | methodObjPC classTagPC |
		pc := pc + cPICCaseSize.

		"verify information in case is as expected."
		methodObjPC := pc - backEnd jumpLongConditionalByteSize - backEnd cmpC32RTempByteSize.
		object := backEnd literalBeforeFollowingAddress: methodObjPC.
		(self asserta: object = (self subsequentPrototypeMethodOop+ i)) ifFalse:
			[errors := errors bitOr: 4].

		classTagPC := pc - backEnd jumpLongConditionalByteSize.
		classTag := backEnd literal32BeforeFollowingAddress: classTagPC.
		(self asserta: classTag = (16rBABE1F15 + i)) ifFalse:
			[errors := errors bitOr: 8].

		entryPoint := backEnd jumpLongConditionalTargetBeforeFollowingAddress: pc.
		(self asserta: entryPoint = (self cPICPrototypeCaseOffset + 16rCA5E10 + (i * 16))) ifFalse:
			[errors := errors bitOr: 16].

		"change case via rewriteCPICCaseAt:tag:objRef:target:"
		self rewriteCPICCaseAt: pc
			tag: (classTag bitXor: 16r5A5A5A5A)
			objRef: (object bitXor: 16rA5A5A5A5)
			target: (entryPoint bitXor: 16r55AA50). "don't xor least 4 bits to leave instruction alignment undisturbed"

		"verify information in case is as expected post update."
		object := backEnd literalBeforeFollowingAddress: methodObjPC.
		(self asserta: object = (self subsequentPrototypeMethodOop + i bitXor: 16rA5A5A5A5)) ifFalse:
			[errors := errors bitOr: 32].
		classTag := backEnd literal32BeforeFollowingAddress: classTagPC.
		(self asserta: classTag = (16rBABE1F15 + i bitXor: 16r5A5A5A5A)) ifFalse:
			[errors := errors bitOr: 64].
		entryPoint := backEnd jumpLongConditionalTargetBeforeFollowingAddress: pc.
		(self asserta: entryPoint = ((self cPICPrototypeCaseOffset + 16rCA5E10 + (i * 16)) bitXor: 16r55AA50)) ifFalse:
			[errors := errors bitOr: 128].

		"finally restore case to the original state"
		self rewriteCPICCaseAt: pc
			tag: (classTag bitXor: 16r5A5A5A5A)
			objRef: (object bitXor: 16rA5A5A5A5)
			target: (entryPoint bitXor: 16r55AA50)].

	entryPoint := backEnd jumpLongTargetBeforeFollowingAddress: pc + cPICEndSize - literalsManager endSizeOffset.
	(self asserta: entryPoint = (self cPICMissTrampolineFor: 0)) ifFalse:
		[errors := errors + 256].
	
	^errors
]

{ #category : #'bytecode generators' }
Cogit >> extABytecode [
	"224		11100000	aaaaaaaa	Extend A (Ext A = Ext A prev * 256 + Ext A)"
	extA := (extA bitShift: 8) + byte1.
	^0
]

{ #category : #'bytecode generators' }
Cogit >> extBBytecode [
	"225		11100001	sbbbbbbb	Extend B (Ext B = Ext B prev * 256 + Ext B)"
	extB := (numExtB = 0 and: [byte1 > 127])
				ifTrue: [byte1 - 256]
				ifFalse: [(extB bitShift: 8) + byte1].
	numExtB := numExtB + 1.
	^0
]

{ #category : #initialization }
Cogit >> fakeAddressFor: anObject index: index [
	"Answer a fake address for some variable based on some index.
	 The index will usually be the size of simulatedAddresses, but
	 in determining the varBaseAddress we take a guess at the final
	 size of simulatedAddresses."
	<doNotGenerate>
	^(index + 101 * objectMemory wordSize) negated
		bitAnd: ((backEnd notNil
				and: [backEnd wantsNearAddressFor: anObject])
					ifTrue: [self addressSpaceMask]
					ifFalse: [self allButTopBitOfAddressSpaceMask])
]

{ #category : #accessing }
Cogit >> fakeVarBaseAddress [
	"We expect simulatedAddresses to have around 40 entries.  48 is hopefully a good maximum."
	<doNotGenerate>
	^self fakeAddressFor: nil index: 48
]

{ #category : #'generate machine code' }
Cogit >> fillInBlockHeadersAt: startAddress [
	"Fill in the block headers now we know the exact layout of the code."
	| blockStart blockHeader |
	<var: #blockStart type: #'BlockStart *'>
	<var: #blockHeader type: #'CogBlockMethod *'>

	(needsFrame and: [blockCount > 0]) ifFalse:
		[^nil].
	blockNoContextSwitchOffset = nil
		ifTrue: [blockNoContextSwitchOffset := blockEntryLabel address - blockEntryNoContextSwitch address]
		ifFalse: [self assert: blockNoContextSwitchOffset = (blockEntryLabel address - blockEntryNoContextSwitch address)].
	0 to: blockCount - 1 do:
		[:i|
		blockStart := self blockStartAt: i.
		blockHeader := self cCoerceSimple: blockStart fakeHeader address
								to: #'CogBlockMethod *'.
		blockHeader
			homeOffset: (blockStart fakeHeader address - startAddress);
			startpc: blockStart startpc;
			cmType: CMBlock;
			cmNumArgs: blockStart numArgs;
			cbUsesInstVars: blockStart hasInstVarRef;
			stackCheckOffset: (blockStart stackCheckLabel = nil
								ifTrue: [0]
								ifFalse: [blockStart stackCheckLabel address - blockStart fakeHeader address])]
]

{ #category : #'generate machine code' }
Cogit >> fillInCPICHeader: pic numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector [
	<returnTypeC: #'CogMethod *'>
	<var: #pic type: #'CogMethod *'>
	<inline: true>
	self assert: (objectMemory isYoung: selector) not.
	pic cmType: CMClosedPIC.
	pic objectHeader: 0.
	pic blockSize: closedPICSize.
	pic methodObject: 0.
	pic methodHeader: 0.
	pic selector: selector.
	pic cmNumArgs: numArgs.
	pic cmRefersToYoung: false.
	pic cmUsageCount: self initialClosedPICUsageCount.
	pic cpicHasMNUCase: hasMNUCase.
	pic cPICNumCases: numCases.
	pic blockEntryOffset: 0.
	self assert: pic cmType = CMClosedPIC.
	self assert: pic selector = selector.
	self assert: pic cmNumArgs = numArgs.
	self assert: pic cPICNumCases = numCases.
	self assert: (backEnd callTargetFromReturnAddress: pic asInteger + missOffset) = (self picAbortTrampolineFor: numArgs).
	self assert: closedPICSize = (methodZone roundUpLength: closedPICSize).
	processor flushICacheFrom: pic asUnsignedInteger to: pic asUnsignedInteger + closedPICSize.
	self maybeEnableSingleStep.
	^pic
]

{ #category : #'generate machine code' }
Cogit >> fillInMethodHeader: method size: size selector: selector [
	<returnTypeC: #'CogMethod *'>
	<var: #method type: #'CogMethod *'>
	| originalMethod rawHeader |
	<var: #originalMethod type: #'CogMethod *'>
	method cmType: CMMethod.
	method objectHeader: objectMemory nullHeaderForMachineCodeMethod.
	method blockSize: size.
	method methodObject: methodObj.
	rawHeader := coInterpreter rawHeaderOf: methodObj.
	"If the method has already been cogged then
	 leave the original method attached to its cog method, but get the right header."
	(coInterpreter isCogMethodReference: rawHeader)
		ifTrue:
			[originalMethod := self cCoerceSimple: rawHeader to: #'CogMethod *'.
			self assert: originalMethod blockSize = size.
			self assert: methodHeader = originalMethod methodHeader ]
		ifFalse: [ coInterpreter rawHeaderOf: methodObj put: method asInteger ].
	method methodHeader: methodHeader.
	method selector: selector.
	method cmNumArgs: (coInterpreter argumentCountOfMethodHeader: methodHeader).
	(method cmRefersToYoung: hasYoungReferent) ifTrue:
		[methodZone addToYoungReferrers: method].
	method cmUsageCount: self initialMethodUsageCount.
	method cpicHasMNUCase: false.
	method cmUsesPenultimateLit: maxLitIndex >= ((objectMemory literalCountOfMethodHeader: methodHeader) - 2).
	method blockEntryOffset: (blockEntryLabel notNil
								ifTrue: [blockEntryLabel address - method asInteger]
								ifFalse: [0]).
	"This can be an error check since a large stackCheckOffset is caused by compiling
	 a machine-code primitive, and hence depends on the Cogit, not the input method."
	needsFrame ifTrue:
		[stackCheckLabel address - method asInteger <= MaxStackCheckOffset ifFalse:
			[self error: 'too much code for stack check offset']].
	method stackCheckOffset: (needsFrame
								ifTrue: [stackCheckLabel address - method asInteger]
								ifFalse: [0]).
	self assert: (backEnd callTargetFromReturnAddress: method asInteger + missOffset)
				= (self methodAbortTrampolineFor: method cmNumArgs).
	self assert: size = (methodZone roundUpLength: size).
	processor flushICacheFrom: method asUnsignedInteger to: method asUnsignedInteger + size.
	self maybeEnableSingleStep.
	^method
]

{ #category : #'generate machine code' }
Cogit >> fillInOPICHeader: pic numArgs: numArgs selector: selector [
	<returnTypeC: #'CogMethod *'>
	<var: #pic type: #'CogMethod *'>
	<inline: true>
	pic cmType: CMOpenPIC.
	pic objectHeader: 0.
	pic blockSize: openPICSize.
	"pic methodObject: 0.""This is also the nextOpenPIC link so don't initialize it"
	methodZone addToOpenPICList: pic.
	pic methodHeader: 0.
	pic selector: selector.
	pic cmNumArgs: numArgs.
	(pic cmRefersToYoung: (objectMemory isYoung: selector)) ifTrue:
		[methodZone addToYoungReferrers: pic].
	pic cmUsageCount: self initialOpenPICUsageCount.
	pic cpicHasMNUCase: false.
	pic cPICNumCases: 0.
	pic blockEntryOffset: 0.
	self assert: pic cmType = CMOpenPIC.
	self assert: pic selector = selector.
	self assert: pic cmNumArgs = numArgs.
	self assert: (backEnd callTargetFromReturnAddress: pic asInteger + missOffset) = (self picAbortTrampolineFor: numArgs).
	self assert: openPICSize = (methodZone roundUpLength: openPICSize).
	processor flushICacheFrom: pic asUnsignedInteger to: pic asUnsignedInteger + openPICSize.
	self maybeEnableSingleStep.
	^pic
]

{ #category : #'method map' }
Cogit >> find: descriptor IsBackwardBranch: isBackwardBranchAndAnnotation Mcpc: mcpc Bcpc: bcpc MatchingBcpc: targetBcpc [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #mcpc type: #'char *'>
	<var: #targetBcpc type: #'void *'>
	<inline: true>
	^targetBcpc asInteger = ((descriptor isNil or: [isBackwardBranchAndAnnotation anyMask: 1])
									ifTrue: [bcpc]
									ifFalse: [bcpc + descriptor numBytes])
		ifTrue: [mcpc asInteger]
		ifFalse: [0]
]

{ #category : #'method map' }
Cogit >> find: descriptor IsBackwardBranch: isBackwardBranchAndAnnotation Mcpc: mcpc Bcpc: bcpc MatchingMcpc: targetMcpc [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #mcpc type: #'char *'>
	<var: #targetMcpc type: #'void *'>
	"Machine code addresses map to the following bytecode for all bytecodes
	 except backward branches, where they map to the backward branch itself.
	 This is so that loops continue, rather than terminate prematurely."
	^targetMcpc = mcpc
		ifTrue: [(descriptor isNil or: [isBackwardBranchAndAnnotation anyMask: 1])
					ifTrue: [bcpc]
					ifFalse: [bcpc + descriptor numBytes]]
		ifFalse: [0]
]

{ #category : #'method map' }
Cogit >> findBackwardBranch: descriptor IsBackwardBranch: isBackwardBranchAndAnnotation Mcpc: mcpc Bcpc: bcpc MatchingBcpc: targetBcpc [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #mcpc type: #'char *'>
	<var: #targetBcpc type: #'void *'>
	<inline: true>
	^((isBackwardBranchAndAnnotation anyMask: 1) and: [targetBcpc asInteger = bcpc])
		ifTrue: [mcpc asInteger]
		ifFalse: [0]
]

{ #category : #'method map' }
Cogit >> findBlockMethodWithEntry: blockEntryMcpc startBcpc: startBcpc [
	<returnTypeC: #usqInt>
	| cogBlockMethod |
	<var: #cogBlockMethod type: #'CogBlockMethod *'>
	cogBlockMethod := self cCoerceSimple: blockEntryMcpc - (self sizeof: CogBlockMethod)
							  to: #'CogBlockMethod *'.
	cogBlockMethod startpc = startBcpc ifTrue:
		[^cogBlockMethod asUnsignedInteger].
	^0 "keep scanning..."
]

{ #category : #'method map' }
Cogit >> findMapLocationForMcpc: targetMcpc inMethod: cogMethod [
	<var: #targetMcpc type: #usqInt>
	<var: #cogMethod type: #'CogMethod *'>
	| mcpc map mapByte annotation |
	mcpc := self firstMappedPCFor: cogMethod.
	map := self mapStartFor: cogMethod.
	mcpc = targetMcpc ifTrue: [^map].
	[(mapByte := objectMemory byteAt: map) ~= MapEnd] whileTrue:
		[annotation := mapByte >> AnnotationShift.
		 annotation ~= IsAnnotationExtension ifTrue:
			[mcpc := mcpc + (backEnd codeGranularity
								* (annotation = IsDisplacementX2N
									ifTrue: [mapByte - DisplacementX2N << AnnotationShift]
									ifFalse: [mapByte bitAnd: DisplacementMask]))].
		 mcpc >= targetMcpc ifTrue:
			[self assert: mcpc = targetMcpc.
			 annotation = IsDisplacementX2N ifTrue:
				[map := map - 1.
				 mapByte := objectMemory byteAt: map.
				 annotation := mapByte >> AnnotationShift.
				 self assert: annotation > IsAnnotationExtension].
			 ^map].
		 map := map - 1].
	^0
]

{ #category : #'method map' }
Cogit >> findMethodForStartBcpc: startbcpc inHomeMethod: cogMethod [
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	<returnTypeC: #'CogBlockMethod *'>
	"Find the CMMethod or CMBlock that has zero-relative startbcpc as its first bytecode pc.
	 As this is for cannot resume processing and/or conversion to machine-code on backward
	 branch, it doesn't have to be fast.  Enumerate block returns and map to bytecode pcs."
	self assert: cogMethod cmType = CMMethod.
	startbcpc = (coInterpreter startPCOfMethodHeader: cogMethod methodHeader) ifTrue:
		[^self cCoerceSimple: cogMethod to: #'CogBlockMethod *'].
	self assert: cogMethod blockEntryOffset ~= 0.
	^self cCoerceSimple: (self blockDispatchTargetsFor: cogMethod
								perform: #findBlockMethodWithEntry:startBcpc:
								arg: startbcpc)
		to: #'CogBlockMethod *'
]

{ #category : #'method map' }
Cogit >> firstMappedPCFor: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	^cogMethod cmIsFullBlock
		ifTrue: [cogMethod asUnsignedInteger + cbNoSwitchEntryOffset]
		ifFalse: [cogMethod asUnsignedInteger + cmNoCheckEntryOffset]
]

{ #category : #'in-line cacheing' }
Cogit >> firstPrototypeMethodOop [
	"Answer a fake value for the first method oop in the PIC prototype.
	 Since we use MoveUniqueCw:R: it must not be confused with a method-relative address."
	<inline: false>
	^(self addressIsInCurrentCompilation: 16r5EAF00D)
		ifTrue: [16rCA7F00D]
		ifFalse: [16r5EAF00D]
]

{ #category : #'compile abstract instructions' }
Cogit >> fixupAt: fixupPC [
	<inline: true>
	^self fixupAtIndex: fixupPC - initialPC
]

{ #category : #'compile abstract instructions' }
Cogit >> fixupAtIndex: index [
	"The fixups Array maps to bytecode pcs such that initialPC maps to index 0.
	 fixupAt: does the conversion."
	<cmacro: '(index) (&fixups[index])'>
	<returnTypeC: #'BytecodeFixup *'>
	^self addressOf: (fixups at: index)
]

{ #category : #'garbage collection' }
Cogit >> followForwardedLiteralsIn: cogMethod [
	<api>
	<option: #SpurObjectMemory>
	<var: #cogMethod type: #'CogMethod *'>
	self assert: (cogMethod cmType ~= CMMethod or: [(objectMemory isForwarded: cogMethod methodObject) not]).
	(objectMemory shouldRemapOop: cogMethod selector) ifTrue:
		[cogMethod selector: (objectMemory remapObj: cogMethod selector).
		 (objectMemory isYoung: cogMethod selector) ifTrue:
			[methodZone ensureInYoungReferrers: cogMethod]].
	self mapFor: cogMethod
		performUntil: #remapIfObjectRef:pc:hasYoung:
		arg: 0
]

{ #category : #'garbage collection' }
Cogit >> followForwardedMethods [
	<api>
	<option: #SpurObjectMemory>
	<var: #cogMethod type: #'CogMethod *'>
	| cogMethod freedPIC |
	<var: #cogMethod type: #'CogMethod *'>
	freedPIC := false.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod ifTrue:
			[(objectMemory isForwarded: cogMethod methodObject) ifTrue:
				[cogMethod methodObject: (objectMemory followForwarded: cogMethod methodObject).
				 (objectMemory isYoungObject: cogMethod methodObject) ifTrue:
					[methodZone ensureInYoungReferrers: cogMethod]]].
		 cogMethod cmType = CMClosedPIC ifTrue:
			[(self followMethodReferencesInClosedPIC: cogMethod) ifTrue:
				[freedPIC := true.
				 methodZone freeMethod: cogMethod]].
		 cogMethod := methodZone methodAfter: cogMethod].
	freedPIC ifTrue:
		[self unlinkSendsToFree]
]

{ #category : #'garbage collection' }
Cogit >> followMaybeObjRefInClosedPICAt: mcpc [
	"Follow a potential object reference from a closed PIC.
	 This may be a method reference or null.
	 Answer if the followed literal is young.
	'mcpc' refers to the jump/branch instruction at the end of
	each cpic case"
	| object subject |
	object := backEnd literalBeforeFollowingAddress: mcpc.
	(objectRepresentation couldBeObject: object) ifFalse:
		[^false].
	(objectMemory isForwarded: object) ifFalse:
		[^objectMemory isYoungObject: object].
	subject := objectMemory followForwarded: object.
	backEnd storeLiteral: subject beforeFollowingAddress: mcpc.
	codeModified := true.
	^objectMemory isYoungObject: subject
]

{ #category : #'garbage collection' }
Cogit >> followMethodReferencesInClosedPIC: cPIC [
	"Remap all object references in the closed PIC.  Answer if any references are young.
	Set codeModified if any modifications are made."
	<var: #cPIC type: #'CogMethod *'>
	| pc refersToYoung |
	pc := self addressOfEndOfCase: 1 inCPIC: cPIC.

	"first we check the potential method oop load at the beginning of the CPIC"
	refersToYoung := self followMaybeObjRefInClosedPICAt: pc - backEnd jumpLongByteSize.

	"We find the end address of the cPICNumCases'th case and can then just step forward by the case size thereafter"
	pc := self addressOfEndOfCase:  cPIC cPICNumCases inCPIC: cPIC.
	
	"Next we check the potential potential method oop load for each case."
	2 to: cPIC cPICNumCases do:
		[:i|
		(self followMaybeObjRefInClosedPICAt: pc - backEnd jumpLongConditionalByteSize - backEnd cmpC32RTempByteSize) ifTrue:
			[refersToYoung := true].
		pc := pc + cPICCaseSize].
	^refersToYoung
]

{ #category : #'simulation only' }
Cogit >> framePointerAddress [
	"redirect for the backEnd's genSaveStackPointers"
	<doNotGenerate>
	^coInterpreter framePointerAddress
]

{ #category : #'jit - api' }
Cogit >> freeMethod: cogMethod [
	<doNotGenerate>
	methodZone freeMethod: cogMethod
]

{ #category : #compaction }
Cogit >> freePICsWithFreedTargets [
	| cogMethod count |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	count := 0.
	[cogMethod < methodZone limitZony] whileTrue:
		[(cogMethod cmType = CMClosedPIC
		 and: [self cPICHasFreedTargets: cogMethod]) ifTrue:
			[cogMethod cmType: CMFree].
		 cogMethod := methodZone methodAfter: cogMethod.
		 count := count + 1].
	self assert: count = methodZone numMethods
]

{ #category : #'jit - api' }
Cogit >> freeUnmarkedMachineCode [
	"Free machine-code methods whose compiled methods are unmarked
	 and open PICs whose selectors are not marked, and closed PICs that
	 refer to unmarked objects."
	<api>
	<option: #SpurObjectMemory>
	| cogMethod freedMethod |
	<var: #cogMethod type: #'CogMethod *'>
	freedMethod := false.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[(cogMethod cmType = CMMethod
		  and: [(objectMemory isMarked: cogMethod methodObject) not]) ifTrue:
			[freedMethod := true.
			 methodZone freeMethod: cogMethod].
		 (cogMethod cmType = CMOpenPIC
		  and: [(objectMemory isImmediate: cogMethod selector) not
		  and: [(objectMemory isMarked: cogMethod selector) not]]) ifTrue:
			[freedMethod := true.
			 methodZone freeMethod: cogMethod].
		 (cogMethod cmType = CMClosedPIC
		  and: [self closedPICRefersToUnmarkedObject: cogMethod]) ifTrue:
			[freedMethod := true.
			 methodZone freeMethod: cogMethod].
		 cogMethod := methodZone methodAfter: cogMethod].
	freedMethod ifTrue:
		[self unlinkSendsToFree]
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode [ "<Integer>"
	| abstractInstruction |
	<inline: false>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	self assert: opcodeIndex < numAbstractOpcodes.
	abstractInstruction := self abstractInstructionAt: opcodeIndex.
	opcodeIndex := opcodeIndex + 1.
	abstractInstruction opcode: opcode.
	self cCode: '' inSmalltalk: [abstractInstruction bcpc: bytecodePC].
	^abstractInstruction
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" literal: operand [ "<Integer|CogAbstractInstruction>"
	"Literals are constants that either represent objects on the heap that may get updated by
	 the garbage collector, or pc-relative spans that may get changed by code compaction, and
	 must hence always be encoded in a form that allows updating to refer to a different value."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^literalsManager
		checkLiteral: operand
		forInstruction: (self gen: opcode operand: operand)
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" literal: operandOne "<Integer>" operand: operandTwo [ "<Integer|CogAbstractInstruction>"
	"Literals are constants that either represent objects on the heap that may get updated by
	 the garbage collector, or pc-relative spans that may get changed by code compaction, and
	 must hence always be encoded in a form that allows updating to refer to a different value."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^literalsManager
		checkLiteral: operandOne
		forInstruction: (self gen: opcode operand: operandOne operand: operandTwo)
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" operand: operand [ "<Integer|CogAbstractInstruction>"
	| abstractInstruction |
	<inline: false>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	self assert: opcodeIndex < numAbstractOpcodes.
	abstractInstruction := self abstractInstructionAt: opcodeIndex.
	opcodeIndex := opcodeIndex + 1.
	abstractInstruction opcode: opcode.
	abstractInstruction operands at: 0 put: operand.
	self cCode: '' inSmalltalk: [abstractInstruction bcpc: bytecodePC].
	^abstractInstruction
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" operand: operandOne "<Integer|CogAbstractInstruction>" literal: operandTwo [ "<Integer>"
	"Literals are constants that either represent objects on the heap that may get updated by
	 the garbage collector, or pc-relative spans that may get changed by code compaction, and
	 must hence always be encoded in a form that allows updating to refer to a different value."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^literalsManager
		checkLiteral: operandTwo
		forInstruction: (self gen: opcode operand: operandOne operand: operandTwo)
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" operand: operandOne "<Integer|CogAbstractInstruction>" operand: operandTwo [ "<Integer|CogAbstractInstruction>"
	| abstractInstruction |
	<inline: false>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	self assert: opcodeIndex < numAbstractOpcodes.
	abstractInstruction := self abstractInstructionAt: opcodeIndex.
	opcodeIndex := opcodeIndex + 1.
	abstractInstruction opcode: opcode.
	abstractInstruction operands at: 0 put: operandOne.
	abstractInstruction operands at: 1 put: operandTwo.
	self cCode: '' inSmalltalk: [abstractInstruction bcpc: bytecodePC].
	^abstractInstruction
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" operand: operandOne "<Integer|CogAbstractInstruction>" operand: operandTwo "<Integer|CogAbstractInstruction>" operand: operandThree [ "<Integer|CogAbstractInstruction>"
	| abstractInstruction |
	<inline: false>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	self assert: opcodeIndex < numAbstractOpcodes.
	abstractInstruction := self abstractInstructionAt: opcodeIndex.
	opcodeIndex := opcodeIndex + 1.
	abstractInstruction opcode: opcode.
	abstractInstruction operands at: 0 put: operandOne.
	abstractInstruction operands at: 1 put: operandTwo.
	abstractInstruction operands at: 2 put: operandThree.
	self cCode: '' inSmalltalk: [abstractInstruction bcpc: bytecodePC].
	^abstractInstruction
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" operand: operandOne "<Integer|CogAbstractInstruction>" operand: operandTwo "<Integer|CogAbstractInstruction>" operand: operandThree "<Integer|CogAbstractInstruction>" operand: operandFour [ "<Integer|CogAbstractInstruction>"
	| abstractInstruction |
	<inline: false>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	self assert: opcodeIndex < numAbstractOpcodes.
	abstractInstruction := self abstractInstructionAt: opcodeIndex.
	opcodeIndex := opcodeIndex + 1.
	abstractInstruction opcode: opcode.
	abstractInstruction operands at: 0 put: operandOne.
	abstractInstruction operands at: 1 put: operandTwo.
	abstractInstruction operands at: 2 put: operandThree.
	abstractInstruction operands at: 3 put: operandFour.
	self cCode: '' inSmalltalk: [abstractInstruction bcpc: bytecodePC].
	^abstractInstruction
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" operand: operandOne "<Integer|CogAbstractInstruction>" quickConstant: operandTwo [ "Integer>"
	"Quick constants are those the back end is free to encode as compactly as possible."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^literalsManager
		checkQuickConstant: operandTwo
		forInstruction: (self gen: opcode operand: operandOne operand: operandTwo)
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" operand: operandOne "<Integer|CogAbstractInstruction>" quickConstant: operandTwo "<Integer>" operand: operandThree [ "<Integer|CogAbstractInstruction>"
	"Quick constants are those the back end is free to encode as compactly as possible.""<Integer|CogAbstractInstruction>"
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^literalsManager
		checkQuickConstant: operandTwo
		forInstruction: (self gen: opcode operand: operandOne operand: operandTwo operand: operandThree)
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" quickConstant: operand [ "<Integer>"
	"Quick constants are those the back end is free to encode as compactly as possible."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^literalsManager
		checkQuickConstant: operand
		forInstruction: (self gen: opcode operand: operand)
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" quickConstant: operandOne "<Integer>" operand: operandTwo [ "<Integer|CogAbstractInstruction>"
	"Quick constants are those the back end is free to encode as compactly as possible."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^literalsManager
		checkQuickConstant: operandOne
		forInstruction: (self gen: opcode operand: operandOne operand: operandTwo)
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" quickConstant: operandOne "<Integer>" operand: operandTwo "<Integer|CogAbstractInstruction>" operand: operandThree [ "<Integer|CogAbstractInstruction>"
	"Quick constants are those the back end is free to encode as compactly as possible.""<Integer|CogAbstractInstruction>"
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^literalsManager
		checkQuickConstant: operandOne
		forInstruction: (self gen: opcode operand: operandOne operand: operandTwo operand: operandThree)
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" uniqueLiteral: operandOne "<Integer>" operand: operandTwo [ "<Integer|CogAbstractInstruction>"
	"Literals are constants that either represent objects on the heap that may get updated by
	 the garbage collector, or pc-relative spans that may get changed by code compaction, and
	 must hence always be encoded in a form that allows updating to refer to a different value."
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^literalsManager
		uniqueLiteral: operandOne
		forInstruction: (self gen: opcode operand: operandOne operand: operandTwo)
]

{ #category : #'trampoline support' }
Cogit >> genCallMustBeBooleanFor: boolean [
	"Call ceSendMustBeBooleanTo: via the relevant trampoline."
	^self CallRT: (boolean = objectMemory falseObject
					ifTrue: [ceSendMustBeBooleanAddFalseTrampoline]
					ifFalse: [ceSendMustBeBooleanAddTrueTrampoline])
]

{ #category : #initialization }
Cogit >> genCheckForInterruptsTrampoline [
	self zeroOpcodeIndex.
	"if we have a link register we will assume that it does not get automatically pushed onto the stack
	and thus there is no need to pop it before saving to instructionPointerAddress"
	backEnd hasLinkRegister
		ifTrue:
			[self MoveR: LinkReg Aw: coInterpreter instructionPointerAddress]
		ifFalse:
			[self PopR: TempReg. "instruction pointer"
			 self MoveR: TempReg Aw: coInterpreter instructionPointerAddress].
	^self genTrampolineFor: #ceCheckForInterrupts
		called: 'ceCheckForInterruptsTrampoline'
		numArgs: 0
		arg: nil
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: false
		resultReg: NoReg
		appendOpcodes: true
]

{ #category : #'compile abstract instructions' }
Cogit >> genConditionalBranch: opcode operand: operandOne [
	^self previousInstruction noteFollowingConditionalBranch: (self gen: opcode operand: operandOne)
]

{ #category : #initialization }
Cogit >> genEnilopmartFor: regArg1 and: regArg2OrNone and: regArg3OrNone forCall: forCall called: trampolineName [
	"An enilopmart (the reverse of a trampoline) is a piece of code that makes
	 the system-call-like transition from the C runtime into generated machine
	 code.  The desired arguments and entry-point are pushed on a stackPage's
	 stack.  The enilopmart pops off the values to be loaded into registers and
	 then executes a return instruction to pop off the entry-point and jump to it.

						BEFORE				AFTER			(stacks grow down)
						whatever			stackPointer ->	whatever
						target address =>	reg1 = reg1val, etc
						reg1val				pc = target address
						reg2val
		stackPointer ->	reg3val"

	<var: #trampolineName type: #'char *'>
	<returnTypeC: #'void (*genEnilopmartForandandforCallcalled(sqInt regArg1, sqInt regArg2OrNone, sqInt regArg3OrNone, sqInt forCall, char *trampolineName))(void)'>

	| size endAddress enilopmart |
	self zeroOpcodeIndex.
	backEnd hasVarBaseRegister ifTrue:
		[self MoveCq: self varBaseAddress R: VarBaseReg]. "Must happen first; value may be used in genLoadStackPointers"
	backEnd genLoadStackPointers.
	regArg3OrNone ~= NoReg ifTrue: [self PopR: regArg3OrNone].
	regArg2OrNone ~= NoReg ifTrue: [self PopR: regArg2OrNone].
	self PopR: regArg1.
	self genEnilopmartReturn: forCall.
	self computeMaximumSizes.
	size := self generateInstructionsAt: methodZoneBase.
	endAddress := self outputInstructionsAt: methodZoneBase.
	self assert: methodZoneBase + size = endAddress.
	enilopmart := methodZoneBase.
	methodZoneBase := self alignUptoRoutineBoundary: endAddress.
	backEnd stopsFrom: endAddress to: methodZoneBase - 1.
	self recordGeneratedRunTime: trampolineName address: enilopmart.
	^self cCoerceSimple: enilopmart to: #'void (*)(void)'
]

{ #category : #initialization }
Cogit >> genEnilopmartFor: regArg1 and: regArg2 forCall: forCall called: trampolineName [
	<inline: true>
	^self genEnilopmartFor: regArg1 and: regArg2 and: NoReg forCall: forCall called: trampolineName
]

{ #category : #initialization }
Cogit >> genEnilopmartFor: regArg1 forCall: forCall called: trampolineName [
	<inline: true>
	^self genEnilopmartFor: regArg1 and: NoReg and: NoReg forCall: forCall called: trampolineName
]

{ #category : #initialization }
Cogit >> genEnilopmartReturn: forCall [
	"An enilopmart (the reverse of a trampoline) is a piece of code that makes
	 the system-call-like transition from the C runtime into generated machine
	 code.  At the point the enilopmart enters machine code via a return instruction,
	 any argument registers have been loaded with their values and the stack, if
	 for call, looks like
							ret pc
			stackPointer ->	target address

	 and if not for call, looks like
							whatever
			stackPointer ->	target address

	 If forCall and running on a CISC, ret pc must be left on the stack.  If forCall and
	 running on a RISC, ret pc must be popped into LinkReg.  In either case, target
	 address must be removed from the stack and jumped/returned to."

	backEnd hasLinkRegister
		ifTrue:
			[forCall
				ifTrue:
					[self PopR: RISCTempReg.
					 self PopR: LinkReg.
					 self JumpR: RISCTempReg]
				ifFalse:
					[backEnd hasPCRegister
						ifTrue: [self PopR: PCReg]
						ifFalse:
							[self PopR: RISCTempReg.
							 self JumpR: RISCTempReg]]]
		ifFalse:
			[self RetN: 0]
]

{ #category : #'trampoline support' }
Cogit >> genExternalizePointersForPrimitiveCall [
	self MoveR: FPReg Aw: coInterpreter framePointerAddress.
	backEnd hasLinkRegister
		ifTrue:
			["Set coInterpreter stackPointer to the topmost argument, skipping the return address."
			 self MoveR: SPReg Aw: coInterpreter stackPointerAddress.
			 self MoveR: LinkReg Aw: coInterpreter instructionPointerAddress]
		ifFalse:
			[self PopR: TempReg. "get retpc"
			 self MoveR: TempReg Aw: coInterpreter instructionPointerAddress.
			 "Set coInterpreter stackPointer to the topmost argument, skipping the return address."
			 self MoveR: SPReg Aw: coInterpreter stackPointerAddress].
	^0
]

{ #category : #initialization }
Cogit >> genGetLeafCallStackPointer [
	"Generate a routine that answers the stack pointer immedately
	 after a leaf call, used for checking stack pointer alignment."
	| startAddress |
	<inline: false>
	self allocateOpcodes: 4 bytecodes: 0.
	startAddress := methodZoneBase.
	self
		MoveR: FPReg R: backEnd cResultRegister;
		RetN: 0.
	self outputInstructionsForGeneratedRuntimeAt: startAddress.
	self recordGeneratedRunTime: 'ceGetFP' address: startAddress.
	ceGetFP := self cCoerceSimple: startAddress to: #'usqIntptr_t (*)(void)'.
	startAddress := methodZoneBase.
	self zeroOpcodeIndex.
	self MoveR: SPReg R: backEnd cResultRegister.
	backEnd leafCallStackPointerDelta ~= 0 ifTrue:
		[self AddCq: backEnd leafCallStackPointerDelta R: backEnd cResultRegister].
	self RetN: 0.
	self outputInstructionsForGeneratedRuntimeAt: startAddress.
	self recordGeneratedRunTime: 'ceGetSP' address: startAddress.
	ceGetSP := self cCoerceSimple: startAddress to: #'usqIntptr_t (*)(void)'
]

{ #category : #initialization }
Cogit >> genInnerPICAbortTrampoline: name [
	"Generate the abort for a PIC.  This abort performs either a call of
	 ceInterpretMethodFromPIC:receiver: to handle invoking an uncogged target
	 or a call of ceMNUFromPICMNUMethod:receiver: to handle an MNU dispatch
	 in a closed PIC.  It distinguishes the two by testing ClassReg.  If the register
	 is zero then this is an MNU.
	
	 This poses a problem in 32-bit Spur, where zero is the cache tag for immediate
	 characters (tag pattern 2r10) because SmallIntegers have tag patterns 2r11
	 and 2r01, so anding with 1 reduces these to 0 & 1.  We solve the ambiguity by
	 patching send sites with a 0 cache tag to open PICs instead of closed PICs."
	<var: #name type: #'char *'>
	| jumpMNUCase |
	<var: #jumpMNUCase type: #'AbstractInstruction *'>
	self CmpCq: self picAbortDiscriminatorValue R: ClassReg.
	jumpMNUCase := self JumpZero: 0.
	self compileTrampolineFor: #ceInterpretMethodFromPIC:receiver:
		numArgs: 2
		arg: SendNumArgsReg
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: false
		resultReg: NoReg.
	jumpMNUCase jmpTarget: self Label.
	^self genTrampolineFor: #ceMNUFromPICMNUMethod:receiver:
		called: name
		numArgs: 2
		arg: SendNumArgsReg
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: false
		resultReg: NoReg
		appendOpcodes: true
]

{ #category : #'trampoline support' }
Cogit >> genLoadCStackPointersForPrimCall [
	debugPrimCallStackOffset = 0
		ifTrue:
			[self MoveAw: self cStackPointerAddress R: backEnd cStackPointer]
		ifFalse:
			[self MoveAw: self cStackPointerAddress R: TempReg.
			 self SubCq: debugPrimCallStackOffset R: TempReg.
			 self MoveR: TempReg R: backEnd cStackPointer].
	cFramePointerInUse ifTrue:
		[self MoveAw: self cFramePointerAddress R: FPReg].
	^0
]

{ #category : #'in-line cacheing' }
Cogit >> genLoadInlineCacheWithSelector: selectorIndex [
	"The in-line cache for a send is implemented as a constant load into ClassReg.
	 We always use a 32-bit load, even in 64-bits.

	 In the initial (unlinked) state the in-line cache is notionally loaded with the selector.
	 But since in 64-bits an arbitrary selector oop won't fit in a 32-bit constant load, we
	 instead load the cache with the selector's index, either into the literal frame of the
	 current method, or into the special selector array.  Negative values are 1-relative
	 indices into the special selector array.

	 When a send is linked, the load of the selector, or selector index, is overwritten with a
	 load of the receiver's class, or class tag.  Hence, the 64-bit VM is currently constrained
	 to use class indices as cache tags.  If out-of-line literals are used, distinct caches /must
	 not/ share acche locations, for if they do, send cacheing will be confused by the sharing.
	 Hence we use the MoveUniqueC32:R: instruction that will not share literal locations."

	| cacheValue |
	self assert: (selectorIndex < 0
					ifTrue: [selectorIndex negated between: 1 and: self numSpecialSelectors]
					ifFalse: [selectorIndex between: 0 and: (objectMemory literalCountOf: methodObj) - 1]).

	self inlineCacheTagsAreIndexes
		ifTrue:
			[cacheValue := selectorIndex]
		ifFalse:
			[| selector |
			 selector := selectorIndex < 0
							ifTrue: [(coInterpreter specialSelector: -1 - selectorIndex)]
							ifFalse: [self getLiteral: selectorIndex].
			 self assert: (objectMemory addressCouldBeOop: selector).
			 (objectMemory isYoung: selector) ifTrue:
				[hasYoungReferent := true].
			 cacheValue := selector].

	self MovePatcheableC32: cacheValue R: ClassReg
]

{ #category : #initialization }
Cogit >> genMethodAbortTrampoline [
	"Generate the abort for a method.  This abort performs either a call of ceSICMiss:
	 to handle a single-in-line cache miss or a call of ceStackOverflow: to handle a
	 stack overflow.  It distinguishes the two by testing ResultReceiverReg.  If the
	 register is zero then this is a stack-overflow because a) the receiver has already
	 been pushed and so can be set to zero before calling the abort, and b) the
	 receiver must always contain an object (and hence be non-zero) on SIC miss."
	| jumpSICMiss |
	<var: #jumpSICMiss type: #'AbstractInstruction *'>
	self zeroOpcodeIndex.
	self CmpCq: 0 R: ReceiverResultReg.
	jumpSICMiss := self JumpNonZero: 0.

	"The abort sequencer has pushed the LinkReg a second time.
	 Overwrite it with the right one."
	backEnd hasLinkRegister ifTrue:
		[self MoveR: LinkReg Mw: 0 r: SPReg].
	self compileTrampolineFor: #ceStackOverflow:
		numArgs: 1
		arg: SendNumArgsReg
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: false "The LinkReg has already been set above."
		resultReg: NoReg.
	jumpSICMiss jmpTarget: self Label.
	^self genTrampolineFor: #ceSICMiss:
		called: 'ceMethodAbort'
		numArgs: 1
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true "Push the LinkReg for the ceMethodAbort call."
		resultReg: NoReg
		appendOpcodes: true
]

{ #category : #initialization }
Cogit >> genNonLocalReturnTrampoline [
	self zeroOpcodeIndex.
	"write the return address to the coInterpreter instructionPointerAddress;
	 following the CallRT to this CISCs will have pushed it on the stack, so pop it first; RISCs will have it in
	 their link register so just write it directly."
	backEnd hasLinkRegister
		ifTrue:
			[self MoveR: LinkReg Aw: coInterpreter instructionPointerAddress]
		ifFalse:
			[self PopR: TempReg. "instruction pointer"
			 self MoveR: TempReg Aw: coInterpreter instructionPointerAddress].
	^self genTrampolineFor: #ceNonLocalReturn:
		called: 'ceNonLocalReturnTrampoline'
		numArgs: 1
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: false
		resultReg: NoReg
		appendOpcodes: true
]

{ #category : #initialization }
Cogit >> genPICAbortTrampoline [
	"Generate the abort for a PIC.  This abort performs either a call of
	 ceInterpretMethodFromPIC:receiver: to handle invoking an uncogged
	 target or a call of ceMNUFromPICMNUMethod:receiver: to handle an
	 MNU dispatch in a closed PIC.  It distinguishes the two by testing
	 ClassReg.  If the register is zero then this is an MNU."
	self zeroOpcodeIndex.
	backEnd hasLinkRegister ifTrue:
		[self PushR: LinkReg].
	^self genInnerPICAbortTrampoline: 'cePICAbort'
]

{ #category : #initialization }
Cogit >> genReturnTrampolineFor: aRoutine  called: aString arg: regOrConst0 [
	"Generate a trampoline for a routine used as a return address, that has one argument.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 1
		arg: regOrConst0
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: false "Since the routine is reached by a return instruction it should /not/ push the link register."
		resultReg: NoReg
		appendOpcodes: false
]

{ #category : #'trampoline support' }
Cogit >> genSmalltalkToCStackSwitch: pushLinkReg [
	"If the client requires, then on an ARM-like RISC processor, the return address needs to
	 be pushed to the stack so that the interpreter sees the same stack layout as on CISC."
	(backEnd hasLinkRegister and: [pushLinkReg]) ifTrue:
		[self PushR: LinkReg].
	backEnd genSaveStackPointers.
	cFramePointerInUse
		ifTrue: [backEnd genLoadCStackPointers]
		ifFalse: [backEnd genLoadCStackPointer].
	^0
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString [
	"Generate a trampoline with no arguments"
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 0
		arg: nil
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine  called: aString arg: regOrConst0 [
	"Generate a trampoline with one argument.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 1
		arg: regOrConst0
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString arg: regOrConst0 arg: regOrConst1 [
	"Generate a trampoline with two arguments.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 2
		arg: regOrConst0
		arg: regOrConst1
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 [
	"Generate a trampoline with three arguments.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 3
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 [
	"Generate a trampoline with four arguments.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 4
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 result: resultReg [
	"Generate a trampoline with two arguments that answers a result.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 3
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: resultReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString arg: regOrConst0 arg: regOrConst1 regsToSave: regMask [
	"Generate a trampoline with two arguments.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 2
		arg: regOrConst0
		arg: regOrConst1
		arg: nil
		arg: nil
		regsToSave: regMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString arg: regOrConst0 arg: regOrConst1 result: resultReg [
	"Generate a trampoline with two arguments that answers a result.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 2
		arg: regOrConst0
		arg: regOrConst1
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: resultReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString arg: regOrConst0 floatResult: resultReg [
	"Generate a trampoline with one argument that answers a result.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 1
		arg: regOrConst0
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		floatResultReg: resultReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine  called: aString arg: regOrConst0 regsToSave: regMask [
	"Generate a trampoline with one argument.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 1
		arg: regOrConst0
		arg: nil
		arg: nil
		arg: nil
		regsToSave: regMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString arg: regOrConst0 regsToSave: regMask result: resultReg [
	"Generate a trampoline with one argument that answers a result.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 1
		arg: regOrConst0
		arg: nil
		arg: nil
		arg: nil
		regsToSave: regMask
		pushLinkReg: true
		resultReg: resultReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString arg: regOrConst0 result: resultReg [
	"Generate a trampoline with one argument that answers a result.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 1
		arg: regOrConst0
		arg: nil
		arg: nil
		arg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: resultReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString floatArg: regOrConst0 result: resultReg [
	"Generate a trampoline with one argument that answers a result.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 1
		floatArg: regOrConst0
		floatArg: nil
		floatArg: nil
		floatArg: nil
		regsToSave: self emptyRegisterMask
		pushLinkReg: true
		resultReg: resultReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: trampolineName numArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 regsToSave: regMask pushLinkReg: pushLinkReg floatResultReg: resultRegOrNone appendOpcodes: appendBoolean [
	"Generate a trampoline with up to four arguments.  Generate either a call or a jump to aRoutineOrNil
	 as requested by callJumpBar.  If generating a call and resultRegOrNone is not NoReg pass the C result
	 back in resultRegOrNone.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #trampolineName type: #'char *'>
	| startAddress |
	<inline: false>
	startAddress := methodZoneBase.
	appendBoolean ifFalse:
		[self zeroOpcodeIndex].
	self compileTrampolineFor: aRoutine
		numArgs: numArgs
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		regsToSave: regMask
		pushLinkReg: pushLinkReg
		floatResultReg: resultRegOrNone.
	self outputInstructionsForGeneratedRuntimeAt: startAddress.
	self recordGeneratedRunTime: trampolineName address: startAddress.
	self recordRunTimeObjectReferences.
	^startAddress
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: trampolineName numArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 regsToSave: regMask pushLinkReg: pushLinkReg resultReg: resultRegOrNone appendOpcodes: appendBoolean [
	"Generate a trampoline with up to four arguments.  Generate either a call or a jump to aRoutineOrNil
	 as requested by callJumpBar.  If generating a call and resultRegOrNone is not NoReg pass the C result
	 back in resultRegOrNone.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #trampolineName type: #'char *'>
	| startAddress |
	<inline: false>
	startAddress := methodZoneBase.
	appendBoolean ifFalse:
		[self zeroOpcodeIndex].
	self compileTrampolineFor: aRoutine
		numArgs: numArgs
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		regsToSave: regMask
		pushLinkReg: pushLinkReg
		resultReg: resultRegOrNone.
	self outputInstructionsForGeneratedRuntimeAt: startAddress.
	self recordGeneratedRunTime: trampolineName address: startAddress.
	self recordRunTimeObjectReferences.
	^startAddress
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: trampolineName numArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 regsToSave: regMask pushLinkReg: pushLinkReg resultReg: resultRegOrNone resultReg: resultReg2OrNone appendOpcodes: appendBoolean [
	"Generate a trampoline with up to four arguments.  Generate either a call or a jump to aRoutineOrNil
	 as requested by callJumpBar.  If generating a call and resultRegOrNone is not NoReg pass the C result
	 back in resultRegOrNone.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #trampolineName type: #'char *'>
	| startAddress |
	<inline: false>
	startAddress := methodZoneBase.
	appendBoolean ifFalse:
		[self zeroOpcodeIndex].
	self compileTrampolineFor: aRoutine
		numArgs: numArgs
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		regsToSave: regMask
		pushLinkReg: pushLinkReg
		resultReg: resultRegOrNone
		resultReg: resultReg2OrNone.
	self outputInstructionsForGeneratedRuntimeAt: startAddress.
	self recordGeneratedRunTime: trampolineName address: startAddress.
	self recordRunTimeObjectReferences.
	^startAddress
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: aString regsToSave: regMask [
	"Generate a trampoline with no arguments"
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		numArgs: 0
		arg: nil
		arg: nil
		arg: nil
		arg: nil
		regsToSave: regMask
		pushLinkReg: true
		resultReg: NoReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> generateCaptureCStackPointers: captureFramePointer [
	"Generate the routine that writes the current values of the C frame and stack pointers into
	 variables.  These are used to establish the C stack in trampolines back into the C run-time.

	 This is a presumptuous quick hack for x86.  It is presumptuous for two reasons.  Firstly
	 the system's frame and stack pointers may differ from those we use in generated code,
	 e.g. on register-rich RISCs.  Secondly the ABI may not support a simple frameless call
	 as written here (for example 128-bit stack alignment on Mac OS X)."
	| startAddress |
	<inline: false>
	self allocateOpcodes: 32 bytecodes: 0.
	startAddress := methodZoneBase.
	 "Must happen first; value may be used in accessing any of the following addresses"
	
	backEnd genCaptureCStackPointers: captureFramePointer.
	
	self outputInstructionsForGeneratedRuntimeAt: startAddress.
	processor flushICacheFrom: startAddress asUnsignedInteger to: methodZoneBase asUnsignedInteger.
	self recordGeneratedRunTime: 'ceCaptureCStackPointers' address: startAddress.
	ceCaptureCStackPointers := self cCoerceSimple: startAddress to: #'void (*)(void)'
]

{ #category : #initialization }
Cogit >> generateClosedPICPrototype [
	"Generate the prototype ClosedPIC to determine how much space as full PIC takes.
	 When we first allocate a closed PIC it only has one or two cases and we want to grow it.
	 So we have to determine how big a full one is before hand."
	| cPIC endAddress |
	<var: 'cPIC' type: #'CogMethod *'>
	"stack allocate the various collections so that they
	 are effectively garbage collected on return."
	self allocateOpcodes: MaxCPICCases * 9 bytecodes: 0.
	methodLabel address: methodZoneBase; dependent: nil. "for pc-relative MoveCw: cPIC R: ClassReg"
	self compileClosedPICPrototype.
	self computeMaximumSizes.
	cPIC := (self cCoerceSimple: methodZoneBase to: #'CogMethod *').
	closedPICSize := (self sizeof: CogMethod) + (self generateInstructionsAt: methodZoneBase + (self sizeof: CogMethod)).
	endAddress := self outputInstructionsAt: methodZoneBase + (self sizeof: CogMethod).
	self assert: methodZoneBase + closedPICSize = endAddress.
	firstCPICCaseOffset := endCPICCase0 address - methodZoneBase.
	cPICEndOfCodeOffset := cPICEndOfCodeLabel address - methodZoneBase.
	cPICCaseSize := endCPICCase1 address - endCPICCase0 address.
	cPICEndSize := closedPICSize - (MaxCPICCases - 1 * cPICCaseSize + firstCPICCaseOffset).
	closedPICSize := methodZone roundUpLength: closedPICSize.
	self assert: picInterpretAbort address = (methodLabel address + self picInterpretAbortOffset).
	self assert: (self expectedClosedPICPrototype: cPIC) = 0.
	
	"tpr this is a little tiresome but after any assert checking we need to 0 out the case0 objRef rather than leaving 16r5EAF00D lying around"

	backEnd storeLiteral: 0 beforeFollowingAddress: endCPICCase0 address - backEnd jumpLongByteSize.
	
	"update the methodZoneBase so we keep the prototype around for later use"
	methodZoneBase := self alignUptoRoutineBoundary: endAddress.
	cPICPrototype := cPIC.
	"self cCode: ''
		inSmalltalk:
			[self disassembleFrom: cPIC + (self sizeof: CogMethod) to: cPIC + closedPICSize - 1.
			 self halt]"
]

{ #category : #'generate machine code' }
Cogit >> generateCogFullBlock [
	"We handle jump sizing simply.  First we make a pass that asks each
	 instruction to compute its maximum size.  Then we make a pass that
	 sizes jumps based on the maxmimum sizes.  Then we make a pass
	 that fixes up jumps.  When fixing up a jump the jump is not allowed to
	 choose a smaller offset but must stick to the size set in the second pass."
	<returnTypeC: #'CogMethod *'>
	<option: #SistaV1BytecodeSet>
	| codeSize headerSize mapSize totalSize startAddress result method |
	<var: #method type: #'CogMethod *'>
	headerSize := self sizeof: CogMethod.
	methodLabel address: methodZone freeStart.
	self computeMaximumSizes.
	methodLabel concretizeAt: methodZone freeStart.
	codeSize := self generateInstructionsAt: methodLabel address + headerSize.
	mapSize := self generateMapAt: nil start: methodLabel address + cbNoSwitchEntryOffset.
.
	totalSize := methodZone roundUpLength: headerSize + codeSize + mapSize.
	totalSize > MaxMethodSize ifTrue:
		[^self cCoerceSimple: MethodTooBig to: #'CogMethod *'].
	startAddress := methodZone allocate: totalSize.
	startAddress = 0 ifTrue:
		[^self cCoerceSimple: InsufficientCodeSpace to: #'CogMethod *'].
	self assert: startAddress + cbEntryOffset = fullBlockEntry address.
	self assert: startAddress + cbNoSwitchEntryOffset = fullBlockNoContextSwitchEntry address.
	result := self outputInstructionsAt: startAddress + headerSize.
	self assert: startAddress + headerSize + codeSize = result.
	backEnd padIfPossibleWithStopsFrom: result to: startAddress + totalSize - mapSize - 1.
	self generateMapAt: startAddress + totalSize - 1 start: startAddress + cbNoSwitchEntryOffset.
	self flag: #TOCHECK. "It's not clear we want the same header than regular methods. 
	It could be of the same size, but maybe the cmType could be different and the selector could be ignored." 
	method := self fillInMethodHeader: (self cCoerceSimple: startAddress to: #'CogMethod *')
					size: totalSize
					selector: objectMemory nilObject.
	method cpicHasMNUCaseOrCMIsFullBlock: true.
	postCompileHook ifNotNil:
		[self perform: postCompileHook with: method.
		 postCompileHook := nil].
	^method
]

{ #category : #'generate machine code' }
Cogit >> generateCogMethod: selector [
	"We handle jump sizing simply.  First we make a pass that asks each
	 instruction to compute its maximum size.  Then we make a pass that
	 sizes jumps based on the maxmimum sizes.  Then we make a pass
	 that fixes up jumps.  When fixing up a jump the jump is not allowed to
	 choose a smaller offset but must stick to the size set in the second pass."
	<returnTypeC: #'CogMethod *'>
	| codeSize headerSize mapSize totalSize startAddress result method |
	<var: #method type: #'CogMethod *'>
	headerSize := self sizeof: CogMethod.
	methodLabel address: methodZone freeStart.
	self computeMaximumSizes.
	methodLabel concretizeAt: methodZone freeStart.
	codeSize := self generateInstructionsAt: methodLabel address + headerSize.
	mapSize := self generateMapAt: nil start: methodLabel address + cmNoCheckEntryOffset.
	totalSize := methodZone roundUpLength: headerSize + codeSize + mapSize.
	totalSize > MaxMethodSize ifTrue:
		[^self cCoerceSimple: MethodTooBig to: #'CogMethod *'].
	startAddress := methodZone allocate: totalSize.
	startAddress = 0 ifTrue:
		[^self cCoerceSimple: InsufficientCodeSpace to: #'CogMethod *'].
	self assert: startAddress + cmEntryOffset = entry address.
	self assert: startAddress + cmNoCheckEntryOffset = noCheckEntry address.
	result := self outputInstructionsAt: startAddress + headerSize.
	self assert: startAddress + headerSize + codeSize = result.
	backEnd padIfPossibleWithStopsFrom: result to: startAddress + totalSize - mapSize - 1.
	self generateMapAt: startAddress + totalSize - 1 start: startAddress + cmNoCheckEntryOffset.
	self fillInBlockHeadersAt: startAddress.
	method := self fillInMethodHeader: (self cCoerceSimple: startAddress to: #'CogMethod *')
					size: totalSize
					selector: selector.
	postCompileHook ifNotNil:
		[self perform: postCompileHook with: method.
		 postCompileHook := nil].
	^method
]

{ #category : #initialization }
Cogit >> generateEnilopmarts [
	"Enilopmarts transfer control from C into machine code (backwards trampolines)."
	self cppIf: Debug
		ifTrue:
			[realCEEnterCogCodePopReceiverReg :=
				self genEnilopmartFor: ReceiverResultReg
					forCall: false
					called: 'realCEEnterCogCodePopReceiverReg'.
			 ceEnterCogCodePopReceiverReg := #enterCogCodePopReceiver.
			 realCECallCogCodePopReceiverReg :=
				self genEnilopmartFor: ReceiverResultReg
					forCall: true
					called: 'realCEEnterCogCodePopReceiverReg'.
			 ceCallCogCodePopReceiverReg := #callCogCodePopReceiver.
			 realCECallCogCodePopReceiverAndClassRegs :=
				self genEnilopmartFor: ReceiverResultReg
					and: ClassReg
					forCall: true
					called: 'realCECallCogCodePopReceiverAndClassRegs'.
			 ceCallCogCodePopReceiverAndClassRegs := #callCogCodePopReceiverAndClassRegs]
		ifFalse:
			[ceEnterCogCodePopReceiverReg := self genEnilopmartFor: ReceiverResultReg
														forCall: false
														called: 'ceEnterCogCodePopReceiverReg'.
			 ceCallCogCodePopReceiverReg := self genEnilopmartFor: ReceiverResultReg
													forCall: true
													called: 'ceCallCogCodePopReceiverReg'.
			 ceCallCogCodePopReceiverAndClassRegs :=
				self genEnilopmartFor: ReceiverResultReg
					and: ClassReg
					forCall: true
					called: 'ceCallCogCodePopReceiverAndClassRegs'].

	self genPrimReturnEnterCogCodeEnilopmart: false.
	cePrimReturnEnterCogCode := methodZoneBase.
	self outputInstructionsForGeneratedRuntimeAt: cePrimReturnEnterCogCode.
	self recordGeneratedRunTime: 'cePrimReturnEnterCogCode' address: cePrimReturnEnterCogCode.

	self genPrimReturnEnterCogCodeEnilopmart: true.
	cePrimReturnEnterCogCodeProfiling := methodZoneBase.
	self outputInstructionsForGeneratedRuntimeAt: cePrimReturnEnterCogCodeProfiling.
	self recordGeneratedRunTime: 'cePrimReturnEnterCogCodeProfiling' address: cePrimReturnEnterCogCodeProfiling
]

{ #category : #'generate machine code' }
Cogit >> generateInstructionsAt: eventualAbsoluteAddress [
	"Size pc-dependent instructions and assign eventual addresses to all instructions.
	 Answer the size of the code.
	 Compute forward branches based on virtual address (abstract code starts at 0),
	 assuming that any branches branched over are long.
	 Compute backward branches based on actual address.
	 Reuse the fixups array to record the pc-dependent instructions that need to have
	 their code generation postponed until after the others."
	| absoluteAddress pcDependentIndex abstractInstruction fixup |
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<var: #fixup type: #'BytecodeFixup *'>
	absoluteAddress := eventualAbsoluteAddress.
	pcDependentIndex := 0.
	0 to: opcodeIndex - 1 do:
		[:i|
		self maybeBreakGeneratingAt: absoluteAddress.
		abstractInstruction := self abstractInstructionAt: i.
		abstractInstruction isPCDependent
			ifTrue:
				[abstractInstruction sizePCDependentInstructionAt: absoluteAddress.
				 fixup := self fixupAtIndex: pcDependentIndex.
				 pcDependentIndex := pcDependentIndex + 1.
				 fixup instructionIndex: i.
				 absoluteAddress := absoluteAddress + abstractInstruction machineCodeSize]
			ifFalse:
				[absoluteAddress := abstractInstruction concretizeAt: absoluteAddress]].
	0 to: pcDependentIndex - 1 do:
		[:j|
		fixup := self fixupAtIndex: j.
		abstractInstruction := self abstractInstructionAt: fixup instructionIndex.
		self maybeBreakGeneratingAt: abstractInstruction address.
		abstractInstruction concretizeAt: abstractInstruction address].
	^absoluteAddress - eventualAbsoluteAddress
]

{ #category : #'method map' }
Cogit >> generateMapAt: addressOrNull start: startAddress [
	"Generate the method map at addressrNull (or compute it if addressOrNull is null).
	 Answer the length of the map in byes.  Each entry in the map is in two parts.  In the
	 least signficant bits are a displacement of how far from the start or previous entry,
	 unless it is an IsAnnotationExtension byte, in which case those bits are the extension.
	 In the most signficant bits are the type of annotation at the point reached.  A null
	 byte ends the map."
	<var: 'addressOrNull' type: #usqInt>
	<var: 'startAddress' type: #usqInt>
	| length location |
	<var: #instruction type: #'AbstractInstruction *'>
	length := 0.
	location := startAddress.
	0 to: opcodeIndex - 1 do:
		[:i| | instruction mcpc delta maxDelta mapEntry |
		instruction := self abstractInstructionAt: i.
		instruction annotation ifNotNil:
			[:annotation|
			 literalsManager assertValidAnnotation: annotation for: instruction.
			 mcpc := instruction mapEntryAddress.
			 [(delta := mcpc - location / backEnd codeGranularity) > DisplacementMask] whileTrue:
				[maxDelta := (delta min: MaxX2NDisplacement) bitClear: DisplacementMask.
				 self assert: maxDelta >> AnnotationShift <= DisplacementMask.
				 addressOrNull ifNotNil:
					[self addToMap: IsDisplacementX2N
						instruction: instruction
						byte: maxDelta >> AnnotationShift + DisplacementX2N
						at: addressOrNull - length
						for: mcpc].
				 location := location + (maxDelta * backEnd codeGranularity).
				 length := length + 1].
			 addressOrNull ifNotNil:
				[mapEntry := delta + ((annotation min: IsSendCall) << AnnotationShift).
				 self addToMap: annotation instruction: instruction byte: mapEntry at: addressOrNull - length for: mcpc].
			 location := location + (delta * backEnd codeGranularity).
			 length := length + 1.
			 annotation > IsSendCall ifTrue: "Add the necessary IsAnnotationExtension"
				[addressOrNull ifNotNil:
					[mapEntry := IsAnnotationExtension << AnnotationShift + (annotation - IsSendCall).
					 self addToMap: annotation instruction: instruction byte: mapEntry at: addressOrNull - length for: mcpc].
				 length := length + 1]]].
	addressOrNull ifNotNil:
		[self addToMap: MapEnd instruction: nil byte: MapEnd at: addressOrNull - length for: 0].
	^length + 1
]

{ #category : #initialization }
Cogit >> generateMissAbortTrampolines [
	"Generate the run-time entries for the various method and PIC entry misses and aborts.
	 Read the class-side method trampolines for documentation on the various trampolines"

	self subclassResponsibility
]

{ #category : #initialization }
Cogit >> generateOpenPICPrototype [
	"Generate the prototype ClosedPIC to determine how much space as full PIC takes.
	 When we first allocate a closed PIC it only has one or two cases and we want to grow it.
	 So we have to determine how big a full one is before hand."
	| codeSize mapSize |
	"stack allocate the various collections so that they
	 are effectively garbage collected on return."
	self allocateOpcodes: 100 bytecodes: 0.
	methodLabel
		address: methodZoneBase;
		dependent: nil.
	"Need a real selector here so that the map accomodates the annotations for the selector.
	 Use self numRegArgs to generate the longest possible code sequence due to
	 genPushRegisterArgsForNumArgs:"
	self compileOpenPIC: (coInterpreter specialSelector: 0) numArgs: self numRegArgs.
	self computeMaximumSizes.
	methodLabel concretizeAt: methodZoneBase.
	codeSize := self generateInstructionsAt: methodZoneBase + (self sizeof: CogMethod).
	mapSize := self generateMapAt: nil start: methodZoneBase + cmNoCheckEntryOffset.
	openPICSize := (methodZone roundUpLength: (self sizeof: CogMethod) + codeSize) + (methodZone roundUpLength: mapSize).
	"self cCode: ''
		inSmalltalk:
			[| end |
			 end := self outputInstructionsAt: methodZoneBase + headerSize.
			 self disassembleFrom: methodZoneBase + (self sizeof: CogMethod) to: end - 1.
			 self halt]"
]

{ #category : #initialization }
Cogit >> generateRunTimeTrampolines [
	"Generate the run-time entries at the base of the native code zone and update the base."
	
	ceSendMustBeBooleanAddFalseTrampoline := self genMustBeBooleanTrampolineFor: objectMemory falseObject
														called: 'ceSendMustBeBooleanAddFalseTrampoline'.
	ceSendMustBeBooleanAddTrueTrampoline := self genMustBeBooleanTrampolineFor: objectMemory trueObject
														called: 'ceSendMustBeBooleanAddTrueTrampoline'.
	ceNonLocalReturnTrampoline := self genNonLocalReturnTrampoline.
	ceCheckForInterruptTrampoline := self genCheckForInterruptsTrampoline.
	"Neither of the context inst var access trampolines save registers.  Their operation could cause
	 arbitrary update of stack frames, so the assumption is that callers flush the stack before calling
	 the context inst var access trampolines, and that everything except the result is dead afterwards."
	ceFetchContextInstVarTrampoline := self genTrampolineFor: #ceContext:instVar:
											called: 'ceFetchContextInstVarTrampoline'
											arg: ReceiverResultReg
											arg: SendNumArgsReg
											result: SendNumArgsReg.
	ceStoreContextInstVarTrampoline := self genTrampolineFor: #ceContext:instVar:value:
											called: 'ceStoreContextInstVarTrampoline'
											arg: ReceiverResultReg
											arg: SendNumArgsReg
											arg: ClassReg
											result: ReceiverResultReg. "to keep ReceiverResultReg live.".
	ceCannotResumeTrampoline := self genTrampolineFor: #ceCannotResume
											called: 'ceCannotResumeTrampoline'.
	"These two are unusual; they are reached by return instructions."
	ceBaseFrameReturnTrampoline := self genReturnTrampolineFor: #ceBaseFrameReturn:
											called: 'ceBaseFrameReturnTrampoline'
											arg: ReceiverResultReg.
	ceReturnToInterpreterTrampoline := self
											genReturnTrampolineFor: #ceReturnToInterpreter:
											called: 'ceReturnToInterpreterTrampoline'
											arg: ReceiverResultReg.
	ceMallocTrampoline := self genTrampolineFor: #ceMalloc:
											called: 'ceMallocTrampoline'
											arg: ReceiverResultReg
											result: TempReg.
	ceFreeTrampoline := self genTrampolineFor: #ceFree:
											called: 'ceFreeTrampoline'
											arg: ReceiverResultReg.
]

{ #category : #initialization }
Cogit >> generateSendTrampolines [
	0 to: NumSendTrampolines - 1 do:
		[:numArgs|
		ordinarySendTrampolines
			at: numArgs
			put: (self genTrampolineFor: #ceSend:super:to:numArgs:
					  called: (self trampolineName: 'ceSend' numArgs: numArgs)
					  arg: ClassReg
					  arg: (self trampolineArgConstant: false)
					  arg: ReceiverResultReg
					  arg: (self numArgsOrSendNumArgsReg: numArgs))].

	"Generate these in the middle so they are within [firstSend, lastSend]."
	BytecodeSetHasDirectedSuperSend ifTrue:
		[0 to: NumSendTrampolines - 1 do:
			[:numArgs|
			directedSuperSendTrampolines
				at: numArgs
				put: (self genTrampolineFor: #ceSend:above:to:numArgs:
						  called: (self trampolineName: 'ceDirectedSuperSend' numArgs: numArgs)
						  arg: ClassReg
						  arg: TempReg
						  arg: ReceiverResultReg
						  arg: (self numArgsOrSendNumArgsReg: numArgs)).
			directedSuperBindingSendTrampolines
				at: numArgs
				put: (self genTrampolineFor: #ceSend:aboveClassBinding:to:numArgs:
						  called: (self trampolineName: 'ceDirectedSuperBindingSend' numArgs: numArgs)
						  arg: ClassReg
						  arg: TempReg
						  arg: ReceiverResultReg
						  arg: (self numArgsOrSendNumArgsReg: numArgs))]].

	0 to: NumSendTrampolines - 1 do:
		[:numArgs|
		superSendTrampolines
			at: numArgs
			put: (self genTrampolineFor: #ceSend:super:to:numArgs:
					  called: (self trampolineName: 'ceSuperSend' numArgs: numArgs)
					  arg: ClassReg
					  arg: (self trampolineArgConstant: true)
					  arg: ReceiverResultReg
					  arg: (self numArgsOrSendNumArgsReg: numArgs))].
	firstSend := ordinarySendTrampolines at: 0.
	lastSend := superSendTrampolines at: NumSendTrampolines - 1
]

{ #category : #initialization }
Cogit >> generateStackPointerCapture [
	"Generate a routine ceCaptureCStackPointers that will capture the C stack pointer,
	 and, if it is in use, the C frame pointer.  These are used in trampolines to call
	 run-time routines in the interpreter from machine-code."

	| oldMethodZoneBase oldTrampolineTableIndex |
	cFramePointerInUse := false. "For the benefit of the following assert, assume the minimum at first."
	self assertCStackWellAligned.
	oldMethodZoneBase := methodZoneBase.
	oldTrampolineTableIndex := trampolineTableIndex.
	self generateCaptureCStackPointers: true.
	self ceCaptureCStackPointers.
	(cFramePointerInUse := self checkCFramePointerInUse) ifFalse:
		[methodZoneBase := oldMethodZoneBase.
		 trampolineTableIndex := oldTrampolineTableIndex.
		 self generateCaptureCStackPointers: false].
	self assertCStackWellAligned.
]

{ #category : #initialization }
Cogit >> generateTrampolines [
	"Generate the run-time entries and exits at the base of the native code zone and update the base.
	 Read the class-side method trampolines for documentation on the various trampolines"
	| methodZoneStart |
	methodZoneStart := methodZoneBase.
	methodLabel address: methodZoneStart.
	self allocateOpcodes: 80 bytecodes: 0.
	hasYoungReferent := false.
	objectRepresentation maybeGenerateSelectorIndexDereferenceRoutine.
	self generateSendTrampolines.
	self generateMissAbortTrampolines.
	objectRepresentation generateObjectRepresentationTrampolines.
	self generateRunTimeTrampolines.
	SistaVM ifTrue: [self generateSistaRuntime].
	self generateEnilopmarts.
	self generateTracingTrampolines.

	"finish up"
	self recordGeneratedRunTime: 'methodZoneBase' address: methodZoneBase.
	processor flushICacheFrom: methodZoneStart asUnsignedInteger to: methodZoneBase asUnsignedInteger
]

{ #category : #initialization }
Cogit >> generateVMOwnerLockFunctions [
	| startAddress |
	self cppIf: COGMTVM
		ifTrue:
			[self allocateOpcodes: 30 bytecodes: 0.
			startAddress := methodZoneBase.
			self zeroOpcodeIndex.
			backEnd generateLowLevelTryLock: coInterpreter vmOwnerLockAddress.
			self outputInstructionsForGeneratedRuntimeAt: startAddress.
			self recordGeneratedRunTime: 'ceTryLockVMOwner' address: startAddress.
			ceTryLockVMOwner := self cCoerceSimple: startAddress to: #'usqIntptr_t (*)(void)'.

			startAddress := methodZoneBase.
			self zeroOpcodeIndex.
			backEnd generateLowLevelUnlock: coInterpreter vmOwnerLockAddress.
			self outputInstructionsForGeneratedRuntimeAt: startAddress.
			self recordGeneratedRunTime: 'ceUnlockVMOwner' address: startAddress.
			ceUnlockVMOwner := self cCoerceSimple: startAddress to: #'void (*)(void)' ]
]

{ #category : #'compile abstract instructions' }
Cogit >> generatorAt: index [
	<cmacro: '(index) (&generatorTable[index])'>
	<returnTypeC: #'BytecodeDescriptor *'>
	^generatorTable at: index
]

{ #category : #'compile abstract instructions' }
Cogit >> generatorForPC: pc [
	<returnTypeC: #'BytecodeDescriptor *'>
	<inline: true>
	^self generatorAt: bytecodeSetOffset + (objectMemory fetchByte: pc ofObject: methodObj)
]

{ #category : #accessing }
Cogit >> generatorTable [
	<doNotGenerate>
	^generatorTable
]

{ #category : #accessing }
Cogit >> getCFramePointer [
	<api>
	<cmacro: '() CFramePointer'>
	"and in the simulator we use..."
	^(backEnd wantsNearAddressFor: #CFramePointer)
		ifTrue: [CFramePointer]
		ifFalse: [(objectMemory longAt: coInterpreter inMemoryCFramePointerAddress) asVoidPointer]
]

{ #category : #accessing }
Cogit >> getCStackPointer [
	<api>
	<cmacro: '() CStackPointer'>
	"and in the simulator we use..."
	^(backEnd wantsNearAddressFor: #CStackPointer)
		ifTrue: [CStackPointer]
		ifFalse: [(objectMemory longAt: coInterpreter inMemoryCStackPointerAddress) asVoidPointer]
]

{ #category : #'method map' }
Cogit >> getIsObjectReference [
	<cmacro>
	^IsObjectReference
]

{ #category : #'compile abstract instructions' }
Cogit >> getLiteral: litIndex [
	maxLitIndex < litIndex ifTrue:
		[maxLitIndex := litIndex].
	^coInterpreter literal: litIndex ofMethod: methodObj
]

{ #category : #accessing }
Cogit >> getOpcodeIndex [
	"Access for the literal manager."
	^opcodeIndex
]

{ #category : #accessing }
Cogit >> getPrimitiveIndex [
	"Access for the object representation primitive generation routines."
	^primitiveIndex
]

{ #category : #'as yet unclassified' }
Cogit >> guardPageSize: anInteger [ 

	<doNotGenerate>
	guardPageSize := anInteger
]

{ #category : #'translation support' }
Cogit >> halt [
	<cmacro: '() warning("halt")'>
	Halt signal
]

{ #category : #'translation support' }
Cogit >> halt: aString [
	<cmacro: '(msg) warning("halt: " msg)'>
	Halt new signal: aString
]

{ #category : #'translation support' }
Cogit >> haltIf: aBlock [

	aBlock ifTrue: [ self halt ]

]

{ #category : #'simulation only' }
Cogit >> handleABICallOrJumpSimulationTrap: aProcessorSimulationTrap evaluable: evaluable [
	<doNotGenerate>

	| addressToReturn |
	self assert: (aProcessorSimulationTrap type = #call or: [ aProcessorSimulationTrap type = #jump]).

	"I am implemented for ARMv5 only"
	addressToReturn := processor hasLinkRegister 
		ifTrue: [ processor linkRegisterValue ] 
		ifFalse: [ 1halt. ].

	processor
		simulateLeafCallOf: aProcessorSimulationTrap address
		nextpc: 16rBADF00D
		memory: coInterpreter memory.

	evaluable valueWithArguments: (processor
										postCallArgumentsNumArgs: evaluable numArgs
										in: coInterpreter memory).

	evaluable numArgs < 4 ifFalse: [ 1 halt  "If we have more parameters than the ones that fit in the registers"].

	processor pc: addressToReturn
]

{ #category : #'simulation only' }
Cogit >> handleCallOrJumpSimulationTrap: aProcessorSimulationTrap [
	<doNotGenerate>
	| evaluable function memory result savedFramePointer savedStackPointer savedArgumentCount rpc |

	evaluable := simulatedTrampolines at: aProcessorSimulationTrap address.

	(evaluable isBlock not and: [self isPrimitiveRunningInSmalltalkStack: evaluable selector]) 
		ifTrue: [ self assertCStackWellAligned ]. 

	function := evaluable isBlock
					ifTrue: ['aBlock; probably some plugin primitive']
					ifFalse:
						[evaluable receiver == backEnd ifTrue:
							[^self handleABICallOrJumpSimulationTrap: aProcessorSimulationTrap evaluable: evaluable].
						 evaluable selector].
	function ~~ #ceBaseFrameReturn: ifTrue:
		[coInterpreter assertValidExternalStackPointers].
	(function beginsWith: 'ceShort') ifTrue:
		[^self perform: function with: aProcessorSimulationTrap].
	
	aProcessorSimulationTrap type == #call
		ifTrue:
			[processor
				simulateCallOf: aProcessorSimulationTrap address
				nextpc: aProcessorSimulationTrap nextpc
				memory: (memory := coInterpreter memory).
			 self recordInstruction: {'(simulated call of '. aProcessorSimulationTrap address. '/'. function. ')'}]
		ifFalse:
			[processor
				simulateJumpCallOf: aProcessorSimulationTrap address
				memory: (memory := coInterpreter memory).
			 self recordInstruction: {'(simulated jump to '. aProcessorSimulationTrap address. '/'. function. ')'}].
	savedFramePointer := coInterpreter framePointer.
	savedStackPointer := coInterpreter stackPointer.
	savedArgumentCount := coInterpreter argumentCount.
	result := ["self halt: evaluable selector."
		   	   ((printRegisters or: [printInstructions]) and: [clickConfirm]) ifTrue:
			 	[(self confirm: 'skip run-time call?') ifFalse:
					[clickConfirm := false. self halt]].
			   evaluable valueWithArguments: (processor
												postCallArgumentsNumArgs: evaluable numArgs
												in: memory)]
				on: ReenterMachineCode
				do: [:ex| ex return: ex returnValue].
			
	coInterpreter assertValidExternalStackPointers.
	"Verify the stack layout assumption compileInterpreterPrimitive: makes, provided we've
	 not called something that has built a frame, such as closure value or evaluate method, or
	 switched frames, such as primitiveSignal, primitiveWait, primitiveResume, primitiveSuspend et al."
	(function beginsWith: 'primitive') ifTrue:
		[coInterpreter checkForLastObjectOverwrite.
		 coInterpreter primFailCode = 0
			ifTrue: [(#(	primitiveClosureValue primitiveClosureValueWithArgs primitiveClosureValueNoContextSwitch
						primitiveFullClosureValue primitiveFullClosureValueWithArgs primitiveFullClosureValueNoContextSwitch
						primitiveSignal primitiveWait primitiveResume primitiveSuspend primitiveYield
						primitiveExecuteMethodArgsArray primitiveExecuteMethod
						primitivePerform primitivePerformWithArgs primitivePerformInSuperclass
						primitiveTerminateTo primitiveStoreStackp primitiveDoPrimitiveWithArgs)
							includes: function) ifFalse:
						["This is a rare case (e.g. in Scorch where a married context's sender is set to nil on trapTrpped and hence the stack layout is altered."
						 (function == #primitiveSlotAtPut and: [objectMemory isContext: (coInterpreter frameReceiver: coInterpreter framePointer)]) ifFalse:
							[self assert: savedFramePointer = coInterpreter framePointer.
							 self assert: savedStackPointer + (savedArgumentCount * objectMemory wordSize)
									= coInterpreter stackPointer]]]
			ifFalse:
				[self assert: savedFramePointer = coInterpreter framePointer.
				 self assert: savedStackPointer = coInterpreter stackPointer]].
	result ~~ #continueNoReturn ifTrue:
		[self recordInstruction: {'(simulated return to '. processor retpcIn: memory. ')'}.
		 rpc := processor retpcIn: memory.
		 self assert: (rpc >= codeBase and: [rpc < methodZone freeStart]).
		 processor
			smashCallerSavedRegistersWithValuesFrom: 16r80000000 by: objectMemory wordSize in: memory;
			simulateReturnIn: memory].
	self assert: (result isInteger "an oop result"
			or: [result == coInterpreter
			or: [result == objectMemory
			or: [#(nil continue continueNoReturn) includes: result]]]).
	processor cResultRegister: (result
							ifNil: [0]
							ifNotNil: [result isInteger
										ifTrue: [result]
										ifFalse: [16rF00BA222]])

	"coInterpreter cr.
	 processor sp + 32 to: processor sp - 32 by: -4 do:
		[:sp|
		 sp = processor sp
			ifTrue: [coInterpreter print: 'sp->'; tab]
			ifFalse: [coInterpreter printHex: sp].
		 coInterpreter tab; printHex: (coInterpreter longAt: sp); cr]"
]

{ #category : #'simulation only' }
Cogit >> handleReadSimulationTrap: aProcessorSimulationTrap [
	<doNotGenerate>
	| variableValue accessor |
	variableValue := (simulatedVariableGetters at: aProcessorSimulationTrap address) value asInteger.
	accessor := aProcessorSimulationTrap registerAccessor.
	processor
		perform: accessor
		with: variableValue signedIntToLong.
	accessor ~~ #pc: ifTrue:
		[processor pc: aProcessorSimulationTrap nextpc]
]

{ #category : #'simulation only' }
Cogit >> handleSimulationTrap: aProcessorSimulationTrap [
	<doNotGenerate>
	aProcessorSimulationTrap type caseOf:
		{ [#read] -> [self handleReadSimulationTrap: aProcessorSimulationTrap].
		  [#write] -> [self handleWriteSimulationTrap: aProcessorSimulationTrap].
		  [#call] -> [self handleCallOrJumpSimulationTrap: aProcessorSimulationTrap].
		  [#jump] -> [self handleCallOrJumpSimulationTrap: aProcessorSimulationTrap] }
]

{ #category : #'simulation only' }
Cogit >> handleWriteSimulationTrap: aProcessorSimulationTrap [ 
	<doNotGenerate>
	| variableValue |
	(self addressIsInCodeZone: aProcessorSimulationTrap address) ifTrue:
		[self error: 'attempt to write to code space'].
	variableValue := aProcessorSimulationTrap writtenValue.
	(simulatedVariableSetters at: aProcessorSimulationTrap address) value: variableValue.

	processor pc: aProcessorSimulationTrap nextpc
]

{ #category : #compaction }
Cogit >> incrementUsageOfTargetIfLinkedSend: annotation mcpc: mcpc ignored: superfluity [
	<var: #mcpc type: #'char *'>
	| entryPoint |

	(self isPureSendAnnotation: annotation) ifTrue:
		[self assert: annotation ~= IsNSSendCall.
		 entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase ifTrue: "It's a linked send."
			[self targetMethodAndSendTableFor: entryPoint annotation: annotation into:
				[:targetMethod :sendTable|
				 targetMethod cmUsageCount < (CMMaxUsageCount // 2) ifTrue:
					[targetMethod cmUsageCount: targetMethod cmUsageCount + 1]]]].

	^0 "keep scanning"
]

{ #category : #'in-line cacheing' }
Cogit >> indexForSelector: selector in: cogMethod at: mcpc [
	"Answer the value to put in an inline-cache that is being loaded with the selector.
	 Usually this is simply the selector, but in 64-bits the cache is only 32-bits wide
	 and so the cache is loaded with the index of the selector."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: false>
	| methodOop |
	self assert: (mcpc asUnsignedInteger > cogMethod asUnsignedInteger
				and: [mcpc < (cogMethod asUnsignedInteger + cogMethod blockSize)]).
	"First search the special selectors; there are only 32 of them so this shouldn't take too long.
	 We could short-circuit this by keeping a hint bit in the target method, or by maintaining the
	 maximum range of selector oops in specialSelectors since they're likely to cluster."
	0 to: NumSpecialSelectors - 1 do:
		[:i|
		selector = (coInterpreter specialSelector: i) ifTrue:
			[^-1 - i]].
	methodOop := cogMethod methodObject.
	"Then search the method's literal frame... open code fetchPointer:ofObject: for speed..."
	LiteralStart to: (objectMemory literalCountOfMethodHeader: cogMethod methodHeader) do:
		[:i|
		(objectMemory longAt: i * objectMemory bytesPerOop + objectMemory baseHeaderSize + methodOop) = selector ifTrue:
			[self assert: selector = (coInterpreter literal: i - 1 ofMethod: methodOop).
			 ^i - 1]].

	self error: 'could not find selector in method when unlinking send site'.
	^0
]

{ #category : #'generate machine code' }
Cogit >> initialClosedPICUsageCount [
	"Answer a usage count that reflects likely long-term usage."
	^CMMaxUsageCount // 2
]

{ #category : #'generate machine code' }
Cogit >> initialMethodUsageCount [
	"Answer a usage count that reflects likely long-term usage.
	 Answer 1 for non-primitives or quick primitives (inst var accessors),
	 2 for methods with interpreter primitives, and 3 for compiled primitives."
	(primitiveIndex = 1
	 or: [coInterpreter isQuickPrimitiveIndex: primitiveIndex]) ifTrue:
		[^1].
	self primitiveGeneratorOrNil ifNil:
		[^2].
	^3
]

{ #category : #'generate machine code' }
Cogit >> initialOpenPICUsageCount [
	"Answer a usage count that reflects likely long-term usage."
	^CMMaxUsageCount - 1
]

{ #category : #initialization }
Cogit >> initialize [
	| wordSize |
	initialPC := 0.
	simulateFPInUse := true.
	wordSize := self class objectMemoryClass wordSize.
	cogMethodSurrogateClass := wordSize = 4
											ifTrue: [CogMethodSurrogate32]
											ifFalse: [CogMethodSurrogate64].
	cogBlockMethodSurrogateClass := wordSize = 4
											ifTrue: [CogBlockMethodSurrogate32]
											ifFalse: [CogBlockMethodSurrogate64].
]

{ #category : #initialization }
Cogit >> initializeBackend [
	methodLabel machineCodeSize: 0.
	methodLabel opcode: Label.
	methodLabel operands at: 0 put: 0.
	methodLabel operands at: 1 put: 0. "label offset"
	backEnd hasVarBaseRegister ifTrue:
		[self assert: ((self registerMaskFor: VarBaseReg) noMask: CallerSavedRegisterMask)].
	literalsManager allocateLiterals: 4; resetLiterals
]

{ #category : #initialization }
Cogit >> initializeCodeZoneFrom: startAddress upTo: endAddress [
	<api>
	self initializeBackend.
	backEnd stopsFrom: startAddress to: endAddress - 1.
	self cCode: [self sqMakeMemoryExecutableFrom: startAddress To: endAddress]
		inSmalltalk:
			[startAddress = self class guardPageSize ifTrue:
				[backEnd stopsFrom: 0 to: endAddress - 1].
			 self initializeProcessor].
	codeBase := methodZoneBase := startAddress.
	minValidCallAddress := (codeBase min: coInterpreter interpretAddress)
								min: coInterpreter primitiveFailAddress.
	methodZone manageFrom: methodZoneBase to: endAddress.
	self maybeGenerateCheckFeatures.
	self maybeGenerateICacheFlush.
	self generateVMOwnerLockFunctions.
	self genGetLeafCallStackPointer.
	self generateStackPointerCapture.
	self generateTrampolines.
	self computeEntryOffsets.
	self computeFullBlockEntryOffsets.
	self generateClosedPICPrototype.
	"repeat so that now the methodZone ignores the generated run-time"
	methodZone manageFrom: methodZoneBase to: endAddress.
	"N.B. this is assumed to be the last thing done in initialization; see Cogit>>initialized"
	self generateOpenPICPrototype
]

{ #category : #'compile abstract instructions' }
Cogit >> initializeFixupAt: targetPC [
	"Make sure there's a flagged fixup at the targetPC in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	<returnTypeC: #'BytecodeFixup *'>
	<inline: true>
	(self fixupAt: targetPC) becomeFixup
]

{ #category : #initialization }
Cogit >> initializeProcessor [
	"Initialize the simulation processor, arranging that its initial stack is somewhere on the rump C stack."
	<doNotGenerate>
	guardPageSize := self class guardPageSize.
	lastNInstructions := OrderedCollection new.
	processor initializeStackFor: self.
	self initializeProcessorStack: coInterpreter rumpCStackAddress.
	self setCFramePointer: processor fp.
	self setCStackPointer: processor sp.
	threadManager ifNotNil:
		[processor := MultiProcessor for: processor coInterpreter: coInterpreter]
]

{ #category : #initialization }
Cogit >> initializeProcessorStack: rumpCStackAddress [
	"Initialize the simulation processor's stack pointers, arranging that they are somewhere on the rump C stack."
	<doNotGenerate>
	| stackPad cFramePointer cStackPointer |
	stackPad := 64 max: cStackAlignment.
	cStackPointer := rumpCStackAddress - stackPad + expectedSPAlignment.
	cFramePointer := rumpCStackAddress - stackPad + cStackAlignment + expectedFPAlignment.
	self assert: cStackPointer \\ cStackAlignment = expectedSPAlignment.
	self assert: cFramePointer \\ cStackAlignment = expectedFPAlignment.
	processor setFramePointer: cFramePointer stackPointer: cStackPointer
]

{ #category : #testing }
Cogit >> initialized [
	<doNotGenerate>
	^openPICSize isInteger
]

{ #category : #'in-line cacheing' }
Cogit >> inlineCacheTagsAreIndexes [
	"The Cogit always generates 32-bit inline caches.  This implies that in 64-bits there is no room
	 in an unlinked inline cache for a selector oop.  Instead it contains a signed 32-bit index, positive
	 for selectors in a method's literal frame and negative for selectors in the specialSelectorsOop.
	 And it implies that linked inline cache entries contain class indices, not class oops."
	<inline: true>
	^objectMemory wordSize = 8
]

{ #category : #'in-line cacheing' }
Cogit >> inlineCacheValueForSelector: selector in: aCogMethod at: mcpc [
	"Answer the value to put in an inline-cache that is being loaded with the selector.
	 Usually this is simply the selector, but in 64-bits the cache is only 32-bits wide
	 and so the cache is loaded with the index of the selector."
	<var: #aCogMethod type: #'CogMethod *'>
	<inline: true>
	^self inlineCacheTagsAreIndexes
		ifTrue: [self indexForSelector: selector in: aCogMethod at: mcpc]
		ifFalse: [selector]
]

{ #category : #'tests-method map' }
Cogit >> innermostSubMethodFor: bcpc in: subMethods startingAt: index [
	<doNotGenerate>
	| subMethod |
	^index <= subMethods size ifTrue:
		[subMethod := subMethods at: index.
		 (bcpc between: subMethod startpc and: subMethod endPC)
			ifTrue:
				[(self innermostSubMethodFor: bcpc in: subMethods startingAt: index + 1)
					ifNil: [subMethod]
					ifNotNil: [:innerSubMethod| innerSubMethod]]
			ifFalse:
				[self innermostSubMethodFor: bcpc in: subMethods startingAt: index + 1]]
]

{ #category : #'in-line cacheing' }
Cogit >> interpretOffset [
	<api>
	<cmacro: '() missOffset'>
	^missOffset
]

{ #category : #'compile abstract instructions' }
Cogit >> inverseBranchFor: opcode [
	opcode caseOf: {
		[JumpLongZero]		->	[^JumpLongNonZero].
		[JumpLongNonZero]	->	[^JumpLongZero].
		[JumpZero]				->	[^JumpNonZero].
		[JumpNonZero]			->	[^JumpZero].
		[JumpNegative]			->	[^JumpNonNegative].
		[JumpNonNegative]		->	[^JumpNegative].
		[JumpOverflow]			->	[^JumpNoOverflow].
		[JumpNoOverflow]		->	[^JumpOverflow].
		[JumpCarry]			->	[^JumpNoCarry].
		[JumpNoCarry]			->	[^JumpCarry].
		[JumpLess]				->	[^JumpGreaterOrEqual].
		[JumpGreaterOrEqual]	->	[^JumpLess].
		[JumpGreater]			->	[^JumpLessOrEqual].
		[JumpLessOrEqual]		->	[^JumpGreater].
		[JumpBelow]			->	[^JumpAboveOrEqual].
		[JumpAboveOrEqual]	->	[^JumpBelow].
		[JumpAbove]			->	[^JumpBelowOrEqual].
		[JumpBelowOrEqual]	->	[^JumpAbove] }.
	self error: 'invalid opcode for inverse'.
	^0
]

{ #category : #'simulation only' }
Cogit >> isAbsentReceiverSendAt: mcpc in: cogHomeMethod [
	| prev this |
	self mapFor: cogHomeMethod
		do: [:a :m|
			m < mcpc
				ifTrue: [prev := a]
				ifFalse: [m = mcpc ifTrue: [this := a]].
			false].
	^this = IsSendCall and: [prev = IsNSSendCall]
]

{ #category : #'compile abstract instructions' }
Cogit >> isBackwardBranch: descriptor at: pc exts: nExts in: aMethodObj [
	"Answer if the branch bytecode with the given descriptor is a backward branch."
	<inline: true>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	self assert: descriptor spanFunction notNil.
	^(self
		perform: descriptor spanFunction
		with: descriptor
		with: pc
		with: nExts
		with: aMethodObj) < 0
]

{ #category : #initialization }
Cogit >> isCFramePointerInUse [
	<doNotGenerate>
	^ cFramePointerInUse
]

{ #category : #'bytecode generator support' }
Cogit >> isDirectedSuper: descriptor extA: exta extB: extb [
	"235	(1)	11101011	iiiiijjj	ExtendB < 64
										ifTrue: [Send To Superclass
													Literal Selector #iiiii (+ Extend A * 32)
													with jjj (+ Extend B * 8) Arguments]
										ifFalse: [Send To Superclass of Stacked Class
													Literal Selector #iiiii (+ Extend A * 32)
													with jjj (+ (Extend B bitAnd: 63) * 8) Arguments]"
	<inline: true>
	^descriptor notNil
	  and: [descriptor generator == #genExtSendSuperBytecode
	  and: [extb >= 64]]
]

{ #category : #'jit - api' }
Cogit >> isNonLocalReturnPC: retpc [
	<doNotGenerate>
	"Answer if the instruction preceding retpc is a call instruction."
	^(backEnd isCallPrecedingReturnPC: retpc)
	 and: [(backEnd callTargetFromReturnAddress: retpc) = ceNonLocalReturnTrampoline]
]

{ #category : #'method map' }
Cogit >> isPCMappedAnnotation: annotation [
	"See Cogit class>>initializeAnnotationConstants"
	<inline: true>
	^annotation >= HasBytecodePC
]

{ #category : #disassembly }
Cogit >> isPCWithinMethodZone: address [
	<api>
	<var: #address type: #'void *'>
	^address asUnsignedInteger
		between: methodZoneBase
		and: methodZone freeStart
]

{ #category : #testing }
Cogit >> isPrimitiveRunningInSmalltalkStack: aSelector [

	^ aSelector = #mcprimHashMultiply:

]

{ #category : #'method map' }
Cogit >> isPureSendAnnotation: annotation [
	<inline: true>
	^annotation >= IsSendCall
]

{ #category : #'method map' }
Cogit >> isSendAnnotation: annotation [
	<inline: true>
	^annotation >= IsSendCall
]

{ #category : #'jit - api' }
Cogit >> isSendReturnPC: retpc [
	<api>
	"Answer if the instruction preceding retpc is a call instruction."
	| target |
	(backEnd isCallPrecedingReturnPC: retpc) ifFalse:
		[^false].
	target := backEnd callTargetFromReturnAddress: retpc.
	^(target between: firstSend and: lastSend)
	   or: [target between: methodZoneBase and: methodZone freeStart]
]

{ #category : #initialization }
Cogit >> isTrampolineArgConstant: n [
	"Test for true and false and 0 to N encoded via trampolineArgConstant:"
	<inline: true>
	^n < NoReg
]

{ #category : #disassembly }
Cogit >> labelForPC: address [
	<doNotGenerate>
	^address < methodZoneBase ifTrue:
		[self lookupAddress: address]
]

{ #category : #'simulation only' }
Cogit >> labelForSimulationAccessor: blockOrMessageSendOrSelector [
	<doNotGenerate>
	^'&', (blockOrMessageSendOrSelector isBlock
			ifTrue: ['block in ', blockOrMessageSendOrSelector method selector]
			ifFalse: [blockOrMessageSendOrSelector isMessageSend
						ifTrue: [blockOrMessageSendOrSelector selector]
						ifFalse: [blockOrMessageSendOrSelector]])
]

{ #category : #'method map' }
Cogit >> lastBytecodePCForBlockAt: startbcpc in: aMethodObj [
	"Answer the 0-relative pc of the last bytecode in the block starting at the 0-relative startbcpc in aMethodObj."
	| aMethodHeader bcpc bsOffset byte descriptor |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	aMethodHeader := objectMemory methodHeaderOf: aMethodObj.
	bcpc := startbcpc - (self blockCreationBytecodeSizeForHeader: aMethodHeader).
	bsOffset := self bytecodeSetOffsetForHeader: aMethodHeader.
	byte := (objectMemory fetchByte: bcpc ofObject: aMethodObj) + bsOffset.
	descriptor := self generatorAt: byte.
	^(self nextBytecodePCFor: descriptor at: bcpc exts: -1 in: aMethodObj) - 1
]

{ #category : #'as yet unclassified' }
Cogit >> lastNInstructions: aCollection [ 
	<doNotGenerate>
	lastNInstructions := aCollection
]

{ #category : #'compile abstract instructions' }
Cogit >> lastOpcode [
	<returnTypeC: #'AbstractInstruction *'>
	self assert: opcodeIndex > 0.
	^self abstractInstructionAt: opcodeIndex - 1
]

{ #category : #'compile abstract instructions' }
Cogit >> latestContinuationPCFor: descriptor at: pc exts: nExts in: aMethodObj [
	"Assuming the descriptor is that for a branch or block,
	 answer the furthest reachable pc for this bytecode."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	| distance |
	distance := self spanFor: descriptor at: pc exts: nExts in: aMethodObj.
	^pc + descriptor numBytes + (distance max: 0)
]

{ #category : #'in-line cacheing' }
Cogit >> linkSendAt: callSiteReturnAddress in: sendingMethod to: targetMethod offset: theEntryOffset receiver: receiver [
	<api>
	<var: #sendingMethod type: #'CogMethod *'>
	<var: #targetMethod type: #'CogMethod *'>
	| inlineCacheTag address extent |
	self assert: (theEntryOffset = cmEntryOffset or: [theEntryOffset = cmNoCheckEntryOffset]).
	self assert: (callSiteReturnAddress between: methodZoneBase and: methodZone freeStart).
	inlineCacheTag := theEntryOffset = cmNoCheckEntryOffset
						ifTrue: [targetMethod selector "i.e. no change"]
						ifFalse: [objectRepresentation inlineCacheTagForInstance: receiver].
	(objectRepresentation inlineCacheTagIsYoung: inlineCacheTag) ifTrue:
		[methodZone ensureInYoungReferrers: sendingMethod].
	address := targetMethod asInteger + theEntryOffset.
	extent := backEnd
				rewriteInlineCacheAt: callSiteReturnAddress
				tag: inlineCacheTag
				target: address.
	processor
		flushICacheFrom: callSiteReturnAddress asUnsignedInteger  - extent
		to: callSiteReturnAddress asUnsignedInteger 
]

{ #category : #analysis }
Cogit >> linkedSuperSendCacheTags [
	"An example; answer the cache tags for linked super sends.  They should all be
	 selectors because super sends don't have their cache tag rewritten when linked."
	<doNotGenerate>
	| cacheTags |
	cacheTags := Set new.
	methodZone methodsDo:
		[:m|
		 m cmType = CMMethod ifTrue:
			[self sendSitesIn: m do:
				[:a :mcpc| | entryPoint |
				 entryPoint := backEnd callTargetFromReturnAddress: mcpc.
				 entryPoint > methodZoneBase ifTrue:
					[self offsetAndSendTableFor: entryPoint
						annotation: a
						into:
							[:off :table|
							 off = cmNoCheckEntryOffset ifTrue:
								[cacheTags add: (backEnd inlineCacheTagAt: mcpc)]]]]]].
	^cacheTags
]

{ #category : #'compile abstract instructions' }
Cogit >> loadBytesAndGetDescriptor [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	| descriptor |
	byte0 := (objectMemory fetchByte: bytecodePC ofObject: methodObj)  + bytecodeSetOffset.
	descriptor := self generatorAt: byte0.
	self loadSubsequentBytesForDescriptor: descriptor at: bytecodePC.
	^ descriptor
	
	
]

{ #category : #'compile abstract instructions' }
Cogit >> loadSubsequentBytesForDescriptor: descriptor at: pc [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	descriptor numBytes > 1 ifTrue:
		[byte1 := objectMemory fetchByte: pc + 1 ofObject: methodObj.
		 descriptor numBytes > 2 ifTrue:
			[byte2 := objectMemory fetchByte: pc + 2 ofObject: methodObj.
			 descriptor numBytes > 3 ifTrue:
				[byte3 := objectMemory fetchByte: pc + 3 ofObject: methodObj.
				 descriptor numBytes > 4 ifTrue:
					[self notYetImplemented]]]]
]

{ #category : #'in-line cacheing' }
Cogit >> lookup: selector for: receiver methodAndErrorSelectorInto: binaryBlock [
	"Lookup selector in the class of receiver.  If found, evaluate binaryBlock with the
	 method, cogged if appropriate..  If not found, due to MNU, lookup the DNU selector
	 and evaluate binaryBlock with the MNU method, cogged if appropriate..  If not found
	 due to cannot interpret, evaluate binaryBlock with a nil method and the error selector."
	| methodOrSelectorIndex |
	<inline: true>
	methodOrSelectorIndex := coInterpreter
									lookupOrdinary: selector
									receiver: receiver.
	methodOrSelectorIndex asUnsignedInteger > coInterpreter maxLookupNoMNUErrorCode ifTrue:
		[(objectMemory isOopCompiledMethod: methodOrSelectorIndex) ifFalse:
			[^binaryBlock value: methodOrSelectorIndex value: SelectorCannotInterpret].
		 ((coInterpreter methodHasCogMethod: methodOrSelectorIndex) not
		  and: [coInterpreter methodShouldBeCogged: methodOrSelectorIndex]) ifTrue:
			["We assume cog:selector: will *not* reclaim the method zone"
			 self cog: methodOrSelectorIndex selector: selector].
		^binaryBlock value: methodOrSelectorIndex value: nil].
	methodOrSelectorIndex = SelectorDoesNotUnderstand ifTrue:
		[methodOrSelectorIndex := coInterpreter
										lookupMNU: (objectMemory splObj: SelectorDoesNotUnderstand)
										receiver: receiver.
		 methodOrSelectorIndex asUnsignedInteger > coInterpreter maxLookupNoMNUErrorCode ifTrue:
			[self assert: (objectMemory isOopCompiledMethod: methodOrSelectorIndex).
			 ((coInterpreter methodHasCogMethod: methodOrSelectorIndex) not
			  and: [coInterpreter methodShouldBeCogged: methodOrSelectorIndex]) ifTrue:
				["We assume cog:selector: will *not* reclaim the method zone"
				 self cog: methodOrSelectorIndex selector: (objectMemory splObj: SelectorDoesNotUnderstand)].
			^binaryBlock value: methodOrSelectorIndex value: SelectorDoesNotUnderstand].
		^binaryBlock value: nil value: SelectorDoesNotUnderstand].
	^binaryBlock value: nil value: methodOrSelectorIndex
]

{ #category : #disassembly }
Cogit >> lookupAddress: address [
	<doNotGenerate>
	| cogMethod |
	address < methodZone freeStart ifTrue:
		[address >= methodZoneBase
			ifTrue:
				[(cogMethod := methodZone methodFor: address) ~= 0 ifTrue:
					[cogMethod := self cCoerceSimple: cogMethod to: #'CogMethod *'.
					 ^((cogMethod selector ~= objectMemory nilObject
					    and: [objectRepresentation couldBeObject: cogMethod selector])
						ifTrue: [coInterpreter stringOf: cogMethod selector]
						ifFalse: [cogMethod asInteger hex]),
					   '@', ((address - cogMethod asInteger) hex allButFirst: 3)]]
			ifFalse:
				[^address = (self codeEntryFor: address) ifTrue:
					[self codeEntryNameFor: address]].
		 ^nil].
	(simulatedTrampolines includesKey: address) ifTrue:
		[^self labelForSimulationAccessor: (simulatedTrampolines at: address)].
	(simulatedVariableGetters includesKey: address) ifTrue:
		[^self labelForSimulationAccessor: (simulatedVariableGetters at: address)].
	^coInterpreter lookupAddress: address
]

{ #category : #disassembly }
Cogit >> lookupCHexString: aCHexString [ 
	<doNotGenerate>
	| pastLastZero shortened address |
	(aCHexString beginsWith: '0x') ifFalse:
		[^aCHexString].
	pastLastZero := aCHexString findFirst: [:c| c ~= $0 and: [c ~= $x]].
	shortened := pastLastZero = 0
					ifTrue: ['0x0']
					ifFalse:
						[(aCHexString size >= 16 and: [pastLastZero >= 4])
							ifTrue: [aCHexString copyReplaceFrom: 3 to: pastLastZero - 1 with: '']
							ifFalse: [aCHexString]].
	address := Number readFrom: (ReadStream on: shortened from: 3 to: shortened size) base: 16.
	(disassemblingMethod notNil
	 and: [address > disassemblingMethod
	 and: [address < (disassemblingMethod asInteger + disassemblingMethod blockSize)]]) ifTrue:
		[shortened := '.+', (address - disassemblingMethod asInteger printStringBase: 16 length: 4 padded: true)].
	^(self lookupAddress: (Number
								readFrom: (ReadStream on: shortened from: 3 to: shortened size)
								base: 16))
		ifNotNil: [:string| shortened, '=', string]
		ifNil: [shortened]
]

{ #category : #disassembly }
Cogit >> lookupFrameOffset: anInteger [
	<doNotGenerate>
	(self class initializationOptions at: #tempNames ifAbsent: nil) ifNotNil:
		[:dict|
		 (self class initializationOptions at: #startpc ifAbsent: nil) ifNotNil:
			[:startpc|
			 (dict at: startpc + 1 ifAbsent: nil) ifNotNil:
				[:tempNames| | numArgs |
				 anInteger = FoxMFReceiver ifTrue:
					[^'self'].
				numArgs := self class initializationOptions at: #numArgs.
				1 to: tempNames size do:
					[:i|
					anInteger = (self frameOffsetOfTemporary: i - 1 numArgs: numArgs) ifTrue:
						[^tempNames at: i]]]]].
	^nil
]

{ #category : #disassembly }
Cogit >> lookupInstVarOffset: offset [
	^offset \\ objectMemory bytesPerOop = 0 ifTrue:
		[(self class initializationOptions at: #instVarNames ifAbsent: nil) ifNotNil:
			[:array|
			 array
				at: offset - objectMemory baseHeaderSize / objectMemory bytesPerOop + 1
				ifAbsent: nil]]
]

{ #category : #'method map' }
Cogit >> mapEndFor: cogMethod [
	"Answer the address of the null byte at the end of the method map."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	| end |
	end := self mapStartFor: cogMethod.
	[(objectMemory byteAt: end) ~= MapEnd] whileTrue:
		[end := end - 1.
		 self assert: end > (self firstMappedPCFor: cogMethod)].
	^end
]

{ #category : #'method map' }
Cogit >> mapFor: cogMethod bcpc: startbcpc performUntil: functionSymbol arg: arg [
	"Machine-code <-> bytecode pc mapping support.  Evaluate functionSymbol
	 for each mcpc, bcpc pair in the map until the function returns non-zero,
	 answering that result, or 0 if it fails to.  To cut down on number of arguments.
	 and to be usable for both pc-mapping and method introspection, we encode
	 the annotation and the isBackwardBranch flag in the same parameter.
	 Guilty as charged."
	<var: #cogMethod type: #'CogBlockMethod *'>
	<var: #functionSymbol declareC: 'sqInt (*functionSymbol)(BytecodeDescriptor *desc, sqInt annotationAndIsBackwardBranch, char *mcpc, sqInt bcpc, void *arg)'>
	<var: #arg type: #'void *'>
	<inline: true>
	| isInBlock mcpc bcpc endbcpc map mapByte homeMethod aMethodObj result
	  latestContinuation byte descriptor bsOffset nExts annotation |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #homeMethod type: #'CogMethod *'>

	self assert: cogMethod stackCheckOffset > 0.
	mcpc := cogMethod asUnsignedInteger + cogMethod stackCheckOffset.
	"The stack check maps to the start of the first bytecode,
	 the first bytecode being effectively after frame build."
	result := self perform: functionSymbol
					with: nil
					with: 0 + (HasBytecodePC << 1)
					with: (self cCoerceSimple: mcpc to: #'char *')
					with: startbcpc
					with: arg.
	result ~= 0 ifTrue:
		[^result].
	bcpc := startbcpc.
	"In both CMMethod and CMBlock cases find the start of the map and
	 skip forward to the bytecode pc map entry for the stack check."
	cogMethod cmType = CMMethod
		ifTrue:
			[isInBlock := cogMethod cmIsFullBlock.
			 homeMethod := self cCoerceSimple: cogMethod to: #'CogMethod *'.
			 self assert: startbcpc = (coInterpreter startPCOfMethodHeader: homeMethod methodHeader).
			 map := self mapStartFor: homeMethod.
			 annotation := (objectMemory byteAt: map) >> AnnotationShift.
			 self assert: (annotation = IsAbsPCReference
						 or: [annotation = IsObjectReference
						 or: [annotation = IsRelativeCall
						 or: [annotation = IsDisplacementX2N]]]).
			 latestContinuation := startbcpc.
			 aMethodObj := homeMethod methodObject.
			 endbcpc := (objectMemory numBytesOf: aMethodObj) - 1.
			 bsOffset := self bytecodeSetOffsetForHeader: homeMethod methodHeader.
			"If the method has a primitive, skip it and the error code store, if any;
			 Logically. these come before the stack check and so must be ignored."
			 bcpc := bcpc + (self deltaToSkipPrimAndErrorStoreIn: aMethodObj
									header: homeMethod methodHeader)]
		ifFalse:
			[isInBlock := true.
			 self assert: bcpc = cogMethod startpc.
			 homeMethod := cogMethod cmHomeMethod.
			 map := self findMapLocationForMcpc: cogMethod asUnsignedInteger + (self sizeof: CogBlockMethod)
						inMethod: homeMethod.
			 self assert: map ~= 0.
			 annotation := (objectMemory byteAt: map) >> AnnotationShift.
			 self assert: (annotation >> AnnotationShift = HasBytecodePC "fiducial"
						 or: [annotation >> AnnotationShift = IsDisplacementX2N]).
			 [(annotation := (objectMemory byteAt: map) >> AnnotationShift) ~= HasBytecodePC] whileTrue:
				[map := map - 1].
			 map := map - 1. "skip fiducial; i.e. the map entry for the pc immediately following the method header."
			 aMethodObj := homeMethod methodObject.
			 bcpc := startbcpc - (self blockCreationBytecodeSizeForHeader: homeMethod methodHeader).
			 bsOffset := self bytecodeSetOffsetForHeader: homeMethod methodHeader.
			 byte := (objectMemory fetchByte: bcpc ofObject: aMethodObj) + bsOffset.
			 descriptor := self generatorAt: byte.
			 endbcpc := self nextBytecodePCFor: descriptor at: bcpc exts: -1 in: aMethodObj.
			 bcpc := startbcpc].
	nExts := 0.
	self inlineCacheTagsAreIndexes ifTrue:
		[enumeratingCogMethod := homeMethod].
	"Now skip up through the bytecode pc map entry for the stack check." 
	[(objectMemory byteAt: map) >> AnnotationShift ~= HasBytecodePC] whileTrue:
		[map := map - 1].
	map := map - 1.
	[(mapByte := objectMemory byteAt: map) ~= MapEnd] whileTrue: "defensive; we exit on bcpc"
		[mapByte >= FirstAnnotation
			ifTrue:
				[| nextBcpc isBackwardBranch |
				annotation := mapByte >> AnnotationShift.
				mcpc := mcpc + ((mapByte bitAnd: DisplacementMask) * backEnd codeGranularity).
				(self isPCMappedAnnotation: annotation) ifTrue:
					[(annotation = IsSendCall
					  and: [(mapByte := objectMemory byteAt: map - 1) >> AnnotationShift = IsAnnotationExtension]) ifTrue:
						[annotation := annotation + (mapByte bitAnd: DisplacementMask).
						 map := map - 1].
					 [byte := (objectMemory fetchByte: bcpc ofObject: aMethodObj) + bsOffset.
					  descriptor := self generatorAt: byte.
					  isInBlock
						ifTrue: [bcpc >= endbcpc ifTrue: [^0]]
						ifFalse:
							[(descriptor isReturn and: [bcpc >= latestContinuation]) ifTrue: [^0].
							 (descriptor isBranch or: [descriptor isBlockCreation]) ifTrue:
								[| targetPC |
								 targetPC := self latestContinuationPCFor: descriptor at: bcpc exts: nExts in: aMethodObj.
								 latestContinuation := latestContinuation max: targetPC].
							 latestContinuation := self maybeUnsafeJumpContinuation: latestContinuation at: bcpc for: descriptor in: aMethodObj].
					  nextBcpc := self nextBytecodePCFor: descriptor at: bcpc exts: nExts in: aMethodObj.
					  descriptor isMapped
					  or: [isInBlock and: [descriptor isMappedInBlock]]] whileFalse:
						[bcpc := nextBcpc.
						 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]].
					 isBackwardBranch := descriptor isBranch
										   and: [self isBackwardBranch: descriptor at: bcpc exts: nExts in: aMethodObj].
					 result := self perform: functionSymbol
									with: descriptor
									with: (isBackwardBranch ifTrue: [annotation << 1 + 1] ifFalse: [annotation << 1])
									with: (self cCoerceSimple: mcpc to: #'char *')
									with: (isBackwardBranch ifTrue: [bcpc - (2 * nExts)] ifFalse: [bcpc])
									with: arg.
					 result ~= 0 ifTrue:
						[^result].
					 bcpc := nextBcpc.
					 nExts := descriptor isExtension ifTrue: [nExts + 1] ifFalse: [0]]]
			ifFalse:
				[self assert: (mapByte >> AnnotationShift = IsDisplacementX2N
							or: [mapByte >> AnnotationShift = IsAnnotationExtension]).
				 mapByte < (IsAnnotationExtension << AnnotationShift) ifTrue:
					[mcpc := mcpc + ((mapByte - DisplacementX2N << AnnotationShift) * backEnd codeGranularity)]].
		 map := map - 1].
	^0
]

{ #category : #'method map' }
Cogit >> mapFor: cogMethod do: aBlock [
	<doNotGenerate>
	self mapFor: cogMethod performUntil: #withAnnotation:pc:evaluate: arg: aBlock
]

{ #category : #'method map' }
Cogit >> mapFor: cogMethod performAllMapEntriesUntil: functionSymbol arg: arg [
	"Analysis support"
	<doNotGenerate>
	| mcpc map mapByte result |
	mcpc := self firstMappedPCFor: cogMethod.
	map := self mapStartFor: cogMethod.
	[(mapByte := objectMemory byteAt: map) ~= MapEnd] whileTrue:
		[mapByte >= FirstAnnotation
			ifTrue:
				[mcpc := mcpc + ((mapByte bitAnd: DisplacementMask) * backEnd codeGranularity)]
			ifFalse:
				[mapByte < (IsAnnotationExtension << AnnotationShift) ifTrue:
					[mcpc := mcpc + ((mapByte - DisplacementX2N << AnnotationShift) * backEnd codeGranularity)]].
		 result := self perform: functionSymbol
					   with: mapByte >> AnnotationShift
					   with: (self cCoerceSimple: mcpc to: #'char *')
					   with: arg.
		 result ~= 0 ifTrue:
			[^result].
		 map := map - 1].
	^0
]

{ #category : #'method map' }
Cogit >> mapFor: cogMethod performUntil: functionSymbol arg: arg [
	"Unlinking/GC/Disassembly support"
	<var: #cogMethod type: #'CogMethod *'>
	<var: #functionSymbol declareC: 'sqInt (*functionSymbol)(sqInt annotation, char *mcpc, sqInt arg)'>
	<inline: true>
	| mcpc map mapByte annotation result |
	mcpc := self firstMappedPCFor: cogMethod.
	map := self mapStartFor: cogMethod.
	self inlineCacheTagsAreIndexes ifTrue:
		[enumeratingCogMethod := cogMethod].
	[(mapByte := objectMemory byteAt: map) ~= MapEnd] whileTrue:
		[mapByte >= FirstAnnotation
			ifTrue:
				[mcpc := mcpc + ((mapByte bitAnd: DisplacementMask) * backEnd codeGranularity).
				 "If this is an IsSendCall annotation, peek ahead for an IsAnnotationExtension, and consume it."
				 ((annotation := mapByte >> AnnotationShift) = IsSendCall
				  and: [(mapByte := objectMemory byteAt: map - 1) >> AnnotationShift = IsAnnotationExtension]) ifTrue:
					[annotation := annotation + (mapByte bitAnd: DisplacementMask).
					 map := map - 1].
				 result := self perform: functionSymbol
							   with: annotation
							   with: (self cCoerceSimple: mcpc to: #'char *')
							   with: arg.
				 result ~= 0 ifTrue:
					[^result]]
			ifFalse:
				[mapByte < (IsAnnotationExtension << AnnotationShift) ifTrue:
					[mcpc := mcpc + ((mapByte - DisplacementX2N << AnnotationShift) * backEnd codeGranularity)]].
		 map := map - 1].
	^0
]

{ #category : #'garbage collection' }
Cogit >> mapObjectReferencesInClosedPIC: cPIC [
	"Remap all object references in the closed PIC.  Answer if any references are young.
	Set codeModified if any modifications are made."
	<var: #cPIC type: #'CogMethod *'>
	| pc refersToYoung |
	pc := self addressOfEndOfCase:1 inCPIC:cPIC.

	"first we check the potential method oop load at the beginning of the CPIC"
	refersToYoung := self remapMaybeObjRefInClosedPICAt: pc - backEnd jumpLongByteSize.

	"We find the end address of the cPICNumCases'th case and can then just step forward by the case size thereafter"
	pc := self addressOfEndOfCase: cPIC cPICNumCases inCPIC: cPIC.
	
	"Next we check the potential class ref in the compare instruction, and the potential method oop load for each case."
	2 to: cPIC cPICNumCases do:
		[:i|
		(self inlineCacheTagsAreIndexes not
		 and: [objectRepresentation inlineCacheTagsMayBeObjects]) ifTrue:
			[(self remapMaybeObjRefInClosedPICAt: pc - backEnd jumpLongConditionalByteSize) ifTrue:
				[refersToYoung := true]].
		(self remapMaybeObjRefInClosedPICAt: pc - backEnd jumpLongConditionalByteSize - backEnd cmpC32RTempByteSize) ifTrue:
			[refersToYoung := true].
		pc := pc + cPICCaseSize].
	^refersToYoung
]

{ #category : #'garbage collection' }
Cogit >> mapObjectReferencesInGeneratedRuntime [
	"Update all references to objects in the generated runtime."
	0 to: runtimeObjectRefIndex - 1 do:
		[:i| | mcpc literal mappedLiteral |
		 mcpc := objectReferencesInRuntime at: i.
		 literal := literalsManager fetchLiteralAtAnnotatedAddress: mcpc using: backEnd.
		 mappedLiteral := objectRepresentation remapObject: literal.
		 mappedLiteral ~= literal ifTrue:
			[literalsManager storeLiteral: mappedLiteral atAnnotatedAddress: mcpc using: backEnd.
			 codeModified := true]]
]

{ #category : #'jit - api' }
Cogit >> mapObjectReferencesInMachineCode: gcMode [
	<api>
	"Update all references to objects in machine code."
	gcMode caseOf: {
		[GCModeNewSpace]	-> [self mapObjectReferencesInMachineCodeForYoungGC].
		[GCModeFull]			-> [self mapObjectReferencesInMachineCodeForFullGC].
		[GCModeBecome]		-> [self mapObjectReferencesInMachineCodeForBecome] }.

	(self asserta: methodZone freeStart <= methodZone youngReferrers) ifFalse:
		[self error: 'youngReferrers list overflowed']
]

{ #category : #'garbage collection' }
Cogit >> mapObjectReferencesInMachineCodeForBecome [
	"Update all references to objects in machine code for a become.
	 Unlike incrementalGC or fullGC a method that does not refer to young may
	 refer to young as a result of the become operation.  Unlike incrementalGC
	 or fullGC the reference from a Cog method to its methodObject *must not*
	 change since the two are two halves of the same object."
	| cogMethod hasYoungObj hasYoungObjPtr freedPIC |
	<var: #cogMethod type: #'CogMethod *'>
	hasYoungObj := false.
	hasYoungObjPtr := (self addressOf: hasYoungObj put: [:val| hasYoungObj := val]) asInteger.
	codeModified := freedPIC := false.
	self mapObjectReferencesInGeneratedRuntime.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[self assert: hasYoungObj not.
		 cogMethod cmType ~= CMFree ifTrue:
			[self assert: (self cogMethodDoesntLookKosher: cogMethod) = 0.
			 cogMethod selector: (objectRepresentation remapOop: cogMethod selector).
			 cogMethod cmType = CMClosedPIC
				ifTrue:
					[((objectMemory isYoung: cogMethod selector)
					   or: [self mapObjectReferencesInClosedPIC: cogMethod]) ifTrue:
						[freedPIC := true.
						 methodZone freeMethod: cogMethod]]
				ifFalse:
					[(objectMemory isYoung: cogMethod selector) ifTrue:
						[hasYoungObj := true].
					 cogMethod cmType = CMMethod ifTrue:
						[| remappedMethod |
						 self assert: cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod.
						 remappedMethod := objectRepresentation remapOop: cogMethod methodObject.
						 remappedMethod ~= cogMethod methodObject ifTrue:
							[(coInterpreter methodHasCogMethod: remappedMethod) ifTrue:
								[self error: 'attempt to become two cogged methods'].
							 (objectMemory
									withoutForwardingOn: cogMethod methodObject
									and: remappedMethod
									with: cogMethod cmUsesPenultimateLit
									sendToCogit: #method:hasSameCodeAs:checkPenultimate:) ifFalse:
								[self error: 'attempt to become cogged method into different method'].
							 "There should be a one-to-one mapping between bytecoded and
							  cog methods."
							 "Only reset the method object's header if it is referring to this CogMethod."
							 (coInterpreter rawHeaderOf: cogMethod methodObject) = cogMethod asInteger
								ifTrue:
									[coInterpreter
										rawHeaderOf: cogMethod methodObject
										put: cogMethod methodHeader.
									 cogMethod
										methodHeader: (coInterpreter rawHeaderOf: remappedMethod);
										methodObject: remappedMethod.
									 coInterpreter
										rawHeaderOf: remappedMethod
										put: cogMethod asInteger]
								ifFalse:
									[self assert: (self noAssertMethodClassAssociationOf: cogMethod methodObject)
													= objectMemory nilObject.
									 cogMethod
										methodHeader: (coInterpreter rawHeaderOf: remappedMethod);
										methodObject: remappedMethod]].
						 (objectMemory isYoung: cogMethod methodObject) ifTrue:
							[hasYoungObj := true]].
					 self mapFor: cogMethod
						 performUntil: #remapIfObjectRef:pc:hasYoung:
						 arg: hasYoungObjPtr.
					 hasYoungObj
						ifTrue:
							[methodZone ensureInYoungReferrers: cogMethod.
							hasYoungObj := false]
						ifFalse:
							[cogMethod cmRefersToYoung: false]]].
		cogMethod := methodZone methodAfter: cogMethod].
	"we /must/ prune youngReferrers here because a) the [cogMethod cmRefersToYoung: false]
	 block could have removed a method and subsequently it could be added back, and b) we
	 can not tolerate duplicates in the youngReferrers list."  
	methodZone pruneYoungReferrers.
	freedPIC ifTrue:
		[self unlinkSendsToFree].
	codeModified ifTrue: "After updating oops in inline caches we need to flush the icache."
		[processor flushICacheFrom: codeBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger]
]

{ #category : #'garbage collection' }
Cogit >> mapObjectReferencesInMachineCodeForFullGC [
	"Update all references to objects in machine code for a full gc.  Since
	 the current (New)ObjectMemory GC makes everything old in a full GC
	 a method not referring to young will not refer to young afterwards"
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	codeModified := false.
	self mapObjectReferencesInGeneratedRuntime.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType ~= CMFree ifTrue:
			[self assert: (self cogMethodDoesntLookKosher: cogMethod) = 0.
			 cogMethod selector: (objectRepresentation remapOop: cogMethod selector).
			 cogMethod cmType = CMClosedPIC
				ifTrue:
					[self assert: cogMethod cmRefersToYoung not.
					 self mapObjectReferencesInClosedPIC: cogMethod]
				ifFalse:
					[cogMethod cmType = CMMethod ifTrue:
						[self assert: cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod.
						 cogMethod methodObject: (objectRepresentation remapOop: cogMethod methodObject)].
					 self mapFor: cogMethod
						 performUntil: #remapIfObjectRef:pc:hasYoung:
						 arg: 0.
					 (cogMethod cmRefersToYoung
					  and: [objectRepresentation allYoungObjectsAgeInFullGC]) ifTrue:
						[cogMethod cmRefersToYoung: false]]].
		cogMethod := methodZone methodAfter: cogMethod].
	methodZone pruneYoungReferrers.
	codeModified ifTrue: "After updating oops in inline caches we need to flush the icache."
		[processor flushICacheFrom: codeBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger]
]

{ #category : #'garbage collection' }
Cogit >> mapObjectReferencesInMachineCodeForYoungGC [
	"Update all references to objects in machine code for either a Spur scavenging gc
	 or a Squeak V3 incremental GC.  Avoid scanning all code by using the youngReferrers
	 list.  In a young gc a method referring to young may no longer refer to young, but a
	 method not referring to young cannot and will not refer to young afterwards."
	| pointer cogMethod hasYoungObj hasYoungObjPtr |
	<var: #cogMethod type: #'CogMethod *'>
	hasYoungObj := false.
	hasYoungObjPtr := (self addressOf: hasYoungObj put: [:val| hasYoungObj := val]) asInteger.
	codeModified := false.
	pointer := methodZone youngReferrers.
	[pointer < methodZone zoneEnd] whileTrue:
		[self assert: hasYoungObj not.
		 cogMethod := coInterpreter cCoerceSimple: (objectMemory longAt: pointer) to: #'CogMethod *'.
		 cogMethod cmType = CMFree
			ifTrue: [self assert: cogMethod cmRefersToYoung not]
			ifFalse:
				[self assert: (self cogMethodDoesntLookKosher: cogMethod) = 0.
				 cogMethod cmRefersToYoung ifTrue:
					[self assert: (cogMethod cmType = CMMethod
								or: [cogMethod cmType = CMOpenPIC]).
					 cogMethod selector: (objectRepresentation remapOop: cogMethod selector).
					 (objectMemory isYoung: cogMethod selector) ifTrue:
						[hasYoungObj := true].
					 cogMethod cmType = CMMethod ifTrue:
						[self assert: cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod.
						 cogMethod methodObject: (objectRepresentation remapOop: cogMethod methodObject).
						 (objectMemory isYoung: cogMethod methodObject) ifTrue:
							[hasYoungObj := true]].
					 self mapFor: cogMethod
						 performUntil: #remapIfObjectRef:pc:hasYoung:
						 arg: hasYoungObjPtr.
					 hasYoungObj
						ifTrue: [hasYoungObj := false]
						ifFalse: [cogMethod cmRefersToYoung: false]]].
		 pointer := pointer + objectMemory wordSize].
	methodZone pruneYoungReferrers.
	codeModified ifTrue: "After updating oops in inline caches we need to flush the icache."
		[processor flushICacheFrom: methodZoneBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger]
]

{ #category : #'simulation only' }
Cogit >> mapPrimitive: primitiveRoutine "<Symbol>" withIndexToUniqueAddress: primIndex [ "<SmallInteger>"
	| uniqueAddress |

	<doNotGenerate>

	self assert: (primitiveRoutine isSymbol or: [primitiveRoutine isBlock]).

	uniqueAddress := -1 - methodZoneBase - (primIndex * 4) - 16r1000 
		bitAnd: self allButTopBitOfAddressSpaceMask.
	
	simulatedTrampolines
		at: uniqueAddress
		ifAbsentPut:
			[primitiveRoutine isSymbol
				ifTrue: [MessageSend 
						receiver: coInterpreter 
						selector: primitiveRoutine
						arguments: (1 to: primitiveRoutine numArgs) asArray ]
				ifFalse: [primitiveRoutine]].
	^uniqueAddress
]

{ #category : #'method map' }
Cogit >> mapStartFor: cogMethod [
	"Answer the address of the first byte of the method map."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	^cogMethod asUnsignedInteger + cogMethod blockSize - 1
]

{ #category : #'garbage collection' }
Cogit >> markAndTraceLiteralsIn: cogMethod [
	<option: #SpurObjectMemory>
	"Unlink sends that have unmarked classes in inline caches or freed/freeable targets.
	 Nil-out inline caches linked to open PICs.
	 Assert that any selectors are marked.  We can do this since
	 this is only run on marked methods and thus any selectors they
	 reference should already be marked."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	self assert: ((cogMethod cmType = CMMethod
				 and: [objectMemory isMarked: cogMethod methodObject])
				 or: [cogMethod cmType = CMOpenPIC
				 and: [(objectMemory isImmediate: cogMethod selector)
					or: [objectMemory isMarked: cogMethod selector]]]).
	objectRepresentation
		markAndTraceLiteral: cogMethod selector
		in: cogMethod
		at: (self addressOf: cogMethod selector put: [:val| cogMethod selector: val]).
	self maybeMarkCountersIn: cogMethod.
	self mapFor: cogMethod
		 performUntil: #markLiterals:pc:method:
		 arg: cogMethod asInteger
]

{ #category : #'jit - api' }
Cogit >> markAndTraceMachineCodeForNewSpaceGC [
	"Free any methods that refer to unmarked objects, unlinking sends to freed methods."
	| pointer cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	objectMemory leakCheckNewSpaceGC ifTrue:
		[self asserta: self allMachineCodeObjectReferencesValid].
	codeModified := false.
	pointer := methodZone youngReferrers.
	[pointer < methodZone zoneEnd] whileTrue:
		[cogMethod := coInterpreter cCoerceSimple: (objectMemory longAt: pointer) to: #'CogMethod *'.
		 cogMethod cmRefersToYoung ifTrue:
			[self assert: (self cogMethodDoesntLookKosher: cogMethod) = 0.
			 self assert: (cogMethod cmType = CMMethod
						or: [cogMethod cmType = CMOpenPIC]).
			 (objectMemory isYoung: cogMethod selector) ifTrue:
				[objectMemory markAndTrace: cogMethod selector].
			 cogMethod cmType = CMMethod ifTrue:
				[(objectMemory isYoung: cogMethod methodObject) ifTrue:
					[objectMemory markAndTrace: cogMethod methodObject].
				self markYoungObjectsIn: cogMethod]].
		 pointer := pointer + objectMemory wordSize].
	objectMemory leakCheckNewSpaceGC ifTrue:
		[self asserta: self allMachineCodeObjectReferencesValid].
	codeModified ifTrue: "After updating oops in inline caches we need to flush the icache."
		[processor flushICacheFrom: methodZoneBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger]
]

{ #category : #'jit - api' }
Cogit >> markAndTraceMachineCodeOfMarkedMethods [
	"Mark objects in machine-code of marked methods (or open PICs with marked selectors)."
	<api>
	<option: #SpurObjectMemory>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	objectMemory leakCheckFullGC ifTrue:
		[self asserta: self allMachineCodeObjectReferencesValid].
	codeModified := false.
	self markAndTraceObjectReferencesInGeneratedRuntime.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[(cogMethod cmType = CMMethod
		  and: [objectMemory isMarked: cogMethod methodObject]) ifTrue:
			[self markAndTraceLiteralsIn: cogMethod].
		 (cogMethod cmType = CMOpenPIC
		  and: [(objectMemory isImmediate: cogMethod selector)
				or: [objectMemory isMarked: cogMethod selector]]) ifTrue:
			[self markAndTraceLiteralsIn: cogMethod].
		 cogMethod := methodZone methodAfter: cogMethod].
	objectMemory leakCheckFullGC ifTrue:
		[self asserta: self allMachineCodeObjectReferencesValid].
	codeModified ifTrue: "After updating oops in inline caches we need to flush the icache."
		[processor flushICacheFrom: methodZoneBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger]
]

{ #category : #'jit - api' }
Cogit >> markAndTraceObjectReferencesInGeneratedRuntime [
	"Mark and trace any object references in the generated run-time."
	0 to: runtimeObjectRefIndex - 1 do:
		[:i| | mcpc literal |
		 mcpc := objectReferencesInRuntime at: i.
		 literal := literalsManager fetchLiteralAtAnnotatedAddress: mcpc using: backEnd.
		 objectRepresentation
			markAndTraceLiteral: literal
			in: (self cCoerceSimple: nil to: #'CogMethod *')
			atpc: mcpc asUnsignedInteger]
]

{ #category : #'garbage collection' }
Cogit >> markAndTraceOrFreeCogMethod: cogMethod firstVisit: firstVisit [
	"Mark and trace objects in the argument and free if it is appropriate.
	 Answer if the method has been freed.  firstVisit is a hint used to avoid
	 scanning methods we've already seen.  False positives are fine.
	 For a CMMethod this
			frees if the bytecode method isnt marked,
			marks and traces object literals and selectors,
			unlinks sends to targets that should be freed.
	 For a CMClosedPIC this
			frees if it refers to anything that should be freed or isn't marked.
	 For a CMOpenPIC this
			frees if the selector isn't marked."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: false> "this recurses at most one level down"
	cogMethod cmType = CMFree ifTrue:
		[^true].
	self assert: (self cogMethodDoesntLookKosher: cogMethod) = 0.
	cogMethod cmType = CMMethod ifTrue:
		[(objectMemory isMarked: cogMethod methodObject) ifFalse:
			[methodZone freeMethod: cogMethod.
			 ^true].
		 firstVisit ifTrue:
			[self markLiteralsAndUnlinkUnmarkedSendsIn: cogMethod].
		^false].
	cogMethod cmType = CMClosedPIC ifTrue:
		[(self closedPICRefersToUnmarkedObject: cogMethod) ifFalse:
			[^false].
		 methodZone freeMethod: cogMethod.
		 ^true].
	cogMethod cmType = CMOpenPIC ifTrue:
		[(objectMemory isMarked: cogMethod selector) ifTrue:
			[^false].
		 methodZone freeMethod: cogMethod.
		 ^true].
	self assert: (cogMethod cmType = CMMethod
				or: [cogMethod cmType = CMClosedPIC
				or: [cogMethod cmType = CMOpenPIC]]).
	^false
]

{ #category : #'jit - api' }
Cogit >> markAndTraceOrFreeMachineCodeForFullGC [
	"Free any methods that refer to unmarked objects, unlinking sends to freed methods."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	objectMemory leakCheckFullGC ifTrue:
		[self asserta: self allMachineCodeObjectReferencesValid].
	codeModified := false.
	self markAndTraceObjectReferencesInGeneratedRuntime.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[self markAndTraceOrFreeCogMethod: cogMethod firstVisit: true.
		 cogMethod := methodZone methodAfter: cogMethod].
	objectMemory leakCheckFullGC ifTrue:
		[self asserta: self allMachineCodeObjectReferencesValid].
	codeModified ifTrue: "After updating oops in inline caches we need to flush the icache."
		[processor flushICacheFrom: methodZoneBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger]
]

{ #category : #'garbage collection' }
Cogit >> markAndTraceOrFreePICTarget: entryPoint in: cPIC [
	"If entryPoint is that of some method, then mark and trace objects in it and free if it is appropriate.
	 Answer if the method has been freed."
	<var: #cPIC type: #'CogMethod *'>
	| targetMethod |
	<var: #targetMethod type: #'CogMethod *'>
	self assert: (entryPoint > methodZoneBase and: [entryPoint < methodZone freeStart]).
	(cPIC containsAddress: entryPoint) ifTrue:
		[^false].
	targetMethod := self cCoerceSimple: entryPoint - cmNoCheckEntryOffset to: #'CogMethod *'.
	self assert: (targetMethod cmType = CMMethod or: [targetMethod cmType = CMFree]).
	^self markAndTraceOrFreeCogMethod: targetMethod
		  firstVisit: targetMethod asUnsignedInteger > cPIC asUnsignedInteger
]

{ #category : #'garbage collection' }
Cogit >> markLiterals: annotation pc: mcpc method: cogMethod [
	"Mark and trace literals."
	<var: #mcpc type: #'char *'>
	| literal |
	annotation = IsObjectReference ifTrue:
		[literal := literalsManager fetchLiteralAtAnnotatedAddress: mcpc asUnsignedInteger using: backEnd.
		 (objectRepresentation
				markAndTraceLiteral: literal
				in: (self cCoerceSimple: cogMethod to: #'CogMethod *')
				atpc: mcpc asUnsignedInteger) ifTrue:
			[codeModified := true]].

	(self isPureSendAnnotation: annotation) ifTrue:
		[self entryCacheTagAndCouldBeObjectAt: mcpc annotation: annotation into:
			[:entryPoint :cacheTag :tagCouldBeObj |
			 tagCouldBeObj ifTrue:
				[(objectRepresentation
						markAndTraceCacheTagLiteral: cacheTag
						in: (self cCoerceSimple: cogMethod to: #'CogMethod *')
						atpc: mcpc asUnsignedInteger) ifTrue:
					["cacheTag is selector" codeModified := true]]]].

	^0 "keep scanning"
]

{ #category : #'garbage collection' }
Cogit >> markLiteralsAndUnlinkIfUnmarkedSend: annotation pc: mcpc method: cogMethod [
	"Mark and trace literals.  Unlink sends that have unmarked cache tags or targets."
	<var: #mcpc type: #'char *'>
	| literal |
	annotation = IsObjectReference ifTrue:
		[literal := literalsManager fetchLiteralAtAnnotatedAddress: mcpc asUnsignedInteger using: backEnd.
		 (objectRepresentation
				markAndTraceLiteral: literal
				in: (self cCoerceSimple: cogMethod to: #'CogMethod *')
				atpc: mcpc asUnsignedInteger) ifTrue:
			[codeModified := true]].

	(self isPureSendAnnotation: annotation) ifTrue:
		[self entryCacheTagAndCouldBeObjectAt: mcpc annotation: annotation into:
			[:entryPoint :cacheTag :tagCouldBeObj | | cacheTagMarked |
			 cacheTagMarked := tagCouldBeObj and: [objectRepresentation cacheTagIsMarked: cacheTag].
			 entryPoint > methodZoneBase
				ifTrue: "It's a linked send."
					[self targetMethodAndSendTableFor: entryPoint annotation: annotation into:
						[:targetMethod :sendTable| 
						 (cacheTagMarked not
						  or: [self markAndTraceOrFreeCogMethod: targetMethod
								firstVisit: targetMethod asUnsignedInteger > mcpc asUnsignedInteger]) ifTrue:
							["Either the cacheTag is unmarked (e.g. new class) or the target
							  has been freed (because it is unmarked), so unlink the send."
							 self unlinkSendAt: mcpc targetMethod: targetMethod sendTable: sendTable.
							 objectRepresentation
								markAndTraceLiteral: targetMethod selector
								in: targetMethod
								at: (self addressOf: targetMethod selector put: [:val| targetMethod selector: val])]]]
				ifFalse:  "cacheTag is selector"
					[(objectRepresentation
							markAndTraceCacheTagLiteral: cacheTag
							in: (self cCoerceSimple: cogMethod to: #'CogMethod *')
							atpc: mcpc asUnsignedInteger) ifTrue:
						[codeModified := true]]]].

	^0 "keep scanning"
]

{ #category : #'garbage collection' }
Cogit >> markLiteralsAndUnlinkUnmarkedSendsIn: cogMethod [
	"Unlink sends that have unmarked classes in inline caches or freed/freeable targets.
	 Nil-out inline caches linked to open PICs.
	 Assert that any selectors are marked.  We can do this since
	 this is only run on marked methods and thus any selectors they
	 reference should already be marked."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	self assert: cogMethod cmType = CMMethod.
	self assert: (objectMemory isMarked: cogMethod methodObject).
	objectRepresentation
		markAndTraceLiteral: cogMethod selector
		in: cogMethod
		at: (self addressOf: cogMethod selector put: [:val| cogMethod selector: val]).
	self maybeMarkCountersIn: cogMethod.
	self mapFor: cogMethod
		 performUntil: #markLiteralsAndUnlinkIfUnmarkedSend:pc:method:
		 arg: cogMethod asInteger
]

{ #category : #'jit - api' }
Cogit >> markMethodAndReferents: aCogMethod [
	<api>
	<var: #aCogMethod type: #'CogBlockMethod *'>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	self assert: (aCogMethod cmType = CMMethod
				or: [aCogMethod cmType = CMBlock]).
	cogMethod := aCogMethod cmType = CMMethod
					ifTrue: [self cCoerceSimple: aCogMethod to: #'CogMethod *']
					ifFalse: [aCogMethod cmHomeMethod].
	cogMethod cmUsageCount: CMMaxUsageCount.
	self mapFor: cogMethod
		performUntil: #incrementUsageOfTargetIfLinkedSend:mcpc:ignored:
		arg: 0
]

{ #category : #'garbage collection' }
Cogit >> markYoungObjects: annotation pc: mcpc method: cogMethod [
	"Mark and trace young literals."
	<var: #mcpc type: #'char *'>
	| literal |
	annotation = IsObjectReference ifTrue:
		[literal := literalsManager fetchLiteralAtAnnotatedAddress: mcpc asUnsignedInteger using: backEnd.
		 objectRepresentation markAndTraceLiteralIfYoung: literal].

	(self isPureSendAnnotation: annotation) ifTrue:
		[self entryCacheTagAndCouldBeObjectAt: mcpc annotation: annotation into:
			[:entryPoint :cacheTag :tagCouldBeObj |
			 tagCouldBeObj ifTrue:
				[objectRepresentation markAndTraceLiteralIfYoung: cacheTag]]].

	^0 "keep scanning"
]

{ #category : #'garbage collection' }
Cogit >> markYoungObjectsIn: cogMethod [
	"Mark young literals in the method."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	self assert: (cogMethod cmType = CMMethod
				or: [cogMethod cmType = CMOpenPIC]).
	 (objectMemory isYoung: cogMethod selector) ifTrue:
		[objectMemory markAndTrace: cogMethod selector].
	(cogMethod cmType = CMMethod
	 and: [objectMemory isYoung: cogMethod methodObject]) ifTrue:
		[objectMemory markAndTrace: cogMethod methodObject].
	self mapFor: cogMethod
		 performUntil: #markYoungObjects:pc:method:
		 arg: cogMethod asInteger
]

{ #category : #accessing }
Cogit >> maxCogCodeSize [
	"We restrict the maximum size of the code zone to 16Mb to allow inter-method
	 calls and jumps to use small offset call and jump instructions if appropriate."
	<api>
	<cmacro: '() (16*1024*1024)'>
	^16*1024*1024
]

{ #category : #debugging }
Cogit >> maxCogMethodAddress [
	<api>
	<returnTypeC: #usqInt>
	^methodZone limitZony asUnsignedInteger
]

{ #category : #accessing }
Cogit >> maxLitIndex: anInteger [ 
	<doNotGenerate>
	maxLitIndex := anInteger
]

{ #category : #'compile abstract instructions' }
Cogit >> maybeAllocAndInitCounters [
	"No-op in the non-Sista Cogits..."
	^true
]

{ #category : #'simulation only' }
Cogit >> maybeBreakAt: address [
	<doNotGenerate>
	((breakPC isBreakpointFor: address)
	 and: [breakBlock shouldStopIfAtPC: address]) ifTrue:
		[coInterpreter changed: #byteCountText.
		 self halt: 'machine code breakpoint at ', address hex, ' in ', thisContext sender selector]
]

{ #category : #'simulation only' }
Cogit >> maybeBreakGeneratingAt: address [
	"Variation on maybeBreakAt: that only works for integer breakPCs,
	 so we can have break blocks that stop at any pc, except when generating."
	<cmacro: '(address) 0'> "Simulation only; void in C"
	(breakPC = address
	 and: [breakBlock shouldStopIfAtPC: address]) ifTrue:
		[coInterpreter changed: #byteCountText.
		 self halt: 'machine code generation at ', address hex, ' in ', thisContext sender selector]
]

{ #category : #'compile abstract instructions' }
Cogit >> maybeDealWithUnsafeJumpForDescriptor: descriptor pc: pc latestContinuation: latestContinuation [
	<inline: true>
	^ latestContinuation
]

{ #category : #'compile abstract instructions' }
Cogit >> maybeDumpLiterals: descriptor [
	<inline: true>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	((literalsManager mustDumpLiterals: opcodeIndex)
	  or: [descriptor isUnconditionalBranch
	  or: [descriptor isReturn]]) ifTrue:
		[literalsManager dumpLiterals: (descriptor isUnconditionalBranch
										or: [descriptor isReturn]) not]
]

{ #category : #'simulation only' }
Cogit >> maybeEnableSingleStep [
	<inline: true>
	self cCode: '' inSmalltalk:
		[singleStep ifFalse: [singleStep := breakPC singleStepRequiredToTriggerIn: self]]
]

{ #category : #debugging }
Cogit >> maybeFreeCogMethodDoesntLookKosher: cogMethod [
	"Check that the header fields are consistent with the type.
	 Answer 0 if it is ok, otherwise answer a code for the error."
	<var: #cogMethod type: #'CogMethod *'>
	| result |
	result := self cogMethodDoesntLookKosher: cogMethod.
	^result = 2 ifTrue: [0] ifFalse: [result]
]

{ #category : #'compile abstract instructions' }
Cogit >> maybeFreeCounters [
	"No-op in the non-Sista Cogits..."
]

{ #category : #compaction }
Cogit >> maybeFreeCountersOf: aCogMethod [
	"Sista allocates counters out-of-line that need to be freed later on.
	 This is the hook Sista uses.  By default do nothing."
	<inline: true>
]

{ #category : #initialization }
Cogit >> maybeGenerateCheckFeatures [
	| startAddress |
	<inline: true>
	backEnd numCheckFeaturesOpcodes > 0 ifTrue:
		[self allocateOpcodes: backEnd numCheckFeaturesOpcodes bytecodes: 0.
		 startAddress := methodZoneBase.
		 backEnd generateCheckFeatures.
		 self outputInstructionsForGeneratedRuntimeAt: startAddress.
		 self recordGeneratedRunTime: 'ceCheckFeaturesFunction' address: startAddress.
		 ceCheckFeaturesFunction := self cCoerceSimple: startAddress to: #'usqIntptr_t (*)(void)']
]

{ #category : #initialization }
Cogit >> maybeGenerateICacheFlush [
	| startAddress |
	<inline: true>
	backEnd numICacheFlushOpcodes > 0 ifTrue:
		[self allocateOpcodes: backEnd numICacheFlushOpcodes bytecodes: 0.
		 startAddress := methodZoneBase.
		 backEnd generateICacheFlush.
		 self outputInstructionsForGeneratedRuntimeAt: startAddress.
		 self recordGeneratedRunTime: 'ceFlushICache' address: startAddress.
		 ceFlushICache := self cCoerceSimple: startAddress to: #'void (*)(usqIntptr_t,usqIntptr_t)']
]

{ #category : #'compile abstract instructions' }
Cogit >> maybeHaltIfDebugPC [ 
	<cmacro: '() 0'> "Simulation only; void in C"
	((debugBytecodePointers includes: bytecodePC)
	 and: [breakMethod isNil or: [methodObj = breakMethod]]) ifTrue:
		[self halt: ' at bcpc ', bytecodePC printString, '/', (bytecodePC + 1) printString]
]

{ #category : #'garbage collection' }
Cogit >> maybeMarkCountersIn: cogMethod [
	"In SIsta Spur counters are held on the heap in pinned objects which must be marked
	 to avoid them being garbage collected.  This is the hook through which that happens."
	<var: #cogMethod type: #'CogMethod *'>
]

{ #category : #disassembly }
Cogit >> maybeNoteStartpcFor: thing [ "<CogBlockStart|CogCodeRange>"
	<doNotGenerate>
	(self class initializationOptions at: #tempNames ifAbsent: nil) ifNotNil:
		[self class initializationOptions
			at: #startpc put: thing startpc;
			at: #numArgs put: ([thing cogMethod ifNil: [-1] ifNotNil: [:cm| cm cmNumArgs]] "CogCodeRange"
									on: MessageNotUnderstood
									do: [:ex| thing numArgs])] "CogBlockStart"
]

{ #category : #'profiling primitives' }
Cogit >> maybeTopRemapped: anOop [
	<inline: true>
	^SPURVM ifTrue: [anOop] ifFalse: [objectMemory topRemappableOop]
]

{ #category : #'compile abstract instructions' }
Cogit >> maybeUnsafeJumpContinuation: latestContinuation at: bcpc for: descriptor in: aMethodObj [
	<inline: true>
	^ latestContinuation
]

{ #category : #'method map' }
Cogit >> mcPCFor: bcpc startBcpc: startbcpc in: cogMethod [
	"Answer the absolute machine code pc matching the zero-relative bytecode pc argument
	 in cogMethod, given the start of the bytecodes for cogMethod's block or method object."
	<var: #cogMethod type: #'CogBlockMethod *'>
	<returnTypeC: #usqInt>
	^self
		mapFor: cogMethod
		bcpc: startbcpc
		performUntil: #find:IsBackwardBranch:Mcpc:Bcpc:MatchingBcpc:
		arg: bcpc asVoidPointer
]

{ #category : #'method map' }
Cogit >> mcPCForBackwardBranch: bcpc startBcpc: startbcpc in: cogMethod [
	"Answer the absolute machine code pc matching the zero-relative
	 bytecode pc of a backward branch in cogMethod, given the start
	 of the bytecodes for cogMethod's block or method object."
	<api>
	<var: #cogMethod type: #'CogBlockMethod *'>
	<returnTypeC: #usqInt>
	^self
		mapFor: cogMethod
		bcpc: startbcpc
		performUntil: #findBackwardBranch:IsBackwardBranch:Mcpc:Bcpc:MatchingBcpc:
		arg: bcpc asVoidPointer
]

{ #category : #initialization }
Cogit >> mclassIsSmallInteger [
	^objectMemory isIntegerObject: receiverTags
]

{ #category : #'garbage collection' }
Cogit >> method: methodA hasSameCodeAs: methodB [
	"For the purposes of become: see if the two methods are similar, i.e. can be safely becommed.
	 This is pretty strict.  All literals and bytecodes must be identical.  Only trailer bytes and header
	  flags can differ."
	<inline: false>
	| headerA headerB numLitsA endPCA |
	headerA := objectMemory methodHeaderOf: methodA.
	headerB := objectMemory methodHeaderOf: methodB.
	numLitsA := objectMemory literalCountOfMethodHeader: headerA.
	endPCA := self endPCOf: methodA.
	((coInterpreter argumentCountOfMethodHeader: headerA) ~= (coInterpreter argumentCountOfMethodHeader: headerB)
	 or: [(coInterpreter temporaryCountOfMethodHeader: headerA) ~= (coInterpreter temporaryCountOfMethodHeader: headerB)
	 or: [(coInterpreter primitiveIndexOfMethod: methodA header: headerA) ~= (coInterpreter primitiveIndexOfMethod: methodB header: headerB)
	 or: [numLitsA ~= (objectMemory literalCountOfMethodHeader: headerB)
	 or: [endPCA > (objectMemory numBytesOf: methodB)]]]]) ifTrue:
		[^false].
	 1 to: numLitsA - 1 do:
		[:li|
		(objectMemory fetchPointer: li ofObject: methodA) ~= (objectMemory fetchPointer: li ofObject: methodB) ifTrue:
			[^false]].
	(coInterpreter startPCOfMethod: methodA) to: endPCA do:
		[:bi|
		(objectMemory fetchByte: bi ofObject: methodA) ~= (objectMemory fetchByte: bi ofObject: methodB) ifTrue:
			[^false]].
	^true
]

{ #category : #'garbage collection' }
Cogit >> method: methodA hasSameCodeAs: methodB checkPenultimate: comparePenultimateLiteral [
	"For the purposes of become: see if the two methods are similar, i.e. can be safely becommed.
	 This is pretty strict.  All literals and bytecodes must be identical.  Only trailer bytes and header
	  flags can differ."
	<inline: false>
	| headerA headerB numLitsA endPCA |
	headerA := objectMemory methodHeaderOf: methodA.
	headerB := objectMemory methodHeaderOf: methodB.
	numLitsA := objectMemory literalCountOfMethodHeader: headerA.
	endPCA := self endPCOf: methodA.
	((coInterpreter argumentCountOfMethodHeader: headerA) ~= (coInterpreter argumentCountOfMethodHeader: headerB)
	 or: [(coInterpreter temporaryCountOfMethodHeader: headerA) ~= (coInterpreter temporaryCountOfMethodHeader: headerB)
	 or: [(coInterpreter primitiveIndexOfMethod: methodA header: headerA) ~= (coInterpreter primitiveIndexOfMethod: methodB header: headerB)
	 or: [numLitsA ~= (objectMemory literalCountOfMethodHeader: headerB)
	 or: [endPCA > (objectMemory numBytesOf: methodB)]]]]) ifTrue:
		[^false].
	 1 to: numLitsA - 1 do:
		[:li|
		(objectMemory fetchPointer: li ofObject: methodA) ~= (objectMemory fetchPointer: li ofObject: methodB) ifTrue:
			[(li < (numLitsA - 1) "If the method doesn't use the penultimate literal then don't fail the comparison."
			  or: [comparePenultimateLiteral]) ifTrue:
				[^false]]].
	(coInterpreter startPCOfMethod: methodA) to: endPCA do:
		[:bi|
		(objectMemory fetchByte: bi ofObject: methodA) ~= (objectMemory fetchByte: bi ofObject: methodB) ifTrue:
			[^false]].
	^true
]

{ #category : #testing }
Cogit >> methodFoundInvalidPostScan [
	"This is a hook for subclasses to filter out methods they can't deal with."
	<inline: true>
	^false
]

{ #category : #accessing }
Cogit >> methodLabel [
	<cmacro: '() methodLabel'>
	^methodLabel
]

{ #category : #accessing }
Cogit >> methodNumArgs [
	^methodOrBlockNumArgs
]

{ #category : #accessing }
Cogit >> methodObj [
	<doNotGenerate>
	^ methodObj
]

{ #category : #accessing }
Cogit >> methodObj: anObject [
	<doNotGenerate>
	methodObj := anObject
]

{ #category : #accessing }
Cogit >> methodZone [
	^methodZone
]

{ #category : #'trampoline support' }
Cogit >> methodZoneBase [
	<cmacro: '() methodZoneBase'>
	^methodZoneBase
]

{ #category : #'*VMMaker-Tests' }
Cogit >> methodZoneBase: anInteger [ 
	<doNotGenerate>
	methodZoneBase := anInteger
]

{ #category : #accessing }
Cogit >> minCallAddress [
	<cmacro: '() minValidCallAddress'>
	^minValidCallAddress
]

{ #category : #debugging }
Cogit >> minCogMethodAddress [
	<api>
	^methodZoneBase
]

{ #category : #accessing }
Cogit >> missOffset [
	<doNotGenerate>
	^ missOffset
]

{ #category : #'in-line cacheing' }
Cogit >> mnuOffset [
	<api>
	^missOffset
]

{ #category : #'compile abstract instructions' }
Cogit >> needsFrameIfImmutability: stackDelta [
	^ IMMUTABILITY
]

{ #category : #'compile abstract instructions' }
Cogit >> needsFrameIfInBlock: stackDelta [
	^inBlock > 0
]

{ #category : #'compile abstract instructions' }
Cogit >> needsFrameNever: stackDelta [
	^false
]

{ #category : #'compile abstract instructions' }
Cogit >> nextBytecodePCFor: descriptor at: pc exts: nExts in: aMethodObj [
	"Compute the distance to the logically subsequent bytecode, i.e. skip over blocks."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	^pc
		+ descriptor numBytes
		+ (descriptor isBlockCreation
			ifTrue: [self spanFor: descriptor at: pc exts: nExts in: aMethodObj]
			ifFalse: [0])
]

{ #category : #'compile abstract instructions' }
Cogit >> nextBytecodePCFor: descriptor exts: nExts [
	<inline: true>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	 ^ self nextBytecodePCFor: descriptor at: bytecodePC exts: nExts in: methodObj
]

{ #category : #'bytecode generator support' }
Cogit >> nextDescriptorExtensionsAndNextPCInto: aQuaternaryBlock [
	"Peek ahead and deliver the next descriptor, extension bytes and next pc."
	<inline: true>
	| savedB0 savedB1 savedB2 savedB3 savedEA savedEB savedNEB descriptor bcpc |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	descriptor := self generatorAt: byte0.
	savedB0 := byte0. savedB1 := byte1. savedB2 := byte2. savedB3 := byte3.
	savedEA := extA. savedEB := extB. savedNEB := numExtB.
	bcpc := bytecodePC + descriptor numBytes.
	[bcpc > endPC ifTrue:
		[^aQuaternaryBlock value: nil value: 0 value: 0 value: 0].
	 byte0 := (objectMemory fetchByte: bcpc ofObject: methodObj)  + bytecodeSetOffset.
	 descriptor := self generatorAt: byte0.
	 self loadSubsequentBytesForDescriptor: descriptor at: bcpc.
	 descriptor isExtension ifFalse:
		[| eA eB |
		 eA := extA. eB := extB.
		 extA := savedEA. extB := savedEB. numExtB := savedNEB.
		 byte0 := savedB0. byte1 := savedB1. byte2 := savedB2. byte3 := savedB3.
	 	 ^aQuaternaryBlock value: descriptor value: eA value: eB value: bcpc].
	 self perform: descriptor generator.
	 bcpc := bcpc + descriptor numBytes.
	 true] whileTrue
]

{ #category : #debugging }
Cogit >> noAssertMethodClassAssociationOf: methodPointer [
	^coInterpreter
		literal: (objectMemory literalCountOfMethodHeader: (coInterpreter noAssertHeaderOf: methodPointer)) - 1
		ofMethod: methodPointer
]

{ #category : #accessing }
Cogit >> noCheckEntryOffset [
	<api>
	<cmacro>
	^cmNoCheckEntryOffset
]

{ #category : #compaction }
Cogit >> noCogMethodsMaximallyMarked [
	"Check that no method is maximally marked.  A maximal mark is an indication the
	 method has been scanned to increase the usage count of its referent methods."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[(cogMethod cmType ~= CMFree
		  and: [cogMethod cmUsageCount = CMMaxUsageCount]) ifTrue:
			[^false].
		 cogMethod := methodZone methodAfter: cogMethod].
	^true
]

{ #category : #accessing }
Cogit >> noContextSwitchBlockEntryOffset [
	<api>
	<cmacro: '() blockNoContextSwitchOffset'>
	self assert: blockNoContextSwitchOffset notNil.
	^blockNoContextSwitchOffset
]

{ #category : #compaction }
Cogit >> noTargetsFreeInClosedPIC: cPIC [
	"Answer if all targets in the PIC are in-use methods."
	<var: #cPIC type: #'CogMethod *'>
	^(self cPICHasFreedTargets: cPIC) not
]

{ #category : #initialization }
Cogit >> numArgsOrSendNumArgsReg: numArgs [
	"The send trampolines have different versions for different arg counts, with special
	 cases for 0 through NumSendTrampolines - 2, and a general case for more, passing
	 the arg count in SendNumArgsReg.  This computes the relevant argument."
	<inline: true>
	^numArgs <= (NumSendTrampolines - 2)
		ifTrue: [self trampolineArgConstant: numArgs]
		ifFalse: [SendNumArgsReg]
]

{ #category : #accessing }
Cogit >> objectMemory [
	<doNotGenerate>
	^objectMemory
]

{ #category : #'simulation only' }
Cogit >> objectRepresentation [
	<doNotGenerate>
	^objectRepresentation
]

{ #category : #'simulation only' }
Cogit >> offset: aClass of: fieldSymbol [
	"This is implemented by stddef's offsetof macro."
	<doNotGenerate>
	^aClass caseOf:
		{ [CogMethod] -> [cogMethodSurrogateClass offsetOf: fieldSymbol] }
]

{ #category : #'in-line cacheing' }
Cogit >> offsetAndSendTableFor: entryPoint annotation: annotation into: binaryBlock [
	"Find the relevant sendTable for a linked-send to entryPoint.  Do this based on the
	 annotation.  c.f. annotationForSendTable:"
	<inline: true>
	| offset sendTable |
	<var: #sendTable type: #'sqInt *'>
	annotation = IsSendCall ifTrue:
		[offset := cmEntryOffset.
		 sendTable := ordinarySendTrampolines] ifFalse:
	[(BytecodeSetHasDirectedSuperSend and: [annotation = IsDirectedSuperSend]) ifTrue:
		[offset := cmNoCheckEntryOffset.
		 sendTable := directedSuperSendTrampolines] ifFalse:
	[(BytecodeSetHasDirectedSuperSend and: [annotation = IsDirectedSuperBindingSend]) ifTrue:
		[offset := cmNoCheckEntryOffset.
		 sendTable := directedSuperBindingSendTrampolines] ifFalse:
	[self assert: annotation = IsSuperSend.
	 offset := cmNoCheckEntryOffset.
	 sendTable := superSendTrampolines]]].

	binaryBlock
		value: offset
		value: sendTable
]

{ #category : #'debug printing' }
Cogit >> opcodePrintStringFrom: startIndex to: stopIndex [
	^(String streamContents:
		[:s|
		startIndex to: stopIndex do:
			[:i|
			(abstractOpcodes at: i) printStateOn: s]]) allButFirst
]

{ #category : #accessing }
Cogit >> openPICSize [
	<doNotGenerate>
	^ openPICSize
]

{ #category : #accessing }
Cogit >> ordinarySendTrampolineAt: anInteger put: aTrampolineAddress [ 
	<doNotGenerate>
	
	ordinarySendTrampolines at: anInteger put: aTrampolineAddress
]

{ #category : #'generate machine code' }
Cogit >> outputInstructionsAt: startAddress [
	"Store the generated machine code, answering the last address"
	| absoluteAddress |
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	absoluteAddress := startAddress.
	0 to: opcodeIndex - 1 do:
		[:i| | abstractInstruction |
		abstractInstruction := self abstractInstructionAt: i.
		self assert: abstractInstruction address = absoluteAddress.
		abstractInstruction outputMachineCodeAt: absoluteAddress.
		absoluteAddress := absoluteAddress + abstractInstruction machineCodeSize].
	^absoluteAddress
]

{ #category : #initialization }
Cogit >> outputInstructionsForGeneratedRuntimeAt: startAddress [
	"Output instructions generated for one of the generated run-time routines, a trampoline, etc"
	| size endAddress |
	<inline: false>
	self computeMaximumSizes.
	methodLabel address: startAddress. "for addressIsInCurrentCompilation:"
	size := self generateInstructionsAt: startAddress.
	endAddress := self outputInstructionsAt: startAddress.
	self assert: startAddress + size = endAddress.
	methodZoneBase := self alignUptoRoutineBoundary: endAddress.
	backEnd stopsFrom: endAddress to: methodZoneBase - 1.
	self cCode: '' inSmalltalk: [methodZone freeStart: methodZoneBase].
	^startAddress
]

{ #category : #'compile abstract instructions' }
Cogit >> patchFixupTargetIfNeeded: fixup nextOpcodeIndex: nextOpcodeIndex [
	<var: #fixup type: #'BytecodeFixup *'>
	<inline: true>
	 fixup needsFixup ifTrue:
		["There is a fixup for this bytecode.  It must point to the first generated
		   instruction for this bytecode.  If there isn't one we need to add a label."
		 opcodeIndex = nextOpcodeIndex ifTrue: [self Label].
		 fixup targetInstruction: (self abstractInstructionAt: nextOpcodeIndex)].
]

{ #category : #'in-line cacheing' }
Cogit >> patchToOpenPICFor: selector numArgs: numArgs receiver: receiver [
	"Code entry closed PIC full or miss to an instance of a young class or to a young target method.
	 Attempt to patch the send site to an open PIC.  Answer if the attempt succeeded; in fact it will
	 only return if the attempt failed.
	 The stack looks like:
			receiver
			args
	 sp=>	sender return address"
	<api>
	| oPIC outerReturn extent |
	<var: #oPIC type: #'CogMethod *'>
	outerReturn := coInterpreter stackTop.
	"See if an Open PIC is already available."
	oPIC := methodZone openPICWithSelector: selector.
	oPIC ifNil:
		["otherwise attempt to create an Open PIC."
		oPIC := self cogOpenPICSelector: selector numArgs: numArgs.
		(oPIC asInteger between: MaxNegativeErrorCode and: -1) ifTrue:
			["For some reason the PIC couldn't be generated, most likely a lack of code memory."
			oPIC asInteger = InsufficientCodeSpace ifTrue:
				[coInterpreter callForCogCompiledCodeCompaction].
			^false]].
	"Relink the send site to the pic.  Reset the cache tag to the selector, for the
	 benefit of the cacheTag assert check in checkIfValidOopRef:pc:cogMethod: et al."
	extent := backEnd
				rewriteInlineCacheAt: outerReturn
				tag: (self inlineCacheValueForSelector: selector
						  in: coInterpreter mframeHomeMethodExport
						  at: outerReturn)
				target: oPIC asInteger + cmEntryOffset.
	processor
		flushICacheFrom: outerReturn asUnsignedInteger - extent to: outerReturn asUnsignedInteger;
		flushICacheFrom: oPIC asUnsignedInteger to: oPIC asUnsignedInteger + openPICSize.
	"Jump into the oPIC at its entry"
	coInterpreter executeCogMethod: oPIC fromLinkedSendWithReceiver: receiver.
	"NOTREACHED"
	^true
]

{ #category : #accessing }
Cogit >> picAbortDiscriminatorValue [
	"This value is used to decide between MNU processing
	 or interpretation in the closed PIC aborts."
	^0
]

{ #category : #debugging }
Cogit >> picInterpretAbortOffset [
	"Answer the start of the abort sequence for invoking the interpreter in a closed PIC."
	^self interpretOffset
	 - (backEnd hasLinkRegister
		ifTrue: [backEnd pushLinkRegisterByteSize + backEnd callInstructionByteSize]
		ifFalse: [backEnd callInstructionByteSize])
]

{ #category : #'profiling primitives' }
Cogit >> positiveMachineIntegerFor: value [
	<var: #value type: #'usqIntptr_t'>
	<inline: true>
	^objectMemory wordSize = 8
		ifTrue: [coInterpreter positive64BitIntegerFor: value]
		ifFalse: [coInterpreter positive32BitIntegerFor: value]
]

{ #category : #'compile abstract instructions' }
Cogit >> preenMethodLabel [
	"The methodLabel serves as the reference to the start of the current code object
	 being produced (CMMethod, CMClosedPIC etc), but it also carries type flags for
	 the frame method field, set via the labelOffset.  So we must clean the flags on each
	 compilation to avoid stale lags being left behind from previous compilations."
	<inline: true>
	methodLabel setLabelOffset: 0
]

{ #category : #'compile abstract instructions' }
Cogit >> previousInstruction [
	<returnTypeC: #'AbstractInstruction *'>
	self assert: opcodeIndex > 0.
	^self abstractInstructionAt: opcodeIndex - 1
]

{ #category : #printing }
Cogit >> print: aString [
	<cmacro: '(aString) vm_printf("%s", aString)'>
	coInterpreter transcript print: aString
]

{ #category : #'method map' }
Cogit >> print: descriptor IsBackwardBranch: isBackwardBranch Mcpc: mcpc Bcpc: bcpc on: aStream [
	<doNotGenerate>
	aStream ensureCr.
	mcpc printOn: aStream base: 16.
	aStream
		space; tab;
		print: (isBackwardBranch ifTrue: [bcpc] ifFalse: [bcpc + descriptor numBytes]);
		cr; flush.
	^0
]

{ #category : #printing }
Cogit >> printCogMethodFor: address [
	<api>
	<var: #address type: #'void *'>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := methodZone methodFor: address.
	cogMethod = 0
		ifTrue: [(self codeEntryFor: address)
					ifNil: [coInterpreter print: 'not a method'; cr]
					ifNotNil: [coInterpreter print: 'trampoline '; print: (self codeEntryNameFor: address); cr]]
		ifFalse: [coInterpreter printCogMethod: cogMethod]
]

{ #category : #printing }
Cogit >> printCogMethodHeaderFor: address [
	<doNotGenerate>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := methodZone methodFor: address.
	cogMethod = 0
		ifTrue: [coInterpreter print: 'not a method'; cr]
		ifFalse: [self printMethodHeader: cogMethod on: coInterpreter transcript]
]

{ #category : #disassembly }
Cogit >> printInstructions [
	<doNotGenerate>
	^printInstructions
]

{ #category : #disassembly }
Cogit >> printInstructions: aBoolean [
	<doNotGenerate>
	printInstructions := aBoolean.
	singleStep := singleStep or: [aBoolean]
]

{ #category : #disassembly }
Cogit >> printMapEntry: annotation mcpc: mcpc args: tupleOfStreamCodeRangesAndMethod [
	"Print the Map entry's mcpc, its annotation and the corresponding bytecode pc, if any."
	<doNotGenerate>
	| printHex |
	printHex := disassemblingMethod
					ifNil: [[:pc| pc hex]]
					ifNotNil: [[:pc| '.+', (pc - disassemblingMethod asInteger printStringBase: 16 length: 4 padded: true)]].
	[:aStream :codeRanges :cogMethod|
	self startMcpcAndCogMethodForMcpc: mcpc in: cogMethod do:
		[:startmcpc :subMethod| | name codeRange |
		"Find the start of the block by searching the code ranges."
		codeRange := codeRanges detect: [:range| range includes: mcpc] ifNone: [codeRanges detect: [:range| range last + 1 = mcpc]].
		codeRange first = mcpc ifTrue:
			[aStream nextPutAll: 'startpc: '; print: codeRange startpc; cr].
		aStream
			next: 2 put: Character space;
			nextPutAll: (printHex value: mcpc);  space;
			nextPutAll: (name := self class annotationConstantNames at: annotation + 1);
			next: 20 - name size put: Character space;
			nextPut: $(;
			nextPutAll: (printHex value: (self findMapLocationForMcpc: mcpc inMethod: cogMethod)).
		(self isPCMappedAnnotation: annotation) ifTrue:
			[aStream
				nextPutAll: ', bc: ';
				print: (self bytecodePCFor: mcpc startBcpc: codeRange startpc in: subMethod)].
		(self isSendAnnotation: annotation) ifTrue:
			[| sel |
			sel := self selectorForSendAt: mcpc annotation: annotation in: cogMethod methodObject.
			sel isInteger ifTrue:
				[sel := self lookupAddress: sel].
			sel isString ifTrue:
				[aStream space; nextPutAll: sel]].
		aStream
			nextPut: $);
			cr; flush]]
		valueWithArguments: tupleOfStreamCodeRangesAndMethod.
	^0
]

{ #category : #disassembly }
Cogit >> printMethodHeader: cogMethod on: aStream [
	<doNotGenerate>
	self cCode: ''
		inSmalltalk:
			[cogMethod isInteger ifTrue:
				[^self printMethodHeader: (self cogMethodOrBlockSurrogateAt: cogMethod) on: aStream]].
	aStream ensureCr.
	cogMethod asInteger printOn: aStream base: 16.
	cogMethod cmType = CMMethod ifTrue:
		[aStream crtab; nextPutAll: 'objhdr: '.
		cogMethod objectHeader printOn: aStream base: 16].
	cogMethod cmType = CMBlock ifTrue:
		[aStream crtab; nextPutAll: 'homemth: '.
		cogMethod cmHomeMethod asUnsignedInteger printOn: aStream base: 16.
		aStream
			nextPutAll: ' (offset '; print: cogMethod homeOffset; nextPut: $);
			crtab; nextPutAll: 'startpc: '; print: cogMethod startpc].
	aStream
		crtab; nextPutAll: 'nArgs: ';	print: cogMethod cmNumArgs;
		tab;    nextPutAll: 'type: ';	print: cogMethod cmType.
	(cogMethod cmType ~= 0 and: [cogMethod cmType ~= CMBlock]) ifTrue:
		[aStream crtab; nextPutAll: 'blksiz: '.
		cogMethod blockSize printOn: aStream base: 16.
		cogMethod cmType = CMMethod ifTrue:
			[aStream crtab; nextPutAll: 'method: '.
			 cogMethod methodObject printOn: aStream base: 16.
			 aStream crtab; nextPutAll: 'mthhdr: '.
			 cogMethod methodHeader printOn: aStream base: 16].
		aStream crtab; nextPutAll: 'selctr: '.
		cogMethod selector printOn: aStream base: 16.
		(coInterpreter lookupAddress: cogMethod selector) ifNotNil:
			[:string| aStream nextPut: $=; nextPutAll: string].
		cogMethod selector = objectMemory nilObject ifTrue:
			[aStream space; nextPut: $(; nextPutAll: (coInterpreter stringOf: (coInterpreter maybeSelectorOfMethod: cogMethod methodObject)); nextPut: $)]. 
		cogMethod cmType = CMMethod ifTrue:
			[aStream crtab; nextPutAll: 'blkentry: '.
			 cogMethod blockEntryOffset printOn: aStream base: 16.
			 cogMethod blockEntryOffset ~= 0 ifTrue:
				[aStream nextPutAll: ' => '.
				 cogMethod asInteger + cogMethod blockEntryOffset printOn: aStream base: 16]]].
	cogMethod cmType = CMClosedPIC
		ifTrue:
			[aStream crtab; nextPutAll: 'cPICNumCases: '.
			 cogMethod cPICNumCases printOn: aStream base: 16.
			 aStream tab; nextPutAll: 'cpicHasMNUCase: ';
			 nextPutAll: (cogMethod cpicHasMNUCase ifTrue: ['yes'] ifFalse: ['no'])]
		ifFalse:
			[aStream crtab; nextPutAll: 'stackCheckOffset: '.
			 cogMethod stackCheckOffset printOn: aStream base: 16.
			 cogMethod stackCheckOffset > 0 ifTrue:
				[aStream nextPut: $/.
				 cogMethod asInteger + cogMethod stackCheckOffset printOn: aStream base: 16].
			cogMethod cmType = CMBlock
				ifTrue:
					[aStream
						crtab;
						nextPutAll: 'cbUsesInstVars ';
						nextPutAll: (cogMethod cbUsesInstVars ifTrue: ['yes'] ifFalse: ['no'])]
				ifFalse:
					[aStream
						crtab;
						nextPutAll: 'cmRefersToYoung: ';
						nextPutAll: (cogMethod cmRefersToYoung ifTrue: ['yes'] ifFalse: ['no']);
						tab;
						nextPutAll: 'cmIsFullBlock: ';
						nextPutAll: (cogMethod cmIsFullBlock ifTrue: ['yes'] ifFalse: ['no'])].
			cogMethod cmType = CMMethod ifTrue:
				[([cogMethod nextMethodOrIRCs] on: MessageNotUnderstood do: [:ex| nil]) ifNotNil:
					[:nmoircs| aStream crtab; nextPutAll: 'nextMethodOrIRCs: '.
						nmoircs = 0 ifTrue: [aStream print: nmoircs] ifFalse: [coInterpreter printHex: nmoircs]].
				 ([cogMethod counters] on: MessageNotUnderstood do: [:ex| nil]) ifNotNil:
					[:cntrs| aStream crtab; nextPutAll: 'counters: '.
						cntrs = 0 ifTrue: [aStream print: cntrs] ifFalse: [coInterpreter printHex: cntrs]]]].
	aStream cr; flush
]

{ #category : #printing }
Cogit >> printNum: n [
	<cmacro: '(n) vm_printf("%" PRIdSQINT, (sqInt) (n))'>
	coInterpreter transcript printNum: n
]

{ #category : #debugging }
Cogit >> printOnTrace [
	<api>
	<cmacro: '() (traceFlags & 1)'>
	^(traceFlags bitAnd: 1) ~= 0
]

{ #category : #'method map' }
Cogit >> printPCMapPairsFor: cogMethod [
	<doNotGenerate>
	"<api>
	<var: 'cogMethod' type: #'CogMethod *'>
	<var: 'mapByte' type: #'unsigned char'>"
	| mcpc map mapByte annotation value |
	mcpc := self firstMappedPCFor: cogMethod.
	map := self mapStartFor: cogMethod.
	[(mapByte := objectMemory byteAt: map) ~= MapEnd] whileTrue:
		[annotation := mapByte >> AnnotationShift.
		 annotation = IsAnnotationExtension
			ifTrue:
				[value := (mapByte bitAnd: DisplacementMask) + IsSendCall]
			ifFalse:
				[value := annotation.
				 mcpc := mcpc + (backEnd codeGranularity
									* (annotation = IsDisplacementX2N
										ifTrue: [mapByte - DisplacementX2N << AnnotationShift]
										ifFalse: [mapByte bitAnd: DisplacementMask]))].
		 coInterpreter
			printHexnp: map;
		 	print: ': '.
		 self
			cCode: [self print: '%02x' f: mapByte]
			inSmalltalk:
				[mapByte < 16 ifTrue:
					[coInterpreter putchar: $0].
				 coInterpreter printHexnp: mapByte].
		 coInterpreter
		 	printChar: $ ;
			printNum: annotation;
			print: ' ('.
		 (BytecodeSetHasDirectedSuperSend
		    and: [value between: IsDirectedSuperSend and: IsDirectedSuperBindingSend]) ifTrue:
			[value
				caseOf: {
					[IsDirectedSuperSend]			->	[coInterpreter print: 'DirectedSuperSend'].
					[IsDirectedSuperBindingSend]	->	[coInterpreter print: 'DirectedSuperBindingSend'] }] ifFalse:
		 [value
			caseOf: {
				[IsDisplacementX2N]		->	[coInterpreter print: 'DisplacementX2N'].
				[IsAnnotationExtension]	->	[coInterpreter print: 'AnnotationExtension'].
				[IsObjectReference]			->	[coInterpreter print: 'ObjectReference'].
				[IsAbsPCReference]			->	[coInterpreter print: 'AbsPCReference'].
				[HasBytecodePC]			->	[coInterpreter print: 'HasBytecodePC'].
				[IsRelativeCall]				->	[coInterpreter print: 'RelativeCall'].
				[IsSendCall]				->	[coInterpreter print: 'SendCall'].
				[IsSuperSend]				->	[coInterpreter print: 'SuperSend'] }
			otherwise: [coInterpreter print: '??? '; printHexnp: value]].
		 coInterpreter
			print: ') ';
			printHexnp: (mapByte bitAnd: DisplacementMask);
			printChar: $ ;
			putchar: $@;
		 printHex: mcpc;
		 cr;
		 flush.
		 map := map - 1]
]

{ #category : #'method map' }
Cogit >> printPCMapPairsFor: cogMethod on: aStream [
	<doNotGenerate>
	<inline: true>
	| mcpc map mapByte annotation |
	mcpc := self firstMappedPCFor: cogMethod.
	map := self mapStartFor: cogMethod.
	[(mapByte := objectMemory byteAt: map) ~= MapEnd] whileTrue:
		[annotation := mapByte >> AnnotationShift.
		 annotation ~= IsAnnotationExtension ifTrue:
			[mcpc := mcpc + (backEnd codeGranularity
								* (annotation = IsDisplacementX2N
									ifTrue: [mapByte - DisplacementX2N << AnnotationShift]
									ifFalse: [mapByte bitAnd: DisplacementMask]))].
		 aStream ensureCr.
		 map printOn: aStream base: 16.
		 aStream nextPutAll: ': '.
		 mapByte printOn: aStream base: 16 length: 2 padded: true.
		 aStream space.
		 annotation printOn: aStream base: 16.
		 aStream nextPutAll: ' ('; print: (AnnotationConstantNames at: annotation + 1); nextPutAll: ') '.
		 (mapByte bitAnd: DisplacementMask) printOn: aStream base: 16.
		 aStream space.
		 aStream nextPut: $@.
		 mcpc printOn: aStream base: 16.
		 aStream flush.
		 map := map - 1]
]

{ #category : #disassembly }
Cogit >> printRegisterMapOn: aStream [
	<doNotGenerate>
	| map n |
	map := backEnd generalPurposeRegisterMap.
	n := 0.
	(map keys asSortedCollection: [:a :b| (map at: a) < (map at: b)])
		do:	[:regName| | abstractName |
			abstractName := backEnd nameForRegister: (map at: regName).
			aStream nextPutAll: abstractName; nextPutAll: ' => '; nextPutAll: regName]
		separatedBy: [(n := n + 1) \\ 4 = 0 ifTrue: [aStream cr] ifFalse: [aStream tab]].
	aStream cr; flush
]

{ #category : #debugging }
Cogit >> printRegisters [
	<doNotGenerate>
	^printRegisters
]

{ #category : #debugging }
Cogit >> printRegisters: aBoolean [
	<doNotGenerate>
	printRegisters := aBoolean
]

{ #category : #debugging }
Cogit >> printTrampolineTable [
	<api>
	0 to: trampolineTableIndex - 1 by: 2 do:
		[:i|
		coInterpreter
			printHex: (trampolineAddresses at: i + 1) asInteger;
			print: ': ';
			print: (self cCoerceSimple: (trampolineAddresses at: i) to: #'char *');
			cr]
]

{ #category : #accessing }
Cogit >> processor [
	<doNotGenerate>
	^processor
]

{ #category : #initialization }
Cogit >> processorHasDivQuoRemAndMClassIsSmallInteger [
	^backEnd canDivQuoRem and: [self mclassIsSmallInteger]
]

{ #category : #initialization }
Cogit >> processorHasDoublePrecisionFloatingPointSupport [
	<option: #DPFPReg0>
	<inline: true>
	^backEnd hasDoublePrecisionFloatingPointSupport
]

{ #category : #initialization }
Cogit >> processorHasMultiplyAndMClassIsSmallInteger [
	^backEnd canMulRR and: [self mclassIsSmallInteger]
]

{ #category : #'profiling primitives' }
Cogit >> profileDataFor: cogMethod withDetails: withDetails [
	"Answers characteristic data for the type of the cogMethod, answering
		a CompiledMethod for a compiled method,
		a selector for an open PIC
		if withDetails then an array containing a selector followed by pairs of class and target method for a closed PIC, otherwise simply a selector."
	<inline: true>
	<var: #cogMethod type: #'CogMethod *'>
	^cogMethod cmType = CMMethod 
		ifTrue: [cogMethod methodObject]
		ifFalse: [(withDetails and: [cogMethod cmType = CMClosedPIC])
					ifTrue: [self createCPICData: cogMethod]
					ifFalse: [cogMethod selector]]
]

{ #category : #'simulation only' }
Cogit >> promptForBreakPC [
	<doNotGenerate>
	| s first pc |
	s := UIManager default request: 'Break pc (hex, + to add, - to remove)'.
	s := s withBlanksTrimmed.
	s isEmpty ifTrue: [^self].
	('+-' includes: s first) ifTrue: [first := s first. s := s allButFirst].
	(s isEmpty and: [first = $-]) ifTrue:
		[^self breakPC: nil].
	pc := (s includes: $r)
			ifTrue:
				[Number readFrom: s readStream]
			ifFalse:
				[(#('0x' '-0x') detect: [:prefix| s beginsWith: prefix] ifNone: []) ifNotNil:
					[:prefix|
					s := s allButFirst: prefix size.
					prefix first = $- ifTrue: [s := '-', s]].
				Integer readFrom: s readStream base: 16].
	first = $+ ifTrue:
		[^self breakPC: (breakPC addBreakpoint: pc)].
	first = $- ifTrue:
		[^self breakPC: (breakPC removeBreakpoint: pc)].
	self breakPC: pc
]

{ #category : #'as yet unclassified' }
Cogit >> receiverTags: anInteger [ 
	receiverTags := anInteger
]

{ #category : #debugging }
Cogit >> recordBlockTrace [
	<api>
	<cmacro: '() (traceFlags & 4)'>
	^(traceFlags bitAnd: 4) ~= 0
]

{ #category : #debugging }
Cogit >> recordEventTrace [
	<api>
	<cmacro: '() (traceFlags & 16)'>
	^(traceFlags bitAnd: 16) ~= 0
]

{ #category : #initialization }
Cogit >> recordGeneratedRunTime: aString address: address [
	<var: #aString type: #'char *'>
	trampolineAddresses
		at: trampolineTableIndex put: aString;
		at: trampolineTableIndex + 1 put: (self cCoerceSimple: address to: #'char *').
	trampolineTableIndex := trampolineTableIndex + 2
]

{ #category : #'simulation only' }
Cogit >> recordInstruction: thing [
	<doNotGenerate>
	lastNInstructions addLast: thing.
	[lastNInstructions size > 160"80"] whileTrue:
		[lastNInstructions removeFirst.
		 lastNInstructions size * 2 > lastNInstructions capacity ifTrue:
			[lastNInstructions makeRoomAtLast]].
	^thing
]

{ #category : #'simulation only' }
Cogit >> recordLastInstruction [
	<doNotGenerate>
	| inst pc |
	(EagerInstructionDecoration or: [printInstructions])
		ifTrue:
			[inst := processor
						disassembleNextInstructionIn: coInterpreter memory
						for: self.
			 printInstructions ifTrue:
				[pc := Integer readFrom: (ReadStream on: inst from: 1 to: (inst indexOf: $:) - 1) base: 16.
				 (self relativeLabelForPC: pc) ifNotNil:
					[:label| inst := inst, ' ', label]]]
		ifFalse:
			[inst := processor
						disassembleNextInstructionIn: coInterpreter memory
						for: nil].
	^self recordInstruction: inst
]

{ #category : #debugging }
Cogit >> recordOverflowTrace [
	<api>
	<cmacro: '() (traceFlags & 32)'>
	^(traceFlags bitAnd: 32) ~= 0
]

{ #category : #debugging }
Cogit >> recordPrimTrace [
	<api>
	<cmacro: '() (traceFlags & 8)'>
	^(traceFlags bitAnd: 8) ~= 0
]

{ #category : #debugging }
Cogit >> recordPrimTraceFunc [
	"This one for C support code."
	<api>
	^self recordPrimTrace
]

{ #category : #'simulation only' }
Cogit >> recordProcessing [
	| inst |
	self recordRegisters.
	inst := self recordLastInstruction.
	"Set RRRName ito the selector that accesses ReceiverResultReg (RRR) to alter instruction printing to add the value of RRR as a suffix
		(RRRName := #rdx)
		(RRRName := #edx)
		(RRRName := nil)"
	printRegisters ifTrue:
		[RRRName ifNil: [processor printRegistersOn: coInterpreter transcript].
		 printInstructions ifFalse:
			[coInterpreter transcript cr]].
	printInstructions ifTrue:
		[printRegisters ifTrue:
			[coInterpreter transcript cr].
		 coInterpreter transcript nextPutAll: inst.
		 RRRName ifNotNil:
			[coInterpreter transcript space; nextPutAll: RRRName; space.
			 (processor perform: RRRName) printOn: coInterpreter transcript base: 16 length: 8 padded: false].
		 coInterpreter transcript cr; flush]
]

{ #category : #'simulation only' }
Cogit >> recordRegisters [
	<doNotGenerate>
	self recordInstruction: processor integerRegisterState
	"self recordInstruction: processor registerState"
]

{ #category : #initialization }
Cogit >> recordRunTimeObjectReferences [
	<var: #instruction type: #'AbstractInstruction *'>
	0 to: opcodeIndex - 1 do:
		[:i| | instruction |
		instruction := self abstractInstructionAt: i.
		instruction annotation = IsObjectReference ifTrue:
			[self assert: runtimeObjectRefIndex < NumObjRefsInRuntime.
			 self assert: hasYoungReferent not.
			 hasYoungReferent ifTrue:
				[self error: 'attempt to generate run-time routine containing young object reference.  Cannot initialize Cogit run-time.'].
			 objectReferencesInRuntime
				at: runtimeObjectRefIndex
				put: instruction mapEntryAddress asUnsignedInteger.
			 runtimeObjectRefIndex := runtimeObjectRefIndex + 1]]
]

{ #category : #debugging }
Cogit >> recordSendTrace [
	<api>
	<cmacro: '() (traceFlags & 2)'>
	^(traceFlags bitAnd: 2) ~= 0
]

{ #category : #'register management' }
Cogit >> registerMaskFor: reg [
	<inline: true>
	^1 << reg
]

{ #category : #'register management' }
Cogit >> registerMaskFor: reg1 and: reg2 [
	<inline: true>
	^1 << reg1 bitOr: 1 << reg2
]

{ #category : #'register management' }
Cogit >> registerMaskFor: reg1 and: reg2 and: reg3 [
	<inline: true>
	^(1 << reg1 bitOr: 1 << reg2) bitOr: 1 << reg3
]

{ #category : #'register management' }
Cogit >> registerMaskFor: reg1 and: reg2 and: reg3 and: reg4 [
	<inline: true>
	^((1 << reg1 bitOr: 1 << reg2) bitOr: 1 << reg3) bitOr: 1 << reg4
]

{ #category : #'register management' }
Cogit >> registerMaskFor: reg1 and: reg2 and: reg3 and: reg4 and: reg5 [
	<inline: true>
	^(((1 << reg1 bitOr: 1 << reg2) bitOr: 1 << reg3) bitOr: 1 << reg4) bitOr: 1 << reg5
]

{ #category : #'register management' }
Cogit >> registerMaskFor: reg1 and: reg2 and: reg3 and: reg4 and: reg5 and: reg6 [
	<inline: true>
	^((((1 << reg1 bitOr: 1 << reg2) bitOr: 1 << reg3) bitOr: 1 << reg4) bitOr: 1 << reg5) bitOr: 1 << reg6
]

{ #category : #'register management' }
Cogit >> registerMaskFor: reg1 and: reg2 and: reg3 and: reg4 and: reg5 and: reg6 and: reg7 [
	<inline: true>
	^(((((1 << reg1 bitOr: 1 << reg2) bitOr: 1 << reg3) bitOr: 1 << reg4) bitOr: 1 << reg5) bitOr: 1 << reg6) bitOr: 1 << reg7
]

{ #category : #'register management' }
Cogit >> registerMaskFor: reg1 and: reg2 and: reg3 and: reg4 and: reg5 and: reg6 and: reg7 and: reg8 [
	<inline: true>
	^((((((1 << reg1 bitOr: 1 << reg2) bitOr: 1 << reg3) bitOr: 1 << reg4) bitOr: 1 << reg5) bitOr: 1 << reg6) bitOr: 1 << reg7) bitOr: 1 << reg8
]

{ #category : #'register management' }
Cogit >> registerMaskFor: reg1 and: reg2 and: reg3 and: reg4 and: reg5 and: reg6 and: reg7 and: reg8 and: reg9 [
	<inline: true>
	^(((((((1 << reg1 bitOr: 1 << reg2) bitOr: 1 << reg3) bitOr: 1 << reg4) bitOr: 1 << reg5) bitOr: 1 << reg6) bitOr: 1 << reg7) bitOr: 1 << reg8) bitOr: 1 << reg9
]

{ #category : #'register management' }
Cogit >> registerMaskFor: reg1 and: reg2 and: reg3 and: reg4 and: reg5 and: reg6 and: reg7 and: reg8 and: reg9 and: reg10 [
	<inline: true>
	^((((((((1 << reg1 bitOr: 1 << reg2) bitOr: 1 << reg3) bitOr: 1 << reg4) bitOr: 1 << reg5) bitOr: 1 << reg6) bitOr: 1 << reg7) bitOr: 1 << reg8) bitOr: 1 << reg9) bitOr: 1 << reg10
]

{ #category : #disassembly }
Cogit >> relativeBaseForDisassemblyInto: aBlock [
	<doNotGenerate>
	disassemblingMethod ifNotNil:
		[aBlock value: disassemblingMethod asInteger value: '.']
]

{ #category : #disassembly }
Cogit >> relativeLabelForPC: pc [ 
	<doNotGenerate>
	pc < methodZone limitZony ifFalse:
		[^nil].
	pc < methodZoneBase ifTrue:
		[^(self codeEntryNameFor: pc) ifNotNil:
			[:name| name, '+', (pc - (self codeEntryFor: pc)) printString]].
	^self lookupAddress: pc
]

{ #category : #compaction }
Cogit >> relocateCallsAndSelfReferencesInMethod: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	| refDelta callDelta |
	refDelta := cogMethod objectHeader.
	callDelta := backEnd zoneCallsAreRelative ifTrue: [refDelta] ifFalse: [0].
	
	self assert: (cogMethod cmType = CMMethod or: [cogMethod cmType = CMOpenPIC]).
	self assert: (backEnd callTargetFromReturnAddress: cogMethod asInteger + missOffset)
				= (cogMethod cmType = CMMethod
					ifTrue: [self methodAbortTrampolineFor: cogMethod cmNumArgs]
					ifFalse: [self picAbortTrampolineFor: cogMethod cmNumArgs]).
	backEnd relocateCallBeforeReturnPC: cogMethod asInteger + missOffset by: callDelta negated.
	self mapFor: cogMethod
		performUntil: #relocateIfCallOrMethodReference:mcpc:delta:
		arg: refDelta
]

{ #category : #compaction }
Cogit >> relocateCallsInClosedPIC: cPIC [
	<var: #cPIC type: #'CogMethod *'>
	| refDelta callDelta pc entryPoint targetMethod |
	<var: #targetMethod type: #'CogMethod *'>
	refDelta := cPIC objectHeader.
	callDelta := backEnd zoneCallsAreRelative ifTrue: [refDelta] ifFalse: [0].
	
	self assert: (backEnd callTargetFromReturnAddress: cPIC asInteger + missOffset)
					= (self picAbortTrampolineFor: cPIC cmNumArgs).
	backEnd relocateCallBeforeReturnPC: cPIC asInteger + missOffset by: callDelta negated.

	pc := cPIC asInteger + firstCPICCaseOffset.
	1 to: cPIC cPICNumCases do:
		[:i|
		pc := self addressOfEndOfCase: i inCPIC: cPIC.
		entryPoint := i = 1
						ifTrue: [backEnd jumpLongTargetBeforeFollowingAddress: pc]
						ifFalse: [backEnd jumpLongConditionalTargetBeforeFollowingAddress: pc].
		(cPIC containsAddress: entryPoint) 
			ifTrue: 
			["Interpret/MNU"
			backEnd zoneCallsAreRelative ifFalse: [
				i = 1 ifTrue:
					[backEnd
						relocateJumpLongBeforeFollowingAddress: pc
						by: refDelta]
					ifFalse:
					[backEnd
						relocateJumpLongConditionalBeforeFollowingAddress: pc
						by: refDelta]]]
			ifFalse:
			[targetMethod := self cCoerceSimple: entryPoint - cmNoCheckEntryOffset to: #'CogMethod *'.
			 self assert: targetMethod cmType = CMMethod.
			 i = 1 ifTrue:
				[backEnd
					relocateJumpLongBeforeFollowingAddress: pc
					by: (callDelta - targetMethod objectHeader) negated]
				ifFalse:
				[backEnd
					relocateJumpLongConditionalBeforeFollowingAddress: pc
					by: (callDelta - targetMethod objectHeader) negated]]].
	self assert: cPIC cPICNumCases > 0.

	"Finally relocate the load of the PIC and the jump to the overflow routine ceCPICMiss:receiver:"
	backEnd relocateMethodReferenceBeforeAddress: (self addressOfEndOfCase: 2 inCPIC: cPIC)+ backEnd loadPICLiteralByteSize by: refDelta.
	backEnd relocateJumpLongBeforeFollowingAddress: cPIC asInteger + cPICEndOfCodeOffset by: callDelta negated
]

{ #category : #compaction }
Cogit >> relocateIfCallOrMethodReference: annotation mcpc: mcpc delta: refDelta [
	<var: #mcpc type: #'char *'>
	<var: #targetMethod type: #'CogMethod *'>
	
	| callDelta entryPoint targetMethod unlinkedRoutine |

	callDelta := backEnd zoneCallsAreRelative ifTrue: [refDelta] ifFalse: [0].

	(self isPureSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		entryPoint <= methodZoneBase ifTrue: "send is not linked; just relocate"
			[backEnd relocateCallBeforeReturnPC: mcpc asInteger by: callDelta negated.
			 ^0].
		"It's a linked send; find which kind."
		self
			offsetAndSendTableFor: entryPoint
			annotation: annotation
			into: [:offset :sendTable|
				 targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
				 targetMethod cmType ~= CMFree ifTrue: "send target not freed; just relocate."
					[backEnd
						relocateCallBeforeReturnPC: mcpc asInteger
						by: (callDelta - targetMethod objectHeader) negated.
					 SistaVM ifTrue: "See comment in planCompaction"
						[methodZone restorePICUsageCount: targetMethod].
					 ^0].
				 "Target was freed; map back to an unlinked send; but include this method's reocation"
				 unlinkedRoutine := sendTable at: (targetMethod cmNumArgs min: NumSendTrampolines - 1).
				 unlinkedRoutine := unlinkedRoutine - callDelta.
				 backEnd
					rewriteInlineCacheAt: mcpc asInteger
					tag: (self inlineCacheValueForSelector: targetMethod selector in: enumeratingCogMethod at: mcpc)
					target: unlinkedRoutine.
				 ^0]].

	annotation = IsRelativeCall ifTrue:
		[backEnd relocateCallBeforeReturnPC: mcpc asInteger by: callDelta negated.
		 ^0].

	annotation = IsAbsPCReference ifTrue:
		[backEnd relocateMethodReferenceBeforeAddress: mcpc asInteger by: refDelta].

	^0 "keep scanning"
]

{ #category : #'garbage collection' }
Cogit >> remapIfObjectRef: annotation pc: mcpc hasYoung: hasYoungPtr [
	<var: #mcpc type: #'char *'>
	<var: #targetMethod type: #'CogMethod *'>
	annotation = IsObjectReference ifTrue:
		[| literal mappedLiteral |
		 literal := literalsManager fetchLiteralAtAnnotatedAddress: mcpc asUnsignedInteger using: backEnd.
		 (objectRepresentation couldBeObject: literal) ifTrue:
			[mappedLiteral := objectRepresentation remapObject: literal.
			 literal ~= mappedLiteral ifTrue:
				[literalsManager storeLiteral: mappedLiteral atAnnotatedAddress: mcpc asUnsignedInteger using: backEnd.
				 codeModified := true].
			 (hasYoungPtr ~= 0
			  and: [objectMemory isYoung: mappedLiteral]) ifTrue:
				[(self cCoerceSimple: hasYoungPtr to: #'sqInt *') at: 0 put: true]]].

	(self isPureSendAnnotation: annotation) ifTrue:
		[self entryCacheTagAndCouldBeObjectAt: mcpc annotation: annotation into:
			[:entryPoint :cacheTag :tagCouldBeObj | | mappedCacheTag |
			 (tagCouldBeObj
			  and: [objectRepresentation couldBeObject: cacheTag]) ifTrue:
				[mappedCacheTag := objectRepresentation remapObject: cacheTag.
				 cacheTag ~= mappedCacheTag ifTrue:
					[backEnd rewriteInlineCacheTag: mappedCacheTag at: mcpc asUnsignedInteger.
					 codeModified := true].
				 (hasYoungPtr ~= 0
				  and: [objectMemory isYoung: mappedCacheTag]) ifTrue:
					[(self cCoerceSimple: hasYoungPtr to: #'sqInt *') at: 0 put: true]].
			hasYoungPtr ~= 0 ifTrue:
				["Since the unlinking routines may rewrite the cacheTag to the send's selector, and
				  since they don't have the cogMethod to hand and can't add it to youngReferrers,
				  the method must remain in youngReferrers if the targetMethod's selector is young."
				 entryPoint > methodZoneBase ifTrue: "It's a linked send."
					[self targetMethodAndSendTableFor: entryPoint annotation: annotation into:
						[:targetMethod :ignored|
						 (objectMemory isYoung: targetMethod selector) ifTrue:
							[(self cCoerceSimple: hasYoungPtr to: #'sqInt *') at: 0 put: true]]]]]].
	^0 "keep scanning"
]

{ #category : #'garbage collection' }
Cogit >> remapMaybeObjRefInClosedPICAt: mcpc [
	"Remap a potential object reference from a closed PIC.
	 This may be an object reference, an inline cache tag or null.
	 Answer if the updated literal is young.
	 mcpc is the address of the next instruction following either
	 the load of the method literal or the compare of the class tag."
	| object subject |
	object := backEnd literalBeforeFollowingAddress: mcpc.
	(objectRepresentation couldBeObject: object) ifFalse:
		[^false].
	subject := objectRepresentation remapOop: object.
	object ~= subject ifTrue:
		[backEnd storeLiteral: subject beforeFollowingAddress: mcpc.
		 codeModified := true].
	^objectMemory isYoungObject: subject
]

{ #category : #'translation support' }
Cogit >> reportError: anInteger [
	<cmacro: '(n) warning("compilation error")'>
	self halt: 'Compilation error ', anInteger printString
]

{ #category : #debugging }
Cogit >> reportLastNInstructions [
	<doNotGenerate>
	| skipNext printInst |
	skipNext := false.
	printInst := [:inst|
				coInterpreter transcript nextPutAll:
					(EagerInstructionDecoration
						ifTrue: [inst]
						ifFalse: [processor
									decorateDisassembly: inst
									for: self
									fromAddress: ((inst at: 3) = $r
													ifTrue: [Integer readFrom: inst readStream]
													ifFalse: [Integer readFrom: inst readStream base: 16])]); cr].
	lastNInstructions withIndexDo:
		[:thing :idx| | next pc label |
		skipNext
			ifTrue: [skipNext := false]
			ifFalse:
				[thing isArray
					ifTrue:
						[thing first isString "i.e. { '(simulated return to '. processor retpcIn: coInterpreter memory. ')'}"
							ifTrue:
								[thing do:
									[:stringOrNumber|
									coInterpreter transcript nextPutAll: (stringOrNumber isString
															ifTrue: [stringOrNumber]
															ifFalse: [stringOrNumber hex])].
									coInterpreter transcript cr]
							ifFalse: "if possible, add the label to the instruction line to condense the output"
								[coInterpreter transcript cr.
								 pc := thing at: processor registerStatePCIndex.
								 label := self relativeLabelForPC: pc.
								 ((next := lastNInstructions at: idx + 1 ifAbsent: []) notNil
								  and: [next isString
								  and: [(Integer readFrom: next readStream radix: 16) = pc]])
									ifTrue: "Decorate instruction and eliminate pc line"
										[skipNext := true.
										 processor printRegisterStateExceptPC: thing on: coInterpreter transcript.
										 label ifNotNil: [coInterpreter transcript nextPutAll: label; space].
										 printInst value: next]
									ifFalse:
										[label ifNotNil: [coInterpreter transcript nextPutAll: label; nextPut: $:; cr].
										 processor printRegisterState: thing on: coInterpreter transcript]]]
					ifFalse:
						[printInst value: thing]]].
	coInterpreter transcript flush
]

{ #category : #'tests-method map' }
Cogit >> resolveToOopOrNil: proxyOrSpecialSelector [
	"Answer the oop of a proxy or a special selector.  When testing pc mapping on simulation
	 methods (as opposed to CurrentImageFacades) selectorForSendBefore:in: answers either
	 VMObjectProxy instances (normal sends) or symbols (special selector sends)."
	<doNotGenerate>
	| index |
	proxyOrSpecialSelector isSymbol ifFalse:
		[^proxyOrSpecialSelector oop].
	index := Smalltalk specialSelectors indexOf: proxyOrSpecialSelector.
	^index > 0 ifTrue:
		[coInterpreter specialSelector: index - 1 // 2]
]

{ #category : #'in-line cacheing' }
Cogit >> rewriteCPIC: cPIC caseJumpTo: target [ 
	"adding a new CPIC case, or making an MNU CPIC, requires altering the jump that takes us to the first case to be used"
	<inline: true>
	backEnd rewriteCPICJumpAt: cPIC asInteger + firstCPICCaseOffset - backEnd jumpLongByteSize - backEnd loadLiteralByteSize target: target
]

{ #category : #'in-line cacheing' }
Cogit >> rewriteCPICCaseAt: followingAddress tag: newTag objRef: newObjRef target: newTarget [
	"Rewrite the three values involved in a CPIC case.  Used by the initialize & extend CPICs.
	 c.f. expectedClosedPICPrototype:"

	"write the obj ref/operand via the second ldr"
	| classTagPC methodObjPC |
	methodObjPC := followingAddress - backEnd jumpLongConditionalByteSize - backEnd cmpC32RTempByteSize.
	backEnd storeLiteral: newObjRef beforeFollowingAddress: methodObjPC.

	classTagPC := followingAddress - backEnd jumpLongConditionalByteSize.
	"rewite the tag via the first ldr"	
	backEnd storeLiteral32: newTag beforeFollowingAddress: classTagPC.

	"write the jump address for the new target address"
	backEnd rewriteJumpLongAt: followingAddress target: newTarget
]

{ #category : #'compile abstract instructions' }
Cogit >> scanBlock: blockStart [
	"Scan the block to determine if the block needs a frame or not"
	| descriptor pc end framelessStackDelta nExts |
	<var: #blockStart type: #'BlockStart *'>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	needsFrame := false.
	methodOrBlockNumArgs := blockStart numArgs.
	inBlock := InVanillaBlock.
	pc := blockStart startpc.
	end := blockStart startpc + blockStart span.
	framelessStackDelta := nExts := extA := numExtB := extB := 0.
	[pc < end] whileTrue:
		[byte0 := (objectMemory fetchByte: pc ofObject: methodObj) + bytecodeSetOffset.
		 descriptor := self generatorAt: byte0.
		 descriptor isExtension ifTrue:
			[self loadSubsequentBytesForDescriptor: descriptor at: pc.
			 self perform: descriptor generator].
		 needsFrame ifFalse:
			[(descriptor needsFrameFunction isNil
			  or: [self perform: descriptor needsFrameFunction with: framelessStackDelta])
				ifTrue: [needsFrame := true]
				ifFalse: [framelessStackDelta := framelessStackDelta + descriptor stackDelta]].
		 objectRepresentation maybeNoteDescriptor: descriptor blockStart: blockStart.
		 pc := self nextBytecodePCFor: descriptor at: pc exts: nExts in: methodObj.
		 descriptor isExtension
			ifTrue: [nExts := nExts + 1]
			ifFalse: [nExts := extA := numExtB := 0. extB := 0]].
	needsFrame ifFalse:
		[framelessStackDelta < 0 ifTrue:
			[self error: 'negative stack delta in block; block contains bogus code or internal error'].
		 [framelessStackDelta > 0] whileTrue:
			[descriptor := self generatorAt: (objectMemory fetchByte: blockStart startpc ofObject: methodObj) + bytecodeSetOffset.
			 descriptor generator ~~ #genPushConstantNilBytecode ifTrue:
				[self error: 'frameless block doesn''t start with enough pushNils'].
			 blockStart
				startpc: blockStart startpc + descriptor numBytes;
				span: blockStart span - descriptor numBytes.
			 framelessStackDelta := framelessStackDelta - 1]].
	^0
]

{ #category : #'compile abstract instructions' }
Cogit >> scanForCleanBlocks [
	"Answer the number of clean blocks found in the literal frame"
	| numCleanBlocks |
	numCleanBlocks := 0.
	1 to: (objectMemory literalCountOf: methodObj) do:
		[:i| | lit |
		lit := objectMemory fetchPointer: i ofObject: methodObj.
		(coInterpreter startPCOrNilOfLiteral: lit in: methodObj) ifNotNil:
			[:startPCOrNil| numCleanBlocks := numCleanBlocks + 1]].
	^numCleanBlocks
]

{ #category : #'compile abstract instructions' }
Cogit >> scanMethod [
	"Scan the method (and all embedded blocks) to determine
		- what the last bytecode is; extra bytes at the end of a method are used to encode things like source pointers or temp names
		- if the method needs a frame or not
		- what are the targets of any backward branches.
		- how many blocks it creates
		- if it contans an unknown bytecode
	 Answer the block count or on error a negative error code"
	| latestContinuation nExts descriptor pc numBlocks distance targetPC framelessStackDelta |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	needsFrame := false.
	(primitiveIndex > 0
	 and: [coInterpreter isQuickPrimitiveIndex: primitiveIndex]) ifTrue:
		[^0].
	pc := latestContinuation := initialPC.
	numBlocks := framelessStackDelta := nExts := extA := numExtB := extB := 0.
	[pc <= endPC] whileTrue:
		[byte0 := (objectMemory fetchByte: pc ofObject: methodObj) + bytecodeSetOffset.
		 descriptor := self generatorAt: byte0.
		 descriptor isExtension ifTrue:
			[descriptor opcode = Nop ifTrue: "unknown bytecode tag; see Cogit class>>#generatorTableFrom:"
				[^EncounteredUnknownBytecode].
			 self loadSubsequentBytesForDescriptor: descriptor at: pc.
			 self perform: descriptor generator].
		 (descriptor isReturn
		  and: [pc >= latestContinuation]) ifTrue:
			[endPC := pc].
		 needsFrame ifFalse:
			[(descriptor needsFrameFunction isNil
			  or: [self perform: descriptor needsFrameFunction with: framelessStackDelta])
				ifTrue: [needsFrame := true]
				ifFalse: [framelessStackDelta := framelessStackDelta + descriptor stackDelta]].
		 descriptor isBranch ifTrue:
			[distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 (self isBackwardBranch: descriptor at: pc exts: nExts in: methodObj)
				ifTrue: [self initializeFixupAt: targetPC]
				ifFalse: [latestContinuation := latestContinuation max: targetPC]].
		 descriptor isBlockCreation ifTrue:
			[numBlocks := numBlocks + 1.
			 distance := self spanFor: descriptor at: pc exts: nExts in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 latestContinuation := latestContinuation max: targetPC].
		 pc := pc + descriptor numBytes.
		 descriptor isExtension
			ifTrue: [nExts := nExts + 1]
			ifFalse: [nExts := extA := numExtB := extB := 0]].
	^numBlocks
]

{ #category : #'simulation only' }
Cogit >> selectorForSendAt: mcpc annotation: annotation in: aCompiledMethod [
	<doNotGenerate>
	| entryPoint offset targetMethod selector |
	entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
	selector := entryPoint > methodZoneBase
					ifTrue: "It's a linked send."
						[self
							offsetAndSendTableFor: entryPoint
							annotation: annotation
							into: [:off :table| offset := off].
						targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
						targetMethod selector]
					ifFalse:
						[self inlineCacheTagsAreIndexes
							ifTrue: [self selectorFromSelectorIndex: (backEnd inlineCacheTagAt: mcpc) signedIntFromLong
										in: aCompiledMethod]
							ifFalse: [backEnd inlineCacheTagAt: mcpc]].
	^(annotation ~= IsNSSendCall and: [coInterpreter isCurrentImageFacade])
		ifTrue: [coInterpreter objectForOop: selector]
		ifFalse: [selector]
]

{ #category : #'simulation only' }
Cogit >> selectorForSendBefore: bcpc in: aCompiledMethod [
	<doNotGenerate>
	| is sel |
	"sends map to the following pc.  need to find the selector for the previous pc"
	is := InstructionStream on: aCompiledMethod.
	is pc: (aCompiledMethod pcPreviousTo: bcpc + 1). "bcpc is 0-rel"
	^(sel := is selectorToSendOrSelf) ~~ is ifTrue: [sel]
]

{ #category : #'in-line cacheing' }
Cogit >> selectorFromSelectorIndex: selectorIndex in: aCompiledMethod [
	<inline: true>
	^selectorIndex < 0
		ifTrue: [(coInterpreter specialSelector: -1 - selectorIndex)]
		ifFalse: [coInterpreter literal: selectorIndex ofMethod: aCompiledMethod]
]

{ #category : #analysis }
Cogit >> sendSitesIn: cogMethod do: binaryBlock [
	"Evaluate binaryBlock with the annotation and mcpc for each send site in cogMethod"
	<doNotGenerate>
	self mapFor: cogMethod
		 performUntil: (#withAnnotation:mcpc:evaluate:)
		 arg: [:ann :mcpc | (self isSendAnnotation: ann) ifTrue: [binaryBlock value: ann value: mcpc]]
]

{ #category : #debugging }
Cogit >> sendTrace [
	<doNotGenerate>
	^traceFlags
]

{ #category : #debugging }
Cogit >> sendTrace: aBooleanOrInteger [
	<doNotGenerate>
	"traceFlags is a set of flags.
	 1 => print trace (if something below is selected)
	 2 => trace sends
	 4 => trace block activations
	 8 => trace interpreter primitives
	 16 => trace events (context switches, GCs, etc)
	 32 => trace stack overflow
	 64 => unused
	128 => check stack depth on send (simulation only)
	256 => trace linked sends "
	traceFlags := aBooleanOrInteger isInteger
							ifTrue: [aBooleanOrInteger]
							ifFalse: [aBooleanOrInteger ifTrue: [6] ifFalse: [0]]
]

{ #category : #debugging }
Cogit >> setBreakMethod: anObj [
	<api>
	breakMethod := anObj
]

{ #category : #accessing }
Cogit >> setCFramePointer: aFramePointer [
	<api>
	<cmacro: '(theFP) (CFramePointer = (void *)(theFP))'>
	"and in the simulator we use..."
	^(backEnd wantsNearAddressFor: #CFramePointer)
		ifTrue: [CFramePointer := aFramePointer]
		ifFalse: [(objectMemory
					longAt: coInterpreter inMemoryCFramePointerAddress
					put: aFramePointer) asVoidPointer]
]

{ #category : #accessing }
Cogit >> setCStackPointer: aStackPointer [
	<api>
	<cmacro: '(theSP) (CStackPointer = (void *)(theSP))'>
	"and in the simulator we use..."
	^(backEnd wantsNearAddressFor: #CStackPointer)
		ifTrue: [CStackPointer := aStackPointer]
		ifFalse: [(objectMemory
					longAt: coInterpreter inMemoryCStackPointerAddress
					put: aStackPointer) asVoidPointer]
]

{ #category : #'simulation only' }
Cogit >> setClickStepBreakBlock [
	"Set the break block to present a confirmer, breaking if true, and restoring the previous break block.
	 If an open debugger on the receiver can be found, proceed it."
	<doNotGenerate>
	| previousBreakBlock previousAtEachStepBlock previousBreakPC previousSingleStep previousClickConfirm |
	(breakBlock isNil or: [breakBlock method ~~ thisContext method]) ifTrue:
		[previousBreakBlock := breakBlock.
		 previousAtEachStepBlock := coInterpreter atEachStepBlock.
		 previousBreakPC := breakPC.
		 previousSingleStep := singleStep.
		 previousClickConfirm := clickConfirm.
		 breakBlock := [:ign|
						(processor pc ~= previousBreakPC
						 and: [UIManager confirm: 'step?'])
							ifTrue: [false]
							ifFalse: [breakBlock := previousBreakBlock.
									coInterpreter atEachStepBlock: previousAtEachStepBlock.
									breakPC := previousBreakPC.
									singleStep := previousSingleStep.
									clickConfirm := previousClickConfirm.
									true]].
		 coInterpreter atEachStepBlock:
								[previousAtEachStepBlock value.
								 (coInterpreter localIP ~= previousBreakPC
								  and: [UIManager confirm: 'step?']) ifFalse:
									[breakBlock := previousBreakBlock.
									coInterpreter atEachStepBlock: previousAtEachStepBlock.
									breakPC := previousBreakPC.
									singleStep := previousSingleStep.
									clickConfirm := previousClickConfirm.
									self halt]].
		 singleStep := breakPC := clickConfirm := true].
	(World submorphs
		detect:
			[:m|
			 m model class == Debugger
			 and: [(m model interruptedProcess suspendedContext findContextSuchThat:
					[:ctxt|
					(ctxt receiver == self
					 and: [ctxt selector == #simulateCogCodeAt:])
					or: [ctxt receiver == coInterpreter
					 and: [ctxt selector == #interpret]]]) notNil]]
		ifNone: []) ifNotNil:
			[:debuggerWindow|
			 WorldState addDeferredUIMessage:
				[debuggerWindow model proceed]]
]

{ #category : #initialization }
Cogit >> setInterpreter: aCoInterpreter [
	"Initialization of the code generator in the simulator.
	 These objects already exist in the generated C VM
	 or are used only in the simulation."
	<doNotGenerate>
	coInterpreter := aCoInterpreter.
	objectMemory := aCoInterpreter objectMemory.
	threadManager := aCoInterpreter threadManager. "N.B. may be nil"
	methodZone := self class methodZoneClass new.
	objectRepresentation := objectMemory objectRepresentationClass
								forCogit: self methodZone: methodZone.
	methodZone setInterpreter: aCoInterpreter
				objectRepresentation: objectRepresentation
				cogit: self.
	generatorTable := self class generatorTable.
	processor := ProcessorClass new.
	simulatedAddresses := Dictionary new.
	simulatedTrampolines := Dictionary new.
	simulatedVariableGetters := Dictionary new.
	simulatedVariableSetters := Dictionary new.
	traceStores := 0.
	traceFlags := (self class initializationOptions at: #recordPrimTrace ifAbsent: [true])
					ifTrue: [8] "record prim trace on by default (see Cogit class>>decareCVarsIn:)"
					ifFalse: [0].
	debugPrimCallStackOffset := 0.
	singleStep := printRegisters := printInstructions := clickConfirm := false.
	backEnd := CogCompilerClass for: self.
	methodLabel := CogCompilerClass for: self.
	(literalsManager := backEnd class literalsManagerClass new) cogit: self.
	ordinarySendTrampolines := CArrayAccessor on: (Array new: NumSendTrampolines).
	superSendTrampolines := CArrayAccessor on: (Array new: NumSendTrampolines).
	BytecodeSetHasDirectedSuperSend ifTrue:
		[directedSuperSendTrampolines := CArrayAccessor on: (Array new: NumSendTrampolines).
		 directedSuperBindingSendTrampolines := CArrayAccessor on: (Array new: NumSendTrampolines).
		 directedSendUsesBinding := false].
	"debug metadata"
	objectReferencesInRuntime := CArrayAccessor on: (Array new: NumObjRefsInRuntime).
	runtimeObjectRefIndex := 0.
	"debug metadata"
	trampolineAddresses := CArrayAccessor on: (Array new: NumTrampolines * 2).
	trampolineTableIndex := 0.

	extA := numExtB := extB := 0.

	compilationTrace ifNil: [compilationTrace := self class initializationOptions at: #compilationTrace ifAbsent: [0]].
	debugOpcodeIndices := self class initializationOptions at: #debugOpcodeIndices ifAbsent: [Set new].
	debugBytecodePointers := self class initializationOptions at: #debugBytecodePointers ifAbsent: [Set new].
	self class initializationOptions at: #breakPC ifPresent: [:pc| breakPC := pc]
]

{ #category : #'jit - api' }
Cogit >> setPostCompileHook: aFunction [
	<api>
	<var: #aFunction declareC: #'void (*aFunction)(CogMethod *)'>
	postCompileHook := aFunction
]

{ #category : #'jit - api' }
Cogit >> setSelectorOf: cogMethod to: aSelectorOop [
	<api>
	"If a method is compiled to machine code via a block entry it won't have a selector.
	 A subsequent send can find the method and hence fill in the selector."
	<var: #cogMethod type: #'CogMethod *'>
	"self disassembleMethod: cogMethod"
	coInterpreter
		compilationBreak: aSelectorOop
		point: (objectMemory numBytesOf: aSelectorOop)
		isMNUCase: false.
	self assert: cogMethod cmType = CMMethod.
	cogMethod selector: aSelectorOop.
	(objectMemory isYoung: aSelectorOop) ifTrue:
		[methodZone ensureInYoungReferrers: cogMethod]
]

{ #category : #initialization }
Cogit >> setStackAlignment: stackAlignment expectedSPOffset: spOffset expectedFPOffset: fpOffset [
	"Spcific platform ABIs mandate specific stack frame alignments.  We capture
	 these constraints in the variables here and test they are adhered to via
	 assertCStackWellAligned whenever transitioning to code that will run in C."
	self assert: stackAlignment isPowerOfTwo.
	expectedSPAlignment := spOffset \\ stackAlignment.
	expectedFPAlignment := fpOffset \\ stackAlignment.
	cStackAlignment := stackAlignment

]

{ #category : #initialization }
Cogit >> setThreadManager: aCogThreadManager [
	"Initialization of the code generator in the simulator.
	 Used in the separate VM since this VM does not do a second initialization of the interpreter,
	 only a second initialization of the objectMemory."
	<doNotGenerate>
	threadManager := aCogThreadManager "N.B. may be nil"
]

{ #category : #'simulation only' }
Cogit >> shortcutTrampoline: aProcessorSimulationTrap to: aBlock [
	<doNotGenerate>
	backEnd hasLinkRegister ifTrue:
		[processor pushWord: processor lr in: coInterpreter memory].
	processor
		simulateLeafCallOf: aProcessorSimulationTrap address
		nextpc: aProcessorSimulationTrap nextpc
		memory: coInterpreter memory.
	coInterpreter
		stackPointer: processor sp;
		framePointer: processor fp.
	processor
		sp: self getCStackPointer;
		fp: self getCFramePointer.
	aBlock value.
	processor
		sp: coInterpreter stackPointer;
		fp: coInterpreter framePointer;
		simulateLeafReturnIn: coInterpreter memory.
	backEnd hasLinkRegister ifTrue:
		[processor lr: (processor popWordIn: coInterpreter memory)]
]

{ #category : #'bytecode generator support' }
Cogit >> shouldBeImplemented [
	"In the production VM we can continue in the interpreter..."
	self cCode: [coInterpreter warning: 'bytecode should be implemented; interpreting']
		inSmalltalk: [super shouldBeImplemented]
]

{ #category : #'simulation processor access' }
Cogit >> simulateCallOf: address nextpc: nextpc memory: aMemory [
	<doNotGenerate>
	self assertCorrectProcessorOwnership.
	^processor simulateCallOf: address nextpc: nextpc memory: aMemory
]

{ #category : #'simulation only' }
Cogit >> simulateCogCodeAt: address [ "<Integer>"
	<doNotGenerate>
	| stackZoneBase |
	stackZoneBase := coInterpreter stackZoneBase.
	processor pc: address.
	[[[singleStep
		ifTrue:
			[[processor sp < stackZoneBase ifTrue: [self halt].
			  self recordProcessing.
			  self maybeBreakAt: processor pc] value. "So that the Debugger's Over steps over all this"
			  processor
					singleStepIn: coInterpreter memory
					minimumAddress: guardPageSize
					readOnlyBelow: methodZone zoneEnd]
		ifFalse:
			[processor
					runInMemory: coInterpreter memory
					minimumAddress: guardPageSize
					readOnlyBelow: methodZone zoneEnd].
	   "((printRegisters or: [printInstructions]) and: [clickConfirm]) ifTrue:
	 	[(self confirm: 'continue?') ifFalse:
			[clickConfirm := false. self halt]]."
	   true] whileTrue]
		on: ProcessorSimulationTrap
		do: [:ex| self handleSimulationTrap: ex].
	 true] whileTrue
]

{ #category : #'simulation only' }
Cogit >> simulateEnilopmart: enilopmartAddress numArgs: n [
	<doNotGenerate>
	"Enter Cog code, popping the class reg and receiver from the stack
	 and then returning to the address beneath them.
	 In the actual VM the enilopmart is a function pointer and so senders
	 of this method end up calling the enilopmart to enter machine code.
	 In simulation we either need to start simulating execution (if we're in
	 the interpreter) or return to the simulation (if we're in the run-time
	 called from machine code. We should also smash the register state
	 since, being an abnormal entry, no saved registers will be restored."
	self assert: (coInterpreter isOnRumpCStack: processor sp).
	self assert: ((coInterpreter stackValue: n) between: guardPageSize and: methodZone freeStart - 1).
	"As a convenience for stack printing, nil localFP so we know we're in machine code."
	coInterpreter nilLocalFP.
	(printInstructions or: [printRegisters]) ifTrue:
		[coInterpreter printExternalHeadFrame].
	processor
		smashRegistersWithValuesFrom: 16r80000000 by: objectMemory wordSize;
		simulateLeafCallOf: enilopmartAddress
		nextpc: 16rBADF00D
		memory: coInterpreter memory.
	"If we're already simulating in the context of machine code then
	 this will take us back to handleCallSimulationTrap:.  Otherwise
	 start executing machine code in the simulator."
	(ReenterMachineCode new returnValue: #continueNoReturn) signal.
	self simulateCogCodeAt: enilopmartAddress.
	"We should either longjmp back to the interpreter or
	 stay in machine code so control should not reach here."
	self assert: false
]

{ #category : #accessing }
Cogit >> simulateFPInUse: aBoolean [
	<doNotGenerate>
	simulateFPInUse := aBoolean
]

{ #category : #'simulation only' }
Cogit >> simulateLeafCallOf: someFunction [
	"Simulate execution of machine code that leaf-calls someFunction,
	 answering the result returned by someFunction."
	<doNotGenerate>
	| spOnEntry |
	self recordRegisters.

	spOnEntry := processor sp.
	
	processor
		simulateLeafCallOf: someFunction
		nextpc: 16rBADF00D0
		memory: coInterpreter memory.
	
	singleStep 
		ifTrue: [ self notYetImplemented ].
		
	processor runUntil: 16rBADF00D0.

	self assert: processor sp = spOnEntry.
	self assert: processor pc = 16rBADF00D0.
	
	self recordRegisters.	
	^processor cResultRegister
]

{ #category : #'simulation processor access' }
Cogit >> simulateLeafReturnIn: aMemory [
	<doNotGenerate>
	self assertCorrectProcessorOwnership.
	^processor simulateLeafReturnIn: aMemory
]

{ #category : #initialization }
Cogit >> simulatedAddressFor: anObject [
	"Answer a simulated address for a block or a symbol.  This is an address that
	 can be called, read or written by generated machine code, and will be mapped
	 into a Smalltalk message send or block evaluation.

	 N.B. These addresses are at the top end of the bottom half of the address space
	 so that they don't have the sign bit set and so will not look like negative numbers,
	 unless they're the short-cut routines on ARM, where we want to use a bl, not a blx."
	<doNotGenerate>
	^simulatedAddresses
		at: anObject
		ifAbsentPut: [self fakeAddressFor: anObject index: simulatedAddresses size]
]

{ #category : #initialization }
Cogit >> simulatedReadWriteVariableAddress: getter in: receiver [
	"Answer a simulated variable.  This is a variable whose value can be read
	 and written by generated machine code."
	<doNotGenerate>
	| address |
	address := self simulatedVariableAddress: getter in: receiver.
	simulatedVariableSetters
		at: address
		ifAbsentPut:
			[| setter |
			setter := (((getter beginsWith: 'get')
						ifTrue: ['s', getter allButFirst]
						ifFalse: [getter]), ':') asSymbol.
			[:value| receiver perform: setter with: value]].
	^address
]

{ #category : #initialization }
Cogit >> simulatedTrampolineFor: selectorOrAddress [
	"Set a simulated trampoline.  This is a method in the cogit, coInterpreter
	 or objectMemory that is called from a machine code trampoline."
	<doNotGenerate>
	| address |
	selectorOrAddress isInteger ifTrue:
		[self assert: (simulatedTrampolines includesKey: selectorOrAddress).
		 ^selectorOrAddress].
	self assert: selectorOrAddress isSymbol.
	address := self simulatedAddressFor: selectorOrAddress.
	simulatedTrampolines
		at: address
		ifAbsentPut:
			[MessageSend
				receiver: ((self respondsTo: selectorOrAddress)
							ifTrue: [self]
							ifFalse: [(coInterpreter respondsTo: selectorOrAddress)
										ifTrue: [coInterpreter]
										ifFalse: [(objectMemory respondsTo: selectorOrAddress)
											ifTrue: [objectMemory]
											ifFalse: [(backEnd respondsTo: selectorOrAddress)
												ifTrue:[backEnd]
												ifFalse:[self notify: 'cannot find receiver for ', selectorOrAddress]]]])
				selector: selectorOrAddress
				arguments: (1 to: selectorOrAddress numArgs) asArray].
	^address
]

{ #category : #initialization }
Cogit >> simulatedTrampolines [
	<doNotGenerate>
	^simulatedTrampolines
]

{ #category : #initialization }
Cogit >> simulatedVariableAddress: getter in: receiver [
	"Answer a simulated variable.  This is a variable whose value can be read
	 by generated machine code."
	<doNotGenerate>
	| address |
	address := self simulatedAddressFor: getter.
	simulatedVariableGetters
		at: address
		ifAbsentPut: [MessageSend receiver: receiver selector: getter].
	^address
]

{ #category : #initialization }
Cogit >> simulatedVariableAt: address [
	"Answer a simulated variable's value for handling the push/pop tracer."
	<doNotGenerate>
	^(simulatedVariableGetters
		at: address
		ifAbsent:[0]) value
]

{ #category : #debugging }
Cogit >> singleStep [
	<doNotGenerate>
	^singleStep
]

{ #category : #debugging }
Cogit >> singleStep: aBoolean [
	<doNotGenerate>
	singleStep := aBoolean
]

{ #category : #'translation support' }
Cogit >> sizeof: aCType [
	<doNotGenerate>
	| bfc |
	aCType == #BytecodeFixup ifTrue:
		[bfc := self class bytecodeFixupClass.
		 ^bfc alignedByteSizeOf: bfc forClient: self].
	^super sizeof: aCType
]

{ #category : #'compile abstract instructions' }
Cogit >> spanFor: descriptor at: pc exts: nExts in: aMethodObj [
	"Compute the span (jump distance) for a particular bytecode, e.g. a backward branch or a block."
	<inline: true>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	^self
		perform: descriptor spanFunction
		with: descriptor
		with: pc
		with: nExts
		with: aMethodObj
]

{ #category : #'compile abstract instructions' }
Cogit >> spanForCleanBlockStartingAt: startPC [
	<var: #descriptor type: #'BytecodeDescriptor *'>
	| pc end descriptor |
	pc := startPC.
	end := objectMemory numBytesOf: methodObj.
	[pc <= end] whileTrue:
		[descriptor := self generatorForPC: pc.
		 pc := pc + descriptor numBytes.
		 descriptor isReturn ifTrue:
			[^pc - startPC]].
	self error: 'couldn''t locate end of clean block'.
	^0
]

{ #category : #'simulation only' }
Cogit >> stackPointerAddress [
	"redirect for the backEnd's genSaveStackPointers"
	<doNotGenerate>
	^coInterpreter stackPointerAddress
]

{ #category : #'as yet unclassified' }
Cogit >> stackPointerAlignment [
	<doNotGenerate>
	^ backEnd stackPointerAlignment
]

{ #category : #disassembly }
Cogit >> startMcpcAndCogMethodForMcpc: mcpc in: cogMethod do: aBinaryBlock [
	"Evaluate aBinaryBlock with the startmcpc and method containing mcpc in cogMethod."
	<doNotGenerate>
	| startMcpc |
	startMcpc := ((self codeRangesFor: cogMethod)
					detect: [:range| range includes: mcpc]
					ifNone:
						[(self codeRangesFor: cogMethod)
							detect: [:range| range last + 1 = mcpc]
							ifNone: [^nil]]) first.
	^aBinaryBlock
		value: startMcpc
		value: (startMcpc = (cogMethod asInteger + (self sizeof: CogMethod))
					ifTrue: [cogMethod]
					ifFalse: [self cCoerceSimple: startMcpc - (self sizeof: CogBlockMethod)
								to: #'CogBlockMethod *'])
]

{ #category : #'method map' }
Cogit >> subMethodsAsRangesFor: surrogateOrAddress [
	<doNotGenerate>
	| cogMethod codeRanges |
	cogMethod := surrogateOrAddress isInteger
								ifTrue: [self cogMethodSurrogateAt: surrogateOrAddress]
								ifFalse: [surrogateOrAddress].
	^cogMethod cmType = CMMethod ifTrue:
		[codeRanges := self codeRangesFor: cogMethod.
		 ^codeRanges size > 1 "omit the block dispatch range"
			ifTrue: [codeRanges allButLast]
			ifFalse: [codeRanges]]
]

{ #category : #'in-line cacheing' }
Cogit >> subsequentPrototypeMethodOop [
	"Answer a fake value for the method oop in other than the first case in the PIC prototype.
	 Since we use MoveUniqueCw:R: it must not be confused with a method-relative address."
	<inline: false>
	^(self addressIsInCurrentCompilation: 16rBADA550)
		ifTrue: [16rDEADEAD]
		ifFalse: [16rBADA550]
]

{ #category : #'in-line cacheing' }
Cogit >> targetMethodAndSendTableFor: entryPoint annotation: annotation into: binaryBlock [
	"Evaluate binaryBlock with the targetMethod and relevant send table for a linked-send
	 to entryPoint.  Do so based on the alignment of entryPoint."
	<inline: true>
	<var: #targetMethod type: #'CogMethod *'>

	self offsetAndSendTableFor: entryPoint
		annotation: annotation
		into: [:offset :sendTable| | targetMethod |
			targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
			binaryBlock
				value: targetMethod
				value: sendTable]
]

{ #category : #testing }
Cogit >> testBcToMcPcMappingForCogMethod: cogMethod [
	<doNotGenerate>
	"self disassembleMethod: cogMethod"
	"self printPCMapPairsFor: cogMethod on: Transcript"
	| aMethodObj subMethods bsOffset |
	aMethodObj := cogMethod methodObject.
	subMethods := self subMethodsAsRangesFor: cogMethod.
	subMethods first endPC: (self endPCOf: aMethodObj).
	bsOffset := self bytecodeSetOffsetFor: aMethodObj.
	self bcpcsDescriptorsAndStartpcsFor: aMethodObj bsOffset: bsOffset do:
		[:bcpc :byte :desc :nExts :startpc|
		(desc notNil and: [desc isBlockCreation]) ifTrue:
			["dead code removal may result in blocks not being generated ;-)"
			 (subMethods detect: [:sm| sm startpc = (bcpc + desc numBytes)] ifNone: [nil]) ifNotNil:
				[:subMethod|
				 subMethod endPC: bcpc + desc numBytes + (self spanFor: desc at: bcpc exts: -1 in: aMethodObj) - 1]]].
	subMethods allButFirst do:
		[:blockSubMethod| | cogBlockMethod |
		cogBlockMethod := self
								findMethodForStartBcpc: blockSubMethod startpc
								inHomeMethod: cogMethod.
		self assert: cogBlockMethod address = (blockSubMethod first - (self sizeof: CogBlockMethod))].
	self bcpcsDescriptorsAndStartpcsFor: aMethodObj bsOffset: bsOffset do:
		[:bcpc :byte :desc :nExts :startpc| | startBcpc currentSubMethod subCogMethod absMcpc mappedBcpc |
		currentSubMethod := self innermostSubMethodFor: bcpc in: subMethods startingAt: 1.
		startpc = currentSubMethod startpc ifTrue:
			[subCogMethod := currentSubMethod cogMethod.
			(subCogMethod stackCheckOffset > 0
			 and: [desc isNil or: [desc isMapped 
			 or: [inBlock = InFullBlock and: [desc isMappedInBlock]]]]) ifTrue:
				[startBcpc := subCogMethod = cogMethod
								ifTrue: [coInterpreter startPCOfMethod: aMethodObj]
								ifFalse: [currentSubMethod startpc].
				 "The first bytecode and backward branch bytecodes are mapped to their pc.
				  Other bytecodes map to their following pc."
				 absMcpc := (desc notNil
							   and: [desc isBranch
							   and: [self isBackwardBranch: desc at: bcpc exts: nExts in: aMethodObj]])
								ifTrue: "Backward branches have a special mapper"
									[mappedBcpc := bcpc - (2 * nExts).
									 self
										mcPCForBackwardBranch: mappedBcpc
										startBcpc: startBcpc
										in: subCogMethod]
								ifFalse: "All others use the generic mapper"
									[mappedBcpc := desc ifNil: [bcpc] ifNotNil: [bcpc + desc numBytes].
									 self
										mcPCFor: mappedBcpc
										startBcpc: startBcpc
										in: subCogMethod].
				 self assert: absMcpc >= (subCogMethod asInteger + subCogMethod stackCheckOffset).
				 self assert: (self bytecodePCFor: absMcpc startBcpc: startBcpc in: subCogMethod) = mappedBcpc]]]
]

{ #category : #'tests-method map' }
Cogit >> testMcToBcPcMappingForCompiledMethod: aCompiledMethod cogMethod: cogMethod [
	<doNotGenerate>
	| bcMethod subMethods prevMcpc |
	"self disassembleMethod: cogMethod"
	"coInterpreter symbolicMethod: cogMethod methodObject"
	"coInterpreter printOop: cogMethod methodObject"
	"self printPCMapPairsFor: cogMethod on: Transcript"
	cogMethod stackCheckOffset = 0 ifTrue: "frameless"
		[^self].
	bcMethod := coInterpreter isCurrentImageFacade
					ifTrue: [coInterpreter objectForOop: cogMethod methodObject]
					ifFalse: [VMCompiledMethodProxy new
								for: cogMethod methodObject
								coInterpreter: coInterpreter
								objectMemory: objectMemory].
	subMethods := self subMethodsAsRangesFor: cogMethod.
	self mapFor: cogMethod do:
		[:annotation :mcpc| | subMethod subCogMethod bcpc mappedpc |
		(self isPCMappedAnnotation: annotation) ifTrue:
			[subMethod := subMethods
								detect: [:range| range includes: mcpc]
								ifNone: ["a trailing call ceNonLocalReturnTrampoline's following
										 pc is the start of a following block or the end of the map"
										subMethods detect: [:range| range includes: mcpc - 1]].
			mcpc > subMethod first ifTrue:
				[bcpc := self
							bytecodePCFor: mcpc
							startBcpc: subMethod startpc
							in: (subCogMethod := subMethod cogMethod).
				self assert: bcpc ~= 0.
				mappedpc := self mcPCFor: bcpc startBcpc: subMethod startpc in: subCogMethod.
				subCogMethod stackCheckOffset = 0
					ifTrue: [self assert: mappedpc > (subCogMethod address + self noCheckEntryOffset)]
					ifFalse: [self assert: mappedpc >= (subCogMethod address + subCogMethod stackCheckOffset)].
				"mcpc = mappedpc is obviously what we want and expect.  prevMcpc = mappedpc hacks
				 around frame building accessors where the first bytecode is mapped twice, once for the
				 stack check and once for the context inst var access.  The bytecode pc can only map
				 back to a single mcpc, the first, so the second map entry will fail without this hack."
				self assert: (mcpc = mappedpc or: [prevMcpc = mappedpc]).
				(self isSendAnnotation: annotation) ifTrue:
					[| mcSelector bcSelector |
					mcSelector := self selectorForSendAt: mcpc annotation: annotation in: aCompiledMethod.
					"sends map to the following pc.  need to find the selector for the previous pc"
					bcSelector := self selectorForSendBefore: bcpc in: bcMethod.
					self assert: (mcSelector = bcSelector
								or: [mcSelector = (self resolveToOopOrNil: bcSelector)])]].
			 prevMcpc := mcpc].
		 false "keep scanning"]
]

{ #category : #'tests-method map' }
Cogit >> testPCMappingForCompiledMethod: aCompiledMethod cogMethod: cm [
	<doNotGenerate>
	methodObj := methodHeader := nil.
	cm isInteger ifTrue: "If testing in a simulation..."
		[^self testPCMappingForCompiledMethod: aCompiledMethod cogMethod: (self cogMethodSurrogateAt: cm)].
	self
		testMcToBcPcMappingForCompiledMethod: aCompiledMethod cogMethod: cm;
		testBcToMcPcMappingForCogMethod: cm
]

{ #category : #debugging }
Cogit >> traceLinkedSendOffset [
	<api>
	^cmNoCheckEntryOffset
	 + backEnd callInstructionByteSize
	 + (backEnd hasLinkRegister
		ifTrue: [backEnd pushLinkRegisterByteSize]
		ifFalse: [0])
]

{ #category : #debugging }
Cogit >> traceStores: aBooleanOrInteger [
	<doNotGenerate>
	traceStores := aBooleanOrInteger isInteger
							ifTrue: [aBooleanOrInteger]
							ifFalse: [aBooleanOrInteger ifTrue: [1] ifFalse: [0]]
]

{ #category : #initialization }
Cogit >> trampolineArgConstant: booleanOrInteger [
	"Encode true and false and 0 to N such that they can't be confused for register numbers (including NoReg)
	 and can be tested for by isTrampolineArgConstant: and decoded by trampolineArgValue:"
	<inline: true>
	self cCode: []
		inSmalltalk: [booleanOrInteger isInteger ifFalse: [^self trampolineArgConstant: (booleanOrInteger ifTrue: [1] ifFalse: [0])]].
	self assert: booleanOrInteger >= 0.
	^-2 - booleanOrInteger "0...N => -2...-(N+2)"
]

{ #category : #initialization }
Cogit >> trampolineArgValue: n [
	"Decode true and false and 0 to N to their C equivalents from the encoding by trampolineArgConstant:"
	<inline: true>
	^-2 - n
]

{ #category : #initialization }
Cogit >> trampolineName: routinePrefix numArgs: numArgs [
	<returnTypeC: #'char *'>
	<var: #routinePrefix type: #'char *'>
	^self trampolineName: routinePrefix numArgs: numArgs limit: NumSendTrampolines - 2
]

{ #category : #initialization }
Cogit >> trampolineName: routinePrefix numArgs: numArgs limit: argsLimit [
	"Malloc a string with the contents for the trampoline table"
	<inline: true>
	<returnTypeC: #'char *'>
	<var: #routinePrefix type: #'char *'>
	<var: #numArgs type: #int>
	| theString |
	<var: #theString type: #'char *'>
	self cCode: '' inSmalltalk:
		[^routinePrefix, (numArgs <= argsLimit ifTrue: [numArgs printString] ifFalse: ['N']), 'Args'].
	theString := self malloc: (self strlen: routinePrefix) + 6.
	self s: theString pr: '%s%cArgs' in: routinePrefix tf: (numArgs <= argsLimit ifTrue: [$0 + numArgs] ifFalse: [$N]).
	^theString
]

{ #category : #initialization }
Cogit >> trampolineName: routinePrefix numRegArgs: numArgs [
	<returnTypeC: #'char *'>
	<var: #routinePrefix type: #'char *'>
	^self trampolineName: routinePrefix numArgs: numArgs limit: self numRegArgs
]

{ #category : #'bytecode generators' }
Cogit >> unknownBytecode [
	^EncounteredUnknownBytecode
]

{ #category : #'jit - api' }
Cogit >> unlinkAllSends [
	<api>
	"Unlink all sends in cog methods."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	methodZoneBase ifNil: [^self].
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	methodZone voidOpenPICList.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod
			ifTrue:
				[self mapFor: cogMethod
					 performUntil: #unlinkIfLinkedSend:pc:ignored:
					 arg: 0]
			ifFalse:
				[cogMethod cmType ~= CMFree ifTrue:
					[methodZone freeMethod: cogMethod]].
		cogMethod := methodZone methodAfter: cogMethod].
	"After updating inline caches we need to flush the icache."
	processor flushICacheFrom: methodZoneBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger
]

{ #category : #'in-line cacheing' }
Cogit >> unlinkIfFreeOrLinkedSend: annotation pc: mcpc of: theSelector [
	<var: #mcpc type: #'char *'>
	| entryPoint |

	(self isPureSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase
			ifTrue: "It's a linked send."
				[self targetMethodAndSendTableFor: entryPoint annotation: annotation into:
					[:targetMethod :sendTable| 
					 (targetMethod cmType = CMFree
					  or: [targetMethod selector = theSelector]) ifTrue:
						[self unlinkSendAt: mcpc targetMethod: targetMethod sendTable: sendTable]]]].

	^0 "keep scanning"
]

{ #category : #'in-line cacheing' }
Cogit >> unlinkIfInvalidClassSend: annotation pc: mcpc ignored: superfluity [
	<var: #mcpc type: #'char *'>
	| entryPoint |

	(self isPureSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase ifTrue: "It's a linked send, but maybe a super send or linked to an OpenPIC, in which case the cache tag will be a selector...."
			[self targetMethodAndSendTableFor: entryPoint annotation: annotation into:
				[:targetMethod :sendTable|
				 ((self annotationIsForUncheckedEntryPoint: annotation)
				  or: [targetMethod cmType = CMOpenPIC]) ifFalse:
					[(objectMemory isValidClassTag: (backEnd inlineCacheTagAt: mcpc asInteger)) ifFalse:
						[self unlinkSendAt: mcpc targetMethod: targetMethod sendTable: sendTable]]]]].

	^0 "keep scanning"
]

{ #category : #'in-line cacheing' }
Cogit >> unlinkIfLinkedSend: annotation pc: mcpc ignored: superfluity [
	<var: #mcpc type: #'char *'>
	| entryPoint |

	(self isPureSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase
			ifTrue: "It's a linked send."
				[self targetMethodAndSendTableFor: entryPoint annotation: annotation into:
					[:targetMethod :sendTable| 
					 self unlinkSendAt: mcpc targetMethod: targetMethod sendTable: sendTable]]].

	^0 "keep scanning"
]

{ #category : #'in-line cacheing' }
Cogit >> unlinkIfLinkedSend: annotation pc: mcpc of: theSelector [
	<var: #mcpc type: #'char *'>
	| entryPoint |

	(self isPureSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase
			ifTrue: "It's a linked send."
				[self targetMethodAndSendTableFor: entryPoint annotation: annotation into:
					[:targetMethod :sendTable| 
					 targetMethod selector = theSelector ifTrue:
						[self unlinkSendAt: mcpc targetMethod: targetMethod sendTable: sendTable]]]].

	^0 "keep scanning"
]

{ #category : #'in-line cacheing' }
Cogit >> unlinkIfLinkedSend: annotation pc: mcpc to: theCogMethod [
	<var: #mcpc type: #'char *'>
	| entryPoint |

	(self isPureSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase
			ifTrue: "It's a linked send."
				[self targetMethodAndSendTableFor: entryPoint annotation: annotation into:
					[:targetMethod :sendTable| 
					 targetMethod asInteger = theCogMethod ifTrue:
						[self unlinkSendAt: mcpc targetMethod: targetMethod sendTable: sendTable]]]].

	^0 "keep scanning"
]

{ #category : #'in-line cacheing' }
Cogit >> unlinkIfLinkedSendToFree: annotation pc: mcpc ignored: superfluity [
	<var: #mcpc type: #'char *'>
	| entryPoint |

	(self isPureSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase ifTrue: "It's a linked send."
			[self targetMethodAndSendTableFor: entryPoint annotation: annotation into:
				[:targetMethod :sendTable| 
				 targetMethod cmType = CMFree ifTrue:
					[self unlinkSendAt: mcpc targetMethod: targetMethod sendTable: sendTable]]]].

	^0 "keep scanning"
]

{ #category : #'in-line cacheing' }
Cogit >> unlinkSendAt: mcpc targetMethod: targetMethod sendTable: sendTable [
	<inline: true>
	| unlinkedRoutine |
	unlinkedRoutine := sendTable at: (targetMethod cmNumArgs min: NumSendTrampolines - 1).
	backEnd
		rewriteInlineCacheAt: mcpc asInteger
		tag: (self inlineCacheValueForSelector: targetMethod selector in: enumeratingCogMethod at: mcpc)
		target: unlinkedRoutine.
	codeModified := true
]

{ #category : #'jit - api' }
Cogit >> unlinkSendsLinkedForInvalidClasses [
	<api>
	<option: #SpurObjectMemory>
	"Unlink all sends in cog methods whose class tag is that of a forwarded class."
	| cogMethod freedPIC |
	<var: #cogMethod type: #'CogMethod *'>
	methodZoneBase ifNil: [^self].
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	codeModified := freedPIC := false.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod
			ifTrue:
				[self mapFor: cogMethod
					 performUntil: #unlinkIfInvalidClassSend:pc:ignored:
					 arg: 0]
			ifFalse:
				[(cogMethod cmType = CMClosedPIC
				  and: [self cPICHasForwardedClass: cogMethod]) ifTrue:
					[methodZone freeMethod: cogMethod.
					 freedPIC := true]].
		cogMethod := methodZone methodAfter: cogMethod].
	freedPIC
		ifTrue: [self unlinkSendsToFree]
		ifFalse:
			[codeModified ifTrue: "After possibly updating inline caches we need to flush the icache."
				[processor flushICacheFrom: methodZoneBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger]]
]

{ #category : #'jit - api' }
Cogit >> unlinkSendsOf: selector isMNUSelector: isMNUSelector [
	<api>
	"Unlink all sends in cog methods. Free all Closed PICs with the selector,
	 or with an MNU case if isMNUSelector.  First check if any method actually
	 has the selector; if not there can't be any linked send to it.  This routine
	 (including descendents) is performance critical.  It contributes perhaps
	 30% of entire execution time in Compiler recompileAll."
	| cogMethod mustScanAndUnlink |
	<var: #cogMethod type: #'CogMethod *'>
	methodZoneBase ifNil: [^self].
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	mustScanAndUnlink := false.
	isMNUSelector
		ifTrue:
			[[cogMethod < methodZone limitZony] whileTrue:
				[cogMethod cmType ~= CMFree ifTrue:
					[cogMethod cpicHasMNUCase
						ifTrue:
							[self assert: cogMethod cmType = CMClosedPIC.
							 methodZone freeMethod: cogMethod.
							 mustScanAndUnlink := true]
						ifFalse:
							[cogMethod selector = selector ifTrue:
								[mustScanAndUnlink := true.
								 cogMethod cmType = CMClosedPIC ifTrue:
									[methodZone freeMethod: cogMethod]]]].
				 cogMethod := methodZone methodAfter: cogMethod]]
		ifFalse:
			[[cogMethod < methodZone limitZony] whileTrue:
				[(cogMethod cmType ~= CMFree
				  and: [cogMethod selector = selector]) ifTrue:
					[mustScanAndUnlink := true.
					 cogMethod cmType = CMClosedPIC ifTrue:
						[methodZone freeMethod: cogMethod]].
				 cogMethod := methodZone methodAfter: cogMethod]].
	mustScanAndUnlink ifFalse:
		[^self].
	codeModified := false.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod ifTrue:
			[self mapFor: cogMethod
				 performUntil: #unlinkIfFreeOrLinkedSend:pc:of:
				 arg: selector].
		cogMethod := methodZone methodAfter: cogMethod].
	codeModified ifTrue: "After possibly updating inline caches we need to flush the icache."
		[processor flushICacheFrom: methodZoneBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger]
]

{ #category : #'jit - api' }
Cogit >> unlinkSendsTo: targetMethodObject andFreeIf: freeIfTrue [
	<api>
	"Unlink all sends in cog methods to a particular target method.
	 If targetMethodObject isn't actually a method (perhaps being
	 used via invokeAsMethod) then there's nothing to do."
	| cogMethod targetMethod freedPIC |
	<var: #cogMethod type: #'CogMethod *'>
	<var: #targetMethod type: #'CogMethod *'>
	((objectMemory isOopCompiledMethod: targetMethodObject)
	and: [coInterpreter methodHasCogMethod: targetMethodObject]) ifFalse:
		[^self].
	targetMethod := coInterpreter cogMethodOf: targetMethodObject.
	methodZoneBase ifNil: [^self].
	codeModified := freedPIC := false.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod
			ifTrue:
				[self mapFor: cogMethod
					 performUntil: #unlinkIfLinkedSend:pc:to:
					 arg: targetMethod asInteger]
			ifFalse:
				[(cogMethod cmType = CMClosedPIC
				  and: [self cPIC: cogMethod HasTarget: targetMethod]) ifTrue:
					[methodZone freeMethod: cogMethod.
					 freedPIC := true]].
		cogMethod := methodZone methodAfter: cogMethod].
	freeIfTrue ifTrue: [self freeMethod: targetMethod].
	freedPIC
		ifTrue: [self unlinkSendsToFree]
		ifFalse:
			[codeModified ifTrue: "After possibly updating inline caches we need to flush the icache."
				[processor flushICacheFrom: methodZoneBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger]]
]

{ #category : #'garbage collection' }
Cogit >> unlinkSendsToFree [
	<api>
	"Unlink all sends in cog methods to free methods and/or pics."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	methodZoneBase ifNil: [^self].
	codeModified := false.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod
			ifTrue:
				[self mapFor: cogMethod
					 performUntil: #unlinkIfLinkedSendToFree:pc:ignored:
					 arg: 0]
			ifFalse:
				[cogMethod cmType = CMClosedPIC ifTrue:
					[self assert: (self noTargetsFreeInClosedPIC: cogMethod)]].
		cogMethod := methodZone methodAfter: cogMethod].
	codeModified ifTrue: "After possibly updating inline caches we need to flush the icache."
		[processor flushICacheFrom: methodZoneBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger]
]

{ #category : #accessing }
Cogit >> varBaseAddress [
	"This is for disassembly decoration by the processor aliens.  they don't know aboud objectMemory hence forward..."
	<doNotGenerate>
	^coInterpreter varBaseAddress
]

{ #category : #'jit - api' }
Cogit >> voidCogCompiledCode [
	<api>
	methodZone clearCogCompiledCode
]

{ #category : #'in-line cacheing' }
Cogit >> voidNSSendCache: nsSendCache [
	<inline: true>
	nsSendCache classTag: objectRepresentation illegalClassTag; enclosingObject: 0; target: 0
]

{ #category : #'debug printing' }
Cogit >> warnMultiple: cogMethod selectors: aSelectorOop [
	<inline: true>
	<var: 'cogMethod' type: #'CogMethod *'>
	self cCode:
			[self fp: #stderr
				r: 'Warning, attempt to use method with selector %.*s and selector %.*s\n'
				i: (self cCoerceSimple: (objectMemory numBytesOf: cogMethod selector) to: #int)
				n: (self cCoerceSimple: (objectMemory firstIndexableField: cogMethod selector) to: #'char *')
				t: (self cCoerceSimple: (objectMemory numBytesOf: aSelectorOop) to: #int)
				f: (self cCoerceSimple: (objectMemory firstIndexableField: aSelectorOop) to: #'char *')]
		inSmalltalk:
			[self warn: 'Warning, attempt to use method with selector ',
						(coInterpreter stringOf: cogMethod selector),
						' and selector ',
						(coInterpreter stringOf: aSelectorOop)]
]

{ #category : #'debug printing' }
Cogit >> whereIsMaybeCodeThing: anOop [
	<doNotGenerate>
	^methodZone whereIsMaybeCodeThing: anOop
]

{ #category : #analysis }
Cogit >> withAnnotation: annotation mcpc: mcpc evaluate: binaryBlock [
	<doNotGenerate>
	binaryBlock value: annotation value: mcpc.
	^0 "keep scanning"
]

{ #category : #'garbage collection' }
Cogit >> withAnnotation: annotation pc: mcpc evaluate: aBinaryBlock [
	<doNotGenerate>
	^(aBinaryBlock value: annotation value: mcpc) ifTrue: [1] ifFalse: [0]
]

{ #category : #accessing }
Cogit >> zeroOpcodeIndex [
	"Access for the object representations when they need to prepend code to trampolines."
	"Eliminate stale dependent info."
	0 to: opcodeIndex - 1 do:
		[:i| (abstractOpcodes at: i) dependent: nil].
	self zeroOpcodeIndexForNewOpcodes
]

{ #category : #accessing }
Cogit >> zeroOpcodeIndexForNewOpcodes [
	"Access for the object representations when they need to prepend code to trampolines."
	opcodeIndex := 0.
	literalsManager resetLiterals
]
