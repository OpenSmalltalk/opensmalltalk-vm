/* sqVirtualMachineInterce.c -- implementation of the standard VM embedding interface
 *
 *   Copyright (C) 2016 by Ronie Salgado
 *   All rights reserved.
 *
 *   This file is part of Minimalistic Headless Squeak.
 *
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 *
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 *
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 * Author: roniesalg@gmail.com
 */

#ifndef _WIN32
#include <unistd.h>
#endif

#include <stdio.h>
#include <string.h>

#include "OpenSmalltalkVM.h"
#include "sq.h"
#include "sqSCCSVersion.h"

#define DefaultHeapSize		  20	     	/* megabytes BEYOND actual image size */
#define DefaultMmapSize		1024     	/* megabytes of virtual memory */

/**
 * Some VM options
 */
extern int sqVMOptionTraceModuleLoading;


char imageName[FILENAME_MAX];
static char imagePath[FILENAME_MAX];

static int headlessMode = 0;

static char *emptyArgumentVector[] = {
    NULL,
};
static char *emptyEnvironmentVector[] = {
    NULL,
};

int    argCnt=		0;	/* global copies for access from plugins */
char **argVec=		0;
char **envVec=		0;
char *squeakPlugins;

char *documentName = 0;
static char shortImageName[FILENAME_MAX];
static char vmName[FILENAME_MAX];
static char vmPath[FILENAME_MAX];
char squeakExtraPluginsPath[FILENAME_MAX];

static int squeakArgumentCount;
static char **squeakArgumentVector;

static int vmArgumentCount;
static char **vmArgumentVector;

int sqVMOptionInstallExceptionHandlers = 1;
int sqVMOptionBlockOnError = 0;
int sqVMOptionBlockOnWarn = 0;

extern void initGlobalStructure(void); // this is effectively null if a global register is not being used
extern void findExecutablePath(const char *localVmName, char *dest, size_t destSize);

extern void ioInitWindowSystem(sqInt headlessMode);
extern void ioShutdownWindowSystem(void);
extern const char *ioWindowSystemName(void);

extern void ioInitTime(void);
extern void ioInitThreads(void);
extern void aioInit(void);

#ifdef _WIN32
extern sqInt ioInitSecurity(void);
#endif

extern void ioInitPlatformSpecific(void);
extern void ioInitializeInternalPluginPrimitives(void);

static long   extraMemory=	0;
int    useMmap=		DefaultMmapSize * 1024 * 1024;

int
ioIsHeadless(void)
{
    return headlessMode;
}

char*
getImageName(void)
{
    return imageName;
}

const char*
sqGetCurrentImagePath()
{
    return imagePath;
}

sqInt
imageNameGetLength(sqInt sqImageNameIndex, sqInt length)
{
    char *sqImageName = pointerForOop(sqImageNameIndex);
    int count;

    count= strlen(imageName);
    count= (length < count) ? length : count;

    /* copy the file name into the Squeak string */
    memcpy(sqImageName, imageName, count);

    return count;
}

sqInt
imageNamePutLength(sqInt sqImageNameIndex, sqInt length)
{
    char *sqImageName= pointerForOop(sqImageNameIndex);
    int count;

    count = (length >= sizeof(imageName)) ? sizeof(imageName) - 1 : length;

    /* copy the file name into a null-terminated C string */
    memcpy(imageName, sqImageName, count);
    imageName[count] = 0;

    return count;
}

sqInt
imageNameSize(void)
{
    return strlen(imageName);
}

sqInt
vmPathSize(void)
{
    return strlen(vmPath);
}

sqInt
vmPathGetLength(sqInt sqVMPathIndex, sqInt length)
{
    char *stVMPath= pointerForOop(sqVMPathIndex);
    int count;

    count = strlen(vmPath);
    count = (length < count) ? length : count;

    /* copy the file name into the Squeak string */
    memcpy(stVMPath, vmPath, count);

    return count;
}

char*
ioGetLogDirectory(void)
{
    return "";
}

sqInt
ioSetLogDirectoryOfSize(void* lblIndex, sqInt sz)
{
    return 1;
}

/*** Access to system attributes and command-line arguments ***/


