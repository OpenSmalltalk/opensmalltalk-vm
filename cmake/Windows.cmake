set(WIN 1)

set(VM_EXECUTABLE_CONSOLE_NAME "${VM_EXECUTABLE_NAME}Console")
set(VM_VERSION_FILEVERSION "${APPNAME}VM-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}-${GIT_COMMIT_HASH}")

set(Win32ResourcesFolder "${CMAKE_CURRENT_SOURCE_DIR}/resources/windows")
if(NOT Win32VMExecutableIcon)
    set(Win32VMExecutableIcon "${Win32ResourcesFolder}/Pharo.ico")
endif()
set(Win32Resource "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}.rc")
set(Win32ConsoleResource "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_CONSOLE_NAME}.rc")
set(Win32DLLResource "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}DLL.rc")
set(Win32Manifest "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}.exe.manifest")
set(Win32ConsoleManifest "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_CONSOLE_NAME}.exe.manifest")

function(add_platform_headers)
    target_include_directories(${VM_LIBRARY_NAME}
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/win
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/common
    )
endfunction()

set(EXTRACTED_SOURCES
#Common sources
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/common/sqHeapMap.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/common/sqVirtualMachine.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/common/sqNamedPrims.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/common/sqExternalSemaphores.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/common/sqTicker.c

#Platform sources
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/win/sqWin32SpurAlloc.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/win/aioWin.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/debugWin.c

# Support sources
    ${CMAKE_CURRENT_SOURCE_DIR}/src/fileDialogWin32.c

# Resource with DLL version info.
    ${Win32DLLResource}
)

set(VM_FRONTEND_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/win32Main.c
    ${Win32Resource})

set(VM_CONSOLE_FRONTEND_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/unixMain.c
    ${Win32ConsoleResource})

set(VM_FRONTEND_APPLICATION_TYPE WIN32)

configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_NAME}.rc.in" "${Win32Resource}" @ONLY IMMEDIATE)
configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_NAME}DLL.rc.in" "${Win32DLLResource}" @ONLY IMMEDIATE)
configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_NAME}.exe.manifest.in" "${Win32Manifest}" @ONLY IMMEDIATE)
configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_CONSOLE_NAME}.rc.in" "${Win32ConsoleResource}" @ONLY IMMEDIATE)
configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_CONSOLE_NAME}.exe.manifest.in" "${Win32ConsoleManifest}" @ONLY IMMEDIATE)

macro(add_third_party_dependencies_per_platform)

    if (DOWNLOAD_DEPENDENCIES)
        # Backwards compatibility for those using PThreaded Plugin
        # Current support is in the VM
        add_third_party_dependency("PThreadedFFI-1.4.0-win64" "build/vm")
		add_third_party_dependency("gcc-runtime-3.4" "build/vm")
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
          DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build/vm/"
          DESTINATION "./"
          COMPONENT ${INSTALL_COMPONENT}
          FILES_MATCHING PATTERN *.dll
          PERMISSIONS OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

    install(
          DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build/vm/"
          USE_SOURCE_PERMISSIONS
          DESTINATION "./"
          USE_SOURCE_PERMISSIONS
          COMPONENT ${INSTALL_COMPONENT}
          FILES_MATCHING
            PATTERN *
            PATTERN *.dll EXCLUDE)

	install(
		DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build/libffi/install/bin/"
		DESTINATION "./"
		COMPONENT ${INSTALL_COMPONENT}
		FILES_MATCHING PATTERN *.dll
		PERMISSIONS OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

	install(
	    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/win/"
	    DESTINATION include/pharovm
	    COMPONENT include
	    FILES_MATCHING PATTERN *.h)

endmacro()

macro(add_required_libs_per_platform)
	add_executable(${VM_EXECUTABLE_CONSOLE_NAME} ${VM_CONSOLE_FRONTEND_SOURCES})
	target_link_libraries(${VM_EXECUTABLE_CONSOLE_NAME} ${VM_LIBRARY_NAME})

	target_link_libraries(${VM_LIBRARY_NAME} winmm)
	target_link_libraries(${VM_LIBRARY_NAME} Ws2_32)
	target_link_libraries(${VM_LIBRARY_NAME} DbgHelp)
	target_link_libraries(${VM_LIBRARY_NAME} Ole32)
	target_link_libraries(${VM_LIBRARY_NAME} comctl32)
	target_link_libraries(${VM_LIBRARY_NAME} uuid)

	if(${CYGWIN})
		target_link_libraries(${VM_LIBRARY_NAME} pthread)
	endif()
	target_link_libraries(${VM_EXECUTABLE_NAME} Ole32)
	target_link_libraries(${VM_EXECUTABLE_NAME} comctl32)
	target_link_libraries(${VM_EXECUTABLE_NAME} uuid)

	target_link_libraries(${VM_EXECUTABLE_CONSOLE_NAME} Ole32)
	target_link_libraries(${VM_EXECUTABLE_CONSOLE_NAME} comctl32)
	target_link_libraries(${VM_EXECUTABLE_CONSOLE_NAME} uuid)

	set_target_properties(${VM_EXECUTABLE_NAME} PROPERTIES LINK_FLAGS "-mwindows")
	set_target_properties(${VM_EXECUTABLE_CONSOLE_NAME} PROPERTIES LINK_FLAGS "-mconsole")
endmacro()

set(LIBFFI_TARGET "--target=x86_64-unknown-cygwin")
set(LIBFFI_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/build/libffi/install/bin/cygffi-7.dll")
set(LIBFFI_FILES "${CMAKE_CURRENT_BINARY_DIR}/build/libffi/install/bin/cygffi-7.dll")
set(LIBFFI_ADDITIONAL "AR=${CMAKE_TOOLCHAIN_PREFIX}-ar.exe" "DLLTOOL=${CMAKE_TOOLCHAIN_PREFIX}-dlltool.exe")