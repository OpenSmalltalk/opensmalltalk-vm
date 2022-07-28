/****************************************************************************
*   PROJECT: Squeak 
*   FILE:    sqNamedPrims.c
*   CONTENT: Generic (cross platform) named primitive support
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*
*   NOTES:
*
*****************************************************************************/

#include "sq.h"
#include "sqAssert.h"

typedef struct {
  char *pluginName;
  char *primitiveName; /* N.B. On Spur metadata including the accessorDepth is hidden after the name's terminating null byte */
  void *primitiveAddress;
} sqExport;

#include "sqNamedPrims.h"

#undef DEBUG

#undef DPRINTF
// In practice these reasons are too important to hide. So if VM compiled with
// -DPRINT_DL_ERRORS=1 always print dlopen errors
#if defined(DEBUG)
# define DPRINTF(what) printf what
# define DERRPRINTF(what) printf what
#else
# define DPRINTF(what)
# if PRINT_DL_ERRORS
#	define DERRPRINTF(what) printf what
# else
#	define DERRPRINTF(what)
# endif
#endif

typedef struct ModuleEntry {
	struct ModuleEntry *next;
	void *handle;
	sqInt ffiLoaded;
	char name[1];
} ModuleEntry;


static ModuleEntry *squeakModule = NULL;
static ModuleEntry *firstModule = NULL;
struct VirtualMachine *sqGetInterpreterProxy(void);

static void *
findLoadedModule(char *pluginName)
{
	ModuleEntry *module = firstModule;
	if (!pluginName || !pluginName[0])
		return squeakModule;
	while (module) {
		if (!strcmp(module->name, pluginName))
			return module;
		module = module->next;
	}
	return NULL;
}

static ModuleEntry *
addToModuleList(char *pluginName, void *handle, sqInt ffiFlag)
{
	ModuleEntry *module;

	module = (ModuleEntry*) calloc(1, sizeof(ModuleEntry) + strlen(pluginName));
	strcpy(module->name, pluginName);
	module->handle = handle;
	module->ffiLoaded = ffiFlag;
	module->next = firstModule;
	firstModule = module;
	return firstModule;
}

/*
	removeFromList:
	Remove the given entry from the list of loaded modules.
	Do NOT free it yet.
*/
static sqInt
removeFromList(ModuleEntry *entry)
{
	/* Unlink the entry from the module chain */
	if (entry == firstModule) {
		firstModule = entry->next;
	}
	else {
		ModuleEntry *prevModule = firstModule;
		while (prevModule->next != entry)
			prevModule = prevModule->next;
		prevModule->next = entry->next;
	}
	return 1;
}

/*
	findExternalFunctionIn:
	Look up "pluginName_functionName" in the specified module through
	the OS dependent call. NEVER used to search through the internal
	primitive table.
*/
static void *
findExternalFunctionIn(char *functionName, ModuleEntry *module
#if SPURVM
# define NADA , 0, 0
					,  sqInt fnameLength, sqInt *metadataPtr
#else
# define NADA /* nada */
#endif
)
{
	void *result;

	DPRINTF(("Looking (externally) for %s in %s... ", functionName,module->name));
	if (module->handle)
#if SPURVM
		result = ioFindExternalFunctionInMetadataInto(functionName, module->handle, metadataPtr);
#else
		result = ioFindExternalFunctionIn(functionName, module->handle);
#endif
	else
		result = NULL;
	DPRINTF(("%s\n", result ? "found" : "not found"));
	return result;
}

