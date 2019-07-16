#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include "sq.h"
#include "config.h"

#include "debug.h"

#ifdef WIN32

#include "Windows.h"
#include "aioWin.h"

#endif

char* getVMName();
EXPORT(void) setVMName(const char* name);

EXPORT(void) setVMPath(const char* path);

char* getImageName();
void setImageName(const char* name);

int getVMArgumentCount();
char* getVMArgument(int index);

int getImageArgumentCount();
char* getImageArgument(int index);


char** getSystemSearchPaths();
char** getPluginPaths();

void setPharoCommandLineParameters(char** newVMParams, int newVMParamsCount, char** newImageParams, int newImageParamsCount);

void initGlobalStructure(void);
void ioInitExternalSemaphores(void);

void ceCheckForInterrupts(void);

sqInt nilObject(void);

long long getVMGMTOffset();

long aioPoll(long microSeconds);
void aioInit(void);

void ioInitTime(void);

EXPORT(int) fileExists(const char *aPath);

void parseArguments(int argc, char* argv[]);
int openFileDialog(char const * aTitle, char const * aDefaultPathAndFile, char const * filter, char ** selectedFile, char const * defaultFile);

EXPORT(char*) getFullPath(char const *relativePath, char* fullPath, int fullPathSize);

#ifndef NULL
#define NULL	0
#endif
