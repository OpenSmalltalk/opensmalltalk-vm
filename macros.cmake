macro(addLibraryWithRPATH NAME)
    SET(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
    set(CMAKE_INSTALL_RPATH "@executable_path/Plugins")

    add_library(${NAME} SHARED ${ARGN})
    set_target_properties(${NAME} PROPERTIES MACOSX_RPATH ON)
    set_target_properties(${NAME} PROPERTIES INSTALL_NAME_DIR "@executable_path/Plugins")
endmacro()


macro(get_platform_name VARNAME)
    if(WIN)
        set(${VARNAME} "win")
    else()    
        if(OSX)
            set(${VARNAME} "mac")
        else()
            set(${VARNAME} "linux")
        endif()
    endif()
endmacro()

macro(get_full_platform_name VARNAME)
    
    if(SIZEOF_VOID_P EQUAL 8)
        set(ARCH 64)
    else()    
        set(ARCH 32)
    endif()

    if(WIN)
        set(${VARNAME} "win${ARCH}")
    else()    
        if(OSX)
            set(${VARNAME} "mac${ARCH}")
        else()
            set(${VARNAME} "linux${ARCH}")
        endif()
    endif()
endmacro()


macro(add_third_party_dependency NAME TARGETPATH)

    get_platform_name(PLATNAME)
    
    message("Adding third-party libraries for ${PLATNAME}: ${NAME}")

    add_custom_command(OUTPUT "build/third-party/${NAME}.zip"
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_SOURCE_DIR}/build/third-party
        COMMAND ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/build/third-party wget --no-check-certificate "https://files.pharo.org/vm/pharo-spur64/${PLATNAME}/third-party/${NAME}.zip"
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

    add_custom_command(OUTPUT "build/third-party/${NAME}.done"
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_SOURCE_DIR}/${TARGETPATH}
        COMMAND ${CMAKE_COMMAND} -E chdir ${CMAKE_SOURCE_DIR}/build/third-party unzip -o "${NAME}.zip" -d ${CMAKE_SOURCE_DIR}/${TARGETPATH}
        COMMAND ${CMAKE_COMMAND} -E touch "build/third-party/${NAME}.done"
        DEPENDS "build/third-party/${NAME}.zip"
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

    add_custom_target(${NAME} ALL DEPENDS "build/third-party/${NAME}.done")        
    add_dependencies(${NAME} ${VM_EXECUTABLE_NAME} )
endmacro()

macro(get_commit_hash VARNAME)
    execute_process(
        COMMAND git log -1 --format=%h
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE ${VARNAME}
        OUTPUT_STRIP_TRAILING_WHITESPACE)
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

macro(get_git_describe VARNAME)
    execute_process(
        COMMAND git describe
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        OUTPUT_VARIABLE ${VARNAME}
        OUTPUT_STRIP_TRAILING_WHITESPACE)
endmacro()