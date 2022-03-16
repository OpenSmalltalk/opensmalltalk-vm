set(OpenSSL_Spec_URL "https://www.openssl.org/source/openssl-1.1.1i.tar.gz")
set(OpenSSL_Spec_ArchiveName openssl-1.1.1i.tar.gz)
set(OpenSSL_Spec_ArchiveSha256 e8be6a35fe41d10603c3cc635e93289ed00bf34b79671a3a4de64fcee00d5242)

set(OpenSSL_Spec_MacLibraries libssl.1.1.dylib libcrypto.1.1.dylib)
set(OpenSSL_Spec_MacLibrariesSymlinks libssl*.dylib libcrypto*.dylib)
set(OpenSSL_Spec_LinuxLibraries libssl.so.1.1 libcrypto.so.1.1)
set(OpenSSL_Spec_LinuxLibrariesSymlinks libssl.so* libcrypto.so*)
set(OpenSSL_Spec_WindowsDLLs libssl-1_1*.dll libcrypto-1_1*.dll)
set(OpenSSL_Spec_WindowsLibraries libssl-1_1.dll.a libcrypto-1_1.dll.a)

#-------------------------------------------------------------------------------
# OpenSSL dependency building
#-------------------------------------------------------------------------------
check_thirdparty_build_artifacts(HaveCachedOpenSSL
    MAC_LIBRARIES ${OpenSSL_Spec_MacLibraries}
    LINUX_LIBRARIES ${OpenSSL_Spec_LinuxLibraries}
    WINDOWS_DLLS ${OpenSSL_Spec_WindowsDLLs}
)

if(HaveCachedOpenSSL)
    set(OpenSSL_BuildDep)
    message(STATUS "Not building cached third-party dependency OpenSSL")
else()
    set(OpenSSL_InstallCommand make install)
    if(DARWIN)
        if(SQUEAK_PLATFORM_X86_64)
            set(OpenSSL_ConfigureCommand "./Configure" darwin64-x86_64-cc
                "--prefix=${ThirdPartyCacheInstall}" shared )
        elseif(SQUEAK_PLATFORM_X86_32)
            set(OpenSSL_ConfigureCommand "./Configure" darwin-i386-cc
                "--prefix=${ThirdPartyCacheInstall}" shared )
        endif()

        set(OpenSSL_BuildCommand
            env
            "LDFLAGS=-Wl,-rpath,@executable_path:@executable_path/Plugins --sysroot=${CMAKE_OSX_SYSROOT}"
            "CFLAGS=--sysroot=${CMAKE_OSX_SYSROOT}"
            make
            -s
        )

        set(OpenSSL_LibrariesToAddPermission)
        foreach(opensslLib ${OpenSSL_Spec_MacLibraries})
            set(OpenSSL_LibrariesToAddPermission "${OpenSSL_LibrariesToAddPermission} ${opensslLib}")
        endforeach()

        configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/OpenSSL.mac-install.sh.in"
            "${CMAKE_CURRENT_BINARY_DIR}/thirdparty/OpenSSL.mac-install.sh" @ONLY)
        set(OpenSSL_InstallCommand "${CMAKE_CURRENT_BINARY_DIR}/thirdparty/OpenSSL.mac-install.sh")
    elseif(WIN32)
# NOTE: on win32, the build must be ran with sufficient privilege to write in c:\Progam Files\Common Files\SSL
# See https://github.com/openssl/openssl/issues/6072
# the alternative is to provide a --openssldir parameter at configure step
        set(OpenSSL_ConfigureCommand env
            CC=${THIRDPARTY_C_COMPILER}
            #AR=x86_64-w64-mingw32-ar
            #LD=$(LD)
            #NM=$(NM)
            #RC=$(RC)
            #DLLTOOL=$(DLLTOOL)
            #DLLWRAP=$(DLLWRAP)
        )
        if(SQUEAK_PLATFORM_X86_64)
            set(OpenSSL_ConfigureCommand ${OpenSSL_ConfigureCommand}
                "./Configure" mingw64
                "--openssldir=${ThirdPartyCacheInstall}/SSL"
                "--prefix=${ThirdPartyCacheInstall}" shared)
        elseif(SQUEAK_PLATFORM_X86_32)
                set(OpenSSL_ConfigureCommand ${OpenSSL_ConfigureCommand}
                "./Configure" mingw
                "--openssldir=${ThirdPartyCacheInstall}/SSL"
                "--prefix=${ThirdPartyCacheInstall}" shared)
        endif()
        set(OpenSSL_BuildCommand make)
    else(UNIX)
        if(SQUEAK_PLATFORM_X86_64)
            set(OpenSSL_ConfigureCommand "./Configure" linux-generic32
                "--prefix=${ThirdPartyCacheInstall}" shared)
        elseif(SQUEAK_PLATFORM_X86_32)
            set(OpenSSL_ConfigureCommand setarch i386 ./config -m32
                "--prefix=${ThirdPartyCacheInstall}" shared)
        endif()
        set(OpenSSL_BuildCommand make)
    endif()

    ExternalProject_Add(OpenSSL
        URL ${OpenSSL_Spec_URL}
        URL_HASH "SHA256=${OpenSSL_Spec_ArchiveSha256}"
        DOWNLOAD_NAME ${OpenSSL_Spec_ArchiveName}
        DOWNLOAD_DIR "${ThirdPartyCacheDownloadDirectory}"
        PREFIX "${CMAKE_CURRENT_BINARY_DIR}/thirdparty/OpenSSL"
        CONFIGURE_COMMAND "${OpenSSL_ConfigureCommand}"
        BUILD_COMMAND "${OpenSSL_BuildCommand}"
        INSTALL_COMMAND "${OpenSSL_InstallCommand}"
        ${ThirdPartyProjectLogSettings}
        ${ThirdPartyProjectInstallLogSettings}
        BUILD_IN_SOURCE TRUE
    )
    set(OpenSSL_BuildDep OpenSSL)
    if(PkgConfig_BuildDep)
        add_dependencies(OpenSSL ${PkgConfig_BuildDep})
    endif()

    if(Zlib_BuildDep)
        add_dependencies(OpenSSL ${Zlib_BuildDep})
    endif()
endif()

install_thirdparty_build_artifacts(OpenSSL
    MAC_LIBRARIES ${OpenSSL_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${OpenSSL_Spec_MacLibrariesSymlinks}
    LINUX_LIBRARIES ${OpenSSL_Spec_LinuxLibraries}
    LINUX_LIBRARIES_SYMLINK_PATTERNS ${OpenSSL_Spec_LinuxLibrariesSymlinks}
    WINDOWS_DLLS ${OpenSSL_Spec_WindowsDLLs}
)

export_included_thirdparty_libraries(OpenSSL
    MAC_LIBRARIES ${OpenSSL_Spec_MacLibraries}
    LINUX_LIBRARIES ${OpenSSL_Spec_LinuxLibraries}
    WINDOWS_LIBRARIES ${OpenSSL_Spec_WindowsLibraries}
)
