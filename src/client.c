#include "pharovm/pharo.h"
#include "pharovm/pharoClient.h"
#include "pharovm/fileDialog.h"
#include "pharovm/pathUtilities.h"

extern void setMaxStacksToPrint(sqInt anInteger);

#if defined(__GNUC__) && ( defined(i386) || defined(__i386) || defined(__i386__)  \
			|| defined(i486) || defined(__i486) || defined (__i486__) \
			|| defined(intel) || defined(x86) || defined(i86pc) )
static void fldcw(unsigned int cw)
{
    __asm__("fldcw %0" :: "m"(cw));
}
#else
#   define fldcw(cw)
#endif

#if defined(__GNUC__) && ( defined(ppc) || defined(__ppc) || defined(__ppc__)  \
			|| defined(POWERPC) || defined(__POWERPC) || defined (__POWERPC__) )
void mtfsfi(unsigned long long fpscr)
{
    __asm__("lfd   f0, %0" :: "m"(fpscr));
    __asm__("mtfsf 0xff, f0");
}
#else
#   define mtfsfi(fpscr)
#endif

static int loadPharoImage(const char* fileName);
static void* runVMThread(void* p);
static int runOnMainThread(VMParameters *parameters);
#if PHARO_VM_IN_WORKER_THREAD
static int runOnWorkerThread(VMParameters *parameters);
#endif

EXPORT(sqInt) runMainThreadWorker();

EXPORT(int) vmRunOnWorkerThread = 0;

//TODO: All this should be concentrated in an unique vm parameters structure.
EXPORT(int)
isVMRunOnWorkerThread(void)
{
    return vmRunOnWorkerThread;
}

EXPORT(int) vm_init(VMParameters* parameters)
{
	initGlobalStructure();

	//Unix Initialization specific
	fldcw(0x12bf);	/* signed infinity, round to nearest, REAL8, disable intrs, disable signals */
    mtfsfi(0);		/* disable signals, IEEE mode, round to nearest */

    ioInitTime();

#if PHARO_VM_IN_WORKER_THREAD
    ioVMThread = ioCurrentOSThread();
#endif
	ioInitExternalSemaphores();
	setMaxStacksToPrint(parameters->maxStackFramesToPrint);

	aioInit();

	setPharoCommandLineParameters(parameters->vmParameters.parameters, parameters->vmParameters.count,
			parameters->imageParameters.parameters, parameters->imageParameters.count);

	return loadPharoImage(parameters->imageFileName);
}

EXPORT(void)
vm_run_interpreter()
{
	interpret();
}

EXPORT(int)
vm_main_with_parameters(VMParameters *parameters)
{
	// HACK: In some cases we need to add an explicit --interactive option to the image.
	VMErrorCode error = vm_parameters_ensure_interactive_image_parameter(parameters);
	if (error) {
		return 1;
	}

	if(parameters->isDefaultImage && !parameters->defaultImageFound)
	{
		////logError("No image has been specified, and no default image has been found.\n");
		vm_printUsageTo(stdout);
		return 0;
	}
	installErrorHandlers();

	setProcessArguments(parameters->processArgc, parameters->processArgv);
	setProcessEnvironmentVector(parameters->environmentVector);

	logInfo("Opening Image: %s\n", parameters->imageFileName);

    //This initialization is required because it makes awful, awful, awful code to calculate
    //the location of the machine code.
    //Luckily, it can be cached.
    osCogStackPageHeadroom();

	// Retrieve the working directory.
	char *workingDirectoryBuffer = (char*)calloc(1, FILENAME_MAX+1);
	if(!workingDirectoryBuffer)
	{
		logErrorFromErrno("Out of memory.\n");
		return 1;
	}

	error = vm_path_get_current_working_dir_into(workingDirectoryBuffer, FILENAME_MAX+1);
	if(error)
	{
		logError("Failed to obtain the current working directory: %s\n", vm_error_code_to_string(error));
		return 1;
	}

	logDebug("Working Directory %s", workingDirectoryBuffer);

	LOG_SIZEOF(int);
	LOG_SIZEOF(long);
	LOG_SIZEOF(long long);
	LOG_SIZEOF(void*);
	LOG_SIZEOF(sqInt);
	LOG_SIZEOF(sqLong);
	LOG_SIZEOF(float);
	LOG_SIZEOF(double);

#if PHARO_VM_IN_WORKER_THREAD
    vmRunOnWorkerThread = vm_parameter_vector_has_element(&parameters->vmParameters, "--worker");

    return vmRunOnWorkerThread
        ? runOnWorkerThread(parameters)
        : runOnMainThread(parameters);
#else
	return runOnMainThread(parameters);
#endif
}

