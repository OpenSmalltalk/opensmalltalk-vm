/* serial port primitives */

/* module initialization/shutdown */
int serialPortInit(void);
int serialPortShutdown(void);

#pragma export on
int serialPortClose(int portNum);
int serialPortCount(void);
int serialPortOpen(
  int portNum, int baudRate, int stopBitsType, int parityType, int dataBits,
  int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar);
int serialPortReadInto(int portNum, int count, int bufferPtr);
int serialPortWriteFrom(int portNum, int count, int bufferPtr);
#pragma export off
