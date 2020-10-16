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
sqInt CameraGetParam(sqInt cameraNum, sqInt paramNum);
sqInt CameraGetSemaphore(sqInt cameraNum);
sqInt CameraSetSemaphore(sqInt cameraNum, sqInt semaphoreIndex);

#endif /* _SQ_CAMERA_PLUGIN_H_ */
