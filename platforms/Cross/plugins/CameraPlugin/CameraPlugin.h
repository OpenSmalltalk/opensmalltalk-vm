#ifndef _SQ_CAMERA_PLUGIN_H_
#define _SQ_CAMERA_PLUGIN_H_

int CameraOpen(int cameraNum, int frameWidth, int frameHeight);
void CameraClose(int cameraNum);
int CameraExtent(int cameraNum);
int CameraGetFrame(int cameraNum, unsigned char* buf, int pixelCount);
char* CameraName(int cameraNum);
int CameraGetParam(int cameraNum, int paramNum);

#endif /* _SQ_CAMERA_PLUGIN_H_ */
