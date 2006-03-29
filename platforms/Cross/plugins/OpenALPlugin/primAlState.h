/*
 *  primAlState.h
 *  OpenALPlugin
 *
 *  Created by Jamie Gjerde on Tue Mar 23 2004.
 *  Copyright (c) 2004 University of Minnesota. All rights reserved.
 *
 */

#include "OpenALPlugin.h"

#pragma export on
EXPORT(int) primAlEnable(void);
EXPORT(int) primAlDisable(void);
EXPORT(int) primAlIsEnabled(void);
EXPORT(int) primAlGetBoolean(void);
EXPORT(int) primAlGetDouble(void);
EXPORT(int) primAlGetFloat(void);
EXPORT(int) primAlGetInteger(void);
EXPORT(int) primAlGetBooleanv(void);
EXPORT(int) primAlGetDoublev(void);
EXPORT(int) primAlGetFloatv(void);
EXPORT(int) primAlGetIntegerv(void);
EXPORT(int) primAlGetString(void);
EXPORT(int) primAlDistanceModel(void);
EXPORT(int) primAlDopplerFactor(void);
EXPORT(int) primAlDopplerVelocity(void);
#pragma export off
