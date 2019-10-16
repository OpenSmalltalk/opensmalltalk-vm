#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#include "fileDialog.h"
#include "stringUtilities.h"
#include <string.h>

bool
vm_file_dialog_is_nop(void)
{
	return false;
}

VMErrorCode
vm_file_dialog_run_modal_open(VMFileDialog *dialog)
{
    NSString *allowedExtension = nil;
    if(dialog->filterExtension && dialog->filterExtension[0] == '.')
    {
        allowedExtension = [NSString stringWithUTF8String: dialog->filterExtension + 1];
    }
    
    // No image file is specified. Display the file open dialog.
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.title = [NSString stringWithUTF8String: dialog->title];
    panel.message = [NSString stringWithUTF8String: dialog->message];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    
    if(allowedExtension != nil)
    {
        panel.allowedFileTypes = [NSArray arrayWithObjects: allowedExtension, nil];        
    }

    dialog->succeeded = false;
    dialog->selectedFileName = NULL;
    
    NSInteger clickedButton = [panel runModal];
    if(clickedButton == NSModalResponseOK)
    {
        for (NSURL *url in [panel URLs])
        {
            if([url isFileURL])
            {
                dialog->succeeded = false;
                dialog->selectedFileName = strdup([url.path UTF8String]);
            }
        }
    }

    return VM_SUCCESS;
}
