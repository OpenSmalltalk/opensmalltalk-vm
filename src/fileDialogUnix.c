#include "fileDialog.h"
#include "pathUtilities.h"

bool
vm_file_dialog_is_nop(void)
{
	return true;
}

VMErrorCode
vm_file_dialog_run_modal_open(VMFileDialog *dialog)
{
	if(!dialog) return VM_ERROR_OUT_OF_MEMORY;

	dialog->succeeded = true;
	dialog->selectedFileName = strdup(dialog->defaultFileNameAndPath);

	return VM_SUCCESS;
}
