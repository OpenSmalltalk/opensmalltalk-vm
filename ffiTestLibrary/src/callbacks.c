#include "callbacks.h"
#if FEATURE_THREADED_FFI
#include <pthread.h>
#endif //FEATURE_THREADED_FFI

int singleCallToCallback(SIMPLE_CALLBACK fun, int base){
	return fun(base + 1);
}

int callbackInALoop(SIMPLE_CALLBACK fun){
	int i;
	int acc = 0;
	
	for(i=0;i<42;i++){
		acc = fun(acc);
	}
	
	return acc;
}

int reentringCallback(SIMPLE_CALLBACK fun, int base){
	printf("Value entered: %d\n", base);

	if(base == 0)
		return 1;

	return fun(base);
}

static int value = 0;

#if FEATURE_THREADED_FFI
void* otherThread(void* aFunction){
	SIMPLE_CALLBACK f = (SIMPLE_CALLBACK) aFunction;
	sleep(3);
	value = f(42);
}
#endif //FEATURE_THREADED_FFI

int getValue(){
	return value;
}

void callbackFromAnotherThread(SIMPLE_CALLBACK fun){
#if FEATURE_THREADED_FFI
	value = 0;
	pthread_t t;
	pthread_create(&t, NULL, otherThread, fun);
	pthread_detach(t);
#endif //FEATURE_THREADED_FFI
}
