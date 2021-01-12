set(LibGit2_Spec_URL "https://github.com/libgit2/libgit2/archive/v0.25.1.tar.gz")
set(LibGit2_Spec_ArchiveName libgit2-v0.25.1.tar.gz)
set(LibGit2_Spec_ArchiveHash "SHA256=465c7c0a3d9b3edf151d4ada31597f2805b7c2e80b92c03062a6345e03ef8c7b")

set(LibGit2_Spec_MacLibraries libgit2.0.25.1.dylib)
set(LibGit2_Spec_MacLibrariesSymlinks libgit2*.dylib)
set(LibGit2_Spec_LinuxLibraries libgit2.so.0.25.1)
set(LibGit2_Spec_LinuxLibrariesSymlinks libgit2.so*)
set(LibGit2_Spec_WindowsDLLs libgit2.dll)

set(OpenSSL_EscapedLibrariesNames)
foreach(lib ${OpenSSL_FullLibrariesPaths})
    if(OpenSSL_EscapedLibrariesNames)
        set(OpenSSL_EscapedLibrariesNames "${OpenSSL_EscapedLibrariesNames}$<SEMICOLON>${lib}")
    else()
        set(OpenSSL_EscapedLibrariesNames "${lib}")
    endif()
endforeach()

set(LibGit2_Spec_CMAKE_ARGS
    -DBUILD_CLAR=OFF -DUSE_SSH=ON
    -DOPENSSL_FOUND=ON
    "-DOPENSSL_INCLUDE_DIR=${ThirdPartyCacheInstallInclude}"
    -DOPENSSL_LIBRARY_DIR=${ThirdPartyCacheInstallLib}
    "-DOPENSSL_LIBRARIES=${OpenSSL_EscapedLibrariesNames}"

    -DLIBSSH2_FOUND=ON
    "-DLIBSSH2_INCLUDE_DIRS=${ThirdPartyCacheInstallInclude}"
    "-DLIBSSH2_LIBRARIES=${LibSSH2_FullLibrariesPaths}"
)

add_thirdparty_with_cmake(LibGit2
    DOWNLOAD_URL ${LibGit2_Spec_URL}
    ARCHIVE_NAME ${LibGit2_Spec_ArchiveName}
    ARCHIVE_HASH ${LibGit2_Spec_ArchiveHash}
    CMAKE_EXTRA_ARGS ${LibGit2_Spec_CMAKE_ARGS}
    MAC_LIBRARIES ${LibGit2_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${LibGit2_Spec_MacLibrariesSymlinks}
    LINUX_LIBRARIES ${LibGit2_Spec_LinuxLibraries}
    LINUX_LIBRARIES_SYMLINK_PATTERNS ${LibGit2_Spec_LinuxLibrariesSymlinks}
    WINDOWS_DLLS ${LibGit2_Spec_WindowsDLLs}
    DEPENDENCIES ${LibSSH2_BuildDep}
    NEVER_LOG_CONFIGURE
)
