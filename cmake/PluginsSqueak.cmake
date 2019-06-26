# Plugin that are only used by Squeak.
if(NOT MINIMAL_PLUGIN_SET)

add_vm_plugin_auto(Klatt INTERNAL)

if(DARWIN)
    add_vm_plugin_auto(UUIDPlugin INTERNAL)
elseif(WIN32)
    add_vm_plugin_auto(UUIDPlugin EXTERNAL)
else()
    if(HAVE_VALID_UUID_LIBRARY)
        add_vm_plugin_auto(UUIDPlugin EXTERNAL)
        vm_plugin_link_libraries(UUIDPlugin ${UUID_LIBRARY})
    endif()
endif()

endif(NOT MINIMAL_PLUGIN_SET)
