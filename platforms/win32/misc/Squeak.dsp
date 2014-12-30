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
# PROP Output_Dir "..\Release"
# PROP Intermediate_Dir "..\Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /Ob2 /I "../../vm" /I "..\vm" /D "NDEBUG" /D "WIN32_FILE_SUPPORT" /D "SQUEAK_BUILTIN_PLUGIN" /D "WIN32" /D "_WINDOWS" /D "_MBCS" /D "NO_STD_FILE_SUPPORT" /FR /YX /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x407 /d "NDEBUG"
# ADD RSC /l 0x407 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib wsock32.lib winmm.lib opengl32.lib /nologo /subsystem:windows /machine:I386

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "..\Debug"
# PROP Intermediate_Dir "..\Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /W3 /Gm /GX /ZI /Od /I "./../../vm" /I "./vm" /I "..\vm" /D "_DEBUG" /D "SQUEAK_BUILTIN_PLUGIN" /D "WIN32" /D "_WINDOWS" /D "_MBCS" /D "WIN32_FILE_SUPPORT" /D "NO_STD_FILE_SUPPORT" /YX /FD /GZ /c
# ADD BASE MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x407 /d "_DEBUG"
# ADD RSC /l 0x407 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib wsock32.lib winmm.lib ddraw.lib /nologo /subsystem:windows /debug /machine:I386 /pdbtype:sept

!ENDIF 

# Begin Target

# Name "Squeak - Win32 Release"
# Name "Squeak - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=..\vm\interp.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqNamedPrims.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=.\Squeak.rc
# End Source File
# Begin Source File

SOURCE=..\vm\sqVirtualMachine.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Alloc.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Args.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Directory.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Exports.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32ExternalPrims.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32GUID.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Main.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32PluginSupport.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Prefs.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Service.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Stubs.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Utils.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Window.c
# SUBTRACT CPP /D "SQUEAK_BUILTIN_PLUGIN"
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=..\vm\sq.h
# End Source File
# Begin Source File

SOURCE=..\vm\sqConfig.h
# End Source File
# Begin Source File

SOURCE=..\vm\sqGnu.h
# End Source File
# Begin Source File

SOURCE=..\vm\sqNamedPrims.h
# End Source File
# Begin Source File

SOURCE=..\vm\sqPlatformSpecific.h
# End Source File
# Begin Source File

SOURCE=..\vm\sqVirtualMachine.h
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32.h
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Alloc.h
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Args.h
# End Source File
# Begin Source File

SOURCE=..\vm\sqWin32Prefs.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# Begin Source File

SOURCE=.\squeak.ico
# End Source File
# Begin Source File

SOURCE=.\squeak2.ico
# End Source File
# Begin Source File

SOURCE=.\squeak3.ico
# End Source File
# End Group
# Begin Group "Plugins (internal)"

# PROP Default_Filter ""
# Begin Group "ADPCMCodecPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\ADPCMCodecPlugin\ADPCMCodecPlugin.c
# End Source File
# End Group
# Begin Group "AsynchFilePlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\AsynchFilePlugin\AsynchFilePlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\AsynchFilePlugin\AsynchFilePlugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\AsynchFilePlugin\sqWin32AsyncFilePrims.c
# End Source File
# End Group
# Begin Group "B2DPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\B2DPlugin\B2DPlugin.c
# End Source File
# End Group
# Begin Group "B3DAcceleratorPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\B3DAcceleratorPlugin\B3DAcceleratorPlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\B3DAcceleratorPlugin\B3DAcceleratorPlugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\B3DAcceleratorPlugin\sqOpenGLRenderer.c
# End Source File
# Begin Source File

SOURCE=..\plugins\B3DAcceleratorPlugin\sqOpenGLRenderer.h
# End Source File
# Begin Source File

SOURCE=..\plugins\B3DAcceleratorPlugin\sqWin32D3D.c
# End Source File
# Begin Source File

SOURCE=..\plugins\B3DAcceleratorPlugin\sqWin32DualB3DX.c
# End Source File
# Begin Source File

SOURCE=..\plugins\B3DAcceleratorPlugin\sqWin32OpenGL.c
# End Source File
# Begin Source File

