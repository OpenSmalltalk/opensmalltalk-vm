/*
 *  OpenALPlugin.h
 *  OpenALPlugin
 *
 *  Created by Jamie Gjerde on Mon Mar 22 2004.
 *  Copyright (c) 2004 University of Minnesota. All rights reserved.
 *
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* #define MACOSX here so finding out if we are on the MAC
   requires just calling these two macros once */
#if defined (__APPLE__) && defined(__MACH__)
#define MACOSX
#endif

/* OpenAL includes below, they are platform specific */
#if defined MACOSX
	#include <OpenAL/al.h>
	#include <OpenAL/alc.h>

	#ifndef AL_VERSION_1_1
		#include <OpenAL/alctypes.h>
		#include <OpenAL/altypes.h>
	#endif
#else 
	#include <al.h>
	#include <alc.h>

	#ifndef AL_VERSION_1_1
		#include <alctypes.h>
		#include <altypes.h>
		#include <alu.h>
	#endif
#endif


/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
#undef EXPORT
// was #undef EXPORT(returnType) but screws NorCroft cc
#define EXPORT(returnType) static returnType
#endif

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)

/*** Constants ***/

/*** Variables ***/

/* #define DEBUG_AL right here if u want to use the debug.txt file */
#define DEBUG_AL
#if defined DEBUG_AL
	FILE* debugFile;
#endif

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"OpenALPlugin 14 March 2004 (i)"
#else
	"OpenALPlugin 14 March 2004 (e)"
#endif
;

/*** Function Prototypes ***/
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
#pragma export on
EXPORT(int) initialiseModule(void);
#pragma export off
static int msg(char *s);
#pragma export on
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
EXPORT(int) shutdownModule(void);
#pragma export off

//normally these are declared static but we do not do that here
//because we need access to these from the various primAlFoo files
int stringFromCString(char *aCString);
char * transientCStringFromString(int aString);

//openAL error handling
void getReturnError( int error, char* strError );





