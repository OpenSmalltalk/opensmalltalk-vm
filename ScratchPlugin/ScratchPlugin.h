#ifndef _SQ_SCRATCH_PLUGIN_H_
#define _SQ_SCRATCH_PLUGIN_H_

/* OS utilities */

void OpenURL(char *url);
void SetScratchWindowTitle(char *title);
void GetFolderPathForID(int folderID, char *path, int maxPath);
int WinShortToLongPath(char *shortPath, char* longPath, int maxPath);
int IsFileOrFolderHidden(char *fullPath);
void SetUnicodePasteBuffer(short int *utf16, int count);

/* serial port enumeration */
int SerialPortCount(void);
void SerialPortName(int portIndex, char *bsdPath, int maxPathSize);

/* serial port open/close */
int SerialPortOpenPortNamed(char *portName, int baudRate);
void SerialPortClose(int portNum);
int SerialPortIsOpen(int portNum);

/* serial port read/write */
int SerialPortRead(int portNum, char *bufPtr, int bufSize);
int SerialPortWrite(int portNum, char *bufPtr, int bufSize);

/* serial port port options */
int SerialPortSetOption(int portNum, int optionNum, int newValue);
int SerialPortGetOption(int portNum, int optionNum);

#endif /* _SQ_SCRATCH_PLUGIN_H_ */
