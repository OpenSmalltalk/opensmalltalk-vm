#include "pharovm/pharo.h"
#include "pharovm/parameters.h"
#include "pharovm/debug.h"
#include "pharovm/pathUtilities.h"
#include <assert.h>

typedef VMErrorCode (*vm_parameter_process_function)(const char *argument, VMParameters* params);

typedef struct VMParameterSpec_
{
	const char *name;
	bool hasArgument;
	vm_parameter_process_function function;
} VMParameterSpec;

void vm_printUsageTo(FILE *out);
static VMErrorCode processHelpOption(const char *argument, VMParameters * params);
static VMErrorCode processPrintVersionOption(const char *argument, VMParameters * params);
static VMErrorCode processLogLevelOption(const char *argument, VMParameters * params);
static VMErrorCode processMaxFramesToPrintOption(const char *argument, VMParameters * params);

static const VMParameterSpec vm_parameters_spec[] =
{
	{.name = "headless", .hasArgument = false, .function = NULL},
    {.name = "worker", .hasArgument = false, .function = NULL},
	{.name = "interactive", .hasArgument = false, .function = NULL}, // For pharo-ui scripts.
	{.name = "vm-display-null", .hasArgument = false, .function = NULL}, // For Smalltalk CI.
	{.name = "help", .hasArgument = false, .function = processHelpOption},
	{.name = "h", .hasArgument = false, .function = processHelpOption},
	{.name = "version", .hasArgument = false, .function = processPrintVersionOption},
	{.name = "logLevel", .hasArgument = true, .function = processLogLevelOption},
	{.name = "maxFramesToLog", .hasArgument = true, .function = processMaxFramesToPrintOption},

#ifdef __APPLE__
	// This parameter is passed by the XCode debugger.
	{.name = "NSDocumentRevisionsDebugMode", .hasArgument = false, .function = NULL},
#endif
};

// TODO: Turn this array size computation into a macro.
static const size_t vm_parameters_spec_size = sizeof(vm_parameters_spec) / sizeof(vm_parameters_spec[0]);

/**
 * Folder search suffixes for finding images.
 */
static const char * const vm_image_search_suffixes[] = {
	DEFAULT_IMAGE_NAME,

#ifdef __APPLE__
	"../Resources/" DEFAULT_IMAGE_NAME,
	"../../../" DEFAULT_IMAGE_NAME,
#endif
};

static const size_t vm_image_search_suffixes_count = sizeof(vm_image_search_suffixes) / sizeof(vm_image_search_suffixes[0]);

