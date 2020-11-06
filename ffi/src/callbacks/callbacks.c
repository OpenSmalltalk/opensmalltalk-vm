#include "callbacks.h"
#include "worker.h"

TSQueue* callbackQueue = NULL;

void queue_add_pending_callback(CallbackInvocation *callback) {
	threadsafe_queue_put(callbackQueue, callback);
}

void initilizeCallbacks(int pharo_semaphore_index){
    callbackQueue = threadsafe_queue_new(pharo_semaphore_new(pharo_semaphore_index));
}

static void callbackFrontend(ffi_cif *cif, void *ret, void* args[], void* cbPtr) {
	CallbackInvocation invocation;
	Callback *callback = cbPtr;

	invocation.callback = callback;
	invocation.arguments = args;
	invocation.returnHolder = ret;
    
    // Push callback invocation into a callback stack
    // This callback stack is used to validate that callbacks return in order
    invocation.previous = callback->runner->callbackStack;
    callback->runner->callbackStack = &invocation;
    
    callback->runner->callbackPrepareInvocation(callback->runner, &invocation);

    queue_add_pending_callback(&invocation);
	
	// Manage callouts while waiting this callback to return
	callback->runner->callbackEnterFunction(callback->runner, &invocation);
}

Callback *callback_new(Runner* runner, ffi_type** parameters, sqInt count, ffi_type* returnType) {
    Callback *callback = malloc(sizeof(Callback));
    int returnCode;
    
    callback->runner = runner;
    callback->parameterTypes = parameters;
    
    // Allocate closure and bound_puts
    callback->closure = ffi_closure_alloc(sizeof(ffi_closure), &(callback->functionAddress));
    
    if(callback->closure == NULL){
        primitiveFailFor(1);
        free(callback);
        free(parameters);
        return NULL;
    }
    
    if((returnCode = ffi_prep_cif(&callback->cif, FFI_DEFAULT_ABI, count, returnType, parameters)) != FFI_OK){
        primitiveFailFor(1);
        ffi_closure_free(callback->closure);
        free(callback);
        free(parameters);
        return NULL;
    }
    
    if((returnCode = ffi_prep_closure_loc(callback->closure, &callback->cif, callbackFrontend, callback, callback->functionAddress)) != FFI_OK){
        primitiveFailFor(1);
        ffi_closure_free(callback->closure);
        free(callback);
        free(parameters);
        return NULL;
    }
    
    return callback;
}

void callback_release(Callback *callback){
	ffi_closure_free(callback->closure);
	free(callback->parameterTypes);

	if(callback->userData){
		free(callback->userData);
	}

	free(callback);
}


CallbackInvocation *queue_next_pending_callback() {
	if(callbackQueue == NULL)
		return NULL;

    CallbackInvocation *invocation = (CallbackInvocation *) threadsafe_queue_take(callbackQueue);
    return invocation;
}
