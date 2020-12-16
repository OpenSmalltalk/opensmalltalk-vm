# VMMaker support file
#
# Manage the pharo-vm to C generation
#
# This support file defines the following variables
#
#     VMSOURCEFILES        - a list of generated VM files
#     PLUGIN_GENERATED_FILES - a list of generated plugin files
#
# and the following targets
#
#     generate-sources
#     vmmaker
#
# TODOs:
#  - Make the VMFlavours autodescribed? Slang could output a list of generated files that we could use

set(CMAKE_VERBOSE_MAKEFILE TRUE)

#Setting vmmaker directory and image 
set( VMMAKER_DIR    "${CMAKE_CURRENT_BINARY_DIR_TO_OUT}/build/vmmaker")
set( VMMAKER_IMAGE  "${VMMAKER_DIR}/image/VMMaker.image")

if(${SIZEOF_VOID_P} STREQUAL "8")
    set(PHARO_CURRENT_GENERATED ${GENERATED_SOURCE_DIR}/generated/64)
else()
    set(PHARO_CURRENT_GENERATED ${GENERATED_SOURCE_DIR}/generated/32)
endif()

#The list of generated files given the flavour
if(FLAVOUR MATCHES "StackVM")
    if(FEATURE_GNUISATION)
        set(VMSOURCEFILES ${PHARO_CURRENT_GENERATED}/vm/src/gcc3x-interp.c)
    else()
        set(VMSOURCEFILES ${PHARO_CURRENT_GENERATED}/vm/src/interp.c)
    endif()
else()
set(VMSOURCEFILES
    ${PHARO_CURRENT_GENERATED}/vm/src/cogit.c
    ${PHARO_CURRENT_GENERATED}/vm/src/gcc3x-cointerp.c)
endif()

set(PLUGIN_GENERATED_FILES 
    ${PHARO_CURRENT_GENERATED}/plugins/src/FilePlugin/FilePlugin.c)

if(GENERATE_SOURCES)

    #Setting platform specific vmmaker virtual machine, with cached download or override
    if (GENERATE_PHARO_VM) 
        message("Overriding VM used for code generation")  
        set(VMMAKER_VM ${GENERATE_PHARO_VM})
    else()
        #Pick platform specific VM to download
        if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
            message("Defining Windows VM to download for code generation")
            set(VMMAKER_VM ${VMMAKER_DIR}/vm/PharoConsole.exe)
            set(VM_URL https://files.pharo.org/vm/pharo-spur64/win/PharoVM-8.6.1-e829a1da-StockReplacement-win64-bin_signed.zip)
            set(VM_URL_HASH SHA256=d24a2fb5d8d744a4c8ce0bc332051960d6f5d8db9f75754317b5aee8eafb7cb1)
        elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
            message("Defining Linux VM to download for code generation")
            set(VMMAKER_VM       ${VMMAKER_DIR}/vm/pharo)
            set(VM_URL https://files.pharo.org/vm/pharo-spur64/linux/PharoVM-8.6.1-e829a1d-StockReplacement-linux64-bin.zip)
            set(VM_URL_HASH      SHA256=4b2d6c48db00437c11b8f7ec72ba09bf39e4c23ab69119858fcb0c1a5b11fd1c)

        elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
            message("Defining OSX VM to download for code generation")
            set(VMMAKER_VM       ${VMMAKER_DIR}/vm/Contents/MacOS/Pharo)
            set(VM_URL https://files.pharo.org/vm/pharo-spur64/mac/PharoVM-8.6.1-e829a1da-StockReplacement-mac64-bin_signed.zip)
            set(VM_URL_HASH      SHA256=c8ad6f4a37a06fd61b6088ede81904ea51f7dbc9cc9043e7d82bc115e155c290)
        else()
            message(FATAL_ERROR "VM DOWNLOAD NOT HANDLED FOR CMAKE SYSTEM: CMAKE_SYSTEM_NAME")
        endif()

        #Download VM
        ExternalProject_Add(
            build_vmmaker_get_vm

            URL ${VM_URL}
            URL_HASH ${VM_URL_HASH}
            BUILD_COMMAND       echo 
            UPDATE_COMMAND      echo 
            CONFIGURE_COMMAND   echo 
            INSTALL_COMMAND     echo 

            PREFIX "${VMMAKER_DIR}"
            SOURCE_DIR "${VMMAKER_DIR}/vm"
            BUILD_IN_SOURCE True

            STEP_TARGETS   build
            )
    endif()

    #Bootstrap VMMaker.image from downloaded image
    ExternalProject_Add(
            build_vmmaker_get_image

            URL https://files.pharo.org/image/90/Pharo9.0-SNAPSHOT.build.839.sha.099690e.arch.64bit.zip
            URL_HASH SHA256=00c489f0516005d7ba7be259673eab1225ad9a4d1f90df9ce5082cbce4b47b82
            BUILD_COMMAND ${VMMAKER_VM} --headless ${VMMAKER_DIR}/image/Pharo9.0-SNAPSHOT-64bit-099690e.image save VMMaker
            COMMAND ${VMMAKER_VM} --headless ${VMMAKER_IMAGE} --save --quit "${CMAKE_CURRENT_SOURCE_DIR_TO_OUT}/scripts/installVMMaker.st" "${CMAKE_CURRENT_SOURCE_DIR_TO_OUT}"
            UPDATE_COMMAND      echo 
            CONFIGURE_COMMAND   echo
            INSTALL_COMMAND     echo

            PREFIX "${VMMAKER_DIR}"
            SOURCE_DIR "${VMMAKER_DIR}/image"
            BUILD_IN_SOURCE True
            WORKING_DIRECTORY "${VMMAKER_DIR}"

            DEPENDS build_vmmaker_get_vm-build
            )

    #Custom command that generates the vm source code from VMMaker into "out/build/XXXX/generated" folder
    add_custom_command(
        OUTPUT ${VMSOURCEFILES} ${PLUGIN_GENERATED_FILES}
        COMMAND ${VMMAKER_VM} --headless ${VMMAKER_IMAGE} eval \"PharoVMMaker generate: \#\'${FLAVOUR}\' outputDirectory: \'${CMAKE_CURRENT_BINARY_DIR_TO_OUT}\'\"
        DEPENDS build_vmmaker_get_image
        COMMENT "Generating VM files for flavour: ${FLAVOUR}")

    #Define generated files as elements in the c-src component for packaging
    install(DIRECTORY
    ${CMAKE_CURRENT_BINARY_DIR}/generated/
    DESTINATION pharo-vm/generated/
    COMPONENT c-src)

    install(
    DIRECTORY "${GENERATED_SOURCE_DIR}/generated/32/vm/include/"
    DESTINATION include/pharovm
    COMPONENT include
    FILES_MATCHING PATTERN *.h)
    
    add_custom_target(vmmaker DEPENDS ${VMMAKER_OUTPUT_PATH}/VMMaker.image)
    add_custom_target(generate-sources DEPENDS ${VMSOURCEFILES} ${PLUGIN_GENERATED_FILES})

endif()
