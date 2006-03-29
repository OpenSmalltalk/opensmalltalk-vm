/*
 *  primAlState.c
 *  OpenALPlugin
 *
 *  Created by Jamie Gjerde on Tue Mar 23 2004.
 *  Copyright (c) 2004 University of Minnesota. All rights reserved.
 *
 */

#include "primAlState.h"

EXPORT(int) primAlEnable(void)
{
	int enumValue;
	ALenum capability;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	capability = (ALenum)enumValue;
    
	//clear the error code
	alGetError();

	//call the openAL function
	alEnable(capability);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlDisable(void)
{
	int enumValue;
	ALenum capability;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	capability = (ALenum)enumValue;
	
	//clear the error code
	alGetError();

	//call the openAL function
	alDisable(capability);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlIsEnabled(void)
{
	int enumValue;
	ALenum capability;
	ALboolean retVal;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	capability = (ALenum)enumValue;
	
	//clear the error code
	alGetError();

	//call the openAL function
	retVal = alIsEnabled(capability);
	
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


EXPORT(int) primAlGetBoolean(void)
{
	//from the openal programming guide ::
	//There aren't any boolean states defined at the time of this writing, so this function will always generate the  error AL_INVALID_ENUM. 
	int enumValue;
	ALenum pname;
	ALboolean retVal;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	retVal=alGetBoolean(pname);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return the value to smalltalk
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


EXPORT(int) primAlGetDouble(void)
{
	//from the openal programming guide ::
	//There aren't any double precision floating point states defined at the time of this writing, so this function  will always generate the error AL_INVALID_ENUM. 
	int enumValue;
	ALenum pname;
	ALdouble retVal;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	retVal=alGetDouble(pname);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return the value to smalltalk
	interpreterProxy->pop(2);
	interpreterProxy->push(interpreterProxy->floatObjectOf(retVal));
	return 1;
}


EXPORT(int) primAlGetFloat(void)
{
	int enumValue;
	ALenum pname;
	ALfloat retVal;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
    
	//clear the error code
	alGetError();

	//call the openAL function
	retVal=alGetFloat(pname);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return the value to smalltalk
	interpreterProxy->pop(2);
	interpreterProxy->push(interpreterProxy->floatObjectOf((double)retVal));
	return 1;
}


EXPORT(int) primAlGetInteger(void)
{
	int enumValue;
	ALenum pname;
	ALint retVal;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	retVal=alGetInteger(pname);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return the value to smalltalk
	interpreterProxy->pop(2);
	interpreterProxy->push(interpreterProxy->integerObjectOf(retVal));
	return 1;
}


EXPORT(int) primAlGetBooleanv(void)
{
	//from the openal programming guide ::
	//There aren't any boolean states defined at the time of this writing, so this function will always generate the error AL_INVALID_ENUM.  
	int enumValue,booleanValueOop;
	ALenum pname;
	ALboolean data;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(1);
    booleanValueOop = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
	
	//clear the error code
	alGetError();

	//call the openAL function
	alGetBooleanv(pname, &data);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//return the value to smalltalk and pop all oops
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	
	if( data == AL_TRUE )
	{
		interpreterProxy->stObjectatput(booleanValueOop, 1, interpreterProxy->trueObject());
	}
	else
	{
		interpreterProxy->stObjectatput(booleanValueOop, 1, interpreterProxy->falseObject());
	}
	
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlGetDoublev(void)
{
	//from the openal programming guide ::
	//There aren't any  double precision floating point states defined at the time of this writing, so this function  will always generate the error AL_INVALID_ENUM.
	int enumValue,doubleValueOop;
	ALenum pname;
	ALdouble data;
	int error;
  
	
	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    enumValue = interpreterProxy->stackIntegerValue(1);
    doubleValueOop = interpreterProxy->stackObjectValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
    
	//clear the error code
	alGetError();

	//call the openAL function
	alGetDoublev(pname, &data);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//return the value to smalltalk
	interpreterProxy->stObjectatput(doubleValueOop, 1, interpreterProxy->floatObjectOf(data));
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	return 1;
}

EXPORT(int) primAlGetFloatv(void)
{
	int enumValue,floatValueOop;
	ALenum pname;
	ALfloat data;
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
	alGetFloatv(pname, &data);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//return the value to smalltalk
	interpreterProxy->stObjectatput(floatValueOop, 1, interpreterProxy->floatObjectOf((double)data));
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	return 1;

}


EXPORT(int) primAlGetIntegerv(void)
{   
	int enumValue,intValueOop;
	ALenum pname;
	ALint data;
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
	alGetIntegerv(pname, &data);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//return the value to smalltalk
	interpreterProxy->stObjectatput(intValueOop, 1, interpreterProxy->integerObjectOf(data));
	
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(3);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlGetString(void)
{
	int enumValue;
	ALenum pname;
	ALubyte* retVal;
	int error;

	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    	enumValue = interpreterProxy->stackIntegerValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	pname = (ALenum)enumValue;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	retVal = (ALubyte *)alGetString(pname);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return the value to smalltalk
	interpreterProxy->pop(2);
	interpreterProxy->push(stringFromCString(retVal));
	return 1;
}


EXPORT(int) primAlDistanceModel(void)
{
	int enumValue;
	ALenum value;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
	enumValue = interpreterProxy->stackIntegerValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	value = (ALenum)enumValue;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	alDistanceModel(value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlDopplerFactor(void)
{
	double floatValue;
	ALfloat value;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    floatValue = interpreterProxy->stackFloatValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	value = (ALfloat)floatValue;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	alDopplerFactor(value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(1);
	return 1;
}


EXPORT(int) primAlDopplerVelocity(void)
{
	double floatValue;
	ALfloat value;
	int error;
	
	if (!((interpreterProxy->methodArgumentCount()) == 1)) {
		return interpreterProxy->primitiveFail();
	}
	
	//smalltalk oops and values for incoming params
    floatValue = interpreterProxy->stackFloatValue(0);
	if(interpreterProxy->failed()) return 0;
	
	//actual corresponding c variables
	value = (ALfloat)floatValue;
	    
	//clear the error code
	alGetError();

	//call the openAL function
	alDopplerVelocity(value);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
        
	//pop all oops and return 1 to smalltalk indicating a success
	interpreterProxy->pop(2);
	interpreterProxy->pushInteger(1);
	return 1;
}



