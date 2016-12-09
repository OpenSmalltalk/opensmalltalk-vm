/* SqueakVirtualMachine.h -- platform-specific modifications to sq.h
 *
 *   Copyright (C) 2016 by Ronie Salgado and other authors/contributors
 *                              listed elsewhere in this file.
 *   All rights reserved.
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
 * Author: ian.piumarta@squeakland.org
 *
 */

/**
 * Squeak virtual machine public embedding interface.
 */

#ifndef SQUEAK_VIRTUAL_MACHINE_H
#define SQUEAK_VIRTUAL_MACHINE_H

#include <stdint.h>

#ifdef _WIN32
#   ifdef BUILD_SQUEAK_STATIC
#       define SQUEAK_VM_EXPORT
#       define SQUEAK_VM_IMPORT
#   else
#       define SQUEAK_VM_EXPORT __declspec(dllexport)
#       define SQUEAK_VM_IMPORT __declspec(dllimport)
#   endif
#else
#   define SQUEAK_VM_EXPORT
#   define SQUEAK_VM_IMPORT
#endif

#ifdef BUILD_VM_CORE
#   define SQUEAK_VM_CORE_PUBLIC SQUEAK_VM_EXPORT
#else
#   define SQUEAK_VM_CORE_PUBLIC SQUEAK_VM_IMPORT
#endif

#define SQUEAK_VM_CORE_VERSION(major, minor, revision) ((major)*1000 + (minor)*10 + (revision))
#define SQUEAK_VM_CORE_COMPILED_VERSION SQUEAK_VM_CORE_VERSION(0, 1, 0)

typedef intptr_t squeakInt;
typedef uintptr_t squeakUInt;

/**/
typedef enum
{
    SQUEAK_SUCCESS = 0,
    SQUEAK_ERROR,
    SQUEAK_ERROR_INVALID_PARAMETER,
    SQUEAK_ERROR_NOT_YET_IMPLEMENTED,
    SQUEAK_ERROR_OUT_OF_BOUNDS,
    SQUEAK_ERROR_OUT_OF_MEMORY,
    SQUEAK_ERROR_UNSUPPORTED_OPERATION,
    SQUEAK_ERROR_UNSUPPORTED_PARAMETER,
    SQUEAK_ERROR_FAILED_TO_OPEN_FILE,
    SQUEAK_ERROR_FAILED_TO_LOAD_IMAGE,
} SqueakError;

/**
 * Get the virtual machine embedding interface version
 */
SQUEAK_VM_CORE_PUBLIC int squeak_getInterfaceVersion(void);

/**
 * Simple all mighty main entry point for running a Squeak VM.
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_main(int argc, const char **argv);

/**
 * Global initialization of Squeak
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_initialize(void);

/**
 * Global shutting down of Squeak VM
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_shutdown(void);

/**
 * Initialize the Squeak VM
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_initializeVM(void);

/**
 * Shutdown the Squeak VM
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_shutdownVM(void);

/**
 * Parse command line arguments
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_parseCommandLineArguments(int argc, const char **argv);

/**
 * Parse the VM command line arguments
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_parseVMCommandLineArguments(int argc, const char **argv);

/**
 * Set a string VM parameter
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_setVMStringParameter(const char *name, const char *value);

/**
 * Set an integer VM parameter
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_setVMIntegerParameter(const char *name, const char *value);

/**
 * Pass the image command line arguments
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_passImageCommandLineArguments(int argc, const char **argv);

/**
 * Load the image
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_loadImage(const char *fileName);

/**
 * Load the default image or the one provided on the command line
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_loadDefaultImage(void);

/**
 * Run indefinetely the previously loaded image.
 */
SQUEAK_VM_CORE_PUBLIC SqueakError squeak_run(void);

#endif /* SQUEAK_VIRTUAL_MACHINE_H */
