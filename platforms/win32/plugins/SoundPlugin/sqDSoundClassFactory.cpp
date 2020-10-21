#include "sqDSoundClassFactory.h"
#include "sq.h"
#include <tchar.h>

#include "sqWin32DPRINTF.h"

typedef HRESULT  (CALLBACK * GETCLASSOBJECTPROC)(REFCLSID, REFIID, LPVOID *);
static HMODULE hDSoundDLL = NULL;
static GETCLASSOBJECTPROC fProc = NULL;


int dsound_InitClassFactory()
{
	hDSoundDLL = LoadLibraryA("dsound.dll");
	if (hDSoundDLL == NULL) {
		DPRINTF(("ERROR dsound_InitClassFactory():  cannot load 'dsound.dll'\n"));
		return 0;
	}
	if (fProc) {
		DPRINTF(("WARNING dsound_InitClassFactory():  'fProc' already non-NULL\n"));
	}
	fProc = (GETCLASSOBJECTPROC)GetProcAddress(hDSoundDLL, "DllGetClassObject");
	if (fProc == NULL) {
		DPRINTF(("ERROR dsound_InitClassFactory():  cannot load 'DllGetClassObject()'\n"));
		return 0;
	}
	return 1;
}


int
dsound_ShutdownClassFactory()
{
	if (hDSoundDLL)
		FreeLibrary(hDSoundDLL);
	hDSoundDLL = NULL;
	fProc = NULL;
	return 1;
}


IClassFactory* dsound_GetClassFactory(REFCLSID classID)
{
	IClassFactory* factory;

	// For some reason, IID_IClassFactory isn't available to the cygwin linker (although
	// it compiles/links fine for MSVC).  Instead, I manually construct the IID for
	// IClassFactory.
	//HRESULT hr = fProc(classID, IID_IClassFactory, (void**)&factory);
	IID iid = {NULL};
	HRESULT hr = IIDFromString((LPOLESTR)(L"{00000001-0000-0000-C000-000000000046}"), &iid);
	if (FAILED(hr)) {
		DPRINTF(("ERROR dsound_GetClassFactory():  failed to initialize IID for IClassFactory\n"));
		return NULL;
	}
	hr = fProc(classID, iid, (void**)&factory);
	if (FAILED(hr)) {
		DPRINTF(("ERROR dsound_GetClassFactory():  failed to obtain class-factory\n"));
		return NULL;
	}
	return factory;
}
