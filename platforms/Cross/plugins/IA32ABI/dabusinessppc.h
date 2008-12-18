/*
 * Copyright 2008 Cadence Design Systems, Inc.
 * 
 * Licensed under the Apache License, Version 2.0 (the ''License''); you may not use this file except in compliance with the License.  You may obtain a copy of the License at  http://www.apache.org/licenses/LICENSE-2.0
 */
/*
 *  dabusiness.h
 *
 *  Written by Eliot Miranda 11/07.
 *  Changes by John M McIntosh 12/1/08 to support powerpc
 *
 * Body of the various callIA32XXXReturn functions.
 * Call a foreign function according to IA32-ish ABI rules.
 */
	long i, size;
	double	floatStorageArea[13];
	sqInt funcAlien, resultMaybeAlien;
	char *argvec;
#if STACK_ALIGN_BYTES
	char *argstart;
#endif


	for (i = numArgs, size = 0; --i >= 0;) {
		sqInt arg = argVector[i];
		if (objIsAlien(arg) && sizeField(arg))
			size += moduloPOT(sizeof(long),abs(sizeField(arg)));
		else if (interpreterProxy->isFloatObject(arg)) {
				if (hasTypeArray) 
					size += figureOutFloatSize(typeSignatureArray,i);
				else
					size += sizeof(double);
		}
		else /* assume an integebr or pointer.  check below. */
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
#endif
	gpRegCount = 0;
	fpRegCount = 0;
	
	for (i = 0; i < numArgs; i++) {
		sqInt arg = argVector[i];
		if (isSmallInt(arg)) {
			*(long *)argvec = intVal(arg);
			if (gpRegCount < 8) gpRegCount++;
			argvec += sizeof(long);
		}
		else if (objIsAlien(arg)) {
			long  argByteSize;

			if (!(size = sizeField(arg)))
				size = argByteSize = sizeof(void *);
			else
				argByteSize = abs(size);
			switch (argByteSize) {
				case (1):
					memcpy(argvec+3, startOfDataWithSize(arg,size), argByteSize);
					break;
				case (2):
					memcpy(argvec+2, startOfDataWithSize(arg,size), argByteSize);
					break;
				case (3):
					memcpy(argvec+1, startOfDataWithSize(arg,size), argByteSize);
					break;
				default: 
					memcpy(argvec, startOfDataWithSize(arg,size), argByteSize);
			}
			long internalSructureSize = moduloPOT(sizeof(long), argByteSize);
			if (gpRegCount < 8) gpRegCount += (internalSructureSize+3)/4;
			if (gpRegCount > 8) gpRegCount = 8;

			if (hasTypeArray) {
				double v;
				int sizeOfFloat = figureOutFloatSize(typeSignatureArray,i);
				if (sizeOfFloat > 0) {
					if (sizeOfFloat == sizeof(float)) {
						float fv = *(float*)argvec;
						v = fv;
					} else {
						v = *(double*)argvec;
					}
					if (fpRegCount < 13) {  /* 13 registers for floating point numbers */
						floatStorageArea[fpRegCount++] = v;
					}
				}
			}
			argvec += internalSructureSize;
		}
		else if (interpreterProxy->isFloatObject(arg)) {
			double v = interpreterProxy->floatValueOf(arg);
			if (interpreterProxy->failed())
				return PrimErrBadArgument;
			if (hasTypeArray && figureOutFloatSize(typeSignatureArray,i) == sizeof(float)) {
				float floatv = v;
				*(float *)argvec = floatv;
				argvec += sizeof(float);			
				if (gpRegCount < 8) gpRegCount += 1;
			} else {
				*(double *)argvec = v;
				argvec += sizeof(double);			
				if (gpRegCount < 8) gpRegCount += 2;
			}
			
			if (fpRegCount < 13) {  /* 13 registers for floating point numbers */
				floatStorageArea[fpRegCount++] = v;
			}
			
			if (gpRegCount > 8) gpRegCount = 8;
		}	else if (objIsUnsafeAlien(arg)) {
			sqInt bitsObj = interpreterProxy->fetchPointerofObject(0,arg);
				void *v = interpreterProxy->firstIndexableField(bitsObj);
				*(void **)argvec = v;
				if (gpRegCount < 8) gpRegCount++;
				argvec += sizeof(long);
		}else {
			long v = interpreterProxy->signed32BitValueOf(arg);
			if (interpreterProxy->failed())
				return PrimErrBadArgument;
			*(long *)argvec = v;
			gpRegCount++;
			if (gpRegCount < 8) gpRegCount++;
			argvec += sizeof(long);
		}
	}

	funcAlien = interpreterProxy->stackValue(funcOffset);
	ffiStackIndex = (argvec-argstart)/4;
	GPRegsLocation = ffiStackLocation = (long *) argstart;
	FPRegsLocation = &floatStorageArea[0];
	f = *(void **)startOfParameterData(funcAlien);
#if STACK_ALIGN_BYTES
	/* cut stack back to start of aligned args */
//	setsp(0);
#endif
	ffiCallAddressOf(f);
	
