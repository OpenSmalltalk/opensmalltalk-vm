@echo off

SET MSYS_ARCH=%1
IF "%MSYS_ARCH%"=="" (SET MSYS_ARCH=x86_64)

IF "%MSYS_ARCH%"=="/?" (

echo This script installs and updates an MSYS2 build environment. Requires
echo Windows 10 or later.
echo
echo installMSYS2.bat [MSYS_ARCH] [MSYS_PATH]
echo
echo ---------------------------------------------------------------------------
echo Choose target architecture MSYS_ARCH:
echo  - base           ... MSYS2 GNU dev tools only, see installWinSDK.bat
echo  - i686           ... mingw-w64, build for native 32-bit Windows Intel/AMD
echo  - x86_64         ... mingw-w64, build for native 64-bit Windows Intel/AMD
echo  - clang-aarch64  ... mingw-w64, build for native 64-bit Windows ARMv8
echo 
echo Also see documentation here:
echo  - https://www.msys2.org/docs/what-is-msys2/
echo  - https://www.mingw-w64.org
echo  - https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
echo ---------------------------------------------------------------------------

)

REM Check that the value is a valid architecture
IF NOT "%MSYS_ARCH%"=="base" (
IF NOT "%MSYS_ARCH%"=="i686" (
IF NOT "%MSYS_ARCH%"=="x86_64" (
IF NOT "%MSYS_ARCH%"=="clang-aarch64" (
    echo ERROR: Unkown environment: %MSYS_ARCH% && exit /b ))))

IF "%MSYS_ARCH%"=="base" (SET MSYS_ENV=msys2)
IF "%MSYS_ARCH%"=="i686" (SET MSYS_ENV=mingw32)
IF "%MSYS_ARCH%"=="x86_64" (SET MSYS_ENV=clang64)
IF "%MSYS_ARCH%"=="clang-aarch64" (SET MSYS_ENV=clangarm64)

echo MSYS2 environment ... %MSYS_ENV%
echo MSYS2 architecture ... %MSYS_ARCH%

REM ----------------------------------------------------------------------------
REM Download, install, and update MSYS2 environment (i.e., no compilers)
REM ----------------------------------------------------------------------------

REM By default, MSYS2 will be installed into C:\msys64 but the first parameter
REM can change this to a different location. However, the custom path will
REM always end with "msys64".
SET MSYS_PATH=%2
IF "%MSYS_PATH%"=="" (SET MSYS_PATH=C:)

REM Download the latest installer and install MSYS2. Overwrite any existing
REM archive.
SET MSYS_SETUP_URL=https://github.com/msys2/msys2-installer/releases/download/^
nightly-x86_64/msys2-base-x86_64-latest.sfx.exe
SET MSYS_SETUP_FILE=msys2-base-x86_64.exe

REM Make sure that we can download tools if necessary through wget.
winget install wget^
    --silent^
    --accept-package-agreements^
    --accept-source-agreements

wget -q -O %MSYS_SETUP_FILE% %MSYS_SETUP_URL%
%MSYS_SETUP_FILE% -y -o%MSYS_PATH%\

REM Make MSYS2 installation available in this script environment.
SET PATH=%PATH%;%MSYS_PATH%\msys64
echo MSYS2 path ... %MSYS_PATH%\msys64

REM Make sure that MSYS2 completed initial setup and is up-to-date
rem msys2_shell.cmd -defterm -no-start -here -c "echo MSYS2 is ready."
msys2_shell.cmd -msys2 -defterm -no-start -here -c "pacman -Suqy --noconfirm"


REM ----------------------------------------------------------------------------
REM Download, install, and update MSYS2 packages (e.g. compilers)
REM ----------------------------------------------------------------------------

REM Common GNU dev tools (e.g., git, make)
msys2_shell.cmd -%MSYS_ENV% -defterm -no-start -here -c "pacman -Sq --noconfirm^
    git base-devel"

REM When using the MSVC toolchain and the WinSDK, we are done here.
IF "%MSYS_ARCH%"=="base" (
    echo GNU dev tools installed. See installWinSDK.bat to continue.

    REM We require dlltool, even when using the MSVC toolchain. Sigh.
    msys2_shell.cmd -%MSYS_ENV% -defterm -no-start -here -c^
        "pacman -Sq --noconfirm^
        mingw-w64-i686-binutils^
        mingw-w64-x86_64-binutils^
        mingw-w64-clang-aarch64-binutils"

    exit /b)

REM Always install clang into MSYS2, not GCC.
msys2_shell.cmd -%MSYS_ENV% -defterm -no-start -here -c "pacman -Sq --noconfirm^
    mingw-w64-%MSYS_ARCH%-toolchain^
    mingw-w64-%MSYS_ARCH%-clang^
    mingw-w64-%MSYS_ARCH%-clang-libs

