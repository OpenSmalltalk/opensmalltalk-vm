include_directories(
    extracted/vm/include/osx
    extracted/vm/include/unix
    extracted/vm/include/common
    generated/vm/include
)

set(GENERATED_SOURCES
    generated/vm/src/cogit.c
    generated/vm/src/gcc3x-cointerp.c
)

set(EXTRACTED_SOURCES
#Common sources
    extracted/vm/src/common/sqHeapMap.c
    extracted/vm/src/common/sqVirtualMachine.c
    extracted/vm/src/common/sqNamedPrims.c
    extracted/vm/src/common/sqExternalSemaphores.c
    extracted/vm/src/common/sqTicker.c

#Platform sources
    extracted/vm/src/unix/aio.c
    extracted/vm/src/unix/sqUnixHeartbeat.c

#Virtual Memory functions
    src/memoryUnix.c
)

set(VM_FRONTEND_SOURCES
    src/main.c
    src/macOpenFileDialog.mm)

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
    add_third_party_dependency("pthreadedPlugin-0.0.1" "build/vm")
    add_third_party_dependency("SDL2-2.0.7" "build/vm")
endmacro()

macro(configure_installables)
    set(CMAKE_INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/build/dist")
    
    install(DIRECTORY "${CMAKE_SOURCE_DIR}/build/vm/" DESTINATION "Pharo.app/Contents/MacOS" USE_SOURCE_PERMISSIONS FILES_MATCHING PATTERN ${VM_EXECUTABLE_NAME})
    install(DIRECTORY "${CMAKE_SOURCE_DIR}/build/vm/" DESTINATION "Pharo.app/Contents/MacOS/Plugins" USE_SOURCE_PERMISSIONS FILES_MATCHING PATTERN *.dylib )
    install(FILES "build/includes/Info.plist" DESTINATION "Pharo.app/Contents")
    install(FILES "resources/mac/Pharo.icns" DESTINATION "Pharo.app/Contents/Resources")
endmacro()

macro(generate_vm_code)
  ensure_pharo_vmmaker()
  execute_process(
    COMMAND ./pharo Pharo.image eval PharoVMMaker generateCoInterpreter
    RESULT_VARIABLE SUCCESS
  )
  assert(SUCCESS 0 "Could not generate sources")
endmacro()

macro(ensure_pharo_vmmaker)
  ensure_pharo()
  if(NOT PHARO_IMAGE_SETUP)
    execute_process(
      COMMAND ./pharo Pharo.image --save --quit scripts/installVMMaker.st
      RESULT_VARIABLE SUCCESS
    )
    assert(SUCCESS 0 "Could not setup VMMaker setup")
    set(PHARO_IMAGE_SETUP TRUE CACHE BOOL "Has the image been setup with VMMaker?" FORCE)
  endif()
endmacro()

macro(ensure_pharo)
  if(NOT PHARO_DOWNLOAD_HAPPENED)
    execute_process(
      COMMAND bash -c "rm -rf Pharo.image Pharo.changes pharo-vm pharo-ui pharo Pharo*.sources"
      COMMAND wget -O - get.pharo.org/64/70+vm
      COMMAND bash
      RESULT_VARIABLE SUCCESS
    )
    assert(SUCCESS 0 "Could not download Pharo image")
    set(PHARO_DOWNLOAD_HAPPENED TRUE CACHE BOOL "Has the Pharo download happened?" FORCE)
  endif()
endmacro()

macro(assert value expected message)
  if(NOT ${value} EQUAL ${expected})
    MESSAGE(FATAL_ERROR ${message})
  endif()
endmacro()