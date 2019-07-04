extern sqExport vm_exports[];
extern sqExport os_exports[];
//extern sqExport ADPCMCodecPlugin_exports[];

sqExport *pluginExports[] = {
	vm_exports,
	os_exports,
//	ADPCMCodecPlugin_exports,
	NULL
};
