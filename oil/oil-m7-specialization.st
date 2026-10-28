"Method-level multi-specialization for the Oil optimizing JIT (Milestone 7, Closed-PIC Dispatcher).
 A method may have up to OilMaxSpecialization (5) Oil versions, each specialized for one receiver class, besides its
 baseline machine code, which runs every other receiver: like a closed PIC of 6 cases whose last case is the generic code.
 - At startup, ProfilingCogit compiles a dedicated Dispatcher prototype (oilDispatcherPrototype) using Cogit abstract
   instructions:
   - Header: cmType = CMMethod, stackCheckOffset = 0, counters = (numCases << 2) + OilDispatcherTag.
   - Entry (cmEntryOffset, and cmNoCheckEntryOffset jumping to cmEntryOffset): extracts the receiver's class tag into
     TempReg (the 22-bit masked header load of the inline cache check, so that no class index aliases another) and
     jumps to the first active specialization case.
   - Cases 1..K (up to OilMaxSpecialization = 5): straight-line CmpC32 tag / JumpLongZero to M_C_i + cmNoCheckEntryOffset.
   - Fall-through last case (at oilDispatcherEndOfCodeOffset): JumpLong to M_baseline + cmNoCheckEntryOffset.  M_baseline
     is never freed or recompiled when specializations are added.
 - Monomorphic inline caches (linkSendAt:in:to:offset:receiver:) and closed PIC cases (configureCPIC:..., cogExtendPIC:...)
   never link to the Dispatcher: they link directly to M_C_k if the receiver's class tag has a specialization, or directly
   to M_baseline otherwise.  Adding a new specialization only unlinks sends targeting M_baseline, leaving existing inline
   caches linked to earlier specializations untouched.
 - When all specializations of a Dispatcher are freed (used = 0 in oilCompactDispatcher:), the method's header is restored
   directly to M_baseline and the Dispatcher stub is freed.
 - M, M_baseline, every M_C_k and the Dispatcher all have methodObject = M; M_C_k's metadata holds receiverClass in slot 2
   so full GC keeps the class and its class tag alive while M_C_k is in the code zone.
 Author: cb."!

!Cogit methodsFor: '*VMMaker-JIT-Oil-specialization' stamp: 'cb 10/28/2026 00:15'!
isOilDispatcher: aCogMethod
	<api>
	<inline: false>
	<var: #aCogMethod type: #'CogMethod *'>
	^false! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
isOilDispatcher: aCogMethod
	"Is aCogMethod a dedicated Dispatcher that dispatches a method's entry to up to OilMaxSpecialization Oil
	 specializations (Cases 1..oilDispatcherNumCases:) and its baseline CogMethod (the fall-through last case)?"
	<api>
	<inline: false>
	<var: #aCogMethod type: #'CogMethod *'>
	aCogMethod = 0 ifTrue: [^false].
	^aCogMethod cmType = CMMethod and: [(aCogMethod counters bitAnd: 3) = OilDispatcherTag]! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilDispatcherNumCases: dispatcher
	"Answer the number of active specialization cases (1..OilMaxSpecialization) in the Dispatcher dispatcher.
	 Stored in counters as (numCases << 2) + OilDispatcherTag so stackCheckOffset remains 0."
	<api>
	<inline: true>
	<var: #dispatcher type: #'CogMethod *'>
	^dispatcher counters >> 2! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilDispatcher: writableDispatcher putNumCases: numCases
	<inline: true>
	<var: #writableDispatcher type: #'CogMethod *'>
	writableDispatcher counters: (numCases << 2) + OilDispatcherTag! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
noAssertMethodClassAssociationOf: methodPointer
	"Cogit asserts noAssertMethodClassAssociationOf(cogMethod->methodObject) == nilObject when a CogMethod's
	 methodObject has another CogMethod as its rawHeader (Newspeak anonymous accessors).  With Oil's Dispatcher,
	 baseline and specialized CogMethods share methodObject while rawHeaderOf(methodObject) points to their
	 Dispatcher: answer nilObject so those assertions hold."
	^objectMemory nilObject! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 05:00'!
generateClosedPICPrototype
	"After generating the standard closed PIC prototype, generate the Oil Dispatcher prototype."
	super generateClosedPICPrototype.
	self oilGenerateDispatcherPrototype! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 05:00'!
