/*
 *  primAlContext.c
 *  OpenALPlugin
 *
 *  Created by Jamie Gjerde on Mon Mar 29 2004.
 *  Copyright (c) 2004 University of Minnesota. All rights reserved.
 *
 */

#include "primAlContext.h"

/*****************************************************************/
EXPORT(int) primCreateNewContext(void) {

	int error;
	ALCcontext *Context;
	ALCdevice *Device;

	if (!((interpreterProxy->methodArgumentCount()) == 0)) {
		return interpreterProxy->primitiveFail();
	}
	
	//clear the error code
	alGetError();

	
	Device=alcOpenDevice(NULL);  //open device
 	
 	if (Device != NULL)
 	{
		Context=alcCreateContext(Device,0);  //create context(s)
		
		if (Context != NULL)
		{
			alcMakeContextCurrent(Context);  //set active context
		}
	}

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	//interpreterProxy->pop(1);
	//interpreterProxy->pushInteger(1);

	return 1;
}


EXPORT(int) primDestroyCurrentContext(void) {
	
	int error;
	ALCcontext *Context;
	ALCdevice *Device;
	
	//clear the error code
	alGetError();
	
	//get active context
	Context=alcGetCurrentContext();
	//get device for active context
	Device=alcGetContextsDevice(Context);
	//release context(s)
	alcDestroyContext(Context);
	//close device
	alcCloseDevice(Device);

	if((error = alGetError()) != AL_NO_ERROR)
	{
		return interpreterProxy->primitiveFail();
	}
	
	return 1;
}


EXPORT(int) primIsCurrentContextValid(void)
{
	return 1;
}


EXPORT(int) primAlcCreateContext(void)
{
	return 1;
}


EXPORT(int) primAlcMakeContextCurrent(void)
{
	return 1;
}


EXPORT(int) primAlcProcessContext(void)
{
	return 1;
}


EXPORT(int) primAlcSuspendContext(void)
{
	return 1;
}


EXPORT(int) primAlcDestroyContext(void)
{
	return 1;
}


EXPORT(int) primAlcGetError(void)
{
	return 1;
}


EXPORT(int) primAlcGetCurrentContext(void)
{
	return 1;
}


EXPORT(int) primAlcOpenDevice(void)
{
	return 1;
}


EXPORT(int) primAlcCloseDevice(void)
{
	return 1;
}


EXPORT(int) primAlcIsExtensionPresent(void)
{
	return 1;
}


EXPORT(int) primAlcGetProcAddress(void)
{
	return 1;
}


EXPORT(int) primAlcGetEnumValue(void)
{
	return 1;
}


EXPORT(int) primAlcGetString(void)
{
	return 1;
}


EXPORT(int) primAlcGetIntegerv(void)
{
	return 1;
}



