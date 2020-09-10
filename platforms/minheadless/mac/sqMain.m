/* sqMain.c -- main entry point for the Mac OS X standalone Squeak VM
 *
 *   Copyright (C) 2019 by Ronie Salgado
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
#include "OpenSmalltalkVM.h"
#include <string.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include <mach-o/dyld.h> // For _NSGetExecutablePath
 
@interface OSVMLaunchApplication : NSApplication
@end

@interface OSVMLaunchAppDelegate : NSObject<NSApplicationDelegate> {
    NSMutableArray<NSString*> *filesToOpen;
}
@end

static OSVMLaunchAppDelegate *launchAppDelegate = nil;

@implementation OSVMLaunchApplication
@end

@implementation OSVMLaunchAppDelegate
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
    char path[2048];
    uint32_t size = sizeof(path);
    if(_NSGetExecutablePath(path, &size))
    {
        NSLog(@"VM executable path name is too long. Aborting.\n");
        abort();
    }
    
    NSArray<NSString*> *processCommandLineArguments = [[NSProcessInfo processInfo] arguments];
    NSMutableArray<NSString*> *newVMProcessCommandLineArguments = [NSMutableArray new];
    [newVMProcessCommandLineArguments addObjectsFromArray: processCommandLineArguments];
    [newVMProcessCommandLineArguments addObjectsFromArray: filesToOpen];
    
    char **vmArgv = calloc([newVMProcessCommandLineArguments count] + 1, sizeof(const char *));
    for(int i = 0; i < [newVMProcessCommandLineArguments count]; ++i)
        vmArgv[i] = strdup([newVMProcessCommandLineArguments[i] UTF8String]);
    
    execv(path, vmArgv);
}
@end

int
launcher_main(int argc, const char **argv)
{
    // Create the application.
    NSApplication *application = [OSVMLaunchApplication sharedApplication];
    
    // Create the application delegate.
    launchAppDelegate = [[OSVMLaunchAppDelegate alloc] init];
    [application setDelegate: launchAppDelegate];
    
    // Start the main run loop.
    [application performSelectorOnMainThread: @selector(run)
        withObject: nil waitUntilDone: YES];
    
    NSLog(@"TODO: Launcher main program\n");
    return 0;
}

int
main(int argc, const char **argv)
{
    // If there is a startup image, then we should just use it.
    if(osvm_findStartupImage(argv[0], NULL))
        return osvm_main(argc, argv);
        
    // In OS X, the user may want to drop an image file to the VM application.
    // Dropped image files are treated as events, whose reception is only
    // obtained through the usage of an AppDelegate, which is tied to a
    // NSApplication Singleton that cannot be created and destroyed for just
    // receiving this event. In addition to this, the user may want to
    // have an open image dialog. For this reason, we need to detect on
    // whether this program is being executed as a command line Unix tool, or is
    // being executed as an OS X application. We detect this by looking for a
    // -psn command line argument. We also look for the presence of the image in
    // the command line. If no image is specified, we run as if we were a
    // launcher application. Once we receive the image drop event, we launch
    // another process but with the image file name passed as a command line
    // argument.
    
    // Look for something that looks like an image file.
    int isImageFilePassedOnTheCommandLine = 0;
    int programExecutedAsCommandLineTool = 0;
    
    for(int i = 1; i < argc; ++i)
    {
        const char *arg = argv[i];
        if(!strcmp(arg, "--"))
        {
            // This is where the VM command line arguments end. We ignore
            // the rest.
            break;
        }
        else if(*arg == '-')
        {
            // The process serial number indicates that this program is being
            // executed as an OS X application.
            if(!strncmp(arg, "-psn", 4) || !strcmp(arg, "-NSDocumentRevisionsDebugMode"))
            {
                programExecutedAsCommandLineTool = 0;
            }
            else
            {
                programExecutedAsCommandLineTool = 1;
            }
            
            // Ignore VM command line arguments
            i += osvm_getVMCommandLineArgumentParameterCount(arg);
        }
        else
        {
            isImageFilePassedOnTheCommandLine = 1;
        }
        
        // Have we found all of the interesting flags?
        if(isImageFilePassedOnTheCommandLine)
            break;
    }
    
    // If this is a program executed as a command line tool, or we found the
    // file passed on the command line, then just hand over the execution to the
    // normal VM execution machinery.
    if(programExecutedAsCommandLineTool || isImageFilePassedOnTheCommandLine)
        return osvm_main(argc, argv);
        
    // This program does not know what VM to run, so run as a separate image
    // launcher program.
    return launcher_main(argc, argv);
}
