"Method-level multi-specialization for the Oil optimizing JIT (Milestone 7).
 A method may have up to OilMaxPICCases Oil versions, each specialized for one receiver class, besides its baseline
 machine code, which runs every other receiver: like a closed PIC of 6 cases whose last case is the generic code.
 - The Oil code of the specialization of method M for class C is the machine code of a copy of M (M_C), so that every
   CogMethod still has its own CompiledMethod (freeing, compaction, contexts and their machine code pcs are unchanged).
   The specialization table (oilSpecializations, a GC root) holds the entries (M, class tag of C, M_C, C).  They are dropped
   (and the Oil code of M_C freed) when M's machine code is voided in place (voidCogVMState, flushCache) or M is becomed.
 - M's baseline code dispatches on the receiver's class at its no-check entry (ProfilingCogit>>compileEntry), where linked
   sends (after the inline cache check), super sends and the interpreter (activateNewCogMethod:inInterpreter:) enter: a
   receiver of class C jumps to the no-check entry of M_C's Oil code, read through M_C's header (the CogMethod's address
   while M_C has machine code), so freeing or moving the Oil code needs no patching.
 - Monomorphic sends of receivers of class C are linked directly to M_C's Oil code (ProfilingCogit>>linkSendAt:...).
 - Copies reached only through the dispatch get the usage count of M at code compactions (compactCogCompiledCode).
 - primitiveOilSpecialize compiles a specialization, primitiveOilSpecializations answers them.
 Author: cb."!

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:00'!
getOilSpecializations
	<api>
	^oilSpecializations! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:00'!
setOilSpecializations: anArray
	<api>
	oilSpecializations := anArray! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:00'!
oilSpecializationsAddress
	"Answer the address of the oilSpecializations variable, for registering it as a GC root."
	<api>
	<returnTypeC: #'sqInt *'>
	^self addressOf: oilSpecializations put: [:value| oilSpecializations := value]! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:00'!
oilSpecializationAt: entryIndex field: fieldIndex
	"Field fieldIndex of entry entryIndex of the specialization table: OilSpecMethod the method, OilSpecClassTag the class tag
	 of the receivers (a SmallInteger), OilSpecCopy the copy of the method whose machine code is the specialized Oil code,
	 OilSpecClass the class (which keeps the tag from being reused).  Answer nil if there is no table."
	<api>
	| oop |
	(oilSpecializations = 0 or: [oilSpecializations = objectMemory nilObject]) ifTrue:
		[^objectMemory nilObject].
	oop := objectMemory fetchPointer: entryIndex * OilSpecializationSize + fieldIndex ofObject: oilSpecializations.
	((objectMemory isNonImmediate: oop) and: [objectMemory isForwarded: oop]) ifTrue:
		[oop := objectMemory followForwarded: oop].
	^oop! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:00'!
oilSpecializationOf: aMethodObj tag: classTag
	"Answer the index of the entry of the specialization table for aMethodObj and receivers of class tag classTag, or -1."
	<api>
	0 to: OilMaxSpecializations - 1 do:
		[:entryIndex|
		((self oilSpecializationAt: entryIndex field: OilSpecMethod) = aMethodObj
		 and: [(self oilSpecializationAt: entryIndex field: OilSpecClassTag) = (objectMemory integerObjectOf: classTag)]) ifTrue:
			[^entryIndex]].
	^-1! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:00'!
oilNumSpecializationsOf: aMethodObj
	"Answer the number of specializations of aMethodObj whose copy has Oil code."
	<api>
	| count |
	(oilSpecializations = 0 or: [oilSpecializations = objectMemory nilObject]) ifTrue:
		[^0].
	count := 0.
	0 to: OilMaxSpecializations - 1 do:
		[:entryIndex|
		(self oilIsLiveSpecialization: entryIndex of: aMethodObj) ifTrue:
			[count := count + 1]].
	^count! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:30'!
