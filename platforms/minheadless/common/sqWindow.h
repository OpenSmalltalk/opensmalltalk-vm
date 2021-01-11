#ifndef SQUEAK_WINDOW_H
#define SQUEAK_WINDOW_H

/**
 * Window system interface.
 */
typedef struct
{
    const char *name;
    void *primitives;

    void (*initialize)(void);

    void (*shutdown)(void);

    sqInt (*setCursorARGB)(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY);

    sqInt (*forceDisplayUpdate)(void);

    sqInt (*formPrint)(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth,
    		  double hScale, double vScale, sqInt landscapeFlag);

    void (*noteDisplayChangedWidthHeightDepth)(void *b, int w, int h, int d);

    sqInt (*setFullScreen)(sqInt fullScreen);

    sqInt (*setCursor)(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY);

    sqInt (*setCursorWithMask)(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY);

    sqInt (*showDisplay)(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
    		    sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB);

    sqInt (*hasDisplayDepth)(sqInt depth);

    sqInt (*setDisplayMode)(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag);

    char* (*getWindowLabel)(void);

    sqInt (*setWindowLabelOfSize)(void *lblIndex, sqInt sz);

    sqInt (*getWindowWidth)(void);

    sqInt (*getWindowHeight)(void);

    sqInt (*setWindowWidthHeight)(sqInt w, sqInt h);

    sqInt (*isWindowObscured)(void);

    sqInt (*getNextEvent)(sqInputEvent *evt);

    sqInt (*getButtonState)(void);

    sqInt (*getKeystroke)(void);

    sqInt (*mousePoint)(void);

    sqInt (*peekKeystroke)(void);

    sqInt (*processEvents)(void);

    double (*screenScaleFactor)(void);

    sqInt (*screenSize)(void);

    sqInt (*screenDepth)(void);

    sqInt (*clipboardSize)(void);

    sqInt (*clipboardReadIntoAt)(sqInt count, sqInt byteArrayIndex, sqInt startIndex);

    sqInt (*clipboardWriteFromAt)(sqInt count, sqInt byteArrayIndex, sqInt startIndex);

    sqInt (*dropInit) (void);
    sqInt (*dropShutdown) (void);

    char* (*dropRequestFileName)(sqInt dropIndex);
    char* (*dropRequestURI)(sqInt dropIndex);
    sqInt (*dropRequestFileHandle)(sqInt dropIndex);
} sqWindowSystem;

#endif /* SQUEAK_WINDOW_H */
