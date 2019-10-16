#include "pathUtilities.h"
#include "stringUtilities.h"
#include <string.h>
#include <stdio.h>

#ifdef _WIN32
#   define WIN32_LEAN_AND_MEAN
#   include <windows.h>
#elif defined(__unix__) || defined(__MACH__) || defined(__APPLE__)
#   include <unistd.h>
#   include <dirent.h>
#else
#   define getcwd(target, targetSize) strcpy(target, ".") // Assume target size is always greater than one.
#endif


EXPORT(VMErrorCode)
vm_path_get_current_working_dir_into(char *target, size_t targetSize)
{
#ifdef _WIN32
    DWORD tempBufferSize = GetCurrentDirectoryW(0, NULL) + 1; // for \0
	WCHAR *tempBuffer = (WCHAR*)calloc(tempBufferSize, sizeof(WCHAR));
    if(!tempBuffer) {
        return VM_ERROR_OUT_OF_MEMORY;
    }
    GetCurrentDirectoryW(tempBufferSize, tempBuffer);

    WideCharToMultiByte(CP_UTF8, 0, tempBuffer, tempBufferSize, target, targetSize, NULL, FALSE);
	target[targetSize - 1] = 0; // CHECK ME: Is this really needed?
#else
    if(getcwd(target, targetSize) == NULL) {
        return VM_ERROR;
    }
#endif

    return VM_SUCCESS;
}

EXPORT(bool)
vm_path_is_absolute_path(const char *path)
{
#ifdef _WIN32
    return path && (path[0] != 0 && path[1] == ':');
#else
    /* Assume UNIX style path. */
    return path && (*path == '/');
#endif
}

EXPORT(VMErrorCode)
vm_path_make_absolute_into(char *target, size_t targetSize, const char *src)
{
    VMErrorCode error;

    if (vm_path_is_absolute_path(src))
    {
        strncpy(target, src, targetSize - 1);
        target[targetSize-1] = 0;
    }
    else
    {
        error = vm_path_get_current_working_dir_into(target, targetSize);
        if(error) {
            return error;
        }

        size_t workDirSize = strlen(target);

#ifdef _WIN32
        if(workDirSize > 0 && target[workDirSize - 1] != '\\')
        {
            vm_string_append_into(target, "\\", targetSize);
        }

        if (src[0] == '.' && (src[1] == '/' || src[1] == '\\'))
        {
            vm_string_append_into(target, src + 2, targetSize);
        }
        else {
            vm_string_append_into(target, src, targetSize);
        }
#else
        if(workDirSize > 0 && target[workDirSize - 1] != '/')
        {
            vm_string_append_into(target, "/", targetSize);
        }

        if(src[0] == '.' && src[1] == '/')
        {
            vm_string_append_into(target, src + 2, targetSize);
        }
        else
        {
            vm_string_append_into(target, src, targetSize);
        }
#endif
    }

    return VM_SUCCESS;
}

EXPORT(VMErrorCode)
vm_path_extract_dirname_into(char *target, size_t targetSize, const char *src)
{
    size_t copySize;
    const char *lastSeparator = strrchr(src, '/');
#ifdef _WIN32
    const char *lastSeparator2 = strrchr(src, '\\');
    if (!lastSeparator || lastSeparator < lastSeparator2)
        lastSeparator = lastSeparator2;
#endif
    copySize = targetSize - 1;
    if (lastSeparator && lastSeparator - src < copySize)
    {
        // FIXME: raise an error code, and handle this case.
        size_t newCopySize = lastSeparator - src;
        if(newCopySize < copySize)
            copySize = newCopySize;
    }

    strncpy(target, src, copySize);
    target[copySize] = 0;

    return VM_SUCCESS;
}

EXPORT(VMErrorCode)
vm_path_extract_basename_into(char *target, size_t targetSize, const char *src)
{
    const char *lastSeparator = strrchr(src, '/');
#ifdef _WIN32
    const char *lastSeparator2 = strrchr(src, '\\');
    if (!lastSeparator || lastSeparator < lastSeparator2)
        lastSeparator = lastSeparator2;
#endif

    if (lastSeparator)
    {
        strncpy(target, lastSeparator, targetSize - 1);
        target[targetSize - 1] = 0;
    }
    else
    {
        strcpy(target, "");
    }

    return VM_SUCCESS;
}

#ifdef _WIN32
# define SEPARATOR_STRING "\\"
# define SEPARATOR_CHAR '\\'
#else
# define SEPARATOR_STRING "/"
# define SEPARATOR_CHAR '/'
#endif

EXPORT(VMErrorCode)
vm_path_join_into(char *target, size_t targetSize, const char *first, const char *second)
{
    strncpy(target, first, targetSize - 1);
    target[targetSize - 1] = 0;

    if(first[strlen(first)-1] != SEPARATOR_CHAR) {
        vm_string_append_into(target, SEPARATOR_STRING, targetSize);
    }
    vm_string_append_into(target, second, targetSize);

    return VM_SUCCESS;
}

#ifdef _WIN32

EXPORT(size_t)
vm_path_find_files_with_extension_in_folder(const char *searchPath, const char *extension, char *imagePathBuffer, size_t imagePathBufferSize)
{
    WIN32_FIND_DATAW findFileData;
    HANDLE findHandle;

    WCHAR *searchPathW = vm_string_convert_utf8_to_utf16(searchPath);
    WCHAR *searchPathPattern = (WCHAR*)calloc(FILENAME_MAX, 2);
    lstrcpyW(searchPathPattern, searchPathW);
    lstrcatW(searchPathPattern, L"\\*.image");

    findHandle = FindFirstFileW(searchPathPattern, &findFileData);
    if(findHandle == INVALID_HANDLE_VALUE)
    {
        free(searchPathW);
        return 0;
    }

    bool hasPreviousOutput = *imagePathBuffer != 0;
    int result = 0;

    WCHAR *pathConversionBuffer = (WCHAR*)calloc(FILENAME_MAX, 2);

    do
    {
        if(!hasPreviousOutput)
        {
            lstrcpyW(pathConversionBuffer, searchPathW);
            lstrcatW(pathConversionBuffer, L"\\");
            lstrcatW(pathConversionBuffer, findFileData.cFileName);
            WideCharToMultiByte(CP_UTF8, 0, pathConversionBuffer, -1, imagePathBuffer, imagePathBufferSize, NULL, FALSE);
            imagePathBuffer[imagePathBufferSize - 1] = 0; // CHECK ME: Is this really needed?
        }

        hasPreviousOutput = true;
        ++result;
    } while(FindNextFileW(findHandle, &findFileData));

    FindClose(findHandle);

    free(pathConversionBuffer);
    free(searchPathPattern);
    free(searchPathW);
    return result;
}
#else

EXPORT(size_t)
vm_path_find_files_with_extension_in_folder(const char *searchPath, const char *extension, char *imagePathBuffer, size_t imagePathBufferSize)
{
    struct dirent *entry;
    int result = 0;
    bool hasPreviousOutput = *imagePathBuffer != 0;
    DIR *dir = opendir(searchPath);
    if(!dir)
        return 0;

    while((entry = readdir(dir)) != NULL)
    {
        char *name = entry->d_name;
        char *fileExtension = strrchr(name, '.');
        if(!extension)
            continue;

        if(strcmp(fileExtension, extension) != 0)
            continue;

        if(!hasPreviousOutput)
            snprintf(imagePathBuffer, imagePathBufferSize, "%s/%s", searchPath, name);
        ++result;
        hasPreviousOutput = true;
    }
    closedir(dir);

    return result;
}
#endif