oilIsLiveSpecialization: entryIndex of: aMethodObj
	"Is entry entryIndex a specialization of aMethodObj whose copy has Oil code?  Also check that its class still has its
	 tag (a reshaped class is becomed into a class with another tag) and that the copy is still a copy of aMethodObj (the
	 table follows the forwarder of a method replaced by become:)."
	<api>
	| copy class |
	(self oilSpecializationAt: entryIndex field: OilSpecMethod) = aMethodObj ifFalse:
		[^false].
	copy := self oilSpecializationAt: entryIndex field: OilSpecCopy.
	class := self oilSpecializationAt: entryIndex field: OilSpecClass.
	^(self oilHasOilCode: copy)
	  and: [(objectMemory isNonImmediate: class)
	  and: [(objectMemory classTagForClass: class) = (objectMemory integerValueOf: (self oilSpecializationAt: entryIndex field: OilSpecClassTag))
	  and: [self oilCopy: copy isCopyOf: aMethodObj]]]! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 05:00'!
oilCopy: copy isCopyOf: aMethodObj
	"Has copy the header, literals and bytecodes of aMethodObj?  (Oil code sets the large context bit of its header.)"
	| numLiterals |
	((objectMemory numBytesOf: copy) = (objectMemory numBytesOf: aMethodObj)
	 and: [(coInterpreter oilHeaderWithoutLargeContext: (objectMemory methodHeaderOf: copy))
			= (coInterpreter oilHeaderWithoutLargeContext: (objectMemory methodHeaderOf: aMethodObj))]) ifFalse:
		[^false].
	numLiterals := objectMemory literalCountOf: aMethodObj.
	1 to: numLiterals do:
		[:i|
		(objectMemory fetchPointer: i ofObject: copy) = (objectMemory fetchPointer: i ofObject: aMethodObj) ifFalse:
			[^false]].
	numLiterals + 1 * objectMemory bytesPerOop to: (objectMemory numBytesOf: aMethodObj) - 1 do:
		[:i|
		(objectMemory fetchByte: i ofObject: copy) = (objectMemory fetchByte: i ofObject: aMethodObj) ifFalse:
			[^false]].
	^true! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:30'!
oilDropSpecializationsOf: aMethodObj freeing: freeCode
	"Forget the specializations of aMethodObj, whose machine code is voided (see unlinkSendsTo:andFreeIf:) or which is
	 becomed (see flagCogMethodForBecome:), and, if freeCode, free their Oil code (unless it has activations, like
	 unlinkSendsOf:isMNUSelector:), which unlinks the sends linked directly to it."
	| copy |
	(oilSpecializations = 0 or: [oilSpecializations = objectMemory nilObject]) ifTrue:
		[^self].
	0 to: OilMaxSpecializations - 1 do:
		[:entryIndex|
		(self oilSpecializationAt: entryIndex field: OilSpecMethod) = aMethodObj ifTrue:
			[copy := self oilSpecializationAt: entryIndex field: OilSpecCopy.
			 0 to: OilSpecializationSize - 1 do: [:fieldIndex| objectMemory storePointerUnchecked: entryIndex * OilSpecializationSize + fieldIndex ofObject: oilSpecializations withValue: objectMemory nilObject].
			 (freeCode
			  and: [(self oilHasOilCode: copy)
			  and: [(coInterpreter oilHasFramesOf: (coInterpreter cogMethodOf: copy)) not]]) ifTrue:
				[self unlinkSendsTo: copy andFreeIf: true]]]! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:30'!
unlinkSendsTo: targetMethodObject andFreeIf: freeIfTrue
	"The machine code of targetMethodObject is voided (e.g. it was modified in place): also drop its specializations,
	 unless primitiveOilSpecialize is freeing its baseline code to add one."
	<api>
	"(before super, which returns early if targetMethodObject has no machine code)"
	oilKeepSpecializations ifFalse:
		[self oilDropSpecializationsOf: targetMethodObject freeing: true].
	super unlinkSendsTo: targetMethodObject andFreeIf: freeIfTrue! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:30'!