oilGenerateDispatcherPrototype
	"Compile the Oil Dispatcher prototype at methodZoneBase using Cogit abstract instructions,
	 compute oilDispatcherFirstCaseOffset, oilDispatcherCaseSize, oilDispatcherEndOfCodeOffset and oilDispatcherSize,
	 and advance methodZoneBase."
	<inline: false>
	| jumpToCases firstCaseLabel endCase1Label endOfCodeLabel endAddress |
	<var: #jumpToCases type: #'AbstractInstruction *'>
	<var: #firstCaseLabel type: #'AbstractInstruction *'>
	<var: #endCase1Label type: #'AbstractInstruction *'>
	<var: #endOfCodeLabel type: #'AbstractInstruction *'>
	self allocateOpcodes: 32 bytecodes: 0.
	methodOrBlockNumArgs := 0.
	methodLabel address: methodZoneBase; dependent: nil.
	self compileAbort.
	entry := objectRepresentation
				genGetInlineCacheClassTagFrom: ReceiverResultReg
				into: TempReg
				forEntry: true.
	self CmpR: TempReg R: TempReg.
	jumpToCases := self JumpZero: 0.
	noCheckEntry := self Jump: entry.
	firstCaseLabel := self Label.
	jumpToCases jmpTarget: firstCaseLabel.
	1 to: OilMaxSpecialization do:
		[:h|
		self CmpC32: 16rBABE1F15 + h R: TempReg.
		self JumpLongZero: self cPICPrototypeCaseOffset + 16rCA5E10 + (h * 16).
		h = 1 ifTrue:
			[endCase1Label := self Label]].
	self JumpLong: (self cPICMissTrampolineFor: 0).
	endOfCodeLabel := self Label.
	self computeMaximumSizes.
	oilDispatcherPrototype := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	oilDispatcherSize := (self sizeof: CogMethod) + (self generateInstructionsAt: methodZoneBase + (self sizeof: CogMethod)).
	endAddress := self outputInstructionsAt: methodZoneBase + (self sizeof: CogMethod).
	self assert: methodZoneBase + oilDispatcherSize = endAddress.
	self assert: entry address - methodZoneBase = cmEntryOffset.
	self assert: noCheckEntry address - methodZoneBase = cmNoCheckEntryOffset.
	oilDispatcherFirstCaseOffset := firstCaseLabel address - methodZoneBase.
	oilDispatcherCaseSize := endCase1Label address - firstCaseLabel address.
	oilDispatcherEndOfCodeOffset := endOfCodeLabel address - methodZoneBase.
	oilDispatcherSize := backEnd roundUpToMethodAlignment: oilDispatcherSize.
	objectMemory byteAt: methodZoneBase + oilDispatcherSize - 1 put: MapEnd.
	methodZoneBase := self alignUptoRoutineBoundary: methodZoneBase + oilDispatcherSize! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilAddressOfEndOfCase: caseIndex inDispatcher: dispatcher
	"Answer the address following specialization case caseIndex (1..OilMaxSpecialization) in the Dispatcher dispatcher.
	 Case 1 is the last case before oilDispatcherEndOfCodeOffset; Case K..1 execute in straight-line sequence and fall
	 through into the baseline JumpLong at oilDispatcherEndOfCodeOffset."
	<inline: true>
	<var: #dispatcher type: #'CogMethod *'>
	^dispatcher asInteger + oilDispatcherFirstCaseOffset + (OilMaxSpecialization + 1 - caseIndex * oilDispatcherCaseSize)! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilRewriteDispatcherCaseAt: followingAddress tag: newTag target: newTarget
	"Rewrite the 32-bit class tag and conditional jump target of the Dispatcher specialization case ending at followingAddress."
	<inline: false>
	backEnd
		storeLiteral32: newTag
		beforeFollowingAddress: followingAddress - backEnd jumpLongConditionalByteSize.
	backEnd
		rewriteConditionalJumpLongAt: followingAddress
		target: newTarget! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilRewriteDispatcher: dispatcher caseJumpTo: targetAddress
	"Rewrite the short jump at the end of the Dispatcher's entry (immediately before cmNoCheckEntryOffset) to jump
	 to targetAddress (the start of the highest active specialization case)."
	<inline: true>
	<var: #dispatcher type: #'CogMethod *'>
	backEnd
		rewriteCPICJumpAt: dispatcher asInteger + cmNoCheckEntryOffset
		target: targetAddress! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilDispatcher: dispatcher targetAt: caseIndex
	"Answer the target Oil CogMethod of specialization case caseIndex (1..oilDispatcherNumCases:) of the Dispatcher dispatcher."
	<api>
	<inline: false>
	<var: #dispatcher type: #'CogMethod *'>
	<returnTypeC: #'CogMethod *'>
	| dispPC dispEntry |
	dispPC := self oilAddressOfEndOfCase: caseIndex inDispatcher: dispatcher.
	dispEntry := backEnd jumpLongConditionalTargetBeforeFollowingAddress: dispPC.
	^self cCoerceSimple: dispEntry - cmNoCheckEntryOffset to: #'CogMethod *'! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilDispatcher: dispatcher tagAt: caseIndex
	"Answer the 32-bit class tag of specialization case caseIndex (1..oilDispatcherNumCases:) of the Dispatcher dispatcher."
	<api>
	<inline: false>
	<var: #dispatcher type: #'CogMethod *'>
	| dispPC |
	dispPC := self oilAddressOfEndOfCase: caseIndex inDispatcher: dispatcher.
	^backEnd literal32BeforeFollowingAddress: dispPC - backEnd jumpLongConditionalByteSize! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilBaselineOfDispatcher: dispatcher
	"Answer the baseline CogMethod (the fall-through last case at oilDispatcherEndOfCodeOffset) of the Dispatcher dispatcher."
	<api>
	<inline: false>
	<var: #dispatcher type: #'CogMethod *'>
	<returnTypeC: #'CogMethod *'>
	| dispEntry |
	dispEntry := backEnd jumpLongTargetBeforeFollowingAddress: dispatcher asInteger + oilDispatcherEndOfCodeOffset.
	^self cCoerceSimple: dispEntry - cmNoCheckEntryOffset to: #'CogMethod *'! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilBaselineCogMethodOf: aMethodObj
	"Answer the baseline CogMethod of aMethodObj, or nil if it has none (not cogged, or cogged with standalone Oil code)."
	<api>
	<inline: false>
	<returnTypeC: #'CogMethod *'>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	(coInterpreter methodHasCogMethod: aMethodObj) ifFalse: [^nil].
	cogMethod := coInterpreter cogMethodOf: aMethodObj.
	(self isOilDispatcher: cogMethod) ifTrue:
		[^self oilBaselineOfDispatcher: cogMethod].
	(self isOilMethod: cogMethod) ifTrue:
		[^nil].
	^cogMethod! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilNumSpecializationsOf: aMethodObj
	"Answer the number of live Oil specializations in the Dispatcher of aMethodObj (1..oilDispatcherNumCases:)."
	<api>
	<inline: false>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	(coInterpreter methodHasCogMethod: aMethodObj) ifFalse: [^0].
	cogMethod := coInterpreter cogMethodOf: aMethodObj.
	(self isOilDispatcher: cogMethod) ifFalse: [^0].
	^self oilDispatcherNumCases: cogMethod! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilSpecializedCogMethodOf: aMethodObj tag: classTag
	"Answer the Oil CogMethod of the specialization of aMethodObj for receivers of class tag classTag, or nil."
	<api>
	<inline: false>
	<returnTypeC: #'CogMethod *'>
	| dispatcher |
	<var: #dispatcher type: #'CogMethod *'>
	(coInterpreter methodHasCogMethod: aMethodObj) ifFalse: [^nil].
	dispatcher := coInterpreter cogMethodOf: aMethodObj.
	(self isOilDispatcher: dispatcher) ifFalse: [^nil].
	1 to: (self oilDispatcherNumCases: dispatcher) do:
		[:caseIndex|
		(self oilDispatcher: dispatcher tagAt: caseIndex) = classTag ifTrue:
			[^self oilDispatcher: dispatcher targetAt: caseIndex]].
	^nil! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilFirstSpecializedCogMethodOf: aMethodObj
	"Answer the Oil code of the first live specialization of aMethodObj, or nil."
	<api>
	<inline: false>
	<returnTypeC: #'CogMethod *'>
	| dispatcher |
	<var: #dispatcher type: #'CogMethod *'>
	(coInterpreter methodHasCogMethod: aMethodObj) ifFalse: [^nil].
	dispatcher := coInterpreter cogMethodOf: aMethodObj.
	((self isOilDispatcher: dispatcher) and: [(self oilDispatcherNumCases: dispatcher) >= 1]) ifFalse: [^nil].
	^self oilDispatcher: dispatcher targetAt: 1! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilTargetCogMethodOf: aMethodObj tag: classTag
	"Answer the CogMethod of the cogged method aMethodObj to link a monomorphic send or a closed PIC case of class tag
	 classTag to: the Oil specialization for classTag if its Dispatcher has one, else its baseline CogMethod (never the
	 Dispatcher itself)."
	<api>
	<inline: false>
	<returnTypeC: #'CogMethod *'>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := coInterpreter cogMethodOf: aMethodObj.
	(self isOilDispatcher: cogMethod) ifFalse:
		[^cogMethod].
	1 to: (self oilDispatcherNumCases: cogMethod) do:
		[:caseIndex|
		(self oilDispatcher: cogMethod tagAt: caseIndex) = classTag ifTrue:
			[^self oilDispatcher: cogMethod targetAt: caseIndex]].
	^self oilBaselineOfDispatcher: cogMethod! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 05:00'!
