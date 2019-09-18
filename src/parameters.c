#include "pharo.h"
#include "parameters.h"
#include "debug.h"
#include "errorCodes.h"
#include "pathUtilities.h"
#include <assert.h>

typedef pharovm_error_code_t (*pharovm_parameter_process_function)(const char *argument);

typedef struct pharovm_parameter_spec_s
{
	const char *name;
	bool hasArgument;
	pharovm_parameter_process_function function;
} pharovm_parameter_spec_t;

// FIXME: Where is this print version defined? this should be a static definition.
void printVersion();

void pharovm_printUsageTo(FILE *out);
static pharovm_error_code_t processHelpOption(const char *argument);
static pharovm_error_code_t processPrintVersionOption(const char *argument);
static pharovm_error_code_t processLogLevelOption(const char *argument);

static const pharovm_parameter_spec_t pharovm_parametersSpec[] = {
	{.name = "headless", .hasArgument = false, .function = NULL},
	{.name = "help", .hasArgument = false, .function = processHelpOption},
	{.name = "h", .hasArgument = false, .function = processHelpOption},
	{.name = "version", .hasArgument = false, .function = processPrintVersionOption},
	{.name = "logLevel", .hasArgument = true, .function = processLogLevelOption},

#ifdef __APPLE__
	// This parameter is passed by the XCode debugger.
	{.name = "NSDocumentRevisionsDebugMode", .hasArgument = false, .function = NULL},
#endif
};
// TODO: Turn this array size computation into a macro.
static const size_t pharovm_parametersSpecSize = sizeof(pharovm_parametersSpec) / sizeof(pharovm_parametersSpec[0]);

static const pharovm_parameter_spec_t*
findParameterWithName(const char *argumentName, size_t argumentNameSize)
{
	for(size_t i = 0; i < pharovm_parametersSpecSize; ++i) {
		const pharovm_parameter_spec_t *paramSpec = &pharovm_parametersSpec[i];
		if(strlen(paramSpec->name) == argumentNameSize &&
		   strncmp(paramSpec->name, argumentName, argumentNameSize) == 0) {
	        return paramSpec;
		}
	}
	return NULL;
}

static int
findParameterArity(const char *parameter)
{
	if(*parameter != '-') {
		return 0;
	};

	// Ignore the preceding hyphens
	++parameter;
	if(*parameter == '-') {
		++parameter;
	}

	// Does the parameter have an equal (=)?
	if(strchr(parameter, '=') != NULL) {
		return 0;
	}

	// Find the parameter spec.
	const pharovm_parameter_spec_t* spec = findParameterWithName(parameter, strlen(parameter));
	if(!spec) {
		return 0;
	}

	return spec->hasArgument ? 1 : 0;
}

pharovm_error_code_t
pharovm_parameter_vector_destroy(pharovm_parameter_vector_t *vector)
{
	if(!vector) return PHAROVM_ERROR_NULL_POINTER;

	free(vector->parameters);
	vector->parameters = NULL;
	vector->count = 0;
	return PHAROVM_SUCCESS;
}

pharovm_error_code_t
pharovm_parameter_vector_insertFrom(pharovm_parameter_vector_t *vector, uint32_t count, const char **elements)
{
	uint32_t newVectorCount = vector->count + count;
	// Add an addition NULL element, for execv and family.
	const char **newVectorData = (const char **)calloc(newVectorCount + 1, sizeof(const char *));
	if(!newVectorData) {
		return PHAROVM_ERROR_OUT_OF_MEMORY;
	}

	// Copy the old vector parameters.
	for(uint32_t i = 0; i < vector->count; ++i)
		newVectorData[i] = vector->parameters[i];

	// Copy the new vector parameters.
	for(uint32_t i = 0; i < count; ++i)
		newVectorData[vector->count + i] = elements[i];

	// Free the old vector parameters
	free(vector->parameters); // Free of NULL is a no-op.
	vector->count = newVectorCount;
	vector->parameters = newVectorData;

	return PHAROVM_SUCCESS;
}

pharovm_error_code_t
pharovm_parameters_destroy(pharovm_parameters_t *parameters)
{
	if(!parameters) return PHAROVM_ERROR_NULL_POINTER;

	free(parameters->imageFileName);
	pharovm_parameter_vector_destroy(&parameters->vmParameters);
	pharovm_parameter_vector_destroy(&parameters->imageParameters);
	memset(parameters, 0, sizeof(pharovm_parameters_t));
	return PHAROVM_SUCCESS;
}

