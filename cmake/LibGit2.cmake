
set(LibGit2_Spec_URL "https://github.com/libgit2/libgit2/archive/v0.25.1.tar.gz")
set(LibGit2_Spec_ArchiveName libgit2-v0.25.1.tar.gz)
set(LibGit2_Spec_ArchiveSha256 465c7c0a3d9b3edf151d4ada31597f2805b7c2e80b92c03062a6345e03ef8c7b)

set(LibGit2_Spec_MacLibraries libgit2.0.25.1.dylib)
set(LibGit2_Spec_MacLibrariesSymlinks libgit2*.dylib)
set(LibGit2_Spec_LinuxLibraries libgit2.so.0.25.1)
set(LibGit2_Spec_LinuxLibrariesSymlinks libgit2.so*)
set(LibGit2_Spec_WindowsDLLs libgit2.dll)

add_thirdparty_with_cmake(LibGit2
    DOWNLOAD_URL ${LibGit2_Spec_URL}
    ARCHIVE_NAME ${LibGit2_Spec_ArchiveName}
    ARCHIVE_SHA256 ${LibGit2_Spec_ArchiveSha256}
    UNPACK_DIR_NAME ${LibGit2_Spec_UnpackDirName}
    CMAKE_EXTRA_ARGS -DBUILD_CLAR=OFF -DUSE_SSH=OFF
    MAC_LIBRARIES ${LibGit2_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${LibGit2_Spec_MacLibrariesSymlinks}
    LINUX_LIBRARIES ${LibGit2_Spec_LinuxLibraries}
    LINUX_LIBRARIES_SYMLINK_PATTERNS ${LibGit2_Spec_LinuxLibrariesSymlinks}
    WINDOWS_DLLS ${LibGit2_Spec_WindowsDLLs}
    DEPENDENCIES ${LibSSH2_BuildDep}
)
