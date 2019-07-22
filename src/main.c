#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>

#include <pharoClient.h>
#include <pharo.h>

typedef struct {
  char *pluginName;
  char *primitiveName; /* N.B. On Spur the accessorDepth is hidden after this */
  void *primitiveAddress;
} sqExport;

extern sqExport* vm_exports;
extern sqExport* os_exports;

extern sqExport* SecurityPlugin_exports;
extern sqExport* FilePlugin_exports;
extern sqExport* FileAttributesPlugin_exports;
extern sqExport* UUIDPlugin_exports;
extern sqExport* SocketPlugin_exports;
extern sqExport* SurfacePlugin_exports;
extern sqExport* SqueakFFIPrims_exports;
extern sqExport* IA32ABI_exports;
extern sqExport* LargeIntegers_exports;
extern sqExport* MiscPrimitivePlugin_exports;
extern sqExport* BitBltPlugin_exports;
extern sqExport* LocalePlugin_exports;
extern sqExport* MD5Plugin_exports;
extern sqExport* SqueakSSL_exports;
extern sqExport* DSAPrims_exports;

extern sqExport** pluginExports;

void initInternalPlugins(){

	sqExport** posta;

	posta = malloc(sizeof(sqExport*) * 18);
	posta[0] = &vm_exports;
	posta[1] = &os_exports;

	posta[2] = &SecurityPlugin_exports;
	posta[3] = &FilePlugin_exports;
	posta[4] = &FileAttributesPlugin_exports;
	posta[5] = &UUIDPlugin_exports;
	posta[6] = &SocketPlugin_exports;
	posta[7] = &SurfacePlugin_exports;
	posta[8] = &SqueakFFIPrims_exports;
	posta[9] = &IA32ABI_exports;
	posta[10] = &LargeIntegers_exports;
	posta[11] = &MiscPrimitivePlugin_exports;
	posta[12] = &BitBltPlugin_exports;
	posta[13] = &LocalePlugin_exports;
	posta[14] = &MD5Plugin_exports;
	posta[15] = &SqueakSSL_exports;
	posta[16] = &DSAPrims_exports;

	posta[17] = NULL;

	pluginExports = posta;
}

int main(int argc, char* argv[]){

	VM_PARAMETERS parameters;
	char buffer[4096+1];

	initInternalPlugins();

	parseArguments(argc, argv, &parameters);

	logInfo("Opening Image: %s\n", parameters.imageFile);

	getcwd(buffer, sizeof(buffer));
	logDebug("Working Directory %s", buffer);


	LOG_SIZEOF(int);
	LOG_SIZEOF(long);
	LOG_SIZEOF(long long);
	LOG_SIZEOF(void*);
	LOG_SIZEOF(sqInt);
	LOG_SIZEOF(sqLong);
	LOG_SIZEOF(float);
	LOG_SIZEOF(double);

	if(!initPharoVM(parameters.imageFile, parameters.vmParams, parameters.vmParamsCount, parameters.imageParams, parameters.imageParamsCount)){
		logError("Error opening image file: %s\n", parameters.imageFile);
		return -1;
	}
	runInterpreter();
}

void printVersion(){
	printf("%s\n", getVMVersion());
	printf("Built from: %s\n", getSourceVersion());
}
