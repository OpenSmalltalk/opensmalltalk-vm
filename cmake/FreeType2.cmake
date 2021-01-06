set(FreeType2_Spec_URL "https://download.savannah.gnu.org/releases/freetype/freetype-2.10.4.tar.xz")
set(FreeType2_Spec_ArchiveName freetype-2.10.4.tar.xz)
set(FreeType2_Spec_ArchiveHash "SHA256=86a854d8905b19698bbc8f23b860bc104246ce4854dcea8e3b0fb21284f75784")

set(FreeType2_Spec_MacLibraries libfreetype.6.dylib)
set(FreeType2_Spec_MacLibrariesSymlinks libfreetype*.dylib)
set(FreeType2_Spec_WindowsDLLs libfreetype.dll)

if(WIN32)
    add_thirdparty_with_cmake(FreeType2
        DOWNLOAD_URL ${FreeType2_Spec_URL}
        ARCHIVE_NAME ${FreeType2_Spec_ArchiveName}
        ARCHIVE_HASH ${FreeType2_Spec_ArchiveHash}
        CMAKE_EXTRA_ARGS -DCMAKE_DISABLE_FIND_PACKAGE_PNG=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_BZip2=TRUE -DBUILD_SHARED_LIBS=ON
        MAC_LIBRARIES ${FreeType2_Spec_MacLibraries}
        MAC_LIBRARIES_SYMLINK_PATTERNS ${FreeType2_Spec_MacLibrariesSymlinks}
        WINDOWS_DLLS ${FreeType2_Spec_WindowsDLLs}
        DEPENDENCIES ${PkgConfig_BuildDep} ${Zlib_BuildDep}
        INSTALL_COMMAND make install && cp libfreetype.dll "${ThirdPartyCacheInstallBin}/${FreeType2_Spec_WindowsDLLs}"
        NEVER_LOG_INSTALL
    )
else()
    add_thirdparty_with_autoconf(FreeType2
        DOWNLOAD_URL ${FreeType2_Spec_URL}
        ARCHIVE_NAME ${FreeType2_Spec_ArchiveName}
        ARCHIVE_HASH ${FreeType2_Spec_ArchiveHash}
        AUTOCONF_EXTRA_ARGS --without-png --without-bzip2
        MAC_LIBRARIES ${FreeType2_Spec_MacLibraries}
        MAC_LIBRARIES_SYMLINK_PATTERNS ${FreeType2_Spec_MacLibrariesSymlinks}
        WINDOWS_DLLS ${FreeType2_Spec_WindowsDLLs}
        DEPENDENCIES ${PkgConfig_BuildDep} ${Zlib_BuildDep}
    )
endif()

include_directories("${ThirdPartyCacheInstallInclude}/freetype2")