/* OS_TYPE may be set in configure.in and passed via the Makefile */

char *
GetAttributeString(sqInt id)
{
    if (id < 0)	/* VM argument */
    {
        if (-id  < vmArgumentCount)
        	return vmArgumentVector[-id];
        success(false);
        return "";
    }

    switch (id)
    {
    case 0:
        return vmName[0] ? vmName : vmArgumentVector[0];
    case 1:
        return imageName;
    case 1001:
        /* OS type: "unix", "win32", "mac", ... */
        return OS_TYPE;
    case 1002:
        /* OS name: e.g. "solaris2.5" on unix, "win95" on win32, ... */
        return VM_TARGET_OS;
    case 1003:
        /* processor architecture: e.g. "68k", "x86", "PowerPC", ...  */
        return VM_TARGET_CPU;
    case 1004:
        /* Interpreter version string */
        return  (char *)interpreterVersion;
    case 1005:
        /* window system name */
        return  (char*)ioWindowSystemName();
    case 1006:
        /* vm build string */
        return VM_BUILD_STRING;
#if STACKVM
    case 1007: { /* interpreter build info */
        extern char *__interpBuildInfo;
        return __interpBuildInfo;
    }
# if COGVM
    case 1008: { /* cogit build info */
        extern char *__cogitBuildInfo;
        return __cogitBuildInfo;
    }
# endif
#endif

    case 1009: /* source tree version info */
        return sourceVersionString(' ');

    default:
        if ((id - 2) < squeakArgumentCount)
            return squeakArgumentVector[id - 2];
    }
    success(false);
    return "";
}

sqInt
attributeSize(sqInt id)
{
    return strlen(GetAttributeString(id));
}

sqInt
getAttributeIntoLength(sqInt id, sqInt byteArrayIndex, sqInt length)
{
    if (length > 0)
        strncpy(pointerForOop(byteArrayIndex), GetAttributeString(id), length);
    return 0;
}

/**
 * FIXME: Check this malloc for memory leaks.
 */
char *getVersionInfo(int verbose)
{
#if STACKVM
  extern char *__interpBuildInfo;
# define INTERP_BUILD __interpBuildInfo
# if COGVM
  extern char *__cogitBuildInfo;
# endif
#else
# define INTERP_BUILD interpreterVersion
#endif
  extern char *revisionAsString();
  char *info= (char *)malloc(4096);
  info[0]= '\0';

#if SPURVM
# if BytesPerOop == 8
#	define ObjectMemory " Spur 64-bit"
# else
#	define ObjectMemory " Spur"
# endif
#else
# define ObjectMemory
#endif
#if defined(NDEBUG)
# define BuildVariant "Production" ObjectMemory
#elif DEBUGVM
# define BuildVariant "Debug" ObjectMemory
# else
# define BuildVariant "Assert" ObjectMemory
#endif

#if ITIMER_HEARTBEAT
# define HBID " ITHB"
#else
# define HBID
#endif

  if (verbose)
    sprintf(info+strlen(info), IMAGE_DIALECT_NAME " VM version: ");
  sprintf(info+strlen(info), "%s-%s ", VM_VERSION, revisionAsString());
#if defined(USE_XSHM)
  sprintf(info+strlen(info), " XShm");
#endif
  sprintf(info+strlen(info), " [" BuildVariant HBID " VM]\n");
  if (verbose)
    sprintf(info+strlen(info), "Built from: ");
  sprintf(info+strlen(info), "%s\n", INTERP_BUILD);
#if COGVM
  if (verbose)
    sprintf(info+strlen(info), "With: ");
  sprintf(info+strlen(info), "%s\n", GetAttributeString(1008)); /* __cogitBuildInfo */
#endif
  if (verbose)
    sprintf(info+strlen(info), "Revision: ");
  sprintf(info+strlen(info), "%s\n", sourceVersionString('\n'));
  sprintf(info+strlen(info), "plugin path: %s [default: %s]\n", squeakPlugins, vmPath);
  return info;
}

void
getCrashDumpFilenameInto(char *buf)
{
	/*
    strcpy(buf,vmLogDirA);
	vmLogDirA[0] && strcat(buf, "/");
    */
	strcat(buf, "crash.dmp");
}