EXPORT(int)
vm_main(int argc, const char** argv, const char** env)
{
	VMParameters parameters;
	parameters.vmParameters.count = 0;
	parameters.vmParameters.parameters = NULL;
	parameters.imageParameters.count = 0;
	parameters.imageParameters.parameters = NULL;

	parameters.processArgc = argc;
	parameters.processArgv = argv;
	parameters.environmentVector = env;

	// Did we succeed on parsing the parameters?
	VMErrorCode error = vm_parameters_parse(argc, argv, &parameters);
	if(error)
	{
		if(error == VM_ERROR_EXIT_WITH_SUCCESS) return 0;
		return 1;
	}

	// Do we need to select an image file interactively?
	if(parameters.isInteractiveSession && parameters.isDefaultImage && !parameters.defaultImageFound &&
		!vm_file_dialog_is_nop())
	{
		VMFileDialog fileDialog;
		fileDialog.title = "Select Pharo Image to Open";
		fileDialog.message = "Choose an image file to execute";
		fileDialog.filterDescription = "Pharo Images (*.image)";
		fileDialog.filterExtension = ".image";
		fileDialog.defaultFileNameAndPath = DEFAULT_IMAGE_NAME;

		error = vm_file_dialog_run_modal_open(&fileDialog);
		if(!fileDialog.succeeded)
		{
			vm_file_dialog_destroy(&fileDialog);
			return 0;
		}

		parameters.imageFileName = strdup(fileDialog.selectedFileName);
		parameters.isDefaultImage = false;
		vm_file_dialog_destroy(&fileDialog);
	}
	int exitCode = vm_main_with_parameters(&parameters);
	vm_parameters_destroy(&parameters);
	return exitCode;
}

static int
loadPharoImage(const char* fileName)
{
    size_t imageSize = 0;
    sqImageFile imageFile = NULL;

    /* Open the image file. */
    imageFile = sqImageFileOpen(fileName, "rb");
    if(!imageFile)
	{
    	logErrorFromErrno("Opening Image");
        return false;
    }

    /* Get the size of the image file*/
    sqImageFileSeekEnd(imageFile, 0);
    imageSize = sqImageFilePosition(imageFile);
    sqImageFileSeek(imageFile, 0);

    readImageFromFileHeapSizeStartingAt(imageFile, 0, 0);
    sqImageFileClose(imageFile);

    char* fullImageName = alloca(FILENAME_MAX);
	fullImageName = getFullPath(fileName, fullImageName, FILENAME_MAX);

    setImageName(fullImageName);

    return 1;
}

static void*
runVMThread(void* p)
{
    VMParameters *parameters = (VMParameters*)p;

    if(!vm_init(parameters))
    {
        logError("Error opening image file: %s\n", parameters->imageFileName);
        return (void*)-1;
    }
    //setFlagVMRunOnWorkerThread(flagVMRunOnWorkerThread);

    registerCurrentThreadToHandleExceptions();

    vm_run_interpreter();
	return NULL;
}

static int
runOnMainThread(VMParameters *parameters)
{
    logDebug("Running VM on main thread\n");
    runVMThread((void *)parameters);
    return 0;
}

#if PHARO_VM_IN_WORKER_THREAD
static int
runOnWorkerThread(VMParameters *parameters)
{
    pthread_attr_t tattr;
    pthread_t thread_id;
    size_t size;

    logDebug("Running VM on worker thread\n");

    /*
     * I have to get the attributes of the main thread
     * to get the max stack size.
     * We need to set this value to the newly created thread,
     * as the created threads does not auto-grow.
     */
    pthread_attr_init(&tattr);
    pthread_attr_getstacksize(&tattr, &size);

    logDebug("Stack size: %ld\n", size);

    if(pthread_attr_setstacksize(&tattr, size * 4)){
        perror("Setting thread stack size");
        exit(-1);
    }

    if(pthread_create(&thread_id, &tattr, runVMThread, parameters)){
        perror("Spawning the VM thread");
        exit(-1);
    }

    pthread_detach(thread_id);

    return runMainThreadWorker();
}
#endif // PHARO_VM_IN_WORKER_THREAD