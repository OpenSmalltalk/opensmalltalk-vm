#include <Windows.h>

// I dunno why atlbase.h barfs when _UNCODE=1, but it does
#if _UNICODE
# define _UNICODE_WAS_SET 1
# undef _UNICODE
#else
# undef _UNICODE_WAS_SET
#endif

#include <atlbase.h>

#if _UNICODE_WAS_SET
# define _UNICODE 1
#endif

#include <dshow.h>
#include <stdio.h>
#include <qedit.h>

extern "C" {
#include "sq.h"
#include "CameraPlugin.h"

extern struct VirtualMachine *interpreterProxy;

static inline void
attemptToSignalSemaphoreOfCameraWithBuffer(BYTE *frameBuffer);

}

// N.B. This pretends to support multiple cameras but in fact only supports
// a single camera.  Volunteers are most welcome to correct this deficiency.
// You'll need a Windows box with multiple cameras to do so though.

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
		if (pFrameBuf) {
			delete [] pFrameBuf;
			pFrameBuf = NULL;
		}
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
		if (!pThisBuf || !lThisBufSize)
			return E_POINTER;

		// if the buffer sizes don't match, discard ours to force creating a new one
		if (lFrameBufSize != lThisBufSize) {
			delete [] pFrameBuf;
			pFrameBuf = NULL;
		}

		// if we haven't yet created the data buffer, do it now.
		if (!pFrameBuf) {
			pFrameBuf = new BYTE[lThisBufSize];
			lFrameBufSize = lThisBufSize;
			if (!pFrameBuf)
				lFrameBufSize = 0;
		}

		// Copy the bitmap data into our global buffer
		if (pFrameBuf) {
			memcpy(pFrameBuf, pThisBuf, lFrameBufSize);
			attemptToSignalSemaphoreOfCameraWithBuffer(pFrameBuf);
		}
		frameCount++;

		return 0;
	}
};

