#ifndef __SQ_WIN32_FILE_H
#define __SQ_WIN32_FILE_H

/**
    Converts multi-byte characters to wide characters. Handles paths longer
    than 260 characters (including NULL) by prepending "\\?\" to encode UNC
    paths as suggested in http://msdn.microsoft.com/en-us/library/windows/
    desktop/aa365247%28v=vs.85%29.aspx#maxpath
      "The maximum path of 32,767 characters is approximate,
         because the "\\?\" prefix may be expanded to a longer
         string by the system at run time, and this expansion
         applies to the total length."
    
    Note that we do not check for the correct path component size,
    which should be MAX_PATH in general but can vary between file systems.   
    Actually, we should perform an additional check with
    GetVolumneInformation to acquire lpMaximumComponentLength. 

    Note that another possibility would be to use 8.3 aliases
    for path components like the Windows Explorer does. However,
    this feature also depends on the volume specifications.

    Calling alloca() should be fine because we limit path length to 32k.
    Stack size limit is much higher.

    When using an API to create a directory, the specified path cannot be 
    so long that you cannot append an 8.3 file name (that is, the directory 
    name cannot exceed MAX_PATH minus 12).
**/


#define ALLOC_WIN32_PATH(out_path, in_name, in_size) { \
  int sz = MultiByteToWideChar(CP_UTF8, 0, in_name, in_size, NULL, 0); \
  if(sz >= 32767) FAIL(); \
  if(sz >= MAX_PATH-12 /* for directory creation; see above */) { \
    out_path = (WCHAR*)alloca((sz + 4 + 1) * sizeof(WCHAR)); \
    out_path[0] = L'\\'; out_path[1] = L'\\'; \
    out_path[2] = L'?'; out_path[3] = L'\\'; \
    MultiByteToWideChar(CP_UTF8, 0, in_name, in_size, out_path + 4, sz); \
    out_path[sz + 4] = 0; \
    sz += 4; \
  } else { \
    out_path = (WCHAR*)alloca((sz + 1) * sizeof(WCHAR)); \
    MultiByteToWideChar(CP_UTF8, 0, in_name, in_size, out_path, sz); \
    out_path[sz] = 0; \
  } \
}

//  if(wcscpy_s(in_out_wide_path, in_size < sz ? in_size : sz, tmp) != 0) FAIL(); \

#define REALLOC_WIN32_PATH(in_out_wide_path, in_out_size) { \
  int sz = wcslen(in_out_wide_path); \
  WCHAR *tmp = in_out_wide_path; \
  if(in_out_size >= 32767) FAIL(); \
  if(in_out_size < sz) tmp[in_out_size] = 0; \
  if(in_out_size >= MAX_PATH-12 && sz < MAX_PATH-12) { \
    in_out_wide_path = (WCHAR*)alloca((in_out_size+4+1) * sizeof(WCHAR)); \
    in_out_wide_path[0] = L'\\'; in_out_wide_path[1] = L'\\'; \
    in_out_wide_path[2] = L'?'; in_out_wide_path[3] = L'\\'; \
    wcscpy(in_out_wide_path+4, tmp); \
    in_out_size += 4; \
  } else { \
    in_out_wide_path = (WCHAR*)alloca((in_out_size+1) * sizeof(WCHAR)); \
    wcscpy(in_out_wide_path, tmp); \
  } \
  in_out_wide_path[in_out_size] = 0; \
}

#endif /* __SQ_WIN32_FILE_H */
