/* serial port primitives */

/* module initialization/shutdown */
int serialPortInit(void);
int serialPortShutdown(void);

#pragma export on
EXPORT (int) serialPortClose(int portNum);
EXPORT (int) serialPortCloseByName(const char *portName);
EXPORT (int) serialPortCount(void);
EXPORT (int) serialPortOpen(int portNum, int baudRate, int stopBitsType,
							int parityType, int dataBits, int inFlowCtrl,
							int outFlowCtrl, int xOnChar, int xOffChar);
EXPORT (int) serialPortOpenByName(const char *portName, int baudRate, int stopBitsType,
           int parityType, int dataBits,
		   int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar);
EXPORT (int) serialPortReadInto(int portNum, int count, void *bufferPtr);
EXPORT (int) serialPortReadIntoByName(const char *portName, int count, void *bufferPtr);
EXPORT (int) serialPortWriteFrom(int portNum, int count, void *bufferPtr);
EXPORT (int) serialPortWriteFromByName(const char *portName, int count, void *bufferPtr);
#pragma export off
