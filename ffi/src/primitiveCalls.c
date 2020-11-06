#include "pThreadedFFI.h"
#include "pharovm/macros.h"

/**
 * primitivePrepareParameters: aParameterArray into: aParameterAddress prepareReturn: aReturnHodler into: aReturnAddress
 *
 * This primitive receives an array of byteArrays that will be sent as parameters.
 * It requires that the elements in the parameterArray and the returnHolder are pinned.
 * It will allocate a vector* for putting the addresses of the elements
 *
 * It receives three parameters:
 *
 * - aParameterArray: an Array of Objects as parameters to the function. Nil if there is no parameters.
 * - aParameterAddress: A external address to put the allocated structure
 * - aReturnHodler: a ByteArray where the return of the function will be put
 * - aReturnAddress: A external addres to put the address of the byteArray.
 */
PrimitiveWithDepth(primitivePrepareParametersForCall, 2){

	sqInt aParameterArray;
	sqInt aParameterAddress;
	sqInt aReturnHodler;
	sqInt aReturnAddress;
	sqInt count;
	sqInt idx;

	sqInt anObject;

	void** parameters;

	aReturnAddress = stackValue(0);
	checkFailed();

	aReturnHodler = stackValue(1);
	checkFailed();

	aParameterAddress = stackValue(2);
	checkFailed();

	aParameterArray = stackValue(3);
	checkFailed();


	// We validate that the passed return holder is pinned, and we copy the address to the external address

	if(!isPinned(aReturnHodler)){
		primitiveFail();
		return;
	}

	writeAddress(aReturnAddress, (void*) (aReturnHodler + BaseHeaderSize));
	checkFailed();

	// If the parameter array is nil, there are no parameters to send.
	if(aParameterArray == nilObject()){
		writeAddress(aParameterAddress, NULL);
		checkFailed();

		primitiveEnd();
		return;
	}

	count = stSizeOf(aParameterArray);
	checkFailed();

	parameters = malloc(count*sizeof(void*));

	for (idx = 0; idx < count; idx += 1) {
		anObject = stObjectat(aParameterArray, idx + 1);

		if(!isPinned(anObject)){
			free(parameters);
			primitiveFail();
			return;
		}

		parameters[idx] = (void*) (anObject + BaseHeaderSize);
	}

	writeAddress(aParameterAddress, parameters);
	if(failed()){
		free(parameters);
		primitiveFail();
		return;
	}

	primitiveEnd();
}

/**
 * This primitive releases the parameters allocated by primitivePrepareParametersForCall
 *
 * primitiveReleaseParameters: aParameterArrayAddress releaseReturn: aReturnAddress
 *
 * - aParameterArrayAddress an external address with the call structure to release.
 * - aReturnAddress an external address with the address of the return address holder.
 *
 */
PrimitiveWithDepth(primitiveReleaseParametersForCall, 2){

	sqInt aParameterArrayAddress;
	sqInt aReturnAddress;

	void* parameters;

	aReturnAddress = stackValue(0);
	checkFailed();

	aParameterArrayAddress = stackValue(1);
	checkFailed();

	parameters = readAddress(aParameterArrayAddress);
	checkFailed();

	if(parameters){
		free(parameters);
	}

	primitiveEnd();
}
