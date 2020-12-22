#include "callbacks.h"

SIMPLE_CALLBACK registeredCallback;

void registerCallback(SIMPLE_CALLBACK fun){
	registeredCallback = fun;
}

int registeredCallbackInALoop(){
	int i;
	int acc = 0;
	
	for(i=0;i<42;i++){
		acc = registeredCallback(acc);
	}
	
	return acc;
}

int reentringRegisteredCallback(int base){
	printf("Value entered: %d\n", base);

	if(base == 0)
		return 1;

	return registeredCallback(base);
}