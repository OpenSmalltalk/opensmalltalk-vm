# Microsoft Developer Studio Project File - Name="Squeak" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=Squeak - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "Squeak.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "Squeak.mak" CFG="Squeak - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "Squeak - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "Squeak - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "Squeak - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /Ob2 /I "../generated" /I "./" /D "NDEBUG" /D "WIN32" /D "_WINDOWS" /D "_MBCS" /D "WIN32_FILE_SUPPORT" /D "LSB_FIRST" /FAcs /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib wsock32.lib winmm.lib ddraw.lib dinput.lib dxguid.lib /nologo /subsystem:windows /machine:I386

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /W3 /Gm /GX /ZI /Od /I "../generated" /I "./" /D "_DEBUG" /D "WIN32" /D "_WINDOWS" /D "_MBCS" /D "WIN32_FILE_SUPPORT" /D "LSB_FIRST" /FAcs /FR /YX /FD /GZ /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib wsock32.lib winmm.lib ddraw.lib dinput.lib dxguid.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept

!ENDIF 

# Begin Target

# Name "Squeak - Win32 Release"
# Name "Squeak - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=..\generated\ADPCMCodecPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\AsynchFilePlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\B2DPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\B3DAcceleratorPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\b3dAlloc.c
# End Source File
# Begin Source File

SOURCE=..\generated\b3dDraw.c
# End Source File
# Begin Source File

SOURCE=..\generated\b3dInit.c
# End Source File
# Begin Source File

SOURCE=..\generated\b3dMain.c
# End Source File
# Begin Source File

SOURCE=..\generated\b3dRemap.c
# End Source File
# Begin Source File

SOURCE=..\generated\BitBltPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\DropPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\DSAPrims.c
# End Source File
# Begin Source File

SOURCE=..\generated\FFTPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\FilePlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\FloatArrayPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\interp.c
# End Source File
# Begin Source File

SOURCE=..\generated\JoystickTabletPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\JPEGReaderPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\Klatt.c
# End Source File
# Begin Source File

SOURCE=..\generated\LargeIntegers.c
# End Source File
# Begin Source File

SOURCE=..\generated\Matrix2x3Plugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\MIDIPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\MiscPrimitivePlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\SecurityPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\SerialPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\SocketPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\SoundCodecPrims.c
# End Source File
# Begin Source File

SOURCE=..\generated\SoundGenerationPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\SoundPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\sqGSMCodecPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\sqNamedPrims.c
# End Source File
# Begin Source File

SOURCE=..\generated\sqOldSoundPrims.c
# End Source File
# Begin Source File

SOURCE=..\generated\Squeak3D.c
# End Source File
# Begin Source File

SOURCE=..\generated\sqVirtualMachine.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32Alloc.c
# End Source File
# Begin Source File

SOURCE=.\Win95\sqWin32Args.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32AsyncFilePrims.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32D3D.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32Directory.c
# End Source File
# Begin Source File

SOURCE=.\Win95\sqWin32Drop.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32ExternalPrims.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32FilePrims.c
# End Source File
# Begin Source File

SOURCE=.\Win95\sqWin32Intel.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32Joystick.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32MIDI.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32NewNet.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32PluginSupport.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32Prefs.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32Security.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32SerialPort.c
# End Source File
# Begin Source File

SOURCE=.\Win95\sqWin32Service.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32Sound.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32Stubs.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32Utils.c
# End Source File
# Begin Source File

SOURCE=.\sqWin32Window.c
# End Source File
# Begin Source File

SOURCE=..\generated\StarSqueakPlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\SurfacePlugin.c
# End Source File
# Begin Source File

SOURCE=..\generated\ZipPlugin.c
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# Begin Source File

SOURCE=.\Squeak.rc
# End Source File
# End Group
# End Target
# End Project
