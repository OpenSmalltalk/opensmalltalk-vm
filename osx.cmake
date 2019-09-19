include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/osx
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
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/unix/sqUnixHeartbeat.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/debugUnix.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/utilsMac.mm

#Virtual Memory functions
    ${CMAKE_CURRENT_SOURCE_DIR}/src/memoryUnix.c
)

set(VM_FRONTEND_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/main.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/parameters.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/macOpenFileDialog.mm)

configure_file(resources/mac/Info.plist.in build/includes/Info.plist)

macro(add_third_party_dependencies_per_platform)
    add_third_party_dependency("pixman-0.34.0" "build/vm")
    add_third_party_dependency("cairo-1.15.4" "build/vm")
    add_third_party_dependency("freetype-2.9.1" "build/vm")
    add_third_party_dependency("libffi-3.3-rc0" "build/vm")
    add_third_party_dependency("libgit2-0.25.1" "build/vm")
    add_third_party_dependency("libpng-1.2.49" "build/vm")
    add_third_party_dependency("libssh2-1.7.0" "build/vm")
    add_third_party_dependency("openssl-1.0.2q" "build/vm")
    add_third_party_dependency("PThreadedFFI-1.0.2-osx64" "build/vm")
    add_third_party_dependency("SDL2-2.0.7" "build/vm")
endmacro()

macro(configure_installables INSTALL_COMPONENT)
    set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/build/dist")
    
    install(
      DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build/vm/"
      DESTINATION "Pharo.app/Contents/MacOS"
      COMPONENT ${INSTALL_COMPONENT}
      USE_SOURCE_PERMISSIONS FILES_MATCHING PATTERN ${VM_EXECUTABLE_NAME})
    install(
      DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build/vm/"
      DESTINATION "Pharo.app/Contents/MacOS/Plugins"
      COMPONENT ${INSTALL_COMPONENT}
      USE_SOURCE_PERMISSIONS FILES_MATCHING PATTERN *.dylib)
    install(
      FILES "${CMAKE_CURRENT_BINARY_DIR}/build/includes/Info.plist"
      DESTINATION "Pharo.app/Contents"
      COMPONENT ${INSTALL_COMPONENT})
    install(
      FILES "${CMAKE_CURRENT_SOURCE_DIR}/resources/mac/Pharo.icns"
      DESTINATION "Pharo.app/Contents/Resources"
      COMPONENT ${INSTALL_COMPONENT})
endmacro()

macro(add_required_libs_per_platform)
   target_link_libraries(${VM_LIBRARY_NAME} "-framework AppKit")

   target_link_libraries(${VM_EXECUTABLE_NAME} "-framework AppKit")
   target_link_libraries(${VM_EXECUTABLE_NAME} "-framework CoreGraphics")
endmacro()