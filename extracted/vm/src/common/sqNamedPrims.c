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

typedef struct {
  char *pluginName;
  char *primitiveName; /* N.B. On Spur the accessorDepth is hidden after this */
  void *primitiveAddress;
} sqExport;

#include "sqNamedPrims.h"

#undef DEBUG

#undef DPRINTF
#ifdef DEBUG
# define DPRINTF(what) printf what
#else
# define DPRINTF(what)
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
	ModuleEntry *module;
	if(!pluginName || !pluginName[0]) return squeakModule;
	module = firstModule;
	while(module) {
		if(strcmp(module->name, pluginName) == 0) return module;
		module = module->next;
	}
	return NULL;
}

static ModuleEntry *
addToModuleList(char *pluginName, void* handle, sqInt ffiFlag)
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
	ModuleEntry *prevModule;

	/* Unlink the entry from the module chain */
	if(entry == firstModule) {
		firstModule = entry->next;
	} else {
		prevModule = firstModule;
		while(prevModule->next != entry)
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
					,  sqInt fnameLength, sqInt *accessorDepthPtr
#else
# define NADA /* nada */
#endif
)
{
	void *result;

	DPRINTF(("Looking (externally) for %s in %s... ", functionName,module->name));
	if(module->handle)
#if SPURVM
		result = ioFindExternalFunctionInAccessorDepthInto(functionName, module->handle, accessorDepthPtr);
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
	Lookup the given "pluginName_functionName" in the internal
	primitive table. If it can not be found try to look it up
	by using the OS dependent mechanism (see comment below).
	On SPUR also get accessorDepth, hidden in functionName, if asked for.
*/
static void *
findInternalFunctionIn(char *functionName, char *pluginName
#if SPURVM
					,  sqInt fnameLength, sqInt *accessorDepthPtr
#endif
)
{
  char *function, *plugin;
  sqInt listIndex, index;
  sqExport *exports;

  DPRINTF(("Looking (internally) for %s in %s ... ", functionName, (pluginName ? pluginName : "<intrinsic>")));

  /* canonicalize functionName and pluginName to be NULL if not specified */
  if(functionName && !functionName[0]) functionName = NULL;
  if(pluginName && !pluginName[0]) pluginName = NULL;
  for(listIndex=0;; listIndex++) {
    exports = pluginExports[listIndex];
    if(!exports) break;
    for(index=0;; index++) {
      plugin = exports[index].pluginName;
      function = exports[index].primitiveName;
      /* canonicalize plugin and function to be NULL if not specified */
      if(plugin && !plugin[0]) plugin = NULL;
      if(function && !function[0]) function = NULL;
      if(!plugin && !function) break; /* At end of table. */
      /* check for module name match */
      if((pluginName == NULL) != (plugin == NULL)) continue; /* one is missing */
      if(plugin && strcmp(pluginName, plugin)) continue; /* name mismatch */
      /* check for function name match */
      if((functionName == NULL) != (function == NULL)) continue; /* one is missing */
      if(function && strcmp(functionName, function)) continue; /* name mismatch */

      /* match */
      DPRINTF(("found\n"));
#if SPURVM
	  if (accessorDepthPtr)
		*accessorDepthPtr = ((signed char *)function)[fnameLength+1];
#endif
      return exports[index].primitiveAddress;
    }
  }
  DPRINTF(("not found\n"));
  return NULL;
}


#if SPURVM
static void *
findFunctionAndAccessorDepthIn(char *functionName, ModuleEntry *module,
								sqInt fnameLength, sqInt *accessorDepthPtr)
{
	return module->handle == squeakModule->handle
		? findInternalFunctionIn(functionName, module->name,
								fnameLength, accessorDepthPtr)
		: findExternalFunctionIn(functionName, module,
								fnameLength, accessorDepthPtr);
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
	call a) setInterpreter() and check it's return, and
	b) initialiseModule (if defined) and check it's return
	as well.
