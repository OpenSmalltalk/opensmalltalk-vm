/*
 *  primAlSource.h
 *  OpenALPlugin
 *
 *  Created by Jamie Gjerde on Mon Mar 22 2004.
 *  Copyright (c) 2004 University of Minnesota. All rights reserved.
 *
 */
 
#include "OpenALPlugin.h"

#pragma export on
EXPORT(int) primAlGenSources(void);
EXPORT(int) primAlDeleteSources(void);
EXPORT(int) primAlIsSource(void);
EXPORT(int) primAlSourcePlay(void);
EXPORT(int) primAlSourcePlayv(void);
EXPORT(int) primAlSourcePause(void);
EXPORT(int) primAlSourcePausev(void);
EXPORT(int) primAlSourceStop(void);
EXPORT(int) primAlSourceStopv(void);
EXPORT(int) primAlSourceRewind(void);
EXPORT(int) primAlSourceRewindv(void);
EXPORT(int) primAlSourcef(void);
EXPORT(int) primAlSourcefv(void);
EXPORT(int) primAlSource3f(void);
EXPORT(int) primAlSourcei(void);
EXPORT(int) primAlGetSourcef(void);
EXPORT(int) primAlGetSourcefv(void);
EXPORT(int) primAlGetSourcei(void);
EXPORT(int) primAlSourceQueueBuffers(void);
EXPORT(int) primAlSourceUnqueueBuffers(void);
#pragma export off