extern "C" {

//////////////////////////////////////////////
// Data
//////////////////////////////////////////////

typedef struct Camera {
	IBaseFilter				*pCamera;
	IGraphBuilder			*pGraph;
	ICaptureGraphBuilder2	*pCapture;
	IMediaControl			*pMediaControl;
	IBaseFilter				*ppf;
	ISampleGrabber			*pGrabber;
	CSampleGrabberCB		 mCB;
	int width;
	int height;
	int semaphoreIndex;
} Camera;

#if 1
# define CAMERA_COUNT 4
#else
# define CAMERA_COUNT 1
#endif
static Camera theCameras[CAMERA_COUNT];

//////////////////////////////////////////////
// Local functions and macros
//////////////////////////////////////////////

static Camera *ActiveCamera(int cameraNum);
static void SetClosestWidthAndFrameRate(IAMStreamConfig *pCameraStream, int desiredWidth);
static HRESULT FindCamera(IBaseFilter **ppSrcFilter, int num);
static void FreeMediaType(AM_MEDIA_TYPE *pMediaType);
static void FreeMediaTypeFields(AM_MEDIA_TYPE *pMediaType);
static char *GetCameraNameAndUID(int num, char **uidp);
static HRESULT InitCamera(int num, int desiredWidth);
static void SetCameraWidthAndFPS(ICaptureGraphBuilder2 *pCaptureGraphBuilder, IBaseFilter *pSrcFilter, int desiredWidth);
static void SetOutputToRGB(Camera *theCamera);
static void SetFramesPerSecond(int fps);

// pGrabber and pMediaControl appear to get overwritten in the non-debug VM
// so be very careful in calling release functions
#if BytesPerWord == 8
# define InRangePtr(p) (!((uintptr_t)(p) >> 56))
#else
# define InRangePtr(p) (!((uintptr_t)(p) >> 31))
#endif
#define SAFE_RELEASE(x) { if ((x) && InRangePtr(x)) (x)->Release(); (x) = NULL; }

//////////////////////////////////////////////
// Entry Points
//////////////////////////////////////////////

sqInt
CameraOpen(sqInt cameraNum, sqInt desiredWidth, sqInt desiredHeight)
{
	CameraClose(cameraNum);
	int hr = InitCamera(cameraNum, desiredWidth);
	return SUCCEEDED(hr);
}

void
CameraClose(sqInt cameraNum)
{
	Camera *theCamera;

	if (!(theCamera = ActiveCamera(cameraNum)))
		return;

	// stop getting video
	// pGrabber and pMediaControl appear to get overwritten in the non-debug VM
	// so be very careful in calling them
	if (InRangePtr(theCamera->pMediaControl))
		theCamera->pMediaControl->StopWhenReady();

	// release DirectShow objects
	SAFE_RELEASE(theCamera->pMediaControl);
	SAFE_RELEASE(theCamera->pGraph);
	SAFE_RELEASE(theCamera->pCapture);
	SAFE_RELEASE(theCamera->pGrabber);
	SAFE_RELEASE(theCamera->ppf);
	SAFE_RELEASE(theCamera->pCamera);
	theCamera->width = theCamera->height = theCamera->semaphoreIndex = 0;
}

sqInt
CameraExtent(sqInt cameraNum)
{
	Camera *theCamera;

	return (theCamera = ActiveCamera(cameraNum))
		? (theCamera->width << 16) + (theCamera->height & 0xFFFF)
		: 0;
}

sqInt
CameraGetFrame(sqInt cameraNum, unsigned char* buf, sqInt pixelCount)
{
	Camera *theCamera;

	if (!(theCamera = ActiveCamera(cameraNum)))
		return -1;

	int framesSinceLastCall = theCamera->mCB.frameCount;
	if (framesSinceLastCall == 0)
		return 0;  // no frame available
	theCamera->mCB.frameCount = 0;  // clear frame count

	if (pixelCount > (theCamera->mCB.lFrameBufSize / 3))
		pixelCount = (theCamera->mCB.lFrameBufSize / 3);

	// flip image vertically while copying to Squeak buf
	// N.B. For certain cameras this is unnecessary, see
	// https://social.msdn.microsoft.com/Forums/windowsdesktop/en-US/bee4f7c0-5938-43ce-9db5-59a60b5f80bb/flip-webcam-vertically?forum=windowsdirectshowdevelopment
	unsigned char *pSrc = theCamera->mCB.pFrameBuf;
	for (int w = theCamera->width, y = theCamera->height - 1; y >= 0; y--) {
		unsigned char *pDst = &buf[4 * y * w];
		for (int x = 0; x < w; x++) {
			*pDst++ = *pSrc++;		// red
			*pDst++ = *pSrc++;		// green
			*pDst++ = *pSrc++;		// blue
			*pDst++ = 255;			// alpha
		}
	}
	return framesSinceLastCall;
}

/* GetCameraNameAndUID mallocs one or two strings every call. This function
 * frees one of them later. The other is the responsibility of the caller.
 */
static char *storageleak = 0;
static inline void
mitigateleak(void)
{
	if (storageleak) {
		free(storageleak);
		storageleak = 0;
	}
}

char *
CameraName(sqInt cameraNum)
{
	mitigateleak();
	return cameraNum < 1 || cameraNum > CAMERA_COUNT
		? NULL
		: storageleak = GetCameraNameAndUID(cameraNum,0);
}

char *
CameraUID(sqInt cameraNum)
{
	char *uid = 0;

	mitigateleak();
	if (cameraNum < 1 || cameraNum > CAMERA_COUNT)
		return NULL;
	char *leak = GetCameraNameAndUID(cameraNum,&uid);
	if (leak) free(leak);
	return storageleak = uid;
}

sqInt
CameraGetSemaphore(sqInt cameraNum)
{
	Camera *theCamera;

	return  (theCamera = ActiveCamera(cameraNum))
		 && theCamera->semaphoreIndex > 0
		? theCamera->semaphoreIndex
		: 0;
}

sqInt
CameraSetSemaphore(sqInt cameraNum, sqInt semaphoreIndex)
{
	Camera *theCamera;

	if (!(theCamera = ActiveCamera(cameraNum)))
		return PrimErrNotFound;
	theCamera->semaphoreIndex = semaphoreIndex;
	return 0;
}

static inline void
attemptToSignalSemaphoreOfCameraWithBuffer(BYTE *frameBuffer)
{
	for (int i = 1, si = 0; i <= CAMERA_COUNT; i++)
		if (theCameras[i].mCB.pFrameBuf == frameBuffer) {
			if ((si = theCameras[i].semaphoreIndex) > 0)
				interpreterProxy->signalSemaphoreWithIndex(si);
			break;
		}
}

sqInt
CameraGetParam(sqInt cameraNum, sqInt paramNum)  // for debugging and testing
{
	Camera *theCamera;

	if (!(theCamera = ActiveCamera(cameraNum)))
		return -1;
	if (paramNum == 1)
		return theCamera->mCB.frameCount;
	if (paramNum == 2)
		return theCamera->mCB.lFrameBufSize;

	return -2;
}

//////////////////////////////////////////////
// Local functions
//////////////////////////////////////////////

static Camera *
ActiveCamera(int cameraNum)
{ return
	cameraNum >= 1 && cameraNum <= CAMERA_COUNT
	&& theCameras[cameraNum].pCamera
	&& theCameras[cameraNum].pGraph
		? &theCameras[cameraNum]
		: 0;
}

static HRESULT
FindCamera(IBaseFilter ** ppSrcFilter, int cameraNum)
{
	HRESULT hr;
	IBaseFilter *pSrc = NULL;
	CComPtr <IMoniker> pMoniker = NULL;
	ULONG cFetched;

	if (!ppSrcFilter)
		return E_POINTER;

	*ppSrcFilter = NULL;  // clear output in case we return early with an error

	// Create system device enumerator
	CComPtr <ICreateDevEnum> pDevEnum = NULL;
	hr = CoCreateInstance(
		CLSID_SystemDeviceEnum, NULL, CLSCTX_INPROC,
		IID_ICreateDevEnum, (void **) &pDevEnum);
	if (FAILED(hr))
		return hr;

	// Create enumerator for the video capture devices
	CComPtr <IEnumMoniker> pClassEnum = NULL;
	hr = pDevEnum->CreateClassEnumerator (CLSID_VideoInputDeviceCategory, &pClassEnum, 0);
	if (FAILED(hr))
		return hr;

	// If there are no enumerators for the requested type, then
	// CreateClassEnumerator will succeed, but pClassEnum will be NULL.
	if (pClassEnum == NULL)
		return E_FAIL;

	// Find the nth video capture device on the device list.
	// Note that if the Next() call succeeds but there are no monikers,
	// it will return S_FALSE (which is not a failure). Therefore, we
	// check that the return code is S_OK instead of using SUCCEEDED() macro
	for (int i = 1; i <= cameraNum; i++)
		if (S_OK != pClassEnum->Next (1, &pMoniker, &cFetched))
			return E_FAIL;

	// Bind Moniker to a filter object
	hr = pMoniker->BindToObject(0, 0, IID_IBaseFilter, (void**) &pSrc);
	if (FAILED(hr))
		return hr;

	// Copy the found filter pointer to the output parameter.
	// Do NOT Release() the reference, since it will still be used
	// by the calling function.
	*ppSrcFilter = pSrc;
	return hr;
}

static void
FreeMediaType(AM_MEDIA_TYPE *pMediaType)  // free fields and structure
{
	if (!pMediaType)
		return;
	FreeMediaTypeFields(pMediaType);
	CoTaskMemFree((void *) pMediaType);
}

static void
FreeMediaTypeFields(AM_MEDIA_TYPE *pMediaType)  // free format and pUnk fields
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

static char *
GetCameraNameAndUID(int requestedCameraNum, char **uidp)
{
	ICreateDevEnum *pDevEnum = NULL;
	IEnumMoniker *pClassEnum = NULL;
	IMoniker *pMoniker = NULL;
	IPropertyBag *pPropBag;
	VARIANT variant;
	HRESULT hr;
	char *result = NULL;
	int videoInputDeviceIndex = 0;

	// Create the system device enumerator
	hr = CoCreateInstance(CLSID_SystemDeviceEnum, NULL, CLSCTX_INPROC,
							IID_ICreateDevEnum, (void **)&pDevEnum);
	if (FAILED(hr))
		return NULL;

	// Create an enumerator for the video capture devices
	// If there are no enumerators for the requested type, then
	// CreateClassEnumerator will succeed, but pClassEnum will be NULL.
	hr = pDevEnum->CreateClassEnumerator(CLSID_VideoInputDeviceCategory, &pClassEnum, 0);
	if (FAILED(hr)
	 || !pClassEnum) {
		pDevEnum->Release();
		return NULL;
	}

	while (pClassEnum->Next(1, &pMoniker, NULL) == S_OK) {
		hr = pMoniker->BindToStorage(0, 0, IID_IPropertyBag, (void**)&pPropBag);
		if (FAILED(hr)) {
			pMoniker->Release();
			continue;  
		} 
		if (++videoInputDeviceIndex >= requestedCameraNum)
			break;

		pPropBag->Release();
		pMoniker->Release();
	}
	if (videoInputDeviceIndex == requestedCameraNum) {
		// Find the description or friendly name
		VariantInit(&variant);
		variant.vt = VT_BSTR;
		hr = pPropBag->Read(L"Description", &variant, 0);
		if (FAILED(hr))
			hr = pPropBag->Read(L"FriendlyName", &variant, 0);

		if (SUCCEEDED(hr)) {
			size_t n = SysStringLen(variant.bstrVal);
			result = (char *)malloc(n + 1);
			n = sprintf(result, "%S", variant.bstrVal);
			result[n] = 0;
			VariantClear(&variant);
		}
		/* If asked for the UID/DevicePath, answer it through uidp */
		VariantInit(&variant);
		variant.vt = VT_BSTR;
		if (result
		 && uidp
		 && SUCCEEDED(hr = pPropBag->Read(L"DevicePath", &variant, 0))) {
			size_t n = SysStringLen(variant.bstrVal);
			*uidp = (char *)malloc(n + 1);
			n = sprintf(*uidp, "%S", variant.bstrVal);
			(*uidp)[n] = 0;
			VariantClear(&variant);
		}
		pMoniker->Release();
		pPropBag->Release();
	}
	pDevEnum->Release();
	return result;
}

static HRESULT
InitCamera(int cameraNum, int desiredWidth)
{
	HRESULT hr;
	int maxFPS;
	Camera *theCamera = &theCameras[cameraNum];
	// get USB camera or other video capture device
	hr = FindCamera(&theCamera->pCamera, cameraNum);
	if (FAILED(hr))
		return hr;

	// create filter graph
	hr = CoCreateInstance (
		CLSID_FilterGraph, NULL, CLSCTX_INPROC,
		IID_IGraphBuilder, (void **) &theCamera->pGraph);
	if (FAILED(hr))
		return hr;

	// create capture graph builder
	hr = CoCreateInstance (
		CLSID_CaptureGraphBuilder2 , NULL, CLSCTX_INPROC,
		IID_ICaptureGraphBuilder2, (void **) &theCamera->pCapture);
	if (FAILED(hr))
		return hr;

	// get media control interface
	hr = theCamera->pGraph->QueryInterface(IID_IMediaControl,(LPVOID *) &theCamera->pMediaControl);
	if (FAILED(hr))
		return hr;

	// create SampleGrabber
	hr = CoCreateInstance(
		CLSID_SampleGrabber, NULL, CLSCTX_INPROC_SERVER,
		IID_IBaseFilter, (void**) &theCamera->ppf);
	if (FAILED(hr))
		return hr;

	theCamera->ppf->QueryInterface(IID_ISampleGrabber, (void**) &theCamera->pGrabber);

	// attach the filter graph to the capture graph
	hr = theCamera->pCapture->SetFiltergraph(theCamera->pGraph);
	if (FAILED(hr))
		return hr;

	hr = theCamera->pGraph->AddFilter(theCamera->ppf, L"Scratch Frame Grabber");
	if (FAILED(hr))
		return hr;

	// add the camera
	hr = theCamera->pGraph->AddFilter(theCamera->pCamera, L"Camera");
	if (FAILED(hr))
		return hr;

	// set the desired framesize and image format and framerate
	SetCameraWidthAndFPS(theCamera->pCapture, theCamera->pCamera, desiredWidth);
	SetOutputToRGB(theCamera);

	// connect the camera to the sample grabber, possibly inserting format conversion filters
	hr = theCamera->pCapture->RenderStream(
		&PIN_CATEGORY_CAPTURE, &MEDIATYPE_Video,
		theCamera->pCamera, NULL, theCamera->ppf);

	// record the actual camera frame dimensions
	AM_MEDIA_TYPE mt;
	hr = theCamera->pGrabber->GetConnectedMediaType(&mt);
	if (FAILED(hr))
		return hr;

	theCamera->width  = ((VIDEOINFOHEADER*) mt.pbFormat)->bmiHeader.biWidth;
	theCamera->height = ((VIDEOINFOHEADER*) mt.pbFormat)->bmiHeader.biHeight;
	theCamera->semaphoreIndex = -1;
	FreeMediaTypeFields(&mt);

	hr = theCamera->pGrabber->SetOneShot(FALSE);
	hr = theCamera->pGrabber->SetBufferSamples(FALSE);
	hr = theCamera->pGrabber->SetCallback(&theCamera->mCB, 1);

	// start getting video
	hr = theCamera->pMediaControl->Run();
	if (FAILED(hr))
		return hr;

	return S_OK;
}

static void
SetOutputToRGB(Camera *theCamera)
{
	AM_MEDIA_TYPE mediaType;
	mediaType.majortype = MEDIATYPE_Video;
	mediaType.subtype = MEDIASUBTYPE_RGB24;
	mediaType.formattype = GUID_NULL;
	mediaType.pbFormat = NULL;
	mediaType.cbFormat = 0;
	theCamera->pGrabber->SetMediaType(&mediaType);
}

static void
SetCameraWidthAndFPS(ICaptureGraphBuilder2 *pCaptureGraphBuilder, IBaseFilter *pSrcFilter, int desiredWidth)
{
	IAMStreamConfig *pCameraStream = NULL;
	HRESULT hr;

	// get the stream configuration interface
	hr = pCaptureGraphBuilder->FindInterface(
		&PIN_CATEGORY_CAPTURE, 0, pSrcFilter,
		IID_IAMStreamConfig, (void**) &pCameraStream);
	if (FAILED(hr))
		return;

	SetClosestWidthAndFrameRate(pCameraStream, desiredWidth);

	SAFE_RELEASE(pCameraStream);
}

static void
SetClosestWidthAndFrameRate(IAMStreamConfig *pCameraStream, int desiredWidth)
{
	int iCount = 0, iSize = 0;
	int bestWidth = 1000000;
	AM_MEDIA_TYPE *selectedMediaType = NULL;
	HRESULT hr;
	LONGLONG minInterval, maxInterval;

	// iterate through all possible camera frame formats to find the best frame size
	hr = pCameraStream->GetNumberOfCapabilities(&iCount, &iSize);
	for (int i = 0; i < iCount; i++) {
		AM_MEDIA_TYPE *thisMediaType = NULL;
		VIDEO_STREAM_CONFIG_CAPS scc;
		hr = pCameraStream->GetStreamCaps(i, &thisMediaType, (BYTE*) &scc);
		if (SUCCEEDED(hr)) {
			if (thisMediaType->majortype == MEDIATYPE_Video
			 && thisMediaType->formattype == FORMAT_VideoInfo
			 && thisMediaType->cbFormat >= sizeof(VIDEOINFOHEADER)
			 && thisMediaType->pbFormat != NULL)
			{
				VIDEOINFOHEADER* info = (VIDEOINFOHEADER*) thisMediaType->pbFormat;
				int thisWidth = info->bmiHeader.biWidth;
				if (abs(thisWidth - desiredWidth) < abs(bestWidth - desiredWidth)) {
					// select the format closest to the desired width
					if (!selectedMediaType)
						FreeMediaType(selectedMediaType);
					selectedMediaType = thisMediaType;
					bestWidth = thisWidth;
					minInterval = scc.MinFrameInterval;
					maxInterval = scc.MaxFrameInterval;
				}
			}

			// Delete the media type unless it's the selected one
			if (thisMediaType != selectedMediaType)
				FreeMediaType(thisMediaType);
			thisMediaType = NULL;
		}
	}

	// if we found a matching format, set the camera to that format
	if (selectedMediaType) {
		// Limit the frame rate to 30 frames per second
		// Perverse, but the VIDEO_STREAM_CONFIG_CAPS contains the
		// minimum and maximum frame durations (and in 100 nsec units).
		LONGLONG thirtyFPS = 10ULL * 1000 * 1000 / 30ULL;
		((VIDEOINFOHEADER*) selectedMediaType->pbFormat)->AvgTimePerFrame
			= max(thirtyFPS,minInterval);
		hr = pCameraStream->SetFormat(selectedMediaType);
		FreeMediaType(selectedMediaType);
	}
}

sqInt
cameraInit(void) { return 1; }

sqInt
cameraShutdown(void)
{
	mitigateleak();
	for (int cameraNum = 1; cameraNum <= CAMERA_COUNT; cameraNum++)
		(void)CameraClose(cameraNum);
	return 1;
}
} // extern "C"

