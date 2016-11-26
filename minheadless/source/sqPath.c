#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#else
#include <unistd.h>
#endif

#include "sqPath.h"
#include "sqTextEncoding.h"

void sqGetCurrentWorkingDir(char *target, size_t targetSize)
{
#ifdef _WIN32
    unsigned short *tempBuffer = (unsigned short*)calloc(MAX_PATH + 1, sizeof(unsigned short));
    GetCurrentDirectoryW(MAX_PATH + 1, tempBuffer);
    sqUTF16ToUTF8Copy(target, targetSize, tempBuffer);
    free(tempBuffer);
#else
    getcwd(target, targetSize);
#endif
}

int sqIsAbsolutePath(const char *path)
{
#ifdef _WIN32
    return path && (path[0] != 0 && path[1] == ':');
#else
    /* Assume UNIX style path. */
    return path && (*path == '/');
#endif
}

void sqPathMakeAbsolute(char *target, size_t targetSize, const char *src)
{
    if (sqIsAbsolutePath(src))
    {
        strcpy(target, src);
    }
    else
    {
        sqGetCurrentWorkingDir(target, targetSize);
        /* TODO: Make a more secure copy than strcat*/
#ifdef _WIN32
        strcat(target, "\\");
        if (src[0] == '.' && (src[1] == '/' || src[1] == '\\'))
            strcat(target, src + 2);
        else
            strcat(target, src);
#else
        strcat(target, "/");
        if(src[0] == '.' && src[1] == '/')
            strcat(target, src + 2);
        else
            strcat(target, src);
#endif
    }
}

void sqPathExtractDirname(char *target, size_t targetSize, const char *src)
{
    size_t copySize;
    const char *lastSeparator = strrchr(src, '/');
#ifdef _WIN32
    const char *lastSeparator2 = strrchr(src, '\\');
    if (!lastSeparator || lastSeparator < lastSeparator2)
        lastSeparator = lastSeparator2;
#endif
    copySize = targetSize;
    if (lastSeparator && lastSeparator - src + 1 < copySize)
        copySize = lastSeparator - src + 1;
    strncpy(target, src, copySize);
}

void sqPathExtractBaseName(char *target, size_t targetSize, const char *src)
{
    const char *lastSeparator = strrchr(src, '/');
#ifdef _WIN32
    const char *lastSeparator2 = strrchr(src, '\\');
    if (!lastSeparator || lastSeparator < lastSeparator2)
        lastSeparator = lastSeparator2;
#endif

    if (lastSeparator)
        strncpy(target, lastSeparator, targetSize);
    else
        strcpy(target, "");
}

void sqPathJoin(char *target, size_t targetSize, const char *first, const char *second)
{
}

