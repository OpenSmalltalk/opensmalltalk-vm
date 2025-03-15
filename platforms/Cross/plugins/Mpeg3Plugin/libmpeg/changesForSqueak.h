#include "mpeg3private.h"
int mpeg3_generate_toc_for_Squeak(mpeg3_t *file, int timecode_search, int print_streams, char *buffer, int buffer_size);

#ifdef _MSC_VER 
//not #if defined(_WIN32) || defined(_WIN64) because we have strncasecmp in mingw
# define strncasecmp _strnicmp
# define strcasecmp _stricmp
#endif
