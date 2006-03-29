/*
 *  primAlBuffer.h
 *  OpenALPlugin
 *
 *  Created by Jamie Gjerde on Mon Mar 22 2004.
 *  Copyright (c) 2004 University of Minnesota. All rights reserved.
 *
 */
 
#include "OpenALPlugin.h"

#pragma export on
EXPORT(int) primAlGenBuffers(void);
EXPORT(int) primAlDeleteBuffers(void);
EXPORT(int) primAlIsBuffer(void);
EXPORT(int) primAlBufferData(void);
EXPORT(int) primAlGetBufferf(void);
EXPORT(int) primAlGetBufferi(void);
#pragma export off

