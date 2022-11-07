/* sqVirtualMachineInterce.c -- implementation of the standard VM embedding interface
 *
 *   Copyright (C) 2016 by Ronie Salgado
 *   All rights reserved.
 *
 *   This file is part of Minimalistic Headless OpenSmalltalk.
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
#include <dirent.h>
#include <sys/stat.h>
#endif

#include <stdio.h>
#include <string.h>

#include "OpenSmalltalkVM.h"
#include "sq.h"
#include "sqSCCSVersion.h"
#include "sqTextEncoding.h"
#include "sqImageFileAccess.h"

#define DefaultHeapSize		  20	     	/* megabytes BEYOND actual image size */
#define DefaultMmapSize		1024     	/* megabytes of virtual memory */

struct OSVMInstance
{
    int singletonInitialized;
};

/**
 * Some VM options
 */
extern int sqVMOptionTraceModuleLoading;

extern int osvm_isFile(const char *path);
extern int osvm_findImagesInFolder(const char *searchPath, char *imagePathBuffer, size_t imagePathBufferSize);


static struct OSVMInstance osvmInstanceSingleton;

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

const char *
getAttributeString(sqInt id)
{
    if (id < 0)	{ // VM argument
        if (-id  < vmArgumentCount)
        	return vmArgumentVector[-id];
        return 0;
    }

    switch (id) {
    case 0: // VM name
        return vmName[0] ? vmName : vmArgumentVector[0];
    case 1: // image name
        return imageName;
    case 1001: // OS type: "unix", "win32", "mac", ...
        return OS_TYPE;
    case 1002: // OS name: e.g. "solaris2.5" on unix, "win95" on win32, ...
        return VM_TARGET_OS;
    case 1003: // processor architecture: e.g. "68k", "x86", "PowerPC", ...
        return VM_TARGET_CPU;
    case 1004: // Interpreter version string
        return  (char *)interpreterVersion;
    case 1005: // window system name
        return  (char*)ioWindowSystemName();
    case 1006: // vm build string
        return VM_BUILD_STRING;
#if STACKVM
    case 1007: { // interpreter build info
        extern char *__interpBuildInfo;
        return (const char *)__interpBuildInfo;
    }
# if COGVM
    case 1008: { // cogit build info
        extern char *__cogitBuildInfo;
        return (const char *)__cogitBuildInfo;
    }
# endif
#endif

    case 1009: // source tree version info
        return (const char *)sourceVersionString(' ');

    default:
        if ((id - 2) < squeakArgumentCount)
            return squeakArgumentVector[id - 2];
    }
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
  char *info = (char *)malloc(4096);
  info[0] = '\0';

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
  sprintf(info+strlen(info), " [" BuildVariant HBID " %s VM]\n", getAttributeString(1003)); // 1003 == processor
  if (verbose)
    sprintf(info+strlen(info), "Built from: ");
  sprintf(info+strlen(info), "%s\n", INTERP_BUILD);
#if COGVM
  if (verbose)
    sprintf(info+strlen(info), "With: ");
  sprintf(info+strlen(info), "%s\n", getAttributeString(1008)); // 1008 == __cogitBuildInfo
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
    else if(IS_VM_OPTION("nosound"))
    {
        /* Ignore this option. For compatibility with Smalltalk CI. */
        return 1;
    }
    else if(IS_VM_OPTION("vm-display-null"))
    {
        /* For compatibility with Smalltalk CI. */
        headlessMode = 1;
        return 1;
    }
#ifdef __APPLE__
    else if(IS_VM_OPTION("NSDocumentRevisionsDebugMode"))
    {
        return 2;
    }
    else if(!strncmp(*argv, "-psn", 4))
    {
        return 1;
    }
#endif
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

#ifndef _WIN32
int
osvm_isFile(const char *path)
{
    struct stat s;
    if(stat(path, &s) == 0)
        return s.st_mode & S_IFREG;

    return 0;
}

int
osvm_findImagesInFolder(const char *searchPath, char *imagePathBuffer, size_t imagePathBufferSize)
{
    struct dirent *entry;
    int result = 0;
    DIR *dir = opendir(searchPath);
    if(!dir)
        return 0;

    while((entry = readdir(dir)) != NULL)
    {
        char *name = entry->d_name;
        char *extension = strrchr(name, '.');
        if(!extension)
            continue;

        if(strcmp(extension, ".image") != 0)
            continue;

        if(result == 0)
            snprintf(imagePathBuffer, imagePathBufferSize, "%s/%s", searchPath, name);
        ++result;
    }
    closedir(dir);

    return result;
}
#endif

OSVM_VM_CORE_PUBLIC int
osvm_findStartupImage(const char *vmExecutablePath, char **startupImagePathResult)
{
    char *imagePathBuffer = osvm_malloc(FILENAME_MAX+1);
    char *vmPathBuffer = osvm_malloc(FILENAME_MAX+1);
    char *searchPathBuffer = osvm_malloc(FILENAME_MAX+1);
    if(osvm_isFile(vmExecutablePath))
        findExecutablePath(vmExecutablePath, vmPathBuffer, FILENAME_MAX+1);
    else
        strcpy(vmPathBuffer, vmExecutablePath);

    if(startupImagePathResult)
        *startupImagePathResult = NULL;

    // Find the mandatory startup.image.
    sqPathJoin(imagePathBuffer, FILENAME_MAX+1, vmPathBuffer, "startup.image");
    if(osvm_isFile(imagePathBuffer))
    {
        if(startupImagePathResult)
            *startupImagePathResult = imagePathBuffer;
        else
            osvm_free(imagePathBuffer);
        osvm_free(vmPathBuffer);
        osvm_free(searchPathBuffer);
        return 1;
    }

#ifdef __APPLE__
    sqPathJoin(imagePathBuffer, FILENAME_MAX+1, vmPathBuffer, "../Resources/startup.image");
    if(osvm_isFile(imagePathBuffer))
    {
        if(startupImagePathResult)
            *startupImagePathResult = imagePathBuffer;
        else
            osvm_free(imagePathBuffer);
        osvm_free(vmPathBuffer);
        osvm_free(searchPathBuffer);
        return 1;
    }

    sqPathJoin(imagePathBuffer, FILENAME_MAX+1, vmPathBuffer, "../../../startup.image");
    if(osvm_isFile(imagePathBuffer))
    {
        if(startupImagePathResult)
            *startupImagePathResult = imagePathBuffer;
        else
            osvm_free(imagePathBuffer);
        osvm_free(vmPathBuffer);
        osvm_free(searchPathBuffer);
        return 1;
    }

#endif

    // Find automatically an image.
    int foundImageCount = 0;

    // Search on the VM executable path.
    foundImageCount += osvm_findImagesInFolder(vmPathBuffer, imagePathBuffer, FILENAME_MAX+1);

#ifdef __APPLE__
    // Search along the bundled resources.
    sqPathJoin(searchPathBuffer, FILENAME_MAX+1, vmPathBuffer, "../Resources");
    foundImageCount += osvm_findImagesInFolder(searchPathBuffer, imagePathBuffer, FILENAME_MAX+1);

    // Search in the folder that contains the bundle.
    sqPathJoin(searchPathBuffer, FILENAME_MAX+1, vmPathBuffer, "../../..");
    char *realBundlePath = osvm_malloc(FILENAME_MAX+1);
    realpath(searchPathBuffer, realBundlePath);

    sqGetCurrentWorkingDir(searchPathBuffer, FILENAME_MAX+1);
    if(strcmp(realBundlePath, searchPathBuffer) != 0)
        foundImageCount += osvm_findImagesInFolder(realBundlePath, imagePathBuffer, FILENAME_MAX+1);

    osvm_free(realBundlePath);
#endif

    // Search in the current working directory.
    sqGetCurrentWorkingDir(searchPathBuffer, FILENAME_MAX+1);
    if(strcmp(searchPathBuffer, vmPathBuffer) != 0)
        foundImageCount += osvm_findImagesInFolder(searchPathBuffer, imagePathBuffer, FILENAME_MAX+1);

    osvm_free(vmPathBuffer);
    osvm_free(searchPathBuffer);
    if(foundImageCount == 1)
    {
        if(startupImagePathResult)
            *startupImagePathResult = imagePathBuffer;
        else
            osvm_free(imagePathBuffer);
        return 1;
    }
    else
    {
        // The image is not found or it is ambiguous.
        osvm_free(imagePathBuffer);
        return 0;
    }
}

OSVM_VM_CORE_PUBLIC void *
osvm_malloc(size_t size)
{
    return malloc(size);
}

OSVM_VM_CORE_PUBLIC void *
osvm_calloc(size_t nmemb, size_t size)
{
    return calloc(nmemb, size);
}

OSVM_VM_CORE_PUBLIC void
osvm_free(void* pointer)
{
    return free(pointer);
}

OSVM_VM_CORE_PUBLIC uint16_t*
osvm_utf8ToUtf16(const char *string)
{
    return sqUTF8ToUTF16New(string);
}

OSVM_VM_CORE_PUBLIC char*
osvm_utf16ToUt8(const uint16_t *wstring)
{
    return sqUTF16ToUTF8New(wstring);
}

OSVM_VM_CORE_PUBLIC int
osvm_getInterfaceVersion()
{
    return OSVM_VM_CORE_COMPILED_VERSION;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_loadImage(OSVMInstanceHandle vmHandle, const char *fileName)
{
    size_t imageSize = 0;
    sqImageFile imageFile = 0;

    if(!vmHandle)
        return OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE;

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
osvm_loadDefaultImage(OSVMInstanceHandle vmHandle)
{
    OSVMError error;

    if(!vmHandle)
        return OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE;

    /* If the image name is empty, try to load the default image. */
    if(!shortImageName[0])
    {
        char *startupImage;
        if(osvm_findStartupImage(vmPath, &startupImage))
        {
            strcpy(shortImageName, startupImage);
            osvm_free(startupImage);
        }
        else
        {
            return OSVM_ERROR_FAILED_TO_FIND_IMAGE;
        }
    }

    /* Try to load the image as was passed. */
    sprintf(tempImageNameAttempt, "%s", shortImageName);
    error = osvm_loadImage(vmHandle, tempImageNameAttempt);
    if(!error)
        return OSVM_SUCCESS;

    /* Make the image path relative to the VM*/
    sprintf(tempImageNameAttempt, "%s/%s", vmPath, shortImageName);
    error = osvm_loadImage(vmHandle, tempImageNameAttempt);
    if(!error)
        return OSVM_SUCCESS;

    /* Failed. */
    return OSVM_ERROR_FAILED_TO_OPEN_FILE;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_initialize(OSVMInstanceHandle *resultVMHandle)
{
    if(!resultVMHandle)
        return OSVM_ERROR_NULL_POINTER;

    if(osvmInstanceSingleton.singletonInitialized)
        return OSVM_ERROR_VM_IMPLEMENTATION_NON_REENTRANT;

    /* check the interpreter's size assumptions for basic data types */
    if (sizeof(int) != 4) error("This C compiler's integers are not 32 bits.");
    if (sizeof(double) != 8) error("This C compiler's floats are not 64 bits.");
    if (sizeof(sqLong) != 8) error("This C compiler's long longs are not 64 bits.");

    argCnt = 0;
    argVec = emptyArgumentVector;
    envVec = emptyEnvironmentVector;

    /* Initialize the list of internal primitives. */
    ioInitializeInternalPluginPrimitives();

    /* Perform platform specific initialization. */
    ioInitPlatformSpecific();

    osvmInstanceSingleton.singletonInitialized = 1;
    *resultVMHandle = &osvmInstanceSingleton;

    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_shutdown(OSVMInstanceHandle vmHandle)
{
    if(!vmHandle)
        return OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE;

    osvmInstanceSingleton.singletonInitialized = 0;
    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC int
osvm_getVMCommandLineArgumentParameterCount(const char *argument)
{
#ifdef __APPLE__
    if(!strcmp(argument, "-NSDocumentRevisionsDebugMode"))
        return 1;
#endif

    return 0;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_parseCommandLineArguments(OSVMInstanceHandle vmHandle, int argc, const char **argv)
{
    if(!vmHandle)
        return OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE;

    /* Make parameters global for access from plugins */
    argCnt = argc;
    argVec = (char**)argv;
    envVec = NULL;

    /* Allocate arrays to store copies of pointers to command line
        arguments.  Used by getAttributeString(). */
    if ((vmArgumentVector = calloc(argc + 1, sizeof(char *))) == 0)
        outOfMemory();

    if ((squeakArgumentVector = calloc(argc + 1, sizeof(char *))) == 0)
        outOfMemory();

    recordPathsForVMName(argv[0]); /* full vm path */
    squeakPlugins = vmPath;		/* default plugin location is VM directory */
    sqPathMakeAbsolute(vmName, sizeof(vmName), argv[0]);
#ifdef __APPLE__
    sqPathJoin(squeakExtraPluginsPath, sizeof(squeakExtraPluginsPath), squeakPlugins, "Plugins");
    strcat(squeakExtraPluginsPath, "/");
#endif
    return parseArguments(argc, (char**)argv);
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_parseVMCommandLineArguments(OSVMInstanceHandle vmHandle, int argc, const char **argv)
{
    if(!vmHandle)
        return OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE;
    return OSVM_ERROR_NOT_YET_IMPLEMENTED;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_setVMStringParameter(OSVMInstanceHandle vmHandle, const char *name, const char *value)
{
    if(!vmHandle)
        return OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE;
    return OSVM_ERROR_UNSUPPORTED_PARAMETER;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_setVMIntegerParameter(OSVMInstanceHandle vmHandle, const char *name, const char *value)
{
    if(!vmHandle)
        return OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE;
    return OSVM_ERROR_UNSUPPORTED_PARAMETER;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_passImageCommandLineArguments(OSVMInstanceHandle vmHandle, int argc, const char **argv)
{
    if(!vmHandle)
        return OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE;
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
osvm_run(OSVMInstanceHandle vmHandle)
{
    if(!vmHandle)
        return OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE;

    sqExecuteFunctionWithCrashExceptionCatching(&osvm_doRunInterpreter, NULL);
    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_initializeVM(OSVMInstanceHandle vmHandle)
{
    if(!vmHandle)
        return OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE;

    ioInitWindowSystem(headlessMode);
    ioInitTime();
    ioInitThreads();
    ioVMThread = ioCurrentOSThread();
    aioInit();

    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_shutdownVM(OSVMInstanceHandle vmHandle)
{
    if(!vmHandle)
        return OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE;
    return OSVM_SUCCESS;
}

OSVM_VM_CORE_PUBLIC OSVMError
osvm_main(int argc, const char **argv)
{
    OSVMError error;
    OSVMInstanceHandle vmHandle;

    /* Global initialization */
    error = osvm_initialize(&vmHandle);
    if(error)
        return error;

    /* Parse the command line*/
    error = osvm_parseCommandLineArguments(vmHandle, argc, argv);
    if(error)
        return error;

    /* Initialize the VM */
    error = osvm_initializeVM(vmHandle);
    if(error)
        return error;

    /* Load the command line image or the default one. */
    error = osvm_loadDefaultImage(vmHandle);
    if(error)
        return error;

    /* Run OpenSmalltalk */
    error = osvm_run(vmHandle);

    /* Shutdown*/
    osvm_shutdown(vmHandle);

    return error;
}
