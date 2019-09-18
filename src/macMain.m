#include "pharoClient.h"
#include <string.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include <mach-o/dyld.h> // For _NSGetExecutablePath

extern char **environ;

@interface PharoVMLaunchApplication : NSApplication
@end

@interface PharoVMLaunchAppDelegate : NSObject<NSApplicationDelegate> {
    NSMutableArray<NSString*> *filesToOpen;
    const pharovm_parameters_t *parsedParameters;
}
@property const pharovm_parameters_t *parsedParameters;
@end

static PharoVMLaunchAppDelegate *launchAppDelegate = nil;

@implementation PharoVMLaunchApplication
@end

@implementation PharoVMLaunchAppDelegate
@synthesize parsedParameters;

- (id) init
{
    self = [super init];
    filesToOpen = [NSMutableArray new];
    return self;
}

- (void) applicationDidFinishLaunching: (NSNotification *)notification
{
    // Execute the VM process if We already have a list of files to open.
    if([filesToOpen count] > 0)
        return [self executeVMProcess];

    // No image file is specified. Display the file open dialog.
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.title = @"Image selection";
    panel.message = @"Choose an image file to execute.";
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.allowedFileTypes = [NSArray arrayWithObjects:@"image", nil];

    NSInteger clickedButton = [panel runModal];
    if(clickedButton == NSModalResponseOK)
    {
        for (NSURL *url in [panel URLs])
        {
            if(url.fileURL)
                [filesToOpen addObject: url.path];
        }

        if([filesToOpen count] > 0)
            return [self executeVMProcess];
    }

    [NSApp terminate: nil];
}

- (BOOL) application: (NSApplication*) theApplication openFile: (NSString *)filename
{
    [filesToOpen addObject: filename];
    return YES;
}

- (void) executeVMProcess
{
    char *path = (char*)calloc(1, FILENAME_MAX + 1);
    if(!path)
    {
        NSLog(@"Out of memory. Aborting.\n");
        abort();
    }

    uint32_t size = FILENAME_MAX;
    if(_NSGetExecutablePath(path, &size))
    {
        NSLog(@"VM executable path name is too long. Aborting.\n");
        abort();
    }

    NSArray<NSString*> *processCommandLineArguments = [[NSProcessInfo processInfo] arguments];
    NSMutableArray<NSString*> *newVMProcessCommandLineArguments = [NSMutableArray new];

    [newVMProcessCommandLineArguments addObjectsFromArray: processCommandLineArguments];
    [newVMProcessCommandLineArguments addObjectsFromArray: filesToOpen];
    [newVMProcessCommandLineArguments addObject: @"--interactive"];

    char **vmArgv = calloc([newVMProcessCommandLineArguments count] + 1, sizeof(char *));
    if(!vmArgv) {
        NSLog(@"Out of memory. Aborting.\n");
        abort();
    }

    for(int i = 0; i < [newVMProcessCommandLineArguments count]; ++i) {
        vmArgv[i] = strdup([newVMProcessCommandLineArguments[i] UTF8String]);
        if(!vmArgv[i]) {
            NSLog(@"Out of memory. Aborting.\n");
            abort();
        }
    }

    execv(path, vmArgv);
}
@end

int
launcher_main(const pharovm_parameters_t *parameters, int argc, const char *argv[])
{
    // Create the application.
    NSApplication *application = [PharoVMLaunchApplication sharedApplication];

    // Create the application delegate.
    launchAppDelegate = [[PharoVMLaunchAppDelegate alloc] init];
    launchAppDelegate.parsedParameters = parameters;
    [application setDelegate: launchAppDelegate];

    // Start the main run loop.
    [application performSelectorOnMainThread: @selector(run)
        withObject: nil waitUntilDone: YES];
    return 0;
}

int
main(int argc, const char *argv[])
{
    // In OS X, the user may want to drop an image file to the VM application.
    // Dropped image files are treated as events, whose reception is only
    // obtained through the usage of an AppDelegate, which is tied to a
    // NSApplication Singleton that cannot be created and destroyed for just
    // receiving this event. In addition to this, the user may want to
    // have an open image dialog. For this reason, we need to detect on
    // whether this program is being executed as a command line Unix tool, or is
    // being executed as an OS X application. We detect this by looking for a
    // -psn_ command line argument. We also look for the presence of the image in
    // the command line. If no image is specified, we run as if we were a
    // launcher application. Once we receive the image drop event, we launch
    // another process but with the image file name passed as a command line
    // argument.
    pharovm_parameters_t parameters = {};
	parameters.processArgc = argc;
	parameters.processArgv = argv;
	parameters.environmentVector = (const char**)environ;

	// Did we succeed on parsing the parameters?
	pharovm_error_code_t error = pharovm_parameters_parse(argc, argv, &parameters);
	if(error) {
		if(error == PHAROVM_ERROR_EXIT_WITH_SUCCESS) return 0;
		return 1;
	}

    // Look for something that looks like an image file.
    bool isImageFilePassedOnTheCommandLine = !parameters.isDefaultImage;
    bool programExecutedAsCommandLineTool = false;

    for(int i = 1; i < parameters.vmParameters.count - /* --headless */1; ++i)
    {
        const char *arg = parameters.vmParameters.parameters[i];
        if(*arg == '-')
        {
            // The process serial number indicates that this program is being
            // executed as an OS X application.
            if(!strncmp(arg, "-psn_", 5) || !strcmp(arg, "-NSDocumentRevisionsDebugMode"))
            {
                programExecutedAsCommandLineTool = 0;
            }
            else
            {
                programExecutedAsCommandLineTool = 1;
            }
        }
    }

    // If this is a program executed as a command line tool, or we found the
    // file passed on the command line, then just hand over the execution to the
    // normal VM execution machinery.
    if(parameters.isForcedStartupImage || programExecutedAsCommandLineTool || isImageFilePassedOnTheCommandLine || (parameters.isDefaultImage && parameters.defaultImageCount == 1))
    {
        int exitCode = pharovm_mainWithParameters(&parameters);
        pharovm_parameters_destroy(&parameters);
        return exitCode;
    }

    // This program does not know what VM to run, so run as a separate image
    // launcher program.
    return launcher_main(&parameters, argc, argv);
}
