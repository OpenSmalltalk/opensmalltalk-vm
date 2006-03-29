/*
 *  primAlSource.c
 *  OpenALPlugin
 *
 *  Created by Jamie Gjerde on Mon Mar 22 2004.
 *  Copyright (c) 2004 University of Minnesota. All rights reserved.
 *
 */

#include "primAlSource.h"

/*****************************************************************/
//  Source-Related AL functions below
/*****************************************************************/

EXPORT(int) primAlGenSources(void) {
	
	int numSources,oopSources;
	ALsizei n;
	ALuint* sources;
	int i,error;

	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    numSources = interpreterProxy->stackIntegerValue(1);
    oopSources = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
	
    //actual corresponding c variables
    n = (ALsizei)numSources;
    sources = malloc(numSources*sizeof(ALuint));
	
	//clear the error code
	alGetError();

	//call the openAL function
	alGenSources(n, sources);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//transfer all of the elements in buffers to the corresponding array in smalltalk
	for(i=0;i<n;i++)
	{
		//remember the smalltalk array is 1 based
		interpreterProxy->pushRemappableOop(oopSources);
		interpreterProxy->stObjectatput(oopSources, i+1, interpreterProxy->positive32BitIntegerFor(sources[i]));
		oopSources = interpreterProxy->popRemappableOop();
	}
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	//free the buffer
	free(sources);	
	return 1;
}

EXPORT(int) primAlDeleteSources(void) {

	int numSources,oopSources,oopElementOfSources;
	ALsizei n;
	ALuint* sources;
	int i,error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}

    //smalltalk oops and values for incoming params
    numSources = interpreterProxy->stackIntegerValue(1);
    oopSources = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;

    //actual corresponding c variables
    n = (ALsizei)numSources;
    sources = malloc(numSources*sizeof(ALuint));
    
	if ( n <= 0 )
	{
   		return interpreterProxy->primitiveFail();
	}

	//now populate the buffers array with the values of the smalltalk array
	for(i=0;i<numSources;i++)
	{
		oopElementOfSources = interpreterProxy->stObjectat(oopSources, i+1);
		sources[i] = interpreterProxy->positive32BitValueOf(oopElementOfSources);	
	}
	
	//clear the error code
	alGetError();

	//call the openAL function
	alDeleteSources(n, sources);
	
	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}

	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	//free the sources
	free(sources);
	return 1;
}


EXPORT(int) primAlIsSource(void) {

	int sourceName;
	ALuint source;
	ALboolean retVal;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	//sourceName can be a big number here so we need to access it differently
	sourceName = interpreterProxy->stackValue(0);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	source = (ALuint)sourceName;
	
	//clear the error code
	alGetError();

	//call the openAL function
	retVal = alIsSource(source);
	
	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//pop all oops and return retVal to smalltalk
	interpreterProxy->pop(2);
	
	if( retVal == AL_TRUE )
	{
		interpreterProxy->push(interpreterProxy->trueObject());
		return 1;
	}
	else
	{
		interpreterProxy->push(interpreterProxy->falseObject());
		return 0;
	}
	
}