oilCreateDispatcherFor: aMethodObj baseline: baselineMethod tag: classTag oilMethod: oilCogMethod
	"Allocate and configure a dedicated Dispatcher for aMethodObj whose specialization Case 1 jumps to oilCogMethod's
	 no-check entry on classTag and whose fall-through last case at oilDispatcherEndOfCodeOffset jumps to
	 baselineMethod's no-check entry; install it as aMethodObj's rawHeader.  Answer the Dispatcher, or nil if full."
	<inline: false>
	<var: #baselineMethod type: #'CogMethod *'>
	<var: #oilCogMethod type: #'CogMethod *'>
	<returnTypeC: #'CogMethod *'>
	| startAddress writableDispatcher dispatcher caseEndAddress |
	<var: #writableDispatcher type: #'CogMethod *'>
	<var: #dispatcher type: #'CogMethod *'>
	startAddress := methodZone allocate: oilDispatcherSize.
	startAddress = 0 ifTrue:
		[methodZone freeMethod: oilCogMethod.
		 coInterpreter callForCogCompiledCodeCompaction.
		 ^nil].
	dispatcher := self cCoerceSimple: startAddress to: #'CogMethod *'.
	writableDispatcher := self writableMethodFor: startAddress.
	self codeMemcpy: writableDispatcher _: oilDispatcherPrototype _: oilDispatcherSize.
	writableDispatcher
		cmType: CMMethod;
		objectHeader: objectMemory nullHeaderForMachineCodeMethod;
		blockSize: oilDispatcherSize;
		methodObject: aMethodObj;
		methodHeader: baselineMethod methodHeader;
		selector: baselineMethod selector;
		cmNumArgs: baselineMethod cmNumArgs;
		cmHasMovableLiteral: false.
	(writableDispatcher cmRefersToYoung: ((objectMemory isYoungObject: aMethodObj) or: [objectMemory isYoung: baselineMethod selector])) ifTrue:
		[methodZone addToYoungReferrers: writableDispatcher].
	writableDispatcher
		cmUsageCount: CMMaxUsageCount - 1;
		cpicHasMNUCase: false;
		cmUsesPenultimateLit: baselineMethod cmUsesPenultimateLit;
		blockEntryOffset: 0;
		stackCheckOffset: 0;
		cmUnusedFlag: false.
	self oilDispatcher: writableDispatcher putNumCases: 1.
	backEnd rewriteCallAt: startAddress + missOffset target: (self methodAbortTrampolineFor: baselineMethod cmNumArgs).
	"Specialization Case 1 compares the receiver's class tag in TempReg with classTag and jumps to oilCogMethod's no-check entry."
	caseEndAddress := self oilAddressOfEndOfCase: 1 inDispatcher: dispatcher.
	self
		oilRewriteDispatcherCaseAt: caseEndAddress
		tag: classTag
		target: oilCogMethod asInteger + cmNoCheckEntryOffset.
	self oilRewriteDispatcher: dispatcher caseJumpTo: caseEndAddress - oilDispatcherCaseSize.
	"Last Case (straight-line fall-through at oilDispatcherEndOfCodeOffset when no specialization case matches): jump to baselineMethod."
	backEnd
		rewriteJumpLongAt: startAddress + oilDispatcherEndOfCodeOffset
		target: baselineMethod asInteger + cmNoCheckEntryOffset.
	backEnd flushICacheFrom: startAddress to: startAddress + oilDispatcherSize.
	coInterpreter rawHeaderOf: aMethodObj put: startAddress.
	^dispatcher! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 05:00'!
oilExtendDispatcher: dispatcher tag: classTag oilMethod: oilCogMethod
	"Add (classTag -> oilCogMethod + cmNoCheckEntryOffset) as the next specialization case of the Dispatcher dispatcher."
	<inline: false>
	<var: #dispatcher type: #'CogMethod *'>
	<var: #oilCogMethod type: #'CogMethod *'>
	| newNumCases caseEndAddress writableDispatcher |
	<var: #writableDispatcher type: #'CogMethod *'>
	writableDispatcher := self writableMethodFor: dispatcher.
	newNumCases := (self oilDispatcherNumCases: dispatcher) + 1.
	caseEndAddress := self oilAddressOfEndOfCase: newNumCases inDispatcher: dispatcher.
	self
		oilRewriteDispatcherCaseAt: caseEndAddress
		tag: classTag
		target: oilCogMethod asInteger + cmNoCheckEntryOffset.
	self oilRewriteDispatcher: dispatcher caseJumpTo: caseEndAddress - oilDispatcherCaseSize.
	self oilDispatcher: writableDispatcher putNumCases: newNumCases.
	backEnd flushICacheFrom: dispatcher asUnsignedInteger to: dispatcher asUnsignedInteger + oilDispatcherSize! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilGenerateSpecialized: aMethodObj tag: classTag
	"Run Pass 2, Pass 3 and assemble the Oil specialization of aMethodObj for classTag, then install it in
	 aMethodObj's Dispatcher (creating the Dispatcher first if aMethodObj only has its baseline CogMethod),
	 and unlink sends targeting the baseline CogMethod so monomorphic and polymorphic sends relink directly to the
	 specialization."
	<api>
	<inline: false>
	<option: #ProfilingCogit>
	| result oilCogMethod headerMethod dispatcher |
	<var: #oilCogMethod type: #'CogMethod *'>
	<var: #headerMethod type: #'CogMethod *'>
	<var: #dispatcher type: #'CogMethod *'>
	result := self oilGenerate: aMethodObj.
	result ~= OilOK ifTrue: [^result].
	oilCogMethod := self cCoerceSimple: methodLabel address to: #'CogMethod *'.
	headerMethod := coInterpreter cogMethodOf: aMethodObj.
	(self isOilDispatcher: headerMethod)
		ifTrue:
			[self oilExtendDispatcher: headerMethod tag: classTag oilMethod: oilCogMethod.
			 dispatcher := headerMethod]
		ifFalse:
			[dispatcher := self oilCreateDispatcherFor: aMethodObj baseline: headerMethod tag: classTag oilMethod: oilCogMethod.
			 dispatcher isNil ifTrue: [^OilFailCodeSpace]].
	self unlinkSendsToCogMethod: (self oilBaselineOfDispatcher: dispatcher).
	^OilOK! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
linkSendAt: callSiteReturnAddress in: sendingMethod to: targetMethod offset: theEntryOffset receiver: receiver
	"Never link a monomorphic send (cmEntryOffset) to a Dispatcher: link it directly to the Oil specialization for
	 the receiver's class tag if the Dispatcher has one, else directly to the baseline CogMethod."
	<api>
	<var: #sendingMethod type: #'CogMethod *'>
	<var: #targetMethod type: #'CogMethod *'>
	| specTarget inlineCacheTag extent |
	<var: #specTarget type: #'CogMethod *'>
	self assert: (theEntryOffset = cmEntryOffset or: [theEntryOffset = cmNoCheckEntryOffset]).
	self assert: (callSiteReturnAddress between: methodZoneBase and: methodZone freeStart).
	specTarget := (theEntryOffset = cmEntryOffset and: [self isOilDispatcher: targetMethod])
					ifTrue: [self oilTargetCogMethodOf: targetMethod methodObject tag: (objectMemory fetchClassTagOf: receiver)]
					ifFalse: [targetMethod].
	self ensureWritableCodeZone.
	theEntryOffset = cmNoCheckEntryOffset
		ifTrue: "no need to change selector cache tag"
			[extent := backEnd rewriteCallAt: callSiteReturnAddress target: specTarget asInteger + cmNoCheckEntryOffset]
		ifFalse:
			[inlineCacheTag := objectRepresentation inlineCacheTagForInstance: receiver.
			 (self inlineCacheTagsAreIndexes not and: [objectRepresentation inlineCacheTagIsYoung: inlineCacheTag]) ifTrue:
				[methodZone ensureInYoungReferrers: sendingMethod].
			 extent := backEnd
						rewriteInlineCacheAt: callSiteReturnAddress
						tag: inlineCacheTag
						target: specTarget asInteger + theEntryOffset].
	backEnd
		flushICacheFrom: callSiteReturnAddress asUnsignedInteger - extent
		to: callSiteReturnAddress asUnsignedInteger! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
