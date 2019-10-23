#include "fileDialog.h"

VMErrorCode
vm_file_dialog_destroy(VMFileDialog *dialog)
{
    if(!dialog) return VM_ERROR_NULL_POINTER;

    free(dialog->selectedFileName);
    return VM_SUCCESS;
}
