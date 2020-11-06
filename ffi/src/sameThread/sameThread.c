#include "setjmp.h"

#include "pThreadedFFI.h"
#include "vmCallback.h"
#include "pharovm/macros.h"

/*
 * Define sigsetjmp and siglongjmp to be the most minimal setjmp/longjmp available on the platform.
 * Note: on windows 64 via mingw-w64, the 2nd argument NULL to _setjmp prevents stack unwinding
 */
#undef sigsetjmp
#undef siglongjmp
#if _MSC_VER
# define sigsetjmp(jb,ssmf) _setjmp(jb)
# define siglongjmp(jb,v) longjmp(jb,v)
#elif _WIN64 && __GNUC__
# define sigsetjmp(jb,ssmf) _setjmp(jb,NULL)
# define siglongjmp(jb,v) longjmp(jb,v)
#elif _WIN32
# define sigsetjmp(jb,ssmf) setjmp(jb)
# define siglongjmp(jb,v) longjmp(jb,v)
#else
# define sigsetjmp(jb,ssmf) _setjmp(jb)
# define siglongjmp(jb,v) _longjmp(jb,v)
#endif

void sameThreadCallbackEnter(struct _Runner* runner, struct _CallbackInvocation* callback);
void sameThreadCallbackExit(struct _Runner* runner, struct _CallbackInvocation* callback);
void sameThreadPrepareCallback(struct _Runner* runner, struct _CallbackInvocation* callback);

static Runner sameThreadRunner = {
	sameThreadCallbackEnter,
	sameThreadCallbackExit,
	sameThreadPrepareCallback,
    NULL
};

Primitive(primitiveGetSameThreadRunnerAddress) {

	sqInt externalAddress;

	externalAddress = instantiateClassindexableSize(classExternalAddress(), sizeof(void*));
    checkFailed();

    writeAddress(externalAddress, &sameThreadRunner);
    checkFailed();

    primitiveEndReturn(externalAddress);
}

void sameThreadCallbackEnter(struct _Runner* runner, struct _CallbackInvocation* callback){

	VMCallbackContext *vmcc;
	sqInt flags;

//	if ((flags = ownVM(0)) < 0) {
//		fprintf(stderr,"Warning; callback failed to own the VM\n");
//		return;
//	}

	vmcc = malloc(sizeof(VMCallbackContext));

	callback->payload = vmcc;

	if ((!sigsetjmp(vmcc->trampoline, 0))) {
		//Used to mark that is a fake callback!
		vmcc->thunkp = NULL;
		vmcc->stackp = NULL;
		vmcc->intregargsp = NULL;
		vmcc->floatregargsp = NULL;
		ptEnterInterpreterFromCallback(vmcc);
		fprintf(stderr,"Warning; callback failed to invoke\n");
//		disownVM(flags);
		return;
	}

	free(vmcc);

//	disownVM(flags);
}

void sameThreadCallbackExit(struct _Runner* runner, struct _CallbackInvocation* callback){

	VMCallbackContext *vmcc;
	vmcc = (VMCallbackContext*)callback->payload;

	ptExitInterpreterToCallback(vmcc);
}

void sameThreadPrepareCallback(struct _Runner* runner, struct _CallbackInvocation* callback){
	// I do not do nothing
}
