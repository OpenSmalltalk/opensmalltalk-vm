#ifndef __SQ_DSOUND_CLASS_FACTORY_H__
#define __SQ_DSOUND_CLASS_FACTORY_H__

#include <dsound.h>
#include <dsconf.h>

#ifdef __cplusplus
extern "C" {
#endif 

int dsound_InitClassFactory(void);
int dsound_ShutdownClassFactory(void);
IClassFactory* dsound_GetClassFactory(REFCLSID classID);

#ifdef __cplusplus
}
#endif 

#endif /* #ifndef __SQ_DSOUND_CLASS_FACTORY_H__ */
