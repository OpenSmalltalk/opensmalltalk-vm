set(LibPNG_Spec_URL "ftp://ftp-osl.osuosl.org/pub/libpng/src/archive/gz/libpng12/libpng-1.2.49.tar.gz")
set(LibPNG_Spec_ArchiveName libpng-1.2.49.tar.gz)
set(LibPNG_Spec_ArchiveSha256 428a07f7cc2822fb53733b79c918722ac5903477fe193acbb23f6bcacd9f12c0)

set(LibPNG_Spec_MacLibraries libpng12.0.dylib)
set(LibPNG_Spec_MacLibrariesSymlinks libpng12*.dylib)
set(LibPNG_Spec_WindowsDLLs libpng12-0.dll)

add_thirdparty_with_autoconf(LibPNG
    DOWNLOAD_URL ${LibPNG_Spec_URL}
    ARCHIVE_NAME ${LibPNG_Spec_ArchiveName}
    ARCHIVE_SHA256 ${LibPNG_Spec_ArchiveSha256}
    MAC_LIBRARIES ${LibPNG_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${LibPNG_Spec_MacLibrariesSymlinks}
    WINDOWS_DLLS ${LibPNG_Spec_WindowsDLLs}
    DEPENDENCIES ${PkgConfig_BuildDep}
)
