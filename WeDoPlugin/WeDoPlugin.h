#ifndef _SQ_WEDO_PLUGIN_H_
#define _SQ_WEDO_PLUGIN_H_

int WeDoOpenPort(void);
int WeDoClosePort(void);
int WeDoRead(char *bufPtr, int bufSize);
int WeDoWrite(char *bufPtr, int bufSize);

#endif /* _SQ_WEDO_PLUGIN_H_ */
