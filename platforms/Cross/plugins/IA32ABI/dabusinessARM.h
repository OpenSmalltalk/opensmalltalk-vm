/*
 *  dabusinessARM.h
 *
 * Ryan Macnak, Eliot Miranda, 7/15
 * Updated for aarch64/arm64 by Ken Dickey 26 Dec 2018
 *
 * Body of the various callIA32XXXReturn functions.
 * Call a foreign function according to ARM-ish ABI rules.
 * N.B. In Cog Stack and Cogit VMs numArgs is negative to access args from
 * the downward-growing stack.
 */

	long i;
	long size;
	long nextReg;
	long nextDReg;
	sqInt regs[NUM_REG_ARGS];
	double dregs[NUM_DREG_ARGS];
	sqInt funcAlien;
	sqInt resultMaybeAlien;
	sqInt argvec;
	sqInt argstart;

	assert(sizeof(sqInt) == sizeof(void*));

	if (numArgs < 0) {
		/* Stack or Cog VM. Need to access args downwards from first arg. */
		for (i = size = 0; --i >= numArgs;) {
			sqInt arg = argVector[i + 1];
			if (objIsAlien(arg) && (sizeField(arg) != 0))
				/* Direct or indirect Alien. */
				size += RoundUpPowerOfTwo(labs(sizeField(arg)), sizeof(sqInt));
			else if (interpreterProxy->isFloatObject(arg))
				size += sizeof(double);
			else 
				/* Assume an integer or pointer Alien. Check below. */
				size += sizeof(sqInt);
		}
	}
	else {
		/* Context Interpreter or array version of callout primitive. */
		for (i = numArgs, size = 0; --i >= 0;) {
			sqInt arg = argVector[i];
			if (objIsAlien(arg) && (sizeField(arg) != 0))
				/* Direct or indirect Alien. */
				size += RoundUpPowerOfTwo(labs(sizeField(arg)), sizeof(sqInt));
			else if (interpreterProxy->isFloatObject(arg))
				size += sizeof(double);
			else
				/* Assume an integer or pointer Alien. Check below. */
				size += sizeof(sqInt);
		}
	}

	argstart = argvec = (sqInt)alloca(size);

	assert(IsAlignedPowerOfTwo(argvec, STACK_ALIGN_BYTES));

	nextReg = 0;
	nextDReg = 0;

#define MaybePassAsRegArg(expr) \
	if (nextReg < NUM_REG_ARGS) \
		regs[nextReg++] = expr; \
	else { \
		*(sqInt*)argvec = expr; \
		argvec += sizeof(sqInt); \
	}