cogExtendPIC: cPIC CaseNMethod: caseNMethod tag: caseNTag isMNUCase: isMNUCase
	"Extend the cPIC with the supplied case.  If caseNMethod has a Dispatcher, jump directly to the no-check entry
	 of its Oil specialization for caseNTag or of its baseline CogMethod (never to the Dispatcher)."
	<var: #cPIC type: #'CogMethod *'>
	| operand target address writablePIC |
	<var: #writablePIC type: #'CogMethod *'>
	coInterpreter compilationBreakpoint: cPIC selector classTag: caseNTag isMNUCase: isMNUCase.
	self assert: (objectRepresentation inlineCacheTagIsYoung: caseNTag) not.
	self assert: (caseNMethod notNil and: [(objectMemory isYoung: caseNMethod) not]).
	writablePIC := self writableMethodFor: cPIC.
	(isMNUCase not and: [coInterpreter methodHasCogMethod: caseNMethod])
		ifTrue:
			[operand := 0.
			 target := (self oilTargetCogMethodOf: caseNMethod tag: caseNTag) asInteger + cmNoCheckEntryOffset]
		ifFalse:
			[operand := caseNMethod.
			 isMNUCase
				ifTrue:
					[writablePIC cpicHasMNUCase: true.
					 target := cPIC asInteger + (self sizeof: CogMethod)]
				ifFalse:
					[target := cPIC asInteger + self picInterpretAbortOffset]].
	address := self addressOfEndOfCase: cPIC cPICNumCases + 1 inCPIC: cPIC.
	self rewriteCPICCaseAt: address tag: caseNTag objRef: operand target: target.
	self rewriteCPIC: cPIC caseJumpTo: address - cPICCaseSize.
	writablePIC cPICNumCases: cPIC cPICNumCases + 1.
	backEnd flushICacheFrom: cPIC asUnsignedInteger to: cPIC asUnsignedInteger + closedPICSize.
	self assertValidDualZoneFrom: cPIC asUnsignedInteger to: cPIC asUnsignedInteger + closedPICSize! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
configureCPIC: cPIC Case0: case0CogMethod Case1Method: case1Method tag: case1Tag isMNUCase: isMNUCase numArgs: numArgs delta: addrDelta
	"Configure a two-case closed PIC for case0CogMethod (already linked directly to its specialization or baseline
	 CogMethod by linkSendAt:...) and (case1Method, case1Tag), jumping directly to case1Method's Oil specialization
	 for case1Tag or baseline CogMethod."
	<var: #cPIC type: #'CogMethod *'>
	<var: #case0CogMethod type: #'CogMethod *'>
	| operand targetEntry caseEndAddress |
	self assert: case1Method notNil.
	backEnd rewriteCallAt: cPIC asInteger + missOffset target: (self picAbortTrampolineFor: numArgs).
	self assert: (objectRepresentation inlineCacheTagIsYoung: case1Tag) not.
	(isMNUCase not and: [coInterpreter methodHasCogMethod: case1Method])
		ifTrue:
			[operand := 0.
			 targetEntry := (self oilTargetCogMethodOf: case1Method tag: case1Tag) asInteger + cmNoCheckEntryOffset]
		ifFalse:
			[operand := (case1Method isNil or: [objectMemory isYoungObject: case1Method])
							ifTrue: [0]
							ifFalse: [case1Method].
			 targetEntry := case1Method ifNil: [cPIC asInteger + (self sizeof: CogMethod)] ifNotNil: [cPIC asInteger + self picInterpretAbortOffset]].
	backEnd rewriteJumpLongAt: cPIC asInteger + firstCPICCaseOffset target: case0CogMethod asInteger + cmNoCheckEntryOffset.
	caseEndAddress := self addressOfEndOfCase: 2 inCPIC: cPIC.
	self
		rewriteCPICCaseAt: caseEndAddress
		tag: case1Tag
		objRef: operand
		target: (isMNUCase ifTrue: [cPIC asInteger + (self sizeof: CogMethod)] ifFalse: [targetEntry]) asInteger.
	backEnd relocateMethodReferenceBeforeAddress: cPIC asInteger + cPICEndOfCodeOffset - backEnd jumpLongByteSize by: addrDelta.
	backEnd rewriteJumpLongAt: cPIC asInteger + cPICEndOfCodeOffset target: (self cPICMissTrampolineFor: numArgs).
	^0! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilDispatcherHasFreedTargets: dispatcher
	"Answer whether any of the specialization cases (1..oilDispatcherNumCases:) of the Dispatcher dispatcher targets a freed CogMethod."
	<inline: false>
	<var: #dispatcher type: #'CogMethod *'>
	| specTarget |
	<var: #specTarget type: #'CogMethod *'>
	1 to: (self oilDispatcherNumCases: dispatcher) do:
		[:caseIndex|
		specTarget := self oilDispatcher: dispatcher targetAt: caseIndex.
		specTarget cmType = CMFree ifTrue: [^true]].
	^false! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilCompactDispatcher: dispatcher
	"Compact any freed specialization cases (1..oilDispatcherNumCases:) out of the Dispatcher dispatcher.
	 When all specializations have been freed (used = 0), restore the method's header directly to its baseline
	 CogMethod, free the Dispatcher stub, and unlink sends to freed methods."
	<inline: false>
	<var: #dispatcher type: #'CogMethod *'>
	| numCases used specTarget caseTag destPC baselineMethod writableDispatcher |
	<var: #specTarget type: #'CogMethod *'>
	<var: #baselineMethod type: #'CogMethod *'>
	<var: #writableDispatcher type: #'CogMethod *'>
	numCases := self oilDispatcherNumCases: dispatcher.
	used := 0.
	1 to: numCases do:
		[:caseIndex|
		specTarget := self oilDispatcher: dispatcher targetAt: caseIndex.
		specTarget cmType ~= CMFree ifTrue:
			[caseTag := self oilDispatcher: dispatcher tagAt: caseIndex.
			 used := used + 1.
			 used < caseIndex ifTrue:
				[destPC := self oilAddressOfEndOfCase: used inDispatcher: dispatcher.
				 self
					oilRewriteDispatcherCaseAt: destPC
					tag: caseTag
					target: specTarget asInteger + cmNoCheckEntryOffset]]].
	used = numCases ifTrue: [^self].
	used = 0 ifTrue:
		[baselineMethod := self oilBaselineOfDispatcher: dispatcher.
		 coInterpreter rawHeaderOf: dispatcher methodObject put: baselineMethod asInteger.
		 methodZone freeMethod: dispatcher.
		 compactionInProgress ifFalse: [self unlinkSendsToFree].
		 ^self].
	writableDispatcher := self writableMethodFor: dispatcher.
	self oilDispatcher: writableDispatcher putNumCases: used.
	self
		oilRewriteDispatcher: dispatcher
		caseJumpTo: (self oilAddressOfEndOfCase: used inDispatcher: dispatcher) - oilDispatcherCaseSize.
	backEnd flushICacheFrom: dispatcher asUnsignedInteger to: dispatcher asUnsignedInteger + oilDispatcherSize! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
unlinkSendsToCogMethod: targetCogMethod
	"Unlink all inline caches and closed PICs targeting targetCogMethod directly (without freeing targetCogMethod)."
	<api>
	<inline: false>
	<var: #targetCogMethod type: #'CogMethod *'>
	| scanMethod anyFreedPIC |
	<var: #scanMethod type: #'CogMethod *'>
	methodZoneBase isNil ifTrue: [^self].
	self ensureWritableCodeZone.
	anyFreedPIC := false.
	scanMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[scanMethod < methodZone limitZony] whileTrue:
		[scanMethod cmType = CMMethod
			ifTrue:
				[(self isOilDispatcher: scanMethod) ifFalse:
					[self
						mapFor: scanMethod
						performUntil: #unlinkIfLinkedSend:pc:to:
						arg: targetCogMethod asVoidPointer]]
			ifFalse:
				[(scanMethod cmType = CMClosedPIC
				  and: [self cPIC: scanMethod HasTarget: targetCogMethod]) ifTrue:
					[methodZone freeMethod: scanMethod.
					 anyFreedPIC := true]].
		 scanMethod := methodZone methodAfter: scanMethod].
	anyFreedPIC
		ifTrue: [self unlinkSendsToFree]
		ifFalse: [backEnd flushICacheFrom: methodZoneBase asUnsignedInteger to: methodZone limitZony asUnsignedInteger]! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilFreeCogMethod: cogMethod
	"Free the single Oil CogMethod cogMethod (e.g. after it deoptimized too many times or an inlined selector was
	 redefined): unlink sends and closed PICs targeting cogMethod directly, mark cogMethod free, and if its
	 methodObject has a Dispatcher, compact the freed specialization case out of the Dispatcher."
	<api>
	<inline: false>
	<var: #cogMethod type: #'CogMethod *'>
	| aMethodObj headerMethod |
	<var: #headerMethod type: #'CogMethod *'>
	aMethodObj := cogMethod methodObject.
	(coInterpreter methodHasCogMethod: aMethodObj) ifTrue:
		[headerMethod := coInterpreter cogMethodOf: aMethodObj.
		 headerMethod = cogMethod ifTrue:
			[^self unlinkSendsTo: aMethodObj andFreeIf: true]].
	self unlinkSendsToCogMethod: cogMethod.
	self ensureWritableCodeZone.
	methodZone freeMethod: cogMethod.
	(coInterpreter methodHasCogMethod: aMethodObj) ifTrue:
		[headerMethod := coInterpreter cogMethodOf: aMethodObj.
		 (self isOilDispatcher: headerMethod) ifTrue:
			[self oilCompactDispatcher: headerMethod]].
	self unlinkSendsToFree! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
