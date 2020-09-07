@echo off

REM This script can takes up to 4 parameters:
REM        - The architecture of the vm to build. Can be: i686 or x86_64. By default is i686.
REM        - The directory where to install Cygwin. By default "C:\cygwin" or "C:\cygwin64" depending on the architecture.
REM        - The path to the cygwin setup. By defaul "setup-x86.exe" or "setup-x86_64.exe" depending on the architecture.
REM        - The mirror from where download cygwin. By default http://cygwin.mirror.constant.com.

REM The architecture can either be i686 or x86_64. By default, if no argument is passed, it will be i686.
SET CYG_INSTALL_ARCH=%1
IF "%CYG_INSTALL_ARCH%"=="" (SET CYG_INSTALL_ARCH=i686)

REM Check that the value is a valid architecture
IF NOT "%CYG_INSTALL_ARCH%"=="i686" (
    IF NOT "%CYG_INSTALL_ARCH%"=="x86_64" (
        echo ERROR: Architecture can either be i686 or x86_64. Got %CYG_INSTALL_ARCH% && exit /b
    )
)

REM The CYG_INSTALL_ROOT is the locations where to install cygwin. If there is no argument to the command line, the default value is "C:\cygwin" if the architecture is i686 and "C:\cygwin64" if the architecture is x86_64.
SET CYG_INSTALL_ROOT=%2
IF "%CYG_INSTALL_ROOT%"=="" (
    IF "%CYG_INSTALL_ARCH%"=="i686" (
        SET CYG_INSTALL_ROOT="C:\cygwin"
    ) ELSE (
        IF "%CYG_INSTALL_ARCH%"=="x86_64" (SET CYG_INSTALL_ROOT="C:\cygwin64")
    )
)

REM The CYG_INSTALL_SETUP is the executable to use to install the vm. By default, it will be "setup-x86.exe" for i686 architecture and "setup-x86_64.exe" for x86_64.
SET CYG_INSTALL_SETUP=%3
IF "%CYG_INSTALL_SETUP%"=="" (
    IF "%CYG_INSTALL_ARCH%"=="i686" (
        SET CYG_INSTALL_SETUP="setup-x86.exe"
    ) ELSE (
        IF "%CYG_INSTALL_ARCH%"=="x86_64" (SET CYG_INSTALL_SETUP="setup-x86_64.exe")
    )
) 

SET CYG_INSTALL_MIRROR=%4
IF "%CYG_INSTALL_MIRROR%"=="" (SET CYG_INSTALL_MIRROR=http://cygwin.mirror.constant.com)

echo Installing cygwin for architecture %CYG_INSTALL_ARCH% at %CYG_INSTALL_ROOT% using setup %CYG_INSTALL_SETUP% from mirror %CYG_INSTALL_MIRROR%

%CYG_INSTALL_SETUP% -dgnqNO -R "%CYG_INSTALL_ROOT%" -s "%CYG_INSTALL_MIRROR%" -l "%CYG_INSTALL_ROOT%\var\cache\setup"^
    -P gcc-core^
    -P gcc-g++^
    -P binutils^
    -P libtool^
    -P libiconv^
    -P automake^
    -P autoconf^
    -P make^
    -P cmake^
    -P wget^
    -P curl^
    -P mingw64-%CYG_INSTALL_ARCH%-gcc-core^
    -P mingw64-%CYG_INSTALL_ARCH%-gcc-g++^
    -P mingw64-%CYG_INSTALL_ARCH%-headers^
    -P mingw64-%CYG_INSTALL_ARCH%-runtime^
    -P zip^
    -P mingw64-%CYG_INSTALL_ARCH%-clang^
    -P mingw64-%CYG_INSTALL_ARCH%-openssl^
    -P libiconv-devel^
    -P libglib2.0-devel^
    -P perl^
    -P mingw64-%CYG_INSTALL_ARCH%-zlib^
    -P mingw64-%CYG_INSTALL_ARCH%-win-iconv^
    -P mingw64-%CYG_INSTALL_ARCH%-libssh2^
    -P mingw64-%CYG_INSTALL_ARCH%-libgit2^
    -P mingw64-%CYG_INSTALL_ARCH%-cairo^
    -P unzip^
    -P patch

REM unzip and curl are not needed for the VM build but is needed for the VMMaker image building. Thus I add it in this script so that people can use it when building VMMaker on their computer.
