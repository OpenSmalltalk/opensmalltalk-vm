/*
 *  primAlListener.h
 *  OpenALPlugin
 *
 *  Created by Jamie Gjerde on Mon Mar 22 2004.
 *  Copyright (c) 2004 University of Minnesota. All rights reserved.
 *
 */

#include "OpenALPlugin.h"

#pragma export on
EXPORT(int) primAlListenerf(void);
EXPORT(int) primAlListener3f(void);
EXPORT(int) primAlListenerfv(void);
EXPORT(int) primAlListeneri(void);
EXPORT(int) primAlGetListenerf(void);
EXPORT(int) primAlGetListener3f(void);
EXPORT(int) primAlGetListenerfv(void);
EXPORT(int) primAlGetListenerfi(void);
#pragma export off

