#include "callbacks.h"
#include "pharovm/macros.h"

/* primitiveReadNextWorkerCallback
 *  answers next pending callback
 */
PrimitiveWithDepth(primitiveReadNextCallback, 1){
    CallbackInvocation *address;
    sqInt externalAddress;

    address = queue_next_pending_callback();

    if(address) {
        externalAddress = instantiateClassindexableSize(classExternalAddress(), sizeof(void*));
        checkFailed();

        writeAddress(externalAddress, address);
        checkFailed();
    } else {
        externalAddress = nilObject();
    }

    primitiveEndReturn(externalAddress);
}

PrimitiveWithDepth(primitiveGetCallbackInvocationUserData, 2){
	CallbackInvocation *callbackInvocation;

    sqInt receiver = getReceiver();
    checkFailed();

    callbackInvocation = (CallbackInvocation *)getHandler(receiver);
    checkFailed();

	sqInt returnValue = stringForCString((char*)callbackInvocation->callback->userData);
	if(!returnValue){
		primitiveFailFor(PrimErrNoMemory);
		return;
	}

	primitiveEndReturn(returnValue);
}

/*
 * Initialize the callback queue with the semaphore index
 *
 * Arguments:
 *
 *  - 0 semaphoreIndex <SmallInteger>
 */
Primitive(primitiveInitilizeCallbacks){

	int semaphoreIndex = stackIntegerValue(0);
	checkFailed();

	initilizeCallbacks(semaphoreIndex);

	primitiveEnd();
}

/* primitiveUnregisterWorkerCallback
 *  unregisters callback (taking a handle as parameter)
 *  arguments:
 *  - callbackHandle    <ExternalAddress>
 */
PrimitiveWithDepth(primitiveUnregisterCallback, 1){
    Callback *callback;

    callback = (Callback *)readAddress(stackValue(0));
    checkFailed();

    if(callback != NULL)
    	callback_release(callback);

    primitiveEnd();
}

/*
 * This primitive register a callback in libFFI.
 * This primitive generates the pointer to the function to be passed as the callback.
 * To do so, it generates all the structures expected by libFfi.
 *
 * It uses two objects, the receiver and a optional parameter ByteString object.
 *
 * The receiver is a TFCallback.
 *
 * It should at least have the following instance variables
 *
 * 0: handler: The pointer to the C callback function. This is the pointer passed to the C libraries using the callback.
 * 1: callbackData: A pointer to the plugin internal data structure.
 * 2: parameterHandlers
 * 3: returnTypeHandler
 * 4: runner
 *
 * The parameter is a ByteString that will be stored in the internal callback structure as a way of debugging.
 * The parameter can be nil.
 */
PrimitiveWithDepth(primitiveRegisterCallback, 3){
    sqInt callbackHandle;
    Callback *callback;
    sqInt count;
    void *handler;
    sqInt idx;
    sqInt paramArray;
    sqInt runnerInstance;
    ffi_type **parameters;
    sqInt receiver;
    ffi_type *returnType;
    sqInt debugString;

    receiver = getReceiver();
    checkFailed();

    //As the parameter is optional, the primitive invocation can came without it
    if(methodArgumentCount() == 1){
    	debugString = stackObjectValue(0);
    	checkFailed();
    }else{
    	debugString = nilObject();
    }

    callbackHandle = getAttributeOf(receiver, 1);
    checkFailed();

    paramArray = getAttributeOf(receiver, 2);
    checkFailed();

    returnType = getHandler(getAttributeOf(receiver, 3));
    checkFailed();

    runnerInstance = getAttributeOf(receiver, 4);
    checkFailed();

    Runner *runner = (Runner *)getHandler(runnerInstance);
    checkFailed();

    if(runner == NULL){
    	primitiveFail();
    	return;
	}

    count = stSizeOf(paramArray);
    checkFailed();


    //This array is freed when the callback is released.
    //If there is an error during the creation of the callback.
    //callback_new() frees it.
    parameters = malloc(count*sizeof(void*));
    for (idx = 0; idx < count; idx += 1) {
        parameters[idx] = (getHandler(stObjectat(paramArray, idx + 1)));
    }
    checkFailed();

    callback = callback_new(runner, parameters, count, returnType);
    checkFailed();

    if(debugString == nilObject()){
    	callback->userData = NULL;
    }else{
    	callback->userData = malloc(strlen(readString(debugString)) + 1);
    	strcpy(callback->userData, readString(debugString));
    }

    setHandler(receiver, callback->functionAddress);
    checkFailed();

    writeAddress(callbackHandle, callback);
    checkFailed();

    primitiveEnd();
}

/* primitiveWorkerCallbackReturn
 *   returns from a callback
 *   receiver <TFCallbackInvocation>
 *   It returns true if the callback can return, and false if the order is not correct and should
 *   retry later.
 */
PrimitiveWithDepth(primitiveCallbackReturn, 2) {
    CallbackInvocation *callbackInvocation;
    sqInt receiver, callbackInstance, runnerInstance;
    Runner *runner;

    // A callback invocation
    receiver = getReceiver();
    checkFailed();
    
    callbackInstance = getAttributeOf(receiver, 1);
    checkFailed();
    
    runnerInstance = getAttributeOf(callbackInstance, 4);
    checkFailed();
    
    runner = (Runner *)getHandler(runnerInstance);
    checkFailed();
    
    if(!runner){
        primitiveFail();
        return;
    }
    
    callbackInvocation = (CallbackInvocation*)getHandler(receiver);
    checkFailed();
    
    if(!callbackInvocation){
        primitiveFail();
        return;
    }

    // If the returning callback is not the last callback that entered, we cannot return
    // Otherwise this would produce a stack corruption (returning to an older callback erasing/overriding the stack of newer ones)
    if (callbackInvocation != runner->callbackStack){
    	primitiveEndReturn(falseObject());
        return;
    }

    //We have to do this here. Because the callbackExitFunction may not return
    //If we are in the samethread runner it does not return, as it uses a sig_longjmp to return to the caller of the callback!
    primitiveEndReturn(trueObject());
    
    // If the callback was the last one, we need to pop it from the callback stack
    runner->callbackStack = runner->callbackStack->previous;
    runner->callbackExitFunction(runner, callbackInvocation);
}
