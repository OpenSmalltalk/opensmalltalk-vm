/* serial port primitives */

/* module initialization/shutdown */
extern int serialPortInit(void);
extern int serialPortShutdown(void);

#pragma export on
extern int serialPortClose(int portNum);
extern int serialPortCloseByName(const char *portName);
extern int serialPortCount(void);
extern int serialPortOpen(int portNum, int baudRate, int stopBitsType,
							int parityType, int dataBits, int inFlowCtrl,
							int outFlowCtrl, int xOnChar, int xOffChar);
extern int serialPortOpenByName(const char *portName, int baudRate, int stopBitsType,
           int parityType, int dataBits,
		   int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar);
extern int serialPortReadInto(int portNum, int count, void *bufferPtr);
extern int serialPortReadIntoByName(const char *portName, int count, void *bufferPtr);
extern int serialPortWriteFrom(int portNum, int count, void *bufferPtr);
extern int serialPortWriteFromByName(const char *portName, int count, void *bufferPtr);
#pragma export off
