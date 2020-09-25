/* sqWin32Main.c -- main entry point for the standalone Squeak VM for the Win32
 * subsystem in Windows
 *
 *   Copyright (C) 2016 by Ronie Salgado
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

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commdlg.h>
#include <stdlib.h>
#include <string.h>
#include "OpenSmalltalkVM.h"

static WCHAR openImageDialogResultBuffer[MAX_PATH + 1];
static int mainEntryPoint(int argc, const char **argv)
{
    // If there is a startup image, then we should just use it.
    if(osvm_findStartupImage(argv[0], NULL))
        return osvm_main(argc, argv);

    // Try to find a explicit image on the command line.
    int hasImageArgument = 0;
    for(int i = 1; i < argc; ++i)
    {
        const char *argument = argv[i];

        // Is this the point where the image command line arguments are starting?
        if(!strcmp(argument, "--"))
        {
            break;
        }
        else if(*argument == '-')
        {
            // Ignore the option argument
            i += osvm_getVMCommandLineArgumentParameterCount(argument);
        }
        else
        {
            // The first non-option argument must be the image name.
            hasImageArgument = 1;
            break;
        }
    }

    // We found an image, so lets just start with the main VM process.
    if(hasImageArgument)
        return osvm_main(argc, argv);

    // No image is specified, so lets ask the user about the image.
    OPENFILENAMEW dialogArguments;
    memset(&dialogArguments, 0, sizeof(dialogArguments));
    dialogArguments.lStructSize = sizeof(dialogArguments);
    dialogArguments.lpstrFile = openImageDialogResultBuffer;
    dialogArguments.nMaxFile = sizeof(openImageDialogResultBuffer);
    dialogArguments.lpstrFilter = L"Pharo image file (*image)\0*.image\0All files\0*.*\0\0";
    dialogArguments.nFilterIndex = 0;
    dialogArguments.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;
    if(GetOpenFileNameW(&dialogArguments))
    {
        // Create a new set of command line arguments.
        int newArgc = argc + 1;
        const char **newArgv = (const char **)osvm_calloc(newArgc + 2, sizeof(const char*));
        for(int i = 0; i < argc; ++i)
            newArgv[i] = argv[i];

        // Convert the image file path.
        char *convertedPathString = osvm_utf16ToUt8(openImageDialogResultBuffer);
        newArgv[argc] = convertedPathString;

        // Run the VM with the new arguments.
        int returnCode = osvm_main(newArgc, newArgv);
        osvm_free(convertedPathString);
        osvm_free(newArgv);
        return returnCode;
    }

    return 0;
}

int CALLBACK WinMain(
  HINSTANCE hInstance,
  HINSTANCE hPrevInstance,
  LPSTR     lpCmdLine,
  int       nCmdShow
)
{
    return mainEntryPoint(__argc, (const char **)__argv);
}
