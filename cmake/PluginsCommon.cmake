# The sources of the FFI plugin are special.
set(SqueakFFIPrims_Sources
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqFFI.h"
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqFFIPlugin.c"
    #"${CrossPlatformPluginFolder}/SqueakFFIPrims/sqFFITestFuncs.c" # Clashes with AlienSUnitTestProcedures
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
    add_vm_plugin_auto(FileAttributesPlugin INTERNAL USE_UNIX_SOURCES_ON_MAC)
endif()
add_vm_plugin_auto(LargeIntegers INTERNAL)
add_vm_plugin_auto(LocalePlugin INTERNAL)
add_vm_plugin_auto(MiscPrimitivePlugin INTERNAL)
add_vm_plugin_auto(SecurityPlugin INTERNAL USE_UNIX_SOURCES_ON_MAC)
add_vm_plugin_auto(SocketPlugin INTERNAL USE_UNIX_SOURCES_ON_MAC)
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

if(NOT MINIMAL_PLUGIN_SET)

#===============================================================================
# Plugins that are used by both, Squeak and Pharo
#===============================================================================
add_vm_plugin_auto(ADPCMCodecPlugin INTERNAL)
add_vm_plugin_auto(AsynchFilePlugin INTERNAL USE_UNIX_SOURCES_ON_MAC)
#add_vm_plugin_auto(B3DAcceleratorPlugin EXTERNAL)
add_vm_plugin_auto(BMPReadWriterPlugin INTERNAL)
add_vm_plugin_auto(CroquetPlugin EXTERNAL)
add_vm_plugin_auto(DSAPrims INTERNAL)
add_vm_plugin_auto(FFTPlugin INTERNAL)
if (NOT WIN32) # Not supported on Windows
	add_vm_plugin_auto(FileCopyPlugin INTERNAL USE_UNIX_SOURCES_ON_MAC)
endif()

if(NOT DARWIN)
    add_vm_plugin_auto(JoystickTabletPlugin INTERNAL)
    add_vm_plugin_auto(MIDIPlugin INTERNAL)
endif()

if(WIN32)
    add_definitions(-DNO_NULL_SERIAL_PLUGIN_IMPLEMENTATION)
endif()
add_vm_plugin_auto(SerialPlugin INTERNAL)

add_vm_plugin_auto(SoundCodecPrims INTERNAL)
add_vm_plugin_auto(SoundGenerationPlugin INTERNAL)
#add_vm_plugin_auto(SoundPlugin INTERNAL)
add_vm_plugin_auto(StarSqueakPlugin INTERNAL)
add_vm_plugin_auto(JPEGReaderPlugin EXTERNAL)
add_vm_plugin_auto(JPEGReadWriter2Plugin EXTERNAL)
add_vm_plugin_auto(RePlugin EXTERNAL)
if((NOT WIN32) AND (NOT DARWIN))
	# Is this plugin actually being used?
	add_vm_plugin_auto(InternetConfigPlugin EXTERNAL)
endif()

if(DARWIN)
    add_vm_plugin_auto(VMProfileMacSupportPlugin INTERNAL)
endif()

# Squeak SSL plugin
# In the case of the minheadless VM for OS X, we are treating the VM as it were
# an unix since we are removing all of the platform specific windowing code in
# this VM variant. For this reason, in the cases where OS X is different than
# another unix, the plugin code has to be added manually.
if (APPLE)
	set(SqueakSSL_Sources
	    "platforms/iOS/plugins/SqueakSSL/sqMacSSL.c"
	)
	add_vm_plugin_auto(SqueakSSL EXTERNAL ${SqueakSSL_Sources})
	vm_plugin_link_libraries(SqueakSSL ${CoreFoundation_LIBRARY} ${Security_LIBRARY})
else()
	add_vm_plugin_auto(SqueakSSL EXTERNAL)
	if(WIN32)
    	vm_plugin_link_libraries(SqueakSSL crypt32 secur32)
	endif()
endif()

if (NOT WIN32)
	add_vm_plugin_auto(AioPlugin EXTERNAL)
	allow_plugin_undefined_symbols(AioPlugin _aioDisable _aioEnable _aioHandle _aioSuspend)
endif()

# More complicated plugins
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/Mpeg3Plugin.cmake")

endif(NOT MINIMAL_PLUGIN_SET)
