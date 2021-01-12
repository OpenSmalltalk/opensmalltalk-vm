set(LibSDL2_Spec_URL "http://www.libsdl.org/release/SDL2-2.0.14.tar.gz")
set(LibSDL2_Spec_ArchiveName SDL2-2.0.14.tar.gz)
set(LibSDL2_Spec_ArchiveHash "SHA256=d8215b571a581be1332d2106f8036fcb03d12a70bae01e20f424976d275432bc")

set(LibSDL2_Spec_MacLibraries libSDL2-2.0.0.dylib)
set(LibSDL2_Spec_MacLibrariesSymlinks libSDL2*.dylib)
set(LibSDL2_Spec_LinuxLibraries libSDL2-2.0.so.0.14.0)
set(LibSDL2_Spec_LinuxLibrariesSymlinks libSDL2*so*)
set(LibSDL2_Spec_WindowsLibraries libSDL2.dll.a)
set(LibSDL2_Spec_WindowsDLLs SDL2.dll)

add_thirdparty_with_autoconf(SDL2
    DOWNLOAD_URL ${LibSDL2_Spec_URL}
    ARCHIVE_NAME ${LibSDL2_Spec_ArchiveName}
    ARCHIVE_HASH ${LibSDL2_Spec_ArchiveHash}
    AUTOCONF_EXTRA_ARGS --disable-video-mir
    MAC_LIBRARIES ${LibSDL2_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${LibSDL2_Spec_MacLibrariesSymlinks}
    LINUX_LIBRARIES ${LibSDL2_Spec_LinuxLibraries}
    LINUX_LIBRARIES_SYMLINK_PATTERNS ${LibSDL2_Spec_LinuxLibrariesSymlinks}
    WINDOWS_LIBRARIES ${LibSDL2_Spec_WindowsLibraries}
    WINDOWS_DLLS ${LibSDL2_Spec_WindowsDLLs}
)
