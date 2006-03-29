#include "OpenALPlugin.h"

/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

static int halt(void) {
	;
}

EXPORT(int) initialiseModule(void) {
#if defined DEBUG_AL	
	//open up the debug file, change the path if u so desire
	if ((debugFile = fopen("debug.txt", "w")) == NULL)
    {
		interpreterProxy->primitiveFail();
		return 0;
    }
	fputs("Plugin initialized yeah!\n", debugFile);
#endif
	return 1; 
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter) {
    int ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}

EXPORT(int) shutdownModule(void) {
#if defined DEBUG_AL
	if(debugFile)
	{
		fputs("Plugin shutdown successfully.\n", debugFile);
	}
	fclose(debugFile);
#endif
	return 1;
}

/*  Both of the below string functions will most likely cause a GC,
    so use the remap buffer where needed when calling these from your code */

/*	Answer a new String copied from a null-terminated C string.
	Caution: This may invoke the garbage collector. */

int stringFromCString(char *aCString) {
    int len;
    char *stringPtr;
    int newString;

	len = (int)strlen(aCString);
	newString = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), len);
	stringPtr = interpreterProxy->arrayValueOf(newString);
	(char *)strncpy(stringPtr, aCString, len);
	return newString;
}

char * transientCStringFromString(int aString) {
    int len;
    char *cString;
    char *stringPtr;
    int newString;


	/* Allocate space for a null terminated C string. */

	len = interpreterProxy->sizeOfSTArrayFromCPrimitive(interpreterProxy->arrayValueOf(aString));
	interpreterProxy->pushRemappableOop(aString);
	newString = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), len + 1);
	stringPtr = interpreterProxy->arrayValueOf(interpreterProxy->popRemappableOop());

	/* Point to the actual C string. */

	cString = interpreterProxy->arrayValueOf(newString);
	(char *)strncpy(cString, stringPtr, len);
	cString[len] = 0;
	return cString;
}

/* this will get u a string description of your openal error if u want it */

void getReturnError( int error, char* strError ) {
        
	switch (error)
	{
	case AL_INVALID_NAME:
		strError = "alError : Invalid Name.";
		break;
	case AL_INVALID_ENUM:
		strError = "alError : Invalid Enum.";
		break;
	case AL_INVALID_VALUE:
		strError = "alError : Invalid Value.";
		break;
	case AL_INVALID_OPERATION:
		strError = "alError : Invalid Operation.";
		break;
	case AL_OUT_OF_MEMORY:
		strError = "alError : Out of Memory.";
		break;
	default:
		strError = "alError : Unknown Error.";
		break;
	}
	
	return;
}

/* if we ever go built-in we do not need to type all this stuff in */
#ifdef SQUEAK_BUILTIN_PLUGIN


