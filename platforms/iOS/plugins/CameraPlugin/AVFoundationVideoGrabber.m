/*
 *  AVFoundationVideoGrabber.mm
 *  Written by Yoshiki Ohshima
 *  Most of code was taken from OpenFrameworks at
 *  https://github.com/openframeworks/openFrameworks/blob/master/addons/ofxiOS/src/video/AVFoundationVideoGrabber.mm
 *  which is released under the MIT license.  Subsequently, this code is also under the MIT license.
 *
 * See https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app
 * Implementaion node:
 * variable cameraNum is 1-based in following code in order to fit Smalltalk expectations
 */

#include "sqVirtualMachine.h"
#include "sqMemoryFence.h"
#include "CameraPlugin.h"
extern struct VirtualMachine *interpreterProxy;

#include <TargetConditionals.h>

#include <Cocoa/Cocoa.h>
#include <AVFoundation/AVFoundation.h>
#include <AVFoundation/AVCaptureDevice.h>

// dispatch_release will only compile if macosx-version-min<=10.7
#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1080
# undef dispatch_release
# define dispatch_release(shunned) 0
#endif

#if defined(MAC_OS_X_VERSION_10_14)
static unsigned char canAccessCamera = false;
static unsigned char askedToAccessCamera = false;

static void
askToAccessCamera()
{
  askedToAccessCamera = true;
  if (@available(macOS 10.14, *)) {
	// Request permission to access the camera.
	// This API is only available in the 10.14 SDK and subsequent.
	switch ([AVCaptureDevice authorizationStatusForMediaType: AVMediaTypeVideo]) {
		case AVAuthorizationStatusAuthorized:
			// The user has previously granted access to the camera.
			canAccessCamera = true;
			return;
		case AVAuthorizationStatusNotDetermined: {
			// The app hasn't yet asked the user for camera access.
			__block BOOL gotResponse = false;
			const struct timespec rqt = {0,100000000}; // 1/10th sec
			[AVCaptureDevice
				requestAccessForMediaType: AVMediaTypeVideo
				completionHandler: ^(BOOL granted) {
										gotResponse = true;
										canAccessCamera = granted;
									}];
			while (!gotResponse)
				nanosleep(&rqt,0);
			return;
		}
		case AVAuthorizationStatusDenied:
			// The user has previously denied access.
			// One would hope one could to ask again; max once per run.
			// But at least in MacOS X 11.1 one cannot ask again; the request to ask
			// send (requestAccessForMediaType:completionHandler:) is ignored.
		case AVAuthorizationStatusRestricted:
			// The user can't grant access due to restrictions.
			canAccessCamera = false;
	}
  }
  else
	canAccessCamera = true;
}
#endif

static __inline bool
ensureCameraAccess()
{
#if defined(MAC_OS_X_VERSION_10_14)
	if (!askedToAccessCamera)
		askToAccessCamera();
	if (!canAccessCamera)
		interpreterProxy->primitiveFailFor(PrimErrInappropriate);
	return canAccessCamera;
#else
	return true;
#endif
}

void printDevices();

@interface SqueakVideoGrabber : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
{
  @public
  AVCaptureDeviceInput		*captureInput;
  AVCaptureVideoDataOutput	*captureOutput;
  AVCaptureDevice			*device;
  AVCaptureSession			*captureSession;
  dispatch_queue_t			 queue;
  unsigned int				*pixels;
  int						 pixelsByteSize;
  void						*bufferAOrNil;
  void						*bufferBOrNil;
  sqInt						 bufferSize;
  sqInt						 frameCount;
  int						 deviceID;
  int						 width;
  int						 height;
  int						 semaphoreIndex;
  unsigned char				 errorCode;
  unsigned char				 bInitCalled;
  unsigned char				 useBNotA;
}
@end

@interface SqueakVideoGrabber() <AVCaptureVideoDataOutputSampleBufferDelegate> {
}
@end

#define CAMERA_COUNT 4

SqueakVideoGrabber *grabbers[CAMERA_COUNT];

