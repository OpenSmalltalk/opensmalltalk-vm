#ifndef _SQ_CAMERA_PLUGIN_H_
#define _SQ_CAMERA_PLUGIN_H_

sqInt cameraInit(void);
sqInt cameraShutdown(void);
sqInt CameraOpen(sqInt cameraNum, sqInt frameWidth, sqInt frameHeight);
void  CameraClose(sqInt cameraNum);
char *CameraName(sqInt cameraNum);
char *CameraUID(sqInt cameraNum);
sqInt CameraExtent(sqInt cameraNum);
sqInt CameraGetFrame(sqInt cameraNum, unsigned char *buf, sqInt pixelCount);

// CameraGet/SetParam names
#define FrameCount 1
#define FrameByteSize 2
#define MirrorImage 3
sqInt CameraGetParam(sqInt cameraNum, sqInt paramNum);
sqInt CameraSetParam(sqInt cameraNum, sqInt paramNum, sqInt paramValue);
sqInt CameraGetSemaphore(sqInt cameraNum);
sqInt CameraSetSemaphore(sqInt cameraNum, sqInt semaphoreIndex);
sqInt CameraSetFrameBuffers(sqInt cameraNum, sqInt bufferA, sqInt bufferBorNil);
sqInt CameraGetLatestBufferIndex(sqInt cameraNum);

#endif /* _SQ_CAMERA_PLUGIN_H_ */
