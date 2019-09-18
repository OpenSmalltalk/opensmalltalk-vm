#include "pathUtilities.h"
#include <string.h>
#include <stdio.h>

#ifdef _WIN32
#   include <windows.h>
#elif defined(__unix__) || defined(__MACH__) || defined(__APPLE__)
#   include <unistd.h>
#   include <dirent.h>
#else
#   define getcwd(target, targetSize) strcpy(target, ".") // Assume target size is always greater than one.
#endif

/**
 * Function for appending string into a buffer. This like strncat, but the size
 * refers to the buffer size instead of the number of elements to copy.
 */
static void
stringAppend(char *dest, const char *source, size_t destBufferSize)
{
    size_t destSize = strlen(dest);
    size_t destIndex = destSize;

    for(destIndex = destSize; (destIndex < destBufferSize - 1) && (*source != 0); ++destIndex)
        dest[destIndex] = *(source++);
    dest[destIndex] = 0;
}

EXPORT(pharovm_error_code_t)
pharovm_path_getCurrentWorkingDirInto(char *target, size_t targetSize)
{
#ifdef _WIN32
    DWORD tempBufferSize = GetCurrentDirectoryW(0, NULL) + 1; // for \0
	WCHAR *tempBuffer = (WCHAR*)calloc(tempBufferSize, sizeof(WCHAR));
    if(!tempBuffer) {
        return PHAROVM_ERROR_OUT_OF_MEMORY;
    }
    GetCurrentDirectoryW(tempBufferSize, tempBuffer);

    WideCharToMultiByte(CP_UTF8, 0, tempBuffer, tempBufferSize, target, targetSize, NULL, FALSE);
	target[targetSize - 1] = 0; // CHECK ME: Is this really needed?
#else
    if(getcwd(target, targetSize) == NULL) {
        return PHAROVM_ERROR;
    }
#endif

    return PHAROVM_SUCCESS;
}

EXPORT(bool)
pharovm_path_isAbsolutePath(const char *path)
{
#ifdef _WIN32
    return path && (path[0] != 0 && path[1] == ':');
#else
    /* Assume UNIX style path. */
    return path && (*path == '/');
#endif
}

EXPORT(pharovm_error_code_t)
pharovm_path_makeAbsoluteInto(char *target, size_t targetSize, const char *src)
{
    pharovm_error_code_t error;

    if (pharovm_path_isAbsolutePath(src))
    {
        strncpy(target, src, targetSize - 1);
        target[targetSize-1] = 0;
    }
    else
    {
        error = pharovm_path_getCurrentWorkingDirInto(target, targetSize);
        if(error) {
            return error;
        }

        size_t workDirSize = strlen(target);

#ifdef _WIN32
        if(workDirSize > 0 && target[workDirSize - 1] != '\\') {
            stringAppend(target, "\\", targetSize);
        }

        if (src[0] == '.' && (src[1] == '/' || src[1] == '\\')) {
            stringAppend(target, src + 2, targetSize);
        } else {
            stringAppend(target, src, targetSize);
        }
#else
        if(workDirSize > 0 && target[workDirSize - 1] != '/') {
            stringAppend(target, "/", targetSize);
        }

        if(src[0] == '.' && src[1] == '/') {
            stringAppend(target, src + 2, targetSize);
        } else {
            stringAppend(target, src, targetSize);
        }
#endif
    }

    return PHAROVM_SUCCESS;
}

EXPORT(pharovm_error_code_t)
pharovm_path_extractDirnameInto(char *target, size_t targetSize, const char *src)
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

    return PHAROVM_SUCCESS;
}

EXPORT(pharovm_error_code_t)
pharovm_path_extractBaseName(char *target, size_t targetSize, const char *src)
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

    return PHAROVM_SUCCESS;
}

#ifdef _WIN32
# define SEPARATOR_STRING "\\"
# define SEPARATOR_CHAR '\\'
#else
# define SEPARATOR_STRING "/"
# define SEPARATOR_CHAR '/'
#endif

EXPORT(pharovm_error_code_t)
pharovm_path_joinInto(char *target, size_t targetSize, const char *first, const char *second)
{
    strncpy(target, first, targetSize - 1);
    target[targetSize - 1] = 0;

    if(first[strlen(first)-1] != SEPARATOR_CHAR) {
        stringAppend(target, SEPARATOR_STRING, targetSize);
    }
    stringAppend(target, second, targetSize);

    return PHAROVM_SUCCESS;
}

#ifdef _WIN32

EXPORT(size_t)
pharovm_path_findImagesInFolder(const char *searchPath, char *imagePathBuffer, size_t imagePathBufferSize)
{
    WIN32_FIND_DATAW findFileData;
    HANDLE findHandle;

    size_t searchPathWSize = MultiByteToWideChar(CP_UTF8, 0, searchPath, strlen(searchPath), NULL, 0);
    WCHAR *searchPathW = (WCHAR*)calloc(searchPathWSize + 1, 2);
    MultiByteToWideChar(CP_UTF8, 0, searchPath, strlen(searchPath), searchPathW, searchPathWSize + 1);
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
pharovm_path_findImagesInFolder(const char *searchPath, char *imagePathBuffer, size_t imagePathBufferSize)
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
        char *extension = strrchr(name, '.');
        if(!extension)
            continue;

        if(strcmp(extension, ".image") != 0)
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
