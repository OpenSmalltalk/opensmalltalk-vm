/*
 *  primAlContext.h
 *  OpenALPlugin
 *
 *  Created by Jamie Gjerde on Mon Mar 29 2004.
 *  Copyright (c) 2004 University of Minnesota. All rights reserved.
 *
 */

#include "OpenALPlugin.h"

#pragma export on
EXPORT(int) primCreateNewContext(void);
EXPORT(int) primDestroyCurrentContext(void);

EXPORT(int) primAlcCreateContext(void);
EXPORT(int) primAlcMakeContextCurrent(void);
EXPORT(int) primAlcProcessContext(void);
EXPORT(int) primAlcSuspendContext(void);
EXPORT(int) primAlcDestroyContext(void);
EXPORT(int) primAlcGetError(void);
EXPORT(int) primAlcGetCurrentContext(void);
EXPORT(int) primAlcOpenDevice(void);
EXPORT(int) primAlcCloseDevice(void);
EXPORT(int) primAlcIsExtensionPresent(void);
EXPORT(int) primAlcGetProcAddress(void);
EXPORT(int) primAlcGetEnumValue(void);
EXPORT(int) primAlcGetString(void);
EXPORT(int) primAlcGetIntegerv(void);
#pragma export off