@implementation SqueakVideoGrabber

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
  didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
  fromConnection:(AVCaptureConnection *)connection
{
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	int currentWidth = CVPixelBufferGetWidth(imageBuffer);
	int currentHeight = CVPixelBufferGetHeight(imageBuffer);
	void *theBuffer;
	int alreadyHaveErrorCondition = errorCode;

	width = currentWidth;
	height = currentHeight;
	if (bufferAOrNil) {
		if (bufferBOrNil) {
			theBuffer = useBNotA
							? bufferBOrNil
							: bufferAOrNil;
			useBNotA = !useBNotA;
		}
		else
			theBuffer = bufferAOrNil;
		if (currentWidth * currentHeight * 4 > bufferSize)
			errorCode = PrimErrWritePastObject;
	}
	else {
		// No synchronization with CameraSetFrameBuffers et al.
		// We assume this is in a higher-priority thread than Smalltalk.
		if (pixels
		 && currentWidth * currentHeight * 4 > pixelsByteSize) {
			free(pixels);
			pixels = 0;
		}
		if (!pixels) {
			pixels = malloc(pixelsByteSize = currentWidth * currentHeight * 4);
			if (!pixels) {
				pixelsByteSize = 0;
				errorCode = PrimErrNoCMemory;
			}
		}
		theBuffer = pixels;
	}
	if (!errorCode) {
		CVPixelBufferLockBaseAddress(imageBuffer, 0);
		memcpy(	theBuffer,
				CVPixelBufferGetBaseAddress(imageBuffer),
				currentWidth * currentHeight * 4);
		CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	}
	frameCount++;
	if (semaphoreIndex > 0 && !alreadyHaveErrorCondition)
		interpreterProxy->signalSemaphoreWithIndex(semaphoreIndex);
}

// If desiredWidth == 0 && desiredHeight == 0 then initialize
// with highest available resolution.
-(SqueakVideoGrabber*)initCapture:(int)deviceNum
      desiredWidth:(int)desiredWidth 
      desiredHeight:(int)desiredHeight
{
	NSArray *devices = [[AVCaptureDevice devices] filteredArrayUsingPredicate:
     [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return [object hasMediaType: AVMediaTypeVideo] || [object hasMediaType: AVMediaTypeMuxed];
    }]];

  // NSLog(@"devices count %d\n", [devices count]);
  if ([devices count] == 0)
    return NULL;

  deviceID = deviceNum > ([devices count] - 1)
				? ([devices count] - 1)
				: deviceNum;
  device = [devices objectAtIndex: deviceID];

  // printDevices();
  // NSLog(@"device %@\n", device);

  NSError *error = nil;

  // We setup the input
  captureInput = [AVCaptureDeviceInput deviceInputWithDevice: device error:&error];
  if (error) {
      NSLog(@"deviceInputWithDevice failed with error %@", [error localizedDescription]);
      return NULL;
  }
  // We setup the output
  captureOutput = [[AVCaptureVideoDataOutput alloc] init];
  // While a frame is processed in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
  // If you don't want this behaviour set the property to NO
  captureOutput.alwaysDiscardsLateVideoFrames = YES;

  // NSLog(@"capture: %@, %@\n", captureInput, captureOutput);

  // We create a serial queue to handle the processing of our frames
  queue = dispatch_queue_create("cameraQueue", DISPATCH_QUEUE_SERIAL);
  [captureOutput setSampleBufferDelegate: self queue:queue];
#ifndef IOS
#define IOS 0
#endif
#if IOS
  dispatch_release(queue);
#endif

  // And we create a capture session
  if (captureSession)
    captureSession = NULL;
  captureSession = [[AVCaptureSession alloc] init];
#if IOS
  [captureSession autorelease];
#endif
  [captureSession beginConfiguration]; 
  NSString *preset = NULL, *bestPreset = NULL, *bestPresetBelow = NULL;
  int bestWidthBelow = 0, bestHeightBelow = 0;
  int bestWidth = INT_MAX / 2, bestHeight = INT_MAX / 2;

	// Choose the configuration. If there is an exact match, choose that.
	// Otherwise choose the closest less than or equal to the desired size.
	// If desiredWidth is zero and desiredHeight is zero, select the default
	// (the largest available). Because smaller sizes may be unavailable, also
	// find the best fit if no size smaller than the requested is available.

