#ifndef SQ_TEXT_ENCODING_H
#define SQ_TEXT_ENCODING_H

/* Text encoding conversions. */
extern const char *sqUTF8ToUTF32Iterate(const char *string, int *dest);
extern const unsigned short *sqUTF16ToUTF32Iterate(const unsigned short *string, int *dest);
extern unsigned short *sqUTF8ToUTF16Copy(unsigned short *dest, size_t destSize, const char *src);
extern unsigned short *sqUTF16ToUTF8Copy(char *dest, size_t destSize, const unsigned short *src);
extern unsigned short *sqUTF8toUTF16New(const char *string);

#endif /* SQ_TEXT_ENCODING_H */
