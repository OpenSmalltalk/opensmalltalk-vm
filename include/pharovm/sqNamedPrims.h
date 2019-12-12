extern sqExport vm_exports[];
extern sqExport os_exports[];

sqExport *pluginExports[] = {
	vm_exports,
	os_exports,
//	SecurityPlugin_exports,
	NULL
};