oilFreeMachineCodeKeepingSpecializationsOf: aMethodObj
	"Free the machine code of aMethodObj (see CoInterpreter>>oilFreeMachineCodeOf:) without dropping its specializations."
	<api>
	oilKeepSpecializations := true.
	coInterpreter oilFreeMachineCodeOf: aMethodObj.
	oilKeepSpecializations := false! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:30'!
flagCogMethodForBecome: cogMethod
	"A becomed method's specializations are copies of the old method: forget them (their Oil code is not freed during the
	 become; it is only reachable from sends linked to it, which the usual selector flush unlinks)."
	<api>
	<var: 'cogMethod' type: #'CogMethod *'>
	super flagCogMethodForBecome: cogMethod.
	self oilDropSpecializationsOf: cogMethod methodObject freeing: false! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 05:30'!
compactCogCompiledCode
	"Cog increments the usage count of the targets of linked sends only: the copies reached through their method's
	 dispatch (from PICs, super sends, the interpreter) would be freed by the compaction.  Give them their method's count.
	 Free the Oil code of the copies of dead entries (see oilIsLiveSpecialization:of:), which only sends linked to it reach."
	<api>
	| method copy |
	(oilSpecializations ~= 0 and: [oilSpecializations ~= objectMemory nilObject]) ifTrue:
		[0 to: OilMaxSpecializations - 1 do:
			[:entryIndex|
			method := self oilSpecializationAt: entryIndex field: OilSpecMethod.
			copy := self oilSpecializationAt: entryIndex field: OilSpecCopy.
			(self oilHasOilCode: copy) ifTrue:
				[(self oilIsLiveSpecialization: entryIndex of: method)
					ifTrue:
						[(coInterpreter methodHasCogMethod: method) ifTrue:
							[self ensureWritableCodeZone.
							 (self writableMethodFor: (coInterpreter cogMethodOf: copy))
								cmUsageCount: ((coInterpreter cogMethodOf: copy) cmUsageCount max: (coInterpreter cogMethodOf: method) cmUsageCount)]]
					ifFalse:
						[(coInterpreter oilHasFramesOf: (coInterpreter cogMethodOf: copy)) ifFalse:
							[0 to: OilSpecializationSize - 1 do: [:fieldIndex| objectMemory storePointerUnchecked: entryIndex * OilSpecializationSize + fieldIndex ofObject: oilSpecializations withValue: objectMemory nilObject].
							 self unlinkSendsTo: copy andFreeIf: true]]]]].
	super compactCogCompiledCode! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:00'!
