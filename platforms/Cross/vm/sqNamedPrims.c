/****************************************************************************
*   PROJECT: Squeak 
*   FILE:    sqNamedPrims.c
*   CONTENT: Generic (cross platform) named primitive support
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*   RCSID:   $Id: sqNamedPrims.c,v 1.2 2002/05/09 01:36:50 rowledge Exp $
*
*   NOTES:
*
*****************************************************************************/
#include "sq.h"


typedef struct {
  char *pluginName;
  char *primitiveName;
  void *primitiveAddress;
} sqExport;

#include "sqNamedPrims.h"

#ifdef DEBUG
#define dprintf(what) printf what
#else
#define dprintf(what)
#endif

typedef struct ModuleEntry {
	struct ModuleEntry *next;
	void *handle;
	int ffiLoaded;
	char name[1];
} ModuleEntry;


static ModuleEntry *squeakModule = NULL;
static ModuleEntry *firstModule = NULL;
struct VirtualMachine *sqGetInterpreterProxy(void);

static void *findLoadedModule(char *pluginName)
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

static ModuleEntry *addToModuleList(char *pluginName, void* handle, int ffiFlag)
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
static int removeFromList(ModuleEntry *entry)
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
static void *findExternalFunctionIn(char *functionName, ModuleEntry *module)
{
	void *result;

	dprintf(("Looking (externally) for %s in %s... ", functionName,module->name));
	if(module->handle)
		result = (void*) ioFindExternalFunctionIn(functionName, (int) module->handle);
	else
		result = NULL;
	dprintf(("%s\n", result ? "found" : "not found"));
	return result;
}

/*
	findInternalFunctionIn:
	Lookup the given "pluginName_functionName" in the internal
	primitive table. If it can not be found try to look it up
	by using the OS dependent mechanism (see comment below).
*/
static void *findInternalFunctionIn(char *functionName, char *pluginName)
{
  char *function, *plugin;
  int listIndex, index;
  sqExport *exports;

  dprintf(("Looking (internally) for %s in %s ... ", functionName, (pluginName ? pluginName : "<intrinsic>")));

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
      dprintf(("found\n"));
      return exports[index].primitiveAddress;
    }
  }
  dprintf(("not found\n"));
  return NULL;

}


static void *findFunctionIn(char *functionName, ModuleEntry *module)
{
	if(module->handle == squeakModule->handle)
		return findInternalFunctionIn(functionName, module->name);
	else
		return findExternalFunctionIn(functionName, module);
}

