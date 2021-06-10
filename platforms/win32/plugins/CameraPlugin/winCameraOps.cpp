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
# undef _UNICODE
# define _UNICODE 1
#endif

#include <dshow.h>
#include <stdio.h>
#include <qedit.h>

extern "C" {
#include "sqVirtualMachine.h"
#include "sqMemoryFence.h"
#include "CameraPlugin.h"

extern struct VirtualMachine *interpreterProxy;

static inline void *
forwardDeclarationHack (struct Camera *aCamera, long lThisBufferSize,
						int *widthp, int *heightp, int *semaphoreIndexp,
						char *errorCodep, char *alreadyErrorp);
static inline void
setErrorCode(struct Camera *aCamera, char errorCode);
}

#define FLIP_IN_CAPTURE 1

class CSampleGrabberCB : public ISampleGrabberCB {
public:
	struct Camera *myCamera;
	BYTE  		  *pFrameBuf;
	long   lFrameBufSize;	// size of pFrameBuf in bytes
	int    frameCount;		// number of frames received since last GetFrame() call

	// fake out any COM ref counting
	STDMETHODIMP_(ULONG) AddRef() { return 2; }
	STDMETHODIMP_(ULONG) Release()
	{
		frameCount = 0;
		lFrameBufSize = 0;
		if (pFrameBuf) {
			delete [] pFrameBuf;
			pFrameBuf = nullptr;
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
		void *theBuffer;
		char alreadyHaveErrorCondition = 0, errorCode = 0;
		int semaphoreIndex;
		int width, height;
		int pixelBytes = (lThisBufSize / 3) * 4;

		if (!pThisBuf || !lThisBufSize)
			return E_POINTER;

		theBuffer = forwardDeclarationHack (myCamera,
											pixelBytes,
											&width, &height,
											&semaphoreIndex,
											&errorCode,
											&alreadyHaveErrorCondition);
		if (!theBuffer && !errorCode) {
			// No synchronization with CameraSetFrameBuffers et al.
			// We assume this is in a higher-priority thread than Smalltalk.
			if (pFrameBuf
			 && pixelBytes > lFrameBufSize) {
				delete [] pFrameBuf;
				pFrameBuf = nullptr;
			}
			if (!pFrameBuf) {
				pFrameBuf = new BYTE[pixelBytes];
				lFrameBufSize = pixelBytes;
				if (!pFrameBuf) {
					lFrameBufSize = 0;
					setErrorCode(myCamera,PrimErrNoCMemory);
				}
			}
			theBuffer = pFrameBuf;
		}

		// Copy the bitmap data into the chosen buffer
		if (!errorCode && theBuffer) {
#if FLIP_IN_CAPTURE
	// flip image vertically while copying to buffer
	// N.B. For certain cameras this is unnecessary, see
	// https://social.msdn.microsoft.com/Forums/windowsdesktop/en-US/bee4f7c0-5938-43ce-9db5-59a60b5f80bb/flip-webcam-vertically?forum=windowsdirectshowdevelopment
			unsigned char *pSrc = pThisBuf;
			for (int y = height - 1; y >= 0; y--) {
				unsigned char *pDst = (unsigned char *)theBuffer + (4 * y * width);
				int x = 0;
				while (++x <= width) {
					pDst[0] = pSrc[0];	// red
					pDst[1] = pSrc[1];	// green
					pDst[2] = pSrc[2];	// blue
					pDst[3] = 255;		// alpha
					pDst += 4;
					pSrc += 3;
				}
			}
#else
			memcpy(theBuffer, pThisBuf, lThisBufSize);
#endif
		}
		++frameCount;
		if (!alreadyHaveErrorCondition && semaphoreIndex > 0)
			interpreterProxy->signalSemaphoreWithIndex(semaphoreIndex);
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
#if 0
	IAMVideoControl			*pVideoControl;
#endif
	IBaseFilter				*ppf;
	ISampleGrabber			*pGrabber;
	CSampleGrabberCB		 mCB;
	void *					bufferAOrNil;
	void *					bufferBOrNil;
	sqInt					bufferSize;
	int width;
	int height;
	int semaphoreIndex;
	char					useBNotA;
	char					errorCode;
} Camera;

#define CAMERA_COUNT 4
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
#define SAFE_RELEASE(x) { if ((x) && InRangePtr(x)) (x)->Release(); (x) = nullptr; }

/* Answer the buffer to use if the camera has a pinned object frame buffer,
 * or nil. Load other usefu variables. This is a hack to get around Camera
 * and CSampleGrabberCB needing to know about each other.
 */
static inline void *
forwardDeclarationHack (struct Camera *aCamera, long lThisBufferSize,
						int *widthp, int *heightp, int *semaphoreIndexp,
						char *errorCodep, char *alreadyErrorp)
{
	void *theBuffer;

	if (aCamera->errorCode)
		*alreadyErrorp = 1;
	*widthp = aCamera->width;
	*heightp = aCamera->height;
	*semaphoreIndexp = aCamera->semaphoreIndex;

	if (!aCamera->bufferAOrNil)
		return 0;

	if (aCamera->bufferBOrNil) {
		theBuffer = aCamera->useBNotA
						? aCamera->bufferBOrNil
						: aCamera->bufferAOrNil;
		aCamera->useBNotA = !aCamera->useBNotA;
	}
	else
		theBuffer = aCamera->bufferAOrNil;
	if (lThisBufferSize > aCamera->bufferSize) {
		*errorCodep = aCamera->errorCode = PrimErrWritePastObject;
		return 0;
	}
	return theBuffer;
}

static inline void
setErrorCode(struct Camera *aCamera, char ec) { aCamera->errorCode = ec; }

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
	theCamera->bufferAOrNil = 0;
	theCamera->bufferBOrNil = 0;
	theCamera->bufferSize = 0;
	theCamera->width = 0;
	theCamera->height = 0;
	theCamera->semaphoreIndex = 0;
	theCamera->useBNotA = 0;
	theCamera->errorCode = 0;
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
CameraGetFrame(sqInt cameraNum, unsigned char *buf, sqInt pixelCount)
{
	Camera *camera;

	if (!(camera = ActiveCamera(cameraNum)))
		return -1;

	if (camera->errorCode) {
		int theCode = camera->errorCode;
		camera->errorCode = 0;
		return -theCode;
	}
	int framesSinceLastCall = camera->mCB.frameCount;
	if (framesSinceLastCall == 0)
		return 0;  // no frame available
	camera->mCB.frameCount = 0;  // clear frame count

	if (camera->bufferAOrNil)
		return framesSinceLastCall;

#if FLIP_IN_CAPTURE
	if (pixelCount > (camera->mCB.lFrameBufSize / 4))
		pixelCount = camera->mCB.lFrameBufSize / 4;

	memcpy(buf, camera->mCB.pFrameBuf, pixelCount * 4);
#else
	if (pixelCount > (camera->mCB.lFrameBufSize / 3))
		pixelCount = camera->mCB.lFrameBufSize / 3;

	// flip image vertically while copying to Squeak buf
	// N.B. For certain cameras this is unnecessary, see
	// https://social.msdn.microsoft.com/Forums/windowsdesktop/en-US/bee4f7c0-5938-43ce-9db5-59a60b5f80bb/flip-webcam-vertically?forum=windowsdirectshowdevelopment
	unsigned char *pSrc = camera->mCB.pFrameBuf;
	for (int w = camera->width, y = camera->height - 1; y >= 0; y--) {
		unsigned char *pDst = &buf[4 * y * w];
		for (int x = 0; x < w; x++) {
			pDst[0] = pSrc[0];	// red
			pDst[1] = pSrc[1];	// green
			pDst[2] = pSrc[2];	// blue
			pDst[3] = 255;		// alpha
			pDst += 4;
			pSrc += 3;
		}
	}
#endif
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
		return nullptr;
	char *leak = GetCameraNameAndUID(cameraNum,&uid);
	if (leak) free(leak);
	return storageleak = uid;
}

sqInt
CameraGetSemaphore(sqInt cameraNum)
{
	Camera *camera;

	return  (camera = ActiveCamera(cameraNum))
		 && camera->semaphoreIndex > 0
		? camera->semaphoreIndex
		: 0;
}

// primSetCameraBuffers ensures buffers are pinned non-pointer objs if non-null
sqInt
CameraSetFrameBuffers(sqInt cameraNum, sqInt bufferA, sqInt bufferB)
{
	Camera *camera;

  if (!(camera = ActiveCamera(cameraNum)))
	return PrimErrNotFound;

  sqInt byteSize = interpreterProxy->byteSizeOf(bufferA);

  if (bufferB
   && byteSize != interpreterProxy->byteSizeOf(bufferB))
	return PrimErrInappropriate;

  if (camera->width * camera->height * 4 > byteSize)
	return PrimErrWritePastObject;

  camera->bufferAOrNil = interpreterProxy->firstIndexableField(bufferA);
  camera->bufferBOrNil = bufferB
						? interpreterProxy->firstIndexableField(bufferB)
						: nullptr;
  camera->bufferSize = byteSize;
  sqLowLevelMFence();
  // Need to free pixels carefully since camera may be running.
  if (camera->mCB.pFrameBuf) {
	BYTE *the_pixels = camera->mCB.pFrameBuf;
	camera->mCB.pFrameBuf = nullptr;
	camera->mCB.lFrameBufSize = 0;
	sqLowLevelMFence();
	delete [] camera->mCB.pFrameBuf;
  }
  return 0;
}

sqInt
CameraSetSemaphore(sqInt cameraNum, sqInt semaphoreIndex)
{
	Camera *camera;

	if (!(camera = ActiveCamera(cameraNum)))
		return PrimErrNotFound;
	camera->semaphoreIndex = (int)semaphoreIndex;
	return 0;
}

sqInt
CameraGetParam(sqInt cameraNum, sqInt paramNum)  // for debugging and testing
{
	Camera *camera;

	if (!(camera = ActiveCamera(cameraNum)))
		return -1;
	if (paramNum == 1)
		return camera->mCB.frameCount;
	if (paramNum == 2)
		return camera->mCB.lFrameBufSize;
#if 0
	/* Negative values are platform specific info */
	if (paramNum == -2) {
		long capsFlags = 0;
		camera->pVideoControl->GetCaps(camera->pVideoControl, &capsFlags);
		return capsFlags;
	}
#endif

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
	IBaseFilter *pSrc = nullptr;
	CComPtr <IMoniker> pMoniker = nullptr;
	ULONG cFetched;

	if (!ppSrcFilter)
		return E_POINTER;

	*ppSrcFilter = nullptr;  // clear output in case we return early with an error

	// Create system device enumerator
	CComPtr <ICreateDevEnum> pDevEnum = nullptr;
	hr = CoCreateInstance(
		CLSID_SystemDeviceEnum, nullptr, CLSCTX_INPROC,
		IID_ICreateDevEnum, (void **) &pDevEnum);
	if (FAILED(hr))
		return hr;

	// Create enumerator for the video capture devices
	CComPtr <IEnumMoniker> pClassEnum = nullptr;
	hr = pDevEnum->CreateClassEnumerator (CLSID_VideoInputDeviceCategory, &pClassEnum, 0);
	if (FAILED(hr))
		return hr;

	// If there are no enumerators for the requested type, then
	// CreateClassEnumerator will succeed, but pClassEnum will be NULL.
	if (pClassEnum == nullptr)
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
		pMediaType->pbFormat = nullptr;
	}
	if (pMediaType->pUnk != nullptr) {
		// pUnk should be unused, but this is safest
		pMediaType->pUnk->Release();
		pMediaType->pUnk = nullptr;
	}
}

static char *
GetCameraNameAndUID(int requestedCameraNum, char **uidp)
{
	ICreateDevEnum *pDevEnum = nullptr;
	IEnumMoniker *pClassEnum = nullptr;
	IMoniker *pMoniker = nullptr;
	IPropertyBag *pPropBag;
	VARIANT variant;
	HRESULT hr;
	char *result = nullptr;
	int videoInputDeviceIndex = 0;

	// Create the system device enumerator
	hr = CoCreateInstance(CLSID_SystemDeviceEnum, nullptr, CLSCTX_INPROC,
							IID_ICreateDevEnum, (void **)&pDevEnum);
	if (FAILED(hr))
		return nullptr;

	// Create an enumerator for the video capture devices
	// If there are no enumerators for the requested type, then
	// CreateClassEnumerator will succeed, but pClassEnum will be NULL.
	hr = pDevEnum->CreateClassEnumerator(CLSID_VideoInputDeviceCategory, &pClassEnum, 0);
	if (FAILED(hr)
	 || !pClassEnum) {
		pDevEnum->Release();
		return nullptr;
	}

	while (pClassEnum->Next(1, &pMoniker, nullptr) == S_OK) {
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
	Camera *camera = &theCameras[cameraNum];
	// get USB camera or other video capture device
	hr = FindCamera(&camera->pCamera, cameraNum);
	if (FAILED(hr))
		return hr;

	// create filter graph
	hr = CoCreateInstance (
		CLSID_FilterGraph, nullptr, CLSCTX_INPROC,
		IID_IGraphBuilder, (void **) &camera->pGraph);
	if (FAILED(hr))
		return hr;

	// create capture graph builder
	hr = CoCreateInstance (
		CLSID_CaptureGraphBuilder2 , nullptr, CLSCTX_INPROC,
		IID_ICaptureGraphBuilder2, (void **) &camera->pCapture);
	if (FAILED(hr))
		return hr;

	// get media control interface
	hr = camera->pGraph->QueryInterface(IID_IMediaControl,(LPVOID *) &camera->pMediaControl);
	if (FAILED(hr))
		return hr;

#if 0
	// get media control interface
	hr = camera->pGraph->QueryInterface(IID_IAMVideoControl,(LPVOID *) &camera->pVideoControl);
	if (FAILED(hr))
		return hr;
#endif

	// create SampleGrabber
	hr = CoCreateInstance(
		CLSID_SampleGrabber, nullptr, CLSCTX_INPROC_SERVER,
		IID_IBaseFilter, (void**) &camera->ppf);
	if (FAILED(hr))
		return hr;

	camera->ppf->QueryInterface(IID_ISampleGrabber, (void**) &camera->pGrabber);

	// attach the filter graph to the capture graph
	hr = camera->pCapture->SetFiltergraph(camera->pGraph);
	if (FAILED(hr))
		return hr;

	hr = camera->pGraph->AddFilter(camera->ppf, L"Scratch Frame Grabber");
	if (FAILED(hr))
		return hr;

	// add the camera
	hr = camera->pGraph->AddFilter(camera->pCamera, L"Camera");
	if (FAILED(hr))
		return hr;

	// set the desired framesize and image format and framerate
	SetCameraWidthAndFPS(camera->pCapture, camera->pCamera, desiredWidth);
	SetOutputToRGB(camera);

	// connect the camera to the sample grabber, possibly inserting format conversion filters
	hr = camera->pCapture->RenderStream(
		&PIN_CATEGORY_CAPTURE, &MEDIATYPE_Video,
		camera->pCamera, nullptr, camera->ppf);

	// record the actual camera frame dimensions
	AM_MEDIA_TYPE mt;
	hr = camera->pGrabber->GetConnectedMediaType(&mt);
	if (FAILED(hr))
		return hr;

	camera->width  = ((VIDEOINFOHEADER*) mt.pbFormat)->bmiHeader.biWidth;
	camera->height = ((VIDEOINFOHEADER*) mt.pbFormat)->bmiHeader.biHeight;
	camera->semaphoreIndex = -1;
	FreeMediaTypeFields(&mt);

	hr = camera->pGrabber->SetOneShot(FALSE);
	hr = camera->pGrabber->SetBufferSamples(FALSE);
	hr = camera->pGrabber->SetCallback(&camera->mCB, 1);

	// start getting video
	hr = camera->pMediaControl->Run();
	if (FAILED(hr))
		return hr;

	camera->mCB.myCamera = camera;
	return S_OK;
}

static void
SetOutputToRGB(Camera *camera)
{
	AM_MEDIA_TYPE mediaType;
	mediaType.majortype = MEDIATYPE_Video;
	mediaType.subtype = MEDIASUBTYPE_RGB24;
	mediaType.formattype = GUID_NULL;
	mediaType.pbFormat = nullptr;
	mediaType.cbFormat = 0;
	camera->pGrabber->SetMediaType(&mediaType);
}

static void
SetCameraWidthAndFPS(ICaptureGraphBuilder2 *pCaptureGraphBuilder, IBaseFilter *pSrcFilter, int desiredWidth)
{
	IAMStreamConfig *pCameraStream = nullptr;
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
	int bestWidth = INT_MAX;
	AM_MEDIA_TYPE *selectedMediaType = nullptr;
	HRESULT hr;
	__int64 minInterval, maxInterval;

	// If desiredWidth = 0 answer largest (default?)
	if (!desiredWidth)
		desiredWidth = INT_MAX;

	// iterate through all possible camera frame formats to find the best frame size
	hr = pCameraStream->GetNumberOfCapabilities(&iCount, &iSize);
	for (int i = 0; i < iCount; i++) {
		AM_MEDIA_TYPE *thisMediaType = nullptr;
		VIDEO_STREAM_CONFIG_CAPS scc;
		hr = pCameraStream->GetStreamCaps(i, &thisMediaType, (BYTE*) &scc);
		if (SUCCEEDED(hr)) {
			if (thisMediaType->majortype == MEDIATYPE_Video
			 && thisMediaType->formattype == FORMAT_VideoInfo
			 && thisMediaType->cbFormat >= sizeof(VIDEOINFOHEADER)
			 && thisMediaType->pbFormat != nullptr)
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
			thisMediaType = nullptr;
		}
	}

	// if we found a matching format, set the camera to that format
	if (selectedMediaType) {
		// Limit the frame rate to 30 frames per second
		// Perverse, but the VIDEO_STREAM_CONFIG_CAPS contains the
		// minimum and maximum frame durations (and in 100 nsec units).
		__int64 thirtyFPS = 10ULL * 1000 * 1000 / 30ULL;
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
	HRESULT hr = CoCreateInstance(CLSID_SystemDeviceEnum, nullptr,  
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
	IMoniker *pMoniker = nullptr;
	int count = 0, ok_count = 0;

	while (pEnum->Next(1, &pMoniker, nullptr) == S_OK) {
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
	HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
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
