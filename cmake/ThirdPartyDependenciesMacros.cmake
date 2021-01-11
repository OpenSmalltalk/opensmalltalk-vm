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
set(ThirdPartyCacheInstallBin "${ThirdPartyCacheInstall}/bin")
set(ThirdPartyCacheInstallLib "${ThirdPartyCacheInstall}/lib")
set(ThirdPartyCacheInstallInclude "${ThirdPartyCacheInstall}/include")
include_directories(${ThirdPartyCacheInstallInclude})

message(STATUS "Third party cache download location ${ThirdPartyCacheDownloadDirectory}")
message(STATUS "Third party cache prefix ${ThirdPartyCacheInstall}")

## On OS X, we cannot just copy the libraries. We use this hack to integrate
## the libraries with the bundle creation utilities.
if(DARWIN)
    set(ThirdPartyLibrariesFileNames "" CACHE INTERNAL "List of built libraries to bundle.")
    set(ThirdPartyLibrariesPatterns "" CACHE INTERNAL "List of built libraries glob patterns to bundle.")
endif()

option(LOG_THIRD_PARTY_BUILD_TO_FILE "Logs the build processes of third party dependencies to file if enabled, otherwise the output is " ON)

# Some variables that could be different for third party projects.
if(NOT THIRDPARTY_C_COMPILER)
    set(THIRDPARTY_C_COMPILER "${CMAKE_C_COMPILER}")
endif()
if(NOT THIRDPARTY_CXX_COMPILER)
    set(THIRDPARTY_CXX_COMPILER "${CMAKE_CXX_COMPILER}")
endif()
if(NOT THIRDPARTY_CMAKE_TOOLCHAIN_FILE)
    if(CMAKE_TOOLCHAIN_FILE)
        set(THIRDPARTY_CMAKE_TOOLCHAIN_FILE "${CMAKE_TOOLCHAIN_FILE}")
    endif()
endif()

# Enable all of the logs to files.
if(LOG_THIRD_PARTY_BUILD_TO_FILE)
    set(ThirdPartyProjectLogSettings
        LOG_DOWNLOAD YES
        LOG_PATCH YES
        LOG_CONFIGURE YES
        LOG_BUILD YES
        LOG_MERGED_STDOUTERR YES
        LOG_OUTPUT_ON_FAILURE YES
    )
    set(ThirdPartyProjectInstallLogSettings
        LOG_INSTALL YES
    )
else()
    set(ThirdPartyProjectLogSettings)
    set(ThirdPartyProjectInstallLogSettings)
endif()

macro(process_third_party_project_log_settings)
    set(ProjectLogSettings)
    if(LOG_THIRD_PARTY_BUILD_TO_FILE)
        set(ProjectLogSettings
            LOG_DOWNLOAD YES
            LOG_PATCH YES
            LOG_MERGED_STDOUTERR YES
            LOG_OUTPUT_ON_FAILURE YES
        )

        if(NOT parsed_arguments_NEVER_LOG_CONFIGURE)
            set(ProjectLogSettings ${ProjectLogSettings} LOG_CONFIGURE YES)
        endif()
        if(NOT parsed_arguments_NEVER_LOG_BUILD)
            set(ProjectLogSettings ${ProjectLogSettings} LOG_BUILD YES)
        endif()
        if(NOT parsed_arguments_NEVER_LOG_INSTALL)
            set(ProjectLogSettings ${ProjectLogSettings} LOG_INSTALL YES)
        endif()
    endif()
endmacro()

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
        set(InstallLibraryGlobPaterns ${ARTIFACT_KIND_WINDOWS_DLLS})
    else()
        set(InstallLibraryFileNames ${ARTIFACT_KIND_LINUX_LIBRARIES})
        set(InstallLibraryGlobPatterns ${ARTIFACT_KIND_LINUX_LIBRARIES_SYMLINK_PATTERNS})
    endif()

    if(DARWIN)
        set(newList ${ThirdPartyLibrariesFileNames} ${InstallLibraryFileNames})
        set(ThirdPartyLibrariesFileNames "${newList}" CACHE INTERNAL "List of built libraries to bundle.")
        set(newList ${ThirdPartyLibrariesPatterns} ${InstallLibraryGlobPatterns})
        set(ThirdPartyLibrariesPatterns "${newList}" CACHE INTERNAL "List of built libraries glob patterns to bundle.")
    else()
        ## CMake install(DIRECTORY ...) does not exclude subdirectories, So we
        set(InstallScriptFileName "${CMAKE_CURRENT_BINARY_DIR}/${ThirdpartyProjectName}-install.cmake")
        configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/ThirdPartyDependencyInstallScript.cmake.in"
            "${InstallScriptFileName}" @ONLY IMMEDIATE)
        install(SCRIPT "${InstallScriptFileName}")
    endif()
