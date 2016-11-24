/* This is an automatically generated table of all builtin modules in the VM
   CoInterpreterPrimitives VMMaker.oscog-eem.497
 */

extern sqExport vm_exports[];
extern sqExport os_exports[];
extern sqExport winsys_exports[];

#define INTERNAL_PLUGIN(pluginName) \
	extern sqExport pluginName ## _exports[];
#include "sqInternalPlugins.inc"

#undef INTERNAL_PLUGIN
#define INTERNAL_PLUGIN(pluginName) \
	pluginName ## _exports,

sqExport *pluginExports[] = {
	vm_exports,
	os_exports,
	winsys_exports,

#include "sqInternalPlugins.inc"

	NULL
};
