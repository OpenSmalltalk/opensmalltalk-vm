/* This is an automatically generated table of all builtin modules in the VM */

extern sqExport vm_exports[];
extern sqExport os_exports[];
extern sqExport B2DPlugin_exports[];
extern sqExport BitBltPlugin_exports[];
extern sqExport FilePlugin_exports[];
extern sqExport SocketPlugin_exports[];

sqExport *pluginExports[] = {
	vm_exports,
	os_exports,
	B2DPlugin_exports,
	BitBltPlugin_exports,
	FilePlugin_exports,
	SocketPlugin_exports,
	NULL
};
