set(LibSDL2_Spec_URL "http://www.libsdl.org/release/SDL2-2.0.7.tar.gz")
set(LibSDL2_Spec_ArchiveName SDL2-2.0.7.tar.gz)
set(LibSDL2_Spec_ArchiveSha256 ee35c74c4313e2eda104b14b1b86f7db84a04eeab9430d56e001cea268bf4d5e)

set(LibSDL2_Spec_MacLibraries libSDL2-2.0.0.dylib)
set(LibSDL2_Spec_MacLibrariesSymlinks libSDL2*.dylib)
set(LibSDL2_Spec_LinuxLibraries libSDL2-2.0.so.0.7.0)
set(LibSDL2_Spec_LinuxLibrariesSymlinks libSDL2*so*)
set(LibSDL2_Spec_WindowsDLLs SDL2.dll)

add_thirdparty_with_autoconf(SDL2
    DOWNLOAD_URL ${LibSDL2_Spec_URL}
    ARCHIVE_NAME ${LibSDL2_Spec_ArchiveName}
    ARCHIVE_SHA256 ${LibSDL2_Spec_ArchiveSha256}
    MAC_LIBRARIES ${LibSDL2_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${LibSDL2_Spec_MacLibrariesSymlinks}
    LINUX_LIBRARIES ${LibSDL2_Spec_LinuxLibraries}
    LINUX_LIBRARIES_SYMLINK_PATTERNS ${LibSDL2_Spec_LinuxLibrariesSymlinks}
    WINDOWS_DLLS ${LibSDL2_Spec_WindowsDLLs}
)
