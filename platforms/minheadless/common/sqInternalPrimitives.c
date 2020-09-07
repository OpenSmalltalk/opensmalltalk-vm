#include <assert.h>
#include <stdlib.h>
#include <time.h>
#include "sq.h"
#include "sqaio.h"
#include "sqMemoryAccess.h"
#include "sqWindow.h"

static int pluginExportsCapacity = 0;
static int pluginExportsSize = 0;

static void *emptyPluginExports[] = {
    NULL
};

void **pluginExports = emptyPluginExports;
extern void *vm_exports[];
extern void *os_exports[];

#define INTERNAL_PLUGIN(pluginName) \
	extern void *pluginName ## _exports[];
#include "sqInternalPlugins.inc"

#undef INTERNAL_PLUGIN

static void
increaseCapacity()
{
    int newCapacity;
    void **newPluginExports;
    int i;

    /* Compute the new capacity. */
    newCapacity = pluginExportsCapacity*2;
    if(newCapacity < 8)
        newCapacity = 8;

    /* Allocate the plugin export list. */
    newPluginExports = (void**)calloc(newCapacity + 1, sizeof(void*));

    /* Copy the old elements to the new list. */
    for(i = 0; i < pluginExportsSize; ++i)
        newPluginExports[i] = pluginExports[i];

    /* Free the old list. */
    if(pluginExports && pluginExports != emptyPluginExports)
        free(pluginExports);

    /* Use the new capacity and the new list. */
    pluginExportsCapacity = newCapacity;
    pluginExports = newPluginExports;
}

void
ioAddInternalPluginPrimitives(void *primitiveList)
{
    if(pluginExportsSize >= pluginExportsCapacity)
        increaseCapacity();

    pluginExports[pluginExportsSize++] = primitiveList;
}

void
ioInitializeInternalPluginPrimitives(void)
{
    ioAddInternalPluginPrimitives(vm_exports);
    ioAddInternalPluginPrimitives(os_exports);

    #define INTERNAL_PLUGIN(pluginName) \
    	ioAddInternalPluginPrimitives(pluginName ## _exports);
    #include "sqInternalPlugins.inc"

    #undef INTERNAL_PLUGIN
}
