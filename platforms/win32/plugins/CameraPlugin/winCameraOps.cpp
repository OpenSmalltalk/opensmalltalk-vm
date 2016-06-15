#include <windows.h>

#include <atlbase.h>
#include <dshow.h>
#include <stdio.h>
#include <qedit.h>

extern "C" {
#include "cameraOps.h"
}

//////////////////////////////////////////////
// Sample Grabber Class
//////////////////////////////////////////////

class CSampleGrabberCB : public ISampleGrabberCB {
public:
	int frameCount;			// number of frames received since last GetFrame() call
	long lFrameBufSize;		// size of buffer
	BYTE *pFrameBuf;

	// fake out any COM ref counting
	STDMETHODIMP_(ULONG) AddRef() { return 2; }
	STDMETHODIMP_(ULONG) Release()
	{
		frameCount = 0;
		lFrameBufSize = 0;
		pFrameBuf = NULL;
		return 1;
	}

	// fake out any COM QI'ing
	STDMETHODIMP QueryInterface(REFIID riid, void ** ppv)
	{
		if (riid == IID_ISampleGrabberCB || riid == IID_IUnknown) {
			*ppv = (void *) static_cast<ISampleGrabberCB*> (this);
			return NOERROR;
		}
		return E_NOINTERFACE;
	}

	STDMETHODIMP SampleCB(double SampleTime, IMediaSample * pSample) { return 0; } // noop

	STDMETHODIMP BufferCB(double dblThisSampleTime, BYTE * pThisBuf, long lThisBufSize)
	{
		if ((pThisBuf == NULL) || (lThisBufSize == 0)) return E_POINTER;

		// if the buffer sizes don't match, discard ours to force creating a new one
		if (lFrameBufSize != lThisBufSize) {
			lFrameBufSize = 0;
			delete [] pFrameBuf;
			pFrameBuf = NULL;
		}

		// if we haven't yet created the data buffer, do it now.
		if (!pFrameBuf) {
			pFrameBuf = new BYTE[lThisBufSize];
			lFrameBufSize = lThisBufSize;
			if (!pFrameBuf) lFrameBufSize = 0;
		}

		// Copy the bitmap data into our global buffer
		if (pFrameBuf) memcpy(pFrameBuf, pThisBuf, lFrameBufSize);
		frameCount++;

		return 0;
	}
};

//////////////////////////////////////////////
// Data
//////////////////////////////////////////////

typedef struct Camera {
	IBaseFilter *pCamera;
	IGraphBuilder *pGraph;
	ICaptureGraphBuilder2 *pCapture;
	IMediaControl *pMediaControl;
	IBaseFilter *ppf;
	ISampleGrabber *pGrabber;
	CSampleGrabberCB mCB;
	int width;
	int height;
} Camera;

#define CAMERA_COUNT 8
Camera theCamera;

//////////////////////////////////////////////
// Local functions and macros
//////////////////////////////////////////////

int CameraIsOpen();
void FindBestWidth(IAMStreamConfig *pCameraStream, int desiredWidth);
HRESULT FindCamera(IBaseFilter ** ppSrcFilter, int num);
void FreeMediaType(AM_MEDIA_TYPE *pMediaType);
void FreeMediaTypeFields(AM_MEDIA_TYPE *pMediaType);
char* GetCameraName(int num);
HRESULT InitCamera(int num, int desiredWidth);
void Msg(TCHAR *szFormat, ...);
void SetCameraWidth(ICaptureGraphBuilder2 *pCaptureGraphBuilder, IBaseFilter *pSrcFilter, int desiredWidth);
void SetOutputToRGB(void);

#define SAFE_RELEASE(x) { if (x) x->Release(); x = NULL; }

//////////////////////////////////////////////
// Entry Points
//////////////////////////////////////////////

int CameraOpen(int cameraNum, int desiredWidth, int desiredHeight)
{
	CameraClose(cameraNum);
	int hr = InitCamera(cameraNum, desiredWidth);
	return SUCCEEDED(hr);
}

void CameraClose(int cameraNum)
{
	if (!CameraIsOpen()) return;

	// stop getting video
	if (theCamera.pMediaControl) theCamera.pMediaControl->StopWhenReady();

	// release DirectShow objects
	SAFE_RELEASE(theCamera.pMediaControl);
	SAFE_RELEASE(theCamera.pGraph);
	SAFE_RELEASE(theCamera.pCapture);
	SAFE_RELEASE(theCamera.pGrabber);
	SAFE_RELEASE(theCamera.ppf);
	SAFE_RELEASE(theCamera.pCamera);
	theCamera.width = theCamera.height = 0;
}