*/
static sqInt
callInitializersIn(ModuleEntry *module)
{
	void *init0;
	void *init1;
	void *init2;
	char *moduleName;
	sqInt okay;

	init0 = findFunctionIn("getModuleName", module);
	init1 = findFunctionIn("setInterpreter", module);
	init2 = findFunctionIn("initialiseModule", module);

	if(init0) {
		/* Check the compiled name of the module */
		moduleName = ((char* (*) (void))init0)();
		if(!moduleName) {
			DPRINTF(("ERROR: getModuleName() returned NULL\n"));
			return 0;
		}
		if(strncmp(moduleName, module->name, strlen(module->name)) != 0) {
			DPRINTF(("ERROR: getModuleName returned %s (expected: %s)\n", moduleName, module->name));
			return 0;
		}
	} else {
		/* Note: older plugins may not export the compiled module name */
		DPRINTF(("WARNING: getModuleName() not found in %s\n", module->name));
	}
	if(!init1) { 
		DPRINTF(("ERROR: setInterpreter() not found\n"));
		return 0;
	}
	/* call setInterpreter */
	okay = ((sqInt (*) (struct VirtualMachine*))init1)(sqGetInterpreterProxy());
	if(!okay) {
		DPRINTF(("ERROR: setInterpreter() returned false\n"));
		return 0;
	}
	if(init2) {
		okay = ((sqInt (*) (void)) init2)();
		if(!okay) {
			DPRINTF(("ERROR: initialiseModule() returned false\n"));
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

/* Disable module loading mechanism for the rest of current session. This operation should be not reversable! */
void ioDisableModuleLoading() {
	moduleLoadingEnabled = 0;
}
#endif

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
	/* Try to load the module externally */
	handle = ioLoadModule(pluginName);
	if(ffiLoad) {
		/* When dealing with the FFI, don't attempt to mess around internally */
		if(!handle) return NULL;
		return addToModuleList(pluginName, handle, ffiLoad);
	}
	/* NOT ffiLoad */
	if(!handle) {
		/* might be internal, so go looking for setInterpreter() */
		if(findInternalFunctionIn("setInterpreter", pluginName NADA))
			handle = squeakModule->handle;
		else
			return NULL; /* PluginName_setInterpreter() not found */
	}
	module = addToModuleList(pluginName, handle, ffiLoad);
	if(!callInitializersIn(module)) {
		/* Initializers failed */
		if(handle != squeakModule->handle) {
			/* physically unload module */
			ioFreeModule(handle);
		}
		removeFromList(module); /* remove list entry */
		free(module); /* give back space */
		module = NULL;
	}
	return module;
}

/* findOrLoadModule:
	Look if the given module is already loaded. 
	If so, return it's handle, otherwise try to load it.
*/
static ModuleEntry *
findOrLoadModule(char *pluginName, sqInt ffiLoad)
{
	ModuleEntry *module;

	if(!squeakModule) {
		/* Load intrinsics (if possible) */
		squeakModule = addToModuleList("", NULL, 1);
		firstModule = NULL; /* drop off module list - will never be unloaded */
	}

	/* see if the module was already loaded */
	module = findLoadedModule(pluginName);
	if(!module) {
		/* if not try loading it */
		module = findAndLoadModule(pluginName, ffiLoad);
	}
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
	ModuleEntry *module;

	module = findOrLoadModule(pluginName, 0);
	if(!module) {
		/* no module */
		DPRINTF(("Failed to find %s (module %s was not loaded)\n", functionName, pluginName));
		return 0;
	}
	if(!functionName) {
		/* only the module was requested but not any specific function */
	  return (void *)1;
	}
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
	char *functionNamePointer= pointerForOop((usqInt)functionNameIndex);
	char *moduleNamePointer= pointerForOop((usqInt)moduleNameIndex);
	char functionName[256];
	char moduleName[256];

	if(functionNameLength > 255 || moduleNameLength > 255)
		return 0; /* can't cope with those */
	strncpy(functionName, functionNamePointer, functionNameLength);
	functionName[functionNameLength] = 0;
	strncpy(moduleName, moduleNamePointer, moduleNameLength);
	moduleName[moduleNameLength] = 0;
	return ioLoadFunctionFrom(functionName, moduleName);
}

#if SPURVM
/* ioLoadFunctionFromAccessorDepthInto
	Load and return the given function from the specified plugin.
	Answer the function address if successful, otherwise 0.
	Assign the primitive's accessor depth through accessorDepthPtr.
	This entry point is called from the interpreter proxy.
*/
static void *
ioLoadFunctionFromAccessorDepthInto(char *functionName, char *pluginName,
									sqInt fnameLength, sqInt *accessorDepthPtr)
{
	ModuleEntry *module;
	void *function;

	module = findOrLoadModule(pluginName, 0);
	if(!module) {
		/* no module */
		DPRINTF(("Failed to find %s (module %s was not loaded)\n", functionName, pluginName));
		return 0;
	}
	if(!functionName) {
		/* only the module was requested but not any specific function */
	  return (void *)1;
	}
	/* and load the actual function */
	function = findFunctionAndAccessorDepthIn(functionName, module, fnameLength, accessorDepthPtr);
	return function;
}

/* ioLoadExternalFunctionOfLengthFromModuleOfLengthAccessorDepthInto
	Entry point for functions looked up through the VM.
*/
void *
ioLoadExternalFunctionOfLengthFromModuleOfLengthAccessorDepthInto
	(sqInt functionNameIndex, sqInt functionNameLength,
	 sqInt moduleNameIndex,   sqInt moduleNameLength, sqInt *accessorDepthPtr)
{
	char *functionNamePointer= pointerForOop((usqInt)functionNameIndex);
	char *moduleNamePointer= pointerForOop((usqInt)moduleNameIndex);
	char functionName[256];
	char moduleName[256];

	if(functionNameLength > 255 || moduleNameLength > 255)
		return 0; /* can't cope with those */
	strncpy(functionName, functionNamePointer, functionNameLength);
	functionName[functionNameLength] = 0;
	strncpy(moduleName, moduleNamePointer, moduleNameLength);
	moduleName[moduleNameLength] = 0;
	return ioLoadFunctionFromAccessorDepthInto
			(functionName, moduleName, functionNameLength, accessorDepthPtr);
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
	return moduleHandle
		? ioFindExternalFunctionIn(functionName, moduleHandle)
		: IO_LOAD_GLOBAL(functionName);
}

/* ioLoadModuleOfLength
	This entry point is exclusively for the FFI.
	It does *NOT* call any of the initializers nor
	does it attempt to lookup stuff internally.
*/
void *
ioLoadModuleOfLength(sqInt moduleNameIndex, sqInt moduleNameLength)
{
	ModuleEntry *module;
	char *moduleNamePointer= pointerForOop((usqInt)moduleNameIndex);
	char moduleName[256];
	sqInt i;

	if(moduleNameLength > 255) return 0; /* can't cope with those */
	for(i=0; i< moduleNameLength; i++)
		moduleName[i] = moduleNamePointer[i];
	moduleName[moduleNameLength] = 0;

	module = findOrLoadModule(moduleName, 1);
	if(module) return module->handle;
	return 0;
}


/* shutdownModule:
	Call the shutdown mechanism from the specified module.
*/
static sqInt
shutdownModule(ModuleEntry *module)
{
	void* fn;

	if(module->ffiLoaded) return 1; /* don't even attempt for ffi loaded modules */

	/* load the actual function */
	fn = findFunctionIn("shutdownModule", module);
	if(fn) return ((sqInt (*) (void)) fn) ();
	return 1;
}

/* ioShutdownAllModules:
	Call the shutdown mechanism for all loaded modules.
*/
sqInt
ioShutdownAllModules(void)
{
	ModuleEntry *entry;
	entry = firstModule;
	while(entry) {
		shutdownModule(entry);
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

	if(!squeakModule) return 0; /* Nothing has been loaded */
	if(!moduleName || !moduleName[0]) return 0; /* nope */

	entry = findLoadedModule(moduleName);
	if(!entry) return 1; /* module was never loaded */

	/* Try to shutdown the module */
	if(!shutdownModule(entry)) {
		/* Could not shut down the module. Bail out. */
		return 0;
	}
	/* Notify all interested parties about the fact */
	temp = firstModule;
	while(temp) {
		if(temp != entry) {
			/* Lookup moduleUnloaded: from the plugin */
			void *fn = findFunctionIn("moduleUnloaded", temp);
			if(fn) {
				/* call it */
				((sqInt (*) (char *))fn)(entry->name);
			}
		}
		temp = temp->next;
	}
	/* And actually unload it if it isn't just the VM... */
	if(entry->handle != squeakModule->handle)
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
	char *moduleNamePointer= pointerForOop((usqInt) moduleNameIndex);
	char moduleName[256];
	sqInt i;

	if(moduleNameLength > 255) return 0; /* can't cope with those */
	for(i=0; i< moduleNameLength; i++)
		moduleName[i] = moduleNamePointer[i];
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
  char *function;
  char *plugin;
  sqExport *exports;

  for(listIndex=0;; listIndex++) {
    exports = pluginExports[listIndex];
    if(!exports) break;
    for(index=0;; index++) {
      plugin = exports[index].pluginName;
      function = exports[index].primitiveName;
      if(!function && !plugin) break; /* no more plugins */
      if(strcmp(function,"setInterpreter") == 0) {
	/* new module */
	if(--moduleIndex == 0) {
	  char *moduleName;
	  void * init0;
	  init0 = findInternalFunctionIn("getModuleName", plugin NADA);
	  if(init0) {
	    /* Check the compiled name of the module */
	    moduleName = ((char* (*) (void))init0)();
	    if(moduleName) { return moduleName;}
	  }
	  return plugin;
	}
      }
    }
  }
  return NULL;
}

char *
ioListLoadedModule(sqInt moduleIndex)
{
	sqInt index = 1;

	ModuleEntry *entry;
	entry = firstModule;

	if ( moduleIndex < 1) return (char*)NULL;
	while(entry && index < moduleIndex) {
		entry = entry->next;
		index = index + 1;
	}
	if ( entry ) {
		char *moduleName;
		void * init0;

		init0 = findFunctionIn("getModuleName", entry);
		if(init0) {
			/* Check the compiled name of the module */
			moduleName = ((char* (*) (void))init0)();
			if(moduleName) { return moduleName;}
		}
		return entry->name;
	}
	else return (char*)NULL;
}