#define USEPRESETFOR(p, w, h, h2) \
  if ([captureSession canSetSessionPreset: p]) { \
	if (desiredWidth == w && (desiredHeight == h || desiredHeight == h2)) { \
	  preset = p; \
	  width = desiredWidth; \
	  height = desiredHeight; \
	} \
	else if (!preset) { \
		if (desiredWidth) { \
			if (abs(desiredWidth - w) < abs(desiredWidth - bestWidth)) { \
				bestPreset = p; \
				bestWidth = w; \
				bestHeight = h; \
			} \
			if (desiredWidth <= w && w > bestWidthBelow \
			 && (desiredHeight <= h || desiredHeight <= h2)) { \
				bestPresetBelow = p; \
				bestWidthBelow = w; \
				bestHeightBelow = h; \
			} \
		} \
		else if (desiredHeight) { \
			if (abs(desiredHeight - h) < abs(desiredHeight - bestHeight)) { \
				bestPreset = p; \
				bestWidth = w; \
				bestHeight = h; \
			} \
			if (desiredWidth <= w) { \
				if (desiredHeight <= h && h > bestHeightBelow) { \
					bestPresetBelow = p; \
					bestWidthBelow = w; \
					bestHeightBelow = h; \
				} \
				else if (desiredHeight <= h2 && h2 > bestHeightBelow) { \
					bestPresetBelow = p; \
					bestWidthBelow = w; \
					bestHeightBelow = h2; \
				} \
			} \
		} \
		else { \
			preset = p; \
			width = w; \
			height = h; \
		} \
	} \
  }

  width = height = 0;
//USEPRESETFOR(AVCaptureSessionPreset1920x1080, 1920, 1440, 1080); // iOS & 10.15 only :-(
  USEPRESETFOR(AVCaptureSessionPreset1280x720,  1280,  960,  720);
  USEPRESETFOR(AVCaptureSessionPreset960x540,    960,  540,  480);
  USEPRESETFOR(AVCaptureSessionPreset640x480,    640,  480,  360);
//USEPRESETFOR(AVCaptureSessionPresetMedium,     480,  360,  270);
  USEPRESETFOR(AVCaptureSessionPreset352x288,    352,  288,  216);
  USEPRESETFOR(AVCaptureSessionPreset320x240,    320,  240,  180);
  USEPRESETFOR(AVCaptureSessionPresetLow,        192,  144,  108);
//USEPRESETFOR(AVCaptureSessionPresetLow,        160,  120,   90);

  if (!preset) {
	if (bestPresetBelow
	 && (bestWidthBelow <= desiredWidth || bestHeightBelow <= desiredHeight)) {
		preset = bestPresetBelow;
		width = bestWidthBelow;
		height = bestHeightBelow;
	}
	else {
		preset = bestPreset;
		width = bestWidth;
		height = bestHeight;
	}
  }

#undef USEPRESETFOR

  [captureInput.device lockForConfiguration: nil];

  if (preset) {
  // Set the video output to store frame in BGRA (It is supposed to be faster)
	NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt: width], (id)kCVPixelBufferWidthKey,
		[NSNumber numberWithInt: height], (id)kCVPixelBufferHeightKey,
		[NSNumber numberWithInt: kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
		nil];
    [captureOutput setVideoSettings:outputSettings];
    [captureSession setSessionPreset: preset];
  }

  if ([captureInput.device isExposureModeSupported: AVCaptureExposureModeAutoExpose])
	[captureInput.device setExposureMode: AVCaptureExposureModeAutoExpose];
  if ([captureInput.device isFocusModeSupported: AVCaptureFocusModeAutoFocus])
    [captureInput.device setFocusMode: AVCaptureFocusModeAutoFocus];

  [captureInput.device unlockForConfiguration];

  // We add input and output
  if ([captureSession canAddInput: captureInput])
    [captureSession addInput: captureInput];
  if ([captureSession canAddOutput: captureOutput])
    [captureSession addOutput: captureOutput];

  // We start the capture Session
  [captureSession commitConfiguration];
  [captureSession startRunning];

  bInitCalled = YES;
  frameCount = 0;
  semaphoreIndex = -1;
  grabbers[deviceID] = self;
  return self;
}

