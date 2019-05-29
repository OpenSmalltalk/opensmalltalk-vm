set(Pixman_Spec_URL "http://www.cairographics.org/releases/pixman-0.34.0.tar.gz")
set(Pixman_Spec_ArchiveName pixman-0.34.0.tar.gz)
set(Pixman_Spec_ArchiveSha256 21b6b249b51c6800dc9553b65106e1e37d0e25df942c90531d4c3997aa20a88e)

set(Pixman_Spec_MacLibraries libpixman-1.0.dylib)
set(Pixman_Spec_MacLibrariesSymlinks libpixman*.dylib)
set(Pixman_Spec_WindowsDLLs libpixman-1-0.dll)

set(Pixman_Spec_Patch)
if(DARWIN)
    set(Pixman_Spec_Patch "${CMAKE_CURRENT_SOURCE_DIR}/third-party/pixman.clang.patch")
endif()

add_thirdparty_with_autoconf(Pixman
    DOWNLOAD_URL ${Pixman_Spec_URL}
    ARCHIVE_NAME ${Pixman_Spec_ArchiveName}
    ARCHIVE_SHA256 ${Pixman_Spec_ArchiveSha256}
    PATCH ${Pixman_Spec_Patch}
    MAC_LIBRARIES ${Pixman_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${Pixman_Spec_MacLibrariesSymlinks}
    WINDOWS_DLLS ${Pixman_Spec_WindowsDLLs}
    DEPENDENCIES ${LibPNG_BuildDep} ${FreeType2_BuildDep}
)
