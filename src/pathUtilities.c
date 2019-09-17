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
        dest[destIndex] = *source;
    dest[destIndex] = 0;
}

pharovm_error_code_t
pharovm_path_getCurrentWorkingDirInto(char *target, size_t targetSize)
{
#ifdef _WIN32
    unsigned short *tempBuffer = (unsigned short*)calloc(MAX_PATH + 1, sizeof(unsigned short));
    GetCurrentDirectoryW(MAX_PATH + 1, tempBuffer);
    sqUTF16ToUTF8Copy(target, targetSize, tempBuffer);
    free(tempBuffer);
#else
    if(getcwd(target, targetSize) == NULL)
        return PHAROVM_ERROR;
#endif

    return PHAROVM_SUCCESS;
}

bool
pharovm_path_isAbsolutePath(const char *path)
{
#ifdef _WIN32
    return path && (path[0] != 0 && path[1] == ':');
#else
    /* Assume UNIX style path. */
    return path && (*path == '/');
#endif
}

pharovm_error_code_t
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

#ifdef _WIN32
        stringAppend(target, "\\", targetSize);
        if (src[0] == '.' && (src[1] == '/' || src[1] == '\\'))
            stringAppend(target, src + 2, targetSize);
        else
            stringAppend(target, src, targetSize);
#else
        stringAppend(target, "/", targetSize);
        if(src[0] == '.' && src[1] == '/')
            stringAppend(target, src + 2, targetSize);
        else
            stringAppend(target, src, targetSize);
#endif
    }

    return PHAROVM_SUCCESS;
}

pharovm_error_code_t
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
    if (lastSeparator && lastSeparator - src + 1 < copySize)
    {
        // FIXME: raise an error code, and handle this case.
        size_t newCopySize = lastSeparator - src + 1;
        if(newCopySize < copySize)
            copySize = newCopySize;
    }

    strncpy(target, src, copySize);
    target[copySize] = 0;

    return PHAROVM_SUCCESS;
}

pharovm_error_code_t
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

pharovm_error_code_t
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

#else

size_t
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
