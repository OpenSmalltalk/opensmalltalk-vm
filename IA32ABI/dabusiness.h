/*
 * Copyright 2008 Cadence Design Systems, Inc.
 * 
 * Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
 */
/*
 *  dabusiness.h
 *
 *  Written by Eliot Miranda 11/07.
 *
 * Body of the various callIA32XXXReturn functions.
 * Call a foreign function according to IA32-ish ABI rules.
 */
	long i, size;
	sqInt funcAlien, resultMaybeAlien;
	char *argvec;
#if STACK_ALIGN_BYTES
	char *argstart;
#endif

	EnsureHaveVMThreadID();

	for (i = numArgs, size = 0; --i >= 0;) {
		sqInt arg = argVector[i];
		if (objIsAlien(arg) && sizeField(arg))
			size += moduloPOT(sizeof(long),abs(sizeField(arg)));
		else /* assume an integer or pointer.  check below. */
			size += sizeof(long);
	}

#if STACK_ALIGN_BYTES
	/* At point of call stack must be aligned to STACK_ALIGN_BYTES.  So alloca
	 * at least enough for this plus the argvector, and start writing argvector
	 * at aligned point.  Then just prior to call cut-back stack to aligned.
	 */
	argvec = alloca(STACK_ALIGN_BYTES + moduloPOT(STACK_ALIGN_BYTES,size));
	argvec = alignModuloPOT(STACK_ALIGN_BYTES, argvec);
	argstart = argvec;
#else
	argvec = alloca(moduloPOT(sizeof(long),size));
# if defined(__MINGW32__) && (__GNUC__ >= 3)
	/*
	 * cygwin & MinGW's gcc 3.4.x's alloca is a library routine that answers
	 * %esp + 4, so the outgoing stack is offset by one word if uncorrected.
	 * Grab the actual stack pointer to correct.
	 */
	getsp(argvec);
# endif
#endif

	for (i = 0; i < numArgs; i++) {
		sqInt arg = argVector[i];
		if (isSmallInt(arg)) {
			*(long *)argvec = intVal(arg);
			argvec += sizeof(long);
		}
		else if (objIsAlien(arg)) {
			long  argByteSize;

			if (!(size = sizeField(arg)))
				size = argByteSize = sizeof(void *);
			else
				argByteSize = abs(size);
			memcpy(argvec, startOfDataWithSize(arg,size), argByteSize);
			argvec += moduloPOT(sizeof(long), argByteSize);
		}
		else if (objIsUnsafeAlien(arg)) {
			sqInt bitsObj = interpreterProxy->fetchPointerofObject(0,arg);
			void *v = interpreterProxy->firstIndexableField(bitsObj);
			*(void **)argvec = v;
			argvec += sizeof(long);
		}
		else {
			long v = interpreterProxy->signed32BitValueOf(arg);
			if (interpreterProxy->failed())
				return PrimErrBadArgument;
			*(long *)argvec = v;
			argvec += sizeof(long);
		}
	}

	funcAlien = interpreterProxy->stackValue(funcOffset);
	f = *(void **)startOfParameterData(funcAlien);
#if STACK_ALIGN_BYTES
	/* cut stack back to start of aligned args */
	setsp(argstart);
#endif
	r = f();
	/* post call need to refresh stack pointer in case of call-back and GC. */
	resultMaybeAlien = interpreterProxy->stackValue(resultOffset);
	if (objIsAlien(resultMaybeAlien)) {
		if (!(size = sizeField(resultMaybeAlien)))
			size = sizeof(void *);
		memcpy(startOfDataWithSize(resultMaybeAlien,size),
				&r,
				min(abs(size), sizeof(r)));
	}

	return PrimErrNoErr;
