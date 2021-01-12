set(Cairo_Spec_URL "http://cairographics.org/snapshots/cairo-1.15.14.tar.xz")
set(Cairo_Spec_ArchiveName cairo-1.15.14.tar.xz)
set(Cairo_Spec_ArchiveHash "SHA1=62ebffbaf4cc81c412f0ad3f87dc20499f85d046")

set(Cairo_Spec_MacLibraries libcairo.2.dylib)
set(Cairo_Spec_MacLibrariesSymlinks libcairo*.dylib)
set(Cairo_Spec_WindowsDLLs libcairo-2.dll)

set(Cairo_Spec_BuildCommand)
set(Cairo_Spec_AutoconfFlags)
if(WIN32)
    set(Cairo_Spec_BuildCommand BUILD_COMMAND
        sed -i "/.* sh .\\/make-/i\\\\ttest -e \\$\\@ \\&\\& rm \\$\\@" test/Makefile && make
        NEVER_LOG_BUILD
    )

    set(Cairo_Spec_AutoconfFlags
        "FREETYPE_LIBS=-L${ThirdPartyCacheInstallLib} -lfreetype -lz"
        "FREETYPE_CFLAGS=-I${ThirdPartyCacheInstallInclude} -I${ThirdPartyCacheInstallInclude}/freetype2"
    )
endif()

add_thirdparty_with_autoconf(Cairo
    DOWNLOAD_URL ${Cairo_Spec_URL}
    ARCHIVE_NAME ${Cairo_Spec_ArchiveName}
    ARCHIVE_HASH ${Cairo_Spec_ArchiveHash}
    AUTOCONF_EXTRA_ARGS --disable-silent-rules --disable-xlib --disable-dependency-tracking --disable-interpreter ${Cairo_Spec_AutoconfFlags}
    MAC_LIBRARIES ${Cairo_Spec_MacLibraries}
    MAC_LIBRARIES_SYMLINK_PATTERNS ${Cairo_Spec_MacLibrariesSymlinks}
    WINDOWS_DLLS ${Cairo_Spec_WindowsDLLs}
    ${Cairo_Spec_BuildCommand}
    DEPENDENCIES ${PkgConfig_BuildDep} ${Pixman_BuildDep} ${FreeType2_BuildDep} ${LibPNG_BuildDep}
)
