set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wl,-rpath=.")
set(PHARO_BIN_LOCATION "default" CACHE STRING "The default location of the PHARO bin, used by the launch.sh.in")

if(${PHARO_BIN_LOCATION} STREQUAL "default")
	set(PHARO_BIN_IN_ROOT "`/usr/bin/dirname \"\$0\"`/lib")
	set(PHARO_BIN_IN_BIN "`/usr/bin/dirname \"\$0\"`/../lib")
else()
	set(PHARO_BIN_IN_ROOT ${PHARO_BIN_LOCATION})
	set(PHARO_BIN_IN_BIN ${PHARO_BIN_LOCATION})
endif()

function(add_platform_headers)
target_include_directories(${VM_LIBRARY_NAME}
PUBLIC
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
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/unix/aio.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/debugUnix.c

#Virtual Memory functions
    ${CMAKE_CURRENT_SOURCE_DIR}/src/memoryUnix.c

# Support sources
    ${CMAKE_CURRENT_SOURCE_DIR}/src/fileDialogUnix.c
)

set(VM_FRONTEND_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/unixMain.c)


macro(add_third_party_dependencies_per_platform)
	if (DOWNLOAD_DEPENDENCIES)
		add_third_party_dependency("PThreadedFFI-1.4.0-linux64" "build/vm")
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
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/packaging/linux/launch.sh.in
        ${CMAKE_CURRENT_BINARY_DIR}/build/packaging/linux/${VM_EXECUTABLE_NAME} @ONLY)
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/packaging/linux/bin/launch.sh.in
        ${CMAKE_CURRENT_BINARY_DIR}/build/packaging/linux/bin/${VM_EXECUTABLE_NAME} @ONLY)


    install(
      DIRECTORY "${CMAKE_BINARY_DIR}/build/packaging/linux/"
      DESTINATION "./"
      USE_SOURCE_PERMISSIONS
      COMPONENT ${INSTALL_COMPONENT})
    install(
      DIRECTORY "${CMAKE_BINARY_DIR}/build/vm/"
      DESTINATION "lib"
      USE_SOURCE_PERMISSIONS
      COMPONENT ${INSTALL_COMPONENT})
	install(
		DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build/libffi/install/lib/"
		DESTINATION "lib"
		USE_SOURCE_PERMISSIONS
		COMPONENT ${INSTALL_COMPONENT}
		FILES_MATCHING PATTERN ${DYLIB_EXT})


	install(
	    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/unix/"
	    DESTINATION include/pharovm
	    COMPONENT include
	    FILES_MATCHING PATTERN *.h)
endmacro()

macro(add_required_libs_per_platform)
  target_link_libraries(${VM_LIBRARY_NAME} dl)
  target_link_libraries(${VM_LIBRARY_NAME} m)
  target_link_libraries(${VM_LIBRARY_NAME} pthread)
endmacro()

set(LIBFFI_TARGET "")

set(LIBFFI_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/build/bin/libffi.so" "${CMAKE_CURRENT_BINARY_DIR}/build/bin/libffi.7.so")
set(DYLIB_EXT "*.so*")
set(LIBFFI_FILES "${CMAKE_CURRENT_BINARY_DIR}/build/libffi/install/lib/${DYLIB_EXT}")