/*
	findInternalFunctionIn:
	Lookup the given "pluginName_functionName" in the internal primitive table.
	On SPUR also get the metadata, hidden after functionName, if asked for.
*/
static void *
findInternalFunctionIn(char *functionName, char *pluginName
#if SPURVM
					,  sqInt fnameLength, sqInt *metadataPtr
#endif
)
{
  sqInt listIndex, index;
  sqExport *exports;

  DPRINTF(("Looking (internally) for %s in %s ... ",
          functionName, (pluginName ? pluginName : "<intrinsic>")));

  if (!functionName || !functionName[0])
    return NULL;

  /* canonicalize pluginName to be NULL if not specified */
  if (pluginName && !pluginName[0]) pluginName = NULL;

  for (listIndex=0; (exports = pluginExports[listIndex]); listIndex++) {
    char *plugin = exports[0].pluginName;

    /* canonicalize plugin to be NULL if not specified */
    if (plugin && !plugin[0]) plugin = NULL;
    /* check for module name match */
    if (!pluginName != !plugin)
      continue; /* one is missing */
    if (plugin && strcmp(pluginName, plugin))
      continue; /* name mismatch */

    for (index=0;; index++) {
      char *function = exports[index].primitiveName;
      if (!function || !function[0]) break; /* At end of table. */

      assert(exports[0].pluginName == exports[index].pluginName);

      /* check for function name match */
      if (strcmp(functionName, function))
        continue; /* name mismatch */

      /* match */
      DPRINTF(("found\n"));
#if SPURVM
      if (metadataPtr)
        *metadataPtr = (SpurPrimitiveMetadataType)
                          ((((signed char *)function)[fnameLength+1] << 8)
                        + ((unsigned char *)function)[fnameLength+2]);
#endif
      return exports[index].primitiveAddress;
    }
  }
  DPRINTF(("not found\n"));
  return NULL;
}


#if SPURVM
static void *
findFunctionAndMetadataIn(char *functionName, ModuleEntry *module,
								sqInt fnameLength, sqInt *metadataPtr)
{
	return module->handle == squeakModule->handle
		? findInternalFunctionIn(functionName, module->name,
								fnameLength, metadataPtr)
		: findExternalFunctionIn(functionName, module,
								fnameLength, metadataPtr);
}
#endif /* SPURVM */

static void *
findFunctionIn(char *functionName, ModuleEntry *module)
{
	return module->handle == squeakModule->handle
		? findInternalFunctionIn(functionName, module->name NADA)
		: findExternalFunctionIn(functionName, module NADA);
}

/*
	callInitializersIn:
	Call the required initializers in the given module.
	The module has been loaded before so the task is to
	call a) setInterpreter() and check its return, and
	b) initialiseModule (if defined) and check its return
	as well.
*/
static sqInt
callInitializersIn(ModuleEntry *module)
{
	char *moduleName;
	sqInt okay;
	void *init0 = findFunctionIn("getModuleName", module);
	void *init1 = findFunctionIn("setInterpreter", module);
	void *init2 = findFunctionIn("initialiseModule", module);

	if (init0) {
		/* Check the compiled name of the module */
		moduleName = ((char* (*) (void))init0)();
		if (!moduleName) {
			DERRPRINTF(("ERROR: getModuleName() returned NULL\n"));
			return 0;
		}
		if (strncmp(moduleName, module->name, strlen(module->name)) != 0) {
			DERRPRINTF(("ERROR: getModuleName returned %s (expected: %s)\n", moduleName, module->name));
			return 0;
		}
	}
	else {
		/* Note: older plugins may not export the compiled module name */
		DPRINTF(("WARNING: getModuleName() not found in %s\n", module->name));
	}
	if (!init1) { 
		DERRPRINTF(("ERROR: setInterpreter() not found\n"));
		return 0;
	}
	/* call setInterpreter */
	okay = ((sqInt (*) (struct VirtualMachine*))init1)(sqGetInterpreterProxy());
	if (!okay) {
		DERRPRINTF(("ERROR: setInterpreter() returned false\n"));
		return 0;
	}
	if (init2) {
		okay = ((sqInt (*) (void)) init2)();
		if (!okay) {
			DERRPRINTF(("ERROR: initialiseModule() returned false\n"));
			return 0;
		}
	}
	DPRINTF(("SUCCESS: Module %s is now initialized\n", module->name));
	return 1;
}

/*
	findAndLoadModule:
	Find the module with the given name by,
	* first looking it up in some (external) shared library
	* then, by trying to find pluginName_setInterpreter.
	If the module is found and the initialisers work, add it
	to the list of loaded modules and return the new module.
	If anything goes wrong make sure the module is unloaded
	(WITHOUT calling shutdownModule()) and return NULL.
*/

