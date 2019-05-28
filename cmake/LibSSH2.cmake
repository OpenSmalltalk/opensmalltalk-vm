set(LibSSH2_Spec_URL "https://www.libssh2.org/download/libssh2-1.7.0.tar.gz")
set(LibSSH2_Spec_ArchiveName libssh2-1.7.0.tar.gz)
set(LibSSH2_Spec_ArchiveSha256 e4561fd43a50539a8c2ceb37841691baf03ecb7daf043766da1b112e4280d584)

set(LibSSH2_Spec_MacLibraries libssh2.1.dylib)
set(LibSSH2_Spec_MacLibrariesSymlinks libssh2*.dylib)
set(LibSSH2_Spec_LinuxLibraries libssh2.so.1.0.1)
set(LibSSH2_Spec_LinuxLibrariesSymlinks libssh2.so*)
set(LibSSH2_Spec_WindowsDLLs libssh2-1.dll)

add_thirdparty_with_autoconf(LibSSH2
    DOWNLOAD_URL ${LibSSH2_Spec_URL}
    ARCHIVE_NAME ${LibSSH2_Spec_ArchiveName}
    ARCHIVE_SHA256 ${LibSSH2_Spec_ArchiveSha256}
    UNPACK_DIR_NAME ${LibSSH2_Spec_UnpackDirName}
    EXTRA_BUILD_ARTIFACTS "bin/pkg-config"
    AUTOCONF_EXTRA_ARGS "--with-openssl" "--with-libssl-prefix=${ThirdPartyCacheInstall}"
    MAC_LIBRARIES ${LibSSH2_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${LibSSH2_Spec_MacLibrariesSymlinks}
    LINUX_LIBRARIES ${LibSSH2_Spec_LinuxLibraries}
    LINUX_LIBRARIES_SYMLINK_PATTERNS ${LibSSH2_Spec_LinuxLibrariesSymlinks}
    WINDOWS_DLLS ${LibSSH2_Spec_WindowsDLLs}
    DEPENDENCIES ${LibSSH2_BuildDep}
)
