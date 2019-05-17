# Plugin that are only used by Squeak.
if(NOT MINIMAL_PLUGIN_SET)

add_vm_plugin_auto(Klatt INTERNAL)
add_vm_plugin_auto(UUIDPlugin INTERNAL)

endif(NOT MINIMAL_PLUGIN_SET)