int CameraExtent(int cameraNum)
{
	if (!CameraIsOpen()) return 0;

	return (theCamera.width << 16) + theCamera.height;
}

int CameraGetFrame(int cameraNum, unsigned char* buf, int pixelCount)
{
	if (!CameraIsOpen()) return -1;

	int framesSinceLastCall = theCamera.mCB.frameCount;
	if (framesSinceLastCall == 0) return 0;  // no frame available
	theCamera.mCB.frameCount = 0;  // clear frame count

	if (pixelCount > (theCamera.mCB.lFrameBufSize / 3)) pixelCount = (theCamera.mCB.lFrameBufSize / 3);

	// flip image vertically while copying to Squeak buf
	unsigned char* pSrc = theCamera.mCB.pFrameBuf;
	for (int y = theCamera.height - 1; y >= 0; y--) {
		unsigned char* pDst = &buf[4 * y * theCamera.width];
		for (int x = 0; x < theCamera.width; x++) {
			*pDst++ = *pSrc++;		// red
			*pDst++ = *pSrc++;		// green
			*pDst++ = *pSrc++;		// blue
			*pDst++ = 255;			// alpha
		}
	}

	return framesSinceLastCall;
}

char* CameraName(int cameraNum)
{
	if ((cameraNum < 1) || (cameraNum > CAMERA_COUNT)) return NULL;
	return GetCameraName(cameraNum);
}

int CameraGetParam(int cameraNum, int paramNum)  // for debugging and testing
{
	if (!CameraIsOpen()) return -1;
	if (paramNum == 1) return theCamera.mCB.frameCount;
	if (paramNum == 2) return theCamera.mCB.lFrameBufSize;

	return -2;
}

//////////////////////////////////////////////
// Local functions
//////////////////////////////////////////////

int CameraIsOpen()
{
	return theCamera.mCB.pFrameBuf != NULL;
}

HRESULT FindCamera(IBaseFilter ** ppSrcFilter, int cameraNum)
{
	HRESULT hr;
	IBaseFilter *pSrc = NULL;
	CComPtr <IMoniker> pMoniker = NULL;
	ULONG cFetched;

	if (!ppSrcFilter) return E_POINTER;

	*ppSrcFilter = NULL;  // clear output in case we return early with an error

	// Create system device enumerator
	CComPtr <ICreateDevEnum> pDevEnum = NULL;
	hr = CoCreateInstance(
		CLSID_SystemDeviceEnum, NULL, CLSCTX_INPROC,
		IID_ICreateDevEnum, (void **) &pDevEnum);
	if (FAILED(hr)) return hr;

	// Create enumerator for the video capture devices
	CComPtr <IEnumMoniker> pClassEnum = NULL;
	hr = pDevEnum->CreateClassEnumerator (CLSID_VideoInputDeviceCategory, &pClassEnum, 0);
	if (FAILED(hr)) return hr;

	// If there are no enumerators for the requested type, then
	// CreateClassEnumerator will succeed, but pClassEnum will be NULL.
	if (pClassEnum == NULL) return E_FAIL;

	// Find the nth video capture device on the device list.
	// Note that if the Next() call succeeds but there are no monikers,
	// it will return S_FALSE (which is not a failure). Therefore, we
	// check that the return code is S_OK instead of using SUCCEEDED() macro
	for (int i = 1; i <= cameraNum; i++) {
		if (S_OK != pClassEnum->Next (1, &pMoniker, &cFetched)) return E_FAIL;
	}

	// Bind Moniker to a filter object
	hr = pMoniker->BindToObject(0, 0, IID_IBaseFilter, (void**) &pSrc);
	if (FAILED(hr)) return hr;

	// Copy the found filter pointer to the output parameter.
	// Do NOT Release() the reference, since it will still be used
	// by the calling function.
	*ppSrcFilter = pSrc;
	return hr;
}

void FreeMediaType(AM_MEDIA_TYPE *pMediaType)  // free fields and structure
{
	if (!pMediaType) return;
	FreeMediaTypeFields(pMediaType);
	CoTaskMemFree((void *) pMediaType);
}

void FreeMediaTypeFields(AM_MEDIA_TYPE *pMediaType)  // free format and pUnk fields
{
	if (pMediaType->cbFormat != 0) {
		CoTaskMemFree((PVOID) pMediaType->pbFormat);
		pMediaType->cbFormat = 0;
		pMediaType->pbFormat = NULL;
	}
	if (pMediaType->pUnk != NULL) {
		// pUnk should be unused, but this is safest
		pMediaType->pUnk->Release();
		pMediaType->pUnk = NULL;
	}
}