-(void)stopCapture: (sqInt)cameraNum {
  if (captureSession) {
    if (captureOutput) {
      if (captureOutput.sampleBufferDelegate != nil) {
        [captureOutput setSampleBufferDelegate: nil queue: NULL];
        dispatch_release(queue);
      }
    }

    // remove the input and outputs from session
    for (AVCaptureInput *input1 in captureSession.inputs)
      [captureSession removeInput: input1];
    for (AVCaptureOutput *output1 in captureSession.outputs)
      [captureSession removeOutput: output1];
    [captureSession stopRunning];
	// No need to free pixels carefully since camera is no longer running.
    if (pixels) {
		free(pixels);
		pixels = NULL;
		pixelsByteSize = 0;
	}
	frameCount = errorCode = 0;
    bInitCalled = useBNotA = NO;
    captureSession = NULL;
    captureOutput = NULL;
    captureInput = NULL;
	bufferAOrNil = bufferBOrNil = 0;
	bufferSize = 0;
    grabbers[cameraNum-1] = NULL;
  }
}

@end

void
printDevices()
{
  NSArray *devices = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];
  int i = 0;
  for (AVCaptureDevice *captureDevice in devices)
    NSLog(@"Device(%d): %@\n", i++, [captureDevice localizedName]);
}

static char *
getDeviceName(sqInt cameraNum)
{
  NSArray *devices = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];
  if (cameraNum < 1 || cameraNum > [devices count])
    return NULL;
  return (char*)[((AVCaptureDevice*)[devices objectAtIndex: cameraNum-1]).localizedName UTF8String];
}

static char *
getDeviceUID(sqInt cameraNum)
{
  NSArray *devices = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];
  if (cameraNum < 1 || cameraNum > [devices count])
    return NULL;
  return (char*)[((AVCaptureDevice*)[devices objectAtIndex: cameraNum-1]).uniqueID UTF8String];
}

sqInt
CameraOpen(sqInt cameraNum, sqInt desiredWidth, sqInt desiredHeight)
{
  if (cameraNum<1 || cameraNum>CAMERA_COUNT)
	return false;

  if (!ensureCameraAccess())
	return false;

  SqueakVideoGrabber *grabber = grabbers[cameraNum-1];

  if (grabber && grabber->pixels)
	return true;

  grabber = [SqueakVideoGrabber alloc];
  if (!grabber)
	return false;
  return [grabber	initCapture: cameraNum-1
					desiredWidth: desiredWidth
					desiredHeight: desiredHeight];
}

void 
CameraClose(sqInt cameraNum)
{
  SqueakVideoGrabber *grabber;

  if (cameraNum >= 1 && cameraNum <= CAMERA_COUNT
	&& (grabber = grabbers[cameraNum-1]))
	  [grabber stopCapture: cameraNum];
}

sqInt
CameraExtent(sqInt cameraNum)
{
  SqueakVideoGrabber *grabber;

  if (!ensureCameraAccess())
	return 0;

  /* if the camera is already open answer its extent */
  if (cameraNum >= 1 && cameraNum <= CAMERA_COUNT
	&& (grabber = grabbers[cameraNum-1]))
	return grabber->width <<16 | grabber->height;
#if 1
  return 0;
#else
  // This could work if cameras were shut down correctly, but they're not yet.
  if (!getDeviceName(cameraNum))
	return 0;
  long extent;
  /* Open to discover default resolution */
  (void)CameraOpen(cameraNum, 0, 0);
  grabber = grabbers[cameraNum-1];
  extent = grabber ? (grabber->width <<16 | grabber->height) : 0;
  CameraClose(cameraNum);
  return extent;
#endif
}

