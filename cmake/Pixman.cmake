set(Pixman_Spec_URL "http://www.cairographics.org/releases/pixman-0.40.0.tar.gz")
set(Pixman_Spec_ArchiveName pixman-0.40.0.tar.gz)
set(Pixman_Spec_ArchiveHash "SHA512=063776e132f5d59a6d3f94497da41d6fc1c7dca0d269149c78247f0e0d7f520a25208d908cf5e421d1564889a91da44267b12d61c0bd7934cd54261729a7de5f")

set(Pixman_Spec_MacLibraries libpixman-1.0.dylib)
set(Pixman_Spec_MacLibrariesSymlinks libpixman*.dylib)
set(Pixman_Spec_WindowsDLLs libpixman-1-0.dll)

set(Pixman_Spec_Patch)

add_thirdparty_with_autoconf(Pixman
    DOWNLOAD_URL ${Pixman_Spec_URL}
    ARCHIVE_NAME ${Pixman_Spec_ArchiveName}
    ARCHIVE_HASH ${Pixman_Spec_ArchiveHash}
    PATCH ${Pixman_Spec_Patch}
    MAC_LIBRARIES ${Pixman_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${Pixman_Spec_MacLibrariesSymlinks}
    WINDOWS_DLLS ${Pixman_Spec_WindowsDLLs}
    DEPENDENCIES ${LibPNG_BuildDep} ${FreeType2_BuildDep}
)