unlinkSendsTo: targetMethodObject andFreeIf: freeIfTrue
	"Unlink all sends to targetMethodObject.  If targetMethodObject has a Dispatcher, unlink and (if freeIfTrue) free
	 its baseline CogMethod, all its specialized Oil CogMethods, and the Dispatcher itself."
	<api>
	| dispMethod numCases specTarget |
	<var: #dispMethod type: #'CogMethod *'>
	<var: #specTarget type: #'CogMethod *'>
	methodZoneBase isNil ifTrue: [^self].
	((objectMemory isOopCompiledMethod: targetMethodObject)
	 and: [coInterpreter methodHasCogMethod: targetMethodObject]) ifFalse: [^self].
	dispMethod := coInterpreter cogMethodOf: targetMethodObject.
	(self isOilDispatcher: dispMethod) ifFalse:
		[^super unlinkSendsTo: targetMethodObject andFreeIf: freeIfTrue].
	numCases := self oilDispatcherNumCases: dispMethod.
	1 to: numCases do:
		[:i|
		specTarget := self oilDispatcher: dispMethod targetAt: i.
		specTarget cmType ~= CMFree ifTrue:
			[self unlinkSendsToCogMethod: specTarget.
			 freeIfTrue ifTrue: [methodZone freeMethod: specTarget]]].
	specTarget := self oilBaselineOfDispatcher: dispMethod.
	specTarget cmType ~= CMFree ifTrue:
		[self unlinkSendsToCogMethod: specTarget.
		 freeIfTrue ifTrue: [methodZone freeMethod: specTarget]].
	self unlinkSendsToCogMethod: dispMethod.
	freeIfTrue ifTrue:
		[methodZone freeMethod: dispMethod.
		 self unlinkSendsToFree]! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
flagCogMethodForBecome: cogMethod
	"When a method with a Dispatcher is becomed, also flag its baseline and specialized CogMethods for become so their
	 frames are divorced and their sends unlinked."
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	| specTarget writableTarget |
	<var: #specTarget type: #'CogMethod *'>
	<var: #writableTarget type: #'CogMethod *'>
	super flagCogMethodForBecome: cogMethod.
	(self isOilDispatcher: cogMethod) ifTrue:
		[1 to: (self oilDispatcherNumCases: cogMethod) do:
			[:i|
			specTarget := self oilDispatcher: cogMethod targetAt: i.
			specTarget cmType = CMMethod ifTrue:
				[writableTarget := self writableMethodFor: specTarget.
				 writableTarget cmType: CMMethodFlaggedForBecome]].
		 specTarget := self oilBaselineOfDispatcher: cogMethod.
		 specTarget cmType = CMMethod ifTrue:
			[writableTarget := self writableMethodFor: specTarget.
			 writableTarget cmType: CMMethodFlaggedForBecome]]! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
unlinkSendsLinkedForInvalidClasses
	"Also free any Oil specialization in a Dispatcher whose receiver class tag is a forwarded class index (e.g. a
	 reshaped class replaced by become:), and compact the Dispatcher."
	<api>
	| scanMethod anyFreed thisFreed specTarget |
	<var: #scanMethod type: #'CogMethod *'>
	<var: #specTarget type: #'CogMethod *'>
	super unlinkSendsLinkedForInvalidClasses.
	methodZoneBase isNil ifTrue: [^self].
	anyFreed := false.
	scanMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[scanMethod < methodZone limitZony] whileTrue:
		[(self isOilDispatcher: scanMethod) ifTrue:
			[thisFreed := false.
			 1 to: (self oilDispatcherNumCases: scanMethod) do:
				[:i|
				(objectMemory isForwardedClassIndex: (self oilDispatcher: scanMethod tagAt: i)) ifTrue:
					[specTarget := self oilDispatcher: scanMethod targetAt: i.
					 (specTarget cmType = CMMethod and: [(coInterpreter oilHasFramesOf: specTarget) not]) ifTrue:
						[self unlinkSendsToCogMethod: specTarget.
						 self ensureWritableCodeZone.
						 methodZone freeMethod: specTarget.
						 thisFreed := true.
						 anyFreed := true]]].
			 thisFreed ifTrue:
				[self oilCompactDispatcher: scanMethod]].
		 scanMethod := methodZone methodAfter: scanMethod].
	anyFreed ifTrue: [self unlinkSendsToFree]! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
compactPICsWithFreedTargets
	"Also compact any Dispatcher whose specialization targets were freed."
	<inline: false>
	| scanMethod baselineMethod writableDispatcher |
	<var: #scanMethod type: #'CogMethod *'>
	<var: #baselineMethod type: #'CogMethod *'>
	<var: #writableDispatcher type: #'CogMethod *'>
	super compactPICsWithFreedTargets.
	scanMethod := self cCoerceSimple: methodZoneBase to: #'CogMethod *'.
	[scanMethod < methodZone limitZony] whileTrue:
		[((self isOilDispatcher: scanMethod)
		  and: [self oilDispatcherHasFreedTargets: scanMethod]) ifTrue:
			[self oilCompactDispatcherInPlace: scanMethod].
		 scanMethod := methodZone methodAfter: scanMethod]! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
oilCompactDispatcherInPlace: dispatcher
	"Compact freed specialization targets out of dispatcher during code compaction or GC (where compactPICsWithFreedTargets
	 marks empty stubs CMFree without changing methodZone methodCount)."
	<inline: false>
	<var: #dispatcher type: #'CogMethod *'>
	| numCases used specTarget caseTag destPC baselineMethod writableDispatcher |
	<var: #specTarget type: #'CogMethod *'>
	<var: #baselineMethod type: #'CogMethod *'>
	<var: #writableDispatcher type: #'CogMethod *'>
	numCases := self oilDispatcherNumCases: dispatcher.
	used := 0.
	1 to: numCases do:
		[:caseIndex|
		specTarget := self oilDispatcher: dispatcher targetAt: caseIndex.
		specTarget cmType ~= CMFree ifTrue:
			[caseTag := self oilDispatcher: dispatcher tagAt: caseIndex.
			 used := used + 1.
			 used < caseIndex ifTrue:
				[destPC := self oilAddressOfEndOfCase: used inDispatcher: dispatcher.
				 self
					oilRewriteDispatcherCaseAt: destPC
					tag: caseTag
					target: specTarget asInteger + cmNoCheckEntryOffset]]].
	used = numCases ifTrue: [^self].
	writableDispatcher := self writableMethodFor: dispatcher.
	used = 0 ifTrue:
		[baselineMethod := self oilBaselineOfDispatcher: dispatcher.
		 baselineMethod cmType ~= CMFree ifTrue:
			[coInterpreter rawHeaderOf: dispatcher methodObject put: baselineMethod asInteger].
		 writableDispatcher cmRefersToYoung: false.
		 writableDispatcher cmType: CMFree.
		 ^self].
	self oilDispatcher: writableDispatcher putNumCases: used.
	self
		oilRewriteDispatcher: dispatcher
		caseJumpTo: (self oilAddressOfEndOfCase: used inDispatcher: dispatcher) - oilDispatcherCaseSize.
	backEnd flushICacheFrom: dispatcher asUnsignedInteger to: dispatcher asUnsignedInteger + oilDispatcherSize! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 00:15'!
