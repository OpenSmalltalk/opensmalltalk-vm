include(ExternalProject)

# Thirdparty cache base directory.
set(ThirdPartyCacheDirectory "${CMAKE_CURRENT_SOURCE_DIR}/.thirdparty-cache/cmake")
set(ThirdPartyCacheDownloadDirectory "${ThirdPartyCacheDirectory}")

## OS name
if(WIN32)
    set(ThirdPartyCacheOSName windows)
elseif(UNIX)
    if(DARWIN)
        set(ThirdPartyCacheOSName osx)
    else()
        set(ThirdPartyCacheOSName linux)
    endif()
else()
    set(ThirdPartyCacheOSName "${CMAKE_SYSTEM_NAME}")
endif()

## CPU architecture name.
if(SQUEAK_PLATFORM_X86_32)
    set(ThirdPartyCacheArchName i386)
elseif(SQUEAK_PLATFORM_X86_64)
    set(ThirdPartyCacheArchName x86_64)
else()
    set(ThirdPartyCacheArchName "${CMAKE_SYSTEM_PROCESSOR}")
endif()

## Thirdparty cache install dir.
set(ThirdPartyCacheInstall "${ThirdPartyCacheDirectory}/${ThirdPartyCacheOSName}/${ThirdPartyCacheArchName}")
set(ThirdPartyCacheInstallLib "${ThirdPartyCacheInstall}/lib")
set(ThirdPartyCacheInstallInclude "${ThirdPartyCacheInstall}/include")

message(STATUS "Third party cache download location ${ThirdPartyCacheDownloadDirectory}")
message(STATUS "Third party cache prefix ${ThirdPartyCacheInstall}")

## Function for checking a list of files exists. This is used to avoid
## rebuilding cached thirdparty dependencies.
function(CHECK_THIRDPARTY_BUILD_FILES_EXIST ResultVar)
    set(${ResultVar} TRUE)
    foreach(file ${ARGN})
        if(NOT (EXISTS "${ThirdPartyCacheInstall}/${file}"))
            set(${ResultVar} FALSE)
        endif()
    endforeach()

    set(${ResultVar} ${${ResultVar}} PARENT_SCOPE)
endfunction()

## Function for checking whether a platform dependent list of build artifacts
## does exists.
function(CHECK_THIRDPARTY_BUILD_ARTIFACTS ResultVar)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs
        EXTRA_BUILD_ARTIFACTS
        MAC_LIBRARIES
        LINUX_LIBRARIES
        WINDOWS_DLLS)

    cmake_parse_arguments(ARTIFACT_KIND "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN} )

    set(ExpectedBuildArtifacts ${ARTIFACT_KIND_EXTRA_BUILD_ARTIFACTS})

    if(DARWIN)
        foreach(artifactName ${ARTIFACT_KIND_MAC_LIBRARIES})
            list(APPEND ExpectedBuildArtifacts "lib/${artifactName}")
        endforeach()
    elseif(WIN32)
        foreach(artifactName ${ARTIFACT_KIND_WINDOWS_DLLS})
            list(APPEND ExpectedBuildArtifacts "bin/${artifactName}")
        endforeach()
    else()
        foreach(artifactName ${ARTIFACT_KIND_LINUX_LIBRARIES})
            list(APPEND ExpectedBuildArtifacts "lib/${artifactName}")
        endforeach()
    endif()

    CHECK_THIRDPARTY_BUILD_FILES_EXIST(${ResultVar} ${ExpectedBuildArtifacts})
    set(${ResultVar} ${${ResultVar}} PARENT_SCOPE)
endfunction()

## This function adds rules for installing the relevant build artifacts to the
## main result.
function(INSTALL_THIRDPARTY_BUILD_ARTIFACTS ThirdpartyProjectName)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs
        MAC_LIBRARIES
        MAC_LIBRARIES_SYMLINK_PATTERNS
        LINUX_LIBRARIES
        LINUX_LIBRARIES_SYMLINK_PATTERNS
        WINDOWS_DLLS)

    cmake_parse_arguments(ARTIFACT_KIND "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN} )

    set(InstallLibraryFileNames)
    set(InstallLibrarySourceFolder lib)
    set(InstallLibraryDestFolder "${ProductInstallProgramFolder}")
    set(InstallLibraryGlobPatterns)

    if(DARWIN)
        set(InstallLibraryFileNames ${ARTIFACT_KIND_MAC_LIBRARIES})
        set(InstallLibraryGlobPatterns ${ARTIFACT_KIND_MAC_LIBRARIES_SYMLINK_PATTERNS})
    elseif(WIN32)
        set(InstallLibrarySourceFolder bin)
        set(InstallLibraryFileNames ${WINDOWS_DLLS})
    else()
        set(InstallLibraryFileNames ${ARTIFACT_KIND_LINUX_LIBRARIES})
        set(InstallLibraryGlobPatterns ${ARTIFACT_KIND_LINUX_LIBRARIES_SYMLINK_PATTERNS})
    endif()

    ## CMake install(DIRECTORY ...) does not exclude subdirectories, So we
    set(InstallScriptFileName "${CMAKE_CURRENT_BINARY_DIR}/${ThirdpartyProjectName}-install.cmake")
    configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/ThirdPartyDependencyInstallScript.cmake.in"
        "${InstallScriptFileName}" @ONLY IMMEDIATE)
    install(SCRIPT "${InstallScriptFileName}")
