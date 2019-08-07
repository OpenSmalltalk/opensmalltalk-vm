/* only locally define UNICODE in this compilation unit */
#ifndef UNICODE
#define UNICODE
#endif

#include <windows.h>
#include <Shobjidl.h>

extern "C" {


int openFileDialog(char const * aTitle,
                   char const * aDefaultPathAndFile,
                   char const * filter,
                   char ** selectedFile,
				   char * defaultFile){

	COMDLG_FILTERSPEC filters[2];
	filters[0].pszName = L"Pharo Images (*.image)";
	filters[0].pszSpec = L"*.image";
	filters[1].pszName = L"All files";
	filters[1].pszSpec = L"*.*";


	//If I am in the console
	if(GetStdHandle(STD_INPUT_HANDLE) != NULL){
		*selectedFile = defaultFile;
		return false;
	};

	HRESULT hr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);

	if (SUCCEEDED(hr)){
		IFileOpenDialog *pFileOpen;

		// Create the FileOpenDialog object.
		hr = CoCreateInstance(CLSID_FileOpenDialog, NULL, CLSCTX_ALL, IID_IFileOpenDialog, (void**)&pFileOpen);

		if (SUCCEEDED(hr)){
			// Show the Open dialog box.
			pFileOpen->SetTitle(L"Select Pharo Image to Open");
			pFileOpen->SetFileTypes(2, filters);
			pFileOpen->SetFileTypeIndex(1); //Selects the first, it is 1 based!
			hr = pFileOpen->Show(NULL);

			// Get the file name from the dialog box.
			if (SUCCEEDED(hr)){
				IShellItem *pItem;
				hr = pFileOpen->GetResult(&pItem);
				if (SUCCEEDED(hr))
				{
					PWSTR pszFilePath;
					hr = pItem->GetDisplayName(SIGDN_FILESYSPATH, &pszFilePath);

					if (SUCCEEDED(hr)){
						int requiredSize = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, pszFilePath, -1, NULL, 0, NULL, NULL);
						*selectedFile = (char*)malloc(requiredSize + 1);
						int result = WideCharToMultiByte(CP_UTF8, WC_ERR_INVALID_CHARS, pszFilePath, -1, *selectedFile, requiredSize, NULL, NULL);

						if(result == 0){
							*selectedFile = defaultFile;
						}

						CoTaskMemFree(pszFilePath);
					}
					pItem->Release();
				}
			}
			pFileOpen->Release();
		}
		CoUninitialize();
	}

	return true;
}

}
