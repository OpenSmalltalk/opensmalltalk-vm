#include "pharovm/pharo.h"

#include "windows.h"

/*
* Allow to test if the standard input/output files are from a console or not
* Inspired of: https://fossies.org/linux/misc/vim-8.0.tar.bz2/vim80/src/iscygpty.c?m=t
* Return values:
* -1 - Error
* 0 - no console (windows only)
* 1 - normal terminal (unix terminal / windows console)
* 2 - pipe
* 3 - file
* 4 - cygwin terminal (windows only)
*/
sqInt
fileHandleType(HANDLE fdHandle) {
   if (fdHandle == INVALID_HANDLE_VALUE) {
       return -1;
   }

   /* In case of Windows Shell case */
   DWORD fileType = GetFileType(fdHandle);
   if (fileType == FILE_TYPE_CHAR)
       /* The specified file is a character file, typically an LPT device or a console. */
       /* https://msdn.microsoft.com/en-us/library/windows/desktop/aa364960(v=vs.85).aspx */
       return 1;

   /* In case of Unix emulator, we need to parse the name of the pipe */

   /* Cygwin/msys's pty is a pipe. */
   if (fileType != FILE_TYPE_PIPE) {
       if (fileType == FILE_TYPE_DISK)
           return 3; //We have a file here
       if (fileType == FILE_TYPE_UNKNOWN && GetLastError() == ERROR_INVALID_HANDLE)
           return  0; //No stdio allocated
       return  -1;
   }

   int size = sizeof(FILE_NAME_INFO) + sizeof(WCHAR) * MAX_PATH;
   FILE_NAME_INFO *nameinfo;
   WCHAR *p = NULL;

   typedef BOOL(WINAPI *pfnGetFileInformationByHandleEx)(
       HANDLE                    hFile,
       FILE_INFO_BY_HANDLE_CLASS FileInformationClass,
       LPVOID                    lpFileInformation,
       DWORD                     dwBufferSize
       );
   static pfnGetFileInformationByHandleEx pGetFileInformationByHandleEx = NULL;
   if (!pGetFileInformationByHandleEx) {
       pGetFileInformationByHandleEx = (pfnGetFileInformationByHandleEx)
           GetProcAddress(GetModuleHandle(TEXT("kernel32.dll")), "GetFileInformationByHandleEx");
       if (!pGetFileInformationByHandleEx)
           return -1;
   }

   nameinfo = malloc(size);
   if (nameinfo == NULL) {
       return -1;
   }
   /* Check the name of the pipe: '\{cygwin,msys}-XXXXXXXXXXXXXXXX-ptyN-{from,to}-master' */
   if (pGetFileInformationByHandleEx(fdHandle, FileNameInfo, nameinfo, size)) {
       nameinfo->FileName[nameinfo->FileNameLength / sizeof(WCHAR)] = L'\0';
       p = nameinfo->FileName;
       //Check that the pipe name contains msys or cygwin
       if ((((wcsstr(p, L"msys-") || wcsstr(p, L"cygwin-"))) &&
           (wcsstr(p, L"-pty") && wcsstr(p, L"-master")))) {
           //The openned pipe is a msys xor cygwin pipe to pty
           free(nameinfo);
           return 4;
       }
       else
           free(nameinfo);
           return 2; //else it is just a standard pipe
   }
   free(nameinfo);
   return -1;
}

/*
* Allow to test whether the file handle is from a console or not
* 1 if one of the stdio is redirected to a console pipe, else 0 (and in this case, a file should be created)
*/
sqInt
isFileHandleATTY(HANDLE fdHandle) {
   sqInt res = fileHandleType(fdHandle) ;
   return res == 1 || res == 4;
}
