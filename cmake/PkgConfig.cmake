set(PkgConfig_Spec_URL "http://pkgconfig.freedesktop.org/releases/pkg-config-0.23.tar.gz")
set(PkgConfig_Spec_ArchiveName pkg-config-0.23.tar.gz)
set(PkgConfig_Spec_ArchiveHash "SHA256=08a0e072d6a05419a58124db864f0685e6ac96e71b2875bf15ac12714e983b53")
set(PkgConfigExtraOptions)
set(PkgConfig_Spec_BuildCommand)
set(PkgConfig_Spec_InstallCommand)
if(WIN32)
    # I need to use a different version of pkgconfig for windows because version 0.29.1 does not work
    # with macOS and 0.23 does not work with Windows.
    # Since this is a support library and it will not go to the final product, we do not care which
    # version we use...
    set(PkgConfig_Spec_URL "http://pkgconfig.freedesktop.org/releases/pkg-config-0.29.1.tar.gz")
    set(PkgConfig_Spec_ArchiveName pkg-config-0.29.1.tar.gz)
    set(PkgConfig_Spec_ArchiveHash "SHA256=beb43c9e064555469bd4390dcfd8030b1536e0aa103f08d7abf7ae8cac0cb001")
    set(PkgConfig_Spec_UnpackDirName pkg-config-0.29.1)
    set(PkgConfig_Spec_BuildCommand BUILD_COMMAND make LN=cp)
    set(PkgConfig_Spec_InstallCommand INSTALL_COMMAND make LN=cp install)
endif()

add_thirdparty_with_autoconf(PkgConfig
    DOWNLOAD_URL ${PkgConfig_Spec_URL}
    ARCHIVE_NAME ${PkgConfig_Spec_ArchiveName}
    ARCHIVE_HASH ${PkgConfig_Spec_ArchiveHash}
    EXTRA_BUILD_ARTIFACTS "bin/pkg-config"
    CFLAGS "-std=gnu89"
    ${PkgConfig_Spec_BuildCommand}
    ${PkgConfig_Spec_InstallCommand}
    BUILD_AS_NATIVE_TOOL
)

set(ThirdPartyPkgConfig "${ThirdPartyCacheInstallBin}/pkg-config")
if(WIN32)
    set(ThirdPartyPkgConfig "${ThirdPartyCacheInstallBin}/pkg-config.exe")
endif()
set(ThirdPartyPkgConfigPath "${ThirdPartyCacheInstallLib}/pkgconfig")