relocateCallsAndSelfReferencesInMethod: cogMethod
	"Relocate calls and jumps in cogMethod during code compaction.  A Dispatcher has its specialization cases at
	 1..oilDispatcherNumCases: and its baseline jump at oilDispatcherEndOfCodeOffset, not a bytecode map."
	<inline: false>
	<var: #cogMethod type: #'CogMethod *'>
	(self isOilDispatcher: cogMethod) ifTrue:
		[^self oilRelocateCallsInDispatcher: cogMethod].
	super relocateCallsAndSelfReferencesInMethod: cogMethod! !

!ProfilingCogit methodsFor: 'oil specialization' stamp: 'cb 10/28/2026 05:00'!
oilRelocateCallsInDispatcher: dispatcher
	"Relocate the abort call, the specialization case jumps (1..oilDispatcherNumCases:) and the fall-through baseline
	 jump at oilDispatcherEndOfCodeOffset in the Dispatcher dispatcher during code compaction."
	<inline: false>
	<var: #dispatcher type: #'CogMethod *'>
	| delta pc targetMethod |
	<var: #targetMethod type: #'CogMethod *'>
	delta := dispatcher objectHeader.
	self assert: (backEnd callTargetFromReturnAddress: dispatcher asInteger + missOffset)
					= (self methodAbortTrampolineFor: dispatcher cmNumArgs).
	backEnd relocateCallBeforeReturnPC: dispatcher asInteger + missOffset by: delta negated.
	1 to: (self oilDispatcherNumCases: dispatcher) do:
		[:i|
		pc := self oilAddressOfEndOfCase: i inDispatcher: dispatcher.
		targetMethod := self oilDispatcher: dispatcher targetAt: i.
		self assert: targetMethod cmType = CMMethod.
		backEnd
			relocateJumpLongConditionalBeforeFollowingAddress: pc
			by: (delta - targetMethod objectHeader) negated].
	targetMethod := self oilBaselineOfDispatcher: dispatcher.
	self assert: targetMethod cmType = CMMethod.
	backEnd
		relocateJumpLongBeforeFollowingAddress: dispatcher asInteger + oilDispatcherEndOfCodeOffset
		by: (delta - targetMethod objectHeader) negated! !

!CogMethodZone methodsFor: '*VMMaker-JIT-Oil-specialization' stamp: 'cb 10/28/2026 00:15'!
freeOlderMethodsForCompaction
	"Free methods, preferring older methods for compaction, up to a quarter of the zone.
	 Oil: a Dispatcher and its targets (Cases 1..oilDispatcherNumCases: specializations and its baseline CogMethod) share
	 the maximum of their usage counts and are kept or freed together as a unit."
	| zoneSize amountToFree initialFreeSpace freedSoFar freeableUsage cogMethod maxCount numCases specTarget writableMethod |
	<var: #cogMethod type: #'CogMethod *'>
	<var: #specTarget type: #'CogMethod *'>
	<var: #writableMethod type: #'CogMethod *'>
	zoneSize := limitAddress - baseAddress.
	initialFreeSpace := limitAddress - mzFreeStart + methodBytesFreedSinceLastCompaction.
	freedSoFar := initialFreeSpace.
	amountToFree := zoneSize // 4.
	cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod asUnsignedInteger < mzFreeStart] whileTrue:
		[(cogit isOilDispatcher: cogMethod) ifTrue:
			[maxCount := cogMethod cmUsageCount.
			 numCases := cogit oilDispatcherNumCases: cogMethod.
			 1 to: numCases do:
				[:i|
				specTarget := cogit oilDispatcher: cogMethod targetAt: i.
				(specTarget cmType ~= CMFree and: [specTarget cmUsageCount > maxCount]) ifTrue:
					[maxCount := specTarget cmUsageCount]].
			 specTarget := cogit oilBaselineOfDispatcher: cogMethod.
			 (specTarget cmType ~= CMFree and: [specTarget cmUsageCount > maxCount]) ifTrue:
				[maxCount := specTarget cmUsageCount].
			 writableMethod := cogit writableMethodFor: cogMethod.
			 writableMethod cmUsageCount: maxCount.
			 1 to: numCases do:
				[:i|
				specTarget := cogit oilDispatcher: cogMethod targetAt: i.
				specTarget cmType ~= CMFree ifTrue:
					[writableMethod := cogit writableMethodFor: specTarget.
					 writableMethod cmUsageCount: maxCount]].
			 specTarget := cogit oilBaselineOfDispatcher: cogMethod.
			 specTarget cmType ~= CMFree ifTrue:
				[writableMethod := cogit writableMethodFor: specTarget.
				 writableMethod cmUsageCount: maxCount]].
		 cogMethod := self methodAfter: cogMethod].
	freeableUsage := 0.
	[cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	 [cogMethod asUnsignedInteger < mzFreeStart and: [freedSoFar < amountToFree]] whileTrue:
		[(cogMethod cmType ~= CMFree
		  and: [cogMethod cmUsageCount <= freeableUsage
		  and: [cogMethod cmType ~= CMMethod
				or: [(coInterpreter rawHeaderOf: cogMethod methodObject) = cogMethod asInteger]]]) ifTrue:
			[(cogit isOilDispatcher: cogMethod) ifTrue:
				[1 to: (cogit oilDispatcherNumCases: cogMethod) do:
					[:i|
					specTarget := cogit oilDispatcher: cogMethod targetAt: i.
					specTarget cmType ~= CMFree ifTrue:
						[self freeMethod: specTarget.
						 freedSoFar := freedSoFar + specTarget blockSize]].
				 specTarget := cogit oilBaselineOfDispatcher: cogMethod.
				 specTarget cmType ~= CMFree ifTrue:
					[self freeMethod: specTarget.
					 freedSoFar := freedSoFar + specTarget blockSize]].
			 self freeMethod: cogMethod.
			 freedSoFar := freedSoFar + cogMethod blockSize].
		 cogMethod := self methodAfter: cogMethod].
	 freedSoFar < amountToFree and: [(freeableUsage := freeableUsage + 1) < CMMaxUsageCount]] whileTrue! !


