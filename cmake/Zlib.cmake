set(Zlib_Spec_URL "http://zlib.net/zlib-1.2.13.tar.gz")
set(Zlib_Spec_ArchiveName zlib-1.2.13.tar.gz)
set(Zlib_Spec_ArchiveSha256 91844808532e5ce316b3c010929493c0244f3d37593afd6de04f71821d5136d9)
set(Zlib_Spec_WindowsDLLs zlib1.dll)

#-------------------------------------------------------------------------------
# Zlib dependency building
#-------------------------------------------------------------------------------
check_thirdparty_build_artifacts(HaveCachedZlib
    WINDOWS_DLLS ${Zlib_Spec_WindowsDLLs}
)

if(HaveCachedZlib)
    set(Zlib_BuildDep)
    message(STATUS "Not building cached third-party dependency Zlib")
else()
    set(Zlib_ConfigureCommand echo "Nothing to configure")
    set(Zlib_InstallCommand make install -fwin32/Makefile.gcc
            SHARED_MODE=1
            "INCLUDE_PATH=${ThirdPartyCacheInstallInclude}"
            "LIBRARY_PATH=${ThirdPartyCacheInstallLib}"
            "BINARY_PATH=${ThirdPartyCacheInstallBin}"
         && cp "${ThirdPartyCacheInstallBin}/zlib1.dll" "${ThirdPartyCacheInstallBin}/libz.dll")
    if(SQUEAK_PLATFORM_X86_64)
        set(Zlib_BuildCommand make -fwin32/Makefile.gcc
            "PREFIX=x86_64-w64-mingw32-"
            "CFLAGS=-m64 -static-libgcc -static-libstdc++"
            "LDFLAGS=-m64 -static-libgcc -static-libstdc++")
    elseif(SQUEAK_PLATFORM_X86_32)
        set(Zlib_BuildCommand make -fwin32/Makefile.gcc
            "PREFIX=i686-w64-mingw32-"
            "CFLAGS=-m32 -static-libgcc -static-libstdc++"
            "LDFLAGS=-m32 -static-libgcc -static-libstdc++")
    endif()

    ExternalProject_Add(Zlib
        URL ${Zlib_Spec_URL}
        URL_HASH "SHA256=${Zlib_Spec_ArchiveSha256}"
        DOWNLOAD_NAME ${Zlib_Spec_ArchiveName}
        DOWNLOAD_DIR "${ThirdPartyCacheDownloadDirectory}"
        PREFIX "${CMAKE_CURRENT_BINARY_DIR}/thirdparty/Zlib"
        CONFIGURE_COMMAND "${Zlib_ConfigureCommand}"
        BUILD_COMMAND "${Zlib_BuildCommand}"
        INSTALL_COMMAND "${Zlib_InstallCommand}"
        ${ThirdPartyProjectLogSettings}
        BUILD_IN_SOURCE TRUE
    )
    set(Zlib_BuildDep Zlib)
endif()

install_thirdparty_build_artifacts(Zlib
    MAC_LIBRARIES ${Zlib_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${Zlib_Spec_MacLibrariesSymlinks}
    LINUX_LIBRARIES ${Zlib_Spec_LinuxLibraries}
    LINUX_LIBRARIES_SYMLINK_PATTERNS ${Zlib_Spec_LinuxLibrariesSymlinks}
    WINDOWS_DLLS ${Zlib_Spec_WindowsDLLs}
)

export_included_thirdparty_libraries(Zlib
    MAC_LIBRARIES ${Zlib_Spec_MacLibraries}
    LINUX_LIBRARIES ${Zlib_Spec_LinuxLibraries}
    WINDOWS_LIBRARIES ${Zlib_Spec_WindowsLibraries}
)
