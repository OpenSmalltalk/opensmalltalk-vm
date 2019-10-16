#include "stringUtilities.h"

void
vm_string_append_into(char *dest, const char *source, size_t destBufferSize)
{
    size_t destSize = strlen(dest);
    size_t destIndex = destSize;

    for(destIndex = destSize; (destIndex < destBufferSize - 1) && (*source != 0); ++destIndex)
        dest[destIndex] = *(source++);
    dest[destIndex] = 0;
}

char*
vm_string_concat(const char *first, const char *second)
{
    size_t firstSize = first ? strlen(first) : 0;
    size_t secondSize = second ? strlen(second) : 0;

    char *buffer = malloc(firstSize + secondSize + 1);
    memcpy(buffer, first, firstSize);
    memcpy(buffer + firstSize, second, secondSize);
    buffer[firstSize + secondSize] = 0;

    return buffer;
}

#ifdef _WIN32
#   define WIN32_LEAN_AND_MEAN
#   include <windows.h>

uint16_t*
vm_string_convert_utf8_to_utf16(const char *utf8String)
{
    size_t stringLength = strlen(utf8String);
    int requiredBufferSize = MultiByteToWideChar(CP_UTF8, 0, utf8String, stringLength, NULL, 0);
    WCHAR *utf16String = (WCHAR*)calloc(requiredBufferSize + 1, 2);
    MultiByteToWideChar(CP_UTF8, 0, utf8String, stringLength, utf16String, requiredBufferSize + 1);
    return utf16String;
}

char*
vm_string_convert_utf16_to_utf8(const uint16_t *utf16String)
{
    size_t stringLength = lstrlenW(utf16String);
    int requiredBufferSize = WideCharToMultiByte(CP_UTF8, 0, utf16String, stringLength, NULL, 0, NULL, FALSE);
    char *utf8String = (char*)calloc(requiredBufferSize + 1, 1);
    WideCharToMultiByte(CP_UTF8, 0, utf16String, stringLength, utf8String, requiredBufferSize + 1, NULL, FALSE);
    return utf8String;
}

#endif //_WIN32
