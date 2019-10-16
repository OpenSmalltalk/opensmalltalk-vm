// only locally define UNICODE in this compilation unit
// FIXME: Unicode should be used everywhere.
#ifndef UNICODE
#define UNICODE
#endif

#include "fileDialog.h"
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <Shobjidl.h>

VMErrorCode
vm_file_dialog_run_modal_open(VMFileDialog *dialog)
{
    COMDLG_FILTERSPEC filters[2];
	filters[0].pszName = L"Pharo Images (*.image)";
	filters[0].pszSpec = L"*.image";
	filters[1].pszName = L"All files";
	filters[1].pszSpec = L"*.*";


	HRESULT hresult = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    if(FAILED(hresult))
        return PHAROVM_ERROR;

	// Create the FileOpenDialog object.
    IFileOpenDialog *fileOpenDialog;
	hresult = CoCreateInstance(&CLSID_FileOpenDialog, NULL, CLSCTX_ALL, &IID_IFileOpenDialog, (void**)&fileOpenDialog);

    pharovm_error_code_t resultCode = PHAROVM_SUCCESS;
	if (SUCCEEDED(hresult)) {
		// Show the Open dialog box.
		fileOpenDialog->lpVtbl->SetTitle(fileOpenDialog, L"Select Pharo Image to Open");
		fileOpenDialog->lpVtbl->SetFileTypes(fileOpenDialog, 2, filters);
		fileOpenDialog->lpVtbl->SetFileTypeIndex(fileOpenDialog, 1); //Selects the first, it is 1 based!
		hresult = fileOpenDialog->lpVtbl->Show(fileOpenDialog, NULL);

		// Get the file name from the dialog box.
		if (SUCCEEDED(hresult)) {
			IShellItem *item;
			hresult = fileOpenDialog->lpVtbl->GetResult(fileOpenDialog, &item);
			if (SUCCEEDED(hresult)) {
				PWSTR filePath;
				hresult = item->lpVtbl->GetDisplayName(item, SIGDN_FILESYSPATH, &filePath);

				if (SUCCEEDED(hresult)) {
					int requiredSize = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, filePath, -1, NULL, 0, NULL, NULL);
					char *resultString = (char*)calloc(1, requiredSize + 1);
					int result = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, filePath, -1, resultString, requiredSize, NULL, NULL);

					if(result != 0) {
                        free(parameters->imageFileName);
						parameters->imageFileName = resultString;
                        parameters->hasBeenSelectedByUserInteractively = true;
					} else {
                        free(resultString);
                    }

					CoTaskMemFree(filePath);
				} else {
                    resultCode = PHAROVM_ERROR;
                }
				item->lpVtbl->Release(item);
			} else {
				resultCode = PHAROVM_ERROR;
            }
		} else {
			if (hresult == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
				resultCode = PHAROVM_ERROR_EXIT_WITH_SUCCESS;
			}
			else {
				resultCode = PHAROVM_ERROR;
			}
		}
		fileOpenDialog->lpVtbl->Release(fileOpenDialog);
	} else {
        resultCode = PHAROVM_ERROR;
    }
	CoUninitialize();

    return resultCode;
}
