/////////////////////////////////////////////////////////////////////////
// $Id: plugin.cc,v 1.25 2008/02/15 22:05:38 sshwarts Exp $
/////////////////////////////////////////////////////////////////////////
//
// This file defines the plugin and plugin-device registration functions and
// the device registration functions.  It handles dynamic loading of modules,
// using the LTDL library for cross-platform support.
//
// This file is based on the plugin.c file from plex86, but with significant
// changes to make it work in Bochs.
// Plex86 is Copyright (C) 1999-2000  The plex86 developers team
//
/////////////////////////////////////////////////////////////////////////

#include "bochs.h"
#include "iodev/iodev.h"
#include "plugin.h"

#define LOG_THIS genlog->

#define PLUGIN_INIT_FMT_STRING  "lib%s_LTX_plugin_init"
#define PLUGIN_FINI_FMT_STRING  "lib%s_LTX_plugin_fini"
#define PLUGIN_PATH ""

#ifndef WIN32
#define PLUGIN_FILENAME_FORMAT "libbx_%s.la"
#else
#define PLUGIN_FILENAME_FORMAT "bx_%s.dll"
#endif

extern "C" {

void  (*pluginRegisterIRQ)(unsigned irq, const char* name) = 0;
void  (*pluginUnregisterIRQ)(unsigned irq, const char* name) = 0;

void (*pluginSetHRQ)(unsigned val) = 0;
void (*pluginSetHRQHackCallback)(void (*callback)(void)) = 0;

int (*pluginRegisterIOReadHandler)(void *thisPtr, ioReadHandler_t callback,
                            unsigned base, const char *name, Bit8u mask) = 0;
int (*pluginRegisterIOWriteHandler)(void *thisPtr, ioWriteHandler_t callback,
                             unsigned base, const char *name, Bit8u mask) = 0;
int (*pluginUnregisterIOReadHandler)(void *thisPtr, ioReadHandler_t callback,
                            unsigned base, Bit8u mask) = 0;
int (*pluginUnregisterIOWriteHandler)(void *thisPtr, ioWriteHandler_t callback,
                             unsigned base, Bit8u mask) = 0;
int (*pluginRegisterIOReadHandlerRange)(void *thisPtr, ioReadHandler_t callback,
                            unsigned base, unsigned end, const char *name, Bit8u mask) = 0;
int (*pluginRegisterIOWriteHandlerRange)(void *thisPtr, ioWriteHandler_t callback,
                             unsigned base, unsigned end, const char *name, Bit8u mask) = 0;
int (*pluginUnregisterIOReadHandlerRange)(void *thisPtr, ioReadHandler_t callback,
                            unsigned begin, unsigned end, Bit8u mask) = 0;
int (*pluginUnregisterIOWriteHandlerRange)(void *thisPtr, ioWriteHandler_t callback,
                             unsigned begin, unsigned end, Bit8u mask) = 0;
int (*pluginRegisterDefaultIOReadHandler)(void *thisPtr, ioReadHandler_t callback,
                            const char *name, Bit8u mask) = 0;
int (*pluginRegisterDefaultIOWriteHandler)(void *thisPtr, ioWriteHandler_t callback,
                             const char *name, Bit8u mask) = 0;
int (*pluginRegisterTimer)(void *this_ptr, void (*funct)(void *),
                            Bit32u useconds, bx_bool continuous,
bx_bool active, const char* name) = 0;
                            void (*pluginActivateTimer)(unsigned id, Bit32u usec, bx_bool continuous) = 0;

void (*pluginHRQHackCallback)(void);
unsigned pluginHRQ = 0;

plugin_t *plugins = NULL;      /* Head of the linked list of plugins  */
#if BX_PLUGINS
static void plugin_init_one(plugin_t *plugin);
#endif

device_t *devices = NULL;      /* Head of the linked list of registered devices  */

plugin_t *current_plugin_context = NULL;

/************************************************************************/
/* Builtins declarations                                                */
/************************************************************************/

  static void
builtinRegisterIRQ(unsigned irq, const char* name)
{
#if 0
  pluginlog->panic("builtinRegisterIRQ called, no pic plugin loaded?");
#else
  bx_devices.register_irq(irq, name);
#endif
}

  static void
builtinUnregisterIRQ(unsigned irq, const char* name)
{
#if 0
  pluginlog->panic("builtinUnregisterIRQ called, no pic plugin loaded?");
#else
  bx_devices.unregister_irq(irq, name);
#endif
}

  static void
builtinSetHRQ(unsigned val)
{
#if 0
  pluginlog->panic("builtinSetHRQ called, no plugin loaded?");
#else
  pluginHRQ = val;
#endif
}

  static void
builtinSetHRQHackCallback(void (*callback)(void))
{
#if 0
  pluginlog->panic("builtinSetHRQHackCallback called, no plugin loaded?");
#else
  pluginHRQHackCallback = callback;
#endif
}

  static int
builtinRegisterIOReadHandler(void *thisPtr, ioReadHandler_t callback,
                            unsigned base, const char *name, Bit8u mask)
{
  int ret;
  BX_ASSERT(mask<8);
  ret = bx_devices.register_io_read_handler (thisPtr, callback, base, name, mask);
  pluginlog->ldebug("plugin %s registered I/O read address at %04x", name, base);
  return ret;
}

  static int
builtinRegisterIOWriteHandler(void *thisPtr, ioWriteHandler_t callback,
                             unsigned base, const char *name, Bit8u mask)
{
  int ret;
  BX_ASSERT(mask<8);
  ret = bx_devices.register_io_write_handler (thisPtr, callback, base, name, mask);
  pluginlog->ldebug("plugin %s registered I/O write address at %04x", name, base);
  return ret;
}

  static int
builtinUnregisterIOReadHandler(void *thisPtr, ioReadHandler_t callback,
                            unsigned base, Bit8u mask)
{
  int ret;
  BX_ASSERT(mask<8);
  ret = bx_devices.unregister_io_read_handler (thisPtr, callback, base, mask);
  pluginlog->ldebug("plugin unregistered I/O read address at %04x", base);
  return ret;
}

  static int
builtinUnregisterIOWriteHandler(void *thisPtr, ioWriteHandler_t callback,
                             unsigned base, Bit8u mask)
{
  int ret;
  BX_ASSERT(mask<8);
  ret = bx_devices.unregister_io_write_handler (thisPtr, callback, base, mask);
  pluginlog->ldebug("plugin unregistered I/O write address at %04x", base);
  return ret;
}

  static int
builtinRegisterIOReadHandlerRange(void *thisPtr, ioReadHandler_t callback,
                            unsigned base, unsigned end, const char *name, Bit8u mask)
{
  int ret;
  BX_ASSERT(mask<8);
  ret = bx_devices.register_io_read_handler_range (thisPtr, callback, base, end, name, mask);
  pluginlog->ldebug("plugin %s registered I/O read addresses %04x to %04x", name, base, end);
  return ret;
}

  static int
builtinRegisterIOWriteHandlerRange(void *thisPtr, ioWriteHandler_t callback,
                             unsigned base, unsigned end, const char *name, Bit8u mask)
{
  int ret;
  BX_ASSERT(mask<8);
  ret = bx_devices.register_io_write_handler_range (thisPtr, callback, base, end, name, mask);
  pluginlog->ldebug("plugin %s registered I/O write addresses %04x to %04x", name, base, end);
  return ret;
}

  static int
builtinUnregisterIOReadHandlerRange(void *thisPtr, ioReadHandler_t callback,
                            unsigned begin, unsigned end, Bit8u mask)
{
  int ret;
  BX_ASSERT(mask<8);
  ret = bx_devices.unregister_io_read_handler_range (thisPtr, callback, begin, end, mask);
  pluginlog->ldebug("plugin unregistered I/O read addresses %04x to %04x", begin, end);
  return ret;
}

  static int
builtinUnregisterIOWriteHandlerRange(void *thisPtr, ioWriteHandler_t callback,
                             unsigned begin, unsigned end, Bit8u mask)
{
  int ret;
  BX_ASSERT(mask<8);
  ret = bx_devices.unregister_io_write_handler_range (thisPtr, callback, begin, end, mask);
  pluginlog->ldebug("plugin unregistered I/O write addresses %04x to %04x", begin, end);
  return ret;
}

  static int
builtinRegisterDefaultIOReadHandler(void *thisPtr, ioReadHandler_t callback,
                            const char *name, Bit8u mask)
{
  BX_ASSERT(mask<8);
  bx_devices.register_default_io_read_handler (thisPtr, callback, name, mask);
  pluginlog->ldebug("plugin %s registered default I/O read ", name);
  return 0;
}

  static int
builtinRegisterDefaultIOWriteHandler(void *thisPtr, ioWriteHandler_t callback,
                             const char *name, Bit8u mask)
{
  BX_ASSERT(mask<8);
  bx_devices.register_default_io_write_handler (thisPtr, callback, name, mask);
  pluginlog->ldebug("plugin %s registered default I/O write ", name);
  return 0;
}

  static int
builtinRegisterTimer(void *this_ptr, void (*funct)(void *),
                        Bit32u useconds, bx_bool continuous,
                        bx_bool active, const char* name)
{
  int id = bx_pc_system.register_timer (this_ptr, funct, useconds, continuous, active, name);
  pluginlog->ldebug("plugin %s registered timer %d", name, id);
  return id;
}

  static void
builtinActivateTimer(unsigned id, Bit32u usec, bx_bool continuous)
{
  bx_pc_system.activate_timer (id, usec, continuous);
  pluginlog->ldebug("plugin activated timer %d", id);
}

#if BX_PLUGINS
/************************************************************************/
/* Plugin initialization / deinitialization                             */
/************************************************************************/

void plugin_init_all (void)
{
  plugin_t *plugin;

  pluginlog->info("Initializing plugins");

  for (plugin = plugins; plugin; plugin = plugin->next)
  {
    char *arg_ptr = plugin->args;

    /* process the command line */
    plugin->argc = 0;
    while (plugin->argc < MAX_ARGC)
    {
      while (*arg_ptr && isspace (*arg_ptr))
        arg_ptr++;

      if (!*arg_ptr) break;
      plugin->argv[plugin->argc++] = arg_ptr;

      while (*arg_ptr && !isspace (*arg_ptr))
        arg_ptr++;

      if (!*arg_ptr) break;
      *arg_ptr++ = '\0';
    }

    /* initialize the plugin */
    if (plugin->plugin_init (plugin, plugin->type, plugin->argc, plugin->argv))
    {
      pluginlog->panic("Plugin initialization failed for %s", plugin->name);
      plugin_abort();
    }

    plugin->initialized = 1;
  }
}

void plugin_init_one(plugin_t *plugin)
{
  char *arg_ptr = plugin->args;

  /* process the command line */
  plugin->argc = 0;
  while (plugin->argc < MAX_ARGC)
  {
    while (*arg_ptr && isspace (*arg_ptr))
      arg_ptr++;

    if (!*arg_ptr) break;
    plugin->argv[plugin->argc++] = arg_ptr;

    while (*arg_ptr && !isspace (*arg_ptr))
      arg_ptr++;

    if (!*arg_ptr) break;
    *arg_ptr++ = '\0';
  }

  /* initialize the plugin */
  if (plugin->plugin_init (plugin, plugin->type, plugin->argc, plugin->argv))
  {
    pluginlog->info("Plugin initialization failed for %s", plugin->name);
    plugin_abort();
  }

  plugin->initialized = 1;
}


plugin_t *plugin_unload(plugin_t *plugin)
{
  plugin_t *dead_plug;

  if (plugin->initialized)
      plugin->plugin_fini();

  lt_dlclose(plugin->handle);
  delete [] plugin->name;

  dead_plug = plugin;
  plugin = plugin->next;
  free(dead_plug);

  return plugin;
}

void plugin_fini_all (void)
{
  plugin_t *plugin;

  for (plugin = plugins; plugin; plugin = plugin_unload(plugin));
}

void plugin_load(char *name, char *args, plugintype_t type)
{
  plugin_t *plugin;

  plugin = (plugin_t *)malloc (sizeof(plugin_t));
  if (!plugin)
  {
    BX_PANIC(("malloc plugin_t failed"));
  }

  plugin->type = type;
  plugin->name = name;
  plugin->args = args;
  plugin->initialized = 0;

  char plugin_filename[BX_PATHNAME_LEN], buf[BX_PATHNAME_LEN];
  sprintf(buf, PLUGIN_FILENAME_FORMAT, name);
  sprintf(plugin_filename, "%s%s", PLUGIN_PATH, buf);

  // Set context so that any devices that the plugin registers will
  // be able to see which plugin created them.  The registration will
  // be called from either dlopen (global constructors) or plugin_init.
  BX_ASSERT(current_plugin_context == NULL);
  current_plugin_context = plugin;
  plugin->handle = lt_dlopen (plugin_filename);
  BX_INFO(("lt_dlhandle is %p", plugin->handle));
  if (!plugin->handle)
  {
    current_plugin_context = NULL;
    BX_PANIC(("dlopen failed for module '%s': %s", name, lt_dlerror ()));
    free (plugin);
    return;
  }

  sprintf(buf, PLUGIN_INIT_FMT_STRING, name);
  plugin->plugin_init =
      (int (*)(struct _plugin_t *, enum plugintype_t, int, char *[])) /* monster typecast */
      lt_dlsym (plugin->handle, buf);
  if (plugin->plugin_init == NULL) {
    pluginlog->panic("could not find plugin_init: %s", lt_dlerror ());
    plugin_abort ();
  }

  sprintf(buf, PLUGIN_FINI_FMT_STRING, name);
  plugin->plugin_fini = (void (*)(void)) lt_dlsym (plugin->handle, buf);
  if (plugin->plugin_init == NULL) {
    pluginlog->panic("could not find plugin_fini: %s", lt_dlerror ());
    plugin_abort();
  }
  pluginlog->info("loaded plugin %s",plugin_filename);

  /* Insert plugin at the _end_ of the plugin linked list. */
  plugin->next = NULL;

  if (!plugins)
  {
    /* Empty list, this become the first entry. */
    plugins = plugin;
  }
  else
  {
   /* Non-empty list.  Add to end. */
   plugin_t *temp = plugins;

   while (temp->next)
      temp = temp->next;

    temp->next = plugin;
  }

  plugin_init_one(plugin);

  // check that context didn't change.  This should only happen if we
  // need a reentrant plugin_load.
  BX_ASSERT(current_plugin_context == plugin);
  current_plugin_context = NULL;
}

void plugin_abort(void)
{
  pluginlog->panic("plugin load aborted");
}

#endif   /* end of #if BX_PLUGINS */

/************************************************************************/
/* Plugin system: initialisation of plugins entry points                */
/************************************************************************/

  void
plugin_startup(void)
{
  pluginRegisterIRQ = builtinRegisterIRQ;
  pluginUnregisterIRQ = builtinUnregisterIRQ;

  pluginSetHRQHackCallback = builtinSetHRQHackCallback;
  pluginSetHRQ = builtinSetHRQ;

  pluginRegisterIOReadHandler = builtinRegisterIOReadHandler;
  pluginRegisterIOWriteHandler = builtinRegisterIOWriteHandler;

  pluginUnregisterIOReadHandler = builtinUnregisterIOReadHandler;
  pluginUnregisterIOWriteHandler = builtinUnregisterIOWriteHandler;

  pluginRegisterIOReadHandlerRange = builtinRegisterIOReadHandlerRange;
  pluginRegisterIOWriteHandlerRange = builtinRegisterIOWriteHandlerRange;

  pluginUnregisterIOReadHandlerRange = builtinUnregisterIOReadHandlerRange;
  pluginUnregisterIOWriteHandlerRange = builtinUnregisterIOWriteHandlerRange;

  pluginRegisterDefaultIOReadHandler = builtinRegisterDefaultIOReadHandler;
  pluginRegisterDefaultIOWriteHandler = builtinRegisterDefaultIOWriteHandler;

  pluginRegisterTimer = builtinRegisterTimer;
  pluginActivateTimer = builtinActivateTimer;

#if BX_PLUGINS
  pluginlog = new logfunctions();
  pluginlog->put("PLGIN");
  pluginlog->settype(PLUGINLOG);
  int status = lt_dlinit ();
  if (status != 0) {
    BX_ERROR (("initialization error in ltdl library (for loading plugins)"));
    BX_PANIC (("error message was: %s", lt_dlerror ()));
  }
#endif
}


/************************************************************************/
/* Plugin system: Device registration                                   */
/************************************************************************/

void pluginRegisterDeviceDevmodel(plugin_t *plugin, plugintype_t type, bx_devmodel_c *devmodel, const char *name)
{
  device_t *device;

  device = (device_t *)malloc (sizeof (device_t));
  if (!device)
  {
    pluginlog->panic("can't allocate device_t");
  }

  device->name = name;
  BX_ASSERT(devmodel != NULL);
  device->devmodel = devmodel;
  device->plugin = plugin;  // this can be NULL
  device->next = NULL;

  // Don't add every kind of device to the list.
  switch (type) {
    case PLUGTYPE_CORE:
      // Core devices are present whether or not we are using plugins, so
      // they are managed by the same code in iodev/devices.cc whether
      // plugins are on or off.
      free(device);
      return; // Do not add core devices to the devices list.
    case PLUGTYPE_OPTIONAL:
    case PLUGTYPE_USER:
    default:
      // The plugin system will manage optional and user devices only.
      break;
  }

  if (!devices) {
    /* Empty list, this become the first entry. */
    devices = device;
  }
  else {
    /* Non-empty list.  Add to end. */
    device_t *temp = devices;

    while (temp->next)
      temp = temp->next;

    temp->next = device;
  }
}

/************************************************************************/
/* Plugin system: Check if a plugin is loaded                           */
/************************************************************************/

bx_bool pluginDevicePresent(char *name)
{
  device_t *device;

  for (device = devices; device; device = device->next)
  {
    if (strcmp(device->name,name)==0) return true;
  }

  return false;
}

#if BX_PLUGINS
/************************************************************************/
/* Plugin system: Load one plugin                                       */
/************************************************************************/

int bx_load_plugin(const char *name, plugintype_t type)
{
  char *namecopy = new char[1+strlen(name)];
  strcpy(namecopy, name);
  plugin_load(namecopy, "", type);
  return 0;
}

void bx_unload_plugin(const char *name)
{
  plugin_t *plugin, *prev = NULL;

  for (plugin = plugins; plugin; plugin = plugin->next) {
    if (!strcmp(plugin->name, name)) {
      plugin = plugin_unload(plugin);
      if (prev == NULL) {
        plugins = plugin;
      } else {
        prev->next = plugin;
      }
      break;
    } else {
      prev = plugin;
    }
  }
}

#endif   /* end of #if BX_PLUGINS */

/*************************************************************************/
/* Plugin system: Execute init function of all registered plugin-devices */
/*************************************************************************/

void bx_init_plugins()
{
  device_t *device;

  // two loops
  for (device = devices; device; device = device->next)
  {
    pluginlog->info("init_mem of '%s' plugin device by virtual method",device->name);
    device->devmodel->init_mem(BX_MEM(0));
  }

  for (device = devices; device; device = device->next)
  {
    pluginlog->info("init_dev of '%s' plugin device by virtual method",device->name);
    device->devmodel->init();
  }
}

/**************************************************************************/
/* Plugin system: Execute reset function of all registered plugin-devices */
/**************************************************************************/

void bx_reset_plugins(unsigned signal)
{
  device_t *device;
  for (device = devices; device; device = device->next)
  {
    pluginlog->info("reset of '%s' plugin device by virtual method",device->name);
    device->devmodel->reset(signal);
  }
}

/*******************************************************/
/* Plugin system: Unload all registered plugin-devices */
/*******************************************************/

void bx_unload_plugins()
{
  device_t *device, *next;

  device = devices;
  while (device != NULL) {
    if (device->plugin != NULL) {
#if BX_PLUGINS
      bx_unload_plugin(device->name);
#endif
    } else {
      delete device->devmodel;
    }
    next = device->next;
    free(device);
    device = next;
  }
  devices = NULL;
}

/**************************************************************************/
/* Plugin system: Register device state of all registered plugin-devices  */
/**************************************************************************/

void bx_plugins_register_state()
{
  device_t *device;
  for (device = devices; device; device = device->next)
  {
    pluginlog->info("register state of '%s' plugin device by virtual method",device->name);
    device->devmodel->register_state();
  }
}

/***************************************************************************/
/* Plugin system: Execute code after restoring state of all plugin devices */
/***************************************************************************/

void bx_plugins_after_restore_state()
{
  device_t *device;
  for (device = devices; device; device = device->next)
  {
    device->devmodel->after_restore_state();
  }
}

}