#ifdef PharoVM
static int moduleLoadingEnabled = 1;

/* Disable module loading mechanism for the rest of current session.
 * This operation should be not reversable!
 */
void ioDisableModuleLoading() {
	moduleLoadingEnabled = 0;
}
#endif

extern char *breakSelector;
extern sqInt breakSelectorLength;

static ModuleEntry *
findAndLoadModule(char *pluginName, sqInt ffiLoad)
{
	void *handle;
	ModuleEntry *module;

#ifdef PharoVM
	if (!moduleLoadingEnabled)
		return NULL;
#endif
	DPRINTF(("Looking for plugin %s\n", (pluginName ? pluginName : "<intrinsic>")));
	if (breakSelectorLength > 0
	 && !strncmp(pluginName, breakSelector, breakSelectorLength)
	 && strlen(pluginName) == breakSelectorLength)
		warning("plugin load");

	/* Try to load the module externally */
	handle = ioLoadModule(pluginName);
	if (ffiLoad) {
		/* When dealing with the FFI, don't attempt to mess around internally */
		if (!handle)
			return NULL;
		return addToModuleList(pluginName, handle, ffiLoad);
	}
	/* NOT ffiLoad */
	if (!handle) {
		/* might be internal, so go looking for setInterpreter() */
		if (!findInternalFunctionIn("setInterpreter", pluginName NADA))
			return NULL; /* PluginName_setInterpreter() not found */
		handle = squeakModule->handle;
	}
	module = addToModuleList(pluginName, handle, ffiLoad);
	if (!callInitializersIn(module)) {
		/* Initializers failed */
		if (handle != squeakModule->handle) /* physically unload module */
			ioFreeModule(handle);
		removeFromList(module); /* remove list entry */
		free(module); /* give back space */
		module = NULL;
	}
	return module;
}

/* findOrLoadModule:
	Look if the given module is already loaded. 
	If so, return its handle, otherwise try to load it.
*/
static ModuleEntry *
findOrLoadModule(char *pluginName, sqInt ffiLoad)
{
	ModuleEntry *module;

	if (!squeakModule) {
		/* Load intrinsics (if possible) */
		squeakModule = addToModuleList("", NULL, 1);
		firstModule = NULL; /* drop off module list - will never be unloaded */
	}

	/* see if the module was already loaded */
	module = findLoadedModule(pluginName);
	if (!module) /* if not try loading it */
		module = findAndLoadModule(pluginName, ffiLoad);
	return module; /* module not found */
}

/* ioLoadFunctionFrom:
	Load and return the given function from the specified plugin.
	Return the function address if successful, otherwise 0.
	This entry point is called from the interpreter proxy.
*/
void *
ioLoadFunctionFrom(char *functionName, char *pluginName)
{
	ModuleEntry *module = findOrLoadModule(pluginName, 0);
	if (!module) {
		/* no module */
		DERRPRINTF(("Failed to find %s (module %s was not loaded)\n", functionName, pluginName));
		return 0;
	}
	if (!functionName)
		/* only the module was requested but not any specific function */
	  return (void *)1;
	/* and load the actual function */
	return findFunctionIn(functionName, module);
}

/* ioLoadExternalFunctionOfLengthFromModuleOfLength
	Entry point for functions looked up through the VM.
*/
void *
ioLoadExternalFunctionOfLengthFromModuleOfLength
	(sqInt functionNameIndex, sqInt functionNameLength,
	 sqInt moduleNameIndex, sqInt moduleNameLength)
{
	char *functionNamePointer = pointerForOop((usqInt)functionNameIndex);
	char *moduleNamePointer = pointerForOop((usqInt)moduleNameIndex);
	char functionName[256], moduleName[256];

	if (functionNameLength > 255 || moduleNameLength > 255)
		return 0; /* can't cope with those */
	strncpy(functionName, functionNamePointer, functionNameLength);
	functionName[functionNameLength] = 0;
	strncpy(moduleName, moduleNamePointer, moduleNameLength);
	moduleName[moduleNameLength] = 0;
	return ioLoadFunctionFrom(functionName, moduleName);
}