static const VMParameterSpec*
findParameterWithName(const char *argumentName, size_t argumentNameSize)
{
	for(size_t i = 0; i < vm_parameters_spec_size; ++i) {
		const VMParameterSpec *paramSpec = &vm_parameters_spec[i];
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
	if(*parameter != '-') return 0;

	// Ignore the preceding hyphens
	++parameter;
	if(*parameter == '-')
	{
		++parameter;
	}

	// Does the parameter have an equal (=)?
	if(strchr(parameter, '=') != NULL) return 0;

	// Find the parameter spec.
	const VMParameterSpec* spec = findParameterWithName(parameter, strlen(parameter));
	if(!spec) return 0;

	return spec->hasArgument ? 1 : 0;
}


// FIXME: This should be provided by the client.
static int
isInConsole()
{
#ifdef _WIN32
	return GetStdHandle(STD_INPUT_HANDLE) != NULL;
#else
	return false;
#endif
}

VMErrorCode
vm_parameters_destroy(VMParameters *parameters)
{
	if(!parameters) return VM_ERROR_NULL_POINTER;

	free(parameters->imageFileName);
	vm_parameter_vector_destroy(&parameters->vmParameters);
	vm_parameter_vector_destroy(&parameters->imageParameters);
	memset(parameters, 0, sizeof(VMParameters));
	return VM_SUCCESS;
}

VMErrorCode
vm_find_startup_image(const char *vmExecutablePath, VMParameters *parameters)
{
    char *imagePathBuffer = (char*)calloc(1, FILENAME_MAX+1);
    char *vmPathBuffer = (char*)calloc(1, FILENAME_MAX+1);
    char *searchPathBuffer = (char*)calloc(1, FILENAME_MAX+1);

	if(!imagePathBuffer || !vmPathBuffer || !searchPathBuffer)
	{
		free(imagePathBuffer);
		free(vmPathBuffer);
		free(searchPathBuffer);
		return VM_ERROR_OUT_OF_MEMORY;
	}

	// Find the VM absolute directory.
	vm_path_make_absolute_into(searchPathBuffer, FILENAME_MAX+1, vmExecutablePath);
    if(sqImageFileExists(searchPathBuffer))
	{
		vm_path_extract_dirname_into(vmPathBuffer, FILENAME_MAX+1, searchPathBuffer);
	}
    else
	{
        strncpy(vmPathBuffer, vmExecutablePath, FILENAME_MAX);
		vmPathBuffer[FILENAME_MAX] = 0;
	}

	// Find the image in the different search directory suffixes.
	for(size_t i = 0; i < vm_image_search_suffixes_count; ++i)
	{
		const char *searchSuffix = vm_image_search_suffixes[i];
		vm_path_join_into(imagePathBuffer, FILENAME_MAX+1, vmPathBuffer, searchSuffix);
	    if(sqImageFileExists(imagePathBuffer))
		{
			parameters->imageFileName = imagePathBuffer;
			parameters->isDefaultImage = true;
			parameters->defaultImageFound = true;
	        free(vmPathBuffer);
	        free(searchPathBuffer);
	        return VM_SUCCESS;
		}
	}

	// Find the image in the current work directory.
	vm_path_get_current_working_dir_into(searchPathBuffer, FILENAME_MAX+1);
	vm_path_join_into(imagePathBuffer, FILENAME_MAX+1, searchPathBuffer, DEFAULT_IMAGE_NAME);
	free(vmPathBuffer);
	free(searchPathBuffer);
	if(sqImageFileExists(imagePathBuffer))
	{
		parameters->imageFileName = imagePathBuffer;
		parameters->isDefaultImage = true;
		parameters->defaultImageFound = true;
		return VM_SUCCESS;
	}

	free(imagePathBuffer);
	parameters->imageFileName = strdup(DEFAULT_IMAGE_NAME);
	parameters->isDefaultImage = true;
	parameters->defaultImageFound = false;
	return VM_SUCCESS;
}

static int
findImageNameIndex(int argc, const char** argv)
{
	//The first parameters is the executable name
	for(int i=1; i < argc; i ++)
	{
		const char *argument = argv[i];

		// Is this a mark for where the image parameters begins?
		if(strcmp(argument, "--") == 0)
		{
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

static VMErrorCode
splitVMAndImageParameters(int argc, const char** argv, VMParameters* parameters)
{
	VMErrorCode error;
	int imageNameIndex = findImageNameIndex(argc, argv);
	int numberOfVMParameters = imageNameIndex;
	int numberOfImageParameters = argc - imageNameIndex - 1;

	if(numberOfImageParameters < 0)
		numberOfImageParameters = 0;

	// We get the image file name
	if(imageNameIndex == argc || strcmp("--", argv[imageNameIndex]) == 0) {
		error = vm_find_startup_image(argv[0], parameters);
		if(error)
		{
			return error;
		}
	}
	else
	{
		parameters->imageFileName = strdup(argv[imageNameIndex]);
		parameters->isDefaultImage = false;
	}

	// Copy image parameters.
	error = vm_parameter_vector_insert_from(&parameters->imageParameters, numberOfImageParameters, &argv[imageNameIndex + 1]);
	if(error)
	{
		vm_parameters_destroy(parameters);
		return error;
	}

	// Copy the VM parameters.
	error = vm_parameter_vector_insert_from(&parameters->vmParameters, numberOfVMParameters, argv);
	if(error)
	{
		vm_parameters_destroy(parameters);
		return error;
	}

	// Add additional VM parameters.
	const char *extraVMParameters = "--headless";
	error = vm_parameter_vector_insert_from(&parameters->vmParameters, 1, &extraVMParameters);
	if(error)
	{
		vm_parameters_destroy(parameters);
		return error;
	}

	return VM_SUCCESS;
}

static void
logParameterVector(const char* vectorName, const VMParameterVector *vector)
{
	logDebug("%s [count = %u]:", vectorName, vector->count);
	for(size_t i = 0; i < vector->count; ++i)
	{
		logDebug(" %s", vector->parameters[i]);
	}
}

static void
logParameters(const VMParameters* parameters)
{
	logDebug("Image file name: %s", parameters->imageFileName);
	logDebug("Is default Image: %s", parameters->isDefaultImage ? "yes" : "no");
	logDebug("Is interactive session: %s", parameters->isInteractiveSession ? "yes" : "no");

	logParameterVector("vmParameters", &parameters->vmParameters);
	logParameterVector("imageParameters", &parameters->imageParameters);
}

VMErrorCode
vm_parameters_ensure_interactive_image_parameter(VMParameters* parameters)
{
	if (parameters->isInteractiveSession)
	{
		if (!vm_parameter_vector_has_element(&parameters->imageParameters, "--interactive"))
		{
			const char* interactiveParameter = "--interactive";
			VMErrorCode error = vm_parameter_vector_insert_from(&parameters->imageParameters, 1, &interactiveParameter);
			if (error) return error;
		}
	}

	return VM_SUCCESS;
}

void
vm_printUsageTo(FILE *out)
{
	fprintf(out,
"Usage: " VM_NAME " [<option>...] [<imageName> [<argument>...]]\n"
"       " VM_NAME " [<option>...] -- [<argument>...]\n"
"\n"
"Common <option>s:\n"
"  --help                 	Print this help message, then exit\n"
"  --headless             	Run in headless (no window) mode (default: true)\n"
"  --worker               run in worker thread (default: false)\n"
"  --logLevel=<level>     	Sets the log level (ERROR, WARN, INFO or DEBUG)\n"
"  --version              	Print version information, then exit\n"
"  --maxFramesToLog=<cant>	Sets the max numbers of Smalltalk frames to log"
"\n"
"Notes:\n"
"\n"
"  <imageName> defaults to `Pharo.image'.\n"
"  <argument>s are ignored, but are processed by the Pharo image.\n"
"  Precede <arguments> by `--' to use default image.\n");
}

static VMErrorCode
processLogLevelOption(const char* value, VMParameters * params)
{
	int intValue = 0;

	intValue = strtol(value, NULL, 10);

	if(intValue == 0)
	{
		logError("Invalid option for logLevel: %s\n", value);
		vm_printUsageTo(stderr);
		return VM_ERROR_INVALID_PARAMETER_VALUE;
	}

	logLevel(intValue);
	return VM_SUCCESS;
}

static VMErrorCode
processMaxFramesToPrintOption(const char* value, VMParameters * params)
{
	int intValue = 0;

	intValue = strtol(value, NULL, 10);

	if(intValue < 0)
	{
		logError("Invalid option for maxFramesToLog: %s\n", value);
		vm_printUsageTo(stderr);
		return VM_ERROR_INVALID_PARAMETER_VALUE;
	}

	params->maxStackFramesToPrint = intValue;

	return VM_SUCCESS;
}

static VMErrorCode
processHelpOption(const char* argument, VMParameters * params)
{
	(void)argument;
	vm_printUsageTo(stdout);
	return VM_ERROR_EXIT_WITH_SUCCESS;
}

static VMErrorCode
processPrintVersionOption(const char* argument, VMParameters * params)
{
	(void)argument;
	printf("%s\n", getVMVersion());
	printf("Built from: %s\n", getSourceVersion());
	return VM_ERROR_EXIT_WITH_SUCCESS;
}

static VMErrorCode
processVMOptions(VMParameters* parameters)
{
	VMParameterVector *vector = &parameters->vmParameters;
	for(size_t i = 1; i < vector->count; ++i)
	{
		const char *param = vector->parameters[i];
		if(!param)
		{
			break;
		}

		// We only care about specific parameters here.
		if(*param != '-')
		{
			continue;
		}

#ifdef __APPLE__
		// Ignore the process serial number special argument passed to OS X applications.
		if(strncmp(param, "-psn_", 5) == 0)
		{
			continue;
		}
#endif

		// Ignore the leading dashes (--)
		const char *argumentName = param + 1;
		if(*argumentName == '-')
		{
			++argumentName;
		}

		// Find the argument value.
		const char *argumentValue = strchr(argumentName, '=');
		size_t argumentNameSize = strlen(argumentName);
		if(argumentValue != NULL)
		{
			argumentNameSize = argumentValue - argumentName;
			++argumentValue;
		}

		// Find a matching parameter
		const VMParameterSpec *paramSpec = findParameterWithName(argumentName, argumentNameSize);
		if(!paramSpec)
		{
			logError("Invalid or unknown VM parameter %s\n", param);
			vm_printUsageTo(stderr);
			return VM_ERROR_INVALID_PARAMETER;
		}

		// If the parameter has a required argument, it may be passed as the next parameter in the vector.
		if(paramSpec->hasArgument)
		{
			// Try to fetch the argument from additional means
			if(argumentValue == NULL)
			{
				if(i + 1 < vector->count)
				{
					argumentValue = vector->parameters[++i];
				}
			}

			// Make sure the argument value is present.
			if(argumentValue == NULL)
			{
				logError("VM parameter %s requires a value\n", param);
				vm_printUsageTo(stderr);
				return VM_ERROR_INVALID_PARAMETER_VALUE;
			}
		}

		// Invoke the VM parameter processing function.
		if(paramSpec->function)
		{
			VMErrorCode error = paramSpec->function(argumentValue, parameters);
			if(error) return error;
		}
	}

	return VM_SUCCESS;
}

EXPORT(VMErrorCode)
vm_parameters_parse(int argc, const char** argv, VMParameters* parameters)
{
	char* fullPath;

	// Split the argument vector in two separate vectors.
	VMErrorCode error = splitVMAndImageParameters(argc, argv, parameters);
	if(error) return error;

	// Is this an interactive environment?
	parameters->isInteractiveSession = !isInConsole() && parameters->isDefaultImage;

	// I get the VM location from the argv[0]
	char *fullPathBuffer = (char*)calloc(1, FILENAME_MAX);
	if(!fullPathBuffer)
	{
		vm_parameters_destroy(parameters);
		return VM_ERROR_OUT_OF_MEMORY;
	}

	fullPath = getFullPath(argv[0], fullPathBuffer, FILENAME_MAX);
	setVMPath(fullPath);
	free(fullPathBuffer);

	error = processVMOptions(parameters);
	if(error)
	{
		vm_parameters_destroy(parameters);
		return error;
	}

	logParameters(parameters);

	return VM_SUCCESS;
}
