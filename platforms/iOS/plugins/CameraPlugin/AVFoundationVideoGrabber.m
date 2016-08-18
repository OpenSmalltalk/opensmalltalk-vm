/*
 *  AVFoundationVideoGrabber.mm
 *  Written by Yoshiki Ohshima
 *  Most of code was taken from OpenFrameworks at
 *  https://github.com/openframeworks/openFrameworks/blob/master/addons/ofxiOS/src/video/AVFoundationVideoGrabber.mm
 *  which is released under the MIT license.  Subsequently, this code is also under the MIT license.
 */

#include <TargetConditionals.h>

#include <Cocoa/Cocoa.h>
#include <AVFoundation/AVFoundation.h>
#include "sqVirtualMachine.h"

#include "sqCamera.h"

void printDevices();

@interface SqueakVideoGrabber : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
  @public
  AVCaptureDeviceInput		*captureInput;
  AVCaptureVideoDataOutput	*captureOutput;
  AVCaptureDevice		*device;
  AVCaptureSession		*captureSession;
  int				deviceID;
  int				width;
  int				height;
  bool				bInitCalled;
  unsigned int			*pixels;
  bool				firstTime;
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
  if(firstTime) {
    // Get information about the image
    //uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    //size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t widthIn = CVPixelBufferGetWidth(imageBuffer);
    size_t heightIn = CVPixelBufferGetHeight(imageBuffer);
    width = widthIn;
    height = heightIn;
    // printf("values: %d, %d, %d, %d\n", baseAddress, bytesPerRow, widthIn, heightIn);

    // We unlock the image buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    pixels = malloc(width * height * 4);
    firstTime = false;
  } else {
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    unsigned int *isrc4 = (unsigned int *)CVPixelBufferGetBaseAddress(imageBuffer);
    memcpy(pixels, isrc4, height * width * 4);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
  }
}

-(SqueakVideoGrabber*)initCapture:(int)deviceNum
      desiredWidth:(int)desiredWidth 
      desiredHeight:(int)desiredHeight {
  NSArray *devices = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];

  printf("devices count %d\n", [devices count]);
  if ([devices count] == 0) {
    return NULL;
  }

  if (deviceNum > [devices count] - 1) {
    deviceID = [devices count] - 1;
  } 
  device = [devices objectAtIndex: deviceID];

  printDevices();
  printf("device %d\n", device);

  // We setup the input
  captureInput = [AVCaptureDeviceInput deviceInputWithDevice: device error: nil];
  // We setup the output
  captureOutput = [[AVCaptureVideoDataOutput alloc] init];
  // While a frame is processes in -captureOutput:didOutputSampleBuffer:fromConnection: delegate methods no other frames are added in the queue.
  // If you don't want this behaviour set the property to NO
  captureOutput.alwaysDiscardsLateVideoFrames = YES;

//  printf("capture: %x, %x\n", captureInput, captureOutput);

  // We create a serial queue to handle the processing of our frames
  dispatch_queue_t queue;
  queue = dispatch_queue_create("cameraQueue", NULL);
  [captureOutput setSampleBufferDelegate: self queue:queue];
#define IOS 0
#if IOS
  dispatch_release(queue);
#endif
		
  // Set the video output to store frame in BGRA (It is supposed to be faster)
  NSString* key = [NSString stringWithCString: "PixelFormatType" encoding: NSASCIIStringEncoding];
  NSNumber* value = [NSNumber numberWithUnsignedInt: kCVPixelFormatType_32BGRA];
//  printf("key value: %x, %x\n", key, value);
  NSDictionary* videoSettings = [NSDictionary dictionaryWithObject: value forKey: key];

//  printf("videoSettings: %x, %d\n", videoSettings, value);
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
  NSString * preset = AVCaptureSessionPresetMedium;

  if (desiredWidth == 640 && desiredHeight == 480) {
    preset = AVCaptureSessionPreset640x480;
  } else if (desiredWidth == 1280 && desiredHeight == 720) {
    preset = AVCaptureSessionPreset1280x720;
  } else if (desiredWidth == 1920 && desiredHeight == 1080) {
//preset = AVCaptureSessionPreset1920x1080;
    preset = AVCaptureSessionPreset1280x720;
  } else if (desiredWidth == 192 && desiredHeight == 144) {
    preset = AVCaptureSessionPresetLow;
  }

  [captureSession setSessionPreset: preset];
		
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
  grabbers[deviceID] = self;
  return self;
}

-(void)startCapture: (int)cameraNum {
  if (!bInitCalled) {
    [self initCapture: cameraNum desiredWidth: 640 desiredHeight: 480];
  }
  [captureSession startRunning];
  [captureInput.device lockForConfiguration: nil];
	
  //if( [captureInput.device isExposureModeSupported:AVCaptureExposureModeAutoExpose] ) [captureInput.device setExposureMode:AVCaptureExposureModeAutoExpose ];
  if ([captureInput.device isFocusModeSupported: AVCaptureFocusModeAutoFocus]) {
    [captureInput.device setFocusMode: AVCaptureFocusModeAutoFocus];
  }
}

-(void)stopCapture: (int)cameraNum {
  if (captureSession) {
    if (captureOutput) {
      if (captureOutput.sampleBufferDelegate != nil) {
	[captureOutput setSampleBufferDelegate: nil queue: NULL];
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
    bInitCalled = NO;
    captureSession = NULL;
    captureOutput = NULL;
    captureInput = NULL;
    grabbers[cameraNum] = NULL;
  }
}

@end

SqueakVideoGrabber *
init(int cameraNum, int desiredWidth, int desiredHeight) {
  SqueakVideoGrabber *this = [SqueakVideoGrabber alloc];
  return [this initCapture: cameraNum
               desiredWidth: desiredWidth
               desiredHeight: desiredHeight];
}

void
printDevices() {
  NSArray * devices = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];
  int i = 0;
  for (AVCaptureDevice *captureDevice in devices) {
    printf("Device(%d): %s\n", i, [captureDevice.localizedName UTF8String]);
    i++;
  }
}

char*
getDeviceName(int cameraNum) {
  NSArray * devices = [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo];
  if (cameraNum > [devices count]) {
    return "";
  }
  return (char*)[((AVCaptureDevice*)[devices objectAtIndex: cameraNum]).localizedName UTF8String];
}

int
CameraOpen(int cameraNum, int desiredWidth, int desiredHeight) {
  SqueakVideoGrabber *this = grabbers[cameraNum];

  if (this) {return true;}

  this = init(cameraNum, desiredWidth, desiredHeight);
  if (!this) {return false;}
  [this startCapture: cameraNum];
  return true;
}

void 
CameraClose(int cameraNum) {
  SqueakVideoGrabber *this = grabbers[cameraNum];
  if (!this) {return;}
  [this stopCapture: cameraNum];
}

int
CameraExtent(int cameraNum) {
  SqueakVideoGrabber *this = grabbers[cameraNum];
  if (!this) {return 0;}
  return (this->width <<16 | this->height);
}

int
CameraGetFrame(int cameraNum, unsigned char *buf, int pixelCount) {
  SqueakVideoGrabber *this = grabbers[cameraNum];
  if (!this) {return false;}
  if (!this->firstTime) {
    memcpy(buf, this->pixels, pixelCount * 4);
  }
  return true;
}

char *
CameraName(int cameraNum) {
  return getDeviceName(cameraNum);
}

int
CameraGetParam(int cameraNum, int paramNum) {
  return 1;
}