#if SPURVM
/* ioLoadFunctionFromMetadataInto
	Load and return the given function from the specified plugin.
	Answer the function address if successful, otherwise 0.
	Assign the primitive's accessor depth and flags through metadataPtr.
	This entry point is called from the interpreter proxy.
*/
static void *
ioLoadFunctionFromMetadataInto(char *functionName, char *pluginName,
									sqInt fnameLength, sqInt *metadataPtr)
{
	ModuleEntry *module;
	void *function;

	module = findOrLoadModule(pluginName, 0);
	if (!module) {
		/* no module */
		DERRPRINTF(("Failed to find %s (module %s was not loaded)\n", functionName, pluginName));
		return 0;
	}
	if (!functionName)
		/* only the module was requested but not any specific function */
	  return (void *)1;
	/* and load the actual function */
	function = findFunctionAndMetadataIn(functionName, module, fnameLength, metadataPtr);
	return function;
}

/* ioLoadExternalFunctionOfLengthFromModuleOfLengthMetadataInto
	Entry point for functions looked up through the VM.
*/
void *
ioLoadExternalFunctionOfLengthFromModuleOfLengthMetadataInto
	(sqInt functionNameIndex, sqInt functionNameLength,
	 sqInt moduleNameIndex,   sqInt moduleNameLength, sqInt *metadataPtr)
{
	char *functionNamePointer = pointerForOop((usqInt)functionNameIndex);
	char *moduleNamePointer = pointerForOop((usqInt)moduleNameIndex);
	char functionName[256], moduleName[256];

	if (functionNameLength > 255 || moduleNameLength > 255)
		return 0; /* can't cope with those */
	strncpy(functionName, functionNamePointer, functionNameLength);
	functionName[functionNameLength] = 0;
	strncpy(moduleName, moduleNamePointer, moduleNameLength);
	moduleName[moduleNameLength] = 0;
	return ioLoadFunctionFromMetadataInto
			(functionName, moduleName, functionNameLength, metadataPtr);
}
#endif /* SPURVM */

/* ioLoadSymbolOfLengthFromModule
	This entry point is exclusively for the FFI.
*/
#ifdef PharoVM
#  define IO_LOAD_GLOBAL(fn) ioLoadFunctionFrom(fn, "")
#else 
#  define IO_LOAD_GLOBAL(fn) 0 
#endif
void *
ioLoadSymbolOfLengthFromModule(sqInt functionNameIndex, sqInt functionNameLength, void *moduleHandle)
{
	char *functionNamePointer = pointerForOop((usqInt)functionNameIndex);
	char functionName[256];

	if (functionNameLength > 255)
		return 0; /* can't cope with those */
	strncpy(functionName, functionNamePointer, functionNameLength);
	functionName[functionNameLength] = 0;
	// Interpret a tagged pointer as a short-hand for an internal plugin
	// e.g. the SqueakFFIPrims module as an internal plugin where access to
	// the test functions is required.
	if (((sqInt)moduleHandle & 1))
		return findInternalFunctionIn
					(functionName, 
					&(((ModuleEntry *)((sqInt)moduleHandle - 1))->name[0])
					NADA);
	return moduleHandle
		? ioFindExternalFunctionIn(functionName, moduleHandle)
		: IO_LOAD_GLOBAL(functionName);
}

/* ioLoadModuleOfLength
	This entry point is exclusively for the FFI.
	It does *NOT* call any of the initializers nor
	does it attempt to lookup stuff internally.
	It answers internal plugins as a tagged pointer.
*/
void *
ioLoadModuleOfLength(sqInt moduleNameIndex, sqInt moduleNameLength)
{
	ModuleEntry *module;
	char *moduleNamePointer= pointerForOop((usqInt)moduleNameIndex);
	char moduleName[256];

	if (moduleNameLength > 255)
		return 0; /* can't cope with those */
	strncpy(moduleName, moduleNamePointer, moduleNameLength);
	moduleName[moduleNameLength] = 0;

	module = findOrLoadModule(moduleName, 1);
	if (module)
		return module->handle
				? module->handle
				: (void *)((sqInt)module + 1);
	return 0;
}


