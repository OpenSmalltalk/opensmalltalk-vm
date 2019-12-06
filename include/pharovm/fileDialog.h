#ifndef PHAROVM_FILE_DIALOG_H
#define PHAROVM_FILE_DIALOG_H

#include "errorCode.h"
#include <stdbool.h>

typedef struct VMFileDialog_
{
    bool succeeded;
    const char *title;
    const char *message;
    const char *filterDescription;
    const char *filterExtension;
    const char *defaultFileNameAndPath;
    char *selectedFileName;
} VMFileDialog;

/**
 * Starts a modal open file dialog.
 */
EXPORT(VMErrorCode) vm_file_dialog_run_modal_open(VMFileDialog *dialog);

/**
 * Destroys a file dialog.
 */
EXPORT(VMErrorCode) vm_file_dialog_destroy(VMFileDialog *dialog);

/**
 * This methods tells on whether the file dialog is actually a dialog, or a no operation passthrough.
 */
EXPORT(bool) vm_file_dialog_is_nop(void);

#endif //PHAROVM_FILE_DIALOG_H