EXPORT(int) primAlSourcef(void) {

	int sourceName,enumValue;
	double floatValue;
	ALuint source;
	ALenum pname;
	ALfloat value;
	int error;

	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	//sourceName can be a big number here so we need to access it differently
	sourceName = interpreterProxy->stackValue(2);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
	enumValue = interpreterProxy->stackIntegerValue(1);
    floatValue = interpreterProxy->stackFloatValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	source = (ALuint)sourceName;
	pname = (ALenum)enumValue;
	value = (ALfloat)floatValue;
	
	//clear the error code
	alGetError();

	//call the openAL function
	alSourcef(source, pname, value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlSource3f(void) {

	int sourceName, enumValue;
	double floatValue1,floatValue2,floatValue3;
	ALuint source;
	ALenum pname;
	ALfloat value1,value2,value3;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 5)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	//sourceName can be a big number here so we need to access it differently
	sourceName = interpreterProxy->stackValue(4);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
    enumValue = interpreterProxy->stackIntegerValue(3);
    floatValue1 = interpreterProxy->stackFloatValue(2);
	floatValue2 = interpreterProxy->stackFloatValue(1);
	floatValue3 = interpreterProxy->stackFloatValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	source = (ALuint)sourceName;
	pname = (ALenum)enumValue;
	value1 = (ALfloat)floatValue1;
	value2 = (ALfloat)floatValue2;
	value3 = (ALfloat)floatValue3;
    
	//clear the error code
	alGetError();

	//call the openAL function
	alSource3f(source, pname, value1, value2, value3);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(6);
	interpreterProxy->pushInteger(1);
	return 1;
}



EXPORT(int) primAlSourcefv(void) {

	int sourceName,enumValue,oopFloatArray,oopFloatValue;
	ALuint source;
	ALenum pname;
	ALfloat* values;
	int i,error;

	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	//sourceName can be a big number here so we need to access it differently
	sourceName = interpreterProxy->stackValue(2);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
    enumValue = interpreterProxy->stackIntegerValue(1);
    oopFloatArray = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;

	//actual corresponding c variables
	source = (ALuint)sourceName;
	pname = (ALenum)enumValue;
		
	values = malloc(3*sizeof(ALfloat));
	for(i=0;i<3;i++)
	{
		oopFloatValue = interpreterProxy->stObjectat(oopFloatArray, i+1);
		values[i] = (ALfloat)interpreterProxy->floatValueOf(oopFloatValue);
	}
			    
	//clear the error code
	alGetError();

	//call the openAL function
	alSourcefv(source, pname, values);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(1);
	//free values
	free(values);
	return 1;
}


EXPORT(int) primAlSourcei(void) {

	int sourceName,enumValue,intValue;
	ALuint source;
	ALenum pname;
	ALint value;
	int error;

	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	//sourceName can be a big number here so we need to access it differently
	sourceName = interpreterProxy->stackValue(2);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
    enumValue = interpreterProxy->stackIntegerValue(1);
	//intValue can be a big number as well, cannot use stackIntegerValue
	intValue = interpreterProxy->stackValue(0);
	intValue = interpreterProxy->positive32BitValueOf(intValue);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	source = (ALuint)sourceName;
	pname = (ALenum)enumValue;
	value = (ALint)intValue;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	alSourcei(source, pname, value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(1);
	return 1;
	
}


EXPORT(int) primAlGetSourcef(void) {

	int sourceName,enumValue,floatValueOop;
	ALuint source;
	ALenum pname;
	ALfloat value;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	//sourceName can be a big number here so we need to access it differently
	sourceName = interpreterProxy->stackValue(2);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
    enumValue = interpreterProxy->stackIntegerValue(1);
    floatValueOop = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	source = (ALuint)sourceName;
	pname = (ALenum)enumValue;
    
	//clear the error code
	alGetError();

	//call the openAL function
	alGetSourcef(source, pname, &value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//return the value to smalltalk
	interpreterProxy->stObjectatput(floatValueOop, 1, interpreterProxy->floatObjectOf((double)value));
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlGetSourcefv(void) {

	int sourceName,enumValue,oopFloatArray;
	ALuint source;
	ALenum pname;
	ALfloat values[3];
	int i,error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	//sourceName can be a big number here so we need to access it differently
	sourceName = interpreterProxy->stackValue(2);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
    enumValue = interpreterProxy->stackIntegerValue(1);
    oopFloatArray = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	source = (ALuint)sourceName;
	pname = (ALenum)enumValue;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	alGetSourcefv(source, pname, values);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//return the value to smalltalk
	for(i=0;i<3;i++)
	{
		interpreterProxy->pushRemappableOop(oopFloatArray);
		interpreterProxy->stObjectatput(oopFloatArray, i+1, interpreterProxy->floatObjectOf((double)values[i]));
		oopFloatArray = interpreterProxy->popRemappableOop();
	}
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlGetSource3f(void) {

	int sourceName,enumValue,floatValueOop1,floatValueOop2,floatValueOop3;
	ALuint source;
	ALenum pname;
	ALfloat value1;
	ALfloat value2;
	ALfloat value3;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 5)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	//sourceName can be a big number here so we need to access it differently
	sourceName = interpreterProxy->stackValue(4);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
    enumValue = interpreterProxy->stackIntegerValue(3);
    floatValueOop1 = interpreterProxy->stackObjectValue(2);
	floatValueOop2 = interpreterProxy->stackObjectValue(1);
	floatValueOop3 = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	source = (ALuint)sourceName;
	pname = (ALenum)enumValue;
    
	//clear the error code
	alGetError();

	//call the openAL function
	alGetSource3f(source, pname, &value1, &value2, &value3);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//return the value to smalltalk
	
	interpreterProxy->pushRemappableOop(floatValueOop3);
	interpreterProxy->pushRemappableOop(floatValueOop2);
	interpreterProxy->stObjectatput(floatValueOop1, 1, interpreterProxy->floatObjectOf((double)value1));
	floatValueOop2 = interpreterProxy->popRemappableOop();
	interpreterProxy->stObjectatput(floatValueOop2, 1, interpreterProxy->floatObjectOf((double)value2));
	floatValueOop3 = interpreterProxy->popRemappableOop();
	interpreterProxy->stObjectatput(floatValueOop3, 1, interpreterProxy->floatObjectOf((double)value3));
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(6);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlGetSourcei(void) {

    int sourceName,enumValue,intValueOop;
	ALuint source;
	ALenum pname;
	ALint value;
	int error;

	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	//sourceName can be a big number here so we need to access it differently
	sourceName = interpreterProxy->stackValue(2);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
    enumValue = interpreterProxy->stackIntegerValue(1);
    intValueOop = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	source = (ALuint)sourceName;
	pname = (ALenum)enumValue;
    
	//clear the error code
	alGetError();

	//call the openAL function
	alGetSourcei(source, pname, &value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	
	//return the value to smalltalk
	interpreterProxy->stObjectatput(intValueOop, 1, interpreterProxy->integerObjectOf(value));
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlSourcePlay(void) {

	int sourceName;
	ALuint source;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	//sourceName can be a big number here so we need to access it differently
	sourceName = interpreterProxy->stackValue(0);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
	if(interpreterProxy->failed()) return 0;

	//actual corresponding c variables
	source = (ALuint)sourceName;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	alSourcePlay(source);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(1);
	return 1;
	
}


EXPORT(int) primAlSourcePlayv(void) {

	int numSources,oopSources,oopElementOfSources;
	ALsizei n;
	ALuint* sources;
	int i,error;

	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}

    //smalltalk oops and values for incoming params
    numSources = interpreterProxy->stackIntegerValue(1);
    oopSources = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
    
	//actual corresponding c variables
    n = (ALsizei)numSources;
	sources = malloc(numSources*sizeof(ALuint));
   	
	if ( n <= 0 )
	{
   		return interpreterProxy->primitiveFail();
	}

	//now populate the buffers array with the values of the smalltalk array
	for(i=0;i<numSources;i++)
	{
		oopElementOfSources = interpreterProxy->stObjectat(oopSources, i+1);
		sources[i] = interpreterProxy->positive32BitValueOf(oopElementOfSources);	
	}
	
	//clear the error code
	alGetError();

	//call the openAL function
	alSourcePlayv(n, sources);
	
	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}

	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	//free the sources
	free(sources);
	return 1;
}


EXPORT(int) primAlSourcePause(void) {

	int sourceName;
	ALuint source;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	//sourceName can be a big number here so we need to access it differently
	sourceName = interpreterProxy->stackValue(0);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
	if(interpreterProxy->failed()) return 0;

	//actual corresponding c variables
	source = (ALuint)sourceName;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	alSourcePause(source);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(1);
	return 1;
	
}


EXPORT(int) primAlSourcePausev(void) {

	int numSources,oopSources,oopElementOfSources;
	ALsizei n;
	ALuint* sources;
	int i,error;


	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}

    //smalltalk oops and values for incoming params
    numSources = interpreterProxy->stackIntegerValue(1);
    oopSources = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
   
    //actual corresponding c variables
    n = (ALsizei)numSources;
    sources = malloc(numSources*sizeof(ALuint));
	
	if ( n <= 0 )
	{
   		return interpreterProxy->primitiveFail();
	}

	//now populate the buffers array with the values of the smalltalk array
	for(i=0;i<numSources;i++)
	{
		oopElementOfSources = interpreterProxy->stObjectat(oopSources, i+1);
		sources[i] = interpreterProxy->positive32BitValueOf(oopElementOfSources);	
	}
	
	//clear the error code
	alGetError();

	//call the openAL function
	alSourcePausev(n, sources);
	
	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}

	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	//free the sources
	free(sources);
	return 1;
}


EXPORT(int) primAlSourceStop(void) {

	int sourceName;
	ALuint source;
	int error;

	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	sourceName = interpreterProxy->stackValue(0);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
	if(interpreterProxy->failed()) return 0;

	//actual corresponding c variables
	source = (ALuint)sourceName;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	alSourceStop(source);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(1);
	return 1;
	
}


EXPORT(int) primAlSourceStopv(void) {

	int numSources,oopSources,oopElementOfSources;
	ALsizei n;
	ALuint* sources;
	int i,error;

	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}

    //smalltalk oops and values for incoming params
    numSources = interpreterProxy->stackIntegerValue(1);
    oopSources = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
    
    //actual corresponding c variables
    n = (ALsizei)numSources;
	sources = malloc(numSources*sizeof(ALuint));
   	
	if ( n <= 0 )
	{
   		return interpreterProxy->primitiveFail();
	}

	//now populate the buffers array with the values of the smalltalk array
	for(i=0;i<numSources;i++)
	{
		oopElementOfSources = interpreterProxy->stObjectat(oopSources, i+1);
		sources[i] = interpreterProxy->positive32BitValueOf(oopElementOfSources);	
	}
	
	//clear the error code
	alGetError();

	//call the openAL function
	alSourceStopv(n, sources);
	
	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}

	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	//free the sources
	free(sources);
	return 1;
}


EXPORT(int) primAlSourceRewind(void) {

	int sourceName;
	ALuint source;
	int error;

	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	sourceName = interpreterProxy->stackValue(0);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
	if(interpreterProxy->failed()) return 0;

	//actual corresponding c variables
	source = (ALuint)sourceName;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	alSourceRewind(source);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(1);
	return 1;
	
}


EXPORT(int) primAlSourceRewindv(void) {

	int numSources,oopSources,oopElementOfSources;
	ALsizei n;
	ALuint* sources;
	int i,error;

	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}

    //smalltalk oops and values for incoming params
    numSources = interpreterProxy->stackIntegerValue(1);
    oopSources = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
   
    //actual corresponding c variables
    n = (ALsizei)numSources;
    sources = malloc(numSources*sizeof(ALuint));
   	
	if ( n <= 0 )
	{
   		return interpreterProxy->primitiveFail();
	}

	//now populate the buffers array with the values of the smalltalk array
	for(i=0;i<numSources;i++)
	{
		oopElementOfSources = interpreterProxy->stObjectat(oopSources, i+1);
		sources[i] = interpreterProxy->positive32BitValueOf(oopElementOfSources);	
	}
	
	//clear the error code
	alGetError();

	//call the openAL function
	alSourceRewindv(n, sources);
	
	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}

	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	//free the sources
	free(sources);
	return 1;
}