/*
	callInitializersIn:
	Call the required initializers in the given module.
	The module has been loaded before so the task is to
	call a) setInterpreter() and check it's return, and
	b) initialiseModule (if defined) and check it's return
	as well.
*/
static int callInitializersIn(ModuleEntry *module)
{
	void *init0;
	void *init1;
	void *init2;
	char *moduleName;
	int okay;

	init0 = findFunctionIn("getModuleName", module);
	init1 = findFunctionIn("setInterpreter", module);
	init2 = findFunctionIn("initialiseModule", module);

	if(init0) {
		/* Check the compiled name of the module */
		moduleName = ((char* (*) (void))init0)();
		if(!moduleName) {
			dprintf(("ERROR: getModuleName() returned NULL\n"));
			return 0;
		}
		if(strncmp(moduleName, module->name, strlen(module->name)) != 0) {
			dprintf(("ERROR: getModuleName returned %s (expected: %s)\n", moduleName, module->name));
			return 0;
		}
	} else {
		/* Note: older plugins may not export the compiled module name */
		dprintf(("WARNING: getModuleName() not found in %s\n", module->name));
	}
	if(!init1) { 
		dprintf(("ERROR: setInterpreter() not found\n"));
		return 0;
	}
	/* call setInterpreter */
	okay = ((int (*) (struct VirtualMachine*))init1)(sqGetInterpreterProxy());
	if(!okay) {
		dprintf(("ERROR: setInterpreter() returned false\n"));
		return 0;
	}
	if(init2) {
		okay = ((int (*) (void)) init2)();
		if(!okay) {
			dprintf(("ERROR: initialiseModule() returned false\n"));
			return 0;
		}
	}
	dprintf(("SUCCESS: Module %s is now initialized\n", module->name));
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
static ModuleEntry *findAndLoadModule(char *pluginName, int ffiLoad)
{
	void *handle;
	ModuleEntry *module;

	dprintf(("Looking for plugin %s\n", (pluginName ? pluginName : "<intrinsic>")));
	/* Try to load the module externally */
	handle = (void*) ioLoadModule(pluginName);
	if(ffiLoad) {
		/* When dealing with the FFI, don't attempt to mess around internally */
		if(!handle) return NULL;
		return addToModuleList(pluginName, handle, ffiLoad);
	}
	/* NOT ffiLoad */
	if(!handle) {
		/* might be internal, so go looking for setInterpreter() */
		if(findInternalFunctionIn("setInterpreter", pluginName))
			handle = squeakModule->handle;
		else
			return NULL; /* PluginName_setInterpreter() not found */
	}
	module = addToModuleList(pluginName, handle, ffiLoad);
	if(!callInitializersIn(module)) {
		/* Initializers failed */
		if(handle != squeakModule->handle) {
			/* physically unload module */
			ioFreeModule((int)handle);
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
static ModuleEntry *findOrLoadModule(char *pluginName, int ffiLoad)
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
int ioLoadFunctionFrom(char *functionName, char *pluginName)
{
	ModuleEntry *module;

	module = findOrLoadModule(pluginName, 0);
	if(!module) {
		/* no module */
		dprintf(("Failed to find %s (module %s was not loaded)\n", functionName, pluginName));
		return 0;
	}
	if(!functionName) {
		/* only the module was requested but not any specific function */
		return 1;
	}
	/* and load the actual function */
	return (int) findFunctionIn(functionName, module);
}

/* ioLoadExternalFunctionOfLengthFromModuleOfLength
	Entry point for functions looked up through the VM.
*/
int ioLoadExternalFunctionOfLengthFromModuleOfLength(int functionNameIndex, int functionNameLength, 
                                                     int moduleNameIndex,   int moduleNameLength)
{
	char functionName[256];
	char moduleName[256];
	int i;

	if(functionNameLength > 255 || moduleNameLength > 255)
		return 0; /* can't cope with those */
	for(i=0; i< functionNameLength; i++)
		functionName[i] = ((char*)functionNameIndex)[i];
	functionName[functionNameLength] = 0;
	for(i=0; i< moduleNameLength; i++)
		moduleName[i] = ((char*)moduleNameIndex)[i];
	moduleName[moduleNameLength] = 0;
	return ioLoadFunctionFrom(functionName, moduleName);
}

/* ioLoadSymbolOfLengthFromModule
	This entry point is exclusively for the FFI.
*/
int ioLoadSymbolOfLengthFromModule(int functionNameIndex, int functionNameLength, int moduleHandle)
{
	char functionName[256];
	int i;

	if(functionNameLength > 255)
		return 0; /* can't cope with those */
	for(i=0; i< functionNameLength; i++)
		functionName[i] = ((char*)functionNameIndex)[i];
	functionName[functionNameLength] = 0;
	if(moduleHandle)
		return ioFindExternalFunctionIn(functionName, moduleHandle);
	else
		return 0;
}

/* ioLoadModuleOfLength
	This entry point is exclusively for the FFI.
	It does *NOT* call any of the initializers nor
	does it attempt to lookup stuff internally.
*/
int ioLoadModuleOfLength(int moduleNameIndex, int moduleNameLength)
{
	ModuleEntry *module;
	char moduleName[256];
	int i;

	if(moduleNameLength > 255) return 0; /* can't cope with those */
	for(i=0; i< moduleNameLength; i++)
		moduleName[i] = ((char*)moduleNameIndex)[i];
	moduleName[moduleNameLength] = 0;

	module = findOrLoadModule(moduleName, 1);
	if(module) return (int) module->handle;
	return 0;
}


/* shutdownModule:
	Call the shutdown mechanism from the specified module.
*/
static int shutdownModule(ModuleEntry *module)
{
	void* fn;

	if(module->ffiLoaded) return 1; /* don't even attempt for ffi loaded modules */

	/* load the actual function */
	fn = findFunctionIn("shutdownModule", module);
	if(fn) return ((int (*) (void)) fn) ();
	return 1;
}

/* ioShutdownAllModules:
	Call the shutdown mechanism for all loaded modules.
*/
int ioShutdownAllModules(void)
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
int ioUnloadModule(char *moduleName)
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
				((int (*) (char *))fn)(entry->name);
			}
		}
		temp = temp->next;
	}
	/* And actually unload it if it isn't just the VM... */
	if(entry->handle != squeakModule->handle)
		ioFreeModule((int) entry->handle);
	removeFromList(entry);
	free(entry); /* give back space */
	return 1;
}

/* ioUnloadModuleOfLength:
	Entry point for the interpreter.
*/
int ioUnloadModuleOfLength(int moduleNameIndex, int moduleNameLength)
{
	char moduleName[256];
	int i;

	if(moduleNameLength > 255) return 0; /* can't cope with those */
	for(i=0; i< moduleNameLength; i++)
		moduleName[i] = ((char*)moduleNameIndex)[i];
	moduleName[moduleNameLength] = 0;
	return ioUnloadModule(moduleName);
}

/* ioListBuiltinModule:
	Return the name of the n-th builtin module.
*/

char *ioListBuiltinModule(int moduleIndex)
{
  int index, listIndex;
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
	  init0 = findInternalFunctionIn("getModuleName", plugin);
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

char *ioListLoadedModule(int moduleIndex) {
	int index = 1;

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