sqInt
CameraGetFrame(sqInt cameraNum, unsigned char *buf, sqInt pixelCount)
{
  if (cameraNum < 1 || cameraNum > CAMERA_COUNT)
	return -1;
  SqueakVideoGrabber *grabber = grabbers[cameraNum-1];
  if (!grabber)
	return -1;
  if (grabber->errorCode) {
	int theCode = grabber->errorCode;
	grabber->errorCode = 0;
	return -theCode;
  }
  if (grabber->pixels || grabber->bufferAOrNil) {
    int ourFrames = grabber->frameCount;
	if (grabber->pixels) {
#define min(a,b) ((a)<=(b)?(a):(b))
		long actualPixelCount = grabber->width * grabber->height;
		memcpy(buf, grabber->pixels, min(pixelCount,actualPixelCount) * 4);
	}
    grabber->frameCount = 0;
    return ourFrames;
  }
  return 0;
}

char *
CameraName(sqInt cameraNum)
{ return getDeviceName(cameraNum); }

char *
CameraUID(sqInt cameraNum)
{ return getDeviceUID(cameraNum); }

static sqInt
CameraIsOpen(sqInt cameraNum)
{
	return
		cameraNum >= 1 && cameraNum <= CAMERA_COUNT
		&& grabbers[cameraNum-1]
		&& grabbers[cameraNum-1]->pixels != (unsigned int *)0;
}

sqInt
CameraGetSemaphore(sqInt cameraNum)
{
  SqueakVideoGrabber *grabber;

  return cameraNum >= 1 && cameraNum <= CAMERA_COUNT
	  && (grabber = grabbers[cameraNum-1])
	  && grabber->semaphoreIndex > 0
		? grabber->semaphoreIndex
		: 0;
}

sqInt
CameraSetSemaphore(sqInt cameraNum, sqInt semaphoreIndex)
{
  SqueakVideoGrabber *grabber;

  if (cameraNum >= 1 && cameraNum <= CAMERA_COUNT
	&& (grabber = grabbers[cameraNum-1])) {
		grabber->semaphoreIndex = semaphoreIndex;
		return 0;
	}
	return PrimErrNotFound;
}

// primSetCameraBuffers ensures buffers are pinned non-pointer objs if non-null
sqInt
CameraSetFrameBuffers(sqInt cameraNum, sqInt bufferA, sqInt bufferB)
{
  SqueakVideoGrabber *grabber;

  if (cameraNum < 1
   || cameraNum > CAMERA_COUNT
   || !(grabber = grabbers[cameraNum-1]))
	return PrimErrNotFound;

  sqInt byteSize = interpreterProxy->byteSizeOf(bufferA);

  if (bufferB
   && byteSize != interpreterProxy->byteSizeOf(bufferB))
	return PrimErrInappropriate;

  if (grabber->width * grabber->height * 4 > byteSize)
	return PrimErrWritePastObject;

  grabber->bufferAOrNil = interpreterProxy->firstIndexableField(bufferA);
  grabber->bufferBOrNil = bufferB
						? interpreterProxy->firstIndexableField(bufferB)
						: (void *)0;
  grabber->bufferSize = byteSize;
  sqLowLevelMFence();
  // Need to free pixels carefully since camera may be running.
  if (grabber->pixels) {
	unsigned int *the_pixels = grabber->pixels;
	grabber->pixelsByteSize = 0;
	grabber->pixels = 0;
	sqLowLevelMFence();
	free(the_pixels);
  }
  return 0;
}

sqInt
CameraGetParam(sqInt cameraNum, sqInt paramNum)
{
	if (!CameraIsOpen(cameraNum)) return -1;
	if (paramNum == 1) return grabbers[cameraNum-1]->frameCount;
	if (paramNum == 2) return grabbers[cameraNum-1]->width
							* grabbers[cameraNum-1]->height * 4;

	return -2;
}

sqInt
cameraInit(void) { return 1; }

sqInt
cameraShutdown(void)
{
	for (int cameraNum = 1; cameraNum <= CAMERA_COUNT; cameraNum++)
		(void)CameraClose(cameraNum);
	return 1;
}
