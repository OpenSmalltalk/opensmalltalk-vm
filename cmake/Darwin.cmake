
function(add_platform_headers)
  target_include_directories(${VM_LIBRARY_NAME}
    PUBLIC
      ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/osx
      ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/unix
      ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/common
    )
endfunction() #add_platform_headers

set(EXTRACTED_SOURCES
#Common sources
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/common/sqHeapMap.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/common/sqVirtualMachine.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/common/sqNamedPrims.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/common/sqExternalSemaphores.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/common/sqTicker.c

#Platform sources
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/osx/aioOSX.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/debugUnix.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/utilsMac.mm

# Support sources
    ${CMAKE_CURRENT_SOURCE_DIR}/src/fileDialogMac.m

#Virtual Memory functions
    ${CMAKE_CURRENT_SOURCE_DIR}/src/memoryUnix.c
)

set_source_files_properties(
  "${CMAKE_CURRENT_SOURCE_DIR}/resources/mac/${APPNAME}.icns"
  "${CMAKE_CURRENT_SOURCE_DIR}/resources/mac/${APPNAME}Changes.icns"
  "${CMAKE_CURRENT_SOURCE_DIR}/resources/mac/${APPNAME}Image.icns"
  "${CMAKE_CURRENT_SOURCE_DIR}/resources/mac/${APPNAME}Sources.icns"
  PROPERTIES
  MACOSX_PACKAGE_LOCATION Resources
)

set(VM_FRONTEND_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/unixMain.c
    "${CMAKE_CURRENT_SOURCE_DIR}/resources/mac/${APPNAME}.icns"
    "${CMAKE_CURRENT_SOURCE_DIR}/resources/mac/${APPNAME}Changes.icns"
    "${CMAKE_CURRENT_SOURCE_DIR}/resources/mac/${APPNAME}Image.icns"
    "${CMAKE_CURRENT_SOURCE_DIR}/resources/mac/${APPNAME}Sources.icns"
)

configure_file(resources/mac/Info.plist.in build/includes/Info.plist)

macro(add_third_party_dependencies_per_platform)
	if (DOWNLOAD_DEPENDENCIES)
		add_third_party_dependency("PThreadedFFI-1.4.0-osx64" "build/vm")
	endif()

	if(${FEATURE_LIB_GIT2})
		include(cmake/importLibGit2.cmake)
	endif()

  if(${FEATURE_LIB_FREETYPE2})
    include(cmake/importFreetype2.cmake)
  endif()

  if(${FEATURE_LIB_CAIRO})
    include(cmake/importCairo.cmake)
  endif()

  if(${FEATURE_LIB_SDL2})
    include(cmake/importSDL2.cmake)
  endif()
endmacro()

macro(configure_installables INSTALL_COMPONENT)
  set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/build/dist")
  
	install(
		DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build/libffi/install/lib/"
		DESTINATION "${VM_EXECUTABLE_NAME}.app/Contents/MacOS/Plugins"
		COMPONENT ${INSTALL_COMPONENT}
		FILES_MATCHING PATTERN ${DYLIB_EXT})
  
  
  install(
    DIRECTORY "${CMAKE_BINARY_DIR}/build/vm/Debug/"
    DESTINATION "./"
    USE_SOURCE_PERMISSIONS
    COMPONENT ${INSTALL_COMPONENT})

	install(
	    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/osx/"
	    DESTINATION include/pharovm
	    COMPONENT include
	    FILES_MATCHING PATTERN *.h)
endmacro()

macro(add_required_libs_per_platform)
   target_link_libraries(${VM_LIBRARY_NAME} "-framework AppKit")
   target_link_libraries(${VM_LIBRARY_NAME} "-framework CoreGraphics")
endmacro()

execute_process(
    COMMAND xcrun --show-sdk-path
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE OSX_SDK_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE)


set(DYLIB_EXT "*.dylib")
set(LIBFFI_TARGET "--target=x86_64-apple-darwin")
set(LIBFFI_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/build/bin/libffi.dylib" "${CMAKE_CURRENT_BINARY_DIR}/build/bin/libffi.7.dylib")
set(LIBFFI_ADDITIONAL "CPATH=${OSX_SDK_PATH}/usr/include")

