/* Plugin support primitives */

#include "sq.h"

EXPORT(sqInt) primitivePluginBrowserReady(void)      { return primitiveFail(); }
EXPORT(sqInt) primitivePluginRequestURLStream(void)  { return primitiveFail(); }
EXPORT(sqInt) primitivePluginRequestURL(void)        { return primitiveFail(); }
EXPORT(sqInt) primitivePluginPostURL(void)           { return primitiveFail(); }
EXPORT(sqInt) primitivePluginRequestFileHandle(void) { return primitiveFail(); }
EXPORT(sqInt) primitivePluginDestroyRequest(void)    { return primitiveFail(); }
EXPORT(sqInt) primitivePluginRequestState(void)      { return primitiveFail(); }
