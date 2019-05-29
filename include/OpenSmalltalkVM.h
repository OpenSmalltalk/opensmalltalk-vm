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
 * Author: roniesalg@gmail.com
 *
 */

/**
 * Squeak virtual machine public embedding interface.
 */

#ifndef OPEN_SMALLTALK_VM_H
#define OPEN_SMALLTALK_VM_H

#include <stdint.h>

#ifdef _WIN32
#   ifdef BUILD_OSVM_STATIC
#       define OSVM_VM_EXPORT
#       define OSVM_VM_IMPORT
#   else
#       define OSVM_VM_EXPORT __declspec(dllexport)
#       define OSVM_VM_IMPORT __declspec(dllimport)
#   endif
#else
#   define OSVM_VM_EXPORT
#   define OSVM_VM_IMPORT
#endif

#ifdef BUILD_VM_CORE
#   define OSVM_VM_CORE_PUBLIC OSVM_VM_EXPORT
#else
#   define OSVM_VM_CORE_PUBLIC OSVM_VM_IMPORT
#endif

#define OSVM_VM_CORE_VERSION(major, minor, revision) ((major)*1000 + (minor)*10 + (revision))
#define OSVM_VM_CORE_COMPILED_VERSION OSVM_VM_CORE_VERSION(0, 1, 0)

typedef intptr_t osvmInt;
typedef uintptr_t osvmUInt;

#ifdef __cplusplus
extern "C" {
#endif

/**
 * OpenSmalltalk VM Error codes.
 */
typedef enum
{
    OSVM_SUCCESS = 0,
    OSVM_ERROR,
    OSVM_ERROR_INVALID_PARAMETER,
    OSVM_ERROR_INVALID_VM_INSTANCE_HANDLE,
    OSVM_ERROR_VM_IMPLEMENTATION_NON_REENTRANT,
    OSVM_ERROR_NULL_POINTER,
    OSVM_ERROR_NOT_YET_IMPLEMENTED,
    OSVM_ERROR_OUT_OF_BOUNDS,
    OSVM_ERROR_OUT_OF_MEMORY,
    OSVM_ERROR_UNSUPPORTED_OPERATION,
    OSVM_ERROR_UNSUPPORTED_PARAMETER,
    OSVM_ERROR_FAILED_TO_OPEN_FILE,
    OSVM_ERROR_FAILED_TO_LOAD_IMAGE,
} OSVMError;

/**
 * OpenSmalltalk VM Instance handle.
 * Note: even though the current VM version is not reentrant, this handle is
 * provided with forward compatibility purposes.
 */
typedef struct OSVMInstance *OSVMInstanceHandle;

#define OSVMInstanceInvalidHandle 0

/**
 * Get the virtual machine embedding interface version
 */
OSVM_VM_CORE_PUBLIC int osvm_getInterfaceVersion(void);

/**
 * Simple all mighty main entry point for running an OpenSmalltalk VM
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_main(int argc, const char **argv);

/**
 * VM instance initialization.
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_initialize(OSVMInstanceHandle *resultVMHandle);

/**
 * Global shutting down of Squeak VM
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_shutdown(OSVMInstanceHandle vmHandle);

/**
 * Initialize the Squeak VM
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_initializeVM(OSVMInstanceHandle vmHandle);

/**
 * Shutdown the Squeak VM
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_shutdownVM(OSVMInstanceHandle vmHandle);

/**
 * Parse command line arguments
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_parseCommandLineArguments(OSVMInstanceHandle vmHandle, int argc, const char **argv);

/**
 * Parse the VM command line arguments
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_parseVMCommandLineArguments(OSVMInstanceHandle vmHandle, int argc, const char **argv);

/**
 * This gets the number of parameters associated with a VM command line argument
 */
OSVM_VM_CORE_PUBLIC int osvm_getVMCommandLineArgumentParameterCount(const char *argument);

/**
 * Set a string VM parameter
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_setVMStringParameter(OSVMInstanceHandle vmHandle, const char *name, const char *value);

/**
 * Set an integer VM parameter
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_setVMIntegerParameter(OSVMInstanceHandle vmHandle, const char *name, const char *value);

/**
 * Pass the image command line arguments
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_passImageCommandLineArguments(OSVMInstanceHandle vmHandle, int argc, const char **argv);

/**
 * Load the image
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_loadImage(OSVMInstanceHandle vmHandle, const char *fileName);

/**
 * Load the default image or the one provided on the command line
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_loadDefaultImage(OSVMInstanceHandle vmHandle);

/**
 * Run indefinetely the previously loaded image.
 */
OSVM_VM_CORE_PUBLIC OSVMError osvm_run(OSVMInstanceHandle vmHandle);

#ifdef __cplusplus
}
#endif

#endif /* OPEN_SMALLTALK_VM_H */
