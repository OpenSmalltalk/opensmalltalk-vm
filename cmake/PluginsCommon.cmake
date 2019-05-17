# The sources of the FFI plugin are special.
set(SqueakFFIPrims_Sources
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqFFI.h"
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqFFIPlugin.c"
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqFFITestFuncs.c"
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqManualSurface.c"
    "${PluginsSourceFolderName}/SqueakFFIPrims/SqueakFFIPrims.c"
)

add_vm_plugin_sources(SqueakFFIPrims INTERNAL ${SqueakFFIPrims_Sources})

# The sources of the IA32ABI plugin are special.
set(IA32ABI_Sources
    "${CrossPlatformPluginFolder}/IA32ABI/AlienSUnitTestProcedures.c"
    "${CrossPlatformPluginFolder}/IA32ABI/xabicc.c"
    "${CrossPlatformPluginFolder}/IA32ABI/x64win64stub.c"
    "${PluginsSourceFolderName}/IA32ABI/IA32ABI.c"
)

add_vm_plugin_sources(IA32ABI INTERNAL ${IA32ABI_Sources})

# Basic internal plugins
add_vm_plugin_auto(FilePlugin INTERNAL)
if(NOT MSVC) # Not compiling with MSVC yet
    add_vm_plugin_auto(FileAttributesPlugin INTERNAL)
endif()
add_vm_plugin_auto(LargeIntegers INTERNAL)
add_vm_plugin_auto(LocalePlugin INTERNAL)
add_vm_plugin_auto(MiscPrimitivePlugin INTERNAL)
add_vm_plugin_auto(SecurityPlugin INTERNAL)
add_vm_plugin_auto(SocketPlugin INTERNAL)
if(WIN32)
    vm_plugin_link_libraries(SocketPlugin Ws2_32)
endif()

add_vm_plugin_auto(B2DPlugin INTERNAL)
add_vm_plugin_sources(BitBltPlugin INTERNAL
    "${PluginsSourceFolderName}/BitBltPlugin/BitBltPlugin.c"
)

add_vm_plugin_auto(FloatArrayPlugin INTERNAL)
add_vm_plugin_auto(FloatMathPlugin INTERNAL)
add_vm_plugin_auto(Matrix2x3Plugin INTERNAL)

# Basic external plugins
add_vm_plugin_auto(SurfacePlugin EXTERNAL)

# Drop plugin
add_vm_plugin_sources(DropPlugin INTERNAL
    "${PluginsSourceFolderName}/DropPlugin/DropPlugin.c"
)

# Extra plugins
add_vm_plugin_auto(ZipPlugin INTERNAL) # Used by Monticello
