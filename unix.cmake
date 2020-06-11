include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/unix
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
    add_third_party_dependency("PThreadedFFI-1.3.1-linux64" "build/vm")
    add_third_party_dependency("libffi-3.3-rc0" "build/vm")
    add_third_party_dependency("libgit2-0.25.1" "build/vm")
    add_third_party_dependency_with_baseurl("libgit2-linux-1.0.0" "build/vm" "https://github.com/guillep/libgit_build/releases/download/v1.0.1")
    add_third_party_dependency("libssh2-1.7.0" "build/vm")
    add_third_party_dependency("openssl-1.0.2q" "build/vm")
    add_third_party_dependency("SDL2-2.0.7" "build/vm")
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
