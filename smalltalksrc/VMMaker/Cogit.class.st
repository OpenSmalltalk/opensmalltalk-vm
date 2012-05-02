"
I am the code generator for the Cog VM.  My job is to produce machine code versions of methods for faster execution and to manage inline caches for faster send performance.

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
	the labels for forward jumps that will be fixed up when reaching the relevant bytecode.  fixup shas one element per byte in methodObj's bytecode
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
	the index into blockStarts as they are being noted, and hence eventuakly teh total number of blocks in the current method
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
		'traceLinkedSends',
		'traceStores',
		'breakMethod',
		'methodObj',
		'initialPC',
		'endPC',
		'methodOrBlockNumArgs',
		'inBlock',
		'needsFrame',
		'hasYoungReferent',
		'primitiveIndex',
		'backEnd',
		'postCompileHook',
		'primInvokeLabel',
		'methodLabel',
		'stackCheckLabel',
		'blockEntryLabel',
		'blockEntryNoContextSwitch',
		'blockNoContextSwitchOffset',
		'stackOverflowCall',
		'sendMissCall',
		'missOffset',
		'entryPointMask',
		'checkedEntryAlignment',
		'cmEntryOffset',
		'entry',
		'cmNoCheckEntryOffset',
		'noCheckEntry',
		'dynSuperEntry',
		'dynSuperEntryAlignment',
		'cmDynSuperEntryOffset',
		'mnuCall',
		'interpretCall',
		'endCPICCase0',
		'endCPICCase1',
		'numPICCases',
		'firstCPICCaseOffset',
		'cPICCaseSize',
		'cPICEndSize',
		'closedPICSize',
		'openPICSize',
		'fixups',
		'abstractOpcodes',
		'annotations',
		'generatorTable',
		'primitiveGeneratorTable',
		'byte0',
		'byte1',
		'byte2',
		'byte3',
		'bytecodePointer',
		'opcodeIndex',
		'numAbstractOpcodes',
		'annotationIndex',
		'blockStarts',
		'blockCount',
		'labelCounter',
		'cStackAlignment',
		'expectedSPAlignment',
		'expectedFPAlignment',
		'codeModified',
		'maxMethodBefore',
		'ceMethodAbortTrampoline',
		'cePICAbortTrampoline',
		'ceCheckForInterruptTrampoline',
		'ceCPICMissTrampoline',
		'ceStoreCheckTrampoline',
		'ceReturnToInterpreterTrampoline',
		'ceBaseFrameReturnTrampoline',
		'ceSendMustBeBooleanAddTrueTrampoline',
		'ceSendMustBeBooleanAddFalseTrampoline',
		'ceCannotResumeTrampoline',
		'ceClosureCopyTrampoline',
		'ceCreateNewArrayTrampoline',
		'ceEnterCogCodePopReceiverReg',
		'ceEnterCogCodePopReceiverAndClassRegs',
		'cePrimReturnEnterCogCode',
		'cePrimReturnEnterCogCodeProfiling',
		'ceNonLocalReturnTrampoline',
		'ceActiveContextTrampoline',
		'ceFetchContextInstVarTrampoline',
		'ceStoreContextInstVarTrampoline',
		'cePositive32BitIntegerTrampoline',
		'ceImplicitReceiverTrampoline',
		'ceExplicitReceiverTrampoline',
		'ceCaptureCStackPointers',
		'ceFlushICache',
		'ceCheckFeaturesFunction',
		'ceTraceLinkedSendTrampoline',
		'ceTraceBlockActivationTrampoline',
		'ceTraceStoreTrampoline',
		'ceGetSP',
		'sendTrampolines',
		'superSendTrampolines',
		'dynamicSuperSendTrampolines',
		'firstSend',
		'lastSend',
		'realCEEnterCogCodePopReceiverReg',
		'realCEEnterCogCodePopReceiverAndClassRegs',
		'trampolineTableIndex',
		'trampolineAddresses',
		'objectReferencesInRuntime',
		'runtimeObjectRefIndex',
		'cFramePointerInUse',
		'debugPrimCallStackOffset',
		'ceTryLockVMOwner',
		'ceUnlockVMOwner',
		'cogMethodSurrogateClass',
		'cogBlockMethodSurrogateClass'
	],
	#classVars : [
		'AnnotationConstantNames',
		'AnnotationShift',
		'BlockCreationBytecodeSize',
		'Debug',
		'DisplacementMask',
		'DisplacementX2N',
		'EagerInstructionDecoration',
		'EncounteredUnknownBytecode',
		'FirstAnnotation',
		'HasBytecodePC',
		'InsufficientCodeSpace',
		'IsAbsPCReference',
		'IsDisplacement',
		'IsDisplacementX2N',
		'IsNSSendCall',
		'IsObjectReference',
		'IsRelativeCall',
		'IsSendCall',
		'MapEnd',
		'MaxCompiledPrimitiveIndex',
		'MaxNegativeErrorCode',
		'MaxUnitDisplacement',
		'MaxUnreportableError',
		'MaxX2NDisplacement',
		'NotFullyInitialized',
		'NumObjRefsInRuntime',
		'NumSendTrampolines',
		'NumTrampolines',
		'ProcessorClass',
		'YoungSelectorInPIC'
	],
	#pools : [
		'CogMethodConstants',
		'CogRTLOpcodes',
		'VMBasicConstants',
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
	^super ancilliaryClasses,
	  { CogMethodZone }
]