/* shutdownModule:
	Call the shutdown mechanism from the specified module.
*/
static sqInt
shutdownModule(ModuleEntry *module)
{
	void *fn;

	if (module->ffiLoaded)
		return 1; /* don't even attempt for ffi loaded modules */

	/* load the actual function */
	fn = findFunctionIn("shutdownModule", module);
	if (fn)
		return ((sqInt (*) (void)) fn) ();
	return 1;
}

/* ioShutdownAllModules:
	Call the shutdown mechanism for all loaded modules.
*/
sqInt
ioShutdownAllModules(void)
{
	ModuleEntry *entry = firstModule;
	while (entry) {
		(void)shutdownModule(entry);
		entry = entry->next;
	}
	return 1;
}

/* ioUnloadModule:
	Unload the module with the given name.
*/
sqInt
ioUnloadModule(char *moduleName)
{
	ModuleEntry *entry, *temp;

	if (!squeakModule)
		return 0; /* Nothing has been loaded */
	if (!moduleName || !moduleName[0])
		return 0; /* nope */

	entry = findLoadedModule(moduleName);
	if (!entry)
		return 1; /* module was never loaded */

	/* Try to shutdown the module */
	if (!shutdownModule(entry))
		/* Could not shut down the module. Bail out. */
		return 0;

	/* Notify all interested parties about the fact */
	temp = firstModule;
	while (temp) {
		if (temp != entry) {
			/* Lookup moduleUnloaded: from the plugin */
			void *fn = findFunctionIn("moduleUnloaded", temp);
			if (fn) /* call it */
				((sqInt (*) (char *))fn)(entry->name);
		}
		temp = temp->next;
	}
	/* And actually unload it if it isn't just the VM... */
	if (entry->handle != squeakModule->handle)
		ioFreeModule(entry->handle);
	removeFromList(entry);
	free(entry); /* give back space */
	return 1;
}

/* ioUnloadModuleOfLength:
	Entry point for the interpreter.
*/
sqInt
ioUnloadModuleOfLength(sqInt moduleNameIndex, sqInt moduleNameLength)
{
	char *moduleNamePointer = pointerForOop((usqInt) moduleNameIndex);
	char moduleName[256];

	if (moduleNameLength > 255)
		return 0; /* can't cope with those */
	strncpy(moduleName, moduleNamePointer, moduleNameLength);
	moduleName[moduleNameLength] = 0;
	return ioUnloadModule(moduleName);
}

/* ioListBuiltinModule:
	Return the name of the n-th builtin module.
*/

char *
ioListBuiltinModule(sqInt moduleIndex)
{
  sqInt index, listIndex;

  for (listIndex=0;; listIndex++) {
    sqExport * exports = pluginExports[listIndex];
    if (!exports) break;
    for (index=0;; index++) {
      char *plugin = exports[index].pluginName;
      char *function = exports[index].primitiveName;
      if (!function && !plugin) break; /* no more plugins */
      if (!strcmp(function,"setInterpreter")
       && --moduleIndex == 0) {
          char *moduleName;
          void * init0;
          init0 = findInternalFunctionIn("getModuleName", plugin NADA);
          if (init0) {
            /* Check the compiled name of the module */
            moduleName = ((char* (*) (void))init0)();
            if (moduleName)
				return moduleName;
          }
          return plugin;
      }
    }
  }
  return NULL;
}

char *
ioListLoadedModule(sqInt moduleIndex)
{
	sqInt index = 1;
	ModuleEntry *entry = firstModule;

	if (moduleIndex < 1)
		return NULL;
	while (entry && index < moduleIndex) {
		entry = entry->next;
		index = index + 1;
	}
	if (entry) {
		void *init0 = findFunctionIn("getModuleName", entry);
		if (init0) {
			/* Check the compiled name of the module */
			char *moduleName = ((char* (*) (void))init0)();
			if (moduleName)
				return moduleName;
		}
		return entry->name;
	}
	return NULL;
}