!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-specialization' stamp: 'cb 10/28/2026 00:15'!
activateNewCogMethod: aCogMethod inInterpreter: inInterpreter
	"Activate newMethod when newMethod has been cogged, i.e. create a machine-code frame and (re)enter machine-code.
	 If newMethod's header is an Oil Dispatcher, activate the target specialization for the receiver's class tag (or
	 the baseline CogMethod if a primitive just failed or no specialization matches) so the frame's method is the
	 actual Oil or baseline CogMethod and any failing primitive prologue at noCheckEntryOffset is skipped."
	<var: #aCogMethod type: #'CogMethod *'>
	| cogMethod methodHeader rcvr numTemps switched |
	<var: #cogMethod type: #'CogMethod *'>
	self assert: (self rawHeaderOf: newMethod) = aCogMethod asInteger.
	methodHeader := aCogMethod methodHeader.
	rcvr := self stackValue: aCogMethod cmNumArgs. "could new rcvr be set at point of send?"
	cogMethod := (cogit isOilDispatcher: aCogMethod)
					ifTrue:
						[primFailCode = 0
							ifTrue: [cogit oilTargetCogMethodOf: newMethod tag: (objectMemory fetchClassTagOf: rcvr)]
							ifFalse: [cogit oilBaselineOfDispatcher: aCogMethod]]
					ifFalse: [aCogMethod].
	self push: instructionPointer.
	cogMethod stackCheckOffset = 0 ifTrue:
		["frameless method; nothing to activate..."
		 cogit numRegArgs > 0 ifTrue:
			[cogMethod cmNumArgs <= cogit numRegArgs ifTrue:
				[self callRegisterArgCogMethod: cogMethod at: cogit noCheckEntryOffset receiver: rcvr]].
		 "dont use and: so as to get Slang to inline cogit numRegArgs > 0"
		 self push: cogMethod asInteger + cogit noCheckEntryOffset.
		 self push: rcvr.
		 cogit ceCallCogCodePopReceiverReg.
		 self error: 'should not be reached'].
	self push: framePointer.
	framePointer := stackPointer.
	self push: cogMethod asInteger.
	self push: objectMemory nilObject. "FxThisContext field"
	self push: rcvr.
	"clear remaining temps to nil"
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	cogMethod cmNumArgs + 1 to: numTemps do:
		[:i| self push: objectMemory nilObject].
	((self methodHeaderHasPrimitive: methodHeader)
	 and: [primFailCode ~= 0]) ifTrue:
		[self reapAndResetErrorCodeTo: stackPointer header: methodHeader].

	"Now check for stack overflow or an event (interrupt, must scavenge, etc)."
	stackPointer >= stackLimit ifTrue:
		[self assert: cogMethod stackCheckOffset > cogit noCheckEntryOffset.
		 self push: cogMethod asInteger + cogMethod stackCheckOffset.
		 self push: rcvr.
		 cogit ceEnterCogCodePopReceiverReg.
		 self error: 'should not be reached'].
	instructionPointer := cogMethod asInteger + cogMethod stackCheckOffset.
	switched := self handleStackOverflowOrEventAllowContextSwitch:
					(self canContextSwitchIfActivating: newMethod header: methodHeader).
	self returnToExecutive: inInterpreter postContextSwitch: switched! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-specialization' stamp: 'cb 10/28/2026 05:00'!
justActivateNewMethod: mustBeInterpreterFrame
	"As CoInterpreter>>justActivateNewMethod: (used by sendInvokeCallbackContext: and primitiveFailForFFIException:at:),
	 except that if newMethod's header is an Oil Dispatcher, the frame activates the target specialization for the
	 receiver's class tag (or the baseline CogMethod if a primitive just failed or no specialization matches), as in
	 activateNewCogMethod:inInterpreter:.  A Dispatcher has no frame code: its stackCheckOffset is 0."
	| methodHeader cogMethod numArgs numTemps rcvr initialIP |
	<var: #initialIP type: #usqInt>
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	methodHeader := self rawHeaderOf: newMethod.
	cogMethod := nil.
	(self isCogMethodReference: methodHeader) ifTrue:
		[cogMethod := self cCoerceSimple: methodHeader to: #'CogMethod *'.
		 methodHeader := cogMethod methodHeader.
		 mustBeInterpreterFrame ifTrue:
			[cogMethod := nil]].
	numTemps := self temporaryCountOfMethodHeader: methodHeader.
	numArgs := self argumentCountOfMethodHeader: methodHeader.

	rcvr := self stackValue: numArgs. "could new rcvr be set at point of send?"
	self assert: (objectMemory addressCouldBeOop: rcvr).
	self assert: (objectMemory isOopForwarded: rcvr) not.

	(cogMethod notNil and: [cogit isOilDispatcher: cogMethod]) ifTrue:
		[cogMethod := primFailCode = 0
						ifTrue: [cogit oilTargetCogMethodOf: newMethod tag: (objectMemory fetchClassTagOf: rcvr)]
						ifFalse: [cogit oilBaselineOfDispatcher: cogMethod]].

	cogMethod ifNotNil:
		[(self isMachineCodeFrame: framePointer) ifFalse:
			[instructionPointer >= objectMemory startOfMemory ifTrue:
				[self iframeSavedIP: framePointer put: instructionPointer].
			 instructionPointer := cogit ceReturnToInterpreterPC].
		 mustBeInterpreterFrame ifTrue:
			[cogMethod := nil]].
	self push: instructionPointer.
	self push: framePointer asUnsignedInteger.
	framePointer := stackPointer.
	initialIP := self initialIPForHeader: methodHeader method: newMethod.
	cogMethod
		ifNotNil:
			[self push: cogMethod asUnsignedInteger.
			 self push: objectMemory nilObject. "FoxThisContext field"
			 instructionPointer := cogMethod asUnsignedInteger + cogMethod stackCheckOffset]
		ifNil:
			[self push: newMethod.
			 self setMethod: newMethod methodHeader: methodHeader.
			 self push: objectMemory nilObject. "FoxThisContext field"
			 self push: (self encodeFrameFieldHasContext: false isBlock: false numArgs: numArgs).
			 self push: 0. "FoxIFSavedIP"
			 instructionPointer := initialIP - 1].
	self push: rcvr.

	"clear remaining temps to nil"
	numArgs + 1 to: numTemps do:
		[:i | self push: objectMemory nilObject].

	(self methodHeaderHasPrimitive: methodHeader) ifTrue:
		["Skip the CallPrimitive bytecode, if it's there, and store the error code if the method starts
		  with a long store temp.  Strictly no need to skip the store because it's effectively a noop."
		 cogMethod ifNil:
			[instructionPointer := instructionPointer + (self sizeOfCallPrimitiveBytecode: methodHeader)].
		 primFailCode ~= 0 ifTrue:
			[self reapAndResetErrorCodeTo: stackPointer header: methodHeader]].

	^methodHeader! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-specialization' stamp: 'cb 10/28/2026 00:15'!
ensureMethodIsCogged: methodObj maybeClosure: maybeClosure
	"Return a cogged method for methodObj, for mapping a machine-code pc of a baseline frame or divorced context.
	 If methodObj's header is a Dispatcher, answer its baseline CogMethod."
	<returnTypeC: #'CogMethod *'>
	| rawHeader cogMethod yetToCompact |
	<var: #cogMethod type: #'CogMethod *'>
	<inline: false>
	rawHeader := self rawHeaderOf: methodObj.
	(self isCogMethodReference: rawHeader) ifTrue:
		[cogMethod := self cCoerceSimple: rawHeader to: #'CogMethod *'.
		 (cogit isOilDispatcher: cogMethod) ifTrue:
			[^cogit oilBaselineOfDispatcher: cogMethod].
		 ^cogMethod].
	yetToCompact := true.
	[cogMethod := (maybeClosure ~= objectMemory nilObject and: [(self isVanillaBlockClosure: maybeClosure) not])
					ifTrue: [cogit cogFullBlockMethod: methodObj numCopied: (self copiedValueCountOfFullClosure: maybeClosure)]
					ifFalse: [cogit cog: methodObj selector: objectMemory nilObject].
	 cogMethod == nil
	 and: [cogCompiledCodeCompactionCalledFor
	 and: [yetToCompact]]] whileTrue:
		[yetToCompact := false.
		 self commenceCogCompiledCodeCompaction].
	(self asserta: cogMethod ~= nil) ifFalse:
		[self error: 'could not compile method that should have been compiled'].
	^cogMethod! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-specialization' stamp: 'cb 10/28/2026 05:00'!
