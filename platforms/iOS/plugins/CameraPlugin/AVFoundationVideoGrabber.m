/*
 *  AVFoundationVideoGrabber.mm
 *  Written by Yoshiki Ohshima
 *  Most of code was taken from OpenFrameworks at
 *  https://github.com/openframeworks/openFrameworks/blob/master/addons/ofxiOS/src/video/AVFoundationVideoGrabber.mm
 *  which is released under the MIT license.  Subsequently, this code is also under the MIT license.
 *
 * Implementaion node:
 * variable cameraNum is 1-based in following code in order to fit Smalltalk expectations
 */

#include "sqVirtualMachine.h"
#include "CameraPlugin.h"

#include <TargetConditionals.h>

#include <Cocoa/Cocoa.h>
#include <AVFoundation/AVFoundation.h>


void printDevices();

@interface SqueakVideoGrabber : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
{
  @public
  AVCaptureDeviceInput		*captureInput;
  AVCaptureVideoDataOutput	*captureOutput;
  AVCaptureDevice		*device;
  AVCaptureSession		*captureSession;
  dispatch_queue_t		queue;
  int				deviceID;
  int				width;
  int				height;
  bool				bInitCalled;
  unsigned int			*pixels;
  bool				firstTime;
  sqInt			frameCount;
}
@end

@interface SqueakVideoGrabber() <AVCaptureVideoDataOutputSampleBufferDelegate> {
}
@end

SqueakVideoGrabber *grabbers[8] = {NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL};

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

    // We unlock the image buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    pixels = malloc(width * height * 4);
    firstTime = false;
  }
  else {
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    unsigned int *isrc4 = (unsigned int *)CVPixelBufferGetBaseAddress(imageBuffer);
    memcpy(pixels, isrc4, height * width * 4);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
  }
  frameCount++;
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
  if ([devices count] == 0) {
    return NULL;
  }

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
  // While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
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

  // Set the video output to store frame in BGRA (It is supposed to be faster)
  NSDictionary* videoSettings = [NSDictionary
    dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
    forKey: (id)kCVPixelBufferPixelFormatTypeKey];

  // NSLog(@"videoSettings: %@\n", videoSettings);
  [captureOutput setVideoSettings: videoSettings];

  // And we create a capture session
  if (captureSession) {
    captureSession = NULL;
  }
  captureSession = [[AVCaptureSession alloc] init];
#if IOS
  [captureSession autorelease];
#endif
  [captureSession beginConfiguration]; 
  NSString *preset = NULL;

#define USEPRESETFOR(p, w, h, h2) \
  if (!preset && ([captureSession canSetSessionPreset: (p)])) { \
	if (desiredWidth == w && (desiredHeight == h || desiredHeight == h2)) { \
	  preset = p; \
	  width = w; \
	  height = desiredHeight == h ? h : h2; \
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
  USEPRESETFOR(AVCaptureSessionPreset320x240,    320,  240,  180);
  USEPRESETFOR(AVCaptureSessionPresetLow,        192,  108,  144);
  USEPRESETFOR(AVCaptureSessionPresetLow,        160,  120,   90);

//  IOS only
//  USEPRESETFOR(AVCaptureSessionPreset1920x1080, 1920, 1080, 1440);

#undef USEPRESETFOR

  if (preset) {
    [captureSession setSessionPreset: preset];
  }

  // We add input and output
  if ([captureSession canAddInput: captureInput]) {
    [captureSession addInput: captureInput];
  }
  if ([captureSession canAddOutput: captureOutput]) {
    [captureSession addOutput: captureOutput];
  }

  // We start the capture Session
  [captureSession commitConfiguration];
  [captureSession startRunning];

  bInitCalled = YES;
  firstTime = true;
  frameCount = 0;
  grabbers[deviceID] = self;
  return self;
}

-(void)startCapture: (sqInt)cameraNum {
  if (!bInitCalled) {
    [self initCapture: cameraNum-1 desiredWidth: 640 desiredHeight: 480];
  }
  [captureSession startRunning];
  [captureInput.device lockForConfiguration: nil];

  //if ( [captureInput.device isExposureModeSupported:AVCaptureExposureModeAutoExpose] ) [captureInput.device setExposureMode:AVCaptureExposureModeAutoExpose ];
  if ([captureInput.device isFocusModeSupported: AVCaptureFocusModeAutoFocus]) {
    [captureInput.device setFocusMode: AVCaptureFocusModeAutoFocus];
  }
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
    for (AVCaptureInput *input1 in captureSession.inputs) {
      [captureSession removeInput: input1];
    }
    for (AVCaptureOutput *output1 in captureSession.outputs) {
      [captureSession removeOutput: output1];
    }
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

SqueakVideoGrabber *
init(sqInt cameraNum, int desiredWidth, int desiredHeight) {
  SqueakVideoGrabber *this = [SqueakVideoGrabber alloc];
  return [this initCapture: cameraNum-1
               desiredWidth: desiredWidth
               desiredHeight: desiredHeight];
}

void
printDevices() {
  NSArray * devices = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];
  int i = 0;
  for (AVCaptureDevice *captureDevice in devices) {
    NSLog(@"Device(%d): %@\n", i, [captureDevice localizedName]);
    i++;
  }
}

static char *
getDeviceName(sqInt cameraNum) {
  NSArray * devices = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];
  if (cameraNum < 1 || cameraNum > [devices count])
    return NULL;
  return (char*)[((AVCaptureDevice*)[devices objectAtIndex: cameraNum-1]).localizedName UTF8String];
}

sqInt
CameraOpen(sqInt cameraNum, sqInt desiredWidth, sqInt desiredHeight) {
  if (cameraNum<1 || cameraNum>8) return false;
  SqueakVideoGrabber *this = grabbers[cameraNum-1];

  if (this)
	return true;

  this = init(cameraNum, desiredWidth, desiredHeight);
  if (!this)
	return false;
  [this startCapture: cameraNum];
  return true;
}

void 
CameraClose(sqInt cameraNum)
{
  if (cameraNum<1 || cameraNum>8) return;
  SqueakVideoGrabber *this = grabbers[cameraNum-1];
  if (!this) return;
  [this stopCapture: cameraNum];
}

sqInt
CameraExtent(sqInt cameraNum)
{
  SqueakVideoGrabber *this;

  /* if the camera is already open answer its extent */
  if (cameraNum >= 1 && cameraNum <= 8
	&& (this = grabbers[cameraNum-1]))
	return this->width <<16 | this->height;
  if (!getDeviceName(cameraNum)) return 0;
  /* if not yet open, open with default resolution and answer default extent */
  this = grabbers[cameraNum-1];
  if (!this)
	this = init(cameraNum, 0, 0);
  return this ? (this->width <<16 | this->height) : 0;
}

sqInt
CameraGetFrame(sqInt cameraNum, unsigned char *buf, sqInt pixelCount)
{
  if (cameraNum<1 || cameraNum>8) return -1;
  SqueakVideoGrabber *this = grabbers[cameraNum-1];
  if (!this)
	return -1;
  if (!this->firstTime) {
    int ourFrames = this->frameCount;
    this->frameCount = 0;
    memcpy(buf, this->pixels, pixelCount * 4);
    return ourFrames;
  }
  return 0;
}

char *
CameraName(sqInt cameraNum)
{ return getDeviceName(cameraNum); }

sqInt
CameraGetParam(sqInt cameraNum, sqInt paramNum)
{ return 1; }