SOURCE=..\plugins\B3DAcceleratorPlugin\sqWin32OpenGL.h
# End Source File
# End Group
# Begin Group "BitBltPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\BitBltPlugin\BitBltPlugin.c
# End Source File
# End Group
# Begin Group "DropPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\DropPlugin\DropPlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\DropPlugin\DropPlugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\DropPlugin\sqWin32Drop.c
# End Source File
# End Group
# Begin Group "DSAPrims"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\DSAPrims\DSAPrims.c
# End Source File
# End Group
# Begin Group "FFTPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\FFTPlugin\FFTPlugin.c
# End Source File
# End Group
# Begin Group "FilePlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\FilePlugin\FilePlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\FilePlugin\FilePlugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\FilePlugin\sqFilePluginBasicPrims.c
# End Source File
# Begin Source File

SOURCE=..\plugins\FilePlugin\sqWin32FilePrims.c
# End Source File
# End Group
# Begin Group "FloatArrayPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\FloatArrayPlugin\FloatArrayPlugin.c
# End Source File
# End Group
# Begin Group "GeniePlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\GeniePlugin\GeniePlugin.c
# End Source File
# End Group
# Begin Group "IntegerPokerPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\IntegerPokerPlugin\IntegerPokerPlugin.c
# End Source File
# End Group
# Begin Group "JoystickTabletPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\JoystickTabletPlugin\JoystickTabletPlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JoystickTabletPlugin\JoystickTabletPlugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JoystickTabletPlugin\sqWin32Joystick.c
# End Source File
# End Group
# Begin Group "JPEGReaderPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\JPEGReaderPlugin\JPEGReaderPlugin.c
# End Source File
# End Group
# Begin Group "JPEGReadWriter2Plugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\Error.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcapimin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcapistd.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jccoefct.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jccolor.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcdctmgr.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jchuff.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jchuff.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcinit.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcmainct.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcmarker.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcmaster.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcomapi.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jconfig.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcparam.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcphuff.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcprepct.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jcsample.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jctrans.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdapimin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdapistd.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdatadst.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdatasrc.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdcoefct.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdcolor.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdct.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jddctmgr.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdhuff.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdhuff.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdinput.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdmainct.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdmarker.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdmaster.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdmerge.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdphuff.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdpostct.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdsample.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jdtrans.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jerror.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jerror.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jfdctflt.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jfdctfst.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jfdctint.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jidctflt.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jidctfst.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jidctint.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jidctred.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jinclude.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jmemdatadst.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jmemdatasrc.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jmemmgr.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jmemnobs.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jmemsys.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jmorecfg.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jpegint.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jpeglib.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\JPEGReadWriter2Plugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\JPEGReadWriter2Plugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jquant1.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jquant2.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jutils.c
# End Source File
# Begin Source File

SOURCE=..\plugins\JPEGReadWriter2Plugin\jversion.h
# End Source File
# End Group
# Begin Group "Klatt"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\Klatt\Klatt.c
# End Source File
# End Group
# Begin Group "LargeIntegers"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\LargeIntegers\LargeIntegers.c
# End Source File
# End Group
# Begin Group "Matrix2x3Plugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\Matrix2x3Plugin\Matrix2x3Plugin.c
# End Source File
# End Group
# Begin Group "MIDIPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\MIDIPlugin\MIDIPlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\MIDIPlugin\MIDIPlugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\MIDIPlugin\sqWin32MIDI.c
# End Source File
# End Group
# Begin Group "MiscPrimitivePlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\MiscPrimitivePlugin\MiscPrimitivePlugin.c
# End Source File
# End Group
# Begin Group "Mpeg3Plugin"

# PROP Default_Filter ""
# Begin Group "libmpeg"

# PROP Default_Filter ""
# Begin Group "audio"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\audio\dct.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\audio\header.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\audio\layer1.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\audio\layer2.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\audio\layer3.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\audio\mpeg3audio.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\audio\pcm.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\audio\synthesizers.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\audio\tables.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# End Group
# Begin Group "video"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\getpicture.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\headers.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\idct.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\macroblocks.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\mmxtest.c
# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video"
# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\motion.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\mpeg3video.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\output.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\reconstruct.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\seek.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\slice.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\video\vlc.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I ".." /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# End Group
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\bitstream.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS" /D inline=__inline

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\changesForSqueak.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS" /D inline=__inline

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\libmpeg3.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS" /D inline=__inline

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\mpeg3atrack.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS" /D inline=__inline

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\mpeg3demux.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS" /D inline=__inline

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\mpeg3io.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS" /D inline=__inline

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\mpeg3title.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS" /D inline=__inline

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\libmpeg\mpeg3vtrack.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS" /D inline=__inline

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# End Group
# Begin Source File

