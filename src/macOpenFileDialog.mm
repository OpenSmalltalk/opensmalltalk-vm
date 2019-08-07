#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#include <string>
#include <vector>

extern "C" {
    int openFileDialog(char const * aTitle,
                       char const * aDefaultPathAndFile,
                       char const * filter,
                       char ** selectedFile,
                       char const * defaultFile);
   
}

int openFileDialog(char const * aTitle,
                   char const * aDefaultPathAndFile,
                   char const * filter,
                   char ** selectedFile,
                   char const * defaultFile) {
    
    int i;
    std::vector<std::string> fileList;

    // Create a File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setLevel:CGShieldingWindowLevel()];
    // Set array of file types
    
    NSMutableArray * fileTypesArray = [NSMutableArray array];
    NSString * filt =[NSString stringWithUTF8String: filter];
    [fileTypesArray addObject:filt];
    
    // Enable options in the dialog.
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowedFileTypes:fileTypesArray];
    [openDlg setAllowsMultipleSelection:FALSE];
    [openDlg setDirectoryURL:[NSURL URLWithString:[NSString stringWithUTF8String:aDefaultPathAndFile ] ] ];
    
    // Display the dialog box. If the OK pressed,
    // process the files.
    if ( [openDlg runModal] == NSModalResponseOK ) {
        // Gets list of all files selected
        NSArray *files = [openDlg URLs];
        // Loop through the files and process them.
        for( i = 0; i < [files count]; i++ ) {
            // Do something with the filename.
            const char* value = [[[files objectAtIndex:i] path] UTF8String];
            *selectedFile = (char*)malloc(strlen(value)+1);
            strcpy(*selectedFile, value);
        }
        return true;
    }
    
    *selectedFile = defaultFile;
    return false;
}