pharovm_error_code_t
pharovm_findStartupImage(const char *vmExecutablePath, pharovm_parameters_t *parameters)
{
    char *imagePathBuffer = (char*)calloc(1, FILENAME_MAX+1);
    char *vmPathBuffer = (char*)calloc(1, FILENAME_MAX+1);
    char *searchPathBuffer = (char*)calloc(1, FILENAME_MAX+1);

	if(!imagePathBuffer || !vmPathBuffer || !searchPathBuffer) {
		free(imagePathBuffer);
		free(vmPathBuffer);
		free(searchPathBuffer);
		return PHAROVM_ERROR_OUT_OF_MEMORY;
	}

	pharovm_path_makeAbsoluteInto(searchPathBuffer, FILENAME_MAX+1, vmExecutablePath);
    if(fileExists(searchPathBuffer)) {
		pharovm_path_extractDirnameInto(vmPathBuffer, FILENAME_MAX+1, searchPathBuffer);
	}
    else {
        strncpy(vmPathBuffer, vmExecutablePath, FILENAME_MAX);
		vmPathBuffer[FILENAME_MAX] = 0;
	}

	// Find the mandatory startup.image.
    pharovm_path_joinInto(imagePathBuffer, FILENAME_MAX+1, vmPathBuffer, FORCED_STARTUP_IMAGE_NAME);
    if(fileExists(imagePathBuffer))
    {
		parameters->imageFileName = imagePathBuffer;
		parameters->isDefaultImage = true;
		parameters->hasBeenSelectedByUserInteractively = false;
		parameters->isForcedStartupImage = true;
        free(vmPathBuffer);
        free(searchPathBuffer);
        return PHAROVM_SUCCESS;
    }

#ifdef __APPLE__
    pharovm_path_joinInto(imagePathBuffer, FILENAME_MAX+1, vmPathBuffer, "../Resources/" FORCED_STARTUP_IMAGE_NAME);
	if(fileExists(imagePathBuffer))
    {
		parameters->imageFileName = imagePathBuffer;
		parameters->isDefaultImage = true;
		parameters->hasBeenSelectedByUserInteractively = false;
		parameters->isForcedStartupImage = true;
        free(vmPathBuffer);
        free(searchPathBuffer);
        return PHAROVM_SUCCESS;
    }

    pharovm_path_joinInto(imagePathBuffer, FILENAME_MAX+1, vmPathBuffer, "../../../" FORCED_STARTUP_IMAGE_NAME);
	if(fileExists(imagePathBuffer))
    {
		parameters->imageFileName = imagePathBuffer;
		parameters->isDefaultImage = true;
		parameters->hasBeenSelectedByUserInteractively = false;
		parameters->isForcedStartupImage = true;
        free(vmPathBuffer);
        free(searchPathBuffer);
        return PHAROVM_SUCCESS;
    }

#endif

    // Find automatically an image.
    int foundImageCount = 0;

    // Search on the VM executable path.
	strcpy(imagePathBuffer, "");
    foundImageCount += pharovm_path_findImagesInFolder(vmPathBuffer, imagePathBuffer, FILENAME_MAX+1);

#ifdef __APPLE__
    // Search along the bundled resources.
    pharovm_path_joinInto(searchPathBuffer, FILENAME_MAX+1, vmPathBuffer, "../Resources");
    foundImageCount += pharovm_path_findImagesInFolder(searchPathBuffer, imagePathBuffer, FILENAME_MAX+1);

    // Search in the folder that contains the bundle.
    pharovm_path_joinInto(searchPathBuffer, FILENAME_MAX+1, vmPathBuffer, "../../..");
    char *realBundlePath = (char*)calloc(1, FILENAME_MAX+1);
    realpath(searchPathBuffer, realBundlePath);

    pharovm_path_getCurrentWorkingDirInto(searchPathBuffer, FILENAME_MAX+1);
    if(strcmp(realBundlePath, searchPathBuffer) != 0)
        foundImageCount += pharovm_path_findImagesInFolder(realBundlePath, imagePathBuffer, FILENAME_MAX+1);

    free(realBundlePath);
#endif

    // Search in the current working directory.
	// CHECK ME: Is it correct to search in the working directory?
    pharovm_path_getCurrentWorkingDirInto(searchPathBuffer, FILENAME_MAX+1);
    if(strcmp(searchPathBuffer, vmPathBuffer) != 0)
        foundImageCount += pharovm_path_findImagesInFolder(searchPathBuffer, imagePathBuffer, FILENAME_MAX+1);

    free(vmPathBuffer);
    free(searchPathBuffer);

	// If there are not images, fallback to the default image name.
	if(foundImageCount == 0) {
		strcpy(imagePathBuffer, DEFAULT_IMAGE_NAME);
	}

	parameters->imageFileName = imagePathBuffer;
	parameters->isDefaultImage = true;
	parameters->hasBeenSelectedByUserInteractively = false;
	parameters->defaultImageCount = foundImageCount;
	return PHAROVM_SUCCESS;
}

