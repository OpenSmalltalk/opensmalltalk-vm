/*
 *  dax64business.h
 *
 *  Written by Eliot Miranda 12/14, Ryan Macnak 9/15
 *
 * Body of the various callIA32XXXReturn functions.
 * Call a foreign function according to x64-ish ABI rules.
 * N.B. In Cog Stack and Cogit VMs numArgs is negative to access args from
 * the downward-growing stack.
 */

	long i;
	long size;
	long nextReg;
	long nextDReg;
	long regs[NUM_REG_ARGS];
	double dregs[NUM_DREG_ARGS];
	sqInt funcAlien;
	sqInt resultMaybeAlien;
	long argvec;
	long argstart;

        assert(sizeof(long) == sizeof(void*)); /* Will need to fix for Windows. */

	if (numArgs < 0) {
		/* Stack or Cog VM. Need to access args downwards from first arg. */
		for (i = size = 0; --i >= numArgs;) {
			sqInt arg = argVector[i + 1];
			if (objIsAlien(arg) && (sizeField(arg) != 0))
				/* Direct or indirect Alien. */
                        	size += RoundUpPowerOfTwo(SQABS(sizeField(arg)), 8);
			else if (interpreterProxy->isFloatObject(arg))
				size += sizeof(double);
			else 
				/* Assume an integer or pointer Alien. Check below. */
				size += sizeof(long);
		}
	}
	else {
		/* Context Interpreter or array version of callout primitive. */
		for (i = numArgs, size = 0; --i >= 0;) {
			sqInt arg = argVector[i];
			if (objIsAlien(arg) && (sizeField(arg) != 0))
				/* Direct or indirect Alien. */
                          size += RoundUpPowerOfTwo(SQABS(sizeField(arg)), 8);
			else if (interpreterProxy->isFloatObject(arg))
				size += sizeof(double);
			else
				/* Assume an integer or pointer Alien. Check below. */
				size += sizeof(long);
		}
	}

	size = RoundUpPowerOfTwo(size, STACK_ALIGN_BYTES);

	argstart = argvec = (long)alloca(size);

	nextReg = 0;
	nextDReg = 0;

#define MaybePassAsRegArg(expr) \
	if (nextReg < NUM_REG_ARGS) \
		regs[nextReg++] = expr; \
	else { \
        	*(long*)argvec = expr;        \
		argvec += sizeof(long); \
	}

#define MaybePassAsDRegArg(expr) \
	if (nextDReg < NUM_DREG_ARGS) \
		dregs[nextDReg++] = expr; \
	else { \
 		argvec = RoundUpPowerOfTwo(argvec, 8);  \
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
				long argByteSize;
				if ((size = sizeField(arg)) == 0) /* Pointer Alien. */
					size = argByteSize = sizeof(void *);
				else /* Direct or indirect Alien. */
					argByteSize = labs(size);
				if ((argByteSize <= sizeof(long)) && (nextReg < NUM_REG_ARGS)) {
					regs[nextReg++] = *(long*)startOfDataWithSize(arg, size);
				}
				else {
					memcpy((void*)argvec, startOfDataWithSize(arg, size), argByteSize);
					argvec += RoundUpPowerOfTwo(argByteSize, 8);
				}
			}
			else if (objIsUnsafeAlien(arg)) {
				sqInt bitsObj = interpreterProxy->fetchPointerofObject(0,arg);
				long v = (long)interpreterProxy->firstIndexableField(bitsObj);
				MaybePassAsRegArg(v)
			}
			else if (interpreterProxy->isFloatObject(arg)) {
				double d = interpreterProxy->floatValueOf(arg);
				MaybePassAsDRegArg(d)
			}
			else {
				long v = interpreterProxy->signed64BitValueOf(arg);
				if (interpreterProxy->failed()) {
					interpreterProxy->primitiveFailFor(0);
					v = interpreterProxy->positive64BitValueOf(arg);
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
				long argByteSize;
				if ((size = sizeField(arg)) == 0) /* Pointer Alien. */
					size = argByteSize = sizeof(void *);
				else /* Direct or indirect Alien. */
					argByteSize = labs(size);
				if ((argByteSize <= sizeof(long)) && (nextReg < NUM_REG_ARGS)) {
					regs[nextReg++] = *(long*)startOfDataWithSize(arg, size);
				}
				else {
					memcpy((void*)argvec, startOfDataWithSize(arg, size), argByteSize);
					argvec += RoundUpPowerOfTwo(argByteSize, 8);
				}
			}
			else if (objIsUnsafeAlien(arg)) {
				sqInt bitsObj = interpreterProxy->fetchPointerofObject(0,arg);
				long v = (long)interpreterProxy->firstIndexableField(bitsObj);
				MaybePassAsRegArg(v)
			}
			else if (interpreterProxy->isFloatObject(arg)) {
				double d = interpreterProxy->floatValueOf(arg);
				MaybePassAsDRegArg(d)
			}
			else {
				long v = interpreterProxy->signed64BitValueOf(arg);
				if (interpreterProxy->failed()) {
					interpreterProxy->primitiveFailFor(0);
					v = interpreterProxy->positive64BitValueOf(arg);
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
     *
	 * But this trick WILL NOT WORK on the Windows ABI. The first integer
	 * argument allocates both the first integer register and the first float
	 * register, and vice versa. This means the call below would pass all the
	 * double arguments on the stack, which is not correct if there are double
	 * arguments among the first four arguments.  Instead we will have to make
	 * two separate calls, the first a call of a dummy function to load the
	 * double arguments (if any) and the second to make the actual call.
	 */
	r = f(regs[0], regs[1], regs[2], regs[3], regs[4], regs[5],
		  dregs[0], dregs[1], dregs[2], dregs[3],
		  dregs[4], dregs[5], dregs[6], dregs[7]);

	/* Post call need to refresh stack pointer in case of call-back and GC. */
	resultMaybeAlien = interpreterProxy->stackValue(resultOffset);
	if (objIsAlien(resultMaybeAlien)) {
		size = sizeField(resultMaybeAlien);
		if (size == 0) /* Pointer Alien. */
			size = sizeof(long);
		memcpy(startOfDataWithSize(resultMaybeAlien, size),
			   &r,
			   min((unsigned long)labs(size), sizeof(r)));
	}

	return PrimNoErr;
