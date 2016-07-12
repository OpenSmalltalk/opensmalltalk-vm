int CameraOpen(int cameraNum, int desiredWidth, int desiredHeight);
void CameraClose(int cameraNum);
int CameraExtent(int cameraNum);
int CameraGetFrame(int cameraNum, unsigned char* buf, int pixelCount);
char* CameraName(int cameraNum);
int CameraGetParam(int cameraNum, int paramNum);
