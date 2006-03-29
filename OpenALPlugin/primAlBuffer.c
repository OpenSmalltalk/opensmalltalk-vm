/*
 *  primAlBuffer.c
 *  OpenALPlugin
 *
 *  Created by Jamie Gjerde on Mon Mar 22 2004.
 *  Copyright (c) 2004 University of Minnesota. All rights reserved.
 *
 */

#include "primAlBuffer.h"

/*****************************************************************/
//  Buffer-Related AL functions below
/*****************************************************************/

EXPORT(int) primAlGenBuffers(void) {
	
	int numBuffers,oopBuffers;
	ALsizei n;
	ALuint* buffers;
	int i,error;

	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    numBuffers = interpreterProxy->stackIntegerValue(1);
    oopBuffers = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;

    //actual corresponding c variables
    n = (ALsizei)numBuffers;
	buffers = malloc(numBuffers*sizeof(ALuint));

	//clear the error code
	alGetError();

	//call the openAL function
	alGenBuffers(n, buffers);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//transfer all of the elements in buffers to the corresponding array in smalltalk
	for(i=0;i<numBuffers;i++)
	{
		//remember the smalltalk array is 1 based
		interpreterProxy->pushRemappableOop(oopBuffers);	
		interpreterProxy->stObjectatput(oopBuffers, i+1, interpreterProxy->positive32BitIntegerFor(buffers[i]));
		oopBuffers = interpreterProxy->popRemappableOop();
	}
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	//free the buffer
	free(buffers);	
	return 1;
}

EXPORT(int) primAlDeleteBuffers(void) {

	int numBuffers,oopBuffers,oopElementOfBuffers;
	int i,error;
	ALsizei n;
	ALuint* buffers;
	
	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}

    //smalltalk oops and values for incoming params
    numBuffers = interpreterProxy->stackIntegerValue(1);
    oopBuffers = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;

    //actual corresponding c variables
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
	alDeleteBuffers(n, buffers);
	
	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}

	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	//free the buffer
	free(buffers);
	return 1;
}

EXPORT(int) primAlIsBuffer(void) {

	int bufferName;
	int error;
	ALuint buffer;
	ALboolean retVal;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	bufferName = interpreterProxy->stackValue(0);
	bufferName = interpreterProxy->positive32BitValueOf(bufferName);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	buffer = (ALuint)bufferName;
	
	//clear the error code
	alGetError();

	//call the openAL function
	retVal = alIsBuffer(buffer);
	
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


EXPORT(int) primAlBufferData(void) {

	int buffer, format, sizeBytes, nSamples, samplingRate, oopSampleArray, oopElementOfSampleArray;
	short int* data;
	int i,error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 5)) {
		return interpreterProxy->primitiveFail();
	}

	//smalltalk oops and values for incoming params
    //bufferName can be a big number here so we need to acces it differently
	buffer = interpreterProxy->stackValue(4);
	buffer = interpreterProxy->positive32BitValueOf(buffer);
	format = interpreterProxy->stackIntegerValue(3);
	oopSampleArray = interpreterProxy->stackObjectValue(2);
	sizeBytes = interpreterProxy->stackIntegerValue(1);
	samplingRate = interpreterProxy->stackIntegerValue(0);

	if(interpreterProxy->failed()) return 0;

	data = malloc(sizeBytes*sizeof(unsigned char));

	nSamples = (int)sizeBytes * 0.5;
	
	for( i=0; i<nSamples; i++)
	{
		oopElementOfSampleArray = interpreterProxy->stObjectat(oopSampleArray, i+1);
		data[i] = interpreterProxy->integerValueOf(oopElementOfSampleArray);
	}	

	//clear the error code
	alGetError();

	//call the openAL function
	alBufferData((ALuint)buffer, (ALenum)format, (ALvoid*)data, (ALsizei)sizeBytes, (ALsizei)samplingRate);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(6);
	interpreterProxy->pushInteger(1);

	//free the data
	free(data);	
	return 1;
}


EXPORT(int) primAlGetBufferf(void) {

	int bufferName, bufferPropName, oopPropValue;
	ALuint buffer;
	ALenum pname;
	ALfloat value; 
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	bufferName = interpreterProxy->stackValue(2);
	bufferName = interpreterProxy->positive32BitValueOf(bufferName);
    bufferPropName = interpreterProxy->stackIntegerValue(1);
    oopPropValue = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;

    //actual corresponding c variables
	buffer = (ALuint)bufferName;
    pname = (ALenum)bufferPropName;

	//clear the error code
	alGetError();

	//call the openAL function
	alGetBufferf(buffer, pname, &value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//transfer the value of the property to the smalltalk oop
	interpreterProxy->stObjectatput(oopPropValue, 1, interpreterProxy->floatObjectOf(value));
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(1);
	return 1;
}

EXPORT(int) primAlGetBufferi(void) {

	int bufferName,bufferPropName,oopPropValue;
	ALuint buffer;
	ALenum pname;
	ALint value;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	bufferName = interpreterProxy->stackValue(2);
	bufferName = interpreterProxy->positive32BitValueOf(bufferName);
    bufferPropName = interpreterProxy->stackIntegerValue(1);
    oopPropValue = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;

    //actual corresponding c variables
	buffer = (ALuint)bufferName;
    pname = (ALenum)bufferPropName;

	//clear the error code
	alGetError();

	//call the openAL function
	alGetBufferi(buffer, pname, &value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//transfer the value of the property to the smalltalk oop
	interpreterProxy->stObjectatput(oopPropValue, 1, interpreterProxy->integerObjectOf(value));
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(4);
	interpreterProxy->pushInteger(1);
	return 1;
}



