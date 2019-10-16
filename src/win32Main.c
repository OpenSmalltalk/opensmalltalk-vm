





static int
mainEntryPoint(int argc, const char **argv)
{
    // Parse the command line parameters.
    pharovm_parameters_t parameters = {};
	parameters.processArgc = argc;
	parameters.processArgv = argv;
	parameters.environmentVector = (const char**)environ;

	// Did we succeed on parsing the parameters?
	pharovm_error_code_t error = pharovm_parameters_parse(argc, argv, &parameters);
	if(error)
    {
		if(error == VM_ERROR_EXIT_WITH_SUCCESS) return 0;
		return 1;
	}

    // Do we have to ask the user for an image?
    if(!parameters.isForcedStartupImage && parameters.isDefaultImage && parameters.defaultImageCount != 1)
    {
        error = openImageFileDialog(&parameters);
        if(error) {
    		if(error == VM_ERROR_EXIT_WITH_SUCCESS) return 0;
    		return 1;
    	}
    }

	parameters.hasBeenSelectedByUserInteractively = true;
    int exitCode = pharovm_mainWithParameters(&parameters);
    pharovm_parameters_destroy(&parameters);
    return exitCode;
}

int CALLBACK WinMain(
  HINSTANCE hInstance,
  HINSTANCE hPrevInstance,
  LPSTR     lpCmdLine,
  int       nCmdShow
)
{
    return vm_main(__argc, (const char **)__argv, (const char**)environ);
}
