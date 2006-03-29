/*
 *  primAlListener.c
 *  OpenALPlugin
 *
 *  Created by Jamie Gjerde on Mon Mar 22 2004.
 *  Copyright (c) 2004 University of Minnesota. All rights reserved.
 *
 */

#include "primAlListener.h"

/*****************************************************************/
// Listener-Related AL functions below
/*****************************************************************/

EXPORT(int) primAlListenerfv(void) {

	int enumValue,oopFloatArray,oopFloatValue;
	int i,error;
	ALenum pname;
	ALfloat* values;

	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}

	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(1);
    oopFloatArray = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;

	//actual corresponding c variables
	pname = (ALenum)enumValue;

	switch (pname) {
		case AL_POSITION:
		case AL_VELOCITY:
			values = malloc(3*sizeof(ALfloat));
			for(i=0;i<3;i++)
			{
				oopFloatValue = interpreterProxy->stObjectat(oopFloatArray, i+1);
				values[i] = (ALfloat)interpreterProxy->floatValueOf(oopFloatValue);
			}
			break;
		case AL_ORIENTATION:
			values = malloc(6*sizeof(ALfloat));
			for(i=0;i<6;i++)
			{
				oopFloatValue = interpreterProxy->stObjectat(oopFloatArray, i+1);
				values[i] = (ALfloat)interpreterProxy->floatValueOf(oopFloatValue);
			}
			break;
	}
    
	//clear the error code
	alGetError();

	//call the openAL function
	alListenerfv(pname, values);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	//free values
	free(values);
	return 1;
}


EXPORT(int) primAlListenerf(void) {

	int enumValue;
	double floatValue;
	ALenum pname;
	ALfloat value;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(1);
    floatValue = interpreterProxy->stackFloatValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
	value = (ALfloat)floatValue;

	//clear the error code
	alGetError();

	//call the openAL function
	alListenerf(pname, value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlListener3f(void) {

	int enumValue;
	double floatValue1,floatValue2,floatValue3;
	ALenum pname;
	ALfloat value1,value2,value3;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 4)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(3);
    floatValue1 = interpreterProxy->stackFloatValue(2);
	floatValue2 = interpreterProxy->stackFloatValue(1);
	floatValue3 = interpreterProxy->stackFloatValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
	value1 = (ALfloat)floatValue1;
	value2 = (ALfloat)floatValue2;
	value3 = (ALfloat)floatValue3;
	
	//clear the error code
	alGetError();

	//call the openAL function
	alListener3f(pname, value1, value2, value3);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(5);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlListeneri(void) {

	int enumValue,intValue;
	ALenum pname;
	ALint value;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(1);
    intValue = interpreterProxy->stackIntegerValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
	value = (ALint)intValue;
	
	//clear the error code
	alGetError();

	//call the openAL function
	alListeneri(pname, value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	return 1;
	
}


EXPORT(int) primAlGetListenerf(void) {

	int enumValue,floatValueOop;
	ALenum pname;
	ALfloat value;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	enumValue = interpreterProxy->stackIntegerValue(1);
    floatValueOop = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
	
    //clear the error code
	alGetError();

	//call the openAL function
	alGetListenerf(pname, &value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//return the value to smalltalk
	interpreterProxy->stObjectatput(floatValueOop, 1, interpreterProxy->floatObjectOf((double)value));
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlGetListenerfv(void) {

	int enumValue,oopFloatArray;
	ALenum pname;
	ALfloat* values;
	int i;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(1);
    oopFloatArray = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
	
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
	
	switch (pname) {
		case AL_POSITION:
		case AL_VELOCITY:
			values = malloc(3 * sizeof(ALfloat));
			break;
		case AL_ORIENTATION:
			values = malloc(6 * sizeof(ALfloat));
			break;
	}
    
	//clear the error code
	alGetError();

	//call the openAL function
	alGetListenerfv(pname, values);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//return the value to smalltalk
	switch (pname) {
		case AL_POSITION:
		case AL_VELOCITY:
			for(i=0;i<3;i++)
			{
				interpreterProxy->pushRemappableOop(oopFloatArray);
				interpreterProxy->stObjectatput(oopFloatArray, i+1, interpreterProxy->floatObjectOf((double)values[i]));
				oopFloatArray = interpreterProxy->popRemappableOop();
			}
			break;
		case AL_ORIENTATION:
			for(i=0;i<6;i++)
			{
				interpreterProxy->pushRemappableOop(oopFloatArray);
				interpreterProxy->stObjectatput(oopFloatArray, i+1, interpreterProxy->floatObjectOf((double)values[i]));
				oopFloatArray = interpreterProxy->popRemappableOop();
			}
			break;
	}
	
	free(values);
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlGetListener3f(void) {

	int enumValue,floatValueOop1,floatValueOop2,floatValueOop3;
	ALenum pname;
	ALfloat value1;
	ALfloat value2;
	ALfloat value3;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 4)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(3);
    floatValueOop1 = interpreterProxy->stackObjectValue(2);
	floatValueOop2 = interpreterProxy->stackObjectValue(1);
	floatValueOop3 = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
	
    //clear the error code
	alGetError();

	//call the openAL function
	alGetListener3f(pname, &value1, &value2, &value3);

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
	interpreterProxy->pop(5);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlGetListeneri(void) {

	int enumValue,intValueOop;
	ALenum pname;
	ALint value;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(1);
    intValueOop = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
    
	//clear the error code
	alGetError();

	//call the openAL function
	alGetListeneri(pname, &value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//return the value to smalltalk
	interpreterProxy->stObjectatput(intValueOop, 1, interpreterProxy->integerObjectOf(value));
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	return 1;
}


/*****************************************************************/


