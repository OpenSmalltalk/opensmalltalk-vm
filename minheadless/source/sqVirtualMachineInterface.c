#ifndef _WIN32
#include <unistd.h>
#endif

#include <stdio.h>
#include <string.h>

#include "SqueakVirtualMachine.h"
#include "sq.h"
#include "sqGitVersionString.h"

#define DefaultHeapSize		  20	     	/* megabytes BEYOND actual image size */
#define DefaultMmapSize		1024     	/* megabytes of virtual memory */

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

static int squeakArgumentCount;
static char **squeakArgumentVector;

static int vmArgumentCount;
static char **vmArgumentVector;

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

#if defined(__GNUC__) && ( defined(i386) || defined(__i386) || defined(__i386__)  \
			|| defined(i486) || defined(__i486) || defined (__i486__) \
			|| defined(intel) || defined(x86) || defined(i86pc) )
  static void fldcw(unsigned int cw)
  {
    __asm__("fldcw %0" :: "m"(cw));
  }
#else
# define fldcw(cw)
#endif

#if defined(__GNUC__) && ( defined(ppc) || defined(__ppc) || defined(__ppc__)  \
			|| defined(POWERPC) || defined(__POWERPC) || defined (__POWERPC__) )
  void mtfsfi(unsigned long long fpscr)
  {
    __asm__("lfd   f0, %0" :: "m"(fpscr));
    __asm__("mtfsf 0xff, f0");
  }
#else
# define mtfsfi(fpscr)
#endif

char *getImageName(void)
{
    return imageName;
}

const char *sqGetCurrentImagePath()
{
    return imagePath;
}

sqInt imageNameGetLength(sqInt sqImageNameIndex, sqInt length)
{
    char *sqImageName = pointerForOop(sqImageNameIndex);
    int count;

    count= strlen(imageName);
    count= (length < count) ? length : count;

    /* copy the file name into the Squeak string */
    memcpy(sqImageName, imageName, count);

    return count;
}

sqInt imageNamePutLength(sqInt sqImageNameIndex, sqInt length)
{
    char *sqImageName= pointerForOop(sqImageNameIndex);
    int count;

    count = (length >= sizeof(imageName)) ? sizeof(imageName) - 1 : length;

    /* copy the file name into a null-terminated C string */
    memcpy(imageName, sqImageName, count);
    imageName[count] = 0;

    return count;
}

sqInt imageNameSize(void)
{
    return strlen(imageName);
}

sqInt vmPathSize(void)
{
    return strlen(vmPath);
}

sqInt vmPathGetLength(sqInt sqVMPathIndex, sqInt length)
{
    char *stVMPath= pointerForOop(sqVMPathIndex);
    int count;

    count = strlen(vmPath);
    count = (length < count) ? length : count;

    /* copy the file name into the Squeak string */
    memcpy(stVMPath, vmPath, count);

    return count;
}

char* ioGetLogDirectory(void)
{
    return "";
}

sqInt ioSetLogDirectoryOfSize(void* lblIndex, sqInt sz)
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
        return SOURCE_VERSION_STRING;

    default:
        if ((id - 2) < squeakArgumentCount)
            return squeakArgumentVector[id - 2];
    }
    success(false);
    return "";
}

sqInt attributeSize(sqInt id)
{
    return strlen(GetAttributeString(id));
}

sqInt getAttributeIntoLength(sqInt id, sqInt byteArrayIndex, sqInt length)
{
    if (length > 0)
        strncpy(pointerForOop(byteArrayIndex), GetAttributeString(id), length);
    return 0;
}

static void outOfMemory(void)
{
  /* pushing stderr outputs the error report on stderr instead of stdout */
  /* pushOutputFile((char *)STDERR_FILENO); */
  error("out of memory\n");
}

static void recordPathsForVMName(const char *localVmName)
{
    findExecutablePath(localVmName, vmPath, sizeof(vmPath));
}

static void usage(void)
{
}

static int parseArguments(int argc, char **argv)
{
# define skipArg()	(--argc, argv++)
# define saveArg()	(vmArgumentVector[vmArgumentCount++]= *skipArg())

    saveArg();	/* vm name */

    while ((argc > 0) && (**argv == '-'))	/* more options to parse */
    {
        int n= 0;
        if (!strcmp(*argv, "--"))		/* escape from option processing */
            break;

        if (!strcmp(*argv, "-headless") || !strcmp(*argv, "--headless"))
        {
            headlessMode = 1;
            n = 1;
        }
        else if(!strcmp(*argv, "-interactive") || !strcmp(*argv, "--interactive"))
        {
            headlessMode = 0;
            n = 1;
        }

        if (n == 0)			/* option not recognised */
        {
            fprintf(stderr, "unknown option: %s\n", argv[0]);
            usage();
            return SQUEAK_ERROR_UNSUPPORTED_PARAMETER;
        }

        while (n--)
            saveArg();
    }

    if (!argc)
        return SQUEAK_SUCCESS;
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
    return SQUEAK_SUCCESS;
}