static void
outOfMemory(void)
{
  /* pushing stderr outputs the error report on stderr instead of stdout */
  /* pushOutputFile((char *)STDERR_FILENO); */
  error("out of memory\n");
}

static void
recordPathsForVMName(const char *localVmName)
{
    findExecutablePath(localVmName, vmPath, sizeof(vmPath));
}

static void
usage(void)
{
}

static int
parseVMArgument(char **argv)
{
#define IS_VM_OPTION(name) (!strcmp(*argv, "-" name) || !strcmp(*argv, "--" name))
    if (IS_VM_OPTION("headless") || IS_VM_OPTION("no-interactive"))
    {
        headlessMode = 1;
        return 1;
    }
    else if(IS_VM_OPTION("interactive") || IS_VM_OPTION("headfull"))
    {
        headlessMode = 0;
        return 1;
    }
    else if(IS_VM_OPTION("trace-module-loads"))
    {
        sqVMOptionTraceModuleLoading = 1;
        return 1;
    }
    else if(IS_VM_OPTION("full-trace"))
    {
        /* This should enable all of the tracing options that are available. */
        sqVMOptionTraceModuleLoading = 1;
        return 1;
    }

#undef IS_VM_OPTION

    return 0;
}

static int
parseArguments(int argc, char **argv)
{
# define skipArg()	(--argc, argv++)
# define saveArg()	(vmArgumentVector[vmArgumentCount++]= *skipArg())

    saveArg();	/* vm name */

    while ((argc > 0) && (**argv == '-'))	/* more options to parse */
    {
        int n= 0;
        if (!strcmp(*argv, "--"))		/* escape from option processing */
            break;

        n = parseVMArgument(argv);

        if (n == 0)			/* option not recognised */
        {
            fprintf(stderr, "unknown option: %s\n", argv[0]);
            usage();
            return OSVM_ERROR_UNSUPPORTED_PARAMETER;
        }

        while (n--)
            saveArg();
    }

    if (!argc)
        return OSVM_SUCCESS;
    if (!strcmp(*argv, "--"))
        skipArg();
    else					/* image name */
    {
        if (!documentName)
            strcpy(shortImageName, saveArg());
        if (!strstr(shortImageName, ".image"))
            strcat(shortImageName, ".image");
    }

    /* save remaining arguments as Squeak arguments */
    while (argc > 0)
        squeakArgumentVector[squeakArgumentCount++]= *skipArg();

# undef saveArg
# undef skipArg
    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC int
osvm_getInterfaceVersion()
{
    return OSVM_VM_CORE_COMPILED_VERSION;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_loadImage(const char *fileName)
{
    size_t imageSize = 0;
    sqImageFile imageFile = 0;

    /* Open the image file. */
    imageFile = sqImageFileOpen(fileName, "rb");
    if(!imageFile)
        return OSVM_ERROR_FAILED_TO_OPEN_FILE;

    /* The security plugin requires an absolute path of the image.*/
    sqPathMakeAbsolute(imageName, sizeof(imageName), fileName);
    sqPathExtractDirname(imagePath, sizeof(imagePath), imageName);

    /* Get the size of the image file*/
    sqImageFileSeekEnd(imageFile, 0);
    imageSize = sqImageFilePosition(imageFile);
    sqImageFileSeek(imageFile, 0);

    if (extraMemory)
        useMmap= 0;
    else
        extraMemory = DefaultHeapSize * 1024 * 1024;
#    ifdef DEBUG_IMAGE
    printf("image size %ld + heap size %ld (useMmap = %d)\n", (long)sb.st_size, extraMemory, useMmap);
#    endif

#if SPURVM
    readImageFromFileHeapSizeStartingAt(imageFile, 0, 0);
#else
    extraMemory += (long)imageSize;
    readImageFromFileHeapSizeStartingAt(imageFile, extraMemory, 0);
#endif
    sqImageFileClose(imageFile);

    return OSVM_SUCCESS;
}

static char tempImageNameAttempt[FILENAME_MAX];
OSVM_VM_CORE_PUBLIC OSVMError
osvm_loadDefaultImage(void)
{
    OSVMError error;

    /* If the image name is empty, try to load the default image. */
    if(!shortImageName[0])
        strcpy(shortImageName, DEFAULT_IMAGE_NAME);

    /* Try to load the image as was passed. */
    sprintf(tempImageNameAttempt, "%s", shortImageName);
    error = osvm_loadImage(tempImageNameAttempt);
    if(!error)
        return OSVM_SUCCESS;

    /* Make the image path relative to the VM*/
    sprintf(tempImageNameAttempt, "%s/%s", vmPath, shortImageName);
    error = osvm_loadImage(tempImageNameAttempt);
    if(!error)
        return OSVM_SUCCESS;

    /* Failed. */
    return OSVM_ERROR_FAILED_TO_OPEN_FILE;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_initialize(void)
{
    /* check the interpreter's size assumptions for basic data types */
    if (sizeof(int) != 4) error("This C compiler's integers are not 32 bits.");
    if (sizeof(double) != 8) error("This C compiler's floats are not 64 bits.");
    if (sizeof(sqLong) != 8) error("This C compiler's long longs are not 64 bits.");

    argCnt = 0;
    argVec = emptyArgumentVector;
    envVec = emptyEnvironmentVector;

    initGlobalStructure();

    /* Initialize the list of internal primitives. */
    ioInitializeInternalPluginPrimitives();

    /* Perform platform specific initialization. */
    ioInitPlatformSpecific();

    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_shutdown(void)
{
    /* Nothing required yet. */
    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_parseCommandLineArguments(int argc, const char **argv)
{
    /* Make parameters global for access from plugins */
    argCnt = argc;
    argVec = (char**)argv;
    envVec = NULL;

    /* Allocate arrays to store copies of pointers to command line
        arguments.  Used by getAttributeIntoLength(). */
    if ((vmArgumentVector = calloc(argc + 1, sizeof(char *))) == 0)
        outOfMemory();

    if ((squeakArgumentVector = calloc(argc + 1, sizeof(char *))) == 0)
        outOfMemory();

    recordPathsForVMName(argv[0]); /* full vm path */
    squeakPlugins = vmPath;		/* default plugin location is VM directory */
    sqPathMakeAbsolute(vmName, sizeof(vmName), argv[0]);
#ifdef __APPLE__
    sqPathJoin(squeakExtraPluginsPath, sizeof(squeakExtraPluginsPath), squeakPlugins, "Plugins");
#endif
    return parseArguments(argc, (char**)argv);
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_parseVMCommandLineArguments(int argc, const char **argv)
{
    return OSVM_ERROR_NOT_YET_IMPLEMENTED;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_setVMStringParameter(const char *name, const char *value)
{
    return OSVM_ERROR_UNSUPPORTED_PARAMETER;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_setVMIntegerParameter(const char *name, const char *value)
{
    return OSVM_ERROR_UNSUPPORTED_PARAMETER;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_passImageCommandLineArguments(int argc, const char **argv)
{
    return OSVM_ERROR_NOT_YET_IMPLEMENTED;
}

static int
osvm_doRunInterpreter(void *userdata)
{
    (void)userdata;
    interpret();
    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_run(void)
{
    sqExecuteFunctionWithCrashExceptionCatching(&osvm_doRunInterpreter, NULL);
    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_initializeVM(void)
{
    ioInitWindowSystem(headlessMode);
    ioInitTime();
    ioInitThreads();
    ioVMThread = ioCurrentOSThread();
    aioInit();

    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_shutdownVM(void)
{
    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_main(int argc, const char **argv)
{
    OSVMError error;

    /* Global initialization */
    error = osvm_initialize();
    if(error)
        return error;

    /* Parse the command line*/
    error = osvm_parseCommandLineArguments(argc, argv);
    if(error)
        return error;

    /* Initialize the VM */
    error = osvm_initializeVM();
    if(error)
        return error;

    /* Load the command line image or the default one. */
    error = osvm_loadDefaultImage();
    if(error)
        return error;

    /* Run Squeak */
    error = osvm_run();

    /* Shutdown*/
    osvm_shutdown();

    return error;
}