void* OpenALPlugin_exports[][3] = {
	{"OpenALPlugin", "shutdownModule", (void*)shutdownModule},
	{"OpenALPlugin", "primAlGenBuffers", (void*)primAlGenBuffers},
	{"OpenALPlugin", "primAlDeleteBuffers", (void*)primAlDeleteBuffers},
	{"OpenALPlugin", "primAlIsBuffer", (void*)primAlIsBuffer},
	{"OpenALPlugin", "primAlBufferData", (void*)primAlBufferData},
	{"OpenALPlugin", "primAlGetBufferf", (void*)primAlGetBufferf},
	{"OpenALPlugin", "primAlGetBufferi", (void*)primAlGetBufferi},
	{"OpenALPlugin", "primAlGenSources", (void*)primAlGenSources},
	{"OpenALPlugin", "primAlDeleteSources", (void*)primAlDeleteSources},
	{"OpenALPlugin", "primAlIsSource", (void*)primAlIsSource},
	{"OpenALPlugin", "primAlSourcef", (void*)primAlSourcef},
	{"OpenALPlugin", "primAlSourcefv", (void*)primAlSourcefv},
	{"OpenALPlugin", "primAlSource3f", (void*)primAlSource3f},
	{"OpenALPlugin", "primAlSourcei", (void*)primAlSourcei},
	{"OpenALPlugin", "primAlGetSourcef", (void*)primAlGetSourcef},
	{"OpenALPlugin", "primAlGetSourcefv", (void*)primAlGetSourcefv},
	{"OpenALPlugin", "primAlGetSourcei", (void*)primAlGetSourcei},
	{"OpenALPlugin", "primAlSourcePlay", (void*)primAlSourcePlay},
	{"OpenALPlugin", "primAlSourcePlayv", (void*)primAlSourcePlayv},
	{"OpenALPlugin", "primAlSourcePause", (void*)primAlSourcePause},
	{"OpenALPlugin", "primAlSourcePausev", (void*)primAlSourcePausev},
	{"OpenALPlugin", "primAlSourceStop", (void*)primAlSourceStop},
	{"OpenALPlugin", "primAlSourceStopv", (void*)primAlSourceStopv},
	{"OpenALPlugin", "primAlSourceRewind", (void*)primAlSourceRewind},
	{"OpenALPlugin", "primAlSourceRewindv", (void*)primAlSourceRewindv},
	{"OpenALPlugin", "primAlSourceQueueBuffers", (void*)primAlSourceQueueBuffers},
	{"OpenALPlugin", "primAlSourceUnqueueBuffers", (void*)primAlSourceUnqueueBuffers},
	{"OpenALPlugin", "primAlListenerf", (void*)primAlListenerf};
	{"OpenALPlugin", "primAlListener3f", (void*)primAlListener3f};
	{"OpenALPlugin", "primAlListenerfv", (void*)primAlListenerfv};
	{"OpenALPlugin", "primAlListeneri", (void*)primAlListeneri};
	{"OpenALPlugin", "primAlGetListenerf", (void*)primAlGetListenerf};
	{"OpenALPlugin", "primAlGetListener3f", (void*)primAlGetListener3f};
	{"OpenALPlugin", "primAlGetListenerfv", (void*)primAlGetListenerfv};
	{"OpenALPlugin", "primAlGetListeneri", (void*)primAlGetListeneri};
	{"OpenALPlugin", "primAlutInit", (void*)primAlutInit},
	{"OpenALPlugin", "primAlutExit", (void*)primAlutExit},
	{"OpenALPlugin", "primAlutLoadWAVFile", (void*)primAlutLoadWAVFile},
	{"OpenALPlugin", "primAlutLoadWAVFile", (void*)primAlutUnloadWAVFile},
	{"OpenALPlugin", "primAlutLoadWAVMemory", (void*)primAlutLoadWAVMemory},
	{"OpenALPlugin", "primAlutUnloadWAV", (void*)primAlutUnloadWAV},
	{"OpenALPlugin", "primAlEnable", (void*)primAlEnable},
	{"OpenALPlugin", "primAlDisable", (void*)primAlDisable},
	{"OpenALPlugin", "primAlIsEnabled", (void*)primAlIsEnabled},
	{"OpenALPlugin", "primAlGetBoolean", (void*)primAlGetBoolean},
	{"OpenALPlugin", "primAlGetDouble", (void*)primAlGetDouble},
	{"OpenALPlugin", "primAlGetFloat", (void*)primAlGetFloat},
	{"OpenALPlugin", "primAlGetInteger", (void*)primAlGetInteger},
	{"OpenALPlugin", "primAlGetBooleanv", (void*)primAlGetBooleanv},
	{"OpenALPlugin", "primAlGetDoublev", (void*)primAlGetDoublev},
	{"OpenALPlugin", "primAlGetFloatv", (void*)primAlGetFloatv},
	{"OpenALPlugin", "primAlGetIntegerv", (void*)primAlGetIntegerv},
	{"OpenALPlugin", "primAlGetString", (void*)primAlGetString},
	{"OpenALPlugin", "primAlDistanceModel", (void*)primAlDistanceModel},
	{"OpenALPlugin", "primAlDopplerFactor", (void*)primAlDopplerFactor},
	{"OpenALPlugin", "primAlDopplerVelocity", (void*)primAlDopplerVelocity},

#if defined (__APPLE__) && defined(__MACH__)
	//a few osx specific al functions
	{"OpenALPlugin", "primAlDistanceScale", (void*)primAlDistanceScale},
	{"OpenALPlugin", "primAlPropagationSpeed", (void*)primAlPropagationSpeed},
#endif

	{"OpenALPlugin", "primAlcCreateContext", (void*)primAlcCreateContext},
	{"OpenALPlugin", "primAlcMakeContextCurrentr", (void*) primAlcMakeContextCurrent},
	{"OpenALPlugin", "primAlcProcessContext", (void*)primAlcProcessContext},
	{"OpenALPlugin", "primAlcSuspendContext", (void*)primAlcSuspendContext},
	{"OpenALPlugin", "primAlcDestroyContext", (void*)primAlcDestroyContext},
	{"OpenALPlugin", "primAlcGetError", (void*)primAlcGetError},
	{"OpenALPlugin", "primAlcGetCurrentContext", (void*)primAlcGetCurrentContext},
	{"OpenALPlugin", "primAlcOpenDevice", (void*)primAlcOpenDevice},
	{"OpenALPlugin", "primAlcCloseDevice", (void*)primAlcCloseDevice},
	{"OpenALPlugin", "primAlcIsExtensionPresent", (void*)primAlcIsExtensionPresent},
	{"OpenALPlugin", "primAlcGetProcAddress", (void*)primAlcGetProcAddress},
	{"OpenALPlugin", "primAlcGetEnumValue", (void*)primAlcGetEnumValue},
	{"OpenALPlugin", "primAlcGetString", (void*)primAlcGetString},
	{"OpenALPlugin", "primAlcGetIntegerv", (void*)primAlcGetIntegerv},
	{"OpenALPlugin", "getModuleName", (void*)getModuleName},
	{"OpenALPlugin", "initialiseModule", (void*)initialiseModule},
	{"OpenALPlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */







