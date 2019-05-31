set(FreeType2_Spec_URL "http://ftp.igh.cnrs.fr/pub/nongnu/freetype/freetype-2.9.1.tar.gz")
set(FreeType2_Spec_ArchiveName freetype-2.9.1.tar.gz)
set(FreeType2_Spec_ArchiveSha256 ec391504e55498adceb30baceebd147a6e963f636eb617424bcfc47a169898ce)

set(FreeType2_Spec_MacLibraries libfreetype.6.dylib)
set(FreeType2_Spec_MacLibrariesSymlinks libfreetype*.dylib)
set(FreeType2_Spec_WindowsDLLs libfreetype.dll)

set(FreeType2_Spec_Patch "${CMAKE_CURRENT_SOURCE_DIR}/third-party/freetype291.patch")

if(WIN32)
    add_thirdparty_with_cmake(FreeType2
        DOWNLOAD_URL ${FreeType2_Spec_URL}
        ARCHIVE_NAME ${FreeType2_Spec_ArchiveName}
        ARCHIVE_SHA256 ${FreeType2_Spec_ArchiveSha256}
        PATCH ${FreeType2_Spec_Patch}
        CMAKE_EXTRA_ARGS -DWITH_PNG=OFF -DBUILD_SHARED_LIBS=ON
        MAC_LIBRARIES ${FreeType2_Spec_MacLibraries}
        MAC_LIBRARIES_SYMLINK_PATTERNS ${FreeType2_Spec_MacLibrariesSymlinks}
        WINDOWS_DLLS ${FreeType2_Spec_WindowsDLLs}
        DEPENDENCIES ${PkgConfig_BuildDep} ${Zlib_BuildDep}
        INSTALL_COMMAND make install && cp libfreetype.dll "${ThirdPartyCacheInstallBin}/${FreeType2_Spec_WindowsDLLs}"
    )
else()
    add_thirdparty_with_autoconf(FreeType2
        DOWNLOAD_URL ${FreeType2_Spec_URL}
        ARCHIVE_NAME ${FreeType2_Spec_ArchiveName}
        ARCHIVE_SHA256 ${FreeType2_Spec_ArchiveSha256}
        PATCH ${FreeType2_Spec_Patch}
        AUTOCONF_EXTRA_ARGS "--without-png"
        MAC_LIBRARIES ${FreeType2_Spec_MacLibraries}
        MAC_LIBRARIES_SYMLINK_PATTERNS ${FreeType2_Spec_MacLibrariesSymlinks}
        WINDOWS_DLLS ${FreeType2_Spec_WindowsDLLs}
        DEPENDENCIES ${PkgConfig_BuildDep} ${Zlib_BuildDep}
    )
endif()

include_directories("${ThirdPartyCacheInstallInclude}/freetype2")
