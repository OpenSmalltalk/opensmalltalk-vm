# VMMaker support file
#
# Manage the pharo-vm to C generation
#
# This support file defines the following variables
#
#     PHARO_VM_SLANG_VM_SOURCE_FILES        - a list of generated VM files
#     PHARO_VM_SLANG_PLUGIN_GENERATED_FILES - a list of generated plugin files
#
# and the following targets
#
#     generate_sources
#     vmmaker
#
# TODOs:
#  - Check at configure time that wget/curl are available? Otherwise this crashes miserably
#  - Make the VMFlavours autodescribed? Slang could output a list of generated files that we could use

if (GENERATE_PHARO_VM) 
	set(VMMAKER_PHARO_VM ${GENERATE_PHARO_VM})
else()
	set(VMMAKER_PHARO_VM ./pharo)
endif()

#Setting output directories
set(VMMAKER_OUTPUT_PATH "build/vmmaker")
make_directory(${VMMAKER_OUTPUT_PATH})

#The list of generated files given the flavour
if(FLAVOUR MATCHES "StackVM")
  set(PHARO_VM_SLANG_VM_SOURCE_FILES
    ${GENERATED_SOURCE_DIR}/generated/vm/src/gcc3x-interp.c)
else()
  set(PHARO_VM_SLANG_VM_SOURCE_FILES
    ${GENERATED_SOURCE_DIR}/generated/vm/src/cogit.c
    ${GENERATED_SOURCE_DIR}/generated/vm/src/gcc3x-cointerp.c)
endif()

set(PHARO_VM_SLANG_PLUGIN_GENERATED_FILES 
  	${GENERATED_SOURCE_DIR}/generated/plugins/src/FilePlugin/FilePlugin.c)


#Custom command that downloads a Pharo image and VM in ${VMMAKER_OUTPUT_PATH}
if(NOT GENERATE_PHARO_VM) 
  add_custom_command(
    OUTPUT ${VMMAKER_OUTPUT_PATH}/Pharo.image ${VMMAKER_OUTPUT_PATH}/pharo
    COMMAND wget -O - https://get.pharo.org/64/90 | bash
    COMMAND wget -O - https://get.pharo.org/64/vm90 | bash
    WORKING_DIRECTORY ${VMMAKER_OUTPUT_PATH}
    COMMENT "Downloading Pharo 90")
else()
  add_custom_command(
    OUTPUT ${VMMAKER_OUTPUT_PATH}/Pharo.image ${VMMAKER_OUTPUT_PATH}/pharo
    COMMAND wget -O - https://get.pharo.org/64/90 | bash
    WORKING_DIRECTORY ${VMMAKER_OUTPUT_PATH}
    COMMENT "Downloading Pharo 90")
endif()


add_custom_command(
  OUTPUT ${VMMAKER_OUTPUT_PATH}/VMMaker.image
  COMMAND ${VMMAKER_PHARO_VM} Pharo.image --save --quit ${CMAKE_CURRENT_SOURCE_DIR_TO_OUT}/scripts/installVMMaker.st ${CMAKE_CURRENT_SOURCE_DIR_TO_OUT}
  COMMAND ${VMMAKER_PHARO_VM} Pharo.image save VMMaker
  DEPENDS ${VMMAKER_OUTPUT_PATH}/Pharo.image
  WORKING_DIRECTORY ${VMMAKER_OUTPUT_PATH}
COMMENT "Generating VMMaker image")

#Custom command that generates the vm source code from VMMaker into ${VMMAKER_OUTPUT_PATH} and copies it to ${CMAKE_CURRENT_SOURCE_DIR}
if (NOT GENERATE_PHARO_VM)
  add_custom_command(
    OUTPUT ${VMSOURCEFILES} ${PLUGIN_GENERATED_FILES}
    COMMAND ${VMMAKER_OUTPUT_PATH}/pharo ${VMMAKER_OUTPUT_PATH}/VMMaker.image eval \"PharoVMMaker generate: \#\'${FLAVOUR}\' outputDirectory: \'${CMAKE_CURRENT_BINARY_DIR_TO_OUT}\'\"
    DEPENDS ${VMMAKER_OUTPUT_PATH}/VMMaker.image
    COMMENT "Generating VM files for flavour: ${FLAVOUR}")
else()
  add_custom_command(
    OUTPUT ${VMSOURCEFILES} ${PLUGIN_GENERATED_FILES}
    COMMAND ${VMMAKER_PHARO_VM} ${VMMAKER_OUTPUT_PATH}/VMMaker.image eval \"PharoVMMaker generate: \#\'${FLAVOUR}\' outputDirectory: \'${CMAKE_CURRENT_BINARY_DIR_TO_OUT}\'\"
    DEPENDS ${VMMAKER_OUTPUT_PATH}/VMMaker.image
    COMMENT "Generating VM files for flavour: ${FLAVOUR}")
endif()

#Define generated files as elements in the c-src component for packaging
install(FILES
  ${VMSOURCEFILES}
  DESTINATION pharo-vm/generated/vm
  COMPONENT c-src)
  
install(FILES
  ${PLUGIN_GENERATED_FILES}
  DESTINATION pharo-vm/generated/plugins
  COMPONENT c-src)

install(FILES
  ${VMSOURCEFILES}
  DESTINATION vm
  COMPONENT generated-src)
  
install(FILES
  ${PLUGIN_GENERATED_FILES}
  DESTINATION plugins
  COMPONENT generated-src)

add_custom_target(vmmaker DEPENDS ${VMMAKER_OUTPUT_PATH}/VMMaker.image)
add_custom_target(generate-sources DEPENDS ${VMSOURCEFILES} ${PLUGIN_GENERATED_FILES})