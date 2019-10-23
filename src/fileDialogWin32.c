// only locally define UNICODE in this compilation unit
// FIXME: Unicode should be used everywhere.
#ifndef UNICODE
#define UNICODE
#endif

#include "fileDialog.h"
#include "stringUtilities.h"
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <Shobjidl.h>

bool
vm_file_dialog_is_nop(void)
{
	return false;
}

VMErrorCode
vm_file_dialog_run_modal_open(VMFileDialog *dialog)
{
    // Convert the filter description and extension.
    WCHAR *filterDescription = vm_string_convert_utf8_to_utf16(dialog->filterDescription);
	char *filterPattern = vm_string_concat("*", dialog->filterExtension);
    WCHAR *filterExtension = vm_string_convert_utf8_to_utf16(filterPattern);
	free(filterPattern);

    COMDLG_FILTERSPEC filters[2];
	filters[0].pszName = filterDescription;
	filters[0].pszSpec = filterExtension;
	filters[1].pszName = L"All files";
	filters[1].pszSpec = L"*.*";

	HRESULT hresult = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    if(FAILED(hresult))
    {
        free(filterDescription);
        free(filterExtension);
        return VM_ERROR;
    }

	// Create the FileOpenDialog object.
    IFileOpenDialog *fileOpenDialog;
	hresult = CoCreateInstance(&CLSID_FileOpenDialog, NULL, CLSCTX_ALL, &IID_IFileOpenDialog, (void**)&fileOpenDialog);

    VMErrorCode resultCode = VM_SUCCESS;
    dialog->succeeded = false;
	if (SUCCEEDED(hresult))
    {
		// Show the Open dialog box.
		fileOpenDialog->lpVtbl->SetTitle(fileOpenDialog, L"Select Pharo Image to Open");
		fileOpenDialog->lpVtbl->SetFileTypes(fileOpenDialog, 2, filters);
		fileOpenDialog->lpVtbl->SetFileTypeIndex(fileOpenDialog, 1); //Selects the first, it is 1 based!
		hresult = fileOpenDialog->lpVtbl->Show(fileOpenDialog, NULL);

		// Get the file name from the dialog box.
		if (SUCCEEDED(hresult))
        {
			IShellItem *item;
			hresult = fileOpenDialog->lpVtbl->GetResult(fileOpenDialog, &item);
			if (SUCCEEDED(hresult))
            {
				PWSTR filePath;
				hresult = item->lpVtbl->GetDisplayName(item, SIGDN_FILESYSPATH, &filePath);

				if (SUCCEEDED(hresult))
                {
                    char *resultString = vm_string_convert_utf16_to_utf8(filePath);
					if(resultString)
                    {
                        dialog->selectedFileName = resultString;
                        dialog->succeeded = true;
					}
                    else
                    {
                        free(resultString);
                    }

					CoTaskMemFree(filePath);
				}
                else
                {
                    resultCode = VM_ERROR;
                }
				item->lpVtbl->Release(item);
			}
            else
            {
				resultCode = VM_ERROR;
            }
		}
        else
        {
			if (hresult == HRESULT_FROM_WIN32(ERROR_CANCELLED))
            {
				resultCode = VM_SUCCESS;
			}
			else
            {
				resultCode = VM_ERROR;
			}
		}
		fileOpenDialog->lpVtbl->Release(fileOpenDialog);
	}
    else
    {
        resultCode = VM_ERROR;
    }
	CoUninitialize();

    free(filterDescription);
    free(filterExtension);

    return resultCode;
}