EXPORT(int) primAlSourceQueueBuffers(void) {

	int sourceName,numBuffers,oopBuffers,oopElementOfBuffers;
	ALuint source;
	ALsizei n;
	ALuint* buffers;
	int i,error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}

    //smalltalk oops and values for incoming params
	sourceName = interpreterProxy->stackValue(2);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
    numBuffers = interpreterProxy->stackIntegerValue(1);
	oopBuffers = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
    
    //actual corresponding c variables
	source = (ALuint)sourceName;
    n = (ALsizei)numBuffers;
    buffers = malloc(numBuffers*sizeof(ALuint));
	
	if ( n <= 0 )
	{
   		return interpreterProxy->primitiveFail();
	}

	//now populate the buffers array with the values of the smalltalk array
	for(i=0;i<numBuffers;i++)
	{
		oopElementOfBuffers = interpreterProxy->stObjectat(oopBuffers, i+1);
		buffers[i] = interpreterProxy->positive32BitValueOf(oopElementOfBuffers);	
	}
	
	//clear the error code
	alGetError();

	//call the openAL function
	alSourceQueueBuffers(source, n, buffers);
	
	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}

	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(1);
	//free the buffers
	free(buffers);
	return 1;
}


EXPORT(int) primAlSourceUnqueueBuffers(void) {

	int sourceName,numBuffers,oopBuffers;
	ALuint source;
	ALsizei n;
	ALuint* buffers;
	int i,error;

	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}

    //smalltalk oops and values for incoming params
	sourceName = interpreterProxy->stackValue(2);
	sourceName = interpreterProxy->positive32BitValueOf(sourceName);
    numBuffers = interpreterProxy->stackIntegerValue(1);
    oopBuffers = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
    
    //actual corresponding c variables
	source = (ALuint)sourceName;
    	n = (ALsizei)numBuffers;
	buffers = malloc(numBuffers*sizeof(ALuint));
    	
	if ( n <= 0 )
	{
   		return interpreterProxy->primitiveFail();
	}

	//clear the error code
	alGetError();

	//call the openAL function
	alSourceUnqueueBuffers(source, n, buffers);
	
	//now populate the buffers array with the values of the smalltalk array
	for(i=0;i<n;i++)
	{
		interpreterProxy->pushRemappableOop(oopBuffers);
		interpreterProxy->stObjectatput(oopBuffers, i+1, interpreterProxy->positive32BitIntegerFor(buffers[i]));
		oopBuffers = interpreterProxy->popRemappableOop();	
	}
	
	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}

	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(1);
	//free the buffers
        free(buffers);
	return 1;
}

/*****************************************************************/


