#include <stdio.h>
#include <string.h>

#include "sq.h"
#include "sqSCCSVersion.h"

#define DefaultHeapSize		  20	     	/* megabytes BEYOND actual image size */
#define DefaultMmapSize		1024     	/* megabytes of virtual memory */

char imageName[FILENAME_MAX];

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

extern void ioInitTime(void);
extern void ioInitThreads(void);
extern void aioInit(void);

static long   extraMemory=	0;
int    useMmap=		DefaultMmapSize * 1024 * 1024;

char *getImageName(void)
{
    return imageName;
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
    //printf("GetAttributeString %d\n", id);
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
        return  "null";
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

static int isAbsolutePath(const char *path)
{
#ifdef _WIN32
    return *path == '\\' || (path[0] != 0 && && path[1] == ':');
#else
    /* Assume UNIX style path. */
    return *path == '/';
#endif
}

static void recordPathsForVMName(const char *localVmName)
{
    const char *lastSeparator = strrchr(localVmName, '/');
#ifdef _WIN32
    const char *lastSeparator2 = strrchr(localVmName, '\\');
    if(!lastSeparator || lastSeparator < lastSeparator2)
        lastSeparator = lastSeparator2;
#endif

    if(!isAbsolutePath(localVmName))
    {
        /* TODO: Get the current working directory*/
        strcpy(vmPath, "./");
    }

    if(lastSeparator)
        strncat(vmPath, localVmName, lastSeparator - localVmName + 1);
}

static void usage(void)
{
}

static void parseArguments(int argc, char **argv)
{
# define skipArg()	(--argc, argv++)
# define saveArg()	(vmArgumentVector[vmArgumentCount++]= *skipArg())

    saveArg();	/* vm name */

    while ((argc > 0) && (**argv == '-'))	/* more options to parse */
    {
        int n= 0;
        if (!strcmp(*argv, "--"))		/* escape from option processing */
            break;
        if (n == 0)			/* option not recognised */
        {
            fprintf(stderr, "unknown option: %s\n", argv[0]);
            usage();
        }

        while (n--)
            saveArg();
    }

    if (!argc)
        return;
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
}

static int tryToLoadImageFromFileName(const char *fileName)
{
    size_t imageSize = 0;
    FILE *imageFile = 0;

    /* Open the image file. */
    imageFile = fopen(fileName, "rb");
    if(!imageFile)
        return 0;

    /* Get the size of the image file*/
    fseek(imageFile, 0, SEEK_END);
    imageSize = ftell(imageFile);
    fseek(imageFile, 0, SEEK_SET);

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

    strcpy(imageName, shortImageName);
    return 1;
}

void imgInit()
{
    /* Try to load the image as was passed. */
    if(tryToLoadImageFromFileName(shortImageName))
        return;

    /* Make the image path relative to the VM*/
    sprintf(imageName, "%s/%s", vmPath, shortImageName);
    if(tryToLoadImageFromFileName(imageName))
        return;

    /* Failed. */
    fprintf(stderr, "Failed to open image file named: %s\n", shortImageName);
    exit(1);
}

int main(int argc, char *argv[], char *envp[])
{
    /* check the interpreter's size assumptions for basic data types */
    if (sizeof(int) != 4) error("This C compiler's integers are not 32 bits.");
    if (sizeof(double) != 8) error("This C compiler's floats are not 64 bits.");
    if (sizeof(sqLong) != 8) error("This C compiler's long longs are not 64 bits.");


    /* Make parameters global for access from plugins */

    argCnt= argc;
    argVec= argv;
    envVec= envp;

    initGlobalStructure();

    /* Allocate arrays to store copies of pointers to command line
        arguments.  Used by getAttributeIntoLength(). */
    if ((vmArgumentVector = calloc(argc + 1, sizeof(char *))) == 0)
        outOfMemory();

    if ((squeakArgumentVector = calloc(argc + 1, sizeof(char *))) == 0)
        outOfMemory();

    recordPathsForVMName(argv[0]); /* full vm path */
    squeakPlugins = vmPath;		/* default plugin location is VM directory */
    parseArguments(argc, argv);

    /* Initialize the VM */
    ioInitTime();
    ioInitThreads();
    aioInit();
    imgInit();

    /* run Squeak */
    printf("Running interpreter\n");
    interpret();

    return 0;
}
