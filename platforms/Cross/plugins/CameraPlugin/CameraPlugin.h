#ifndef _SQ_CAMERA_PLUGIN_H_
#define _SQ_CAMERA_PLUGIN_H_

sqInt CameraOpen(sqInt cameraNum, sqInt frameWidth, sqInt frameHeight);
void CameraClose(sqInt cameraNum);
sqInt CameraExtent(sqInt cameraNum);
sqInt CameraGetFrame(sqInt cameraNum, unsigned char* buf, sqInt pixelCount);
char* CameraName(sqInt cameraNum);
sqInt CameraGetParam(sqInt cameraNum, sqInt paramNum);

#endif /* _SQ_CAMERA_PLUGIN_H_ */