static int
findImageNameIndex(int argc, const char** argv)
{
	//The first parameters is the executable name
	for(int i=1; i < argc; i ++) {
		const char *argument = argv[i];

		// Is this a mark for where the image parameters begins?
		if(strcmp(argument, "--") == 0) {
			return i;
		}

		// Is this an option?
		if(*argv[i] == '-') {
			i += findParameterArity(argument);
			continue;
		}

		// This must be the first non vmoption argument, so this must be the image.
		return i;
	}

	// I could not find it.
	return argc;
}

static pharovm_error_code_t
splitVMAndImageParameters(int argc, const char** argv, pharovm_parameters_t* parameters)
{
	pharovm_error_code_t error;
	int imageNameIndex = findImageNameIndex(argc, argv);
	int numberOfVMParameters = imageNameIndex;
	int numberOfImageParameters = argc - imageNameIndex - 1;

	if(numberOfImageParameters < 0)
		numberOfImageParameters = 0;

	// We get the image file name
	if(imageNameIndex == argc || strcmp("--", argv[imageNameIndex]) == 0) {
		error = pharovm_findStartupImage(argv[0], parameters);
		if(error) {
			return error;
		}
	} else {
		parameters->imageFileName = strdup(argv[imageNameIndex]);
		parameters->isDefaultImage = false;
		parameters->hasBeenSelectedByUserInteractively = false;
	}

	// Copy image parameters.
	error = pharovm_parameter_vector_insertFrom(&parameters->imageParameters, numberOfImageParameters, &argv[imageNameIndex + 1]);
	if(error) {
		pharovm_parameters_destroy(parameters);
		return error;
	}

	// Copy the VM parameters.
	error = pharovm_parameter_vector_insertFrom(&parameters->vmParameters, numberOfVMParameters, argv);
	if(error) {
		pharovm_parameters_destroy(parameters);
		return error;
	}

	// Add additional VM parameters.
	const char *extraVMParameters = "--headless";
	error = pharovm_parameter_vector_insertFrom(&parameters->vmParameters, 1, &extraVMParameters);
	if(error) {
		pharovm_parameters_destroy(parameters);
		return error;
	}

	return PHAROVM_SUCCESS;
}

static void
logParameterVector(const char* vectorName, const pharovm_parameter_vector_t *vector)
{
	logDebug("%s [count = %u]:", vectorName, vector->count);
	for(size_t i = 0; i < vector->count; ++i)
	{
		logDebug(" %s", vector->parameters[i]);
	}
}

static void
logParameters(const pharovm_parameters_t* parameters)
{
	logDebug("Image file name: %s", parameters->imageFileName);
	logDebug("Is default Image: %s", parameters->isDefaultImage ? "yes" : "no");
	logDebug("Has been selected interactively: %s", parameters->hasBeenSelectedByUserInteractively ? "yes" : "no");

	logParameterVector("vmParameters", &parameters->vmParameters);
	logParameterVector("imageParameters", &parameters->imageParameters);
}

// FIXME: This should be provided by the client.
static int
isConsole()
{
#ifdef _WIN32
	return GetStdHandle(STD_INPUT_HANDLE) != NULL;
#else
	return false;
#endif
}

static pharovm_error_code_t
processImageOptions(pharovm_parameters_t* parameters){
	if(parameters->isDefaultImage || parameters->hasBeenSelectedByUserInteractively) {
		//If there are no parameters, we are next to the launch of the VM, we need to add the interactive flag
		//As we always have two parameters (the --headless)
		if(parameters->vmParameters.count == 2 && parameters->imageParameters.count == 0 && !isConsole()){
			const char *interactiveParameter = "--interactive";
			pharovm_error_code_t error = pharovm_parameter_vector_insertFrom(&parameters->imageParameters, 1, &interactiveParameter);
			if(error) return error;
		}
	}

	return PHAROVM_SUCCESS;
}