divorceMachineCodeFramesWithMethod: methodObj
	"Divorce all machine-code frames of methodObj: if methodObj has a Dispatcher, first deoptimize any suspended frames
	 of its Oil specializations into contexts, then divorce the frames of its baseline CogMethod.
	 Deoptimizing the last frame of a specialization frees it and compacts it out of the Dispatcher (moving the cases
	 above it down, and freeing the Dispatcher when it was the last one), so read the baseline first and visit the cases
	 from the highest down."
	| aPage theFP calleeFP theSP theIP cogMethod specTarget baseline |
	<var: #aPage type: #'StackPage *'>
	<var: #theFP type: #'char *'>
	<var: #calleeFP type: #'char *'>
	<var: #theSP type: #'char *'>
	<var: #cogMethod type: #'CogMethod *'>
	<var: #specTarget type: #'CogMethod *'>
	<var: #baseline type: #'CogMethod *'>
	cogMethod := self cogMethodOf: methodObj.
	(cogit isOilDispatcher: cogMethod) ifTrue:
		[baseline := cogit oilBaselineOfDispatcher: cogMethod.
		 (cogit oilDispatcherNumCases: cogMethod) to: 1 by: -1 do:
			[:i|
			specTarget := cogit oilDispatcher: cogMethod targetAt: i.
			specTarget cmType = CMMethod ifTrue:
				[self oilDeoptimizeFramesOf: specTarget]].
		 cogMethod := baseline].
	(cogit isOilMethod: cogMethod) ifTrue:
		[self oilDeoptimizeFramesOf: cogMethod.
		 ^self].
	0 to: numStackPages - 1 do:
		[:i|
		aPage := stackPages stackPageAt: i.
		(stackPages isFree: aPage) ifFalse:
			[theFP := aPage headFP.
			 theSP := aPage headSP.
			 theIP := (stackPages longAt: theSP) asUnsignedInteger.
			 theSP := theSP + objectMemory wordSize.
			 [(self isMachineCodeFrame: theFP) ifTrue:
				[(self mframeHomeMethod: theFP) = cogMethod ifTrue:
					[self externalDivorceFrame: theFP andContext: (self ensureFrameIsMarried: theFP SP: theSP).
					 "Restart page scan after splitting stack page"
					 theFP := aPage headFP.
					 theSP := aPage headSP.
					 theIP := (stackPages longAt: theSP) asUnsignedInteger.
					 theSP := theSP + objectMemory wordSize]].
			  calleeFP := theFP.
			  theFP := self frameCallerFP: theFP.
			  theFP ~= 0] whileTrue:
				[theIP := (self frameCallerSavedIP: calleeFP) asUnsignedInteger.
				 theSP := self frameCallerSP: calleeFP]]]! !

!CoInterpreter methodsFor: '*VMMaker-JIT-Oil-specialization' stamp: 'cb 10/28/2026 00:15'!
oilFreeMachineCodeOf: methodObj
	"Free the machine code of methodObj, if any (c.f. primitiveVoidVMStateForMethod): its frames are divorced and its
	 contexts get bytecode pcs.  The caller has married the current frame (see oilMarryActiveFrame)."
	<api>
	<essential: #ProfilingCogit>
	self flushMethodCacheForMethod: methodObj.
	(self methodHasCogMethod: methodObj) ifTrue:
		[self divorceMachineCodeFramesWithMethod: methodObj.
		 self ensureAllContextsWithMethodHaveBytecodePCs: methodObj.
		 cogit unlinkSendsTo: methodObj andFreeIf: true]! !


!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/28/2026 00:15'!
primitiveOilSpecialize
	"Receiver: a CompiledMethod; argument: a class.  Compile an Oil version of the method specialized for receivers of the
	 class, in addition to its other specializations (at most OilMaxSpecialization) and to its baseline machine code, which
	 keeps running the receivers of every other class.  The method's header is bound to a dedicated Dispatcher whose Cases
	 1..oilDispatcherNumCases: jump to the Oil specializations and whose fall-through last case at
	 oilDispatcherEndOfCodeOffset jumps to the baseline CogMethod (which is never freed or recompiled); sends targeting the
	 baseline CogMethod are unlinked so they relink directly to the matching specialization or baseline CogMethod.
	 Answer OilOK (0) or an Oil failure code."
	<export: true>
	<essential: #ProfilingCogit>
	| methodObj classObj classTag result |
	argumentCount ~= 1 ifTrue:
		[^self primitiveFailFor: PrimErrBadNumArgs].
	methodObj := self stackValue: 1.
	classObj := self stackTop.
	((objectMemory isNonImmediate: methodObj)
	 and: [(objectMemory isOopCompiledMethod: methodObj)
	 and: [(self isFullBlockMethod: methodObj) not
	 and: [objectMemory isNonImmediate: classObj]]]) ifFalse:
		[^self primitiveFailFor: PrimErrBadArgument].
	"Oil code of the method itself (primitiveOilCompile) cannot be specialized."
	((self methodHasCogMethod: methodObj)
	 and: [cogit isOilMethod: (self cogMethodOf: methodObj)]) ifTrue:
		[^self pop: 2 thenPush: (objectMemory integerObjectOf: OilFailSpecialization)].
	classTag := objectMemory classTagForClass: classObj.
	(cogit oilSpecializedCogMethodOf: methodObj tag: classTag) ~= nil ifTrue:
		[^self pop: 2 thenPush: (objectMemory integerObjectOf: OilOK)].
	(cogit oilNumSpecializationsOf: methodObj) >= cogit oilMaxSpecialization ifTrue:
		[^self pop: 2 thenPush: (objectMemory integerObjectOf: OilFailSpecialization)].
	self oilEnsureExtraSelectorTable ifFalse:
		[^self primitiveFailFor: PrimErrNoMemory].
	(self methodHasCogMethod: methodObj) ifFalse:
		[cogit cog: methodObj selector: objectMemory nilObject.
		 (self methodHasCogMethod: methodObj) ifFalse:
			[^self pop: 2 thenPush: (objectMemory integerObjectOf: OilFailCodeSpace)]].
	result := cogit oilCompile: methodObj receiverClass: classObj.
	result ~= OilOK ifTrue:
		[^self pop: 2 thenPush: (objectMemory integerObjectOf: result)].
	result := cogit oilGenerateSpecialized: methodObj tag: classTag.
	result = OilOK ifTrue:
		[self flushMethodCacheForMethod: methodObj].
	self pop: 2 thenPush: (objectMemory integerObjectOf: result)! !

!CoInterpreterPrimitives methodsFor: '*VMMaker-JIT-Oil-primitives' stamp: 'cb 10/28/2026 00:15'!
primitiveOilSpecializations
	"Receiver: a CompiledMethod.  Answer an Array of pairs { class. method } for its live Oil specializations in its
	 Dispatcher (see primitiveOilSpecialize)."
	<export: true>
	<essential: #ProfilingCogit>
	| methodObj dispatcher numSpecs result count classTag |
	<var: #dispatcher type: #'CogMethod *'>
	methodObj := self stackTop.
	((objectMemory isNonImmediate: methodObj)
	 and: [objectMemory isOopCompiledMethod: methodObj]) ifFalse:
		[^self primitiveFailFor: PrimErrBadReceiver].
	numSpecs := cogit oilNumSpecializationsOf: methodObj.
	result := objectMemory instantiateClass: (objectMemory splObj: ClassArray) indexableSize: 2 * numSpecs.
	result isNil ifTrue:
		[^self primitiveFailFor: PrimErrNoMemory].
	numSpecs > 0 ifTrue:
		[dispatcher := self cogMethodOf: methodObj.
		 count := 0.
		 1 to: numSpecs do:
			[:caseIndex|
			classTag := cogit oilDispatcher: dispatcher tagAt: caseIndex.
			objectMemory
				storePointer: count ofObject: result withValue: (objectMemory classOrNilAtIndex: classTag);
				storePointer: count + 1 ofObject: result withValue: methodObj.
			count := count + 2]].
	self pop: argumentCount + 1 thenPush: result! !