#define MaybePassAsDRegArg(expr) \
	if (nextDReg < NUM_DREG_ARGS) \
		dregs[nextDReg++] = expr; \
	else { \
		argvec = RoundUpPowerOfTwo(argvec, sizeof(double)); \
		*(double*) argvec = expr; \
		argvec += sizeof(double); \
	}

	if (numArgs < 0) {
		/* Stack or Cog VM. Need to access args downwards from first arg. */
		for (i = size = 0; --i >= numArgs;) {
			sqInt arg = argVector[i+1];
			if (isSmallInt(arg)) {
				MaybePassAsRegArg(intVal(arg))
			}
			else if (objIsAlien(arg)) {
				sqInt argByteSize;
				if ((size = sizeField(arg)) == 0) /* Pointer Alien. */
					size = argByteSize = sizeof(void *);
				else /* Direct or indirect Alien. */
					argByteSize = labs(size);
				/* TODO(rmacnak): Structs larger than word size should be split
				 * between remaining registers and the stack.
				 */
				if ((argByteSize <= sizeof(sqInt)) && (nextReg < NUM_REG_ARGS)) {
					regs[nextReg++] = *(sqInt*)startOfDataWithSize(arg, size);
				}
				else {
					memcpy((void*)argvec, startOfDataWithSize(arg, size), argByteSize);
					argvec += RoundUpPowerOfTwo(argByteSize, sizeof(sqInt));
				}
			}
			else if (objIsUnsafeAlien(arg)) {
				sqInt bitsObj = interpreterProxy->fetchPointerofObject(0,arg);
				sqInt v = (sqInt)interpreterProxy->firstIndexableField(bitsObj);
				MaybePassAsRegArg(v)
			}
			else if (interpreterProxy->isFloatObject(arg)) {
				double d = interpreterProxy->floatValueOf(arg);
				MaybePassAsDRegArg(d)
			}
			else {
				sqInt v = interpreterProxy->signedMachineIntegerValueOf(arg);
				if (interpreterProxy->failed()) {
					interpreterProxy->primitiveFailFor(0);
					v = interpreterProxy->positiveMachineIntegerValueOf(arg);
					if (interpreterProxy->failed()) {
						return PrimErrBadArgument;
					}
				}
				MaybePassAsDRegArg(v)
			}
		}
	}
	else {
		/* Context Interpreter or array version of callout primitive. */
		for (i = 0; i < numArgs; i++) {
			sqInt arg = argVector[i];
			if (isSmallInt(arg))
				MaybePassAsDRegArg(intVal(arg))
			else if (objIsAlien(arg)) {
				sqInt argByteSize;
				if ((size = sizeField(arg)) == 0) /* Pointer Alien. */
					size = argByteSize = sizeof(void *);
				else /* Direct or indirect Alien. */
					argByteSize = labs(size);
				/* TODO(rmacnak): Structs larger than word size should be split between
					 remaining registers and the stack. */
				if ((argByteSize <= sizeof(sqInt)) && (nextReg < NUM_REG_ARGS)) {
					regs[nextReg++] = *(sqInt*)startOfDataWithSize(arg, size);
				}
				else {
					memcpy((void*)argvec, startOfDataWithSize(arg, size), argByteSize);
					argvec += RoundUpPowerOfTwo(argByteSize, sizeof(sqInt));
				}
			}
			else if (objIsUnsafeAlien(arg)) {
				sqInt bitsObj = interpreterProxy->fetchPointerofObject(0,arg);
				sqInt v = (sqInt)interpreterProxy->firstIndexableField(bitsObj);
				MaybePassAsRegArg(v)
			}
			else if (interpreterProxy->isFloatObject(arg)) {
				double d = interpreterProxy->floatValueOf(arg);
				MaybePassAsDRegArg(d)
			}
			else {
				sqInt v = interpreterProxy->signedMachineIntegerValueOf(arg);
				if (interpreterProxy->failed()) {
					interpreterProxy->primitiveFailFor(0);
					v = interpreterProxy->positiveMachineIntegerValueOf(arg);
					if (interpreterProxy->failed()) {
						return PrimErrBadArgument;
					}
				}
				MaybePassAsRegArg(v)
			}
		}
	}

	funcAlien = interpreterProxy->stackValue(funcOffset);
	f = *(void**)startOfParameterData(funcAlien);

	/* Note that this call a) passes the integer reg args in regs in the core
	 * integer registers, and b) passes the floating point args in dregs in the
	 * floating-point co-processor registers.  Neat.
	 */
	r = f(regs[0], regs[1], regs[2], regs[3],
#if NUM_REG_ARGS > 4
		  regs[4], regs[5], regs[6], regs[7],
#endif
		  dregs[0], dregs[1], dregs[2], dregs[3],
		  dregs[4], dregs[5], dregs[6], dregs[7]);

	/* Post call need to refresh stack pointer in case of call-back and GC. */
	resultMaybeAlien = interpreterProxy->stackValue(resultOffset);
	if (objIsAlien(resultMaybeAlien)) {
		size = sizeField(resultMaybeAlien);
		if (size == 0) /* Pointer Alien. */
			size = sizeof(sqInt);
		memcpy(startOfDataWithSize(resultMaybeAlien, size),
			   &r,
			   min((usqInt)labs(size), sizeof(r)));
	}

	return PrimNoErr;
