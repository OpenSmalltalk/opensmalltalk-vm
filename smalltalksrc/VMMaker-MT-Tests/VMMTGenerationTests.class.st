Class {
	#name : #VMMTGenerationTests,
	#superclass : #TestCase,
	#instVars : [
		'vm'
	],
	#category : #'VMMaker-MT-Tests'
}

{ #category : #tests }
VMMTGenerationTests >> generate: aSelector [
	| codeGenerator |
	codeGenerator := CCodeGeneratorGlobalStructure new.
	codeGenerator vmClass: CoInterpreter.
	codeGenerator addClass: InterpreterPrimitives.
	codeGenerator addClass: StackInterpreterPrimitives.
	codeGenerator addClass: StackInterpreter.
	codeGenerator addClass: CoInterpreter.
	codeGenerator addClass: CogStackPages.
	codeGenerator addClass: SpurMemoryManager.
	codeGenerator addClass: Spur64BitMemoryManager.
	codeGenerator addClass: SpurGenerationScavenger.
	codeGenerator inferTypesForImplicitlyTypedVariablesAndMethods.
	
	(codeGenerator methodNamed: aSelector) export: true.
	codeGenerator retainMethods: { aSelector }.
	codeGenerator prepareMethods.
	codeGenerator doInlining: true.
		
	^ codeGenerator cCodeForMethod: aSelector
]

{ #category : #tests }
VMMTGenerationTests >> testGenerateActiveProcess [

	| result |
	result := self generate: #activeProcess.
	
	self assert: (self withoutComments: result) equals: (self withoutComments: '

/*	Answer the current activeProcess. */
/*	useful for VM debugging */

	/* StackInterpreter>>#activeProcess */
EXPORT(sqInt)
activeProcess(void)
{
    sqInt objOop;
    sqInt objOop1;

	/* begin memoryActiveProcess */
	objOop1 = longAt((GIV(specialObjectsOop) + BaseHeaderSize) + (((sqInt)((usqInt)(SchedulerAssociation) << (shiftForWord())))));
	objOop = longAt((objOop1 + BaseHeaderSize) + (((sqInt)((usqInt)(ValueIndex) << (shiftForWord())))));
	return longAt((objOop + BaseHeaderSize) + (((sqInt)((usqInt)(ActiveProcessIndex) << (shiftForWord())))));
}
')
]

{ #category : #tests }
VMMTGenerationTests >> testGenerateMethodWithInlinedComment [

	| result |
	result := self generate: #imageSegmentVersion.
	
	self assert: result equals: '

/*	a more complex version that tells both the word reversal and the
	endianness of the machine
	it came from. Low half of word is e.g. 6521. Top byte is top byte of
	#doesNotUnderstand: on
	this machine. ($d on the Mac or $s on the PC) */

	/* SpurMemoryManager>>#imageSegmentVersion */
EXPORT(sqInt)
imageSegmentVersion(void)
{
    int wholeWord;


	/* first data word, ''does'' */
	wholeWord = long32At((longAt((GIV(specialObjectsOop) + BaseHeaderSize) + (((sqInt)((usqInt)(SelectorDoesNotUnderstand) << (shiftForWord())))))) + BaseHeaderSize);
	return 68021 /* imageFormatVersion */ | (wholeWord & 0xFF000000U);
}
'
]

{ #category : #tests }
VMMTGenerationTests >> testGeneratePrimitiveVMParameter [

	| result |
	result := self generate: #primitiveVMParameter.
	
	self assert: result equals: '

/*	Behaviour depends on argument count:
	0 args:	return an Array of VM parameter values;
	1 arg:	return the indicated VM parameter;
	2 args:	set the VM indicated parameter.
	VM parameters are numbered as follows:
	1	end (v3)/size(Spur) of old-space (0-based, read-only)
	2	end (v3)/size(Spur) of young/new-space (read-only)
	3	end (v3)/size(Spur) of heap (read-only)
	4	nil (was allocationCount (read-only))
	5	nil (was allocations between GCs (read-write)
	6	survivor count tenuring threshold (read-write)
	7	full GCs since startup (read-only)
	8	total milliseconds in full GCs since startup (read-only)
	9	incremental GCs (SqueakV3) or scavenges (Spur) since startup (read-only)
	10	total milliseconds in incremental GCs (SqueakV3) or scavenges (Spur)
	since startup (read-only)
	11	tenures of surving objects since startup or reset (read-write)
	12-20 were specific to ikp''s JITTER VM, now 12-15 are open for use
	16	total microseconds at idle since start-up (if non-zero)
	17	fraction of the code zone to use (Sista only; used to control code zone
	use to preserve sendAndBranchData on counter tripped callback)
	18	total milliseconds in compaction phase of full GC since start-up (Spur
	only) 19	scavenge threshold, the effective size of eden. When eden fills
	to the threshold a scavenge is scheduled. Newer Spur VMs only.
	20	utc microseconds at VM start-up (actually at time initialization, which
	precedes image load).
	21	root/remembered table size (occupancy) (read-only)
	22	root table overflows since startup (read-only)
	23	bytes of extra memory to reserve for VM buffers, plugins, etc (stored
	in image file header).
	24	memory threshold above which shrinking object memory (rw)
	25	memory headroom when growing object memory (rw)
	26	interruptChecksEveryNms - force an ioProcessEvents every N milliseconds
	(rw) 27	number of times mark loop iterated for current IGC/FGC (read-only)
	includes ALL marking
	28	number of times sweep loop iterated for current IGC/FGC (read-only)
	29	number of times make forward loop iterated for current IGC/FGC
	(read-only) 30	number of times compact move loop iterated for current
	IGC/FGC (read-only)
	31	number of grow memory requests (read-only)
	32	number of shrink memory requests (read-only)
	33	number of root table entries used for current IGC/FGC (read-only)
	34	Spur: bytes allocated in total since start-up or reset (read-write)
	(Used to be number of allocations done before current IGC/FGC (read-only))
	35	number of survivor objects after current IGC/FGC (read-only)
	36	millisecond clock when current IGC/FGC completed (read-only)
	37	number of marked objects for Roots of the world, not including Root
	Table entries for current IGC/FGC (read-only)
	38	milliseconds taken by current IGC (read-only)
	39	Number of finalization signals for Weak Objects pending when current
	IGC/FGC completed (read-only)
	40	BytesPerOop for this image
	41	imageFormatVersion for the VM
	42	number of stack pages in use
	43	desired number of stack pages (stored in image file header, max 65535)
	44	size of eden, in bytes
	45	desired size of eden, in bytes (stored in image file header)
	46	machine code zone size, in bytes (Cog only; otherwise nil)
	47	desired machine code zone size (stored in image file header; Cog only;
	otherwise nil)
	48	various header flags. See getCogVMFlags.
	49	max size the image promises to grow the external semaphore table to (0
	sets to default, which is 256 as of writing)
	50-51 nil; reserved for VM parameters that persist in the image (such as
	eden above)
	52	root/remembered table capacity
	53	number of segments (Spur only; otherwise nil)
	54	total size of free old space (Spur only, otherwise nil)
	55	ratio of growth and image size at or above which a GC will be performed
	post scavenge
	56	number of process switches since startup (read-only)
	57	number of ioProcessEvents calls since startup (read-only)
	58	number of ForceInterruptCheck calls since startup (read-only)
	59	number of check event calls since startup (read-only)
	60	number of stack page overflows since startup (read-only)
	61	number of stack page divorces since startup (read-only)
	62	compiled code compactions since startup (read-only; Cog only; otherwise
	nil) 63	total milliseconds in compiled code compactions since startup
	(read-only; Cog only; otherwise nil)
	64	the number of methods that currently have jitted machine-code
	65	whether the VM supports a certain feature, MULTIPLE_BYTECODE_SETS is
	bit 0, IMMUTABILITY is bit 1
	66	the byte size of a stack page
	67	the max allowed size of old space (Spur only; nil otherwise; 0 implies
	no limit except that of the underlying platform)
	68	the average number of live stack pages when scanned by GC (at
	scavenge/gc/become et al) (read-write)
	69	the maximum number of live stack pages when scanned by GC (at
	scavenge/gc/become et al) (read-write)
	70	the vmProxyMajorVersion (the interpreterProxy VM_MAJOR_VERSION)
	71	the vmProxyMinorVersion (the interpreterProxy VM_MINOR_VERSION)
	72 total milliseconds in full GCs Mark phase since startup (read-only)
	73 total milliseconds in full GCs Sweep phase since startup (read-only,
	can be 0 depending on compactors)
	74 maximum pause time due to segment allocation
	
	Note: Thanks to Ian Piumarta for this primitive. */

	/* StackInterpreterPrimitives>>#primitiveVMParameter */
EXPORT(void)
primitiveVMParameter(void)
{
    double aDouble;
    double aFloat;
    double aProportion;
    sqInt arg;
    sqInt argOop;
    sqLong delta;
    sqInt index;
    sqInt offset;
    sqInt oop;
    sqInt paramsArraySize;
    sqInt result;
    sqInt result1;
    char *sp;
    char *sp1;
    sqInt tagBits;

	paramsArraySize = 74;
	if (GIV(argumentCount) == 0) {
		primitiveAllVMParameters(paramsArraySize);
		return;
	}
	if (GIV(argumentCount) > 2) {
		/* begin primitiveFailFor: */
		GIV(primFailCode) = PrimErrBadNumArgs;
		return;
	}
	/* begin stackValue: */
	offset = (GIV(argumentCount) == 1
		? 0
		: 1);
	index = longAt(GIV(stackPointer) + (offset * BytesPerWord));
	if (!((((index) & 7) == 1))) {
		/* begin primitiveFailFor: */
		GIV(primFailCode) = PrimErrBadArgument;
		return;
	}
	index = (index >> 3);
	if ((index < 1)
	 || (index > paramsArraySize)) {
		/* begin primitiveFailFor: */
		GIV(primFailCode) = PrimErrBadIndex;
		return;
	}
	if (GIV(argumentCount) == 1) {

		/* read VM parameter; written this way to avoid branch limits in V3 bytecode set */
		result = primitiveGetVMParameter(index);
		/* begin methodReturnValue: */
		oop = (!(result)
			? /* begin nilObject */ GIV(nilObj)
			: result);
		longAtput((sp = GIV(stackPointer) + (((GIV(argumentCount) + 1) - 1) * BytesPerWord)), oop);
		GIV(stackPointer) = sp;
		return;
	}
	/* begin primitiveSetVMParameter:arg: */
	argOop = longAt(GIV(stackPointer));
	if ((index == 17)
	 || ((index == 55)
	 || (index == 68))) {
		if (!(((((tagBits = argOop & (tagMask()))) != 0
				? tagBits == (smallFloatTag())
				: ((longAt(argOop)) & (classIndexMask())) == ClassFloatCompactIndex))
			 || ((((argOop) & 7) == 1)))) {
			/* begin primitiveFailFor: */
			GIV(primFailCode) = PrimErrBadArgument;
			goto l16;
		}
	}
	else {
		if (!((((argOop) & 7) == 1))) {
			/* begin primitiveFailFor: */
			GIV(primFailCode) = PrimErrBadArgument;
			goto l16;
		}
		arg = (argOop >> 3);
	}
	/* begin primitiveFailFor: */
	GIV(primFailCode) = PrimErrBadArgument;
	
	switch (index) {
	case 5:
				break;
	case 6:
		result1 = (((usqInt)(((sqInt)(((scavengerTenuringThreshold()) * ((limit(&GIV(pastSpace))) - (start(&GIV(pastSpace))))) / (8 * BytesPerOop)))) << 3) | 1);
		/* begin tenuringThreshold: */
		if (arg < 0) {
			GIV(primFailCode) = PrimErrBadArgument;
			goto l11;
		}
		/* begin scavengerTenuringThreshold: */
		aProportion = (((double) (arg * (8 * BytesPerOop)) )) / (((double) ((limit(&GIV(pastSpace))) - (start(&GIV(pastSpace)))) ));
		GIV(tenuringProportion) = aProportion;
		GIV(tenureThreshold) = (aProportion == 0.0
			? 0
			: (round((((limit(&GIV(pastSpace))) - (start(&GIV(pastSpace)))) * (1.0 - aProportion)))) + (start(&GIV(pastSpace))));
		GIV(primFailCode) = 0;
	l11:	/* end tenuringThreshold: */;
		break;
	case 11:
		if (arg >= 0) {
			result1 = (((usqInt)GIV(statTenures) << 3) | 1);
			/* begin statTenures: */
			GIV(statTenures) = arg;
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
		}
		break;
	case 17:
				break;
	case 23:
		result1 = (((usqInt)extraVMMemory << 3) | 1);
		extraVMMemory = arg;
		/* begin initPrimCall */
		GIV(primFailCode) = 0;
		break;
	case 24:
		if (arg > 0) {
			result1 = (((usqInt)GIV(shrinkThreshold) << 3) | 1);
			/* begin shrinkThreshold: */
			GIV(shrinkThreshold) = arg;
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
		}
		break;
	case 25:
		if (arg > 0) {
			result1 = (((usqInt)GIV(growHeadroom) << 3) | 1);
			/* begin growHeadroom: */
			GIV(growHeadroom) = arg;
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
		}
		break;
	case 26:
		if (arg >= 0) {

			/* 0 turns off the heartbeat */
			result1 = (((usqInt)(ioHeartbeatMilliseconds()) << 3) | 1);
			ioSetHeartbeatMilliseconds(arg);
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
		}
		break;
	case 34:
		if (arg >= 0) {
			result1 = positive64BitIntegerFor(currentAllocatedBytes());
			/* begin setCurrentAllocatedBytesTo: */
			delta = (currentAllocatedBytes()) - GIV(statAllocatedBytes);
			GIV(statAllocatedBytes) = arg;
			GIV(oldSpaceUsePriorToScavenge) += delta;
			assert((currentAllocatedBytes()) == arg);
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
		}
		break;
	case 43:
		if (((arg >= 0) && (arg <= 0xFFFF))) {
			result1 = (((usqInt)desiredNumStackPages << 3) | 1);
			desiredNumStackPages = arg;
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
		}
		break;
	case 45:
		if (arg >= 0) {
			result1 = (((usqInt)desiredEdenBytes << 3) | 1);
			desiredEdenBytes = arg;
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
		}
		break;
	case 47:
		if (((arg >= 0) && (arg <= (maxCogCodeSize())))) {
			result1 = (((usqInt)(getDesiredCogCodeSize()) << 3) | 1);
			/* begin setDesiredCogCodeSize: */
			desiredCogCodeSize = arg;
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
		}
		break;
	case 48:
		if (arg >= 0) {
			result1 = (((usqInt)(getCogVMFlags()) << 3) | 1);
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
			/* begin setCogVMFlags: */
			if ((((usqInt)arg)) > 0x3F) {
				GIV(primFailCode) = PrimErrUnsupported;
				goto l10;
			}
			GIV(flagInterpretedMethods) = arg & 2;

			/* noThreadingOfGUIThread := flags anyMask: 8.. specific to CoInterpreterMT */
			GIV(preemptionYields) = (arg & 4) == 0;
			GIV(newFinalization) = arg & 16;
			sendWheelEvents = arg & 32;
	l10:	/* end setCogVMFlags: */;
		}
		break;
	case 49:
		if (((arg >= 0) && (arg <= 0xFFFF))) {
			result1 = (((usqInt)(ioGetMaxExtSemTableSize()) << 3) | 1);
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
			/* begin setMaxExtSemSizeTo: */
			GIV(maxExtSemTabSizeSet) = 1;
			ioSetMaxExtSemTableSize(arg);
		}
		break;
	case 55:
		result1 = floatObjectOf(getHeapGrowthToSizeGCRatio());
		/* begin setHeapGrowthToSizeGCRatio: */
		aDouble = noInlineLoadFloatOrIntFrom(argOop);
		GIV(heapGrowthToSizeGCRatio) = aDouble;
		GIV(primFailCode) = 0;
		break;
	case 67:
		if ((arg >= 0)
		 && (1)) {
			result1 = (((maxOldSpaceSize()) << 3) | 1);
			/* begin setMaxOldSpaceSize: */
			maxOldSpaceSize = arg;
			GIV(primFailCode) = 0;
		}
		break;
	case 68:
		result1 = floatObjectOf(statAverageLivePagesWhenMapping());
		/* begin initPrimCall */
		GIV(primFailCode) = 0;
		/* begin statAverageLivePagesWhenMapping: */
		aFloat = noInlineLoadFloatOrIntFrom(argOop);
		if (aFloat == 0.0) {
			GIV(statPageCountWhenMappingSum) = (GIV(statNumMaps) = 0);
		}
		else {
			GIV(primFailCode) = PrimErrBadArgument;
		}
		break;
	case 69:
		if (arg >= 0) {
			result1 = (((usqInt)(statMaxPageCountWhenMapping()) << 3) | 1);
			/* begin statMaxPageCountWhenMapping: */
			GIV(statMaxPageCountWhenMapping) = arg;
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
		}
		break;
	case 74:
		if ((arg >= 0)
		 && (1)) {
			result1 = (((usqInt)((GIV(statMaxAllocSegmentTime) + 500) / 1000) << 3) | 1);
			/* begin statMaxAllocSegmentTime: */
			GIV(statMaxAllocSegmentTime) = arg;
			/* begin initPrimCall */
			GIV(primFailCode) = 0;
		}
		break;
	default:
		;
	}
	if (!GIV(primFailCode)) {

		/* return old value */
		/* begin methodReturnValue: */
		longAtput((sp1 = GIV(stackPointer) + (((GIV(argumentCount) + 1) - 1) * BytesPerWord)), result1);
		GIV(stackPointer) = sp1;
	}
	else {

		/* attempting to write a read-only or non-existent parameter */
		/* begin primitiveFailFor: */
		GIV(primFailCode) = PrimErrInappropriate;
	}
	l16:	/* end primitiveSetVMParameter:arg: */;
}
'
]

{ #category : #tests }
VMMTGenerationTests >> withoutComments: aString [

	^ Character cr join: (aString lines reject: [ :l | | trimmed |
		trimmed := l trimBoth.
		trimmed isEmpty or: [trimmed beginsWith: '/*'] ])
]