void
pharovm_printUsageTo(FILE *out)
{
	fprintf(out,
"Usage: " VM_NAME " [<option>...] [<imageName> [<argument>...]]\n"
"       " VM_NAME " [<option>...] -- [<argument>...]\n"
"\n"
"Common <option>s:\n"
"  --help                 print this help message, then exit\n"
"  --headless             run in headless (no window) mode (default: true)\n"
"  --logLevel=<level>     Sets the log level (ERROR, WARN, INFO or DEBUG)\n"
"  --version              print version information, then exit\n"
"\n"
"Notes:\n"
"\n"
"  <imageName> defaults to `Pharo.image'.\n"
"  <argument>s are ignored, but are processed by the Pharo image.\n"
"  Precede <arguments> by `--' to use default image.\n");
}

static pharovm_error_code_t
processLogLevelOption(const char* value)
{
	int intValue = 0;

	intValue = strtol(value, NULL, 10);

	if(intValue == 0) {
		fprintf(stderr, "Invalid option for logLevel: %s\n", value);
		pharovm_printUsageTo(stderr);
		return PHAROVM_ERROR_INVALID_PARAMETER_VALUE;
	}

	logLevel(intValue);
	return PHAROVM_SUCCESS;
}

static pharovm_error_code_t
processHelpOption(const char* argument)
{
	(void)argument;
	pharovm_printUsageTo(stdout);
	return PHAROVM_ERROR_EXIT_WITH_SUCCESS;
}

static pharovm_error_code_t
processPrintVersionOption(const char* argument)
{
	(void)argument;
	printVersion();
	return PHAROVM_ERROR_EXIT_WITH_SUCCESS;
}

static pharovm_error_code_t
processVMOptions(pharovm_parameters_t* parameters)
{
	pharovm_parameter_vector_t *vector = &parameters->vmParameters;
	for(size_t i = 1; i < vector->count; ++i)
	{
		const char *param = vector->parameters[i];
		if(!param) {
			break;
		}

		// We only care about specific parameters here.
		if(*param != '-') {
			continue;
		}

#ifdef __APPLE__
		// Ignore the process serial number special argument passed to OS X applications.
		if(strncmp(param, "-psn_", 5) == 0) {
			continue;
		}
#endif

		// Ignore the leading dashes (--)
		const char *argumentName = param + 1;
		if(*argumentName == '-') {
			++argumentName;
		}

		// Find the argument value.
		const char *argumentValue = strchr(argumentName, '=');
		size_t argumentNameSize = strlen(argumentName);
		if(argumentValue != NULL) {
			argumentNameSize = argumentValue - argumentName;
			++argumentValue;
		}

		// Find a matching parameter
		const pharovm_parameter_spec_t *paramSpec = findParameterWithName(argumentName, argumentNameSize);
		if(!paramSpec) {
			fprintf(stderr, "Invalid or unknown VM parameter %s\n", param);
			pharovm_printUsageTo(stderr);
			return PHAROVM_ERROR_INVALID_PARAMETER;
		}

		// If the parameter has a required argument, it may be passed as the next parameter in the vector.
		if(paramSpec->hasArgument) {
			// Try to fetch the argument from additional means
			if(argumentValue == NULL)
			{
				if(i + 1 < vector->count) {
					argumentValue = vector->parameters[++i];
				}
			}

			// Make sure the argument value is present.
			if(argumentValue == NULL) {
				fprintf(stderr, "VM parameter %s requires a value\n", param);
				pharovm_printUsageTo(stderr);
				return PHAROVM_ERROR_INVALID_PARAMETER_VALUE;
			}
		}

		// Invoke the VM parameter processing function.
		if(paramSpec->function)
		{
			pharovm_error_code_t error = paramSpec->function(argumentValue);
			if(error) return error;
		}
	}

	return PHAROVM_SUCCESS;
}

pharovm_error_code_t
pharovm_parameters_parse(int argc, const char** argv, pharovm_parameters_t* parameters)
{
	char* fullPath;

	// Split the argument vector in two separate vectors.
	pharovm_error_code_t error = splitVMAndImageParameters(argc, argv, parameters);
	if(error) return error;

	// I get the VM location from the argv[0]
	char *fullPathBuffer = (char*)calloc(1, FILENAME_MAX);
	if(!fullPathBuffer) {
		pharovm_parameters_destroy(parameters);
		return PHAROVM_ERROR_OUT_OF_MEMORY;
	}

	fullPath = getFullPath(argv[0], fullPathBuffer, FILENAME_MAX);
	setVMPath(fullPath);
	free(fullPathBuffer);

	error = processVMOptions(parameters);
	if(error) {
		pharovm_parameters_destroy(parameters);
		return error;
	}

	// HACK: if the image does not receive parameters, add the --interactive flag.
	error = processImageOptions(parameters);
	if(error) {
		pharovm_parameters_destroy(parameters);
		return error;
	}

	logParameters(parameters);

	return PHAROVM_SUCCESS;
}
