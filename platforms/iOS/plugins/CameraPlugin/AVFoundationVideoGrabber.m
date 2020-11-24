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
#include "CameraPlugin.h"
extern struct VirtualMachine *interpreterProxy;

#include <TargetConditionals.h>

#include <Cocoa/Cocoa.h>
#include <AVFoundation/AVFoundation.h>

// dispatch_release will only compile if macosx-version-min<=10.7
#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1080
# define dispatch_release(shunned) 0
#endif

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
  sqInt						 frameCount;
  int						 deviceID;
  int						 width;
  int						 height;
  int						 semaphoreIndex;
  bool						 bInitCalled;
  bool						 firstTime;
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
	if (firstTime) {
		width = CVPixelBufferGetWidth(imageBuffer);
		height = CVPixelBufferGetHeight(imageBuffer);
		pixels = malloc(width * height * 4);
	}
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	memcpy(	pixels,
			CVPixelBufferGetBaseAddress(imageBuffer),
			width * height * 4);
	firstTime = false;
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	frameCount++;
	if (semaphoreIndex > 0)
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
  NSString *preset = NULL;

#define USEPRESETFOR(p, w, h, h2) \
  if ([captureSession canSetSessionPreset: p]) { \
	if (desiredWidth == w && (desiredHeight == h || desiredHeight == h2)) { \
	  preset = p; \
	  width = desiredWidth; \
	  height = desiredHeight; \
	} \
	else if (!preset && !desiredWidth && !desiredHeight) { \
	    preset = p; \
		width = w; \
		height = h; \
	} \
  }

  width = height = 0;
  USEPRESETFOR(AVCaptureSessionPreset1280x720,  1920, 1080, 1440);
  USEPRESETFOR(AVCaptureSessionPreset1280x720,  1280,  720,  960);
  USEPRESETFOR(AVCaptureSessionPreset640x480,    640,  480,  360);
  USEPRESETFOR(AVCaptureSessionPresetMedium,     480,  360,  270);
  USEPRESETFOR(AVCaptureSessionPreset352x288,    352,  288,  216);
  USEPRESETFOR(AVCaptureSessionPreset320x240,    320,  240,  180);
  USEPRESETFOR(AVCaptureSessionPresetLow,        192,  108,  144);
  USEPRESETFOR(AVCaptureSessionPresetLow,        160,  120,   90);

//  IOS only
//  USEPRESETFOR(AVCaptureSessionPreset1920x1080, 1920, 1080, 1440);

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
  firstTime = true;
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
    free(pixels);
    pixels = NULL;
    firstTime = true;
    frameCount = 0;
    bInitCalled = NO;
    captureSession = NULL;
    captureOutput = NULL;
    captureInput = NULL;
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
  SqueakVideoGrabber *grabber = grabbers[cameraNum-1];

  if (grabber && grabber->pixels)
	return true;

  grabber = [SqueakVideoGrabber alloc];
  if (!grabber)
	return false;
  return [grabber	initCapture: cameraNum-1
					desiredWidth: desiredWidth
					desiredHeight: desiredHeight];
  return true;
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
  if (cameraNum<1 || cameraNum>CAMERA_COUNT)
	return -1;
  SqueakVideoGrabber *grabber = grabbers[cameraNum-1];
  if (!grabber)
	return -1;
  if (!grabber->firstTime) {
    int ourFrames = grabber->frameCount;
#define min(a,b) ((a)<=(b)?(a):(b))
	long actualPixelCount = grabber->width * grabber->height;
    memcpy(buf, grabber->pixels, min(pixelCount,actualPixelCount) * 4);
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
