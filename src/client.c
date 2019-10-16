#include "pharo.h"
#include "pharoClient.h"
#include "fileDialog.h"
#include "pathUtilities.h"

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

EXPORT(int) vm_init(const char* imageFileName, const VMParameterVector *vmParameters, const VMParameterVector *imageParameters) {
	initGlobalStructure();

	//Unix Initialization specific
	fldcw(0x12bf);	/* signed infinity, round to nearest, REAL8, disable intrs, disable signals */
    mtfsfi(0);		/* disable signals, IEEE mode, round to nearest */


    ioInitTime();

    ioVMThread = ioCurrentOSThread();
	ioInitExternalSemaphores();

	aioInit();

	setPharoCommandLineParameters(vmParameters->parameters, vmParameters->count,
			imageParameters->parameters, imageParameters->count);

	return loadPharoImage(imageFileName);
}

EXPORT(void) vm_run_interpreter()
{
	interpret();
}

EXPORT(int)
vm_main_with_parameters(VMParameters *parameters)
{
	// HACK: In some cases we need to add an explicit --interactive option to the image.
	VMErrorCode error = vm_parameters_ensure_interactive_image_parameter(parameters);
	if (error)
	{
		return 1;
	}

	if(parameters->isDefaultImage && !parameters->defaultImageFound)
	{
		printf("No image has been specified, and no default image has been found.\n");
		vm_printUsageTo(stdout);
		return 0;
	}
	installErrorHandlers();

	setProcessArguments(parameters->processArgc, parameters->processArgv);
	setProcessEnvironmentVector(parameters->environmentVector);

	logInfo("Opening Image: %s\n", parameters->imageFileName);

	// Retrieve the working directory.
	char *workingDirectoryBuffer = (char*)calloc(1, FILENAME_MAX+1);
	if(!workingDirectoryBuffer)
	{
		fprintf(stderr, "Out of memory.\n");
		return 1;
	}

	error = vm_path_get_current_working_dir_into(workingDirectoryBuffer, FILENAME_MAX+1);
	if(error)
	{
		fprintf(stderr, "Failed to obtain the current working directory: %s\n", vm_error_code_to_string(error));
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

	if(!vm_init(parameters->imageFileName, &parameters->vmParameters, &parameters->imageParameters))
	{
		logError("Error opening image file: %s\n", parameters->imageFileName);
		return -1;
	}

	vm_run_interpreter();

	return 0;
}

EXPORT(int)
vm_main(int argc, const char** argv, const char** env)
{
	VMParameters parameters = {};
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
		VMFileDialog fileDialog = {};
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

static int loadPharoImage(const char* fileName)
{
    size_t imageSize = 0;
    FILE* imageFile = NULL;

    /* Open the image file. */
    imageFile = fopen(fileName, "rb");
    if(!imageFile)
	{
    	perror("Opening Image");
        return false;
    }

    /* Get the size of the image file*/
    fseek(imageFile, 0, SEEK_END);
    imageSize = ftell(imageFile);
    fseek(imageFile, 0, SEEK_SET);

    readImageFromFileHeapSizeStartingAt(imageFile, 0, 0);
    fclose(imageFile);

    char* fullImageName = alloca(FILENAME_MAX);
	fullImageName = getFullPath(fileName, fullImageName, FILENAME_MAX);

    setImageName(fullImageName);

    return true;
}