char* GetCameraName(int cameraNum)
{
	CComPtr <ICreateDevEnum> pDevEnum = NULL;
	CComPtr <IEnumMoniker> pClassEnum = NULL;
	CComPtr <IMoniker> pMoniker = NULL;
	IPropertyBag* pPropBag;
	VARIANT varName;
	HRESULT hr;
	ULONG cFetched;
	char* result = NULL;

	// Create the system device enumerator
	hr = CoCreateInstance(
		CLSID_SystemDeviceEnum, NULL, CLSCTX_INPROC,
		IID_ICreateDevEnum, (void **) &pDevEnum);
	if (FAILED(hr)) return NULL;

	// Create an enumerator for the video capture devices
	hr = pDevEnum->CreateClassEnumerator(CLSID_VideoInputDeviceCategory, &pClassEnum, 0);
	if (FAILED(hr)) return NULL;

	// If there are no enumerators for the requested type, then
	// CreateClassEnumerator will succeed, but pClassEnum will be NULL.
	if (pClassEnum == NULL) return NULL;

	// Note that if the Next() call succeeds but there are no monikers,
	// it will return S_FALSE, which is not a failure. Therefore, we check
	// that the return code is S_OK instead of using the SUCCEEDED() macro.
	for (int i = 0; i < cameraNum; i++) {
		hr = pClassEnum->Next(1, &pMoniker, &cFetched);
		if (hr != S_OK) return NULL;
	}

	hr = pMoniker->BindToStorage(0, 0, IID_IPropertyBag, (void**)(&pPropBag));

	// Find the description or friendly name
	VariantInit(&varName);
	hr = pPropBag->Read(L"Description", &varName, 0);
	if (FAILED(hr)) {
		hr = pPropBag->Read(L"FriendlyName", &varName, 0);
	}

	if (SUCCEEDED(hr)) {
		int n = SysStringLen(varName.bstrVal);
		result = new char[n + 1];
		for (int i = 0; i < n; i++) {
			result[i] = (char) varName.bstrVal[i];
		}
		result[n] = 0;
		VariantClear(&varName);
	}

	pPropBag->Release();
	return result;
}

HRESULT InitCamera(int num, int desiredWidth)
{
	HRESULT hr;

	// get USB camera or other video capture device
	hr = FindCamera(&theCamera.pCamera, num);
	if (FAILED(hr)) return hr;

	// create filter graph
	hr = CoCreateInstance (
		CLSID_FilterGraph, NULL, CLSCTX_INPROC,
		IID_IGraphBuilder, (void **) &theCamera.pGraph);
	if (FAILED(hr)) return hr;

	// create capture graph builder
	hr = CoCreateInstance (
		CLSID_CaptureGraphBuilder2 , NULL, CLSCTX_INPROC,
		IID_ICaptureGraphBuilder2, (void **) &theCamera.pCapture);
	if (FAILED(hr)) return hr;

	// get media control interface
	hr = theCamera.pGraph->QueryInterface(IID_IMediaControl,(LPVOID *) &theCamera.pMediaControl);
	if (FAILED(hr)) return hr;

	// create SampleGrabber
	hr = CoCreateInstance(
		CLSID_SampleGrabber, NULL, CLSCTX_INPROC_SERVER,
		IID_IBaseFilter, (void**) &theCamera.ppf);
	if (FAILED(hr)) return hr;

	theCamera.ppf->QueryInterface(IID_ISampleGrabber, (void**) &theCamera.pGrabber);

	// attach the filter graph to the capture graph
	hr = theCamera.pCapture->SetFiltergraph(theCamera.pGraph);
	if (FAILED(hr)) return hr;

	hr = theCamera.pGraph->AddFilter(theCamera.ppf, L"Scratch Frame Grabber");
	if (FAILED(hr)) return hr;

	// add the camera
	hr = theCamera.pGraph->AddFilter(theCamera.pCamera, L"Camera");
	if (FAILED(hr)) return hr;

	// set the desired framesize and image format
	SetCameraWidth(theCamera.pCapture, theCamera.pCamera, desiredWidth);
	SetOutputToRGB();

	// connect the camera to the sample grabber, possibly inserting format conversion filters
	hr = theCamera.pCapture->RenderStream(
		&PIN_CATEGORY_CAPTURE, &MEDIATYPE_Video,
		theCamera.pCamera, NULL, theCamera.ppf);

	// record the actual camera frame dimensions
	AM_MEDIA_TYPE mt;
	hr = theCamera.pGrabber->GetConnectedMediaType(&mt);
	if (FAILED(hr)) return hr;

	theCamera.width  = ((VIDEOINFOHEADER*) mt.pbFormat)->bmiHeader.biWidth;
	theCamera.height = ((VIDEOINFOHEADER*) mt.pbFormat)->bmiHeader.biHeight;
	FreeMediaTypeFields(&mt);

	hr = theCamera.pGrabber->SetOneShot(FALSE);
	hr = theCamera.pGrabber->SetBufferSamples(FALSE);
	hr = theCamera.pGrabber->SetCallback(&theCamera.mCB, 1);

	// start getting video
	hr = theCamera.pMediaControl->Run();
	if (FAILED(hr)) return hr;

	return S_OK;
}

