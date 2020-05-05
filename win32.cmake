set(VM_EXECUTABLE_CONSOLE_NAME "${VM_EXECUTABLE_NAME}Console")
set(VM_VERSION_FILEVERSION "${APPNAME}VM-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}-${GIT_COMMIT_HASH}")

set(Win32ResourcesFolder "${CMAKE_CURRENT_SOURCE_DIR}/resources/windows")
if(NOT Win32VMExecutableIcon)
    set(Win32VMExecutableIcon "${Win32ResourcesFolder}/Pharo.ico")
endif()
set(Win32Resource "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}.rc")
set(Win32DLLResource "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}DLL.rc")
set(Win32Manifest "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}.exe.manifest")
set(Win32ConsoleManifest "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_CONSOLE_NAME}.exe.manifest")

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/win
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/common
)

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

set(VM_FRONTEND_SOURCES_COMMON
    ${Win32Resource}
)

set(VM_FRONTEND_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/win32Main.c
    ${Win32Manifest}
    ${VM_FRONTEND_SOURCES_COMMON})

set(VM_CONSOLE_FRONTEND_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/unixMain.c
    ${Win32ConsoleManifest}
    ${VM_FRONTEND_SOURCES_COMMON})

set(VM_FRONTEND_APPLICATION_TYPE WIN32)

configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_NAME}.rc.in" "${Win32Resource}" @ONLY IMMEDIATE)
configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_NAME}DLL.rc.in" "${Win32DLLResource}" @ONLY IMMEDIATE)
configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_NAME}.exe.manifest.in" "${Win32Manifest}" @ONLY IMMEDIATE)
configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_NAME}.exe.manifest.in" "${Win32ConsoleManifest}" @ONLY IMMEDIATE)

macro(add_third_party_dependencies_per_platform)
    add_third_party_dependency("pixman-0.34.0" "build/vm")
    add_third_party_dependency("cairo-1.15.4" "build/vm")
    add_third_party_dependency("freetype-2.9.1" "build/vm")
    add_third_party_dependency("libffi-3.3-rc0" "build/vm")
    add_third_party_dependency("libgit2-0.25.1-fixLibGit" "build/vm")
    add_third_party_dependency("libpng-1.6.34" "build/vm")
    add_third_party_dependency("libssh2-1.9.0" "build/vm")
    add_third_party_dependency("openssl-1.0.2q-fixLigGit" "build/vm")
    add_third_party_dependency("gcc-runtime-3.4" "build/vm")
    add_third_party_dependency("zlib-1.2.11-fixLibGit" "build/vm")
    add_third_party_dependency("SDL2-2.0.5" "build/vm")
    add_third_party_dependency("PThreadedFFI-1.3.0-win64" "build/vm")
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

   target_link_libraries(${VM_LIBRARY_NAME} pthread)
   target_link_libraries(${VM_EXECUTABLE_NAME} Ole32)
   target_link_libraries(${VM_EXECUTABLE_NAME} comctl32)
   target_link_libraries(${VM_EXECUTABLE_NAME} uuid)

   target_link_libraries(${VM_EXECUTABLE_CONSOLE_NAME} Ole32)
   target_link_libraries(${VM_EXECUTABLE_CONSOLE_NAME} comctl32)
   target_link_libraries(${VM_EXECUTABLE_CONSOLE_NAME} uuid)

   set_target_properties(${VM_EXECUTABLE_NAME} PROPERTIES LINK_FLAGS "-mwindows")
   set_target_properties(${VM_EXECUTABLE_CONSOLE_NAME} PROPERTIES LINK_FLAGS "-mconsole")
endmacro()