#if defined(PRINT_DEVICES_PROGRAM)
extern "C" {

struct VirtualMachine *interpreterProxy;

HRESULT
EnumerateDevices(REFGUID category, IEnumMoniker **ppEnum)
{
	// Create the System Device Enumerator.
	ICreateDevEnum *pDevEnum;
	HRESULT hr = CoCreateInstance(CLSID_SystemDeviceEnum, NULL,  
		CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&pDevEnum));

	if (SUCCEEDED(hr)) {
		// Create an enumerator for the category.
		hr = pDevEnum->CreateClassEnumerator(category, ppEnum, 0);
		if (hr == S_FALSE) {
			hr = VFW_E_NOT_FOUND;  // The category is empty. Treat as an error.
		}
		pDevEnum->Release();
	}
	return hr;
}

void
DisplayDeviceInformation(IEnumMoniker *pEnum)
{
	IMoniker *pMoniker = NULL;
	int count = 0, ok_count = 0;

	while (pEnum->Next(1, &pMoniker, NULL) == S_OK) {
		IPropertyBag *pPropBag;
		HRESULT hr = pMoniker->BindToStorage(0, 0, IID_PPV_ARGS(&pPropBag));
		count += 1;
		if (FAILED(hr)) {
			pMoniker->Release();
			continue;  
		} 
		ok_count += 1;

		VARIANT var;
		VariantInit(&var);

		// Get description or friendly name.
		hr = pPropBag->Read(L"Description", &var, 0);
		if (SUCCEEDED(hr)) {
			printf("Description: %S (%d,%d)\n", var.bstrVal, count, ok_count);
			VariantClear(&var); 
		}
		hr = pPropBag->Read(L"FriendlyName", &var, 0);
		if (SUCCEEDED(hr)) {
			printf("FriendlyName %S (%d,%d)\n", var.bstrVal, count, ok_count);
			VariantClear(&var); 
		}

		hr = pPropBag->Write(L"FriendlyName", &var);

		// WaveInID applies only to audio capture devices.
		hr = pPropBag->Read(L"WaveInID", &var, 0);
		if (SUCCEEDED(hr)) {
			printf("WaveIn ID: %d\n", var.lVal);
			VariantClear(&var); 
		}

		hr = pPropBag->Read(L"DevicePath", &var, 0);
		if (SUCCEEDED(hr)) {
			// The device path is not intended for display.
			printf("Device path: %S\n", var.bstrVal);
			VariantClear(&var); 
		}

		pPropBag->Release();
		pMoniker->Release();
	}
}

int
main()
{
	HRESULT hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
	if (SUCCEEDED(hr)) {
		IEnumMoniker *pEnum;

		hr = EnumerateDevices(CLSID_VideoInputDeviceCategory, &pEnum);
		if (SUCCEEDED(hr)) {
			DisplayDeviceInformation(pEnum);
			pEnum->Release();
		}
		hr = EnumerateDevices(CLSID_AudioInputDeviceCategory, &pEnum);
		if (SUCCEEDED(hr)) {
			DisplayDeviceInformation(pEnum);
			pEnum->Release();
		}
		CoUninitialize();
	}
	return 0;
}
}
#endif // PRINT_DEVICES_PROGRAM
