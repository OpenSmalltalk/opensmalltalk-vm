/*
 *  dax64win64business.h
 *
 * Body of the various callIA32XXXReturn functions.
 * Call a foreign function according to x64-ish win64-ish ABI rules.
 * N.B. In Cog Stack and Cogit VMs numArgs is negative to access args from
 * the downward-growing stack.
 */

	long long i;
	long long size;
	long long nextReg;
	int64_or_double regs[NUM_REG_ARGS];
	sqInt funcAlien;
	sqInt resultMaybeAlien;
	long long argvec;
	long long argstart;
    int sig;

    assert(sizeof(long long) == sizeof(void*)); /* Will need to fix for Windows. */

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
				size += sizeof(long long);
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
				size += sizeof(long long);
		}
	}

	size = RoundUpPowerOfTwo(size, STACK_ALIGN_BYTES);

	argstart = argvec = (long long)alloca(size);

	nextReg = 0;
    sig = 0;

#define MaybePassAsRegArg(expr) \
	if (nextReg < NUM_REG_ARGS) \
		regs[nextReg++].i = expr; \
	else { \
        	*(long long*)argvec = expr;        \
		argvec += sizeof(long long); \
	}

#define MaybePassAsDRegArg(expr) \
	if (nextReg < NUM_REG_ARGS) { \
        sig += (1<<nextReg); \
		regs[nextReg++].d = expr; \
	} else { \
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
				long long argByteSize;
				if ((size = sizeField(arg)) == 0) /* Pointer Alien. */
					size = argByteSize = sizeof(void *);
				else /* Direct or indirect Alien. */
					argByteSize = llabs(size);
				if ((argByteSize <= sizeof(long long)) && (nextReg < NUM_REG_ARGS)) {
					regs[nextReg++].i = *(long long*)startOfDataWithSize(arg, size);
				}
				else {
					memcpy((void*)argvec, startOfDataWithSize(arg, size), argByteSize);
					argvec += RoundUpPowerOfTwo(argByteSize, 8);
				}
			}
			else if (objIsUnsafeAlien(arg)) {
				sqInt bitsObj = interpreterProxy->fetchPointerofObject(0,arg);
				long long v = (long long)interpreterProxy->firstIndexableField(bitsObj);
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
				long long argByteSize;
				if ((size = sizeField(arg)) == 0) /* Pointer Alien. */
					size = argByteSize = sizeof(void *);
				else /* Direct or indirect Alien. */
					argByteSize = labs(size);
				if ((argByteSize <= sizeof(long long)) && (nextReg < NUM_REG_ARGS)) {
					regs[nextReg++].i = *(long long*)startOfDataWithSize(arg, size);
				}
				else {
					memcpy((void*)argvec, startOfDataWithSize(arg, size), argByteSize);
					argvec += RoundUpPowerOfTwo(argByteSize, 8);
				}
			}
			else if (objIsUnsafeAlien(arg)) {
				sqInt bitsObj = interpreterProxy->fetchPointerofObject(0,arg);
				long long v = (long long)interpreterProxy->firstIndexableField(bitsObj);
				MaybePassAsRegArg(v)
			}
			else if (interpreterProxy->isFloatObject(arg)) {
				double d = interpreterProxy->floatValueOf(arg);
				MaybePassAsDRegArg(d)
			}
			else {
				long long v = interpreterProxy->signed64BitValueOf(arg);
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

	/* Note that this call pass any combination of int/double parameters in registers.
     */
    switch( sig ) {
        case 0x0:
            f0=*(void**)startOfParameterData(funcAlien);
            r = f0( regs[0].i , regs[1].i , regs[2].i , regs[3].i);
            break;
        case 0x1:
            f1=*(void**)startOfParameterData(funcAlien);
            r = f1( regs[0].d , regs[1].i , regs[2].i, regs[3].i);
            break;
        case 0x2:
            f2=*(void**)startOfParameterData(funcAlien);
            r = f2( regs[0].i , regs[1].d , regs[2].i, regs[3].i);
            break;
        case 0x3:
            f3=*(void**)startOfParameterData(funcAlien);
            r = f3( regs[0].d , regs[1].d , regs[2].i, regs[3].i);
            break;
        case 0x4:
            f4=*(void**)startOfParameterData(funcAlien);
            r = f4( regs[0].i , regs[1].i , regs[2].d , regs[3].i);
            break;
        case 0x5:
            f5=*(void**)startOfParameterData(funcAlien);
            r = f5( regs[0].d , regs[1].i , regs[2].d , regs[3].i);
            break;
        case 0x6:
            f6=*(void**)startOfParameterData(funcAlien);
            r = f6( regs[0].i , regs[1].d , regs[2].d , regs[3].i);
            break;
        case 0x7:
            f7=*(void**)startOfParameterData(funcAlien);
            r = f7( regs[0].d , regs[1].d , regs[2].d , regs[3].i);
            break;
        case 0x8:
            f8=*(void**)startOfParameterData(funcAlien);
            r = f8( regs[0].i , regs[1].i , regs[2].i , regs[3].d);
            break;
        case 0x9:
            f9=*(void**)startOfParameterData(funcAlien);
            r = f9( regs[0].d , regs[1].i , regs[2].i, regs[3].d);
            break;
        case 0xA:
            fA=*(void**)startOfParameterData(funcAlien);
            r = fA( regs[0].i , regs[1].d , regs[2].i, regs[3].d);
            break;
        case 0xB:
            fB=*(void**)startOfParameterData(funcAlien);
            r = fB( regs[0].d , regs[1].d , regs[2].i, regs[3].d);
            break;
        case 0xC:
            fC=*(void**)startOfParameterData(funcAlien);
            r = fC( regs[0].i , regs[1].i , regs[2].d , regs[3].d);
            break;
        case 0xD:
            fD=*(void**)startOfParameterData(funcAlien);
            r = fD( regs[0].d , regs[1].i , regs[2].d , regs[3].d);
            break;
        case 0xE:
            fE=*(void**)startOfParameterData(funcAlien);
            r = fE( regs[0].i , regs[1].d , regs[2].d , regs[3].d);
            break;
        case 0xF:
            fF=*(void**)startOfParameterData(funcAlien);
            r = fF( regs[0].d , regs[1].d , regs[2].d , regs[3].d);
            break;
        default:
            r = 0;
    }

	/* Post call need to refresh stack pointer in case of call-back and GC. */
	resultMaybeAlien = interpreterProxy->stackValue(resultOffset);
	if (objIsAlien(resultMaybeAlien)) {
		size = sizeField(resultMaybeAlien);
		if (size == 0) /* Pointer Alien. */
			size = sizeof(long long);
		memcpy(startOfDataWithSize(resultMaybeAlien, size),
			   &r,
			   min((unsigned long long)llabs(size), sizeof(r)));
	}

	return PrimNoErr;
