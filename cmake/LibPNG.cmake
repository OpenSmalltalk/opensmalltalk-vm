set(LibPNG_Spec_URL "https://downloads.sourceforge.net/project/libpng/libpng16/1.6.37/libpng-1.6.37.tar.gz")
set(LibPNG_Spec_ArchiveName libpng-1.6.37.tar.gz)
set(LibPNG_Spec_ArchiveHash "SHA256=daeb2620d829575513e35fecc83f0d3791a620b9b93d800b763542ece9390fb4")

set(LibPNG_Spec_MacLibraries libpng16.16.dylib)
set(LibPNG_Spec_MacLibrariesSymlinks libpng16*.dylib)
set(LibPNG_Spec_WindowsDLLs libpng16-16.dll)

set(LibPNG_Spec_BuildCommand)
set(LibPNG_Spec_InstallCommand)
if(WIN32)
    set(LibPNG_Spec_BuildCommand BUILD_COMMAND make LN=CP LN_S=CP)
    set(LibPNG_Spec_InstallCommand INSTALL_COMMAND make LN=CP LN_S=CP install )
endif()

add_thirdparty_with_autoconf(LibPNG
    DOWNLOAD_URL ${LibPNG_Spec_URL}
    ARCHIVE_NAME ${LibPNG_Spec_ArchiveName}
    ARCHIVE_HASH ${LibPNG_Spec_ArchiveHash}
    MAC_LIBRARIES ${LibPNG_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${LibPNG_Spec_MacLibrariesSymlinks}
    WINDOWS_DLLS ${LibPNG_Spec_WindowsDLLs}
    ${LibPNG_Spec_BuildCommand}
    ${LibPNG_Spec_InstallCommand}
    DEPENDENCIES ${PkgConfig_BuildDep} ${Zlib_BuildDep}
)