SOURCE=..\plugins\Mpeg3Plugin\Mpeg3Plugin.c

!IF  "$(CFG)" == "Squeak - Win32 Release"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS" /D inline=__inline

!ELSEIF  "$(CFG)" == "Squeak - Win32 Debug"

# ADD CPP /I "../plugins/Mpeg3Plugin/libmpeg" /I "../plugins/Mpeg3Plugin/libmpeg/audio" /I "../plugins/Mpeg3Plugin/libmpeg/video" /D "NOPTHREADS"

!ENDIF 

# End Source File
# End Group
# Begin Group "SecurityPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\SecurityPlugin\SecurityPlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\SecurityPlugin\SecurityPlugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\SecurityPlugin\sqWin32Security.c
# End Source File
# End Group
# Begin Group "SerialPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\SerialPlugin\SerialPlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\SerialPlugin\SerialPlugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\SerialPlugin\sqWin32SerialPort.c
# End Source File
# End Group
# Begin Group "SocketPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\SocketPlugin\SocketPlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\SocketPlugin\SocketPlugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\SocketPlugin\sqWin32NewNet.c
# End Source File
# End Group
# Begin Group "SoundCodecPrims"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\SoundCodecPrims\SoundCodecPrims.c
# End Source File
# Begin Source File

SOURCE=..\plugins\SoundCodecPrims\SoundCodecPrims.h
# End Source File
# Begin Source File

SOURCE=..\plugins\SoundCodecPrims\sqSoundCodecPluginBasicPrims.c
# End Source File
# End Group
# Begin Group "SoundGenerationPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\SoundGenerationPlugin\SoundGenerationPlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\SoundGenerationPlugin\SoundGenerationPlugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\SoundGenerationPlugin\sqOldSoundPrims.c
# End Source File
# End Group
# Begin Group "SoundPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\SoundPlugin\SoundPlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\SoundPlugin\SoundPlugin.h
# End Source File
# Begin Source File

SOURCE=..\plugins\SoundPlugin\sqWin32Sound.c
# End Source File
# End Group
# Begin Group "Squeak3D"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\Squeak3D\b3d.h
# End Source File
# Begin Source File

SOURCE=..\plugins\Squeak3D\b3dAlloc.c
# End Source File
# Begin Source File

SOURCE=..\plugins\Squeak3D\b3dAlloc.h
# End Source File
# Begin Source File

SOURCE=..\plugins\Squeak3D\b3dDraw.c
# End Source File
# Begin Source File

SOURCE=..\plugins\Squeak3D\b3dInit.c
# End Source File
# Begin Source File

SOURCE=..\plugins\Squeak3D\b3dMain.c
# End Source File
# Begin Source File

SOURCE=..\plugins\Squeak3D\b3dRemap.c
# End Source File
# Begin Source File

SOURCE=..\plugins\Squeak3D\b3dTypes.h
# End Source File
# Begin Source File

SOURCE=..\plugins\Squeak3D\Squeak3D.c
# End Source File
# End Group
# Begin Group "SqueakFFIPrims"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\SqueakFFIPrims\sqFFI.h
# PROP Exclude_From_Build 1
# End Source File
# Begin Source File

SOURCE=..\plugins\SqueakFFIPrims\SqueakFFIPrims.c
# PROP Exclude_From_Build 1
# End Source File
# Begin Source File

SOURCE=..\plugins\SqueakFFIPrims\sqWin32FFI.c
# PROP Exclude_From_Build 1
# End Source File
# End Group
# Begin Group "StarSqueakPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\StarSqueakPlugin\StarSqueakPlugin.c
# End Source File
# End Group
# Begin Group "SurfacePlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\SurfacePlugin\SurfacePlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\SurfacePlugin\SurfacePlugin.h
# End Source File
# End Group
# Begin Group "UUIDPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\UUIDPlugin\sqWin32UUID.c
# End Source File
# Begin Source File

SOURCE=..\plugins\UUIDPlugin\UUIDPlugin.c
# End Source File
# Begin Source File

SOURCE=..\plugins\UUIDPlugin\UUIDPlugin.h
# End Source File
# End Group
# Begin Group "ZipPlugin"

# PROP Default_Filter ""
# Begin Source File

SOURCE=..\plugins\ZipPlugin\ZipPlugin.c
# End Source File
# End Group
# End Group
# End Target
# End Project