void SetOutputToRGB() {
	AM_MEDIA_TYPE mediaType;
	mediaType.majortype = MEDIATYPE_Video;
	mediaType.subtype = MEDIASUBTYPE_RGB24;
	mediaType.formattype = GUID_NULL;
	mediaType.pbFormat = NULL;
	mediaType.cbFormat = 0;
	theCamera.pGrabber->SetMediaType(&mediaType);
}

void SetCameraWidth(ICaptureGraphBuilder2 *pCaptureGraphBuilder, IBaseFilter *pSrcFilter, int desiredWidth)
{
	IAMStreamConfig *pCameraStream = NULL;
	HRESULT hr;

	// get the stream configuration interface
	hr = pCaptureGraphBuilder->FindInterface(
		&PIN_CATEGORY_CAPTURE, 0, pSrcFilter,
		IID_IAMStreamConfig, (void**) &pCameraStream);
	if (FAILED(hr)) return;

	FindBestWidth(pCameraStream, desiredWidth);

	SAFE_RELEASE(pCameraStream);
}

void FindBestWidth(IAMStreamConfig *pCameraStream, int desiredWidth)
{
	int iCount = 0, iSize = 0;
	int bestWidth = 1000000;
	AM_MEDIA_TYPE *selectedMediaType = NULL;
	HRESULT hr;

	// iterate through all possible camera frame formats to find the best frame size
	hr = pCameraStream->GetNumberOfCapabilities(&iCount, &iSize);
	for (int i = 0; i < iCount; i++) {
		AM_MEDIA_TYPE *thisMediaType = NULL;
		VIDEO_STREAM_CONFIG_CAPS scc;
		hr = pCameraStream->GetStreamCaps(i, &thisMediaType, (BYTE*) &scc);
		if (SUCCEEDED(hr)) {
			if ((thisMediaType->majortype == MEDIATYPE_Video) &&
				(thisMediaType->formattype == FORMAT_VideoInfo) &&
				(thisMediaType->cbFormat >= sizeof (VIDEOINFOHEADER)) &&
				(thisMediaType->pbFormat != NULL))
			{
				VIDEOINFOHEADER* info = (VIDEOINFOHEADER*) thisMediaType->pbFormat;
				int thisWidth = info->bmiHeader.biWidth;
				if (abs(thisWidth - desiredWidth) < abs(bestWidth - desiredWidth)) {
					// select the format closest to the desired width
					if (!selectedMediaType) FreeMediaType(selectedMediaType);
					selectedMediaType = thisMediaType;
					bestWidth = thisWidth;
				}
			}

			// Delete the media type unless it's the selected one
			if (thisMediaType != selectedMediaType) FreeMediaType(thisMediaType);
			thisMediaType = NULL;
		}
	}

	// if we found a matching format, set the camera to that format
	if (selectedMediaType) {
		hr = pCameraStream->SetFormat(selectedMediaType);
		FreeMediaType(selectedMediaType);
	}
}

//////////////////////////////////////////////
// Debugging function
//////////////////////////////////////////////

void Msg(TCHAR *szFormat, ...)
{
	TCHAR szBuffer[1024];	// Large buffer for long filenames or URLs
	const size_t NUMCHARS = sizeof(szBuffer) / sizeof(szBuffer[0]);
	const int LASTCHAR = NUMCHARS - 1;

	// Format the input string
	va_list pArgs;
	va_start(pArgs, szFormat);

	// Use a bounded buffer size to prevent buffer overruns. Limit count to
	// character size minus one to allow for a NULL terminating character.
	_vsntprintf(szBuffer, NUMCHARS - 1, szFormat, pArgs);
	va_end(pArgs);

	// Ensure that the formatted string is NULL-terminated
	szBuffer[LASTCHAR] = TEXT('\0');

	MessageBox(NULL, szBuffer, TEXT("Debug"), 0);
}
