#ifndef _SQ_CAMERA_PLUGIN_H_
#define _SQ_CAMERA_PLUGIN_H_

sqInt CameraOpen(int cameraNum, int frameWidth, int frameHeight);
void CameraClose(int cameraNum);
sqInt CameraExtent(int cameraNum);
sqInt CameraGetFrame(int cameraNum, unsigned char* buf, int pixelCount);
char* CameraName(int cameraNum);
sqInt CameraGetParam(int cameraNum, int paramNum);

#endif /* _SQ_CAMERA_PLUGIN_H_ */