SQUEAK_VM_CORE_PUBLIC int squeak_getInterfaceVersion()
{
    return SQUEAK_VM_CORE_COMPILED_VERSION;
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_loadImage(const char *fileName)
{
    size_t imageSize = 0;
    sqImageFile imageFile = 0;

    /* Open the image file. */
    imageFile = sqImageFileOpen(fileName, "rb");
    if(!imageFile)
        return SQUEAK_ERROR_FAILED_TO_OPEN_FILE;

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

    sqPathMakeAbsolute(imageName, sizeof(imageName), fileName);
    sqPathExtractDirname(imagePath, sizeof(imagePath), imageName);
    return SQUEAK_SUCCESS;
}

static char tempImageNameAttempt[FILENAME_MAX];
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_loadDefaultImage(void)
{
    SqueakError error;

    /* If the image name is empty, try to load the default image. */
    if(!shortImageName[0])
        strcpy(shortImageName, DEFAULT_IMAGE_NAME);

    /* Try to load the image as was passed. */
    sprintf(tempImageNameAttempt, "%s", shortImageName);
    error = squeak_loadImage(tempImageNameAttempt);
    if(!error)
        return SQUEAK_SUCCESS;

    /* Make the image path relative to the VM*/
    sprintf(tempImageNameAttempt, "%s/%s", vmPath, shortImageName);
    error = squeak_loadImage(tempImageNameAttempt);
    if(!error)
        return SQUEAK_SUCCESS;

    /* Failed. */
    return SQUEAK_ERROR_FAILED_TO_OPEN_FILE;
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_initialize(void)
{
    /* check the interpreter's size assumptions for basic data types */
    if (sizeof(int) != 4) error("This C compiler's integers are not 32 bits.");
    if (sizeof(double) != 8) error("This C compiler's floats are not 64 bits.");
    if (sizeof(sqLong) != 8) error("This C compiler's long longs are not 64 bits.");

    fldcw(0x12bf);	/* signed infinity, round to nearest, REAL8, disable intrs, disable signals */
    mtfsfi(0);		/* disable signals, IEEE mode, round to nearest */

    argCnt = 0;
    argVec = emptyArgumentVector;
    envVec = emptyEnvironmentVector;

    initGlobalStructure();

    /* Initialize the list of internal primitives. */
    ioInitializeInternalPluginPrimitives();

    /* Perform platform specific initialization. */
    ioInitPlatformSpecific();

    return SQUEAK_SUCCESS;
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_shutdown(void)
{
    /* Nothing required yet. */
    return SQUEAK_SUCCESS;
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_parseCommandLineArguments(int argc, const char **argv)
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
    return parseArguments(argc, (char**)argv);
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_parseVMCommandLineArguments(int argc, const char **argv)
{
    return SQUEAK_ERROR_NOT_YET_IMPLEMENTED;
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_setVMStringParameter(const char *name, const char *value)
{
    return SQUEAK_ERROR_UNSUPPORTED_PARAMETER;
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_setVMIntegerParameter(const char *name, const char *value)
{
    return SQUEAK_ERROR_UNSUPPORTED_PARAMETER;
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_passImageCommandLineArguments(int argc, const char **argv)
{
    return SQUEAK_ERROR_NOT_YET_IMPLEMENTED;
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_run(void)
{
    interpret();
    return SQUEAK_SUCCESS;
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_initializeVM(void)
{
    ioInitWindowSystem(headlessMode);
    ioInitTime();
    ioInitThreads();
    ioVMThread = ioCurrentOSThread();
    aioInit();

    return SQUEAK_SUCCESS;
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_shutdownVM(void)
{
    return SQUEAK_SUCCESS;
}

SQUEAK_VM_CORE_PUBLIC SqueakError squeak_main(int argc, const char **argv)
{
    SqueakError error;

    /* Global initialization */
    error = squeak_initialize();
    if(error)
        return error;

    /* Parse the command line*/
    error = squeak_parseCommandLineArguments(argc, argv);
    if(error)
        return error;

    /* Initialize the VM */
    error = squeak_initializeVM();
    if(error)
        return error;

    /* Load the command line image or the default one. */
    error = squeak_loadDefaultImage();
    if(error)
        return error;

    /* Run Squeak */
    error = squeak_run();

    /* Shutdown*/
    squeak_shutdown();

    return error;
}