endfunction()

## This function adds an autoconf based thirdparty dependency.
function(ADD_THIRDPARTY_WITH_AUTOCONF NAME)
    set(options)
    set(oneValueArgs DOWNLOAD_URL ARCHIVE_NAME ARCHIVE_SHA256 UNPACK_DIR_NAME CFLAGS LDFLAGS)
    set(multiValueArgs
        AUTOCONF_EXTRA_ARGS
        DEPENDENCIES
        EXTRA_BUILD_ARTIFACTS
        MAC_LIBRARIES
        MAC_LIBRARIES_SYMLINK_PATTERNS
        LINUX_LIBRARIES
        LINUX_LIBRARIES_SYMLINK_PATTERNS
        WINDOWS_DLLS)

    cmake_parse_arguments(parsed_arguments "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN} )
    # Compute the actually used build artifacts.
    check_thirdparty_build_artifacts(HaveCachedBuildArtifacts
        EXTRA_BUILD_ARTIFACTS ${parsed_arguments_EXTRA_BUILD_ARTIFACTS}
        MAC_LIBRARIES ${parsed_arguments_MAC_LIBRARIES}
        LINUX_LIBRARIES ${parsed_arguments_LINUX_LIBRARIES}
        WINDOWS_DLLS ${parsed_arguments_WINDOWS_DLLS}
    )

    if(HaveCachedBuildArtifacts)
        message(STATUS "Not building cached third-party dependency ${NAME}.")
        set(${NAME}_BuildDep PARENT_SCOPE)
    else()
        set(autoconf_cflags "${parsed_arguments_CFLAGS}")
        set(autoconf_ldflags "${parsed_arguments_LDFLAGS} ")

        if(DARWIN)
            if(SQUEAK_PLATFORM_X86_32)
                set(autoconf_cflags "${autoconf_cflags} -arch i386")
                set(autoconf_ldflags "${autoconf_ldflags} -arch i386")
            elseif(SQUEAK_PLATFORM_X86_64)
                set(autoconf_cflags "${autoconf_cflags} -arch x86_64")
                set(autoconf_ldflags "${autoconf_ldflags} -arch x86_64")
            endif()
        else()
            if(SQUEAK_PLATFORM_X86_32)
                set(autoconf_cflags "${autoconf_cflags} -m32")
                set(autoconf_ldflags "${autoconf_ldflags} -m32")
            elseif(SQUEAK_PLATFORM_X86_64)
                set(autoconf_cflags "${autoconf_cflags} -m64")
                set(autoconf_ldflags "${autoconf_ldflags} -m64")
            endif()
        endif()

        set(autoconf_cflags "${autoconf_cflags} -I${ThirdPartyCacheInstallInclude}")
        set(autoconf_ldflags "${autoconf_ldflags} -L${ThirdPartyCacheInstallLib}")

        set(thirdparty_autoconf_command "./configure"
            "--prefix=${ThirdPartyCacheInstall}"
            ${parsed_arguments_AUTOCONF_EXTRA_ARGS}
            "CFLAGS=${autoconf_cflags}"
            "LDFLAGS=${autoconf_ldflags}"
        )

        ExternalProject_Add(${NAME}
            URL "${parsed_arguments_DOWNLOAD_URL}"
            URL_HASH "SHA256=${parsed_arguments_ARCHIVE_SHA256}"
            DOWNLOAD_NAME "${parsed_arguments_ARCHIVE_NAME}"
            DOWNLOAD_DIR "${ThirdPartyCacheDownloadDirectory}"
            PREFIX "${CMAKE_CURRENT_BINARY_DIR}/thirdparty/${NAME}"
            CONFIGURE_COMMAND "${thirdparty_autoconf_command}"
            BUILD_IN_SOURCE TRUE
        )

        foreach(dep ${parsed_arguments_DEPENDENCIES})
            add_dependencies(${NAME} ${dep})
        endforeach()
        set(${NAME}_BuildDep ${NAME} PARENT_SCOPE)
    endif()

    ## Install the relevant build artifacts
    install_thirdparty_build_artifacts(${NAME}
        MAC_LIBRARIES ${parsed_arguments_MAC_LIBRARIES}
        MAC_LIBRARIES_SYMLINK_PATTERNS ${parsed_arguments_MAC_LIBRARIES_SYMLINK_PATTERNS}
        LINUX_LIBRARIES ${parsed_arguments_LINUX_LIBRARIES}
        LINUX_LIBRARIES_SYMLINK_PATTERNS ${parsed_arguments_LINUX_LIBRARIES_SYMLINK_PATTERNS}
        WINDOWS_DLLS ${parsed_arguments_WINDOWS_DLLS}
    )
endfunction()

function(ADD_THIRDPARTY_WITH_CMAKE NAME)
    set(options)
    set(oneValueArgs DOWNLOAD_URL ARCHIVE_NAME ARCHIVE_SHA256 UNPACK_DIR_NAME CFLAGS CXXFLAGS LDFLAGS)
    set(multiValueArgs
        CMAKE_EXTRA_ARGS
        DEPENDENCIES
        EXTRA_BUILD_ARTIFACTS
        MAC_LIBRARIES
        MAC_LIBRARIES_SYMLINK_PATTERNS
        LINUX_LIBRARIES
        LINUX_LIBRARIES_SYMLINK_PATTERNS
        WINDOWS_DLLS)

    cmake_parse_arguments(parsed_arguments "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN} )
    # Compute the actually used build artifacts.
    check_thirdparty_build_artifacts(HaveCachedBuildArtifacts
        EXTRA_BUILD_ARTIFACTS ${parsed_arguments_EXTRA_BUILD_ARTIFACTS}
        MAC_LIBRARIES ${parsed_arguments_MAC_LIBRARIES}
        LINUX_LIBRARIES ${parsed_arguments_LINUX_LIBRARIES}
        WINDOWS_DLLS ${parsed_arguments_WINDOWS_DLLS}
    )

    if(HaveCachedBuildArtifacts)
        message(STATUS "Not building cached third-party dependency ${NAME}.")
        set(${NAME}_BuildDep PARENT_SCOPE)
    else()
        set(cmake_cflags "${parsed_arguments_CFLAGS}")
        set(cmake_cxxflags "${parsed_arguments_CXXFLAGS}")
        set(cmake_ldflags "${parsed_arguments_LDFLAGS} ")

        if(DARWIN)
            if(SQUEAK_PLATFORM_X86_32)
                set(cmake_cflags "${cmake_cflags} -arch i386")
                set(cmake_cxxflags "${cmake_cxxflags} -arch i386")
                set(cmake_ldflags "${cmake_ldflags} -arch i386")
            elseif(SQUEAK_PLATFORM_X86_64)
                set(cmake_cflags "${cmake_cflags} -arch x86_64")
                set(cmake_cxxflags "${cmake_cxxflags} -arch x86_64")
                set(cmake_ldflags "${cmake_ldflags} -arch x86_64")
            endif()
        else()
            if(SQUEAK_PLATFORM_X86_32)
                set(cmake_cflags "${cmake_cflags} -m32")
                set(cmake_cxxflags "${cmake_cxxflags} -m32")
                set(cmake_ldflags "${cmake_ldflags} -m32")
            elseif(SQUEAK_PLATFORM_X86_64)
                set(cmake_cflags "${cmake_cflags} -m64")
                set(cmake_cxxflags "${cmake_cxxflags} -m64")
                set(cmake_ldflags "${cmake_ldflags} -m64")
            endif()
        endif()

        set(cmake_cflags "${cmake_cflags} -I${ThirdPartyCacheInstallInclude}")
        set(cmake_ldflags "${cmake_ldflags} -L${ThirdPartyCacheInstallLib}")

        set(thirdparty_cmake_command cmake "../${NAME}"
            "-DCMAKE_INSTALL_PREFIX=${ThirdPartyCacheInstall}"
            "-DCMAKE_PREFIX_PATH=${ThirdPartyCacheInstall}"
            "-DCMAKE_C_FLAGS=${cmake_cflags}"
            "-DCMAKE_CXX_FLAGS=${cmake_cxxflags}"
            ${parsed_arguments_CMAKE_EXTRA_ARGS}
        )

        ExternalProject_Add(${NAME}
            URL "${parsed_arguments_DOWNLOAD_URL}"
            URL_HASH "SHA256=${parsed_arguments_ARCHIVE_SHA256}"
            DOWNLOAD_NAME "${parsed_arguments_ARCHIVE_NAME}"
            DOWNLOAD_DIR "${ThirdPartyCacheDownloadDirectory}"
            PREFIX "${CMAKE_CURRENT_BINARY_DIR}/thirdparty/${NAME}"
            CONFIGURE_COMMAND "${thirdparty_cmake_command}"
            BUILD_IN_SOURCE FALSE
        )

        foreach(dep ${parsed_arguments_DEPENDENCIES})
            add_dependencies(${NAME} ${dep})
        endforeach()
        set(${NAME}_BuildDep ${NAME} PARENT_SCOPE)
    endif()

    ## Install the relevant build artifacts
    install_thirdparty_build_artifacts(${NAME}
        MAC_LIBRARIES ${parsed_arguments_MAC_LIBRARIES}
        MAC_LIBRARIES_SYMLINK_PATTERNS ${parsed_arguments_MAC_LIBRARIES_SYMLINK_PATTERNS}
        LINUX_LIBRARIES ${parsed_arguments_LINUX_LIBRARIES}
        LINUX_LIBRARIES_SYMLINK_PATTERNS ${parsed_arguments_LINUX_LIBRARIES_SYMLINK_PATTERNS}
        WINDOWS_DLLS ${parsed_arguments_WINDOWS_DLLS}
    )
endfunction()
