# Internal Pharo plugins
add_vm_plugin_auto(ADPCMCodecPlugin INTERNAL)
add_vm_plugin_auto(AsynchFilePlugin INTERNAL)
add_vm_plugin_auto(BMPReadWriterPlugin INTERNAL)
#add_vm_plugin_auto(CroquetPlugin INTERNAL)
add_vm_plugin_auto(DSAPrims INTERNAL)
add_vm_plugin_auto(FFTPlugin INTERNAL)
if (NOT WIN32) # Not supported on Windows
	add_vm_plugin_auto(FileCopyPlugin INTERNAL)
endif()
add_vm_plugin_auto(JoystickTabletPlugin INTERNAL)
add_vm_plugin_auto(MIDIPlugin INTERNAL)
add_vm_plugin_auto(SerialPlugin INTERNAL)
add_vm_plugin_auto(SoundCodecPrims INTERNAL)
add_vm_plugin_auto(SoundGenerationPlugin INTERNAL)
#add_vm_plugin_auto(SoundPlugin INTERNAL)
add_vm_plugin_auto(StarSqueakPlugin INTERNAL)

# External Pharo plugins
#add_vm_plugin_auto(B3DAcceleratorPlugin EXTERNAL)

add_vm_plugin_auto(JPEGReaderPlugin EXTERNAL)
add_vm_plugin_auto(JPEGReadWriter2Plugin EXTERNAL)
add_vm_plugin_auto(RePlugin EXTERNAL)
if(NOT WIN32)
	add_vm_plugin_auto(InternetConfigPlugin EXTERNAL)
endif()

# Squeak SSL plugin
if (APPLE)
	set(SqueakSSL_Sources
	    "platforms/iOS/plugins/SqueakSSL/sqMacSSL.c"
	)
	add_vm_plugin_sources(SqueakSSL EXTERNAL ${SqueakSSL_Sources})
else()
	add_vm_plugin_auto(SqueakSSL EXTERNAL)
	if(WIN32)
    	vm_plugin_link_libraries(SqueakSSL crypt32 secur32)
	endif()
endif()

if (NOT WIN32)
	add_vm_plugin_auto(AioPlugin EXTERNAL)
endif()

add_vm_plugin_auto(EventsHandlerPlugin EXTERNAL)
if(HAVE_SDL2)
    add_vm_plugin_auto(SDL2DisplayPlugin EXTERNAL)
    vm_plugin_link_libraries(SDL2DisplayPlugin ${SDL2_LIBRARY})
endif()

# More complicated plugins
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/Mpeg3Plugin.cmake")

# Free type plugin
find_package(Freetype)
if(FREETYPE_FOUND)
    include_directories(${FREETYPE_INCLUDE_DIRS})
    add_vm_plugin_auto(FT2Plugin EXTERNAL)
    vm_plugin_link_libraries(FT2Plugin ${FREETYPE_LIBRARIES})
endif()

# OSProcess
if(UNIX)
    if(NOT APPLE)
        add_vm_plugin_auto(VMProfileLinuxSupportPlugin INTERNAL)
    endif()
    add_vm_plugin_auto(UnixOSProcessPlugin INTERNAL)
endif()
if(WIN32)
    add_vm_plugin_auto(Win32OSProcessPlugin INTERNAL)
endif()
