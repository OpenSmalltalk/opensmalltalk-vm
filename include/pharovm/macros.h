#ifndef _MACROS_H_
#define _MACROS_H_

/*
 * The primitives should be defined with a depth parameter.
 * For this, the following macros are generated.
 *
 * Primitive macro generates with 0, because it is the normal value for depth.
 * PrimitiveWithDepth receives a parameters for the depth.
 *
 * What is depth?
 *
 * Initially when the VM executes a primitive it does not handle the forwarding
 * of the parameters. It sends the parameters as they are.
 * A primitive should validate the parameters sent to it.
 * If they are not valid (or they are a forwarder, and they need to be used) it should fail.
 *
 * The VM will handle the resolution of the forwarders and recall the primitive.
 * If the depth is -1, the VM will not do nothing and just fail the call.
 * If the depth is >=0, the VM will resolve the forwarders and then recall the primitive.
 *
 * The depth, is the levels of accessors used in the primitive.
 *
 * If the primitive only uses the objects received by parameter the depth is 0,
 * if it uses one of the objects refereced by the parameters the depth is 1, and so on.
 *
 * Example
 * =======
 *
 * [ p ] --> [ a ] -> [ x ]
 * 		 --> [ b ]
 * 		 \-> [ c ] -> [ y ]
 *
 *
 * If we only require to use the object p (that is a parameter to the primitive in the stack),
 * the depth is 0, if we want to use the object a, b or c (that are referenciated by p) the depth
 * should be 1. In the case of wanting to use x or y, depth should be 2.
 *
 */
#include "exportDefinition.h"

#define PrimitiveWithDepth(functionName, N) EXPORT(signed) char functionName ##AccessorDepth = N; \
	EXPORT(void) functionName (void)

#define Primitive(functionName) PrimitiveWithDepth(functionName, 0)

#define checkFailed() if(failed()) return;

#define checkFailedReturn(ret) if(failed()) return ret;

#define checkIsArray(anObject) 	if(!isKindOfClass(anObject, classArray())){ \
		primitiveFail(); \
		return;\
	} \

#define checkIsClassOf(anObject, aClass) 	if(!isKindOfClass(anObject, aClass)){ \
		primitiveFail(); \
		return;\
	} \

#define checkIsPointerSize(anObject, size)	if(!(isPointers(anObject) && slotSizeOf(anObject) >= size)) {\
		primitiveFail();\
		return;\
	}

#define check(cond) if(!(cond)) { \
        primitiveFail();\
        return; \
    }

#endif /* _MACROS_H_ */
