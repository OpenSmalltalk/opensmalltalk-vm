/* miscellaneous functions */


void sqFilenameFromStringOpen(char *dst, int src, int len) 
{
     memcpy(dst, (char *) src, len);
     dst[len] = '\0';
}