{ #category : #translation }
Cogit class >> ancilliaryStructClasses [
	ProcessorClass ifNil: [thisContext methodClass theNonMetaClass initialize].
	^{	CogAbstractInstruction.
		ProcessorClass basicNew abstractInstructionCompilerClass.
		CogBlockStart.
		CogBytecodeDescriptor.
		CogBytecodeFixup.
		CogInstructionAnnotation.
		CogPrimitiveDescriptor.
		CogBlockMethod.
		CogMethod	}
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

{ #category : #translation }
Cogit class >> bytecodeTable [
	| selectors |
	selectors := Set new.
	generatorTable object do:
		[:bytecodeDescriptor|
		selectors add: bytecodeDescriptor generator.
		bytecodeDescriptor spanFunction ifNotNil:
			[selectors add: bytecodeDescriptor spanFunction]].
	^selectors
]

{ #category : #accessing }
Cogit class >> chooseCogitClass [
	^Smalltalk at: ([:choices| choices at: (UIManager default chooseFrom: choices) ifAbsent: [^nil]]
						value: (Cogit allSubclasses collect: [:ea| ea  name]) sorted)
]

{ #category : #'in-image compilation' }
Cogit class >> cog: aCompiledMethod selector: aSelector [
	"COGMTVM := false. StackToRegisterMappingCogit cog: (Integer >> #benchFib) selector: #benchFib"
	"| tuple |
	 COGMTVM := false.
	 tuple := StackToRegisterMappingCogit cog: (Object >> #at:) selector: #at:.
	 tuple second disassembleMethod: tuple last"
	| coInterpreter |
	self initialize.
	coInterpreter := CurrentImageCoInterpreterFacade new cogit: self new; yourself.
	^[{ coInterpreter.
		coInterpreter cogit.
		coInterpreter cogit
			setInterpreter: coInterpreter;
			singleStep: true;
			initializeCodeZoneFrom: 1024 upTo: coInterpreter memory size;
			cog: (coInterpreter oopForObject: aCompiledMethod) selector: (coInterpreter oopForObject: aSelector) }]
		on: Notification
		do: [:ex|
			(ex messageText beginsWith: 'cannot find receiver for') ifTrue:
				[ex resume: coInterpreter].
			ex pass]
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
		'cogBlockMethodSurrogateClass' 'cogMethodSurrogateClass'
		'threadManager' 'processor' 'lastNInstructions' 'simulatedAddresses'
		'simulatedTrampolines' 'simulatedVariableGetters' 'simulatedVariableSetters'
		'printRegisters' 'printInstructions' 'clickConfirm' 'singleStep') do:
			[:simulationVariableNotNeededForRealVM|
			aCCodeGenerator removeVariable: simulationVariableNotNeededForRealVM].
	NewspeakVM ifFalse:
		[#(	'dynSuperEntry' 'dynSuperEntryAlignment' 'dynamicSuperSendTrampolines'
			'ceImplicitReceiverTrampoline' 'ceExplicitReceiverTrampoline' 'cmDynSuperEntryOffset') do:
				[:variableNotNeededInNormalVM|
				aCCodeGenerator removeVariable: variableNotNeededInNormalVM]].
	aCCodeGenerator
		addHeaderFile:'<stddef.h>'; "for e.g. offsetof"
		addHeaderFile:'"sqCogStackAlignment.h"';
		addHeaderFile:'"cogmethod.h"';
		addHeaderFile:'#if COGMTVM';
		addHeaderFile:'"cointerpmt.h"';
		addHeaderFile:'#else';
		addHeaderFile:'"cointerp.h"';
		addHeaderFile:'#endif';
		addHeaderFile:'"cogit.h"';
		addHeaderFile:'"dispdbg.h"'.
	aCCodeGenerator
		var: #ceGetSP
			declareC: 'unsigned long (*ceGetSP)(void)';
		var: #ceCaptureCStackPointers
			declareC: 'void (*ceCaptureCStackPointers)(void)';
		var: #ceEnterCogCodePopReceiverReg
			declareC: 'void (*ceEnterCogCodePopReceiverReg)(void)';
		var: #realCEEnterCogCodePopReceiverReg
			declareC: 'void (*realCEEnterCogCodePopReceiverReg)(void)';
		var: #ceEnterCogCodePopReceiverAndClassRegs
			declareC: 'void (*ceEnterCogCodePopReceiverAndClassRegs)(void)';
		var: #realCEEnterCogCodePopReceiverAndClassRegs
			declareC: 'void (*realCEEnterCogCodePopReceiverAndClassRegs)(void)';
		var: #ceFlushICache
			declareC: 'static void (*ceFlushICache)(unsigned long from, unsigned long to)';
		var: #ceCheckFeaturesFunction
			declareC: 'static unsigned long (*ceCheckFeaturesFunction)(void)';
		var: #ceTryLockVMOwner
			declareC: 'unsigned long (*ceTryLockVMOwner)(void)';
		var: #ceUnlockVMOwner
			declareC: 'void (*ceUnlockVMOwner)(void)';
		var: #postCompileHook
			declareC: 'void (*postCompileHook)(CogMethod *, void *)';
		var: #openPICList declareC: 'CogMethod *openPICList = 0';
		var: #maxMethodBefore type: #'CogBlockMethod *'.
	aCCodeGenerator
		declareVar: 'aMethodLabel' type: #'AbstractInstruction'; "Has to come lexicographically before backEnd & methodLabel"
		var: #backEnd declareC: 'AbstractInstruction *backEnd = &aMethodLabel';
		var: #methodLabel declareC: 'AbstractInstruction *methodLabel = &aMethodLabel';
		var: #primInvokeLabel type: #'AbstractInstruction *'.
	self declareC: #(abstractOpcodes stackCheckLabel
					blockEntryLabel blockEntryNoContextSwitch
					stackOverflowCall sendMissCall entry noCheckEntry dynSuperEntry
					mnuCall interpretCall endCPICCase0 endCPICCase1)
			as: #'AbstractInstruction *'
				in: aCCodeGenerator.
	aCCodeGenerator
		declareVar: #annotations type: #'InstructionAnnotation *';
		declareVar: #blockStarts type: #'BlockStart *';
		declareVar: #fixups type: #'BytecodeFixup *'.
	aCCodeGenerator
		var: #sendTrampolines
			declareC: 'sqInt sendTrampolines[NumSendTrampolines]';
		var: #superSendTrampolines
			declareC: 'sqInt superSendTrampolines[NumSendTrampolines]';
		var: #dynamicSuperSendTrampolines
			declareC: 'sqInt dynamicSuperSendTrampolines[NumSendTrampolines]';
		var: #trampolineAddresses
			declareC: 'static char *trampolineAddresses[NumTrampolines*2]';
		var: #objectReferencesInRuntime
			declareC: 'static sqInt objectReferencesInRuntime[NumObjRefsInRuntime]';
		var: #cePositive32BitIntegerTrampoline
			declareC: 'static sqInt cePositive32BitIntegerTrampoline';
		var: #labelCounter
			declareC: 'static int labelCounter';
		var: #traceLinkedSends
			declareC: 'int traceLinkedSends = 8 /* prim trace log on by default */';
		var: #cStackAlignment
			declareC: 'const int cStackAlignment = STACK_ALIGN_BYTES'.
	aCCodeGenerator
		declareVar: #CFramePointer type: #'void *';
		declareVar: #CStackPointer type: #'void *';
		declareVar: #minValidCallAddress type: #'unsigned long';
		declareVar: #debugPrimCallStackOffset type: #'unsigned long'.
	aCCodeGenerator
		var: #generatorTable
			declareC: 'BytecodeDescriptor generatorTable[256]'
						, (self tableInitializerFor: aCCodeGenerator vmClass generatorTable
							in: aCCodeGenerator);
		var: #primitiveGeneratorTable
			declareC: 'PrimitiveDescriptor primitiveGeneratorTable[MaxCompiledPrimitiveIndex+1]'
						, (self tableInitializerFor: aCCodeGenerator vmClass primitiveTable
							in: aCCodeGenerator).
	"In C the abstract opcode names clash with the Smalltak generator syntactic sugar.
	 Most of the syntactic sugar is inlined, but alas some remains.  Rename the syntactic
	 sugar to avoid the clash."
	(self organization listAtCategoryNamed: #'abstract instructions') do:
		[:s|
		aCCodeGenerator addSelectorTranslation: s to: 'g', (aCCodeGenerator cFunctionNameFor: s)].
	aCCodeGenerator addSelectorTranslation: #halt: to: 'haltmsg'
]

{ #category : #translation }
Cogit class >> doInlining [
	"inline only those methods that are marked with <inline: true>"
	^#asSpecified
]

{ #category : #translation }
Cogit class >> exportAPISelectors [
	^((self withAllSuperclasses copyUpThrough: Cogit), self ancilliaryClasses collect:
		[:c| self exportAPISelectorsFor: c]) fold: [:a :b| a, b]
]

{ #category : #'in-image compilation' }
Cogit class >> genAndDis: methodOrDoitString [
	| tuple |
	methodOrDoitString isCompiledMethod ifFalse:
		[^self genAndDis: (Compiler new
								compiledMethodFor: methodOrDoitString
								in: nil
								to: nil
								notifying: nil
								ifFail: nil
								logged: false)].
	tuple := self cog: methodOrDoitString selector: methodOrDoitString selector.
	tuple second disassembleMethod: tuple last.
	^tuple
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
						isMapped: (tuple includes: #mapped);
						isMappedInBlock: (tuple includes: #mappedInBlock);
						isBlockCreation: (tuple includes: #block);
						isBranch: ((tuple includes: #forward) or: [tuple includes: #backward]);
						spanFunction: ((descriptor isBranch or: [descriptor isBlockCreation]) ifTrue:
										[tuple last]);
						isBackwardBranch: (tuple includes: #backward);
						isBranchTrue: (tuple includes: true);
						isBranchFalse: (tuple includes: false);
						yourself.
		descriptor isBlockCreation ifTrue:
			[blockCreationBytecodeSize
				ifNil: [blockCreationBytecodeSize := descriptor numBytes]
				ifNotNil: [self assert: blockCreationBytecodeSize = descriptor numBytes]].
		tuple do:
			[:thing|
			thing isSymbol ifTrue:
				[(thing beginsWith: 'needsFrame') ifTrue:
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

{ #category : #translation }
Cogit class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #'class initialization' }
Cogit class >> initializeAnnotationConstants [
	"These form the method map for a cog method.  Each annotated instruction has a
	 byte in the map, and each byte in the map has two parts.  In the least signficant
	 bits are a byte distance from the start of the method or previous map entry.  In
	 the most signficant bits are the type of annotation at the point reached.  A null
	 byte ends the map.

	 The map occurs at the end of a method (*), in reverse, so that its start is found
	 by adding the method's block size.  If the distance between two mapped
	 instructions will not fit in the displacement field then one or more displacement
	 entries are placed in the map to bridge the gap.  There are either unit displacement
	 bytes or * 32 displacement bytes. (* if methods have performance counters then
	 the map preceedes the counters and so one finds the map by adding the block
	 size and subtracting numCounters * sizeof(counter)).

	 There is only one kind of call annotation that serves for all calls from machine
	 code. There are four kinds of call, sends, super sends, calls of the generated
	 run-time, and direct calls of primitive functions in the interpreter.  These need
	 different treatment at different times.  For example, when the send cache is
	 flushed or the method zone is shrunk some sends must be unlinked and some
	 sends must be relocated.

	 Sends can be distinguished from run-time or direct primitive calls based on
	 address; only sends have their target between methodZoneBase and methodZone
	 freeStart.  Further, normal sends can be distinguished from super sends because
	 normal sends link to the checked entry-point, whereas super sends link to the
	 unchecked entry-point, and both entry points have different alignment.
	 But to be able to parse bytecoded methods and match their pcs with corresponding
	 machine code pcs the map needs to differentiate between sends and run-time calls. 

	 While run-time calls can be distinguished from direct primitive calls on the basis
	 of address there is no need to do so.  They are merely calls to locations that
	 don't move during method zone compaction.

	 Absolute PC references are used for method references and counter references.
	 These are references from withi a particular method to absolute pcs in that same
	 method that must be relocated when the method moves."
	"self initializeAnnotationConstants"
	IsSendCall := 7.
	IsRelativeCall := 6.
	HasBytecodePC := 5.
	IsAbsPCReference := 4.
	IsObjectReference := 3.
	IsNSSendCall := NewspeakVM ifTrue: [2].
	IsDisplacementX2N := 1.
	IsDisplacement := 0.
	AnnotationShift := 5.

	DisplacementMask := (1 << AnnotationShift) - 1.
	DisplacementX2N := IsDisplacementX2N << AnnotationShift.
	FirstAnnotation := IsDisplacementX2N + 1 << AnnotationShift.
	MaxUnitDisplacement := DisplacementMask.
	MaxX2NDisplacement := DisplacementMask << AnnotationShift.

	MapEnd := 0.

	AnnotationConstantNames := NewspeakVM
									ifTrue:
										[#(	IsDisplacement IsDisplacementX2N
											IsNSSendCall
											IsObjectReference
											IsAbsPCReference
											HasBytecodePC
											IsRelativeCall
											IsSendCall)]
									ifFalse:
										[#(	IsDisplacement IsDisplacementX2N unused
											IsObjectReference
											IsAbsPCReference
											HasBytecodePC
											IsRelativeCall
											IsSendCall)]
]

{ #category : #'class initialization' }
Cogit class >> initializeBytecodeTable [
	"SimpleStackBasedCogit initializeBytecodeTable"
	"StackToRegisterMappingCogit initializeBytecodeTable"

	NewspeakVM ifTrue:
		[^self initializeBytecodeTableForNewspeakV3PlusClosures].

	^self initializeBytecodeTableForSqueakV3PlusClosures
]

{ #category : #'class initialization' }
Cogit class >> initializeCogMethodConstants [
	CMOpenPIC := 1 + (CMClosedPIC := 1 + (CMBlock := 1 +(CMMethod := 1 + (CMFree := 1))))
]

{ #category : #'class initialization' }
Cogit class >> initializeCompilationConstants [
	ProcessorClass := BochsIA32Alien.
	NumSendTrampolines := 4
]

{ #category : #'class initialization' }
Cogit class >> initializeErrorCodes [
	self flag: 'these should be positive quantities and the check for error code should be a comparison against minCogMethodAddress/methodZoneBase'.
	NotFullyInitialized := -1.
	InsufficientCodeSpace := -2.
	YoungSelectorInPIC := -3.
	MaxUnreportableError := YoungSelectorInPIC.
	EncounteredUnknownBytecode := -4.
	MaxNegativeErrorCode := EncounteredUnknownBytecode
]

{ #category : #'class initialization' }
Cogit class >> initializeMiscConstantsWith: optionsDictionary [
	Debug := optionsDictionary at: #Debug ifAbsent: [false].
	(optionsDictionary includesKey: #EagerInstructionDecoration)
		ifTrue:
			[EagerInstructionDecoration := optionsDictionary at: #EagerInstructionDecoration]
		ifFalse:
			[EagerInstructionDecoration isNil ifTrue:
				[EagerInstructionDecoration := false]]. "speeds up single stepping but could lose fidelity"

	NewspeakVM := optionsDictionary at: #NewspeakVM ifAbsent: [false].
	"N.B.  Not yet implemented!!"
	IMMUTABILITY := optionsDictionary at: #IMMUTABILITY ifAbsent: [false].

	"Currently only the ceImplicitReceiverTrampoline contains object references."
	NumObjRefsInRuntime := 2
]

{ #category : #'class initialization' }
Cogit class >> initializePrimitiveTable [
	"Currently there is only one sequence of primitives."
	self initializePrimitiveTableForSqueakV3
]

{ #category : #'class initialization' }
Cogit class >> initializeWithOptions: optionsDictionary [

	self initializeMiscConstantsWith: optionsDictionary. "must preceed other initialization."
	self initializeErrorCodes.
	self initializeCogMethodConstants.
	self initializeAnnotationConstants.
	self initializeCompilationConstants.
	self initializeBytecodeTable.
	self initializePrimitiveTable
]

{ #category : #translation }
Cogit class >> isCogitClass [
	^true
]

{ #category : #translation }
Cogit class >> isNonArgumentImplicitReceiverVariableName: aString [
	^#('cogit' 'coInterpreter'
		'methodZone'
		'objectMemory' 'objectRepresentation') includes: aString
]

{ #category : #translation }
Cogit class >> mustBeGlobal: var [
	"Answer if a variable must be global and exported.  Used for inst vars that are accessed from VM
	 support code.  include cePositive32BitIntegerTrampoline as a hack to prevent it being inlined (it is
	 only used outside of Cogit by the object representation).  Include labelCounter as a hack to stop it
	 being inlined into genLabel, and CFramePointer CStackPointer as a hack to get them declared at all."
	^#('ceBaseFrameReturnTrampoline' 'ceCaptureCStackPointers' 'ceCheckForInterruptTrampoline'
		'ceEnterCogCodePopReceiverReg' 'realCEEnterCogCodePopReceiverReg'
		'ceEnterCogCodePopReceiverAndClassRegs' 'realCEEnterCogCodePopReceiverAndClassRegs'
		'ceReturnToInterpreterTrampoline' 'ceCannotResumeTrampoline'
		'cePositive32BitIntegerTrampoline' 'ceFlushICache' 'ceTryLockVMOwner' 'ceUnlockVMOwner'
		'cmEntryOffset' 'cmNoCheckEntryOffset' 'cmDynSuperEntryOffset'
		'blockNoContextSwitchOffset' 'breakPC'
		'labelCounter' 'CFramePointer' 'CStackPointer' 'cFramePointerInUse' 'ceGetSP'
		'traceLinkedSends' 'traceStores' 'debugPrimCallStackOffset')
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

{ #category : #translation }
Cogit class >> preGenerationHook: aCCodeGenerator [
	"Perform any last-minute changes to the code generator immediately
	 before it performs code analysis and generation.  In this case, make
	 all non-exported methods private."
	| exportAPISelectors |
	exportAPISelectors := self exportAPISelectors.
	aCCodeGenerator selectorsAndMethodsDo:
		[:s :m|
		(exportAPISelectors includes: s)
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
Cogit class >> requiredMethodNames [
	"self requiredMethodNames"
	^self exportAPISelectors
		addAll: self tableFunctions;
		yourself
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

{ #category : #'class initialization' }
Cogit class >> table: primArray from: specArray [ 
	"Fill in the specified entries in the primitive table."
	specArray do:
		[:spec | | descriptor |
		(primArray at: spec first put: CogPrimitiveDescriptor new)
			primitiveGenerator: spec second;
			primNumArgs: (spec at: 3 ifAbsent: -1);
			enabled: (spec at: 4 ifAbsent: nil)].
	primArray object withIndexDo:
		[:generator :i|
		generator ifNil:
			[(primArray object at: i put: CogPrimitiveDescriptor new)
				primNumArgs: -1]]
]

{ #category : #translation }
Cogit class >> tableFunctions [
	"self tableFunctions"
	self getVMMaker ifNotNil:
		[:vmMaker| vmMaker cogitClass ~= self ifTrue: [^Set new]].
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
		addAll: (primitiveTable object
					select: [:ea| ea notNil and: [ea enabled notNil]]
					thenCollect: [:ea| ea enabled]);
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
	| tuple |
	tuple := self cog: aCompiledMethod selector: aCompiledMethod selector.
	tuple second testPCMappingForMethod: tuple last
]

{ #category : #tests }
Cogit class >> testPCMappingSelect: aBlock [
	"Test pc mapping both ways using the methods in the current image"
	| cogit coInterpreter |
	self initialize.
	cogit := self new.
	coInterpreter := CurrentImageCoInterpreterFacade new cogit: cogit; yourself.
	[cogit
			setInterpreter: coInterpreter;
			singleStep: true;
			initializeCodeZoneFrom: 1024 upTo: coInterpreter memory size]
		on: Notification
		do: [:ex|
			(ex messageText beginsWith: 'cannot find receiver for') ifTrue:
				[ex resume: coInterpreter]].
	SystemNavigation new allSelect:
		[:m| | cm |
		(m isQuick not
		 and: [aBlock value: m]) ifTrue:
			[Transcript nextPut: $.; flush.
			 [cm := cogit
						cog: (coInterpreter oopForObject: m)
						selector: (coInterpreter oopForObject: m selector).
			   cm isNil and: [coInterpreter isCogCompiledCodeCompactionCalledFor]] whileTrue:
				[cogit methodZone clearCogCompiledCode.
				 coInterpreter clearCogCompiledCodeCompactionCalledFor.
				 coInterpreter initializeObjectMap].
			 cogit testPCMappingForMethod: cm].
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
	not used, but its addres is used as a key in the simulator.  An open PIC calls ceSendFromInLineCacheMiss
	after it has switched from the Smalltalk to teh C stack (an inline trampoline) hence there is no return pc
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
Cogit class >> typeForSelf [
	^#implicit
]

{ #category : #translation }
Cogit class >> wantsLabels [
	^true
]

{ #category : #'abstract instructions' }
Cogit >> AddCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AddCqR operand: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> AddCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AddCwR operand: wordConstant operand: reg
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
Cogit >> AlignmentNops: alignment [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AlignmentNops operand: alignment
]

{ #category : #'abstract instructions' }
Cogit >> AndCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AndCqR operand: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> AndCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: AndCwR operand: wordConstant operand: reg
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

{ #category : #'method map' }
Cogit >> CallNewspeakSend: callTarget [
	<returnTypeC: #'AbstractInstruction *'>
	^self annotateNewspeakSend: (self Call: callTarget)
]

{ #category : #'method map' }
Cogit >> CallRT: callTarget [
	<returnTypeC: #'AbstractInstruction *'>
	^self annotateCall: (self Call: callTarget)
]

{ #category : #'method map' }
Cogit >> CallSend: callTarget [
	<returnTypeC: #'AbstractInstruction *'>
	^self annotateSend: (self Call: callTarget)
]

{ #category : #'abstract instructions' }
Cogit >> CmpCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: CmpCqR operand: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> CmpCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: CmpCwR operand: wordConstant operand: reg
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
Cogit >> ConvertR: reg1 Rd: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: ConvertRRd operand: reg1 operand: dpreg2
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
Cogit >> Fill16: value [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	self assert: (value between: 0 and: 16rFFFF).
	^self gen: Fill16 operand: value
]

{ #category : #'abstract instructions' }
Cogit >> Fill32: value [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: Fill32 operand: value
]

{ #category : #'abstract instructions' }
Cogit >> FillFrom: address Word: value [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: FillFromWord operand: address operand: value
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
	^self gen: JumpAbove operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpAboveOrEqual: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpAboveOrEqual operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpBelow: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpBelow operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpBelowOrEqual: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpBelowOrEqual operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpCarry: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpCarry operand: jumpTarget asInteger
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
Cogit >> JumpGreater: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpGreater operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpGreaterOrEqual: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpGreaterOrEqual operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpLess: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpLess operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpLessOrEqual: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpLessOrEqual operand: jumpTarget asInteger
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
	^self gen: JumpLongNonZero operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpLongZero: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: JumpLongZero operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpNegative: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpNegative operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpNoCarry: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpNoCarry operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpNoOverflow: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpNoOverflow operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpNonNegative: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpNonNegative operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpNonZero: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpNonZero operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpOverflow: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpOverflow operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> JumpR: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: JumpR operand: reg
]

{ #category : #'method map' }
Cogit >> JumpRT: callTarget [
	"Big assumption here that calls and jumps look the same as regards their displacement.
	 This works on x86 and I think on ARM."
	<returnTypeC: #'AbstractInstruction *'>
	^self annotateCall: (self JumpLong: callTarget)
]

{ #category : #'abstract instructions' }
Cogit >> JumpZero: jumpTarget [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	<var: #jumpTarget type: #'void *'>
	^self gen: JumpZero operand: jumpTarget asInteger
]

{ #category : #'abstract instructions' }
Cogit >> Label [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: Label operand: (labelCounter := labelCounter + 1) operand: bytecodePointer
]

{ #category : #'abstract instructions' }
Cogit >> LoadEffectiveAddressMw: offset r: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: LoadEffectiveAddressMwrR operand: offset operand: baseReg operand: destReg
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
Cogit >> MoveAw: address R: reg [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveAwR operand: address operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> MoveCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveCqR operand: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> MoveCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveCwR operand: wordConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> MoveM16: offset r: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveM16rR operand: offset operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveM64: offset r: baseReg Rd: destDPReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveM64rRd operand: offset operand: baseReg operand: destDPReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveMb: offset r: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveMbrR operand: offset operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveMw: offset r: baseReg R: destReg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveMwrR operand: offset operand: baseReg operand: destReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: reg Aw: address [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRAw operand: reg operand: address
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: sourceReg Mb: offset r: baseReg [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRMbr operand: sourceReg operand: offset operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: sourceReg Mw: offset r: baseReg [ 
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRMwr operand: sourceReg operand: offset operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRR operand: reg1 operand: reg2
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
	^self gen: MoveRdM64r operand: sourceDPReg operand: offset operand: baseReg
]

{ #category : #'abstract instructions' }
Cogit >> MoveRd: dpreg1 Rd: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MoveRdRd operand: dpreg1 operand: dpreg2
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
	<returnTypeC: #'AbstractInstruction *'>
	<inline: false>
	backEnd genMulR: reg1 R: reg2.
	^self abstractInstructionAt: opcodeIndex - 1
]

{ #category : #'abstract instructions' }
Cogit >> MulRd: dpreg1 Rd: dpreg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: MulRdRd operand: dpreg1 operand: dpreg2
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
Cogit >> OrCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: OrCqR operand: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> OrCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: OrCwR operand: wordConstant operand: reg
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
Cogit >> PrefetchAw: address [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: PrefetchAw operand: address
]

{ #category : #'abstract instructions' }
Cogit >> PushCw: wordConstant [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: PushCw operand: wordConstant
]

{ #category : #'abstract instructions' }
Cogit >> PushR: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: PushR operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> RetN: offset [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: RetN operand: offset
]

{ #category : #'abstract instructions' }
Cogit >> SqrtRd: dpreg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SqrtRd operand: dpreg
]

{ #category : #'abstract instructions' }
Cogit >> SubCq: quickConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SubCqR operand: quickConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> SubCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: SubCwR operand: wordConstant operand: reg
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
Cogit >> XorCw: wordConstant R: reg [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: XorCwR operand: wordConstant operand: reg
]

{ #category : #'abstract instructions' }
Cogit >> XorR: reg1 R: reg2 [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^self gen: XorRR operand: reg1 operand: reg2
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
	^abstractOpcodes at: index
]

{ #category : #accessing }
Cogit >> abstractOpcodes [
	"For CogAbstractInstruction>>#>, which in turn is for Cogit>>abstractInstruction:follows:"
	<doNotGenerate>
	^abstractOpcodes
]

{ #category : #'compile abstract instructions' }
Cogit >> addBlockStartAt: bytecodepc numArgs: numArgs numCopied: numCopied span: span [
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
			   blockStart startpc > bytecodepc
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
		startpc: bytecodepc;
		numArgs: numArgs;
		numCopied: numCopied;
		stackCheckLabel: nil;
		span: span.
	^blockStart
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
			[self heapMapAtWord: cogMethod Put: 1].
		cogMethod := methodZone methodAfter: cogMethod]
]

{ #category : #testing }
Cogit >> addressIsInFixups: address [
	<var: #address type: #'void *'>
	^self cCode: 'address >= (void *)&fixups[0] && address < (void *)&fixups[numAbstractOpcodes]'
		inSmalltalk: [fixups notNil
					and: [(fixups object identityIndexOf: address) between: 1 and: numAbstractOpcodes]]
]

{ #category : #testing }
Cogit >> addressIsInInstructions: address [
	<var: #address type: #'void *'>
	^self cCode: 'address >= (void *)&abstractOpcodes[0] && address < (void *)&abstractOpcodes[opcodeIndex]'
		inSmalltalk: [(abstractOpcodes object identityIndexOf: address) between: 1 and: opcodeIndex]
]

{ #category : #'in-line cacheing' }
Cogit >> addressOfEndOfCase: n inCPIC: cPIC [
	"N.B. zero-relative"
	<var: #cPIC type: #'CogMethod *'>
	^cPIC asInteger + firstCPICCaseOffset + (n * cPICCaseSize)
]

{ #category : #accessing }
Cogit >> addressSpaceMask [
	<doNotGenerate>
	^(1 << (8 * BytesPerWord)) - 1
]

{ #category : #'generate machine code' }
Cogit >> alignUptoRoutineBoundary: anAddress [ 
	^anAddress + 7 bitAnd: 7 bitInvert32
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
			[(self asserta: (objectRepresentation checkValidObjectReference: cogMethod selector)) ifFalse:
				[ok := false].
			 (self asserta: (self cogMethodDoesntLookKosher: cogMethod) = 0) ifFalse:
				[ok := false]].
		(cogMethod cmType = CMMethod
		 or: [cogMethod cmType = CMOpenPIC]) ifTrue:
			[(self asserta: ((self mapFor: cogMethod
								 performUntil: #checkIfValidObjectRefAndTarget:pc:cogMethod: asSymbol
								 arg: cogMethod asInteger) = 0)) ifFalse:
				[ok := false]].
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
		blockStarts = numBlocks ? alloca(sizeof(BlockStart) * numBlocks) : 0; \
} while (0)'>
	blockStarts := numBlocks > 0 ifTrue:
					[CArrayAccessor on:
						((1 to: numBlocks) collect:
							[:ign| CogBlockStart new])]
]

{ #category : #initialization }
Cogit >> allocateOpcodes: numberOfAbstractOpcodes bytecodes: numberOfBytecodes [
	"Allocate the various arrays needed to compile abstract instructions.
	 This needs to be a macro since the arrays are alloca'ed (stack allocated)
	 to ensure their being freed when compilation is done.
	 Notionally we only need as many fixups as there are bytecodes.  But we
	 reuse fixups to record pc-dependent instructions in generateInstructionsAt:
	 and so need at least as many as there are abstract opcodes.

	 N.B. We do one single alloca to save embarrassing C optimizers that
	 generate incorrect code as both gcc and the intel compiler do on x86."
	<cmacro: '(numberOfAbstractOpcodes,numberOfBytecodes) do { \
		int opcodeSize = sizeof(AbstractInstruction) * (numAbstractOpcodes = (numberOfAbstractOpcodes)); \
		int fixupSize = sizeof(BytecodeFixup) * numAbstractOpcodes; \
		int annotationSize = sizeof(InstructionAnnotation) * ((numAbstractOpcodes + 3) / 4); \
		abstractOpcodes = alloca(opcodeSize + fixupSize + annotationSize); \
		bzero(abstractOpcodes, opcodeSize + fixupSize); \
		fixups = (void *)((char *)abstractOpcodes + opcodeSize); \
		annotations = (void *)((char *)fixups + fixupSize); \
		opcodeIndex = labelCounter = annotationIndex = 0; \
} while (0)'>
	numAbstractOpcodes := numberOfAbstractOpcodes.
	abstractOpcodes := CArrayAccessor on:
						((1 to: numAbstractOpcodes) collect:
							[:ign| processor abstractInstructionCompilerClass for: self]).
	fixups := CArrayAccessor on:
						((1 to: numAbstractOpcodes) collect:
							[:ign| self bytecodeFixupClass new]).
	annotations := CArrayAccessor on:
						((1 to: numAbstractOpcodes + 3 // 4) collect:
							[:ign| CogInstructionAnnotation new]).
	opcodeIndex := labelCounter := annotationIndex := 0
]

{ #category : #'method map' }
Cogit >> annotate: abstractInstruction objRef: anOop [
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	(objectRepresentation shouldAnnotateObjectReference: anOop) ifTrue:
		[(objectMemory isYoung: anOop) ifTrue:
			[hasYoungReferent := true].
		^self annotate: abstractInstruction with: IsObjectReference].
	^abstractInstruction
]

{ #category : #'method map' }
Cogit >> annotate: abstractInstruction with: annotationFlag [ "<Integer>"
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	| annotation |
	<var: #annotation type: #'InstructionAnnotation *'>
	annotation := self addressOf: (annotations at: annotationIndex).
	annotationIndex := annotationIndex + 1.
	annotation
		instruction: abstractInstruction;
		annotation: annotationFlag.
	^abstractInstruction
]

{ #category : #'method map' }
Cogit >> annotateAbsolutePCRef: abstractInstruction [
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^self annotate: abstractInstruction with: IsAbsPCReference
]

{ #category : #'method map' }
Cogit >> annotateBytecode: abstractInstruction [
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^self annotate: abstractInstruction with: HasBytecodePC
]

{ #category : #'method map' }
Cogit >> annotateCall: abstractInstruction [
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^self annotate: abstractInstruction with: IsRelativeCall
]

{ #category : #'method map' }
Cogit >> annotateNewspeakSend: abstractInstruction [
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^self annotate: abstractInstruction with: IsNSSendCall
]

{ #category : #'method map' }
Cogit >> annotateSend: abstractInstruction [
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	<returnTypeC: #'AbstractInstruction *'>
	<inline: true>
	^self annotate: abstractInstruction with: IsSendCall
]

{ #category : #'simulation only' }
Cogit >> assertCStackWellAligned [
	"Check alignment of the C stack.  This is a simulation only facsimilie.
	 See platforms/Cross/vm/sqCogStackAlignment.h for the real code."
	<doNotGenerate>
	self assert: processor sp \\ cStackAlignment = expectedSPAlignment.
	self assert: processor fp \\ cStackAlignment = expectedFPAlignment
]

{ #category : #debugging }
Cogit >> assertSaneJumpTarget: jumpTarget [
	<var: #jumpTarget type: #'void *'>

	self assert: (closedPICSize isNil "don't whinge when producing the PIC prototypes"
			or: [openPICSize isNil
			or: [(self addressIsInInstructions: jumpTarget)
			or: [(jumpTarget asInteger
					between: codeBase
					and: methodZone limitZony asInteger + (closedPICSize max: openPICSize))]]])
]

{ #category : #'tests-method map' }
Cogit >> bcpcsAndDescriptorsFor: aMethodObj do: trinaryBlock [
	<doNotGenerate>
	| byte descriptor endpc latestContinuation pc primIdx |
	((primIdx := coInterpreter primitiveIndexOf: aMethodObj) > 0
	and: [coInterpreter isQuickPrimitiveIndex: primIdx]) ifTrue:
		[^self].
	latestContinuation := pc := coInterpreter startPCOfMethod: aMethodObj.
	trinaryBlock value: pc value: nil value: nil. "stackCheck/entry pc"
	endpc := objectMemory byteSizeOf: aMethodObj.
	[pc <= endpc] whileTrue:
		[byte := objectMemory fetchByte: pc ofObject: aMethodObj.
		descriptor := self generatorAt: byte.
		trinaryBlock value: pc value: byte value: descriptor.
		(descriptor isReturn
		 and: [pc >= latestContinuation]) ifTrue:
			[endpc := pc].
		(descriptor isBranch
		 or: [descriptor isBlockCreation]) ifTrue:
			[| targetPC |
			 descriptor isBlockCreation ifTrue:
				[trinaryBlock value: pc + descriptor numBytes value: nil value: nil]. "stackCheck/entry pc"
			 targetPC := self latestContinuationPCFor: descriptor at: pc byte0: byte in: aMethodObj.
			 latestContinuation := latestContinuation max: targetPC].
		pc := pc + descriptor numBytes]
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
				[targetpc := backEnd jumpTargetAt: pc.
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
			[targetpc := backEnd jumpTargetAt: pc.
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
	^blockStarts at: index
]

{ #category : #disassembly }
Cogit >> blockStartPcsIn: aMethod [
	"Answer the start bytecopde pcs in a method in compilation order, i.e. depth-first.
	 Blocks must occur in pc/depth-first order for binary tree block dispatch to work."
	| startpcs pc latestContinuation end descriptor byte |
	<doNotGenerate>
	startpcs := OrderedCollection new.
	startpcs add: (pc := latestContinuation := coInterpreter startPCOfMethod: aMethod).
	end := objectMemory byteSizeOf: aMethod.
	[pc <= end] whileTrue:
		[descriptor := self generatorAt: (byte := objectMemory fetchByte: pc ofObject: aMethod).
		(descriptor isReturn
		 and: [pc >= latestContinuation]) ifTrue:
			[end := pc].
		(descriptor isBranch
		 or: [descriptor isBlockCreation]) ifTrue:
			[| targetPC |
			 targetPC := self latestContinuationPCFor: descriptor at: pc byte0: byte in: aMethod.
			 latestContinuation := latestContinuation max: targetPC].
		 pc := pc + descriptor numBytes.
		 descriptor isBlockCreation ifTrue:
			[startpcs add: pc]].
	^startpcs
]

{ #category : #'simulation only' }
Cogit >> breakBlock: aBlock [
	<doNotGenerate>
	breakBlock := aBlock
]

{ #category : #'simulation only' }
Cogit >> breakMethod [
	<doNotGenerate>
	^breakMethod
]

{ #category : #debugging }
Cogit >> breakOnImplicitReceiver [
	<api>
	<cmacro: '() (traceLinkedSends & 32)'>
	^(traceLinkedSends bitAnd: 32) ~= 0
]

{ #category : #'simulation only' }
Cogit >> breakPC [
	<doNotGenerate>
	^breakPC
]

{ #category : #'simulation only' }
Cogit >> breakPC: anAddress [
	<doNotGenerate>
	breakPC := anAddress.
	"If there's a breakPC then it is anded with breakBlock's result, so the breakBlock must default to true.
	If there's no breakPC the break block is used on its own and so must befault to false."
	(breakBlock isNil
	 or: [breakBlock method = thisContext method]) ifTrue:
		[breakBlock := breakPC isInteger
						ifTrue: [[:cogit| true]]
						ifFalse: [[:cogit| false]]]
]

{ #category : #'generate machine code' }
Cogit >> byteAt: anAddress put: aValue [
	"Store a byte in memory.  In Smaltalk defer to the coInterpreter.
	 In C this will be replaced by a macro (byteAtPut)."
	<doNotGenerate> 
	objectMemory byteAt: anAddress put: aValue
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
		performUntil: #findMcpc:Bcpc:MatchingMcpc: asSymbol
		arg: (self cCoerceSimple: mcpc to: #'void *')
]

{ #category : #'translation support' }
Cogit >> cCoerceSimple: value to: cTypeString [
	<doNotGenerate>
	cTypeString == #'CogMethod *' ifTrue:
		[^(value isInteger and: [value < 0])
			ifTrue: [value] "it's an error code; leave it be"
			ifFalse: [self cogMethodSurrogateAt: value asUnsignedInteger]].
	cTypeString == #'CogBlockMethod *' ifTrue:
		[^self cogBlockMethodSurrogateAt: value asUnsignedInteger].
	^super cCoerceSimple: value to: cTypeString
]

{ #category : #'trampoline support' }
Cogit >> cFramePointerAddress [
	<cmacro: '() ((unsigned long)&CFramePointer)'>
	^coInterpreter inMemoryCFramePointerAddress
]

{ #category : #'in-line cacheing' }
Cogit >> cPIC: cPIC HasTarget: targetMethod [
	<var: #cPIC type: #'CogMethod *'>
	<var: #targetMethod type: #'CogMethod *'>
	| pc target |
	target := targetMethod asUnsignedInteger + cmNoCheckEntryOffset.
	pc := cPIC asInteger + firstCPICCaseOffset.
	1 to: cPIC cPICNumCases do:
		[:i|
		target = (backEnd jumpLongTargetBeforeFollowingAddress: pc) ifTrue:
			[^true].
		pc := pc + cPICCaseSize].
	^false
]

{ #category : #'in-line cacheing' }
Cogit >> cPICHasFreedTargets: cPIC [
	<var: #cPIC type: #'CogMethod *'>
	| pc entryPoint targetMethod |
	<var: #targetMethod type: #'CogMethod *'>
	pc := cPIC asInteger + firstCPICCaseOffset.
	1 to: cPIC cPICNumCases do:
		[:i|
		entryPoint := backEnd jumpLongTargetBeforeFollowingAddress: pc.
		"Find target from jump.  Ignore jumps to the interpret and MNU calls within this PIC"
		(entryPoint < cPIC asInteger
		 or: [entryPoint > (cPIC asInteger + cPIC blockSize)]) ifTrue:
			[targetMethod := self cCoerceSimple: entryPoint - cmNoCheckEntryOffset to: #'CogMethod *'.
			 self assert: (targetMethod cmType = CMMethod or: [targetMethod cmType = CMFree]).
			 targetMethod cmType = CMFree ifTrue:
				[^true]].
		pc := pc + cPICCaseSize].
	^false
]

{ #category : #'trampoline support' }
Cogit >> cStackPointerAddress [
	<cmacro: '() ((unsigned long)&CStackPointer)'>
	^coInterpreter inMemoryCStackPointerAddress
]

{ #category : #'jit - api' }
Cogit >> canLinkToYoungClasses [
	<api>
	^methodZone roomOnYoungReferrersList
]

{ #category : #accessing }
Cogit >> ceBaseFrameReturnPC [
	<api>
	<cmacro: '() ceBaseFrameReturnTrampoline'>
	^ceBaseFrameReturnTrampoline
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
	outerReturn := coInterpreter stackTop.
	cPIC cPICNumCases < numPICCases ifTrue:
		[self lookup: cPIC selector
			for: receiver
			methodAndErrorSelectorInto:
				[:method :errsel|
				newTargetMethodOrNil := method.
				errorSelectorOrNil := errsel]].
	"We assume lookupAndCog:for: will *not* reclaim the method zone"
	self assert: outerReturn = coInterpreter stackTop.
	cacheTag := objectRepresentation inlineCacheTagForInstance: receiver.
	(cPIC cPICNumCases >= numPICCases
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
		executeCogMethodFromLinkedSend: cPIC
		withReceiver: receiver
		andCacheTag: (backEnd inlineCacheTagAt: outerReturn).
	"NOTREACHED"
	^nil
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
	| range |
	coInterpreter isThreadedVM ifFalse:
		[^self].
	thisContext sender selector == #generateStackPointerCapture ifTrue:
		[^self].
	range := coInterpreter cStackRangeForThreadIndex: coInterpreter threadManager getVMOwner.
	self assert: (range notNil "VM is owned"
				and: [(range includes: processor sp)
				and: [range includes: processor fp]]).
	self setCStackPointer: processor sp.
	self setCFramePointer: processor fp
]

{ #category : #testing }
Cogit >> ceCheckFeatures [
	<cmacro: '() ceCheckFeaturesFunction()'>
	^self simulateLeafCallOf: ceCheckFeaturesFunction
]

{ #category : #'simulation only' }
Cogit >> ceEnterCogCodePopReceiverAndClassRegs [
	<api: 'extern void (*ceEnterCogCodePopReceiverAndClassRegs)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceEnterCogCodePopReceiverAndClassRegs numArgs: 2
]

{ #category : #'simulation only' }
Cogit >> ceEnterCogCodePopReceiverReg [
	<api: 'extern void (*ceEnterCogCodePopReceiverReg)()'>
	<doNotGenerate>
	self simulateEnilopmart: ceEnterCogCodePopReceiverReg numArgs: 1
]

{ #category : #'in-line cacheing' }
Cogit >> ceImplicitReceiverFor: selector receiver: receiver class: rcvrClass [
	"Cached implicit receiver implementation.  Caller looks like
		mov selector, ClassReg
				call ceImplicitReceiver
				br continue
		Lclass	.word
		Lmixin:	.word
		continue:
	 The trampoline has already fetched the class and probed the cache and found
	 that the cache missed.  Compute the implicit receiver for the receiver's class
	 and reload the class.  If either the class or the mixin are young the method needs
	 to be added to the youngReferrers list to ensure correct GC."

	| retpc classpc mixinpc mixin cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	retpc := coInterpreter stackTop.
	classpc := retpc + backEnd jumpShortByteSize.
	mixinpc := retpc + backEnd jumpShortByteSize + BytesPerOop.
	self assert: rcvrClass ~= (backEnd unalignedLongAt: classpc).
	mixin := coInterpreter
				implicitReceiverFor: receiver
				mixin: coInterpreter mMethodClass
				implementing: selector.
	cogMethod := coInterpreter mframeHomeMethodExport.
	cogMethod cmRefersToYoung ifFalse:
		[((objectMemory isYoung: rcvrClass)
		  or: [mixin ~= receiver and: [objectMemory isYoung: mixin]]) ifTrue:
			[methodZone roomOnYoungReferrersList ifFalse:
				[coInterpreter callForCogCompiledCodeCompaction.
				 ^mixin].
			 cogMethod cmRefersToYoung: true.
			 methodZone addToYoungReferrers: cogMethod]].
	backEnd unalignedLongAt: classpc put: rcvrClass.
	backEnd unalignedLongAt: mixinpc put: (mixin = receiver ifTrue: [0] ifFalse: [mixin]).
	^mixin
]

{ #category : #accessing }
Cogit >> cePositive32BitIntegerTrampoline [
	<cmacro: '() cePositive32BitIntegerTrampoline'>
	^cePositive32BitIntegerTrampoline
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
	innerReturn := coInterpreter popStack.
	targetMethod := self cCoerceSimple: innerReturn - missOffset to: #'CogMethod *'.
	outerReturn := coInterpreter stackTop.
	self assert: (outerReturn between: methodZoneBase and: methodZone zoneLimit).
	entryPoint := backEnd callTargetFromReturnAddress: outerReturn.

	self assert: targetMethod selector ~= objectMemory nilObject.
	self cppIf: NewspeakVM ifTrue:
		[self assert: (targetMethod asInteger + cmEntryOffset = entryPoint
					or: [targetMethod asInteger + cmDynSuperEntryOffset = entryPoint]).
		 "Avoid the effort of implementing PICs for the relatively low dynamic frequency
		  dynamic super send and simply rebind the send site."
		 targetMethod asInteger + cmDynSuperEntryOffset = entryPoint ifTrue:
			[^coInterpreter
				ceDynamicSuperSend: targetMethod selector
				to: receiver
				numArgs: targetMethod cmNumArgs]].
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
	 or: [newTargetMethodOrNil isNil
	 or: [objectMemory isYoung: newTargetMethodOrNil]]]) ifTrue:
		[result := self patchToOpenPICFor: targetMethod selector
					numArgs: targetMethod cmNumArgs
					receiver: receiver.
		 self assert: result not. "If patchToOpenPICFor:.. returns we're out of code memory"
		 ^coInterpreter ceSendFromInLineCacheMiss: targetMethod].
	"See if an Open PIC is already available."
	pic := methodZone openPICWithSelector: targetMethod selector.
	pic isNil ifTrue:
		["otherwise attempt to create a closed PIC for the two cases."
		 pic := self cogPICSelector: targetMethod selector
					numArgs: targetMethod cmNumArgs
					Case0Method: targetMethod
					Case1Method: newTargetMethodOrNil
					tag: cacheTag
					isMNUCase: errorSelectorOrNil = SelectorDoesNotUnderstand.
		 (errorSelectorOrNil notNil
		  or: [pic asInteger between: MaxNegativeErrorCode and: -1]) ifTrue:
			["If for some reason the PIC couldn't be generated, most likely a lack of code memory.
			  Continue as if this is an unlinked send.  If this is an error case continue as if this is an
			  unlinked send to invoke the appropriate error behavior (MNU, cannot interpret et al)."
			 pic asInteger = InsufficientCodeSpace ifTrue:
				[coInterpreter callForCogCompiledCodeCompaction].
			^coInterpreter ceSendFromInLineCacheMiss: targetMethod]].
	extent := backEnd
				rewriteCallAt: outerReturn
				target: pic asInteger + cmEntryOffset.
	processor
		flushICacheFrom: outerReturn - 1 - extent to: outerReturn - 1;
		flushICacheFrom: pic asInteger to: pic asInteger + closedPICSize.
	"Jump back into the pic at its entry in case this is an MNU (newTargetMethodOrNil is nil)"
	coInterpreter
		executeCogMethodFromLinkedSend: pic
		withReceiver: receiver
		andCacheTag: (backEnd inlineCacheTagAt: outerReturn).
	"NOTREACHED"
	^nil
]

{ #category : #accessing }
Cogit >> ceStoreCheckTrampoline [
	<cmacro: '() ceStoreCheckTrampoline'>
	^ceStoreCheckTrampoline
]

{ #category : #debugging }
Cogit >> checkAssertsEnabledInCogit [
	<api>
	| assertsAreEnabledInCogit |
	assertsAreEnabledInCogit := false.
	self assert: assertsAreEnabledInCogit
]

{ #category : #debugging }
Cogit >> checkEnoughOpcodes [
	<inline: true>
	opcodeIndex > numAbstractOpcodes ifTrue:
		[self error: 'Cog JIT internal error. Too many abstract opcodes.  Num opcodes heuristic is too optimistic.']
]

{ #category : #'garbage collection' }
Cogit >> checkIfValidObjectRef: annotation pc: mcpc cogMethod: cogMethod [
	<var: #mcpc type: #'char *'>
	annotation = IsObjectReference ifTrue:
		[| literal |
		 literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 (objectRepresentation checkValidObjectReference: literal) ifFalse:
			[self print: 'object ref leak in CM '; printHex: cogMethod asInteger; print: ' @ '; printHex: mcpc asInteger; cr.
			^1]].
	(self isSendAnnotation: annotation) ifTrue:
		[| cacheTag |
		 cacheTag := backEnd inlineCacheTagAt: mcpc asInteger.
		 (objectRepresentation checkValidInlineCacheTag: cacheTag) ifFalse:
			[self print: 'cache tag/selector leak in CM '; printHex: cogMethod asInteger; print: ' @ '; printHex: mcpc asInteger; cr.
			^1]].
	^0 "keep scanning"
]

{ #category : #'garbage collection' }
Cogit >> checkIfValidObjectRefAndTarget: annotation pc: mcpc cogMethod: cogMethod [
	<var: #mcpc type: #'char *'>
	| literal cacheTag entryPoint offset targetMethod |
	<var: #targetMethod type: #'CogMethod *'>
	annotation = IsObjectReference ifTrue:
		[literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 (self asserta: (objectRepresentation checkValidObjectReference: literal)) ifFalse:
			[^1].
		((objectRepresentation couldBeObject: literal)
		 and: [coInterpreter isReallyYoungObject: literal]) ifTrue:
			[(self asserta: (self cCoerceSimple: cogMethod to: #'CogMethod *') cmRefersToYoung) ifFalse:
				[^2]]].
	(self isSendAnnotation: annotation) ifTrue:
		[(self asserta: (self cCoerceSimple: cogMethod to: #'CogMethod *') cmType = CMMethod) ifFalse:
			[^3].
		 cacheTag := backEnd inlineCacheTagAt: mcpc asInteger.
		 (self asserta: (objectRepresentation checkValidInlineCacheTag: cacheTag)) ifFalse:
			[^4].
		((objectRepresentation couldBeObject: cacheTag)
		 and: [coInterpreter isReallyYoungObject: cacheTag]) ifTrue:
			[(self asserta: (self cCoerceSimple: cogMethod to: #'CogMethod *') cmRefersToYoung) ifFalse:
				[^5]].
		entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		entryPoint > methodZoneBase ifTrue:
			["It's a linked send; find which kind."
			 self
				offsetAndSendTableFor: entryPoint
				annotation: annotation
				into: [:off :table| offset := off].
			 targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
			 (self asserta: (targetMethod cmType = CMMethod
						   or: [targetMethod cmType = CMClosedPIC
						   or: [targetMethod cmType = CMOpenPIC]])) ifFalse:
				[^6]]].
	^0 "keep scanning"
]

{ #category : #debugging }
Cogit >> checkIntegrityOfObjectReferencesInCode: fullGCFlag [
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
					[self print: 'young referrer CM '; printHex: cogMethod asInteger.
					 count = 0
						ifTrue: [self print: ' is not in youngReferrers'; cr]
						ifFalse: [self print: ' is in youngReferrers '; printNum: count; print: ' times!'; cr].
					 ok := false]].
			 (objectRepresentation checkValidObjectReference: cogMethod selector) ifFalse:
				[self print: 'object leak in CM '; printHex: cogMethod asInteger; print: ' selector'; cr.
				 ok := false].
			 cogMethod cmType = CMMethod
				ifTrue:
					[self assert: cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod.
					 (objectRepresentation checkValidObjectReference: cogMethod methodObject) ifFalse:
						[self print: 'object leak in CM '; printHex: cogMethod asInteger; print: ' methodObject'; cr.
						 ok := false].
					 (self mapFor: cogMethod
						 performUntil: #checkIfValidObjectRef:pc:cogMethod: asSymbol
						 arg: cogMethod asInteger) ~= 0
							ifTrue: [ok := false].
					 fullGCFlag ifFalse:
						[(((objectMemory isYoung: cogMethod methodObject)
						    or: [objectMemory isYoung: cogMethod selector])
						   and: [cogMethod cmRefersToYoung not]) ifTrue:
							[self print: 'CM '; printHex: cogMethod asInteger; print: ' refers to young but not marked as such'; cr.
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
										performUntil: #checkIfValidObjectRef:pc:cogMethod: asSymbol
										arg: cogMethod asInteger) ~= 0
											ifTrue: [ok := false]]]]].
		cogMethod := methodZone methodAfter: cogMethod].
	^ok
]

{ #category : #'garbage collection' }
Cogit >> checkMaybeObjRefAt: mcpc [
	| maybeObject |
	maybeObject := backEnd literalBeforeFollowingAddress: mcpc.
	(objectRepresentation couldBeObject: maybeObject) ifFalse:
		[^true].
	^objectRepresentation checkValidObjectReference: maybeObject
]

{ #category : #initialization }
Cogit >> checkPrimitiveTableEnablers [
	"Disable primitive generators with enablers that answer false."
	| primitiveDescriptor |
	<var: #primitiveDescriptor type: #'PrimitiveDescriptor *'>
	1 to: MaxCompiledPrimitiveIndex do:
		[:i|
		primitiveDescriptor := self addressOf: (primitiveGeneratorTable at: i).
		primitiveDescriptor enabled notNil ifTrue:
			[(self perform: primitiveDescriptor enabled with: i) ifFalse:
				[primitiveDescriptor primitiveGenerator: nil]]]
]

{ #category : #'garbage collection' }
Cogit >> checkValidObjectReferencesInClosedPIC: cPIC [
	<var: #cPIC type: #'CogMethod *'>
	| ok pc |
	ok := true.
	pc := cPIC asInteger + firstCPICCaseOffset.
	(self checkMaybeObjRefAt: pc - backEnd jumpLongByteSize) ifFalse:
		[self print: 'object leak in CPIC '; printHex: cPIC asInteger;
			print: ' @ '; printHex: pc - backEnd jumpLongByteSize; cr.
		 ok := false].
	pc := pc + cPICCaseSize.
	2 to: cPIC cPICNumCases do:
		[:i|
		(self checkMaybeObjRefAt: pc - backEnd jumpLongConditionalByteSize - backEnd loadLiteralByteSize) ifFalse:
			[self print: 'object leak in CPIC '; printHex: cPIC asInteger;
				print: ' @ '; printHex: pc - backEnd jumpLongConditionalByteSize - backEnd loadLiteralByteSize; cr.
			 ok := false].
		(self checkMaybeObjRefAt: pc - backEnd jumpLongConditionalByteSize) ifFalse:
			[self print: 'object leak in CPIC '; printHex: cPIC asInteger;
				print: ' @ '; printHex: pc - backEnd jumpLongConditionalByteSize; cr.
			 ok := false].
		pc := pc + cPICCaseSize].
	^ok
]

{ #category : #'garbage collection' }
Cogit >> closedPICRefersToUnmarkedObject: cPIC [
	"Answer if the ClosedPIC refers to any unmarked objects or freed/freeable target methods,
	 applying markAndTraceOrFreeCogMethod:firstVisit: to those targets to determine if freed/freeable."
	<var: #cPIC type: #'CogMethod *'>
	| pc offsetToLiteral object entryPoint targetMethod |
	<var: #targetMethod type: #'CogMethod *'>
	(objectMemory isMarked: cPIC selector)  ifFalse:
		[^true].
	pc := cPIC asInteger + firstCPICCaseOffset.
	"First jump is unconditional; subsequent ones are conditional"
	offsetToLiteral := backEnd jumpLongByteSize.
	1 to: cPIC cPICNumCases do:
		[:i|
		object := backEnd literalBeforeFollowingAddress: pc - offsetToLiteral - backEnd loadLiteralByteSize.
		((objectRepresentation couldBeObject: object)
		 and: [(objectMemory isMarked: object) not]) ifTrue:
			[^true].
		object := backEnd literalBeforeFollowingAddress: pc - offsetToLiteral.
		((objectRepresentation couldBeObject: object)
		 and: [(objectMemory isMarked: object) not]) ifTrue:
			[^true].
		entryPoint := backEnd jumpLongTargetBeforeFollowingAddress: pc.
		"Find target from jump.  Ignore jumps to the interpret and MNU calls within this PIC"
		(entryPoint asUnsignedInteger < cPIC asUnsignedInteger
		 or: [entryPoint asUnsignedInteger > (cPIC asUnsignedInteger + cPIC blockSize) asUnsignedInteger]) ifTrue:
			[targetMethod := self cCoerceSimple: entryPoint - cmNoCheckEntryOffset to: #'CogMethod *'.
			 self assert: (targetMethod cmType = CMMethod
						or: [targetMethod cmType = CMFree]).
			 (self markAndTraceOrFreeCogMethod: targetMethod
				  firstVisit: targetMethod asUnsignedInteger > pc asUnsignedInteger) ifTrue:
				[^true]].
		offsetToLiteral := backEnd jumpLongConditionalByteSize.
		pc := pc + cPICCaseSize].
	^false
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
		[end := (self addressOfEndOfCase: cogMethod cPICNumCases - 1 inCPIC: cogMethod) + cPICEndSize.
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
				startpc: (coInterpreter startPCOfMethodHeader: cogMethod methodHeader) }].
	pc := blockEntry := cogMethod blockEntryOffset + cogMethod asInteger.
	starts := OrderedCollection with: cogMethod.
	[pc < end] whileTrue:
		[| targetpc |
		 targetpc := blockEntry.
		 (backEnd isJumpAt: pc) ifTrue:
			[targetpc := backEnd jumpTargetAt: pc.
			 targetpc < blockEntry ifTrue:
				[starts add: (self cCoerceSimple: targetpc - (self sizeof: CogBlockMethod) to: #'CogBlockMethod *')]].
		 pc := pc + (backEnd instructionSizeAt: pc)].
	starts := starts asSortedCollection.
	^(1 to: starts size + 1) collect:
		[:i| | cogSubMethod nextpc |
		i <= starts size
			ifTrue:
				[cogSubMethod := starts at: i.
				 nextpc := i < starts size ifTrue: [(starts at: i + 1) address] ifFalse: [end].
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
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	self assert: ((coInterpreter methodHasCogMethod: aMethodObj) not
				or: [(self noAssertMethodClassAssociationOf: aMethodObj) = objectMemory nilObject]).
	"coInterpreter stringOf: aSelectorOop"
	coInterpreter
		compilationBreak: aSelectorOop
		point: (objectMemory lengthOf: aSelectorOop).
	aMethodObj = breakMethod ifTrue: [self halt: 'Compilation of breakMethod'].
	self cppIf: NewspeakVM
		ifTrue: [cogMethod := methodZone findPreviouslyCompiledVersionOf: aMethodObj with: aSelectorOop.
				cogMethod ifNotNil:
					[(coInterpreter methodHasCogMethod: aMethodObj) not ifTrue:
						[self assert: (coInterpreter rawHeaderOf: aMethodObj) = cogMethod methodHeader.
						 cogMethod methodObject: aMethodObj.
						 coInterpreter rawHeaderOf: aMethodObj put: cogMethod asInteger].
					^cogMethod]].
	"The alternate bytecode set is for now always interpreted."
	(coInterpreter methodUsesAlternateBytecodeSet: aMethodObj) ifTrue:
		[^nil].
	methodObj := aMethodObj.
	cogMethod := self compileCogMethod: aSelectorOop.
	(cogMethod asInteger between: MaxNegativeErrorCode and: -1) ifTrue:
		[cogMethod asInteger >= MaxUnreportableError
			ifTrue:
				[cogMethod asInteger = InsufficientCodeSpace ifTrue:
					[coInterpreter callForCogCompiledCodeCompaction]]
			ifFalse:
				[self reportError: (self cCoerceSimple: cogMethod to: #sqInt)].
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
	self assert: (address bitAnd: BytesPerWord - 1) = 0.
	^cogBlockMethodSurrogateClass new
		at: address
		memory: objectMemory memory
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

{ #category : #'profiling primitives' }
Cogit >> cogCodeConstituents [
	"Answer the contents of the code zone as an array of pair-wise element, address in ascending address order.
	 Answer a string for a runtime routine or abstract label (beginning, end, etc), a CompiledMethod for a CMMethod,
	 or a selector (presumably a Symbol) for a PIC."
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
	constituents isNil ifTrue:
		[^constituents].
	coInterpreter pushRemappableOop: constituents.
	((label := coInterpreter stringForCString: 'CogCode') isNil
	 or: [(value := coInterpreter cePositive32BitIntegerFor: codeBase) isNil]) ifTrue:
		[^nil].
	coInterpreter
		storePointerUnchecked: 0 ofObject: coInterpreter topRemappableOop withValue: label;
		storePointerUnchecked: 1 ofObject: coInterpreter topRemappableOop withValue: value.
	0 to: trampolineTableIndex - 1 by: 2 do:
		[:i|
		((label := coInterpreter stringForCString: (trampolineAddresses at: i)) isNil
		 or: [(value := coInterpreter cePositive32BitIntegerFor: (trampolineAddresses at: i + 1) asUnsignedInteger) isNil]) ifTrue:
			[coInterpreter popRemappableOop.
			 ^nil].
		coInterpreter
			storePointerUnchecked: 2 + i ofObject: coInterpreter topRemappableOop withValue: label;
			storePointerUnchecked: 3 + i ofObject: coInterpreter topRemappableOop withValue: value].
	count := trampolineTableIndex + 2.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType ~= CMFree ifTrue:
			[coInterpreter
				storePointerUnchecked: count
				ofObject: coInterpreter topRemappableOop
				withValue: (cogMethod cmType = CMMethod
								ifTrue: [cogMethod methodObject]
								ifFalse: [cogMethod selector]).
			 (value := coInterpreter cePositive32BitIntegerFor: cogMethod asUnsignedInteger) isNil ifTrue:
				[coInterpreter popRemappableOop.
				 ^nil].
			 coInterpreter
				storePointerUnchecked: count + 1
				ofObject: coInterpreter topRemappableOop
				withValue: value.
			 count := count + 2].
		cogMethod := methodZone methodAfter: cogMethod].
	((label := coInterpreter stringForCString: 'CCFree') isNil
	 or: [(value := coInterpreter cePositive32BitIntegerFor: methodZone zoneLimit) isNil]) ifTrue:
		[coInterpreter popRemappableOop.
		 ^nil].
	coInterpreter
		storePointerUnchecked: count ofObject: coInterpreter topRemappableOop withValue: label;
		storePointerUnchecked: count + 1 ofObject: coInterpreter topRemappableOop withValue: value.
	((label := coInterpreter stringForCString: 'CCEnd') isNil
	 or: [(value := coInterpreter cePositive32BitIntegerFor: methodZone zoneEnd) isNil]) ifTrue:
		[coInterpreter popRemappableOop.
		 ^nil].
	coInterpreter
		storePointerUnchecked: count + 2 ofObject: coInterpreter topRemappableOop withValue: label;
		storePointerUnchecked: count + 3 ofObject: coInterpreter topRemappableOop withValue: value.
	constituents := coInterpreter popRemappableOop.
	coInterpreter beRootIfOld: constituents.
	^constituents
]

{ #category : #'in-line cacheing' }
Cogit >> cogExtendPIC: cPIC CaseNMethod: caseNMethod tag: caseNTag isMNUCase: isMNUCase [
	"Extend the cPIC with the supplied case.  If caseNMethod is cogged dispatch direct to
	 its unchecked entry-point.  If caseNMethod is not cogged, jump to the fast interpreter
	 dispatch, and if isMNUCase then dispatch to fast MNU invocation and mark the cPIC as
	 having the MNU case for cache flushing."
 	<var: #cPIC type: #'CogMethod *'>
	| operand target address size end |
	"stack allocate the various collections so that they
	 are effectively garbage collected on return."
	coInterpreter
		compilationBreak: cPIC selector
		point: (objectMemory lengthOf: cPIC selector).
	self allocateOpcodes: 5 bytecodes: 0.
	self assert: (objectRepresentation inlineCacheTagIsYoung: caseNTag) not.
	"Caller patches to open pic if caseNMethod is young."
	self assert: (caseNMethod notNil and: [(objectMemory isYoung: caseNMethod) not]).
	(isMNUCase not
	 and: [coInterpreter methodHasCogMethod: caseNMethod])
		ifTrue:
			[operand := 0.
			 target :=  (coInterpreter cogMethodOf: caseNMethod) asInteger + cmNoCheckEntryOffset]
		ifFalse:
			[isMNUCase ifTrue:
				[cPIC cpicHasMNUCase: true].
			 operand := caseNMethod.
			 target := cPIC asInteger
					+ (isMNUCase
						ifTrue: [self sizeof: CogMethod]
						ifFalse: [self interpretOffset - backEnd callInstructionByteSize])].
	self CmpCw: caseNTag R: TempReg.
	self MoveCw: operand R: SendNumArgsReg.
	self JumpLongZero: target.
	self MoveCw: cPIC asInteger R: ClassReg.
	self JumpLong: (self cPICMissTrampolineFor: cPIC cmNumArgs).

	self computeMaximumSizes.
	address := self addressOfEndOfCase: cPIC cPICNumCases - 1 inCPIC: cPIC.
	size := self generateInstructionsAt: address.
	end := self outputInstructionsAt: address.
	processor flushICacheFrom: address to: cPIC asInteger + closedPICSize.
	cPIC cPICNumCases: cPIC cPICNumCases + 1.
	^0
]

{ #category : #'in-line cacheing' }
Cogit >> cogMNUPICSelector: selector methodOperand: methodOperand numArgs: numArgs [
	<api>
	"Attempt to create a one-case PIC for an MNU.
	 The tag for the case is at the send site and so doesn't need to be generated."
	<returnTypeC: #'CogMethod *'>
	| startAddress headerSize size end |
	(objectMemory isYoung: selector) ifTrue:
		[^0].
	coInterpreter
		compilationBreak: selector
		point: (objectMemory lengthOf: selector).
	self assert: endCPICCase0 notNil.
	startAddress := methodZone allocate: closedPICSize.
	startAddress = 0 ifTrue:
		[coInterpreter callForCogCompiledCodeCompaction.
		 ^0].
	methodLabel
		address: startAddress;
		dependent: nil.
	"stack allocate the various collections so that they
	 are effectively garbage collected on return."
	self allocateOpcodes: numPICCases * 7 bytecodes: 0.
	self compileMNUCPIC: (self cCoerceSimple: startAddress to: #'CogMethod *')
		methodOperand: methodOperand
		numArgs: numArgs.
	self computeMaximumSizes.
	headerSize := self sizeof: CogMethod.
	size := self generateInstructionsAt: startAddress + headerSize.
	end := self outputInstructionsAt: startAddress + headerSize.
	"The missOffset is the same as the interpretOffset."
	self assert: missOffset = (interpretCall address + interpretCall machineCodeSize - startAddress).
	self assert: startAddress + cmEntryOffset = entry address.
	^self
		fillInCPICHeader: (self cCoerceSimple: startAddress to: #'CogMethod *')
		size: closedPICSize
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
	((cogMethod blockSize bitAnd: BytesPerWord - 1) ~= 0
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
		 ^0].

	cogMethod cmType = CMOpenPIC ifTrue:
		[cogMethod blockSize ~= openPICSize ifTrue:
			[^21].
		 cogMethod methodHeader ~= 0 ifTrue:
			[^22].
		
		 "Check the nextOpenPIC link unless we're compacting"
		 cogMethod objectHeader signedIntFromLong >= 0 ifTrue:
			[(cogMethod methodObject ~= 0
			 and: [cogMethod methodObject < methodZoneBase
				   or: [cogMethod methodObject > (methodZone zoneLimit - openPICSize)
				   or: [(cogMethod methodObject bitAnd: BytesPerWord - 1) ~= 0
				   or: [(self cCoerceSimple: cogMethod methodObject
							to: #'CogMethod *') cmType ~= CMOpenPIC]]]]) ifTrue:
				[^23]].
		 cogMethod stackCheckOffset ~= 0 ifTrue:
			[^24].
		 ^0].

	cogMethod cmType = CMClosedPIC ifTrue:
		[cogMethod blockSize ~= closedPICSize ifTrue:
			[^31].
		 (cogMethod cPICNumCases between: 1 and: numPICCases) ifFalse:
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
	self assert: (address bitAnd: BytesPerWord - 1) = 0.
	^cogMethodSurrogateClass new
		at: address
		memory: objectMemory memory
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
	| startAddress headerSize codeSize mapSize end |
	coInterpreter
		compilationBreak: selector
		point: (objectMemory lengthOf: selector).
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
	headerSize := self sizeof: CogMethod.
	codeSize := self generateInstructionsAt: startAddress + headerSize.
	mapSize := self generateMapAt: startAddress + openPICSize - 1 start: startAddress + cmNoCheckEntryOffset.
	self assert: entry address - startAddress = cmEntryOffset.
	self assert: headerSize + codeSize + mapSize <= openPICSize.
	end := self outputInstructionsAt: startAddress + headerSize.
	^self
		fillInOPICHeader: (self cCoerceSimple: startAddress to: #'CogMethod *')
		size: openPICSize
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
	| startAddress headerSize size end |
	(objectMemory isYoung: selector) ifTrue:
		[^self cCoerceSimple: YoungSelectorInPIC to: #'CogMethod *'].
	coInterpreter
		compilationBreak: selector
		point: (objectMemory lengthOf: selector).
	startAddress := methodZone allocate: closedPICSize.
	startAddress = 0 ifTrue:
		[^self cCoerceSimple: InsufficientCodeSpace to: #'CogMethod *'].
	methodLabel
		address: startAddress;
		dependent: nil.
	"stack allocate the various collections so that they
	 are effectively garbage collected on return."
	self allocateOpcodes: numPICCases * 7 bytecodes: 0.
	self compileCPIC: (self cCoerceSimple: startAddress to: #'CogMethod *')
		Case0: case0CogMethod
		Case1Method: case1MethodOrNil
		tag: case1Tag
		isMNUCase: isMNUCase
		numArgs: numArgs.
	self computeMaximumSizes.
	headerSize := self sizeof: CogMethod.
	size := self generateInstructionsAt: startAddress + headerSize.
	end := self outputInstructionsAt: startAddress + headerSize.
	"The missOffset is th same as the interpretOffset."
	self assert: missOffset = (interpretCall address + interpretCall machineCodeSize - startAddress).
	self assert: startAddress + cmEntryOffset = entry address.
	self assert: endCPICCase0 address = (startAddress + firstCPICCaseOffset).
	self assert: endCPICCase1 address = (startAddress + firstCPICCaseOffset + cPICCaseSize).
	^self
		fillInCPICHeader: (self cCoerceSimple: startAddress to: #'CogMethod *')
		size: closedPICSize
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
	"Post-GC update every full method's objectHeader to whatever it needs to be"
	self assert: self allMethodsHaveCorrectHeader.
	self assert: methodZone kosherYoungReferrers
]

{ #category : #disassembly }
Cogit >> collectMapEntry: annotation address: mcpc into: aDictionary [
	<doNotGenerate>
	aDictionary at: mcpc put: (self class annotationConstantNames at: annotation + 1).
	^0
]

{ #category : #'jit - api' }
Cogit >> compactCogCompiledCode [
	<api>
	self assert: self noCogMethodsMaximallyMarked.
	coInterpreter markActiveMethodsAndReferents.
	methodZone freeOlderMethodsForCompaction.
	self freePICsWithFreedTargets.
	methodZone planCompaction.
	coInterpreter updateStackZoneReferencesToCompiledCodePreCompaction.
	self relocateMethodsPreCompaction.
	methodZone compactCompiledCode: objectMemory nullHeaderForMachineCodeMethod.
	self assert: self allMethodsHaveCorrectHeader.
	self assert: methodZone kosherYoungReferrers.
	processor flushICacheFrom: methodZoneBase to: methodZone zoneLimit
]

{ #category : #'simulation only' }
Cogit >> compilationTrace [
	^compilationTrace
]

{ #category : #'simulation only' }
Cogit >> compilationTrace: anInteger [
	compilationTrace := anInteger
]

{ #category : #'compile abstract instructions' }
Cogit >> compileAbstractInstructionsFrom: start through: end [
	"Loop over bytecodes, dispatching to the generator for each bytecode, handling fixups in due course."
	| nextOpcodeIndex descriptor fixup result |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #fixup type: #'BytecodeFixup *'>
	bytecodePointer := start.
	[byte0 := objectMemory fetchByte: bytecodePointer ofObject: methodObj.
	 descriptor := self generatorAt: byte0.
	 descriptor numBytes > 1 ifTrue:
		[byte1 := objectMemory fetchByte: bytecodePointer + 1 ofObject: methodObj.
		 descriptor numBytes > 2 ifTrue:
			[byte2 := objectMemory fetchByte: bytecodePointer + 2 ofObject: methodObj.
			 descriptor numBytes > 3 ifTrue:
				[byte3 := objectMemory fetchByte: bytecodePointer + 3 ofObject: methodObj.
				 descriptor numBytes > 4 ifTrue:
					[self notYetImplemented]]]].
	 nextOpcodeIndex := opcodeIndex.
	 result := self perform: descriptor generator.
	 fixup := self fixupAt: bytecodePointer - initialPC.
	 fixup targetInstruction ~= 0 ifTrue:
		["There is a fixup for this bytecode.  It must point to the first generated
		   instruction for this bytecode.  If there isn't one we need to add a label."
		 opcodeIndex = nextOpcodeIndex ifTrue:
			[self Label].
		 fixup targetInstruction: (self abstractInstructionAt: nextOpcodeIndex)].
	 bytecodePointer := self nextBytecodePCFor: descriptor at: bytecodePointer byte0: byte0 in: methodObj.
	 result = 0 and: [bytecodePointer <= end]] whileTrue.
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
	self AlignmentNops: (self sizeof: CogBlockMethod).
	self assert: (self sizeof: CogBlockMethod) = (2 * BytesPerWord).
	blockStart fakeHeader: self Label.
	self Fill32: 0. "gets filled in later with the homeOffset and startpc"
	self Fill32: 0. "gets filled in later with numArgs et al"
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
Cogit >> compileBlockFrameBuild: blockStart [
	self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
Cogit >> compileBlockFramelessEntry: blockStart [
	self subclassResponsibility
]

{ #category : #'in-line cacheing' }
Cogit >> compileCPIC: cPIC Case0: case0CogMethod Case1Method: case1Method tag: case1Tag isMNUCase: isMNUCase numArgs: numArgs [
	"Compile the code for a two-case PIC for case0CogMethod and  case1Method,case1Tag.
	 The tag for case0CogMethod is at the send site and so doesn't need to be generated.
	 case1Method may be any of
		- a Cog method; jump to its unchecked entry-point
		- a CompiledMethod; jump to the ceInterpretFromPIC trampoline
		- nil; call ceMNUFromPIC"
	<var: #cPIC type: #'CogMethod *'>
	| operand targetEntry jumpNext |
	<var: #case0CogMethod type: #'CogMethod *'>
	<var: #targetEntry type: #'void *'>
	<var: #jumpNext type: #'AbstractInstruction *'>
	self assert: case1Method notNil.
	self compilePICProlog: numArgs.
	self assert: (objectRepresentation inlineCacheTagIsYoung: case1Tag) not.
	(isMNUCase not
	 and: [coInterpreter methodHasCogMethod: case1Method])
		ifTrue:
			[operand := 0.
			 targetEntry := self cCoerceSimple: (coInterpreter cogMethodOf: case1Method) asInteger + cmNoCheckEntryOffset
								to: #'void *']
		ifFalse:
			[self assert: (case1Method isNil or: [(objectMemory isYoung: case1Method) not]).
			 operand := case1Method.
			 targetEntry := case1Method isNil ifTrue: [mnuCall] ifFalse: [interpretCall]].

	jumpNext := self compileCPICEntry.
	self MoveCw: 0 R: SendNumArgsReg.
	self JumpLong: case0CogMethod asInteger + cmNoCheckEntryOffset.
	endCPICCase0 := self CmpCw: case1Tag R: TempReg.
	jumpNext jmpTarget: endCPICCase0.
	self MoveCw: operand R: SendNumArgsReg.
	self JumpLongZero: (isMNUCase ifTrue: [mnuCall] ifFalse: [targetEntry]) asInteger.
	endCPICCase1 := self MoveCw: cPIC asInteger R: ClassReg.
	self JumpLong: (self cPICMissTrampolineFor: numArgs).
	^0

]

{ #category : #'in-line cacheing' }
Cogit >> compileCPICEntry [
	<returnTypeC: #'AbstractInstruction *'>
	"Compile the cache tag computation and the first comparison.  Answer the address of that comparison."
	self AlignmentNops: (BytesPerWord max: 8).
	entry := self Label.
	objectRepresentation getInlineCacheClassTagFrom: ReceiverResultReg into: TempReg.
	self CmpR: ClassReg R: TempReg.
	^self JumpNonZero: 0
]

{ #category : #'in-line cacheing' }
Cogit >> compileClosedPICPrototype [
	"Compile the abstract instructions for a full closed PIC used to initialize closedPICSize"
	| numArgs jumpNext |
	<var: #jumpNext type: #'AbstractInstruction *'>
	numArgs := 0.
	self compilePICProlog: numArgs.
	jumpNext := self compileCPICEntry.
	self MoveCw: 16r5EAF00D R: SendNumArgsReg.
	self JumpLong: 16r5EEDCA5E.
	jumpNext jmpTarget: (endCPICCase0 := self Label).
	1 to: numPICCases - 1 do:
		[:h|
		self CmpCw: 16rBABE1F15+h R: TempReg.
		self MoveCw: 16rBADA550 + h R: SendNumArgsReg.
		self JumpLongZero: 16rBEDCA5E0.
		h = 1 ifTrue:
			[endCPICCase1 := self Label]].
	self MoveCw: 16rAB5CE55 R: ClassReg.
	self JumpLong: (self cPICMissTrampolineFor: numArgs).
	^0
]

{ #category : #'compile abstract instructions' }
Cogit >> compileCogMethod: selector [
	<returnTypeC: #'CogMethod *'>
	| numBytecodes numBlocks result extra |
	hasYoungReferent := (objectMemory isYoung: methodObj)
						  or: [objectMemory isYoung: selector].
	methodOrBlockNumArgs := coInterpreter argumentCountOf: methodObj.
	inBlock := false.
	primInvokeLabel := nil.
	postCompileHook := nil.
	extra := ((primitiveIndex := coInterpreter primitiveIndexOf: methodObj) > 0
			and: [(coInterpreter isQuickPrimitiveIndex: primitiveIndex) not])
				ifTrue: [30]
				ifFalse: [10].
	initialPC := coInterpreter startPCOfMethod: methodObj.
	"initial estimate.  Actual endPC is determined in scanMethod."
	endPC := (coInterpreter isQuickPrimitiveIndex: primitiveIndex)
					ifTrue: [initialPC - 1]
					ifFalse: [objectMemory byteSizeOf: methodObj].
	numBytecodes := endPC - initialPC + 1.
	self allocateOpcodes: (numBytecodes + extra) * 10 bytecodes: numBytecodes.
	(numBlocks := self scanMethod) < 0 ifTrue:
		[^coInterpreter cCoerceSimple: numBlocks to: #'CogMethod *'].
	self allocateBlockStarts: numBlocks.
	blockEntryLabel := nil.
	methodLabel dependent: nil.
	(result := self compileEntireMethod) < 0 ifTrue:
		[^coInterpreter cCoerceSimple: result to: #'CogMethod *'].
	^self generateCogMethod: selector
]

{ #category : #'compile abstract instructions' }
Cogit >> compileEntireMethod [
	"Compile the abstract instructions for the entire method, including blocks."
	| result |
	self compileProlog.
	self compileEntry.
	(result := self compilePrimitive) < 0 ifTrue:
		[^result].
	self compileFrameBuild.
	blockCount := 0.
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
	 can distinguish normal and super sends (super sends bind to the noCheckEntry).
	 In Newspeak we also need to distinguish dynSuperSends from normal and super
	 and so bind a the preceeding nop (on x86 there happens to be one anyway)."
	self cppIf: NewspeakVM
		ifTrue: [dynSuperEntry := self Nop].
	self AlignmentNops: (BytesPerWord max: 8).
	entry := self Label.
	objectRepresentation getInlineCacheClassTagFrom: ReceiverResultReg into: TempReg.
	self CmpR: ClassReg R: TempReg.
	self JumpNonZero: sendMissCall.
	noCheckEntry := self Label.
	self recordSendTrace ifTrue:
		[self CallRT: ceTraceLinkedSendTrampoline]
]

{ #category : #'compile abstract instructions' }
Cogit >> compileFrameBuild [
	self subclassResponsibility
]

{ #category : #'in-line cacheing' }
Cogit >> compileMNUCPIC: cPIC methodOperand: methodOperand numArgs: numArgs [
	"Compile the code for a one-case MNU PIC that calls ceMNUFromPIC for case0Tag
	 The tag for case0 is at the send site and so doesn't need to be generated."
	<var: #cPIC type: #'CogMethod *'>
	| jumpNext |
	<var: #jumpNext type: #'AbstractInstruction *'>
	self compilePICProlog: numArgs.
	jumpNext := self compileCPICEntry.
	self MoveCw: methodOperand R: SendNumArgsReg.
	self JumpLong: mnuCall asInteger.
	jumpNext jmpTarget: (self MoveCw: cPIC asInteger R: ClassReg).
	self JumpLong: (self cPICMissTrampolineFor: numArgs).
	^0

]

{ #category : #'compile abstract instructions' }
Cogit >> compileMethodBody [
	"Compile the top-level method body."
	<inline: true>
	endPC < initialPC ifTrue: [^0]. "quick primitives"
	^self compileAbstractInstructionsFrom: initialPC through: endPC
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
Cogit >> compilePICProlog: numArgs [
	"The start of a PIC has a call to a run-time abort routine that either handles
	 a dispatch to an interpreted method or a dispatch of an MNU case.  The
	 routine selects the path depending on ClassReg; if zero it takes the MNU
	 path; if nonzero the dispatch to interpreter path.  Neither of these paths
	 returns. The abort routine must be called;  In the callee the PIC is located
	 by adding the relevant offset to the return address of the call."
	mnuCall := self MoveCq: 0 R: ClassReg.
	interpretCall := self Call: (self picAbortTrampolineFor: numArgs).
	^0
]

{ #category : #'compile abstract instructions' }
Cogit >> compilePrimitive [
	"Compile a primitive.  If possible, performance-critical primtiives will
	 be generated by their own routines (primitiveGenerator).  Otherwise,
	 if there is a primitive at all, we call the C routine with the usual
	 stack-switching dance, test the primFailCode and then either return
	 on success or continue to the method body."
	<inline: false>
	| primitiveDescriptor primitiveRoutine |
	<var: #primitiveDescriptor type: #'PrimitiveDescriptor *'>
	<var: #primitiveRoutine declareC: 'void (*primitiveRoutine)(void)'>
	primitiveIndex = 0 ifTrue: [^0].
	((primitiveDescriptor := self primitiveGeneratorOrNil) notNil
	 and: [primitiveDescriptor primitiveGenerator notNil]) ifTrue:
		["If a descriptor specifies an argument count (by numArgs >= 0)
		  then it must match for the generated code to be correct.  For
		  example for speed many primitives use ResultReceiverReg
		  instead of accessing the stack, so the receiver better be at
		  numArgs down the stack.  Use the interpreter version if not."
		 (primitiveDescriptor primNumArgs < 0 "means don't care"
		  or: [primitiveDescriptor primNumArgs = (coInterpreter argumentCountOf: methodObj)]) ifTrue:
			[^self perform: primitiveDescriptor primitiveGenerator]].
	((primitiveRoutine := coInterpreter
							functionPointerForCompiledMethod: methodObj
							primitiveIndex: primitiveIndex) isNil "no primitive"
	or: [primitiveRoutine = (coInterpreter functionPointerFor: 0 inClass: nil) "routine = primitiveFail"]) ifTrue:
		[^self genFastPrimFail].
	minValidCallAddress := minValidCallAddress min: primitiveRoutine asUnsignedInteger.
	^self compileInterpreterPrimitive: primitiveRoutine
]

{ #category : #'compile abstract instructions' }
Cogit >> compileProlog [
	"The start of a CogMethod has a call to a run-time abort routine that either
	 handles an in-line cache failure or a stack overflow.  The routine selects the
	 path depending on ReceiverResultReg; if zero it takes the stack overflow
	 path; if nonzero the in-line cache miss path.  Neither of these paths returns.
	 The abort routine must be called;  In the callee the method is located by
	 adding the relevant offset to the return address of the call."
	stackOverflowCall := self MoveCq: 0 R: ReceiverResultReg.
	sendMissCall := self Call: (self methodAbortTrampolineFor: methodOrBlockNumArgs)
]

{ #category : #initialization }
Cogit >> compileTrampolineFor: aRoutine callJumpBar: callJumpBar "<Boolean>" numArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 saveRegs: saveRegs resultReg: resultRegOrNil [
	"Generate a trampoline with up to four arguments.  Generate either a call or a jump to aRoutine
	 as requested by callJumpBar.  If generating a call and resultRegOrNil is non-zero pass the C result
	 back in resultRegOrNil.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<inline: false>
	self genSaveStackPointers.
	self genLoadCStackPointers.
	cStackAlignment > BytesPerWord ifTrue:
		[backEnd
			genAlignCStackSavingRegisters: saveRegs
			numArgs: numArgs
			wordAlignment: cStackAlignment / BytesPerWord].
	saveRegs ifTrue:
		[callJumpBar ifFalse:
			[self error: 'why save registers when you''re not going to return?'].
		 backEnd genSaveRegisters].
	numArgs > 0 ifTrue:
		[numArgs > 1 ifTrue:
			[numArgs > 2 ifTrue:
				[numArgs > 3 ifTrue:
					[regOrConst3 < 0
						ifTrue: [backEnd genPassReg: regOrConst3 asArgument: 3]
						ifFalse: [backEnd genPassConst: regOrConst3 asArgument: 3]].
				 regOrConst2 < 0
					ifTrue: [backEnd genPassReg: regOrConst2 asArgument: 2]
					ifFalse: [backEnd genPassConst: regOrConst2 asArgument: 2]].
			regOrConst1 < 0
				ifTrue: [backEnd genPassReg: regOrConst1 asArgument: 1]
				ifFalse: [backEnd genPassConst: regOrConst1 asArgument: 1]].
		regOrConst0 < 0
			ifTrue: [backEnd genPassReg: regOrConst0 asArgument: 0]
			ifFalse: [backEnd genPassConst: regOrConst0 asArgument: 0]].
	self gen: (callJumpBar ifTrue: [Call] ifFalse: [Jump])
		operand: (self cCode: [aRoutine asUnsignedInteger]
					   inSmalltalk: [self simulatedTrampolineFor: aRoutine]).
	callJumpBar ifTrue:
		[resultRegOrNil ifNotNil:
			[backEnd genWriteCResultIntoReg: resultRegOrNil].
		 saveRegs ifTrue:
			[numArgs > 0 ifTrue:
				[backEnd genRemoveNArgsFromStack: numArgs].
			resultRegOrNil
				ifNotNil: [backEnd genRestoreRegsExcept: resultRegOrNil]
				ifNil: [backEnd genRestoreRegs]].
		self genLoadStackPointers.
		self RetN: 0]
]

{ #category : #initialization }
Cogit >> computeEntryOffsets [
	"Generate the entry code for a method to determine cmEntryOffset and cmNoCheckEntryOffset.  We
	 need cmNoCheckEntryOffset up front to be able to generate the map starting from cmNoCheckEntryOffset"
	"stack allocate the various collections so that they
	 are effectively garbage collected on return."
	self allocateOpcodes: 20 bytecodes: 0.
	methodOrBlockNumArgs := 0.
	self compileProlog.
	self compileEntry.
	self computeMaximumSizes.
	self generateInstructionsAt: methodZoneBase + (self sizeof: CogMethod).
	cmEntryOffset := entry address - methodZoneBase.
	cmNoCheckEntryOffset := noCheckEntry address - methodZoneBase.
	self cppIf: NewspeakVM
		ifTrue: [cmDynSuperEntryOffset := dynSuperEntry address - methodZoneBase].
	missOffset := sendMissCall address + sendMissCall machineCodeSize - methodZoneBase.
	entryPointMask := BytesPerWord - 1.
	[self cppIf: NewspeakVM
		ifTrue: [(cmEntryOffset bitAnd: entryPointMask) = (cmNoCheckEntryOffset bitAnd: entryPointMask)
				or: [(cmEntryOffset bitAnd: entryPointMask) = (cmDynSuperEntryOffset bitAnd: entryPointMask)
				or: [(cmNoCheckEntryOffset bitAnd: entryPointMask) = (cmDynSuperEntryOffset bitAnd: entryPointMask)]]]
		ifFalse: [(cmEntryOffset bitAnd: entryPointMask) = (cmNoCheckEntryOffset bitAnd: entryPointMask)]] whileTrue:
		[entryPointMask := entryPointMask + entryPointMask + 1].
	entryPointMask >= (methodZone roundUpLength: 1) ifTrue:
		[self error: 'cannot differentiate checked and unchecked entry-points with current cog method alignment'].
	checkedEntryAlignment := cmEntryOffset bitAnd: entryPointMask.
	self assert: checkedEntryAlignment ~= (cmNoCheckEntryOffset bitAnd: entryPointMask).
	self cppIf: NewspeakVM
		ifTrue:
			[cmDynSuperEntryOffset := dynSuperEntry address - methodZoneBase.
			 dynSuperEntryAlignment := cmDynSuperEntryOffset bitAnd: entryPointMask.
			self assert: (cmDynSuperEntryOffset bitAnd: entryPointMask) ~= (cmEntryOffset bitAnd: entryPointMask).
			self assert: (cmDynSuperEntryOffset bitAnd: entryPointMask) ~= (cmNoCheckEntryOffset bitAnd: entryPointMask)]
]

{ #category : #'generate machine code' }
Cogit >> computeMaximumSizes [
	"This pass assigns maximum sizes to all abstract instructions and eliminates jump fixups.
	 It hence assigns the maximum address an instruction will occur at which allows the next
	 pass to conservatively size jumps."
	<inline: false>
	<var: #abstractInstruction type: #'AbstractInstruction *'>
	| relativeAddress |
	relativeAddress := 0.
	0 to: opcodeIndex - 1 do:
		[:i| | abstractInstruction |
		abstractInstruction := self abstractInstructionAt: i.
		abstractInstruction address: relativeAddress.
		abstractInstruction computeMaximumSize.
		relativeAddress := relativeAddress + abstractInstruction maxSize].

]

{ #category : #printing }
Cogit >> cr [
	<cmacro: '() putchar(''\n'')'>
	coInterpreter transcript cr; flush
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
	(pc between: (trampolineAddresses at: 1) and: methodZoneBase) ifTrue:
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
	processor disassembleFrom: startAddress to: endAddress in: coInterpreter memory for: self labels: labelDictionary on: aStream.
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
	self printMethodHeader: cogMethod on: aStream.

	(mapEntries := Dictionary new)
		at: cogMethod asInteger + cmEntryOffset put: 'entry'.
	
	cogMethod cmType = CMMethod ifTrue:
		[mapEntries at: cogMethod asInteger + cmNoCheckEntryOffset put: 'noCheckEntry'.
		self cppIf: NewspeakVM
			ifTrue: [mapEntries at: cogMethod asInteger + dynSuperEntryAlignment put: 'dynSuperEntry']].

	cogMethod cmType = CMClosedPIC ifTrue:
		[mapEntries at: cogMethod asInteger + firstCPICCaseOffset put: 'ClosedPICCase0'.
		 1 to: numPICCases - 1 do:
			[:i|
			mapEntries
				at: cogMethod asInteger + firstCPICCaseOffset + (i * cPICCaseSize)
				put: 'ClosedPICCase', i printString]].

	self mapFor: cogMethod
		performUntil: #collectMapEntry:address:into: asSymbol
		arg: mapEntries.

	"This would all be far more elegant and simple if we used blocks.
	 But there are no blocks in C and the basic enumerators here need
	 to be used in the real VM.  Apologies."
	(codeRanges := self codeRangesFor: cogMethod) do:
		[:range|
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

{ #category : #accessing }
Cogit >> dynSuperEntryOffset [
	<api>
	<cmacro: '() cmDynSuperEntryOffset'>
	^cmDynSuperEntryOffset
]

{ #category : #'simulation only' }
Cogit >> endPCOf: aMethod [
	| pc end latestContinuation descriptor prim distance targetPC byte |
	pc := latestContinuation := coInterpreter startPCOfMethod: aMethod.
	(prim := coInterpreter primitiveIndexOf: aMethod) > 0 ifTrue:
		[(coInterpreter isQuickPrimitiveIndex: prim) ifTrue:
			[^pc - 1]].
	end := objectMemory byteSizeOf: aMethod.
	[pc <= end] whileTrue:
		[byte := objectMemory fetchByte: pc ofObject: aMethod.
		descriptor := self generatorAt: byte.
		(descriptor isReturn
		 and: [pc >= latestContinuation]) ifTrue:
			[end := pc].
		descriptor isBranch ifTrue:
			[distance := self spanFor: descriptor at: pc byte0: byte in: aMethod.
			 targetPC := pc + descriptor numBytes + distance.
			 descriptor isBackwardBranch ifFalse:
				[latestContinuation := latestContinuation max: targetPC]].
		descriptor isBlockCreation ifTrue:
			[distance := self spanFor: descriptor at: pc byte0: byte in: aMethod.
			 targetPC := pc + descriptor numBytes + distance.
			 latestContinuation := latestContinuation max: targetPC.
			 pc := pc + distance].
		pc := pc + descriptor numBytes].
	^end
]

{ #category : #'compile abstract instructions' }
Cogit >> ensureFixupAt: targetIndex [
	"Make sure there's a flagged fixup at the targetIndex (pc relative to first pc) in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	<returnTypeC: #'BytecodeFixup *'>
	| fixup |
	<var: #fixup type: #'BytecodeFixup *'>
	fixup := self fixupAt: targetIndex.
	fixup targetInstruction = 0 ifTrue:
		[fixup targetInstruction: (self cCoerceSimple: 1 to: #'AbstractInstruction *')].
	^fixup
]

{ #category : #debugging }
Cogit >> enterCogCodePopReceiver [
	"This is a static version of ceEnterCogCodePopReceiverReg
	 for break-pointing when debugging in C."
	<api>
	<inline: false>
	"(and this exists only to reference Debug)"
	Debug ifFalse: [self error: 'what??'].
	"This exists only for break-pointing."
	self cCode: 'realCEEnterCogCodePopReceiverReg()'
		inSmalltalk: [self ceEnterCogCodePopReceiverReg]
]

{ #category : #debugging }
Cogit >> enterCogCodePopReceiverAndClassRegs [
	"This is a static version of ceEnterCogCodePopReceiverAndClassRegs
	 for break-pointing when debugging in C."
	<api>
	<inline: false>
	"(and this exists only to reference Debug)"
	Debug ifFalse: [self error: 'what??'].
	"This exists only for break-pointing."
	self cCode: 'realCEEnterCogCodePopReceiverAndClassRegs()'
		inSmalltalk: [self ceEnterCogCodePopReceiverAndClassRegs]
]

{ #category : #accessing }
Cogit >> entryOffset [
	<api>
	<cmacro: '() cmEntryOffset'>
	^cmEntryOffset
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
			stackCheckOffset: (blockStart stackCheckLabel = nil
								ifTrue: [0]
								ifFalse: [blockStart stackCheckLabel address - blockStart fakeHeader address])]
]

{ #category : #'generate machine code' }
Cogit >> fillInCPICHeader: pic size: size numArgs: numArgs numCases: numCases hasMNUCase: hasMNUCase selector: selector [
	<returnTypeC: #'CogMethod *'>
	<var: #pic type: #'CogMethod *'>
	self assert: (objectMemory isYoung: selector) not.
	pic cmType: CMClosedPIC.
	pic objectHeader: 0.
	pic blockSize: size.
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
	self assert: size = (methodZone roundUpLength: size).
	^pic
]

{ #category : #'generate machine code' }
Cogit >> fillInMethodHeader: method size: size selector: selector [
	<returnTypeC: #'CogMethod *'>
	<var: #method type: #'CogMethod *'>
	<var: #originalMethod type: #'CogMethod *'>
	| methodHeader originalMethod |
	method cmType: CMMethod.
	method objectHeader: objectMemory nullHeaderForMachineCodeMethod.
	method blockSize: size.
	method methodObject: methodObj.
	methodHeader := coInterpreter rawHeaderOf: methodObj.
	"If the method has already been cogged (e.g. Newspeak accessors) then
	 leave the original method attached to its cog method, but get the right header."
	(coInterpreter isCogMethodReference: methodHeader)
		ifTrue:
			[originalMethod := self cCoerceSimple: methodHeader to: #'CogMethod *'.
			self assert: originalMethod blockSize = size.
			methodHeader := originalMethod methodHeader]
		ifFalse:
			[coInterpreter rawHeaderOf: methodObj put: method asInteger].
	method methodHeader: methodHeader.
	method selector: selector.
	method cmNumArgs: (coInterpreter argumentCountOfMethodHeader: methodHeader).
	(method cmRefersToYoung: hasYoungReferent) ifTrue:
		[methodZone addToYoungReferrers: method].
	method cmUsageCount: self initialMethodUsageCount.
	method cpicHasMNUCase: false.
	method blockEntryOffset: (blockEntryLabel notNil
								ifTrue: [blockEntryLabel address - method asInteger]
								ifFalse: [0]).
	method stackCheckOffset: (needsFrame
								ifTrue: [stackCheckLabel address - method asInteger]
								ifFalse: [0]).
	self assert: (backEnd callTargetFromReturnAddress: method asInteger + missOffset) = (self methodAbortTrampolineFor: method cmNumArgs).
	self assert: size = (methodZone roundUpLength: size).
	^method
]

{ #category : #'generate machine code' }
Cogit >> fillInOPICHeader: pic size: size numArgs: numArgs selector: selector [
	<returnTypeC: #'CogMethod *'>
	<var: #pic type: #'CogMethod *'>
	pic cmType: CMOpenPIC.
	pic objectHeader: 0.
	pic blockSize: size.
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
	self assert: size = (methodZone roundUpLength: size).
	^pic
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
Cogit >> findEnclosingMethodFor: mcpc inHomeMethod: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<returnTypeC: #'CogBlockMethod *'>
	<api>
	"Find the CMMethod or CMBlock that encloses mcpc.
	 If the method contains blocks then, because block dispatch is not in order,
	 enumerate the block dispatch and find the nearest preceeding entry."
	self assert: cogMethod cmType = CMMethod.
	cogMethod blockEntryOffset = 0 ifTrue:
		[^self cCoerceSimple: cogMethod to: #'CogBlockMethod *'].
	maxMethodBefore := self cCoerceSimple: cogMethod to: #'CogBlockMethod *'.
	self blockDispatchTargetsFor: cogMethod perform: #findMinAndMaxMethodsPC:around: asSymbol arg: mcpc.
	^maxMethodBefore
]

{ #category : #'method map' }
Cogit >> findMapLocationForMcpc: targetMcpc inMethod: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	| mcpc map mapByte annotation |
	mcpc := cogMethod asInteger + cmNoCheckEntryOffset.
	map := self mapStartFor: cogMethod.
	mcpc = targetMcpc ifTrue: [^map].
	[(mapByte := coInterpreter byteAt: map) ~= MapEnd] whileTrue:
		[annotation := mapByte >> AnnotationShift.
		 mcpc := mcpc + (annotation = IsDisplacementX2N
							ifTrue: [mapByte - DisplacementX2N << AnnotationShift]
							ifFalse: [mapByte bitAnd: DisplacementMask]).
		 mcpc >= targetMcpc ifTrue:
			[self assert: mcpc = targetMcpc.
			 ^map].
		 map := map - 1].
	^0
]

{ #category : #'method map' }
Cogit >> findMcpc: mcpc Bcpc: bcpc MatchingBcpc: targetBcpc [
	<var: #mcpc type: #'char *'>
	<var: #targetBcpc type: #'void *'>
	^targetBcpc asInteger = bcpc ifTrue: [mcpc asInteger] ifFalse: [0]
]

{ #category : #'method map' }
Cogit >> findMcpc: mcpc Bcpc: bcpc MatchingMcpc: targetMcpc [
	<var: #mcpc type: #'char *'>
	<var: #targetMcpc type: #'void *'>
	^targetMcpc = mcpc ifTrue: [bcpc] ifFalse: [0]
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
								perform: #findBlockMethodWithEntry:startBcpc: asSymbol
								arg: startbcpc)
		to: #'CogBlockMethod *'
]

{ #category : #'method map' }
Cogit >> findMinAndMaxMethodsPC: blockEntryPC around: mcpc [
	<returnTypeC: #usqInt>
	(blockEntryPC asUnsignedInteger <= mcpc asUnsignedInteger
	and: [blockEntryPC asUnsignedInteger > maxMethodBefore asUnsignedInteger]) ifTrue:
		[maxMethodBefore := self cCoerceSimple: blockEntryPC - (self sizeof: CogBlockMethod)
								   to: #'CogBlockMethod *'].
	^0 "keep scanning..."
]

{ #category : #'compile abstract instructions' }
Cogit >> fixupAt: index [
	<cmacro: '(index) (&fixups[index])'>
	<returnTypeC: #'BytecodeFixup *'>
	^self addressOf: (fixups at: index)
]

{ #category : #compaction }
Cogit >> freePICsWithFreedTargets [
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[(cogMethod cmType = CMClosedPIC
		 and: [self cPICHasFreedTargets: cogMethod]) ifTrue:
			[cogMethod cmType: CMFree].
		 cogMethod := methodZone methodAfter: cogMethod]
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
	self cCode: '' inSmalltalk: [abstractInstruction bcpc: bytecodePointer].
	^abstractInstruction
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
	self cCode: '' inSmalltalk: [abstractInstruction bcpc: bytecodePointer].
	^abstractInstruction
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" operand: operandOne "<Integer|CogAbstractInstruction>"  operand: operandTwo [ "<Integer|CogAbstractInstruction>"
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
	self cCode: '' inSmalltalk: [abstractInstruction bcpc: bytecodePointer].
	^abstractInstruction
]

{ #category : #'compile abstract instructions' }
Cogit >> gen: opcode "<Integer>" operand: operandOne "<Integer|CogAbstractInstruction>"  operand: operandTwo "<Integer|CogAbstractInstruction>" operand: operandThree [ "<Integer|CogAbstractInstruction>"
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
	self cCode: '' inSmalltalk: [abstractInstruction bcpc: bytecodePointer].
	^abstractInstruction
]

{ #category : #initialization }
Cogit >> genActiveContextTrampoline [
	"Short-circuit the interpreter call if a frame is already married."
	| jumpSingle |
	<var: #jumpSingle type: #'AbstractInstruction *'>
	opcodeIndex := 0.
	self MoveMw: FoxMethod r: FPReg R: TempReg.
	self AndCq: MFMethodFlagHasContextFlag R: TempReg.
	jumpSingle := self JumpZero: 0.
	self MoveMw: FoxThisContext r: FPReg R: ReceiverResultReg.
	self RetN: 0.
	jumpSingle jmpTarget: self Label.
	^self genTrampolineFor: #ceActiveContext asSymbol
		called: 'ceActiveContextTrampoline'
		callJumpBar: true
		numArgs: 0
		arg: nil
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: ReceiverResultReg
		appendOpcodes: true
]

{ #category : #initialization }
Cogit >> genCheckForInterruptsTrampoline [
	opcodeIndex := 0.
	self PopR: TempReg. "instruction pointer"
	self MoveR: TempReg Aw: coInterpreter instructionPointerAddress.
	^self genTrampolineFor: #ceCheckForInterrupts asSymbol
		called: 'ceCheckForInterruptsTrampoline'
		callJumpBar: true
		numArgs: 0
		arg: nil
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil
		appendOpcodes: true
]

{ #category : #initialization }
Cogit >> genEnilopmartFor: regArg1 and: regArg2 and: regArg3 called: trampolineName [
	"An enilopmart (the reverse of a trampoline) is a piece of code that makes
	 the system-call-like transition from the C runtime into generated machine
	 code.  The desired arguments and entry-point are pushed on a stackPage's
	 stack.  The enilopmart pops off the values to be loaded into registers and
	 then executes a return instruction to pop off the entry-point and jump to it."
	<returnTypeC: 'void (*genEnilopmartForandandcalled(sqInt regArg1, sqInt regArg2, sqInt regArg3, char *trampolineName))(void)'>
	| size endAddress enilopmart |
	opcodeIndex := 0.
	self genLoadStackPointers.
	self PopR: regArg3.
	self PopR: regArg2.
	self PopR: regArg1.
	self RetN: 0.
	self computeMaximumSizes.
	size := self generateInstructionsAt: methodZoneBase.
	endAddress := self outputInstructionsAt: methodZoneBase.
	self assert: methodZoneBase + size = endAddress.
	enilopmart := methodZoneBase.
	methodZoneBase := self alignUptoRoutineBoundary: endAddress.
	backEnd nopsFrom: endAddress to: methodZoneBase - 1.
	self recordGeneratedRunTime: trampolineName address: enilopmart.
	^self cCoerceSimple: enilopmart to: #'void (*)(void)'
]

{ #category : #initialization }
Cogit >> genEnilopmartFor: regArg1 and: regArg2 called: trampolineName [
	"An enilopmart (the reverse of a trampoline) is a piece of code that makes
	 the system-call-like transition from the C runtime into generated machine
	 code.  The desired arguments and entry-point are pushed on a stackPage's
	 stack.  The enilopmart pops off the values to be loaded into registers and
	 then executes a return instruction to pop off the entry-point and jump to it."
	<returnTypeC: 'void (*genEnilopmartForandcalled(sqInt regArg1, sqInt regArg2, char *trampolineName))(void)'>
	| size endAddress enilopmart |
	opcodeIndex := 0.
	self genLoadStackPointers.
	self PopR: regArg2.
	self PopR: regArg1.
	self RetN: 0.
	self computeMaximumSizes.
	size := self generateInstructionsAt: methodZoneBase.
	endAddress := self outputInstructionsAt: methodZoneBase.
	self assert: methodZoneBase + size = endAddress.
	enilopmart := methodZoneBase.
	methodZoneBase := self alignUptoRoutineBoundary: endAddress.
	backEnd nopsFrom: endAddress to: methodZoneBase - 1.
	self recordGeneratedRunTime: trampolineName address: enilopmart.
	^self cCoerceSimple: enilopmart to: #'void (*)(void)'
]

{ #category : #initialization }
Cogit >> genEnilopmartFor: regArg called: trampolineName [
	"An enilopmart (the reverse of a trampoline) is a piece of code that makes
	 the system-call-like transition from the C runtime into generated machine
	 code.  The desired arguments and entry-point are pushed on a stackPage's
	 stack.  The enilopmart pops off the values to be loaded into registers and
	 then executes a return instruction to pop off the entry-point and jump to it."
	<returnTypeC: 'void (*genEnilopmartForcalled(sqInt regArg, char *trampolineName))(void)'>
	| size endAddress enilopmart |
	opcodeIndex := 0.
	self genLoadStackPointers.
	self PopR: regArg.
	self RetN: 0.
	self computeMaximumSizes.
	size := self generateInstructionsAt: methodZoneBase.
	endAddress := self outputInstructionsAt: methodZoneBase.
	self assert: methodZoneBase + size = endAddress.
	enilopmart := methodZoneBase.
	methodZoneBase := self alignUptoRoutineBoundary: endAddress.
	backEnd nopsFrom: endAddress to: methodZoneBase - 1.
	self recordGeneratedRunTime: trampolineName address: enilopmart.
	^self cCoerceSimple: enilopmart to: #'void (*)(void)'
]

{ #category : #'trampoline support' }
Cogit >> genExternalizePointersForPrimitiveCall [
	self MoveMw: 0 r: SPReg R: ClassReg.
	self MoveR: FPReg Aw: coInterpreter framePointerAddress.
	"Set coInterpreter stackPointer to the topmost argument, skipping the return address."
	self LoadEffectiveAddressMw: BytesPerWord r: SPReg R: TempReg.
	self MoveR: ClassReg Aw: coInterpreter instructionPointerAddress.
	self MoveR: TempReg Aw: coInterpreter stackPointerAddress.
	^0
]

{ #category : #initialization }
Cogit >> genGetLeafCallStackPointer [
	"Generate a routine that answers the stack pointer immedately
	 after a leaf call, used for checking stack pointer alignment."
	| startAddress |
	<inline: false>
	self allocateOpcodes: 32 bytecodes: 0.
	initialPC := 0.
	endPC := numAbstractOpcodes - 1.
	startAddress := methodZoneBase.
	backEnd genGetLeafCallStackPointerFunction.
	self outputInstructionsForGeneratedRuntimeAt: startAddress.
	self recordGeneratedRunTime: 'ceGetSP' address: startAddress.
	^startAddress
]

{ #category : #initialization }
Cogit >> genInnerPICAbortTrampoline: name [
	"Generate the abort for a PIC.  This abort performs either a call of
	 ceInterpretMethodFromPIC:receiver: to handle invoking an uncogged
	 target or a call of ceMNUFromPICMNUMethod:receiver: to handle an
	 MNU dispatch in a closed PIC.  It distinguishes the two by testing
	 ClassReg.  If the register is zero then this is an MNU."
	<var: #name type: #'char *'>
	| jumpMNUCase |
	<var: #jumpMNUCase type: #'AbstractInstruction *'>
	self CmpCq: 0 R: ClassReg.
	jumpMNUCase := self JumpZero: 0.
	self compileTrampolineFor: #ceInterpretMethodFromPIC:receiver: asSymbol
		callJumpBar: true
		numArgs: 2
		arg: SendNumArgsReg
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil.
	jumpMNUCase jmpTarget: self Label.
	^self genTrampolineFor: #ceMNUFromPICMNUMethod:receiver: asSymbol
		called: name
		callJumpBar: true
		numArgs: 2
		arg: SendNumArgsReg
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil
		appendOpcodes: true
]

{ #category : #'trampoline support' }
Cogit >> genLoadCStackPointers [
	self MoveAw: self cStackPointerAddress R: SPReg.
	cFramePointerInUse ifTrue:
		[self MoveAw: self cFramePointerAddress R: FPReg].
	^0
]

{ #category : #'trampoline support' }
Cogit >> genLoadCStackPointersForPrimCall [
	debugPrimCallStackOffset = 0
		ifTrue:
			[self MoveAw: self cStackPointerAddress R: SPReg]
		ifFalse:
			[self MoveAw: self cStackPointerAddress R: TempReg.
			 self SubCq: debugPrimCallStackOffset R: TempReg.
			 self MoveR: TempReg R: SPReg].
	cFramePointerInUse ifTrue:
		[self MoveAw: self cFramePointerAddress R: FPReg].
	^0
]

{ #category : #'trampoline support' }
Cogit >> genLoadStackPointers [
	"Switch back to the Smalltalk stack. Assign SPReg first
	 because typically it is used immediately afterwards."
	self MoveAw: coInterpreter stackPointerAddress R: SPReg.
	self MoveAw: coInterpreter framePointerAddress R: FPReg.
	^0
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
	opcodeIndex := 0.
	self CmpCq: 0 R: ReceiverResultReg.
	jumpSICMiss := self JumpNonZero: 0.
	self compileTrampolineFor: #ceStackOverflow: asSymbol
		callJumpBar: true
		numArgs: 1
		arg: SendNumArgsReg
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil.
	jumpSICMiss jmpTarget: self Label.
	^self genTrampolineFor: #ceSICMiss: asSymbol
		called: 'ceMethodAbort'
		callJumpBar: true
		numArgs: 1
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil
		appendOpcodes: true
]

{ #category : #initialization }
Cogit >> genNonLocalReturnTrampoline [
	opcodeIndex := 0.
	self PopR: TempReg. "instruction pointer"
	self MoveR: TempReg Aw: coInterpreter instructionPointerAddress.
	^self genTrampolineFor: #ceNonLocalReturn: asSymbol
		called: 'ceNonLocalReturnTrampoline'
		callJumpBar: true
		numArgs: 1
		arg: ReceiverResultReg
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil
		appendOpcodes: true
]

{ #category : #initialization }
Cogit >> genPICAbortTrampoline [
	"Generate the abort for a PIC.  This abort performs either a call of
	 ceInterpretMethodFromPIC:receiver: to handle invoking an uncogged
	 target or a call of ceMNUFromPICMNUMethod:receiver: to handle an
	 MNU dispatch in a closed PIC.  It distinguishes the two by testing
	 ClassReg.  If the register is zero then this is an MNU."
	opcodeIndex := 0.
	^self genInnerPICAbortTrampoline: 'cePICAbort'
]

{ #category : #initialization }
Cogit >> genSafeTrampolineFor: aRoutine called: aString arg: regOrConst0 [
	"Generate a trampoline with one argument that will
	 save and restore all registers around the call"
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		callJumpBar: true
		numArgs: 1
		arg: regOrConst0
		arg: nil
		arg: nil
		arg: nil
		saveRegs: true
		resultReg: nil
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genSafeTrampolineFor: aRoutine called: aString arg: regOrConst0 arg: regOrConst1 [
	"Generate a trampoline with two arguments that
	 will save and restore all registers around the call"
	<var: #aRoutine type: #'void *'>
	<var: #aString type: #'char *'>
	^self
		genTrampolineFor: aRoutine
		called: aString
		callJumpBar: true
		numArgs: 2
		arg: regOrConst0
		arg: regOrConst1
		arg: nil
		arg: nil
		saveRegs: true
		resultReg: nil
		appendOpcodes: false
]

{ #category : #'trampoline support' }
Cogit >> genSaveStackPointers [
	self MoveR: FPReg Aw: coInterpreter framePointerAddress.
	self MoveR: SPReg Aw: coInterpreter stackPointerAddress.
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
		callJumpBar: true
		numArgs: 0
		arg: nil
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil
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
		callJumpBar: true
		numArgs: 1
		arg: regOrConst0
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil
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
		callJumpBar: true
		numArgs: 2
		arg: regOrConst0
		arg: regOrConst1
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: nil
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
		callJumpBar: true
		numArgs: 3
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: nil
		saveRegs: false
		resultReg: nil
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
		callJumpBar: true
		numArgs: 4
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		saveRegs: false
		resultReg: nil
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
		callJumpBar: true
		numArgs: 3
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: nil
		saveRegs: false
		resultReg: resultReg
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
		callJumpBar: true
		numArgs: 2
		arg: regOrConst0
		arg: regOrConst1
		arg: nil
		arg: nil
		saveRegs: false
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
		callJumpBar: true
		numArgs: 1
		arg: regOrConst0
		arg: nil
		arg: nil
		arg: nil
		saveRegs: false
		resultReg: resultReg
		appendOpcodes: false
]

{ #category : #initialization }
Cogit >> genTrampolineFor: aRoutine called: trampolineName callJumpBar: callJumpBar "<Boolean>" numArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 saveRegs: saveRegs resultReg: resultRegOrNil appendOpcodes: appendBoolean [
	"Generate a trampoline with up to four arguments.  Generate either a call or a jump to aRoutineOrNil
	 as requested by callJumpBar.  If generating a call and resultRegOrNil is non-zero pass the C result
	 back in resultRegOrNil.
	 Hack: a negative value indicates an abstract register, a non-negative value indicates a constant."
	<var: #aRoutine type: #'void *'>
	<var: #trampolineName type: #'char *'>
	| startAddress |
	<inline: false>
	startAddress := methodZoneBase.
	appendBoolean ifFalse:
		[opcodeIndex := 0].
	self compileTrampolineFor: aRoutine
		callJumpBar: callJumpBar
		numArgs: numArgs
		arg: regOrConst0
		arg: regOrConst1
		arg: regOrConst2
		arg: regOrConst3
		saveRegs: saveRegs
		resultReg: resultRegOrNil.
	self outputInstructionsForGeneratedRuntimeAt: startAddress.
	self recordGeneratedRunTime: trampolineName address: startAddress.
	self recordRunTimeObjectReferences.
	^startAddress
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
	initialPC := 0.
	endPC := numAbstractOpcodes - 1.
	startAddress := methodZoneBase.
	captureFramePointer ifTrue:
		[self MoveR: FPReg Aw: self cFramePointerAddress].
	"Capture the stack pointer prior to the call."
	backEnd leafCallStackPointerDelta = 0
		ifTrue: [self MoveR: SPReg Aw: self cStackPointerAddress]
		ifFalse: [self MoveR: SPReg R: TempReg.
				self AddCq: backEnd leafCallStackPointerDelta R: TempReg.
				self MoveR: TempReg Aw: self cStackPointerAddress].
	self RetN: 0.
	self outputInstructionsForGeneratedRuntimeAt: startAddress.
	self recordGeneratedRunTime: 'ceCaptureCStackPointers' address: startAddress.
	ceCaptureCStackPointers := self cCoerceSimple: startAddress to: #'void (*)(void)'
]

{ #category : #initialization }
Cogit >> generateClosedPICPrototype [
	"Generate the prototype ClosedPIC to determine how much space as full PIC takes.
	 When we first allocate a closed PIC it only has one or two cases and we want to grow it.
	 So we have to determine how big a full one is before hand."
	| headerSize |
	numPICCases := 6.
	"stack allocate the various collections so that they
	 are effectively garbage collected on return."
	self allocateOpcodes: numPICCases * 7 bytecodes: 0.
	self compileClosedPICPrototype.
	self computeMaximumSizes.
	headerSize := self sizeof: CogMethod.
	closedPICSize := headerSize + (self generateInstructionsAt: methodZoneBase + headerSize).
	firstCPICCaseOffset := endCPICCase0 address - methodZoneBase.
	cPICCaseSize := endCPICCase1 address - endCPICCase0 address.
	cPICEndSize := closedPICSize - (numPICCases - 1 * cPICCaseSize + firstCPICCaseOffset).
	closedPICSize := methodZone roundUpLength: closedPICSize
	"self cCode: ''
		inSmalltalk:
			[| end |
			 end := self outputInstructionsAt: methodZoneBase + headerSize.
			 self disassembleFrom: methodZoneBase + headerSize to: end - 1.
			 self halt]"
]

{ #category : #'generate machine code' }
Cogit >> generateCogMethod: selector [
	"We handle jump sizing simply.  First we make a pass that asks each
	 instruction to compute its maximum size.  Then we make a pass that
	 sizes jumps based on the maxmimum sizes.  Then we make a pass
	 that fixes up jumps.  When fixing up a jump the jump is not allowed to
	 choose a smaller offset but must stick to the size set in the second pass."
	| codeSize headerSize mapSize totalSize startAddress result method |
	<var: #method type: #'CogMethod *'>
	<var: #blockStart type: #'BlockStart *'>
	<var: #headerReference type: #'AbstractInstruction *'>
	<returnTypeC: #'CogMethod *'>
	headerSize := self sizeof: CogMethod.
	methodLabel address: headerSize negated.
	self computeMaximumSizes.
	methodLabel concretizeAt: (methodZone allocate: 0).
	codeSize := self generateInstructionsAt: methodLabel address + headerSize.
	mapSize := self generateMapAt: 0 start: methodLabel address + cmNoCheckEntryOffset.
	totalSize := methodZone roundUpLength: headerSize + codeSize + mapSize.
	startAddress := methodZone allocate: totalSize.
	startAddress = 0 ifTrue:
		[^self cCoerceSimple: InsufficientCodeSpace to: #'CogMethod *'].
	self assert: startAddress + cmEntryOffset = entry address.
	self assert: startAddress + cmNoCheckEntryOffset = noCheckEntry address.
	result := self outputInstructionsAt: startAddress + headerSize.
	self assert: startAddress + headerSize + codeSize = result.
	backEnd nopsFrom: result to: startAddress + totalSize - mapSize.
	self generateMapAt: startAddress + totalSize - 1 start: startAddress + cmNoCheckEntryOffset.
	self fillInBlockHeadersAt: startAddress.
	method := self fillInMethodHeader: (self cCoerceSimple: startAddress to: #'CogMethod *')
					size: totalSize
					selector: selector.
	postCompileHook notNil ifTrue:
		[self perform: postCompileHook with: method with: primInvokeLabel.
		 postCompileHook := nil].
	processor flushICacheFrom: startAddress to: startAddress + headerSize + codeSize.
	^method
]

{ #category : #initialization }
Cogit >> generateEnilopmarts [
	"Enilopmarts transfer control from C into machine code (backwards trampolines)."
	self cppIf: Debug
		ifTrue:
			[realCEEnterCogCodePopReceiverReg :=
				self genEnilopmartFor: ReceiverResultReg
					called: 'realCEEnterCogCodePopReceiverReg'.
			 ceEnterCogCodePopReceiverReg := #enterCogCodePopReceiver asSymbol.
			 realCEEnterCogCodePopReceiverAndClassRegs :=
				self genEnilopmartFor: ReceiverResultReg
					and: ClassReg
					called: 'realCEEnterCogCodePopReceiverAndClassRegs'.
			 ceEnterCogCodePopReceiverAndClassRegs := #enterCogCodePopReceiverAndClassRegs asSymbol]
		ifFalse:
			[ceEnterCogCodePopReceiverReg := self genEnilopmartFor: ReceiverResultReg
				called: 'ceEnterCogCodePopReceiverReg'.
			 ceEnterCogCodePopReceiverAndClassRegs :=
				self genEnilopmartFor: ReceiverResultReg
					and: ClassReg
					called: 'ceEnterCogCodePopReceiverAndClassRegs'].

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
		breakPC = absoluteAddress ifTrue:
			[self halt: 'breakPC reached in generateInstructionsAt:'].
		abstractInstruction := self abstractInstructionAt: i.
		abstractInstruction isPCDependent
			ifTrue:
				[abstractInstruction sizePCDependentInstructionAt: absoluteAddress.
				 fixup := self fixupAt: pcDependentIndex.
				 pcDependentIndex := pcDependentIndex + 1.
				 fixup instructionIndex: i.
				 absoluteAddress := absoluteAddress + abstractInstruction machineCodeSize]
			ifFalse:
				[absoluteAddress := abstractInstruction concretizeAt: absoluteAddress]].
	0 to: pcDependentIndex - 1 do:
		[:i|
		fixup := self fixupAt: i.
		abstractInstruction := self abstractInstructionAt: fixup instructionIndex.
		breakPC = absoluteAddress ifTrue:
			[self halt: 'breakPC reached in generateInstructionsAt:'].
		abstractInstruction concretizeAt: abstractInstruction address].
	self cCode: ''
		inSmalltalk:
			[breakPC ifNotNil:
				[breakPC <= absoluteAddress ifTrue:
					[self singleStep: true]]].
	^absoluteAddress - eventualAbsoluteAddress
]

{ #category : #'method map' }
Cogit >> generateMapAt: addressOrNull start: startAddress [
	"Generate the method map at addressrNull (or compute it if adressOrNull is null).
	 Answer the length of the map in byes.  Each entry in the map is in two parts.  In the
	 least signficant bits are a displacement of how far from the start or previous entry.
	 In the most signficant bits are the type of annotation at the point reached.  A null
	 byte ends the map."
	| length location |
	<var: #annotation type: #'InstructionAnnotation *'>
	length := 0.
	location := startAddress.
	0 to: annotationIndex - 1 do:
		[:i| | annotation mcpc delta maxDelta mapEntry |
		 annotation := self addressOf: (annotations at: i).
		 mcpc := annotation instruction address + annotation instruction machineCodeSize.
		 [(delta := mcpc - location) > MaxUnitDisplacement] whileTrue:
			[maxDelta := (delta min: MaxX2NDisplacement) bitAnd: DisplacementMask bitInvert32.
			 self assert: maxDelta >> AnnotationShift <= DisplacementMask.
			 addressOrNull ~= 0 ifTrue:
				[objectMemory
					byteAt: addressOrNull - length
					put: maxDelta >> AnnotationShift + DisplacementX2N.
				 self traceMap: IsDisplacementX2N
					  byte: maxDelta >> AnnotationShift + DisplacementX2N
					  at: addressOrNull - length
					  for: mcpc].
			 location := location + maxDelta.
			 length := length + 1].
		 addressOrNull ~= 0 ifTrue:
			[mapEntry := delta + (annotation annotation << AnnotationShift).
			 objectMemory byteAt: addressOrNull - length put: mapEntry.
			 self traceMap: annotation
				  byte: mapEntry
				  at: addressOrNull - length
				  for: mcpc].
		 location := location + delta.
		 length := length + 1].
	addressOrNull ~= 0 ifTrue:
		[objectMemory byteAt: addressOrNull - length put: MapEnd.
		 self traceMap: MapEnd
			  byte: MapEnd
			  at: addressOrNull - length
			  for: 0].
	^length + 1
]

{ #category : #initialization }
Cogit >> generateMissAbortTrampolines [
	"Generate the run-time entries for the various method and PIC entry misses and aborts..
	 Read the class-side method trampolines for documentation on the various trampolines"

	self subclassResponsibility
]

{ #category : #initialization }
Cogit >> generateNewspeakRuntime [
	<option: #NewspeakVM>
	| jumpMiss jumpItsTheReceiverStupid |
	<var: #jumpMiss type: #'AbstractInstruction *'>
	<var: #jumpItsTheReceiverStupid type: #'AbstractInstruction *'>
	"Generate the non-send runtime support for Newspeak, explicit outer and implicit receiver.
	 The dynamic frequency of explicit outer is so low we merely cann an interpreter routine."
	ceExplicitReceiverTrampoline := self genTrampolineFor: #ceExplicitReceiverAt: asSymbol
												called: 'ceExplicitReceiverTrampoline'
												arg: SendNumArgsReg
												result: ReceiverResultReg.
	"Cached push implicit receiver implementation.  Caller looks like
				mov selector, ClassReg
				call ceImplicitReceiver
				br continue
		Lclass:	.word
		Lmixin::	.word
		continue:
	 If class matches class of receiver then mixin contains either 0 or the implicit receiver.
	 If 0, answer the actual receiver, otherwise the mixin.
	 Generate the class fetch and cache probe inline for speed. Smashes Arg0Reg and caller-saved regs."
	opcodeIndex := 0.
	self MoveMw: FoxMFReceiver r: FPReg R: ReceiverResultReg.
	objectRepresentation genGetClassObjectOf: ReceiverResultReg into: ClassReg scratchReg: TempReg.
	self MoveMw: 0 r: SPReg R: TempReg.
	self MoveMw: backEnd jumpShortByteSize r: TempReg R: Arg0Reg.
	self CmpR: ClassReg R: Arg0Reg.
	jumpMiss := self JumpNonZero: 0.
	self MoveMw: backEnd jumpShortByteSize + BytesPerOop r: TempReg R: ClassReg.
	self CmpCq: 0 R: ClassReg.
	jumpItsTheReceiverStupid := self JumpZero: 0.
	self MoveR: ClassReg R: ReceiverResultReg.
	jumpItsTheReceiverStupid jmpTarget: (self RetN: 0).
	jumpMiss jmpTarget: self Label.
	ceImplicitReceiverTrampoline := self
										genTrampolineFor: #ceImplicitReceiverFor:receiver:class: asSymbol
										called: 'ceImplicitReceiverTrampoline'
										callJumpBar: true
										numArgs: 3
										arg: SendNumArgsReg
										arg: ReceiverResultReg
										arg: ClassReg
										arg: nil
										saveRegs: false
										resultReg: ReceiverResultReg
										appendOpcodes: true
]

{ #category : #initialization }
Cogit >> generateOpenPICPrototype [
	"Generate the prototype ClosedPIC to determine how much space as full PIC takes.
	 When we first allocate a closed PIC it only has one or two cases and we want to grow it.
	 So we have to determine how big a full one is before hand."
	| headerSize codeSize mapSize |
	"stack allocate the various collections so that they
	 are effectively garbage collected on return."
	self allocateOpcodes: 100 bytecodes: 0.
	"Ned a real selector here so that the map accomodates the annotations for the selector."
	self compileOpenPIC: (coInterpreter specialSelector: 0) numArgs: self numRegArgs.
	self computeMaximumSizes.
	headerSize := self sizeof: CogMethod.
	methodLabel concretizeAt: methodZoneBase.
	codeSize := self generateInstructionsAt: methodZoneBase + headerSize.
	mapSize := self generateMapAt: 0 start: methodZoneBase + cmNoCheckEntryOffset.
	openPICSize := (methodZone roundUpLength: headerSize + codeSize) + (methodZone roundUpLength: mapSize).
	"self cCode: ''
		inSmalltalk:
			[| end |
			 end := self outputInstructionsAt: methodZoneBase + headerSize.
			 self disassembleFrom: methodZoneBase + headerSize to: end - 1.
			 self halt]"
]

{ #category : #initialization }
Cogit >> generateRunTimeTrampolines [
	"Generate the run-time entries at the base of the native code zone and update the base."
	ceSendMustBeBooleanAddFalseTrampoline := self genMustBeBooleanTrampolineFor: objectMemory falseObject
														called: 'ceSendMustBeBooleanAddFalseTrampoline'.
	ceSendMustBeBooleanAddTrueTrampoline := self genMustBeBooleanTrampolineFor: objectMemory trueObject
														called: 'ceSendMustBeBooleanAddTrueTrampoline'.
	"Slang needs these apparently superfluous asSymbol sends."
	ceClosureCopyTrampoline := self genTrampolineFor: #ceClosureCopyDescriptor: asSymbol
									called: 'ceClosureCopyTrampoline'
									arg: SendNumArgsReg
									result: ReceiverResultReg.
	ceActiveContextTrampoline := self genActiveContextTrampoline.
	ceNonLocalReturnTrampoline := self genNonLocalReturnTrampoline.
	ceBaseFrameReturnTrampoline := self genTrampolineFor: #ceBaseFrameReturn: asSymbol
										called: 'ceBaseFrameReturnTrampoline'
										arg: ReceiverResultReg.
	ceCreateNewArrayTrampoline := self genTrampolineFor: #ceNewArraySlotSize: asSymbol
										called: 'ceCreateNewArrayTrampoline'
										arg: SendNumArgsReg
										result: ReceiverResultReg.
	ceCheckForInterruptTrampoline := self genCheckForInterruptsTrampoline.
	ceStoreCheckTrampoline := objectRepresentation genStoreCheckTrampoline.
	ceFetchContextInstVarTrampoline := self genTrampolineFor: #ceContext:instVar: asSymbol
											called: 'ceFetchContextInstVarTrampoline'
											arg: ReceiverResultReg
											arg: SendNumArgsReg
											result: SendNumArgsReg.
	ceStoreContextInstVarTrampoline := self genTrampolineFor: #ceContext:instVar:value: asSymbol
											called: 'ceStoreContextInstVarTrampoline'
											arg: ReceiverResultReg
											arg: SendNumArgsReg
											arg: ClassReg
											result: ReceiverResultReg. "to keep ReceiverResultReg live."
	cePositive32BitIntegerTrampoline := self genTrampolineFor: #cePositive32BitIntegerFor: asSymbol
											called: 'cePositive32BitIntegerTrampoline'
											arg: ReceiverResultReg
											result: TempReg.
	ceReturnToInterpreterTrampoline := self genTrampolineFor: #ceReturnToInterpreter: asSymbol
											called: 'ceReturnToInterpreterTrampoline'
											arg: ReceiverResultReg.
	ceCannotResumeTrampoline := self genTrampolineFor: #ceCannotResume asSymbol
											called: 'ceCannotResumeTrampoline'
]

{ #category : #initialization }
Cogit >> generateSendTrampolines [
	"Slang needs these apparently superfluous asSymbol sends."
	0 to: NumSendTrampolines - 2 do:
		[:numArgs|
		sendTrampolines
			at: numArgs
			put: (self genTrampolineFor: #ceSend:super:to:numArgs: asSymbol
					  called: (self trampolineName: 'ceSend' numArgs: numArgs)
					  arg: ClassReg
					  arg: 0
					  arg: ReceiverResultReg
					  arg: numArgs)].
	sendTrampolines
		at: NumSendTrampolines - 1
		put: (self genTrampolineFor: #ceSend:super:to:numArgs: asSymbol
					called: (self trampolineName: 'ceSend' numArgs: -1)
					arg: ClassReg
					arg: 0
					arg: ReceiverResultReg
					arg: SendNumArgsReg).
	self cppIf: NewspeakVM
		ifTrue:
			[0 to: NumSendTrampolines - 2 do:
				[:numArgs|
				dynamicSuperSendTrampolines
					at: numArgs
					put: (self genTrampolineFor: #ceDynamicSuperSend:to:numArgs: asSymbol
							  called: (self trampolineName: 'ceDynSuperSend' numArgs: numArgs)
							  arg: ClassReg
							  arg: ReceiverResultReg
							  arg: numArgs)].
			dynamicSuperSendTrampolines
				at: NumSendTrampolines - 1
				put: (self genTrampolineFor: #ceDynamicSuperSend:to:numArgs: asSymbol
							called: (self trampolineName: 'ceDynSuperSend' numArgs: -1)
							arg: ClassReg
							arg: ReceiverResultReg
							arg: SendNumArgsReg)].
	0 to: NumSendTrampolines - 2 do:
		[:numArgs|
		superSendTrampolines
			at: numArgs
			put: (self genTrampolineFor: #ceSend:super:to:numArgs: asSymbol
					  called: (self trampolineName: 'ceSuperSend' numArgs: numArgs)
					  arg: ClassReg
					  arg: 1
					  arg: ReceiverResultReg
					  arg: numArgs)].
	superSendTrampolines
		at: NumSendTrampolines - 1
		put: (self genTrampolineFor: #ceSend:super:to:numArgs: asSymbol
					called: (self trampolineName: 'ceSuperSend' numArgs: -1)
					arg: ClassReg
					arg: 1
					arg: ReceiverResultReg
					arg: SendNumArgsReg).
	firstSend := sendTrampolines at: 0.
	lastSend := superSendTrampolines at: NumSendTrampolines - 1
]

{ #category : #initialization }
Cogit >> generateStackPointerCapture [
	"Generate a routine ceCaptureCStackPointers that will capture the C stack pointer,
	 and, if it is in use, the C frame pointer.  These are used in trampolines to call
	 run-time routines in the interpreter from machine-code."

	| oldMethodZoneBase oldTrampolineTableIndex |
	self assertCStackWellAligned.
	oldMethodZoneBase := methodZoneBase.
	oldTrampolineTableIndex := trampolineTableIndex.
	self generateCaptureCStackPointers: true.
	self perform: #ceCaptureCStackPointers asSymbol.
	(cFramePointerInUse := self isCFramePointerInUse) ifFalse:
		[methodZoneBase := oldMethodZoneBase.
		 trampolineTableIndex := oldTrampolineTableIndex.
		 self generateCaptureCStackPointers: false]
]

{ #category : #initialization }
Cogit >> generateTrampolines [
	"Generate the run-time entries and exits at the base of the native code zone and update the base.
	 Read the class-side method trampolines for documentation on the various trampolines"
	| methodZoneStart |
	methodZoneStart := methodZoneBase.
	self allocateOpcodes: 40 bytecodes: 0.
	initialPC := 0.
	endPC := numAbstractOpcodes - 1.
	hasYoungReferent := false.
	self generateSendTrampolines.
	self generateMissAbortTrampolines.
	self generateRunTimeTrampolines.
	self cppIf: NewspeakVM ifTrue: 	[self generateNewspeakRuntime].
	self generateEnilopmarts.
	self generateTracingTrampolines.

	"finish up"
	self recordGeneratedRunTime: 'methodZoneBase' address: methodZoneBase.
	processor flushICacheFrom: methodZoneStart to: methodZoneBase.
	self cCode: ''
		inSmalltalk:
			[simulatedTrampolines keysAndValuesDo:
				[:addr :selector|
				simulatedTrampolines
					at: addr
					put: (MessageSend
							receiver: ((self respondsTo: selector)
										ifTrue: [self]
										ifFalse: [(coInterpreter respondsTo: selector)
													ifTrue: [coInterpreter]
													ifFalse: [(objectMemory respondsTo: selector)
														ifTrue: [objectMemory]
														ifFalse: [self notify: 'cannot find receiver for ', selector]]])
							selector: selector
							arguments: (1 to: selector numArgs) asArray)]]
]

{ #category : #initialization }
Cogit >> generateVMOwnerLockFunctions [
	| startAddress |
	<inline: false>
	self cppIf: COGMTVM
		ifTrue:
			[self allocateOpcodes: backEnd numLowLevelLockOpcodes bytecodes: 0.
			initialPC := 0.
			endPC := numAbstractOpcodes - 1.
			startAddress := methodZoneBase.
			backEnd generateLowLevelTryLock: coInterpreter vmOwnerLockAddress.
			self outputInstructionsForGeneratedRuntimeAt: startAddress.
			self recordGeneratedRunTime: 'ceTryLockVMOwner' address: startAddress.
			ceTryLockVMOwner := self cCoerceSimple: startAddress to: #'unsigned long (*)(void)'.

			opcodeIndex := 0.
			initialPC := 0.
			endPC := numAbstractOpcodes - 1.
			startAddress := methodZoneBase.
			backEnd generateLowLevelUnlock: coInterpreter vmOwnerLockAddress.
			self outputInstructionsForGeneratedRuntimeAt: startAddress.
			self recordGeneratedRunTime: 'ceUnlockVMOwner' address: startAddress.
			ceUnlockVMOwner := self cCoerceSimple: startAddress to: #'void (*)(void)']
]

{ #category : #'compile abstract instructions' }
Cogit >> generatorAt: index [
	<cmacro: '(index) (&generatorTable[index])'>
	<returnTypeC: #'BytecodeDescriptor *'>
	^generatorTable at: index
]

{ #category : #accessing }
Cogit >> getCFramePointer [
	<api>
	<cmacro: '() CFramePointer'>
	"and in the simulator we use..."
	^objectMemory longAt: coInterpreter inMemoryCFramePointerAddress
]

{ #category : #accessing }
Cogit >> getCStackPointer [
	<api>
	<cmacro: '() CStackPointer'>
	"and in the simulator we use..."
	^objectMemory longAt: coInterpreter inMemoryCStackPointerAddress
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

{ #category : #'simulation only' }
Cogit >> handleCallOrJumpSimulationTrap: aProcessorSimulationTrap [
	<doNotGenerate>
	| evaluable function result savedFramePointer savedStackPointer savedArgumentCount rpc |
	evaluable := simulatedTrampolines at: aProcessorSimulationTrap address.
	function := evaluable
					isBlock ifTrue: ['aBlock; probably some plugin primitive']
					ifFalse: [evaluable selector].
	function ~~ #ceBaseFrameReturn: ifTrue:
		[coInterpreter assertValidExternalStackPointers].
	(function beginsWith: 'ceShort') ifTrue:
		[^self perform: function with: aProcessorSimulationTrap].
	aProcessorSimulationTrap type = #call
		ifTrue:
			[processor
				simulateCallOf: aProcessorSimulationTrap address
				nextpc: aProcessorSimulationTrap nextpc
				memory: coInterpreter memory.
			self recordInstruction: {'(simulated call of '. aProcessorSimulationTrap address. '/'. function. ')'}]
		ifFalse:
			[processor
				simulateJumpCallOf: aProcessorSimulationTrap address
				memory: coInterpreter memory.
			 self recordInstruction: {'(simulated jump to '. aProcessorSimulationTrap address. '/'. function. ')'}].
	savedFramePointer := coInterpreter framePointer.
	savedStackPointer := coInterpreter stackPointer.
	savedArgumentCount := coInterpreter argumentCount.
	result := ["self halt: evaluable selector."
			   evaluable valueWithArguments: (processor
												postCallArgumentsNumArgs: evaluable numArgs
												in: coInterpreter memory)]
				on: ReenterMachineCode
				do: [:ex| ex return: ex returnValue].
			
	coInterpreter assertValidExternalStackPointers.
	"Verify the stack layout assumption compileInterpreterPrimitive: makes, provided we've
	 not called something that has built a frame, such as closure value or evaluate method, or
	 switched frames, such as primitiveSignal, primitiveWait, primitiveResume, primitiveSuspend et al."
	(function beginsWith: 'primitive') ifTrue:
		[coInterpreter primFailCode = 0
			ifTrue: [(#(	primitiveClosureValue primitiveClosureValueWithArgs primitiveClosureValueNoContextSwitch
						primitiveSignal primitiveWait primitiveResume primitiveSuspend primitiveYield
						primitiveExecuteMethodArgsArray primitiveExecuteMethod
						primitivePerform primitivePerformWithArgs primitivePerformInSuperclass
						primitiveTerminateTo primitiveStoreStackp primitiveDoPrimitiveWithArgs)
							includes: function) ifFalse:
						[self assert: savedFramePointer = coInterpreter framePointer.
						 self assert: savedStackPointer + (savedArgumentCount * BytesPerWord)
								= coInterpreter stackPointer]]
			ifFalse:
				[self assert: savedFramePointer = coInterpreter framePointer.
				 self assert: savedStackPointer = coInterpreter stackPointer]].
	result ~~ #continueNoReturn ifTrue:
		[self recordInstruction: {'(simulated return to '. processor retpcIn: coInterpreter memory. ')'}.
		 rpc := processor retpcIn: coInterpreter memory.
		 self assert: (rpc >= codeBase and: [rpc < methodZone zoneLimit]).
		 processor
			smashCallerSavedRegistersWithValuesFrom: 16r80000000 by: BytesPerWord;
			simulateReturnIn: coInterpreter memory].
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
	| variableValue |
	variableValue := (simulatedVariableGetters at: aProcessorSimulationTrap address) value asInteger.
	processor
		perform: aProcessorSimulationTrap registerAccessor
		with: variableValue signedIntToLong.
	processor pc: aProcessorSimulationTrap nextpc
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
	aProcessorSimulationTrap address < coInterpreter cogCodeSize ifTrue:
		[self error: 'attempt to write to code space'].
	variableValue := processor perform: aProcessorSimulationTrap registerAccessor.
	(simulatedVariableSetters at: aProcessorSimulationTrap address) value: variableValue.
	processor pc: aProcessorSimulationTrap nextpc
]

{ #category : #compaction }
Cogit >> incrementUsageOfTargetIfLinkedSend: annotation mcpc: mcpc ignored: superfluity [
	<var: #mcpc type: #'char *'>
	| entryPoint offset targetMethod |
	<var: #targetMethod type: #'CogMethod *'>
	(self isSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase ifTrue: "It's a linked send."
			[self
				offsetAndSendTableFor: entryPoint
				annotation: annotation
				into: [:off :table| offset := off].
			targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
			targetMethod cmUsageCount < (CMMaxUsageCount // 2) ifTrue:
				[targetMethod cmUsageCount: targetMethod cmUsageCount + 1]]].
	^0 "keep scanning"
]

{ #category : #'generate machine code' }
Cogit >> initialClosedPICUsageCount [
	"Answer a usage count that reflects likely long-term usage."
	^2
]

{ #category : #'generate machine code' }
Cogit >> initialMethodUsageCount [
	"Answer a usage count that reflects likely long-term usage.
	 Answer 0 for non-primitives or quick primitives (inst var accessors),
	 1 for methods with interpreter primitives, and 2 for compiled primitives."
	(primitiveIndex = 0
	 or: [coInterpreter isQuickPrimitiveIndex: primitiveIndex]) ifTrue:
		[^0].
	self primitiveGeneratorOrNil isNil ifTrue:
		[^1].
	^2
]

{ #category : #'generate machine code' }
Cogit >> initialOpenPICUsageCount [
	"Answer a usage count that reflects likely long-term usage."
	^3
]

{ #category : #initialization }
Cogit >> initialize [
	cogMethodSurrogateClass := BytesPerWord = 4
											ifTrue: [CogMethodSurrogate32]
											ifFalse: [CogMethodSurrogate64].
	cogBlockMethodSurrogateClass := BytesPerWord = 4
											ifTrue: [CogBlockMethodSurrogate32]
											ifFalse: [CogBlockMethodSurrogate64]
]

{ #category : #initialization }
Cogit >> initializeBackend [
	"A hook for the StackToregisterMappingCogit to override.
	 We just initialize the methodLabel here because backEnd is static."
	methodLabel machineCodeSize: 0.
	methodLabel opcode: Label.
	methodLabel operands at: 0 put: 0.
	methodLabel operands at: 1 put: 0 "label offset"
]

{ #category : #initialization }
Cogit >> initializeCodeZoneFrom: startAddress upTo: endAddress [
	<api>
	self cCode: [self sqMakeMemoryExecutableFrom: startAddress To: endAddress]
		inSmalltalk: [self initializeProcessor].
	codeBase := methodZoneBase := (self
											cCode: [startAddress]
											inSmalltalk: [startAddress + guardPageSize]).
	minValidCallAddress := (codeBase min: coInterpreter interpretAddress)
								min: coInterpreter primitiveFailAddress.
	self initializeBackend.
	self maybeGenerateCheckFeatures.
	self maybeGenerateICacheFlush.
	self generateVMOwnerLockFunctions.
	ceGetSP := self cCoerceSimple: self genGetLeafCallStackPointer to: #'unsigned long (*)(void)'.
	self generateStackPointerCapture.
	self generateTrampolines.
	self checkPrimitiveTableEnablers.
	methodZone manageFrom: methodZoneBase to: endAddress.
	self computeEntryOffsets.
	self generateClosedPICPrototype.
	"N.B. this is assumed to be the last thing done in initialization; see Cogit>>initialized"
	self generateOpenPICPrototype
]

{ #category : #'compile abstract instructions' }
Cogit >> initializeFixupAt: targetIndex [
	"Make sure there's a flagged fixup at the targetIndex (pc relative to first pc) in fixups.
	 Initially a fixup's target is just a flag.  Later on it is replaced with a proper instruction."
	<returnTypeC: #'BytecodeFixup *'>
	| fixup |
	<var: #fixup type: #'BytecodeFixup *'>
	fixup := self fixupAt: targetIndex.
	fixup targetInstruction: (self cCoerceSimple: 1 to: #'AbstractInstruction *').
	^fixup
]

{ #category : #initialization }
Cogit >> initializeProcessor [
	"Initialize the simulation processor, arranging that its initial stack is somewhere on the rump C stack."
	<doNotGenerate>
	guardPageSize := 1024.
	lastNInstructions := OrderedCollection new.
	"This is for testing.  On many OS's the stack must remain aligned;
	 e.g. IA32 using SSE requires 16 byte alignment."
	expectedSPAlignment := 0. expectedFPAlignment := 8. cStackAlignment := 16.
	processor class setStackAlignmentDelta: cStackAlignment.
	self initializeProcessorStack: coInterpreter rumpCStackAddress.
	objectMemory
		longAt: self cFramePointerAddress put: processor fp;
		longAt: self cStackPointerAddress put: processor sp.
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

{ #category : #initialization }
Cogit >> isCFramePointerInUse [
	<doNotGenerate>
	"This should be implemented externally, e.g. in sqPlatMain.c."
	^true
]

{ #category : #'method map' }
Cogit >> isPCMappedAnnotation: annotation [
	<inline: true>
	^(self isSendAnnotation: annotation)
	  or: [annotation = HasBytecodePC]
]

{ #category : #disassembly }
Cogit >> isPCWithinMethodZone: address [
	<api>
	<var: #address type: #'char *'>
	^address asUnsignedInteger
		between: methodZoneBase
		and: methodZone zoneLimit
]

{ #category : #'method map' }
Cogit >> isSendAnnotation: annotation [
	<inline: true>
	^self cppIf: NewspeakVM
		ifTrue: [annotation = IsSendCall or: [annotation = IsNSSendCall]]
		ifFalse: [annotation = IsSendCall]
]

{ #category : #'jit - api' }
Cogit >> isSendReturnPC: retpc [
	<api>
	"Answer if the instruction preceeding retpc is a call instruction."
	| target |
	(backEnd isCallPreceedingReturnPC: retpc) ifFalse:
		[^false].
	target := backEnd callTargetFromReturnAddress: retpc.
	^(target between: firstSend and: lastSend)
	   or: [target between: methodZoneBase and: methodZone zoneLimit]
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

{ #category : #'compile abstract instructions' }
Cogit >> lastOpcode [
	<returnTypeC: #'AbstractInstruction *'>
	self assert: opcodeIndex > 0.
	^self abstractInstructionAt: opcodeIndex - 1
]

{ #category : #'compile abstract instructions' }
Cogit >> latestContinuationPCFor: descriptor at: pc byte0: opcodeByte in: aMethodObj [
	"Assuming the descriptor is that for a branch or block,
	 answer the furthest reachable pc for this bytecode."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	| distance |
	distance := self spanFor: descriptor at: pc byte0: opcodeByte in: aMethodObj.
	^pc + descriptor numBytes + (distance max: 0)
]

{ #category : #'in-line cacheing' }
Cogit >> linkSendAt: callSiteReturnAddress in: sendingMethod to: targetMethod offset: entryOffset receiver: receiver [
	<api>
	<var: #sendingMethod type: #'CogMethod *'>
	<var: #targetMethod type: #'CogMethod *'>
	| inlineCacheTag address extent |
	self cppIf: NewspeakVM
		ifTrue: [self assert: (entryOffset = cmEntryOffset
							or: [entryOffset = cmNoCheckEntryOffset
							or: [entryOffset = cmDynSuperEntryOffset]])]
		ifFalse: [self assert: (entryOffset = cmEntryOffset
							or: [entryOffset = cmNoCheckEntryOffset])].
	self assert: (callSiteReturnAddress between: methodZoneBase and: methodZone zoneLimit).
	inlineCacheTag := entryOffset = cmNoCheckEntryOffset
						ifTrue: [targetMethod selector "i.e. no change"]
						ifFalse: [objectRepresentation inlineCacheTagForInstance: receiver].
	(sendingMethod cmRefersToYoung not
	 and: [(objectRepresentation inlineCacheTagIsYoung: inlineCacheTag)]) ifTrue:
		[self assert: (methodZone occurrencesInYoungReferrers: sendingMethod) = 0.
		 sendingMethod cmRefersToYoung: true.
		 methodZone addToYoungReferrers: sendingMethod].
	address := targetMethod asInteger + entryOffset.
	extent := backEnd
				rewriteInlineCacheAt: callSiteReturnAddress
				tag: inlineCacheTag
				target: address.
	processor
		flushICacheFrom: callSiteReturnAddress - 1 - extent
		to: callSiteReturnAddress - 1
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
									lookup: selector
									receiver: receiver.
	methodOrSelectorIndex asUnsignedInteger > objectMemory startOfMemory ifTrue:
		[(objectMemory isOopCompiledMethod: methodOrSelectorIndex) ifFalse:
			[^binaryBlock value: methodOrSelectorIndex value: SelectorCannotInterpret].
		 ((coInterpreter methodHasCogMethod: methodOrSelectorIndex) not
		  and: [coInterpreter methodShouldBeCogged: methodOrSelectorIndex]) ifTrue:
			["We assume cog:selector: will *not* reclaim the method zone"
			 self cog: methodOrSelectorIndex selector: selector].
		^binaryBlock value: methodOrSelectorIndex value: nil].
	methodOrSelectorIndex = SelectorDoesNotUnderstand ifTrue:
		[methodOrSelectorIndex := coInterpreter
										lookup: (objectMemory splObj: SelectorDoesNotUnderstand)
										receiver: receiver.
		 methodOrSelectorIndex asUnsignedInteger > objectMemory startOfMemory ifTrue:
			[self assert: (objectMemory isOopCompiledMethod: methodOrSelectorIndex).
			 ((coInterpreter methodHasCogMethod: methodOrSelectorIndex) not
			  and: [coInterpreter methodShouldBeCogged: methodOrSelectorIndex]) ifTrue:
				["We assume cog:selector: will *not* reclaim the method zone"
				 self cog: methodOrSelectorIndex selector: selector].
			^binaryBlock value: methodOrSelectorIndex value: SelectorDoesNotUnderstand].
		^binaryBlock value: nil value: SelectorDoesNotUnderstand].
	^binaryBlock value: nil value: methodOrSelectorIndex
]

{ #category : #disassembly }
Cogit >> lookupAddress: address [
	<doNotGenerate>
	| cogMethod |
	address < methodZone zoneLimit ifTrue:
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
	(aCHexString beginsWith: '0x') ifFalse:
		[^aCHexString].
	^(self lookupAddress: (Number
								readFrom: (aCHexString copyFrom: 3 to: aCHexString size) asUppercase readStream
								base: 16))
		ifNotNil: [:string| aCHexString, '=', string]
		ifNil: [aCHexString]
]

{ #category : #'method map' }
Cogit >> mapEndFor: cogMethod [
	"Answer the address of the null byte at the end of the method map."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	| end |
	end := self mapStartFor: cogMethod.
	[(coInterpreter byteAt: end) ~= MapEnd] whileTrue:
		[end := end - 1.
		 self assert: end > (cogMethod asInteger + cmNoCheckEntryOffset)].
	^end
]

{ #category : #'method map' }
Cogit >> mapFor: cogMethod bcpc: startbcpc performUntil: functionSymbol arg: arg [
	"Machine-code <-> bytecode pc mapping support.  Evaluate functionSymbol
	 for each mcpc, bcpc pair in the map until the function returns non-zero,
	 answering that result, or 0 if it fails to.  This works only for frameful methods."
	<var: #cogMethod type: #'CogBlockMethod *'>
	<var: #functionSymbol declareC: 'sqInt (*functionSymbol)(char *mcpc, sqInt bcpc, void *arg)'>
	<var: #arg type: #'void *'>
	| isInBlock mcpc bcpc endbcpc map mapByte homeMethod aMethodObj result
	  latestContinuation byte descriptor |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<var: #homeMethod type: #'CogMethod *'>
	self assert: cogMethod stackCheckOffset > 0.
	"In both CMMethod and CMBlock cases find the start of the map and
	 skip forward to the bytecode pc map entry for the stack check."
	cogMethod cmType = CMMethod
		ifTrue:
			[isInBlock := false.
			 homeMethod := self cCoerceSimple: cogMethod to: #'CogMethod *'.
			 self assert: startbcpc = (coInterpreter startPCOfMethodHeader: homeMethod methodHeader).
			 map := self mapStartFor: homeMethod.
			 self assert: ((coInterpreter byteAt: map) >> AnnotationShift = IsAbsPCReference
						 or: [(coInterpreter byteAt: map) >> AnnotationShift = IsRelativeCall
						 or: [(coInterpreter byteAt: map) >> AnnotationShift = IsDisplacementX2N]]).
			 latestContinuation := startbcpc.
			 aMethodObj := homeMethod methodObject.
			 endbcpc := (objectMemory byteSizeOf: aMethodObj) - 1]
		ifFalse:
			[isInBlock := true.
			 homeMethod := cogMethod cmHomeMethod.
			 map := self findMapLocationForMcpc: cogMethod asUnsignedInteger + (self sizeof: CogBlockMethod)
						inMethod: homeMethod.
			 self assert: map ~= 0.
			 self assert: ((coInterpreter byteAt: map) >> AnnotationShift = HasBytecodePC "fiducial"
						 or: [(coInterpreter byteAt: map) >> AnnotationShift = IsDisplacementX2N]).
			 [(coInterpreter byteAt: map) >> AnnotationShift ~= HasBytecodePC] whileTrue:
				[map := map - 1].
			 map := map - 1. "skip fiducial; i.e. the map entry for the pc immediately following the method header."
			 aMethodObj := homeMethod methodObject.
			 bcpc := startbcpc - BlockCreationBytecodeSize.
			 byte := objectMemory fetchByte: bcpc ofObject: aMethodObj.
			 descriptor := self generatorAt: byte.
			 endbcpc := self nextBytecodePCFor: descriptor at: bcpc byte0: byte in: aMethodObj].
	bcpc := startbcpc.
	mcpc := cogMethod asUnsignedInteger + cogMethod stackCheckOffset.
	"The stack check maps to the start of the first bytecode,
	 the first bytecode being effectively after frame build."
	result := self perform: functionSymbol
					with: (self cCoerceSimple: mcpc to: #'char *')
					with: startbcpc
					with: arg.
	result ~= 0 ifTrue:
		[^result].
	"Now skip up through the bytecode pc map entry for the stack check." 
	[(coInterpreter byteAt: map) >> AnnotationShift ~= HasBytecodePC] whileTrue:
		[map := map - 1].
	map := map - 1.
	[(mapByte := objectMemory byteAt: map) ~= MapEnd] whileTrue: "defensive; we exit on bcpc"
		[mapByte >= FirstAnnotation
			ifTrue:
				[| annotation nextBcpc |
				annotation := mapByte >> AnnotationShift.
				mcpc := mcpc + (mapByte bitAnd: DisplacementMask).
				(self isPCMappedAnnotation: annotation) ifTrue:
					[[byte := objectMemory fetchByte: bcpc ofObject: aMethodObj.
					  descriptor := self generatorAt: byte.
					  isInBlock
						ifTrue: [bcpc >= endbcpc ifTrue: [^0]]
						ifFalse:
							[(descriptor isReturn and: [bcpc > latestContinuation]) ifTrue: [^0].
							 (descriptor isBranch or: [descriptor isBlockCreation]) ifTrue:
								[| targetPC |
								 targetPC := self latestContinuationPCFor: descriptor at: bcpc byte0: byte in: aMethodObj.
								 latestContinuation := latestContinuation max: targetPC]].
					  nextBcpc := self nextBytecodePCFor: descriptor at: bcpc byte0: byte in: aMethodObj.
					  descriptor isMapped
					  or: [isInBlock and: [descriptor isMappedInBlock]]] whileFalse:
						[bcpc := nextBcpc].
					"All subsequent bytecodes except backward branches map to the
					 following bytecode. Backward branches map to themselves other-
					 wise mapping could cause premature breaking out of loops." 
					result := self perform: functionSymbol
									with: (self cCoerceSimple: mcpc to: #'char *')
									with: (descriptor isBackwardBranch
											ifTrue: [bcpc]
											ifFalse: [bcpc + descriptor numBytes])
									with: arg.
					 result ~= 0 ifTrue:
						[^result].
					 bcpc := nextBcpc]]
			ifFalse:
				[mcpc := mcpc + (mapByte >= DisplacementX2N
									ifTrue: [mapByte - DisplacementX2N << AnnotationShift]
									ifFalse: [mapByte])].
		 map := map - 1].
	^0
]

{ #category : #'method map' }
Cogit >> mapFor: cogMethod do: aBlock [
	<doNotGenerate>
	self mapFor: cogMethod performUntil: #withAnnotation:pc:evaluate: arg: aBlock
]

{ #category : #'method map' }
Cogit >> mapFor: cogMethod performUntil: functionSymbol arg: arg [
	"Disassembly/GC support"
	<var: #cogMethod type: #'CogMethod *'>
	<var: #functionSymbol declareC: 'int (*functionSymbol)(sqInt annotation, char *mcpc, sqInt arg)'>
	| mcpc map mapByte result |
	mcpc := cogMethod asInteger + cmNoCheckEntryOffset.
	map := self mapStartFor: cogMethod.
	[(mapByte := coInterpreter byteAt: map) ~= MapEnd] whileTrue:
		[mapByte >= FirstAnnotation
			ifTrue:
				[mcpc := mcpc + (mapByte bitAnd: DisplacementMask).
				 result := self perform: functionSymbol
							   with: mapByte >> AnnotationShift
							   with: (self cCoerceSimple: mcpc to: #'char *')
							   with: arg.
				 result ~= 0 ifTrue:
					[^result]]
			ifFalse:
				[mcpc := mcpc + (mapByte >= DisplacementX2N
									ifTrue: [mapByte - DisplacementX2N << AnnotationShift]
									ifFalse: [mapByte])].
		 map := map - 1].
	^0
]

{ #category : #'garbage collection' }
Cogit >> mapObjectReferencesInClosedPIC: cPIC [
	"Remap all object references in the closed PIC.  Answer if any references are young.
	Set codeModified if any modifications are made."
	<var: #cPIC type: #'CogMethod *'>
	| pc refersToYoung |
	pc := cPIC asInteger + firstCPICCaseOffset.
	refersToYoung := self updateMaybeObjRefAt: pc - backEnd jumpLongByteSize.
	pc := pc + cPICCaseSize.
	2 to: cPIC cPICNumCases do:
		[:i|
		(self updateMaybeObjRefAt: pc - backEnd jumpLongConditionalByteSize - backEnd loadLiteralByteSize) ifTrue:
			[refersToYoung := true].
		(self updateMaybeObjRefAt: pc - backEnd jumpLongConditionalByteSize) ifTrue:
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
		 literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 mappedLiteral := objectMemory remap: literal.
		 mappedLiteral ~= literal ifTrue:
			[backEnd storeLiteral: mappedLiteral beforeFollowingAddress: mcpc.
			 codeModified := true]]
]

{ #category : #'jit - api' }
Cogit >> mapObjectReferencesInMachineCode: gcMode [
	<api>
	"Update all references to objects in machine code."
	gcMode caseOf: {
		[GCModeIncr]		-> [self mapObjectReferencesInMachineCodeForIncrementalGC].
		[GCModeFull]		-> [self mapObjectReferencesInMachineCodeForFullGC].
		[GCModeBecome]	-> [self mapObjectReferencesInMachineCodeForBecome] }
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
	hasYoungObjPtr := self cCode: [(self addressOf: hasYoungObj) asInteger]
							inSmalltalk: [CPluggableAccessor new
											setObject: nil;
											atBlock: [:obj :idx| hasYoungObj]
											atPutBlock: [:obj :idx :val| hasYoungObj := val]].
	codeModified := freedPIC := false.
	self mapObjectReferencesInGeneratedRuntime.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[self assert: hasYoungObj not.
		 cogMethod cmType ~= CMFree ifTrue:
			[self assert: (self cogMethodDoesntLookKosher: cogMethod) = 0.
			 cogMethod selector: (objectRepresentation remapOop: cogMethod selector)..
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
						[self assert: cogMethod objectHeader = objectMemory nullHeaderForMachineCodeMethod.
						 self assert: ((coInterpreter rawHeaderOf: cogMethod methodObject) = cogMethod asInteger
									or: [(self noAssertMethodClassAssociationOf: cogMethod methodObject)
											= objectMemory nilObject]).
						 (objectMemory isYoung: cogMethod methodObject) ifTrue:
							[hasYoungObj := true]].
					 self mapFor: cogMethod
						 performUntil: (self cppIf: NewspeakVM
											ifTrue: [#remapNSIfObjectRef:pc:hasYoung: asSymbol]
											ifFalse: [#remapIfObjectRef:pc:hasYoung: asSymbol])
						 arg: hasYoungObjPtr.
					 hasYoungObj
						ifTrue:
							[cogMethod cmRefersToYoung ifFalse:
								[cogMethod cmRefersToYoung: true.
								 methodZone addToYoungReferrers: cogMethod].
							hasYoungObj := false]
						ifFalse: [cogMethod cmRefersToYoung: false]]].
		cogMethod := methodZone methodAfter: cogMethod].
	methodZone pruneYoungReferrers.
	freedPIC ifTrue:
		[self unlinkSendsToFree.
		 codeModified := true].
	codeModified ifTrue: "After updating oops in inline caches we need to flush the icache."
		[processor flushICacheFrom: codeBase to: methodZone limitZony asInteger]
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
						 performUntil: (self cppIf: NewspeakVM
											ifTrue: [#remapNSIfObjectRef:pc:hasYoung: asSymbol]
											ifFalse: [#remapIfObjectRef:pc:hasYoung: asSymbol])
						 arg: 0.
					 (cogMethod cmRefersToYoung
					  and: [objectRepresentation allYoungObjectsAgeInFullGC]) ifTrue:
						[cogMethod cmRefersToYoung: false]]].
		cogMethod := methodZone methodAfter: cogMethod].
	methodZone pruneYoungReferrers.
	codeModified ifTrue: "After updating oops in inline caches we need to flush the icache."
		[processor flushICacheFrom: codeBase to: methodZone limitZony asInteger]
]

{ #category : #'garbage collection' }
Cogit >> mapObjectReferencesInMachineCodeForIncrementalGC [
	"Update all references to objects in machine code for an incremental gc.
	 Avoid scanning all code by using the youngReferrers list.  In an incremental
	 GC a method referring to young may no longer refer to young, but a method
	 not referring to young cannot and will not refer to young afterwards."
	| pointer cogMethod hasYoungObj hasYoungObjPtr |
	<var: #cogMethod type: #'CogMethod *'>
	hasYoungObj := false.
	hasYoungObjPtr := self cCode: [(self addressOf: hasYoungObj) asInteger]
							inSmalltalk: [CPluggableAccessor new
											setObject: nil;
											atBlock: [:obj :idx| hasYoungObj]
											atPutBlock: [:obj :idx :val| hasYoungObj := val]].
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
						 performUntil: (self cppIf: NewspeakVM
											ifTrue: [#remapNSIfObjectRef:pc:hasYoung: asSymbol]
											ifFalse: [#remapIfObjectRef:pc:hasYoung: asSymbol])
						 arg: hasYoungObjPtr.
					 hasYoungObj
						ifTrue: [hasYoungObj := false]
						ifFalse: [cogMethod cmRefersToYoung: false]]].
		 pointer := pointer + BytesPerWord].
	methodZone pruneYoungReferrers.
	codeModified ifTrue: "After updating oops in inline caches we need to flush the icache."
		[processor flushICacheFrom: methodZoneBase to: methodZone limitZony asInteger]
]

{ #category : #'simulation only' }
Cogit >> mapPrimitive: primitiveRoutine "<Symbol>" withIndexToUniqueAddress: primitiveIndex [ "<SmallInteger>"
	| uniqueAddress |
	<doNotGenerate>
	self assert: (primitiveRoutine isSymbol or: [primitiveRoutine isBlock]).
	uniqueAddress := -1 - methodZoneBase - (primitiveIndex * 4) - 16r1000 bitAnd: self addressSpaceMask.
	simulatedTrampolines
		at: uniqueAddress
		ifAbsentPut:
			[primitiveRoutine isSymbol
				ifTrue: [MessageSend receiver: coInterpreter selector: primitiveRoutine]
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

{ #category : #'jit - api' }
Cogit >> markAndTraceMachineCodeForIncrementalGC [
	"Free any methods that refer to unmarked objects, unlinking sends to freed methods."
	| pointer cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	objectMemory leakCheckIncrementalGC ifTrue:
		[self assert: self allMachineCodeObjectReferencesValid].
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
		 pointer := pointer + BytesPerWord].
	objectMemory leakCheckIncrementalGC ifTrue:
		[self assert: self allMachineCodeObjectReferencesValid].
	codeModified ifTrue: "After updating oops in inline caches we need to flush the icache."
		[processor flushICacheFrom: methodZoneBase to: methodZone limitZony asInteger]
]

{ #category : #'jit - api' }
Cogit >> markAndTraceObjectReferencesInGeneratedRuntime [
	"Mark and trace any object references in the generated run-time."
	0 to: runtimeObjectRefIndex - 1 do:
		[:i| | mcpc literal |
		 mcpc := objectReferencesInRuntime at: i.
		 literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 objectRepresentation markAndTraceLiteral: literal]
]

{ #category : #'jit - api' }
Cogit >> markAndTraceObjectReferencesInMachineCode [
	"Mark and trace any object references in the generated run-time."
	0 to: runtimeObjectRefIndex - 1 do:
		[:i| | mcpc literal |
		 mcpc := objectReferencesInRuntime at: i.
		 literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 objectRepresentation markAndTraceLiteral: literal]
]

{ #category : #'jit - api' }
Cogit >> markAndTraceObjectsOrFreeMachineCode: inFullGC [
	<api>
	inFullGC
		ifTrue: [self markAndTraceOrFreeMachineCodeForFullGC]
		ifFalse: [self markAndTraceMachineCodeForIncrementalGC]
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
		[self assert: self allMachineCodeObjectReferencesValid].
	codeModified := false.
	self markAndTraceObjectReferencesInGeneratedRuntime.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[self markAndTraceOrFreeCogMethod: cogMethod firstVisit: true.
		 cogMethod := methodZone methodAfter: cogMethod].
	objectMemory leakCheckFullGC ifTrue:
		[self assert: self allMachineCodeObjectReferencesValid].
	codeModified ifTrue: "After updating oops in inline caches we need to flush the icache."
		[processor flushICacheFrom: methodZoneBase to: methodZone limitZony asInteger]
]

{ #category : #'garbage collection' }
Cogit >> markLiteralsAndUnlinkIfUnmarkedSend: annotation pc: mcpc method: cogMethod [
	"Mark and trace literals.  Unlink sends that have unmarked cache tags or targets."
	<var: #mcpc type: #'char *'>
	| literal cacheTag cacheTagMarked entryPoint targetMethod offset sendTable unlinkedRoutine |
	<var: #targetMethod type: #'CogMethod *'>
	<var: #sendTable type: #'sqInt *'>
	annotation = IsObjectReference ifTrue:
		[literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 objectRepresentation markAndTraceLiteral: literal].
	(self isSendAnnotation: annotation) ifTrue:
		[cacheTag := backEnd inlineCacheTagAt: mcpc asInteger.
		 cacheTagMarked := objectRepresentation cacheTagIsMarked: cacheTag.
		 objectRepresentation markAndTraceLiteral: cacheTag.
		 entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase ifTrue: "It's a linked send."
			[self
				offsetAndSendTableFor: entryPoint
				annotation: annotation
				into: [:off :table| offset := off. sendTable := table].
			targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
			(cacheTagMarked not
			 or: [self markAndTraceOrFreeCogMethod: targetMethod firstVisit: targetMethod asUnsignedInteger > mcpc asUnsignedInteger]) ifTrue:
				["Either the cacheTag is unmarked (e.g. new class) or the target
				  has been freed (because it is unmarked) so unlink the send."
				 unlinkedRoutine := sendTable at: (targetMethod cmNumArgs min: NumSendTrampolines - 1).
				 backEnd
					rewriteInlineCacheAt: mcpc asInteger
					tag: targetMethod selector
					target: unlinkedRoutine.
				 codeModified := true.
				 objectRepresentation markAndTraceLiteral: targetMethod selector]]].
	^0 "keep scanning"
]

{ #category : #'garbage collection' }
Cogit >> markLiteralsAndUnlinkIfUnmarkedSendOrPushImplicit: annotation pc: mcpc method: cogMethod [
	<option: #NewspeakVM>
	"Mark and trace literals.  Unlink sends that have unmarked cache tags or targets."
	<var: #mcpc type: #'char *'>
	| literal cacheTag cacheTagMarked entryPoint targetMethod offset sendTable unlinkedRoutine |
	<var: #targetMethod type: #'CogMethod *'>
	<var: #sendTable type: #'sqInt *'>
	annotation = IsObjectReference ifTrue:
		[literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 objectRepresentation markAndTraceLiteral: literal].
	(self isSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 cacheTag := backEnd inlineCacheTagAt: mcpc asInteger.
		 cacheTagMarked := objectRepresentation cacheTagIsMarked: cacheTag.
		 objectRepresentation markAndTraceLiteral: cacheTag.
		 entryPoint = ceImplicitReceiverTrampoline
			ifTrue:
				[| classpc mixinpc class mixin |
				 self assert: cacheTagMarked.  "cacheTag is selector"
				 classpc := mcpc asInteger + backEnd jumpShortByteSize.
				 mixinpc := mcpc asInteger + backEnd jumpShortByteSize + BytesPerOop.
				 class := backEnd unalignedLongAt: classpc.
				 class ~= 0
					ifTrue:
						[self assert: (objectMemory addressCouldBeObj: class).
						 (objectRepresentation cacheTagIsMarked: class)
							ifTrue:
								[(mixin := backEnd unalignedLongAt: mixinpc) ~= 0 ifTrue:
									[objectRepresentation markAndTraceLiteral: mixin]]
							ifFalse:
								[backEnd
									unalignedLongAt: classpc put: 0;
									unalignedLongAt: mixinpc put: 0.
								 codeModified := true]]
					ifFalse:
						[self assert: (backEnd unalignedLongAt: mixinpc) = 0]]
			ifFalse:
				[entryPoint > methodZoneBase ifTrue: "It's a linked send."
					[self
						offsetAndSendTableFor: entryPoint
						annotation: annotation
						into: [:off :table| offset := off. sendTable := table].
					targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
					(cacheTagMarked not
					 or: [self markAndTraceOrFreeCogMethod: targetMethod firstVisit: targetMethod asUnsignedInteger > mcpc asUnsignedInteger]) ifTrue:
						["Either the cacheTag is unmarked (e.g. new class) or the target
						  has been freed (because it is unmarked) so unlink the send."
						 unlinkedRoutine := sendTable at: (targetMethod cmNumArgs min: NumSendTrampolines - 1).
						 backEnd
							rewriteInlineCacheAt: mcpc asInteger
							tag: targetMethod selector
							target: unlinkedRoutine.
						 codeModified := true.
						 objectRepresentation markAndTraceLiteral: targetMethod selector]]]].
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
	objectRepresentation markAndTraceLiteral: cogMethod selector.
	self mapFor: cogMethod
		 performUntil: (self cppIf: NewspeakVM
						ifTrue: [#markLiteralsAndUnlinkIfUnmarkedSendOrPushImplicit:pc:method: asSymbol]
						ifFalse: [#markLiteralsAndUnlinkIfUnmarkedSend:pc:method: asSymbol])
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
		performUntil: #incrementUsageOfTargetIfLinkedSend:mcpc:ignored: asSymbol
		arg: 0
]

{ #category : #'garbage collection' }
Cogit >> markNSYoungObjects: annotation pc: mcpc method: cogMethod [
	<option: #NewspeakVM>
	"Mark and trace young literals."
	<var: #mcpc type: #'char *'>
	| literal cacheTag entryPoint |
	annotation = IsObjectReference ifTrue:
		[literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 objectRepresentation markAndTraceLiteralIfYoung: literal].
	(self isSendAnnotation: annotation) ifTrue:
		[cacheTag := backEnd inlineCacheTagAt: mcpc asInteger.
		 objectRepresentation markAndTraceLiteralIfYoung: cacheTag.
		 entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint = ceImplicitReceiverTrampoline ifTrue:
			[| class mixin |
			 (class := backEnd unalignedLongAt: mcpc asInteger + backEnd jumpShortByteSize) ~= 0 ifTrue:
				[objectRepresentation markAndTraceLiteralIfYoung: class.
				 mixin := backEnd unalignedLongAt: mcpc asInteger + backEnd jumpShortByteSize + BytesPerOop.
				 objectRepresentation markAndTraceLiteralIfYoung: mixin]]].
	^0 "keep scanning"
]

{ #category : #'garbage collection' }
Cogit >> markYoungObjects: annotation pc: mcpc method: cogMethod [
	"Mark and trace young literals."
	<var: #mcpc type: #'char *'>
	| literal cacheTag |
	annotation = IsObjectReference ifTrue:
		[literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 objectRepresentation markAndTraceLiteralIfYoung: literal].
	(self isSendAnnotation: annotation) ifTrue:
		[cacheTag := backEnd inlineCacheTagAt: mcpc asInteger.
		 objectRepresentation markAndTraceLiteralIfYoung: cacheTag].
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
		 performUntil: (self cppIf: NewspeakVM
						ifTrue: [#markNSYoungObjects:pc:method: asSymbol]
						ifFalse: [#markYoungObjects:pc:method: asSymbol])
		 arg: cogMethod asInteger
]

{ #category : #debugging }
Cogit >> maxCogMethodAddress [
	<api>
	<returnTypeC: #usqInt>
	^methodZone limitZony asUnsignedInteger
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

{ #category : #initialization }
Cogit >> maybeGenerateCheckFeatures [
	| startAddress |
	<inline: false>
	backEnd numCheckFeaturesOpcodes = 0 ifTrue:
		[^nil].
	self allocateOpcodes: backEnd numCheckFeaturesOpcodes bytecodes: 0.
	initialPC := 0.
	endPC := numAbstractOpcodes - 1.
	startAddress := methodZoneBase.
	backEnd generateCheckFeatures.
	self outputInstructionsForGeneratedRuntimeAt: startAddress.
	self recordGeneratedRunTime: 'ceCheckFeaturesFunction' address: startAddress.
	ceCheckFeaturesFunction := self cCoerceSimple: startAddress to: #'unsigned long (*)(void)'
]

{ #category : #initialization }
Cogit >> maybeGenerateICacheFlush [
	| startAddress |
	<inline: false>
	backEnd numICacheFlushOpcodes = 0 ifTrue:
		[^nil].
	self allocateOpcodes: backEnd numICacheFlushOpcodes bytecodes: 0.
	initialPC := 0.
	endPC := numAbstractOpcodes - 1.
	startAddress := methodZoneBase.
	backEnd generateICacheFlush.
	self outputInstructionsForGeneratedRuntimeAt: startAddress.
	self recordGeneratedRunTime: 'ceFlushICache' address: startAddress.
	ceFlushICache := self cCoerceSimple: startAddress to: #'void (*)(unsigned long,unsigned long)'
]

{ #category : #'method map' }
Cogit >> mcPCFor: bcpc startBcpc: startbcpc in: cogMethod [
	"Answer the absolute machine code pc matching the zero-relative bytecode pc argument
	 in cogMethod, given the start of the bytecodes for cogMethod's block or method object."
	<api>
	<var: #cogMethod type: #'CogBlockMethod *'>
	| absPC |
	absPC := self
				mapFor: cogMethod
				bcpc: startbcpc
				performUntil: #findMcpc:Bcpc:MatchingBcpc: asSymbol
				arg: (self cCoerceSimple: bcpc to: #'void *').
	^absPC ~= 0
		ifTrue: [absPC asUnsignedInteger - cogMethod asUnsignedInteger]
		ifFalse: [absPC]
]

{ #category : #'simulation only' }
Cogit >> methodZone [
	<doNotGenerate>
	^methodZone
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

{ #category : #'in-line cacheing' }
Cogit >> mnuOffset [
	<api>
	^missOffset
]

{ #category : #'compile abstract instructions' }
Cogit >> needsFrameIfInBlock: isInBlock [
	^inBlock
]

{ #category : #'compile abstract instructions' }
Cogit >> needsFrameNever: isInBlock [
	^false
]

{ #category : #'compile abstract instructions' }
Cogit >> nextBytecodePCFor: descriptor at: pc byte0: opcodeByte in: aMethodObj [
	"Compute the distance to the logically subsequent bytecode, i.e. skip over blocks."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	<inline: true>
	^pc
		+ descriptor numBytes
		+ (descriptor isBlockCreation
			ifTrue: [self spanFor: descriptor at: pc byte0: opcodeByte in: aMethodObj]
			ifFalse: [0])
]

{ #category : #debugging }
Cogit >> noAssertMethodClassAssociationOf: methodPointer [
	^coInterpreter
		literal: (coInterpreter literalCountOfHeader: (coInterpreter noAssertHeaderOf: methodPointer)) - 1
		ofMethod: methodPointer
]

{ #category : #accessing }
Cogit >> noCheckEntryOffset [
	<api>
	<cmacro: '() cmNoCheckEntryOffset'>
	^cmNoCheckEntryOffset
]

{ #category : #compaction }
Cogit >> noCogMethodsMaximallyMarked [
	"Check that no metod is maximally marked.  A maximal mark is an indication the
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
	"Answerr if all targets in the PIC are in-use methods."
	<var: #cPIC type: #'CogMethod *'>
	| pc entryPoint targetMethod |
	<var: #targetMethod type: #'CogMethod *'>
	pc := cPIC asInteger + firstCPICCaseOffset.
	1 to: cPIC cPICNumCases do:
		[:i|
		entryPoint := backEnd jumpLongTargetBeforeFollowingAddress: pc.
		"Find target from jump.  Ignore jumps to the interpret and MNU calls within this PIC"
		(entryPoint < cPIC asInteger
		 or: [entryPoint > (cPIC asInteger + cPIC blockSize)]) ifTrue:
			[targetMethod := self cCoerceSimple: entryPoint - cmNoCheckEntryOffset to: #'CogMethod *'.
			 targetMethod cmType ~= CMMethod ifTrue:
				[^false]].
		i < cPIC cPICNumCases ifTrue:
			[pc := pc + cPICCaseSize]].
	^true
]

{ #category : #'translation support' }
Cogit >> notYetImplemented [
	<cmacro: '() warning("not yet implemented")'>
	super notYetImplemented
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
	 alignment of entryPoint.  N.B.  For Newspeak sends we don't need to distinguish
	 between ceImplicitReceiver and the other sends since ceImplicitReceiver will
	 never appear to be linked, so only three cases here."
	<inline: true>
	self cppIf: NewspeakVM
		ifTrue:
			[(entryPoint bitAnd: entryPointMask) = checkedEntryAlignment
				ifTrue:
					[self assert: annotation = IsSendCall.
					 binaryBlock
							value: cmEntryOffset
							value: sendTrampolines]
				ifFalse:
					[(entryPoint bitAnd: entryPointMask) = dynSuperEntryAlignment
						ifTrue:
							[self assert: annotation = IsNSSendCall.
							 binaryBlock
								value: cmDynSuperEntryOffset
								value: dynamicSuperSendTrampolines]
						ifFalse:
							[self assert: annotation = IsSendCall.
							 binaryBlock
								value: cmNoCheckEntryOffset
								value: superSendTrampolines]]]
		ifFalse:
			[(entryPoint bitAnd: entryPointMask) = checkedEntryAlignment
				ifTrue: [binaryBlock value: cmEntryOffset value: sendTrampolines]
				ifFalse: [binaryBlock value: cmNoCheckEntryOffset value: superSendTrampolines]]
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
		0 to: abstractInstruction machineCodeSize - 1 do:
			[:j|
			objectMemory byteAt: absoluteAddress put: (abstractInstruction machineCode at: j).
			absoluteAddress := absoluteAddress + 1]].
	^absoluteAddress
]

{ #category : #initialization }
Cogit >> outputInstructionsForGeneratedRuntimeAt: startAddress [
	"Output instructions generated for one of the generated run-time routines, a trampoline, etc"
	| size endAddress |
	<inline: false>
	self computeMaximumSizes.
	size := self generateInstructionsAt: startAddress.
	endAddress := self outputInstructionsAt: startAddress.
	self assert: startAddress + size = endAddress.
	methodZoneBase := self alignUptoRoutineBoundary: endAddress.
	backEnd nopsFrom: endAddress to: methodZoneBase - 1.
	self cCode: '' inSmalltalk: [methodZone zoneLimit: methodZoneBase].
	^startAddress
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
	oPIC isNil ifTrue:
		["otherwise attempt to create an Open PIC."
		oPIC := self cogOpenPICSelector: selector numArgs: numArgs.
		(oPIC asInteger between: MaxNegativeErrorCode and: -1) ifTrue:
			["For some reason the PIC couldn't be generated, most likely a lack of code memory."
			oPIC asInteger = InsufficientCodeSpace ifTrue:
				[coInterpreter callForCogCompiledCodeCompaction].
			^false]].
	extent := backEnd
				rewriteInlineCacheAt: outerReturn
				tag: selector
				target: oPIC asInteger + cmEntryOffset.
	processor
		flushICacheFrom: outerReturn - 1 - extent to: outerReturn - 1;
		flushICacheFrom: oPIC asInteger to: oPIC asInteger + openPICSize.
	"Jump into the oPIC at its entry"
	coInterpreter executeCogMethodFromLinkedSend: oPIC withReceiver: receiver.
	"NOTREACHED"
	^true
]

{ #category : #disassembly }
Cogit >> pc: address isWithinMethod: cogMethod [
	<api>
	<var: #address type: #'char *'>
	<var: #cogMethod type: #'CogMethod *'>
	^address asInteger
		between: cogMethod asInteger + (self sizeof: CogMethod)
		and: cogMethod asInteger + cogMethod blockSize
]

{ #category : #'compile abstract instructions' }
Cogit >> primitiveGeneratorOrNil [
	"If there is a generator for the current primitive then answer it;
	 otherwise answer nil."
	<returnTypeC: #'PrimitiveDescriptor *'>
	| primitiveDescriptor |
	<var: #primitiveDescriptor type: #'PrimitiveDescriptor *'>
	(coInterpreter isQuickPrimitiveIndex: primitiveIndex) ifTrue:
		[primitiveDescriptor := self addressOf: (primitiveGeneratorTable at: 0). "an unused one"
		 primitiveDescriptor primitiveGenerator: (coInterpreter quickPrimitiveGeneratorFor: primitiveIndex).
		 ^primitiveDescriptor].
	(primitiveIndex between: 1 and: MaxCompiledPrimitiveIndex) ifTrue:
		[^self addressOf: (primitiveGeneratorTable at: primitiveIndex)].
	^nil
]

{ #category : #printing }
Cogit >> print: aString [
	<cmacro: '(aString) printf(aString)'>
	coInterpreter transcript print: aString
]

{ #category : #printing }
Cogit >> printCogMethodFor: address [
	<api>
	<var: #address type: #'void *'>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := methodZone methodFor: address.
	cogMethod = 0
		ifTrue: [coInterpreter print: 'not a method'; cr]
		ifFalse: [coInterpreter printCogMethod: cogMethod]
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
	[:aStream :codeRanges :cogMethod|
	self startMcpcAndCogMethodForMcpc: mcpc in: cogMethod do:
		[:startmcpc :subMethod| | name codeRange |
		"Find the start of the block by searching the code ranges."
		codeRange := codeRanges detect: [:range| range includes: mcpc].
		codeRange first = mcpc ifTrue:
			[aStream nextPutAll: 'startpc: '; print: codeRange startpc; cr].
		aStream
			next: 2 put: Character space;
			nextPutAll: mcpc hex;  space;
			nextPutAll: (name := self class annotationConstantNames at: annotation + 1);
			next: 20 - name size put: Character space;
			nextPut: $(;
			nextPutAll: (self findMapLocationForMcpc: mcpc inMethod: cogMethod) hex.
		(self isPCMappedAnnotation: annotation) ifTrue:
			[aStream
				nextPutAll: ', bc: ';
				print: (self bytecodePCFor: mcpc startBcpc: codeRange startpc in: subMethod)].
		aStream
			nextPut: $);
			cr; flush]]
		valueWithArguments: tupleOfStreamCodeRangesAndMethod.
	^0
]

{ #category : #'method map' }
Cogit >> printMcpc: mcpc Bcpc: bcpc on: aStream [
	<doNotGenerate>
	aStream ensureCr.
	mcpc printOn: aStream base: 16.
	aStream space; tab; print: bcpc; cr; flush.
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
	aStream crtab.
	cogMethod cmType = CMMethod
		ifTrue:
			[aStream nextPutAll: 'objhdr: '.
			cogMethod objectHeader printOn: aStream base: 16]
		ifFalse:
			[aStream nextPutAll: 'homemth: '.
			cogMethod cmHomeMethod asUnsignedInteger printOn: aStream base: 16.
			aStream crtab; nextPutAll: 'startpc: '; print: cogMethod startpc].
	aStream
		crtab; nextPutAll: 'nArgs: ';	print: cogMethod cmNumArgs;
		tab;    nextPutAll: 'type: ';	print: cogMethod cmType.
	(cogMethod cmType ~= 0 and: [cogMethod cmType ~= CMBlock]) ifTrue:
		[aStream crtab; nextPutAll: 'blksiz: '.
		cogMethod blockSize printOn: aStream base: 16.
		aStream crtab; nextPutAll: 'method: '.
		cogMethod methodObject printOn: aStream base: 16.
		aStream crtab; nextPutAll: 'mthhdr: '.
		cogMethod methodHeader printOn: aStream base: 16.
		aStream crtab; nextPutAll: 'selctr: '.
		cogMethod selector printOn: aStream base: 16.
		(coInterpreter lookupAddress: cogMethod selector) ifNotNil:
			[:string| aStream nextPut: $=; nextPutAll: string].
		aStream crtab; nextPutAll: 'blkentry: '.
		cogMethod blockEntryOffset printOn: aStream base: 16.
		cogMethod blockEntryOffset ~= 0 ifTrue:
			[aStream nextPutAll: ' => '.
			 cogMethod asInteger + cogMethod blockEntryOffset printOn: aStream base: 16]].
	cogMethod cmType = CMClosedPIC
		ifTrue:
			[aStream crtab; nextPutAll: 'cPICNumCases: '.
			 cogMethod cPICNumCases printOn: aStream base: 16.]
		ifFalse:
			[aStream crtab; nextPutAll: 'stackCheckOffset: '.
			 cogMethod stackCheckOffset printOn: aStream base: 16.
			 cogMethod stackCheckOffset > 0 ifTrue:
				[aStream nextPut: $/.
				 cogMethod asInteger + cogMethod stackCheckOffset printOn: aStream base: 16].
			cogMethod cmType ~= CMBlock ifTrue:
				[aStream
					crtab;
					nextPutAll: 'cmRefersToYoung: ';
					nextPutAll: (cogMethod cmRefersToYoung ifTrue: ['yes'] ifFalse: ['no'])].
			cogMethod cmType = CMMethod ifTrue:
				[([cogMethod numCounters] on: MessageNotUnderstood do: [:ex| nil]) ifNotNil:
					[:nc| aStream crtab; nextPutAll: 'numCounters: '; print: nc]]].
	aStream cr; flush
]

{ #category : #printing }
Cogit >> printNum: n [
	<cmacro: '(n) printf("%ld", (long) n)'>
	coInterpreter transcript printNum: n
]

{ #category : #debugging }
Cogit >> printOnTrace [
	<api>
	<cmacro: '() (traceLinkedSends & 1)'>
	^(traceLinkedSends bitAnd: 1) ~= 0
]

{ #category : #'method map' }
Cogit >> printPCMapPairsFor: cogMethod on: aStream [
	<doNotGenerate>
	(self subMethodsAsRangesFor: cogMethod)
		do: [:sm|
			self mapFor: sm cogMethod bcpc: sm startpc performUntil: #printMcpc:Bcpc:on: arg: aStream]
		separatedBy: [aStream tab; next: 2 put: $=; cr]
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
			print: (trampolineAddresses at: i);
			cr]
]

{ #category : #accessing }
Cogit >> processor [
	<doNotGenerate>
	^processor
]

{ #category : #initialization }
Cogit >> processorHasDivQuoRem: ignoredPrimIndex [ 
	^backEnd canDivQuoRem
]

{ #category : #initialization }
Cogit >> processorHasDoublePrecisionFloatingPointSupport: ignoredPrimIndex [ 
	^backEnd hasDoublePrecisionFloatingPointSupport
]

{ #category : #initialization }
Cogit >> processorHasMultiply: ignoredPrimIndex [ 
	^backEnd canMulRR
]

{ #category : #debugging }
Cogit >> recordBlockTrace [
	<api>
	<cmacro: '() (traceLinkedSends & 4)'>
	^(traceLinkedSends bitAnd: 4) ~= 0
]

{ #category : #debugging }
Cogit >> recordEventTrace [
	<api>
	<cmacro: '() (traceLinkedSends & 16)'>
	^(traceLinkedSends bitAnd: 16) ~= 0
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
			[lastNInstructions makeRoomAtLast]]
]

{ #category : #'simulation only' }
Cogit >> recordLastInstruction [
	<doNotGenerate>
	self recordInstruction: (processor
								disassembleNextInstructionIn: coInterpreter memory
								for: (EagerInstructionDecoration ifTrue: [self]))
]

{ #category : #debugging }
Cogit >> recordPrimTrace [
	<api>
	<cmacro: '() (traceLinkedSends & 8)'>
	^(traceLinkedSends bitAnd: 8) ~= 0
]

{ #category : #debugging }
Cogit >> recordPrimTraceFunc [
	"This one for C support code."
	<api>
	^self recordPrimTrace
]

{ #category : #'simulation only' }
Cogit >> recordRegisters [
	<doNotGenerate>
	self recordInstruction: processor integerRegisterState
	"self recordInstruction: processor registerState"
]

{ #category : #initialization }
Cogit >> recordRunTimeObjectReferences [
	| annotation |
	<var: #annotation type: #'InstructionAnnotation *'>
	0 to: annotationIndex - 1 do:
		[:i|
		annotation := self addressOf: (annotations at: i).
		annotation annotation = IsObjectReference ifTrue:
			[self assert: runtimeObjectRefIndex < NumObjRefsInRuntime.
			 self assert: hasYoungReferent not.
			 hasYoungReferent ifTrue:
				[self error: 'attempt to generate run-time routine containing young object reference.  Cannot initialize Cogit run-time.'].
			 objectReferencesInRuntime
				at: runtimeObjectRefIndex
				put: (annotation instruction address + annotation instruction machineCodeSize) asInteger.
			 runtimeObjectRefIndex := runtimeObjectRefIndex + 1]].
	annotationIndex := 0
]

{ #category : #debugging }
Cogit >> recordSendTrace [
	<api>
	<cmacro: '() (traceLinkedSends & 2)'>
	^(traceLinkedSends bitAnd: 2) ~= 0
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
	| delta |
	delta := cogMethod objectHeader signedIntFromLong.
	backEnd relocateCallBeforeReturnPC: cogMethod asInteger + missOffset by: delta negated.
	self mapFor: cogMethod
		performUntil: #relocateIfCallOrMethodReference:mcpc:delta: asSymbol
		arg: delta
]

{ #category : #compaction }
Cogit >> relocateCallsInClosedPIC: cPIC [
	<var: #cPIC type: #'CogMethod *'>
	| delta pc entryPoint targetMethod |
	<var: #targetMethod type: #'CogMethod *'>
	delta := cPIC objectHeader signedIntFromLong.
	self assert: (backEnd callTargetFromReturnAddress: cPIC asInteger + missOffset)
					= (self picAbortTrampolineFor: cPIC cmNumArgs).
	backEnd relocateCallBeforeReturnPC: cPIC asInteger + missOffset by: delta negated.

	pc := cPIC asInteger + firstCPICCaseOffset.
	1 to: cPIC cPICNumCases do:
		[:i|
		entryPoint := backEnd jumpLongTargetBeforeFollowingAddress: pc.
		"Find target from jump.  Ignore jumps to the interpret and MNU calls within this PIC"
		(entryPoint < cPIC asInteger
		 or: [entryPoint > (cPIC asInteger + cPIC blockSize)]) ifTrue:
			[targetMethod := self cCoerceSimple: entryPoint - cmNoCheckEntryOffset to: #'CogMethod *'.
			 self assert: targetMethod cmType = CMMethod.
			 backEnd
				relocateJumpBeforeFollowingAddress: pc
				by: (delta - targetMethod objectHeader signedIntFromLong) negated].
		pc := pc + cPICCaseSize].
	self assert: cPIC cPICNumCases > 0.
	pc := pc - cPICCaseSize.
	"Finally relocate the load of the PIC and the jump to the overflow routine ceCPICMiss:receiver:"
	backEnd relocateMethodReferenceBeforeAddress: pc + backEnd loadLiteralByteSize by: delta.
	backEnd relocateJumpBeforeFollowingAddress: pc + cPICEndSize by: delta negated
]

{ #category : #compaction }
Cogit >> relocateIfCallOrMethodReference: annotation mcpc: mcpc delta: delta [
	<var: #mcpc type: #'char *'>
	| entryPoint offset sendTable targetMethod unlinkedRoutine |
	<var: #sendTable type: #'sqInt *'>
	<var: #targetMethod type: #'CogMethod *'>
	(self isSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint <= methodZoneBase ifTrue: "send is not linked; just relocate"
			[backEnd relocateCallBeforeReturnPC: mcpc asInteger by: delta negated.
			 ^0].
		"It's a linked send; find which kind."
		self
			offsetAndSendTableFor: entryPoint
			annotation: annotation
			into: [:off :table| offset := off. sendTable := table].
		 targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
		 targetMethod cmType = CMMethod ifTrue: "send target not freed; just relocate."
			[backEnd
				relocateCallBeforeReturnPC: mcpc asInteger
				by: (delta - targetMethod objectHeader signedIntFromLong) negated.
			 ^0].
		"Target was freed; map back to an unlinked send; but include this method's reocation"
		 unlinkedRoutine := sendTable at: (targetMethod cmNumArgs min: NumSendTrampolines - 1).
		 unlinkedRoutine := unlinkedRoutine - delta.
		 backEnd
			rewriteInlineCacheAt: mcpc asInteger
			tag: targetMethod selector
			target: unlinkedRoutine.
		 ^0].
	annotation = IsRelativeCall ifTrue:
		[backEnd relocateCallBeforeReturnPC: mcpc asInteger by: delta negated.
		 ^0].
	annotation = IsAbsPCReference ifTrue:
		[backEnd relocateMethodReferenceBeforeAddress: mcpc asInteger by: delta].
	^0 "keep scanning"
]

{ #category : #compaction }
Cogit >> relocateMethodsPreCompaction [
	"All surviving methods have had the amount they are going to relocate by
	 stored in their objectHeader fields.  Relocate all relative calls so that after
	 the compaction of both the method containing each call and the call target
	 the calls invoke the same target."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType ~= CMFree ifTrue:
			[cogMethod cmType = CMClosedPIC
				ifTrue: [self relocateCallsInClosedPIC: cogMethod]
				ifFalse: [self relocateCallsAndSelfReferencesInMethod: cogMethod]].
		 cogMethod := methodZone methodAfter: cogMethod].
	methodZone relocateAndPruneYoungReferrers.
	^true
]

{ #category : #'garbage collection' }
Cogit >> remapIfObjectRef: annotation pc: mcpc hasYoung: hasYoungPtr [
	<var: #mcpc type: #'char *'>
	<var: #targetMethod type: #'CogMethod *'>
	annotation = IsObjectReference ifTrue:
		[| literal mappedLiteral |
		 literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 (objectRepresentation couldBeObject: literal) ifTrue:
			[mappedLiteral := objectMemory remap: literal.
			 literal ~= mappedLiteral ifTrue:
				[backEnd storeLiteral: mappedLiteral beforeFollowingAddress: mcpc asInteger.
				 codeModified := true].
			 (hasYoungPtr ~= 0
			  and: [objectMemory isYoung: mappedLiteral]) ifTrue:
				[(self cCoerceSimple: hasYoungPtr to: #'sqInt *') at: 0 put: true]]].
	(self isSendAnnotation: annotation) ifTrue:
		[| cacheTag mappedCacheTag |
		 cacheTag := backEnd inlineCacheTagAt: mcpc asInteger.
		 (objectRepresentation couldBeObject: cacheTag) ifTrue:
			[mappedCacheTag := objectMemory remap: cacheTag.
			 cacheTag ~= mappedCacheTag ifTrue:
				[backEnd rewriteInlineCacheTag: mappedCacheTag at: mcpc asInteger.
				 codeModified := true].
			 (hasYoungPtr ~= 0
			  and: [objectMemory isYoung: mappedCacheTag]) ifTrue:
				[(self cCoerceSimple: hasYoungPtr to: #'sqInt *') at: 0 put: true]].
		 hasYoungPtr ~= 0 ifTrue:
			[| entryPoint offset targetMethod |
			 "Since the unlinking routines may rewrite the cacheTag to the send's selector, and
			  since they don't have the cogMethod to hand and can't add it to youngReferrers,
			  the method must remain in youngReferrers if the targetMethod's selector is young."
			 entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
			 entryPoint > methodZoneBase ifTrue: "It's a linked send."
				[offset := (entryPoint bitAnd: entryPointMask) = checkedEntryAlignment
							ifTrue: [cmEntryOffset]
							ifFalse: [cmNoCheckEntryOffset].
				targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
				(objectMemory isYoung: targetMethod selector) ifTrue:
					[(self cCoerceSimple: hasYoungPtr to: #'sqInt *') at: 0 put: true]]]].
	^0 "keep scanning"
]

{ #category : #'garbage collection' }
Cogit >> remapNSIfObjectRef: annotation pc: mcpc hasYoung: hasYoungPtr [
	<option: #NewspeakVM>
	<var: #mcpc type: #'char *'>
	<var: #targetMethod type: #'CogMethod *'>
	annotation = IsObjectReference ifTrue:
		[| literal mappedLiteral |
		 literal := backEnd literalBeforeFollowingAddress: mcpc asInteger.
		 (objectRepresentation couldBeObject: literal) ifTrue:
			[mappedLiteral := objectMemory remap: literal.
			 literal ~= mappedLiteral ifTrue:
				[backEnd storeLiteral: mappedLiteral beforeFollowingAddress: mcpc asInteger.
				 codeModified := true].
			 (hasYoungPtr ~= 0
			  and: [objectMemory isYoung: mappedLiteral]) ifTrue:
				[(self cCoerceSimple: hasYoungPtr to: #'sqInt *') at: 0 put: true]]].
	(self isSendAnnotation: annotation) ifTrue:
		[| cacheTag mappedCacheTag entryPoint |
		 cacheTag := backEnd inlineCacheTagAt: mcpc asInteger.
		 (objectRepresentation couldBeObject: cacheTag) ifTrue:
			[mappedCacheTag := objectMemory remap: cacheTag.
			 cacheTag ~= mappedCacheTag ifTrue:
				[backEnd rewriteInlineCacheTag: mappedCacheTag at: mcpc asInteger.
				 codeModified := true].
			 (hasYoungPtr ~= 0
			  and: [objectMemory isYoung: mappedCacheTag]) ifTrue:
				[(self cCoerceSimple: hasYoungPtr to: #'sqInt *') at: 0 put: true]].
		 entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint = ceImplicitReceiverTrampoline ifTrue:
			[| pc oop mappedOop |
			 pc := mcpc asInteger + backEnd jumpShortByteSize.
			 (oop := backEnd unalignedLongAt: pc) ~= 0 ifTrue:
				[mappedOop := objectMemory remap: oop.
				 mappedOop ~= oop ifTrue:
					[backEnd unalignedLongAt: pc put: mappedOop].
				 (hasYoungPtr ~= 0
				  and: [objectMemory isYoung: mappedOop]) ifTrue:
					[(self cCoerceSimple: hasYoungPtr to: #'sqInt *') at: 0 put: true].
				 pc := mcpc asInteger + backEnd jumpShortByteSize + BytesPerOop.
				 (oop := backEnd unalignedLongAt: pc) ~= 0 ifTrue:
					[mappedOop := objectMemory remap: oop.
					 mappedOop ~= oop ifTrue:
						[backEnd unalignedLongAt: pc put: mappedOop].
				 (hasYoungPtr ~= 0
				  and: [objectMemory isYoung: mappedOop]) ifTrue:
					[(self cCoerceSimple: hasYoungPtr to: #'sqInt *') at: 0 put: true]]]].
		 hasYoungPtr ~= 0 ifTrue:
			[| offset targetMethod |
			 "Since the unlinking routines may rewrite the cacheTag to the send's selector, and
			  since they don't have the cogMethod to hand and can't add it to youngReferrers,
			  the method must remain in youngReferrers if the targetMethod's selector is young."
			 entryPoint > methodZoneBase ifTrue: "It's a linked send."
				[offset := (entryPoint bitAnd: entryPointMask) = checkedEntryAlignment
							ifTrue: [cmEntryOffset]
							ifFalse: [cmNoCheckEntryOffset].
				targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
				(objectMemory isYoung: targetMethod selector) ifTrue:
					[(self cCoerceSimple: hasYoungPtr to: #'sqInt *') at: 0 put: true]]]].
	^0 "keep scanning"
]

{ #category : #'translation support' }
Cogit >> reportError: anInteger [
	<cmacro: '(n) warning("compilation error")'>
	self halt: 'Compilation error ', anInteger printString
]

{ #category : #debugging }
Cogit >> reportLastNInstructions [
	<doNotGenerate>
	lastNInstructions do:
		[:thing|
		thing isArray
			ifTrue:
				[thing first isString "i.e. { '(simulated return to '. processor retpcIn: coInterpreter memory. ')'}"
					ifTrue:
						[thing do:
							[:stringOrNumber|
							coInterpreter transcript nextPutAll: (stringOrNumber isString
													ifTrue: [stringOrNumber]
													ifFalse: [stringOrNumber hex])].
							coInterpreter transcript cr]
					ifFalse:
						[coInterpreter transcript cr.
						 (self relativeLabelForPC: (thing at: processor registerStatePCIndex)) ifNotNil:
							[:label| coInterpreter transcript nextPutAll: label; nextPut: $:; cr].
						 processor printRegisterState: thing on: coInterpreter transcript]]
			ifFalse:
				[coInterpreter transcript
					nextPutAll: (EagerInstructionDecoration
									ifTrue: [thing]
									ifFalse: [processor
												decorateDisassembly: thing
												for: self]); cr]].
	coInterpreter transcript flush
]

{ #category : #'compile abstract instructions' }
Cogit >> scanBlock: blockStart [
	"Scan the block to determine if the block needs a frame or not"
	| descriptor pc end stackDelta |
	<var: #blockStart type: #'BlockStart *'>
	<var: #descriptor type: #'BytecodeDescriptor *'>
	needsFrame := false.
	methodOrBlockNumArgs := blockStart numArgs.
	pc := blockStart startpc.
	end := blockStart startpc + blockStart span.
	stackDelta := 0.
	[pc < end] whileTrue:
		[byte0 := objectMemory fetchByte: pc ofObject: methodObj.
		 descriptor := self generatorAt: byte0.
		 needsFrame ifFalse:
			[(descriptor needsFrameFunction isNil
			  or: [self perform: descriptor needsFrameFunction with: true])
				ifTrue: [needsFrame := true]
				ifFalse: [stackDelta := stackDelta + descriptor stackDelta]].
		 pc := self nextBytecodePCFor: descriptor at: pc byte0: byte0 in: methodObj].
	needsFrame ifFalse:
		[stackDelta < 0 ifTrue:
			[self error: 'negative stack delta in block; block contains bogus code or internal error'].
		 [stackDelta > 0] whileTrue:
			[descriptor := self generatorAt: (objectMemory fetchByte: blockStart startpc ofObject: methodObj).
			 descriptor generator ~~ #genPushConstantNilBytecode asSymbol ifTrue:
				[self error: 'frameless block doesn''t start with enough pushNils'].
			 blockStart
				startpc: blockStart startpc + descriptor numBytes;
				span: blockStart span - descriptor numBytes.
			 stackDelta := stackDelta - 1]]
]

{ #category : #'compile abstract instructions' }
Cogit >> scanMethod [
	"Scan the method to determine
		- what the last bytecode is; extra bytes at the end of a method are used to encode things like source pointers or temp names
		- if the method needs a frame or not
		- what are the targets of any backward branches.
		- how many blocks it creates
	 Answer the block count or on error a negative error code"
	| latestContinuation descriptor pc numBlocks distance targetPC |
	<var: #descriptor type: #'BytecodeDescriptor *'>
	needsFrame := false.
	(primitiveIndex > 0
	 and: [coInterpreter isQuickPrimitiveIndex: primitiveIndex]) ifTrue:
		[^0].
	numBlocks := 0.
	pc := latestContinuation := initialPC.
	[pc <= endPC] whileTrue:
		[byte0 := objectMemory fetchByte: pc ofObject: methodObj.
		descriptor := self generatorAt: byte0.
		(descriptor isReturn
		 and: [pc >= latestContinuation]) ifTrue:
			[endPC := pc].
		 (needsFrame not
		  and: [descriptor needsFrameFunction isNil
			  or: [self perform: descriptor needsFrameFunction with: false]]) ifTrue:
			[needsFrame := true].
		descriptor isBranch ifTrue:
			[distance := self spanFor: descriptor at: pc byte0: byte0 in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 descriptor isBackwardBranch
				ifTrue: [self initializeFixupAt: targetPC - initialPC]
				ifFalse: [latestContinuation := latestContinuation max: targetPC]].
		descriptor isBlockCreation ifTrue:
			[numBlocks := numBlocks + 1.
			 distance := self spanFor: descriptor at: pc byte0: byte0 in: methodObj.
			 targetPC := pc + descriptor numBytes + distance.
			 latestContinuation := latestContinuation max: targetPC].
		pc := pc + descriptor numBytes].
	^numBlocks
]

{ #category : #debugging }
Cogit >> sendTrace [
	<doNotGenerate>
	^traceLinkedSends
]

{ #category : #debugging }
Cogit >> sendTrace: aBooleanOrInteger [
	<doNotGenerate>
	"traceLinkedSends is a set of flags.
	 1 => print trace (if somethign below is selected)
	 2 => trace sends
	 4 => trace block activations
	 8 => trace interpreter primitives
	 16 => trace events (context switches, GCs, etc)
	 32 => send breakpoint on implicit receiver (Newspeak VM only)"
	traceLinkedSends := aBooleanOrInteger isInteger
							ifTrue: [aBooleanOrInteger]
							ifFalse: [aBooleanOrInteger ifTrue: [1] ifFalse: [0]]
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
	^objectMemory
		longAt: coInterpreter inMemoryCFramePointerAddress
		put: aFramePointer
]

{ #category : #accessing }
Cogit >> setCStackPointer: aStackPointer [
	<api>
	<cmacro: '(theSP) (CStackPointer = (void *)(theSP))'>
	"and in the simulator we use..."
	^objectMemory
		longAt: coInterpreter inMemoryCStackPointerAddress
		put: aStackPointer
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
	objectRepresentation := objectMemory objectRepresentationClass for: self.
	methodZone := CogMethodZone new.
	methodZone setInterpreter: aCoInterpreter
				objectRepresentation: objectRepresentation
				cogit: self.
	generatorTable := self class generatorTable.
	primitiveGeneratorTable := self class primitiveTable.
	processor := ProcessorClass new.
	simulatedAddresses := Dictionary new.
	simulatedTrampolines := Dictionary new.
	simulatedVariableGetters := Dictionary new.
	simulatedVariableSetters := Dictionary new.
	traceStores := 0.
	traceLinkedSends := 8. "record prim trace on by default (see Cogit class>>decareCVarsIn:)"
	debugPrimCallStackOffset := 0.
	singleStep := printRegisters := printInstructions := clickConfirm := false.
	breakBlock ifNil: [self breakPC: breakPC].
	(backEnd := processor abstractInstructionCompilerClass new) cogit: self.
	(methodLabel := processor abstractInstructionCompilerClass new) cogit: self.
	sendTrampolines := CArrayAccessor on: (Array new: NumSendTrampolines).
	superSendTrampolines := CArrayAccessor on: (Array new: NumSendTrampolines).
	NewspeakVM ifTrue:
		[dynamicSuperSendTrampolines := CArrayAccessor on: (Array new: NumSendTrampolines)].
	"debug metadata"
	objectReferencesInRuntime := CArrayAccessor on: (Array new: NumObjRefsInRuntime).
	runtimeObjectRefIndex := 0.
	"debug metadata"
	trampolineAddresses := CArrayAccessor on: (Array new: NumTrampolines * 2).
	trampolineTableIndex := 0.

	compilationTrace ifNil: [compilationTrace := 0]
]

{ #category : #'jit - api' }
Cogit >> setPostCompileHook: aFunction [
	<api>
	<var: #aFunction declareC: #'void (*aFunction)(CogMethod *, void *)'>
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
		point: (objectMemory lengthOf: aSelectorOop).
	self assert: cogMethod cmType = CMMethod.
	cogMethod selector: aSelectorOop.
	(cogMethod cmRefersToYoung not
	 and: [objectMemory isYoung: aSelectorOop]) ifTrue:
		[self assert: (methodZone occurrencesInYoungReferrers: cogMethod) = 0.
		 cogMethod cmRefersToYoung: true.
		 methodZone addToYoungReferrers: cogMethod]
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
		simulateLeafReturnIn: coInterpreter memory
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
	processor eip: address.
	[[[singleStep ifTrue:
		[[processor sp < stackZoneBase ifTrue: [self halt].
		  self recordRegisters.
		  printRegisters ifTrue:
			[processor printRegistersOn: coInterpreter transcript].
		  self recordLastInstruction.
		  printInstructions ifTrue:
			[coInterpreter transcript nextPutAll: lastNInstructions last; cr; flush].
		  (breakPC isInteger
			ifTrue:
				[processor pc = breakPC
				 and: [breakBlock value: self]]
			ifFalse:
				[breakBlock value: self]) ifTrue:
			["printRegisters := printInstructions := true"
			 "self reportLastNInstructions"
			 "coInterpreter printExternalHeadFrame"
			 "coInterpreter printFrameAndCallers: coInterpreter framePointer SP: coInterpreter stackPointer"
			 "coInterpreter shortPrintFrameAndCallers: coInterpreter framePointer"
			 "coInterpreter printFrame: processor fp WithSP: processor sp"
			 "coInterpreter printFrameAndCallers: processor fp SP: processor sp"
			 "coInterpreter shortPrintFrameAndCallers: processor fp"
			"self disassembleMethodFor: processor pc"
			 coInterpreter changed: #byteCountText.
			 self halt: 'machine code breakpoint at ',
						(breakPC isInteger
							ifTrue: [breakPC hex]
							ifFalse: [String streamContents: [:s| breakBlock decompile printOn: s indent: 0]])]] value]. "So that the Debugger's Over steps over all this"
	   singleStep
		ifTrue: [processor
					singleStepIn: coInterpreter memory
					minimumAddress: guardPageSize
					readOnlyBelow: coInterpreter cogCodeSize]
		ifFalse: [processor
					runInMemory: coInterpreter memory
					minimumAddress: guardPageSize
					readOnlyBelow: coInterpreter cogCodeSize].
	   ((printRegisters or: [printInstructions]) and: [clickConfirm]) ifTrue:
	 	[(self confirm: 'continue?') ifFalse:
			[self halt]].
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
	self assert: ((coInterpreter stackValue: n) between: guardPageSize and: methodZone zoneLimit - 1).
	(printInstructions or: [printRegisters]) ifTrue:
		[coInterpreter printExternalHeadFrame].
	processor
		smashRegistersWithValuesFrom: 16r80000000 by: BytesPerWord;
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

{ #category : #'simulation only' }
Cogit >> simulateLeafCallOf: someFunction [
	"Simulate execution of machine code that leaf-calls someFunction,
	 answering the result returned by someFunction."
	<doNotGenerate>
	| spOnEntry |
	self recordRegisters.
	processor
		simulateLeafCallOf: someFunction
		nextpc: 16rBADF00D5
		memory: coInterpreter memory.
	spOnEntry := processor sp.
	self recordInstruction: {'(simulated call of '. someFunction. ')'}.
	[[processor pc between: 0 and: coInterpreter cogCodeSize] whileTrue:
		[singleStep
			ifTrue: [self recordLastInstruction.
					self recordRegisters.
					processor
						singleStepIn: coInterpreter memory
						minimumAddress: guardPageSize
						readOnlyBelow: coInterpreter cogCodeSize]
			ifFalse: [processor
						runInMemory: coInterpreter memory
						minimumAddress: guardPageSize
						readOnlyBelow: coInterpreter cogCodeSize]]]
		on: ProcessorSimulationTrap
		do: [:ex| | retpc |
			"If the ip is out of bounds the return has already occurred."
			((processor pc between: 0 and: coInterpreter cogCodeSize)
			 and: [processor sp <= spOnEntry]) ifTrue:
				[retpc := processor leafRetpcIn: coInterpreter memory.
				 self assert: retpc = 16rBADF00D5.
				 self recordInstruction: {'(simulated return to '. retpc. ')'.
				 processor simulateLeafReturnIn: coInterpreter memory}.
				 self recordRegisters]].
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
	 into a Smalltalk message send or block evaluation."
	<doNotGenerate>
	^simulatedAddresses
		at: anObject
		ifAbsentPut: [(simulatedAddresses size + 101 * BytesPerWord) negated bitAnd: self addressSpaceMask]
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
			setter := (getter, ':') asSymbol.
			[:value| receiver perform: setter with: value]].
	^address
]

{ #category : #initialization }
Cogit >> simulatedTrampolineFor: selector [
	"Set a simulated trampoline.  This is a method in the cogit, coInterpreter
	 or objectMemory that is called from a machine code trampoline."
	<doNotGenerate>
	| address |
	address := self simulatedAddressFor: selector.
	simulatedTrampolines at: address ifAbsentPut: [selector].
	^address
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

{ #category : #'compile abstract instructions' }
Cogit >> spanFor: descriptor at: pc byte0: opcodeByte in: aMethodObj [
	"Compute the span (jump distance) for a particular bytecode, e.g. a backward branch or a block."
	<var: #descriptor type: #'BytecodeDescriptor *'>
	^descriptor numBytes caseOf:
		{ [1] -> [self
					perform: descriptor spanFunction
					with: opcodeByte].
		   [2] -> [self
					perform: descriptor spanFunction
					with: opcodeByte
					with: (objectMemory fetchByte: pc + 1 ofObject: aMethodObj)].
		   [3] -> [self
					perform: descriptor spanFunction
					with: opcodeByte
					with: (objectMemory fetchByte: pc + 1 ofObject: aMethodObj)
					with: (objectMemory fetchByte: pc + 2 ofObject: aMethodObj)].
		   [4] -> [self
					perform: descriptor spanFunction
					with: opcodeByte
					with: (objectMemory fetchByte: pc + 1 ofObject: aMethodObj)
					with: (objectMemory fetchByte: pc + 2 ofObject: aMethodObj)
					with: (objectMemory fetchByte: pc + 3 ofObject: aMethodObj)] }
]

{ #category : #'jit - api' }
Cogit >> stackPageHeadroomBytes [
	<api>
	"Delegate this to the processor..."
	^backEnd stackPageInterruptHeadroomBytes
]

{ #category : #disassembly }
Cogit >> startMcpcAndCogMethodForMcpc: mcpc in: cogMethod do: aBinaryBlock [
	"Evaluate aBinaryBlock with the startmcpc and method containing mcpc in cogMethod."
	<doNotGenerate>
	| startMcpc |
	startMcpc := ((self codeRangesFor: cogMethod)
					detect: [:range| range includes: mcpc]
					ifNone: [^nil]) first.
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

{ #category : #'tests-method map' }
Cogit >> testBcToMcPcMappingForMethod: cogMethod [
	<doNotGenerate>
	"self disassembleMethod: cogMethod"
	"self printPCMapPairsFor: cogMethod on: Transcript"
	| aMethodObj currentSubMethod subMethods |
	aMethodObj := cogMethod methodObject.
	subMethods := self subMethodsAsRangesFor: cogMethod.
	currentSubMethod := subMethods first.
	currentSubMethod endPC: (self endPCOf: aMethodObj).
	self bcpcsAndDescriptorsFor: aMethodObj do:
		[:bcpc :byte :desc| | subMethod |
		(desc notNil and: [desc isBlockCreation]) ifTrue:
			[subMethod := subMethods detect: [:sm| sm startpc = (bcpc + desc numBytes)].
			 subMethod endPC: bcpc + desc numBytes + (self spanFor: desc at: bcpc byte0: byte in: aMethodObj) - 1]].
	subMethods allButFirst do:
		[:blockSubMethod| | cogBlockMethod |
		cogBlockMethod := self
								findMethodForStartBcpc: blockSubMethod startpc
								inHomeMethod: cogMethod.
		self assert: cogBlockMethod address = (blockSubMethod first - (self sizeof: CogBlockMethod))].
	self bcpcsAndDescriptorsFor: aMethodObj do:
		[:bcpc :byte :desc| | relMcpc absMcpc mappedBcpc |
		currentSubMethod := self innermostSubMethodFor: bcpc in: subMethods startingAt: 1.
		(currentSubMethod cogMethod stackCheckOffset > 0
		 and: [desc isNil or: [desc isMapped]]) ifTrue:
			["The first bytecode and backward branch bytecodes are mapped to their pc.
			  Other bytecodes map to their following pc."
			mappedBcpc := (desc isNil or: [desc isBackwardBranch])
								ifTrue: [bcpc]
								ifFalse: [bcpc + desc numBytes].
			 relMcpc := self
							mcPCFor: mappedBcpc
							startBcpc: currentSubMethod startpc
							in: currentSubMethod cogMethod.
			 self assert: relMcpc ~= 0.
			 absMcpc := relMcpc + currentSubMethod cogMethod address.
			 self assert: (self
							bytecodePCFor: absMcpc
							startBcpc: currentSubMethod startpc
							in: currentSubMethod cogMethod) = mappedBcpc]]
]

{ #category : #'tests-method map' }
Cogit >> testMcToBcPcMappingForMethod: cogMethod [
	<doNotGenerate>
	| subMethods prevMcpc |
	"self disassembleMethod: cogMethod"
	"coInterpreter symbolicMethod: cogMethod methodObject"
	"coInterpreter printOop: cogMethod methodObject"
	"self printPCMapPairsFor: cogMethod on: Transcript"
	cogMethod stackCheckOffset = 0 ifTrue: "frameless"
		[^self].
	subMethods := self subMethodsAsRangesFor: cogMethod.
	self mapFor: cogMethod do:
		[:annotation :mcpc| | subMethod bcpc mappedpc |
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
							in: subMethod cogMethod.
				self assert: bcpc ~= 0.
				mappedpc := self mcPCFor: bcpc startBcpc: subMethod startpc in: subMethod cogMethod.
				self assert: mappedpc ~= 0.
				mappedpc := mappedpc + subMethod cogMethod address.
				"mcpc = mappedpc is obviously what we want and expect.  PrevMcpc = mappedpc hacks
				 around frame building accessors where the frst bytecode is mapped twice, once for the
				 stack check and once for the context inst var access.  The bytecode pc can only map
				 back to a single mcpc, the first, so the second map entry will fail with- out this hack."
				self assert: (mcpc = mappedpc or: [prevMcpc = mappedpc])].
			 prevMcpc := mcpc].
		 false "keep scanning"]
]

{ #category : #'tests-method map' }
Cogit >> testPCMappingForMethod: cm [
	<doNotGenerate>
	methodObj := nil.
	self
		testMcToBcPcMappingForMethod: cm;
		testBcToMcPcMappingForMethod: cm
]

{ #category : #debugging }
Cogit >> traceLinkedSendOffset [
	<api>
	^cmNoCheckEntryOffset + backEnd callInstructionByteSize
]

{ #category : #'method map' }
Cogit >> traceMap: annotation byte: byte at: address for: mcpc [
	<cmacro: '(ig,no,re,d) 0'>
	| s code |
	(compilationTrace anyMask: 16) ifTrue:
		[code := annotation isInteger ifTrue: [annotation] ifFalse: [annotation annotation].
		(s := coInterpreter transcript)
			ensureCr;
			print: code; nextPut: $/; nextPutAll: byte hex; space;
			nextPutAll: address hex; space; nextPutAll: mcpc hex; space;
			nextPutAll: (AnnotationConstantNames detect: [:name| (Cogit classPool at: name ifAbsent: []) = code]); cr; flush.
		(annotation isInteger not
		 and: [annotation instruction bcpc isInteger]) ifTrue:
			[s tab; print: annotation instruction bcpc; nextPut: $/.
			 annotation instruction bcpc printOn: s base: 16.
			 s space.
			 annotation instruction printStateOn: s.
			 s space.
			 (self generatorAt: (objectMemory fetchByte: annotation instruction bcpc ofObject: methodObj)) printStateOn: s.
			 s cr; flush]]
]

{ #category : #debugging }
Cogit >> traceStores: aBooleanOrInteger [
	<doNotGenerate>
	traceStores := aBooleanOrInteger isInteger
							ifTrue: [aBooleanOrInteger]
							ifFalse: [aBooleanOrInteger ifTrue: [1] ifFalse: [0]]
]

{ #category : #initialization }
Cogit >> trampolineName: routinePrefix numArgs: numArgs [
	"Malloc a string with the contents for the trampoline table"
	<returnTypeC: #'char *'>
	<var: #routinePrefix type: #'char *'>
	| theString |
	<var: #theString type: #'char *'>
	self cCode: '' inSmalltalk:
		[^routinePrefix, (numArgs >= 0 ifTrue: [numArgs printString] ifFalse: ['N']), 'Args'].
	theString := self malloc: (self strlen: routinePrefix) + 6.
	self s: theString pr: '%s%cArgs' in: routinePrefix tf: (numArgs >= 0 ifTrue: [$0 + numArgs] ifFalse: [$N]).
	^theString
]

{ #category : #'multi-threading' }
Cogit >> tryLockVMOwner [
	<api>
		"ceTryLockVMOwner does an atomic swap of the lock with 1 and
		 then subtracts 1from lock's value.  So if the result is 0 the lock was
		 already held.  Anything else (in fact -1) implies we hold the lock."
	<cmacro: '() (ceTryLockVMOwner() != 0)'>
	^(self simulateLeafCallOf: ceTryLockVMOwner) ~= 0
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
	methodZoneBase isNil ifTrue: [^self].
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod
			ifTrue:
				[self mapFor: cogMethod
					 performUntil: #unlinkIfLinkedSend:pc:ignored: asSymbol
					 arg: 0]
			ifFalse:
				[cogMethod cmType ~= CMFree ifTrue:
					[methodZone freeMethod: cogMethod]].
		cogMethod := methodZone methodAfter: cogMethod].
	"After updating inline caches we need to flush the icache."
	processor flushICacheFrom: methodZoneBase to: methodZone limitZony asInteger
]

{ #category : #'in-line cacheing' }
Cogit >> unlinkIfLinkedSend: annotation pc: mcpc ignored: superfluity [
	<var: #mcpc type: #'char *'>
	| entryPoint targetMethod offset sendTable unlinkedRoutine |
	<var: #targetMethod type: #'CogMethod *'>
	<var: #sendTable type: #'sqInt *'>
	(self isSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase ifTrue: "It's a linked send."
			[self
				offsetAndSendTableFor: entryPoint
				annotation: annotation
				into: [:off :table| offset := off. sendTable := table].
			targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
			unlinkedRoutine := sendTable at: (targetMethod cmNumArgs min: NumSendTrampolines - 1).
			backEnd
				rewriteInlineCacheAt: mcpc asInteger
				tag: targetMethod selector
				target: unlinkedRoutine]].
	^0 "keep scanning"
]

{ #category : #'in-line cacheing' }
Cogit >> unlinkIfLinkedSend: annotation pc: mcpc of: theSelector [
	<var: #mcpc type: #'char *'>
	| entryPoint targetMethod offset sendTable unlinkedRoutine |
	<var: #targetMethod type: #'CogMethod *'>
	<var: #sendTable type: #'sqInt *'>
	(self isSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 self cppIf: NewspeakVM ifTrue:
			[entryPoint = ceImplicitReceiverTrampoline ifTrue:
				[(backEnd inlineCacheTagAt: mcpc asInteger) = theSelector ifTrue:
				 	[backEnd
						unalignedLongAt: mcpc asInteger + backEnd jumpShortByteSize put: 0;
						unalignedLongAt: mcpc asInteger + backEnd jumpShortByteSize + BytesPerOop put: 0]]].
		 entryPoint > methodZoneBase ifTrue: "It's a linked send."
			[self
				offsetAndSendTableFor: entryPoint
				annotation: annotation
				into: [:off :table| offset := off. sendTable := table].
			targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
			targetMethod selector = theSelector ifTrue:
				[unlinkedRoutine := sendTable at: (targetMethod cmNumArgs min: NumSendTrampolines - 1).
				 backEnd
					rewriteInlineCacheAt: mcpc asInteger
					tag: targetMethod selector
					target: unlinkedRoutine.
				 codeModified := true]]].
	^0 "keep scanning"
]

{ #category : #'in-line cacheing' }
Cogit >> unlinkIfLinkedSend: annotation pc: mcpc to: theCogMethod [
	<var: #mcpc type: #'char *'>
	| entryPoint targetMethod offset sendTable unlinkedRoutine |
	<var: #targetMethod type: #'CogMethod *'>
	<var: #sendTable type: #'sqInt *'>
	(self isSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase ifTrue: "It's a linked send."
			[self
				offsetAndSendTableFor: entryPoint
				annotation: annotation
				into: [:off :table| offset := off. sendTable := table].
			targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
			targetMethod asInteger = theCogMethod ifTrue:
				[unlinkedRoutine := sendTable at: (targetMethod cmNumArgs min: NumSendTrampolines - 1).
				 backEnd
					rewriteInlineCacheAt: mcpc asInteger
					tag: targetMethod selector
					target: unlinkedRoutine.
				 codeModified := true]]].
	^0 "keep scanning"
]

{ #category : #'in-line cacheing' }
Cogit >> unlinkIfLinkedSendToFree: annotation pc: mcpc ignored: superfluity [
	<var: #mcpc type: #'char *'>
	| entryPoint targetMethod offset sendTable unlinkedRoutine |
	<var: #targetMethod type: #'CogMethod *'>
	<var: #sendTable type: #'sqInt *'>
	(self isSendAnnotation: annotation) ifTrue:
		[entryPoint := backEnd callTargetFromReturnAddress: mcpc asInteger.
		 entryPoint > methodZoneBase ifTrue: "It's a linked send."
			[self
				offsetAndSendTableFor: entryPoint
				annotation: annotation
				into: [:off :table| offset := off. sendTable := table].
			targetMethod := self cCoerceSimple: entryPoint - offset to: #'CogMethod *'.
			targetMethod cmType = CMFree ifTrue:
				[unlinkedRoutine := sendTable at: (targetMethod cmNumArgs min: NumSendTrampolines - 1).
				 backEnd
					rewriteInlineCacheAt: mcpc asInteger
					tag: targetMethod selector
					target: unlinkedRoutine.
				 codeModified := true]]].
	^0 "keep scanning"
]

{ #category : #'jit - api' }
Cogit >> unlinkSendsOf: selector isMNUSelector: isMNUSelector [
	<api>
	"Unlink all sends in cog methods."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	methodZoneBase isNil ifTrue: [^self].
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	"First check if any method actually has the selector; if not there can't
	 be any linked send to it."
	[cogMethod < methodZone limitZony
	 and: [cogMethod selector ~= selector]] whileTrue:
		[cogMethod := methodZone methodAfter: cogMethod].
	cogMethod >= methodZone limitZony ifTrue:
		[^nil].
	codeModified := false.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod
			ifTrue:
				[self mapFor: cogMethod
					 performUntil: #unlinkIfLinkedSend:pc:of: asSymbol
					 arg: selector]
			ifFalse:
				[(cogMethod cmType ~= CMFree
				  and: [(isMNUSelector and: [cogMethod cpicHasMNUCase])
					or: [cogMethod selector = selector]]) ifTrue:
					[methodZone freeMethod: cogMethod]].
		cogMethod := methodZone methodAfter: cogMethod].
	codeModified ifTrue: "After possibly updating inline caches we need to flush the icache."
		[processor flushICacheFrom: methodZoneBase to: methodZone limitZony asInteger]
]

{ #category : #'jit - api' }
Cogit >> unlinkSendsTo: targetMethodObject andFreeIf: freeIfTrue [
	<api>
	"Unlink all sends in cog methods to a particular target method.
	 If targetMethodObject isn't actually a method (perhaps being
	 used via invokeAsMethod) then flush all sends since anything
	 could be affected."
	| cogMethod targetMethod freedPIC |
	<var: #cogMethod type: #'CogMethod *'>
	<var: #targetMethod type: #'CogMethod *'>
	((objectMemory isOopCompiledMethod: targetMethodObject)
	and: [coInterpreter methodHasCogMethod: targetMethodObject]) ifFalse:
		[^self].
	targetMethod := coInterpreter cogMethodOf: targetMethodObject.
	methodZoneBase isNil ifTrue: [^self].
	codeModified := freedPIC := false.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod
			ifTrue:
				[self mapFor: cogMethod
					 performUntil: #unlinkIfLinkedSend:pc:to: asSymbol
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
				[processor flushICacheFrom: methodZoneBase to: methodZone limitZony asInteger]]
]

{ #category : #'garbage collection' }
Cogit >> unlinkSendsToFree [
	<api>
	"Unlink all sends in cog methods to free methods and/or pics."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	methodZoneBase isNil ifTrue: [^self].
	codeModified := false.
	cogMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[cogMethod < methodZone limitZony] whileTrue:
		[cogMethod cmType = CMMethod
			ifTrue:
				[self mapFor: cogMethod
					 performUntil: #unlinkIfLinkedSendToFree:pc:ignored: asSymbol
					 arg: 0]
			ifFalse:
				[cogMethod cmType = CMClosedPIC ifTrue:
					[self assert: (self noTargetsFreeInClosedPIC: cogMethod)]].
		cogMethod := methodZone methodAfter: cogMethod].
	codeModified ifTrue: "After possibly updating inline caches we need to flush the icache."
		[processor flushICacheFrom: methodZoneBase to: methodZone limitZony asInteger]
]

{ #category : #'multi-threading' }
Cogit >> unlockVMOwner [
	<api>
	<cmacro: '() ceUnlockVMOwner()'>
	^self simulateLeafCallOf: ceUnlockVMOwner
]

{ #category : #'garbage collection' }
Cogit >> updateMaybeObjRefAt: mcpc [
	"Update a potential object reference form a closed PIC.
	 This may be an object reference, an inline cache tag or null.
	 Answer if the updated literal is young."
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

{ #category : #'jit - api' }
Cogit >> voidCogCompiledCode [
	<api>
	methodZone clearCogCompiledCode
]

{ #category : #'garbage collection' }
Cogit >> withAnnotation: annotation pc: mcpc evaluate: aBinaryBlock [
	<doNotGenerate>
	^(aBinaryBlock value: annotation value: mcpc) ifTrue: [1] ifFalse: [0]
]