oilAddSpecialization: aMethodObj class: classObj copy: copyObj
	"Record a new specialization in a free entry, else in the entry of one whose copy has lost its Oil code, else in an
	 entry chosen round robin.  (An evicted specialization keeps working until its method's baseline code is compiled again.)"
	<api>
	| entryIndex copy classTag |
	classTag := objectMemory classTagForClass: classObj.
	entryIndex := -1.
	0 to: OilMaxSpecializations - 1 do:
		[:index|
		(entryIndex < 0
		 and: [(self oilSpecializationAt: index field: OilSpecMethod) = objectMemory nilObject]) ifTrue:
			[entryIndex := index]].
	entryIndex < 0 ifTrue:
		[0 to: OilMaxSpecializations - 1 do:
			[:index|
			copy := self oilSpecializationAt: index field: OilSpecCopy.
			(entryIndex < 0
			 and: [(self oilHasOilCode: copy) not]) ifTrue:
				[entryIndex := index]]].
	entryIndex < 0 ifTrue:
		[entryIndex := oilNumSpecializations \\ OilMaxSpecializations].
	oilNumSpecializations := oilNumSpecializations + 1.
	objectMemory
		storePointer: entryIndex * OilSpecializationSize + OilSpecMethod ofObject: oilSpecializations withValue: aMethodObj;
		storePointer: entryIndex * OilSpecializationSize + OilSpecClassTag ofObject: oilSpecializations withValue: (objectMemory integerObjectOf: classTag);
		storePointer: entryIndex * OilSpecializationSize + OilSpecCopy ofObject: oilSpecializations withValue: copyObj;
		storePointer: entryIndex * OilSpecializationSize + OilSpecClass ofObject: oilSpecializations withValue: classObj! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:00'!
oilHasOilCode: aMethodObj
	"Is aMethodObj (or nil) a method whose machine code is Oil code?"
	<api>
	^(objectMemory isOopCompiledMethod: aMethodObj)
	  and: [self oilMethodHasOilCode: aMethodObj]! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:00'!
oilSpecializedCogMethodOf: aMethodObj tag: classTag
	"Answer the Oil code of the specialization of aMethodObj for receivers of class tag classTag, or nil."
	<returnTypeC: #'CogMethod *'>
	(oilSpecializations = 0 or: [oilSpecializations = objectMemory nilObject]) ifTrue:
		[^nil].
	0 to: OilMaxSpecializations - 1 do:
		[:entryIndex|
		((self oilIsLiveSpecialization: entryIndex of: aMethodObj)
		 and: [(self oilSpecializationAt: entryIndex field: OilSpecClassTag) = (objectMemory integerObjectOf: classTag)]) ifTrue:
			[^coInterpreter cogMethodOf: (self oilSpecializationAt: entryIndex field: OilSpecCopy)]].
	^nil! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:00'!
compileEntry
	"After the inline cache check, at the no-check entry (where linked sends continue, and where super sends and the
	 interpreter enter), a method with specializations (see primitiveOilSpecialize) dispatches on the receiver's class tag:
		cmp TempReg, tag(C_i); jne next; ClassReg := M_C_i; ClassReg := header(ClassReg); test ClassReg, 1; jnz next;
		jmp ClassReg + cmNoCheckEntryOffset; next: ...
	 i.e. to the no-check entry of the Oil code of the copy M_C_i of the method, if it still has machine code (its header is
	 then the CogMethod's address, not a SmallInteger).  Every other receiver runs this (baseline) code: the sixth case.
	 (Each case is 9 abstract instructions, see estimateOfAbstractOpcodesPerBytecodes.)
	 TempReg and ClassReg are free at the entry; the copies are literals of this code (the GC keeps them and updates them)."
	| jumpNext jumpNotCogged first |
	<var: #jumpNext type: #'AbstractInstruction *'>
	<var: #jumpNotCogged type: #'AbstractInstruction *'>
	super compileEntry.
	oilNumMethodPICCases = 0 ifTrue:
		[^self].
	first := true.
	0 to: OilMaxSpecializations - 1 do:
		[:entryIndex|
		(self oilIsLiveSpecialization: entryIndex of: methodObj) ifTrue:
			[first ifTrue:
				[objectRepresentation genGetInlineCacheClassTagFrom: ReceiverResultReg into: TempReg forEntry: false.
				 first := false].
			 self CmpCq: (objectMemory integerValueOf: (self oilSpecializationAt: entryIndex field: OilSpecClassTag)) R: TempReg.
			 jumpNext := self JumpNonZero: 0.
			 self genMoveConstant: (self oilSpecializationAt: entryIndex field: OilSpecCopy) R: ClassReg.
			 self MoveMw: objectMemory baseHeaderSize r: ClassReg R: ClassReg.
			 self TstCq: objectMemory smallIntegerTag R: ClassReg.
			 jumpNotCogged := self JumpNonZero: 0.
			 self AddCq: cmNoCheckEntryOffset R: ClassReg.
			 self JumpR: ClassReg.
			 jumpNext jmpTarget: (jumpNotCogged jmpTarget: self Label)]]! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/25/2026 04:00'!
linkSendAt: callSiteReturnAddress in: sendingMethod to: targetMethod offset: theEntryOffset receiver: receiver
	"Link a monomorphic send whose receiver's class has a specialization of the target method directly to its Oil code,
	 bypassing the dispatch in the target's baseline code (see compileEntry).  Otherwise as in Cogit."
	<api>
	<var: #sendingMethod type: #'CogMethod *'>
	<var: #targetMethod type: #'CogMethod *'>
	| target specialized inlineCacheTag extent |
	<var: #target type: #'CogMethod *'>
	<var: #specialized type: #'CogMethod *'>
	self assert: (theEntryOffset = cmEntryOffset or: [theEntryOffset = cmNoCheckEntryOffset]).
	self assert: (callSiteReturnAddress between: methodZoneBase and: methodZone freeStart).
	target := targetMethod.
	(theEntryOffset = cmEntryOffset
	 and: [targetMethod cmUnusedFlag
	 and: [(self isOilMethod: targetMethod) not]]) ifTrue:
		[specialized := self oilSpecializedCogMethodOf: targetMethod methodObject tag: (objectMemory fetchClassTagOf: receiver).
		 specialized ~= nil ifTrue: [target := specialized]].
	self ensureWritableCodeZone.
	theEntryOffset = cmNoCheckEntryOffset
		ifTrue: "no need to change selector cache tag"
			[extent := backEnd rewriteCallAt: callSiteReturnAddress target: target asInteger + cmNoCheckEntryOffset]
		ifFalse:
			[inlineCacheTag := objectRepresentation inlineCacheTagForInstance: receiver.
			 (self inlineCacheTagsAreIndexes not and: [objectRepresentation inlineCacheTagIsYoung: inlineCacheTag]) ifTrue:
				[methodZone ensureInYoungReferrers: sendingMethod].
			 extent := backEnd
						rewriteInlineCacheAt: callSiteReturnAddress
						tag: inlineCacheTag
						target: target asInteger + theEntryOffset].
	backEnd
		flushICacheFrom: callSiteReturnAddress asUnsignedInteger  - extent
		to: callSiteReturnAddress asUnsignedInteger! !


!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-specialization' stamp: 'cb 10/25/2026 04:00'!
oilFreeMachineCodeOf: methodObj
	"Free the machine code of methodObj, if any (c.f. primitiveVoidVMStateForMethod): its frames are divorced and its
	 contexts get bytecode pcs.  The caller has married the current frame (see primitiveOilCompile)."
	<api>
	<essential: #ProfilingCogit>
	self flushMethodCacheForMethod: methodObj.
	(self methodHasCogMethod: methodObj) ifTrue:
		[self divorceMachineCodeFramesWithMethod: methodObj.
		 self ensureAllContextsWithMethodHaveBytecodePCs: methodObj.
		 cogit unlinkSendsTo: methodObj andFreeIf: true]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-specialization' stamp: 'cb 10/25/2026 04:00'!
activateNewCogMethod: cogMethod inInterpreter: inInterpreter
	<var: #cogMethod type: #'CogMethod *'>
	"Activate newMethod when newMethod has been cogged, i.e. create a machine-code frame and (re)enter machine-code.
	 Oil: a baseline method that dispatches to its specializations (cmUnusedFlag, see ProfilingCogit>>compileEntry) is
	 entered at its no-check entry, like a frameless method: it builds its frame itself."
	| methodHeader rcvr numTemps switched |
	self assert: (self rawHeaderOf: newMethod) = cogMethod asInteger.
	methodHeader := cogMethod methodHeader.
	rcvr := self stackValue: cogMethod cmNumArgs. "could new rcvr be set at point of send?"
	self push: instructionPointer.
	(cogMethod stackCheckOffset = 0
	 or: [self cppIf: #Oil ifTrue: [cogMethod cmUnusedFlag and: [(cogit isOilMethod: cogMethod) not]] ifFalse: [false]]) ifTrue:
		["frameless method, or method with specializations; nothing to activate..."
		 cogit numRegArgs > 0 ifTrue: "dont use and: so as to get Slang to inline cogit numRegArgs > 0"
			[cogMethod cmNumArgs <= cogit numRegArgs ifTrue:
				[self callRegisterArgCogMethod: cogMethod at: cogit noCheckEntryOffset receiver: rcvr]].
		 self push: cogMethod asUnsignedInteger + cogit noCheckEntryOffset.
		 self push: rcvr.
		 cogit ceCallCogCodePopReceiverReg.
		 self error: 'should not be reached'].
	self push: framePointer asUnsignedInteger.
	framePointer := stackPointer.
	self push: cogMethod asUnsignedInteger.
	self push: objectMemory nilObject. "FxThisContext field"
	self push: rcvr.

	"clear remaining temps to nil"
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	cogMethod cmNumArgs + 1 to: numTemps do:
		[:i | self push: objectMemory nilObject].

	((self methodHeaderHasPrimitive: methodHeader)
	 and: [primFailCode ~= 0]) ifTrue:
		[self reapAndResetErrorCodeTo: stackPointer header: methodHeader].

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	stackPointer >= stackLimit ifTrue:
		[self assert: cogMethod stackCheckOffset > cogit noCheckEntryOffset.
		 self push: cogMethod asUnsignedInteger + cogMethod stackCheckOffset.
		 self push: rcvr.
		 cogit ceEnterCogCodePopReceiverReg.
		 self error: 'should not be reached'].
	instructionPointer := cogMethod asUnsignedInteger + cogMethod stackCheckOffset.
	switched := self handleStackOverflowOrEventAllowContextSwitch: (self canContextSwitchIfActivating: newMethod header: methodHeader).
	self returnToExecutive: inInterpreter postContextSwitch: switched! !


!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/25/2026 04:00'!
primitiveOilSpecialize
	"Receiver: a CompiledMethod; argument: a class.  Compile an Oil version of the method specialized for receivers of the
	 class, in addition to its other specializations (at most OilMaxPICCases) and to its baseline machine code, which keeps
	 running the receivers of every other class.  The Oil code is the machine code of a copy of the method, recorded in the
	 specialization table.  The method's machine code is freed: it is compiled again, with a dispatch to its specializations
	 (see ProfilingCogit>>compileEntry), and the sends linked to it relink, directly to a specialization when monomorphic (see
	 ProfilingCogit>>linkSendAt:in:to:offset:receiver:).  Pass 1 uses the inline caches of the method's baseline code, so run
	 the method first.  Answer a SmallInteger, OilOK (0) on success, else an Oil failure code (see OilConstants)."
	<export: true>
	<essential: #ProfilingCogit>
	| methodObj classObj classTag entryIndex copy result table activeContext theFrame thePage |
	argumentCount ~= 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	methodObj := self stackValue: 1.
	classObj := self stackTop.
	((objectMemory isNonImmediate: methodObj)
	 and: [(objectMemory isOopCompiledMethod: methodObj)
	 and: [(self isFullBlockMethod: methodObj) not
	 and: [objectMemory isNonImmediate: classObj]]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	"Oil code of the method itself (primitiveOilCompile) cannot be freed: its frames and contexts cannot be mapped to bytecodes."
	((self methodHasCogMethod: methodObj)
	 and: [cogit isOilMethod: (self cogMethodOf: methodObj)]) ifTrue:
		[^self pop: 2 thenPush: (objectMemory integerObjectOf: OilFailSpecialization)].
	"The specialization table (a GC root), allocated once."
	cogit getOilSpecializations = 0 ifTrue:
		[table := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: OilMaxSpecializations * OilSpecializationSize.
		 table isNil ifTrue:
			[^self primitiveFailFor: PrimErrNoMemory].
		 cogit setOilSpecializations: table.
		 (objectMemory addGCRoot: cogit oilSpecializationsAddress) ifFalse:
			[cogit setOilSpecializations: 0.
			 ^self primitiveFailFor: PrimErrNoMemory]].
	classTag := objectMemory classTagForClass: classObj.
	entryIndex := cogit oilSpecializationOf: methodObj tag: classTag.
	entryIndex >= 0
		ifTrue:
			[copy := cogit oilSpecializationAt: entryIndex field: OilSpecCopy.
			 (cogit oilHasOilCode: copy) ifTrue:
				[^self pop: 2 thenPush: (objectMemory integerObjectOf: OilOK)]]
		ifFalse:
			[(cogit oilNumSpecializationsOf: methodObj) >= OilMaxPICCases ifTrue:
				[^self pop: 2 thenPush: (objectMemory integerObjectOf: OilFailSpecialization)].
			 copy := objectMemory cloneInOldSpace: methodObj forPinning: false. "(with its header, not its machine code)"
			 copy = 0 ifTrue:
				[^self pop: 2 thenPush: (objectMemory integerObjectOf: OilFailCodeSpace)]].
	self oilEnsureExtraSelectorTable ifFalse:
		[^self primitiveFailFor: PrimErrNoMemory].
	"Pass 1 first, while the baseline inline caches (type feedback) are there (nothing allocates from here on)."
	result := cogit oilCompile: methodObj receiverClass: classObj.
	result ~= OilOK ifTrue:
		[^self pop: 2 thenPush: (objectMemory integerObjectOf: result)].
	"Free the machine code of the method (and of the copy, if any), then run Pass 3 into the copy and install."
	activeContext := self ensureFrameIsMarried: framePointer SP: stackPointer.
	self ensurePushedInstructionPointer.
	self externalWriteBackHeadFramePointers.
	cogit oilFreeMachineCodeKeepingSpecializationsOf: methodObj.
	self oilFreeMachineCodeOf: copy.
	result := cogit oilGenerate: copy.
	(result = OilOK and: [entryIndex < 0]) ifTrue:
		[cogit oilAddSpecialization: methodObj class: classObj copy: copy].
	"If flushing led to divorce continue in the interpreter."
	(self isStillMarriedContext: activeContext) ifFalse:
		[self nilStackPage. "to avoid assert in marryContextInNewStackPageAndInitializeInterpreterRegisters:"
		 self marryContextInNewStackPageAndInitializeInterpreterRegisters: activeContext.
		 self popStack. "pop bogus machine-code instructionPointer"
		 self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: result).
		 cogit ceInvokeInterpret
		 "NOTREACHED"].
	"If not, work out where we are and continue"
	theFrame := self frameOfMarriedContext: activeContext.
	thePage := stackPages stackPageFor: theFrame.
	self assert: thePage headFP = theFrame.
	self setStackPageAndLimit: thePage.
	self setStackPointersFromPage: thePage.
	instructionPointer := self popStack.
	self pop: argumentCount + 1 thenPush: (objectMemory integerObjectOf: result)! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/25/2026 04:00'!
primitiveOilSpecializations
	"Receiver: a CompiledMethod.  Answer an Array of pairs { class. copy } for its specializations that have Oil code (see
	 primitiveOilSpecialize): the copy's machine code is the Oil code specialized for receivers of the class."
	<export: true>
	<essential: #ProfilingCogit>
	| methodObj result count |
	methodObj := self stackTop.
	((objectMemory isNonImmediate: methodObj)
	 and: [objectMemory isOopCompiledMethod: methodObj]) ifFalse:
		[^self primitiveFailFor: PrimErrBadReceiver].
	result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 2 * (cogit oilNumSpecializationsOf: methodObj).
	result isNil ifTrue:
		[^self primitiveFailFor: PrimErrNoMemory].
	count := 0.
	0 to: OilMaxSpecializations - 1 do:
		[:entryIndex|
		(cogit oilIsLiveSpecialization: entryIndex of: methodObj) ifTrue:
			[objectMemory
				storePointer: count ofObject: result withValue: (objectMemory classOrNilAtIndex: (objectMemory integerValueOf: (cogit oilSpecializationAt: entryIndex field: OilSpecClassTag)));
				storePointer: count + 1 ofObject: result withValue: (cogit oilSpecializationAt: entryIndex field: OilSpecCopy).
			 count := count + 2]].
	self pop: argumentCount + 1 thenPush: result! !