endfunction()

## This export variables for linking with an included thirdparty
function (export_included_thirdparty_libraries NAME)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs
        MAC_LIBRARIES
        LINUX_LIBRARIES
        WINDOWS_LIBRARIES)

    cmake_parse_arguments(ARTIFACT_KIND "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN} )

    set(libraries)
    if(DARWIN)
        set(libraries ${ARTIFACT_KIND_MAC_LIBRARIES})
    elseif(WIN32)
        set(libraries ${ARTIFACT_KIND_WINDOWS_LIBRARIES})
    else()
        set(libraries ${ARTIFACT_KIND_LINUX_LIBRARIES})
    endif()

    if(libraries)
        set(librariesFullPaths)
        foreach(lib ${libraries})
            set(librariesFullPaths ${librariesFullPaths} "${ThirdPartyCacheInstallLib}/${lib}")
            if(WIN32)
                add_library(${lib} STATIC IMPORTED)
                set_target_properties(${lib} PROPERTIES IMPORTED_LOCATION "${ThirdPartyCacheInstallLib}/${lib}")
            else()
                add_library(${lib} SHARED IMPORTED)
                set_target_properties(${lib} PROPERTIES IMPORTED_LOCATION "${ThirdPartyCacheInstallLib}/${lib}")
            endif()
        endforeach()

        set(HAVE_${NAME} True CACHE INTERNAL "Is ${NAME} avaiable?" FORCE)
        #set(${NAME}_LIBRARIES "${librariesFullPaths}" CACHE STRING "${NAME} libraries" FORCE)
        set(${NAME}_LIBRARIES "${libraries}" CACHE STRING "${NAME} libraries" FORCE)
        set(${NAME}_INCLUDE_DIR "" CACHE PATH "${NAME} include directory" FORCE)
        #message("libraries ${NAME}_LIBRARIES ${${NAME}_LIBRARIES}")
        set(${NAME}_LibrariesNames "${libraries}" CACHE INTERNAL "The name of the libraries")
        set(${NAME}_FullLibrariesPaths "${librariesFullPaths}" CACHE INTERNAL "The full paths of the libraries")
    else()
        set(HAVE_${NAME} False CACHE INTERNAL "Is ${NAME} avaiable?")
    endif()
endfunction()


## This function adds an autoconf based thirdparty dependency.
function(ADD_THIRDPARTY_WITH_AUTOCONF NAME)
    set(options BUILD_AS_NATIVE_TOOL NEVER_LOG_CONFIGURE NEVER_LOG_BUILD NEVER_LOG_INSTALL)
    set(oneValueArgs DOWNLOAD_URL ARCHIVE_NAME ARCHIVE_HASH PATCH CFLAGS CXXFLAGS LDFLAGS)
    set(multiValueArgs
        AUTOCONF_EXTRA_ARGS
        DEPENDENCIES
        EXTRA_BUILD_ARTIFACTS
        BUILD_COMMAND
        INSTALL_COMMAND
        MAC_LIBRARIES
        MAC_LIBRARIES_SYMLINK_PATTERNS
        LINUX_LIBRARIES
        LINUX_LIBRARIES_SYMLINK_PATTERNS
        WINDOWS_LIBRARIES
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

    set(computed_patch_command)
    if(parsed_arguments_PATCH)
        set(computed_patch_command PATCH_COMMAND patch -p1 < ${parsed_arguments_PATCH})
    endif()

    process_third_party_project_log_settings()

    if(HaveCachedBuildArtifacts)
        message(STATUS "Not building cached third-party dependency ${NAME}.")
        set(${NAME}_BuildDep PARENT_SCOPE)
    else()
        set(autoconf_cflags "${parsed_arguments_CFLAGS}")
        set(autoconf_cxxflags "${parsed_arguments_CXXFLAGS}")
        set(autoconf_ldflags "${parsed_arguments_LDFLAGS} ")
        set(ExtraRequiredAutoconfArgs)
        set(ExtraRequiredAutoconfVariables)


        if(parsed_arguments_BUILD_AS_NATIVE_TOOL)
            # Do not pass extra options.
        elseif(DARWIN)
            set(ExtraRequiredAutoconfVariables
                "CC=${THIRDPARTY_C_COMPILER} --sysroot=${CMAKE_OSX_SYSROOT}"
                "CXX=${THIRDPARTY_CXX_COMPILER} --sysroot=${CMAKE_OSX_SYSROOT}"
            )
            set(ExtraRequiredAutoconfArgs ${ExtraRequiredAutoconfArgs} "--with-sysroot=${CMAKE_OSX_SYSROOT}")
            if(SQUEAK_PLATFORM_X86_32)
                set(autoconf_cflags "${autoconf_cflags} -arch i386")
                set(autoconf_cxxflags "${autoconf_cxxflags} -arch i386")
                set(autoconf_ldflags "${autoconf_ldflags} -arch i386")
            elseif(SQUEAK_PLATFORM_X86_64)
                set(autoconf_cflags "${autoconf_cflags} -arch x86_64")
                set(autoconf_cxxflags "${autoconf_cxxflags} -arch x86_64")
                set(autoconf_ldflags "${autoconf_ldflags} -arch x86_64")
            endif()
        elseif(WIN32)
            if(SQUEAK_PLATFORM_X86_32)
                set(ExtraRequiredAutoconfArgs ${ExtraRequiredAutoconfArgs} "--host=i686-w64-mingw32")
                set(autoconf_cflags "${autoconf_cflags} -m32 -march=pentium4 -static-libgcc -static-libstdc++")
                set(autoconf_cxxflags "${autoconf_cxxflags} -m32 -march=pentium4 -static-libgcc -static-libstdc++")
                set(autoconf_ldflags "${autoconf_ldflags} -m32 -march=pentium4 -static-libgcc -static-libstdc++")
            elseif(SQUEAK_PLATFORM_X86_64)
                set(ExtraRequiredAutoconfArgs ${ExtraRequiredAutoconfArgs} "--host=x86_64-w64-mingw32")
                set(autoconf_cflags "${autoconf_cflags} -m64 -static-libgcc -static-libstdc++")
                set(autoconf_cxxflags "${autoconf_cxxflags} -m64 -static-libgcc -static-libstdc++")
                set(autoconf_ldflags "${autoconf_ldflags} -m64 -static-libgcc -static-libstdc++")
            endif()
        else()
            if(SQUEAK_PLATFORM_X86_32)
                set(autoconf_cflags "${autoconf_cflags} -m32 -march=pentium4")
                set(autoconf_cxxflags "${autoconf_cxxflags} -m32 -march=pentium4")
                set(autoconf_ldflags "${autoconf_ldflags} -m32 -march=pentium4")
            elseif(SQUEAK_PLATFORM_X86_64)
                set(autoconf_cflags "${autoconf_cflags} -m64")
                set(autoconf_cxxflags "${autoconf_cxxflags} -m64")
                set(autoconf_ldflags "${autoconf_ldflags} -m64")
            endif()
        endif()

        set(autoconf_cflags "${autoconf_cflags} -I${ThirdPartyCacheInstallInclude}")
        set(autoconf_cxxflags "${autoconf_cxxflags} -I${ThirdPartyCacheInstallInclude}")
        set(autoconf_ldflags "${autoconf_ldflags} -L${ThirdPartyCacheInstallLib}")

        set(thirdparty_autoconf_command "./configure"
            "--prefix=${ThirdPartyCacheInstall}"
            ${ExtraRequiredAutoconfArgs}
            ${parsed_arguments_AUTOCONF_EXTRA_ARGS}
            ${ExtraRequiredAutoconfVariables}
            "CFLAGS=${autoconf_cflags}"
            "CXXFLAGS=${autoconf_cxxflags}"
            "LDFLAGS=${autoconf_ldflags}"
        )

        if(ThirdPartyPkgConfig AND ThirdPartyPkgConfigPath)
            set(thirdparty_autoconf_command ${thirdparty_autoconf_command}
                "PKG_CONFIG=${ThirdPartyPkgConfig}"
                "PKG_CONFIG_PATH=${ThirdPartyPkgConfigPath}"
            )
        endif()

        set(CustomBuildCommand)
        if(parsed_arguments_BUILD_COMMAND)
            set(CustomBuildCommand BUILD_COMMAND ${parsed_arguments_BUILD_COMMAND})
        endif()
        set(CustomInstallCommand)
        if(parsed_arguments_INSTALL_COMMAND)
            set(CustomInstallCommand INSTALL_COMMAND ${parsed_arguments_INSTALL_COMMAND})
        endif()

        ExternalProject_Add(${NAME}
            URL "${parsed_arguments_DOWNLOAD_URL}"
            URL_HASH "${parsed_arguments_ARCHIVE_HASH}"
            DOWNLOAD_NAME "${parsed_arguments_ARCHIVE_NAME}"
            DOWNLOAD_DIR "${ThirdPartyCacheDownloadDirectory}"
            PREFIX "${CMAKE_CURRENT_BINARY_DIR}/thirdparty/${NAME}"
            ${computed_patch_command}
            CONFIGURE_COMMAND "${thirdparty_autoconf_command}"
            ${CustomBuildCommand}
            ${CustomInstallCommand}
            ${ProjectLogSettings}
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

    export_included_thirdparty_libraries(${NAME}
        MAC_LIBRARIES ${parsed_arguments_MAC_LIBRARIES}
        LINUX_LIBRARIES ${parsed_arguments_LINUX_LIBRARIES}
        WINDOWS_LIBRARIES ${parsed_arguments_WINDOWS_LIBRARIES}
    )
endfunction()

function(ADD_THIRDPARTY_WITH_CMAKE NAME)
    set(options NEVER_LOG_CONFIGURE NEVER_LOG_BUILD NEVER_LOG_INSTALL)
    set(oneValueArgs DOWNLOAD_URL ARCHIVE_NAME ARCHIVE_HASH PATCH CFLAGS CXXFLAGS LDFLAGS)
    set(multiValueArgs
        CMAKE_EXTRA_ARGS
        DEPENDENCIES
        EXTRA_BUILD_ARTIFACTS
        BUILD_COMMAND
        INSTALL_COMMAND
        MAC_LIBRARIES
        MAC_LIBRARIES_SYMLINK_PATTERNS
        LINUX_LIBRARIES
        LINUX_LIBRARIES_SYMLINK_PATTERNS
        WINDOWS_DLLS
        WINDOWS_LIBRARIES)

    cmake_parse_arguments(parsed_arguments "${options}" "${oneValueArgs}"
                          "${multiValueArgs}" ${ARGN} )
    # Compute the actually used build artifacts.
    check_thirdparty_build_artifacts(HaveCachedBuildArtifacts
        EXTRA_BUILD_ARTIFACTS ${parsed_arguments_EXTRA_BUILD_ARTIFACTS}
        MAC_LIBRARIES ${parsed_arguments_MAC_LIBRARIES}
        LINUX_LIBRARIES ${parsed_arguments_LINUX_LIBRARIES}
        WINDOWS_DLLS ${parsed_arguments_WINDOWS_DLLS}
    )

    set(computed_patch_command)
    if(parsed_arguments_PATCH)
        set(computed_patch_command PATCH_COMMAND patch -p1 < ${parsed_arguments_PATCH})
    endif()

    process_third_party_project_log_settings()

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
                set(cmake_cflags "${cmake_cflags} -m32 -march=pentium4")
                set(cmake_cxxflags "${cmake_cxxflags} -m32 -march=pentium4")
                set(cmake_ldflags "${cmake_ldflags} -m32 -march=pentium4")
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
            "-DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
            "-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}"
            ${parsed_arguments_CMAKE_EXTRA_ARGS}
        )
        # Use the same toolchain file that we are using.
        if(THIRDPARTY_CMAKE_TOOLCHAIN_FILE)
            set(thirdparty_cmake_command ${thirdparty_cmake_command}
                "-DCMAKE_TOOLCHAIN_FILE=${THIRDPARTY_CMAKE_TOOLCHAIN_FILE}")
        endif()

        set(CustomBuildCommand)
        if(parsed_arguments_BUILD_COMMAND)
            set(CustomBuildCommand BUILD_COMMAND ${parsed_arguments_BUILD_COMMAND})
        endif()
        set(CustomInstallCommand)
        if(parsed_arguments_INSTALL_COMMAND)
            set(CustomInstallCommand INSTALL_COMMAND ${parsed_arguments_INSTALL_COMMAND})
        endif()

        ExternalProject_Add(${NAME}
            URL "${parsed_arguments_DOWNLOAD_URL}"
            URL_HASH "${parsed_arguments_ARCHIVE_HASH}"
            DOWNLOAD_NAME "${parsed_arguments_ARCHIVE_NAME}"
            DOWNLOAD_DIR "${ThirdPartyCacheDownloadDirectory}"
            PREFIX "${CMAKE_CURRENT_BINARY_DIR}/thirdparty/${NAME}"
            ${computed_patch_command}
            CONFIGURE_COMMAND "${thirdparty_cmake_command}"
            ${ProjectLogSettings}
            BUILD_IN_SOURCE FALSE
            ${CustomBuildCommand}
            ${CustomInstallCommand}
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

    export_included_thirdparty_libraries(${NAME}
        MAC_LIBRARIES ${parsed_arguments_MAC_LIBRARIES}
        LINUX_LIBRARIES ${parsed_arguments_LINUX_LIBRARIES}
        WINDOWS_LIBRARIES ${parsed_arguments_WINDOWS_LIBRARIES}
    )
endfunction()
