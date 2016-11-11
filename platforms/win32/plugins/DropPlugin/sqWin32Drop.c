/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Drop.c
*   CONTENT: Drag and Drop support from Windows
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   Andreas.Raab@disney.com
*
*****************************************************************************/
#include <windows.h>
#include <ole2.h>
#include "sq.h"

/* Import from VM */
extern struct VirtualMachine *interpreterProxy;

/* Import from generated plugin AioPlugin/AioPlugin.c or FilePlugin/FilePlugin.c or Win32OSProcessPlugin/Win32OSProcessPlugin.c
   KNOWN LIMITATION: one and only one of these plugin should be internal... */
usqInt fileRecordSize(void);
void * fileValueOf(sqInt objectPointer);

/* Import from FilePlugin/sqWin32FilePrims.c */
sqInt sqFileOpen(void *f, char* fileNameIndex, sqInt fileNameSize, sqInt writeFlag);

/* Import from sqWin32Window.c */
extern HWND stWindow;

#if 0
#define DPRINTF(x) printf x
#else
#define DPRINTF(x)
#endif

int sqSecFileAccessCallback(void *function) {
#ifndef _MSC_VER
#warning "REMOVE THIS NONSENSE"
#warning "REMOVE THIS NONSENSE"
#warning "REMOVE THIS NONSENSE"
#warning "REMOVE THIS NONSENSE"
#warning "REMOVE THIS NONSENSE"
#endif
  return 0;
}


/***************************************************************************/
/***************************************************************************/
/* File writing helpers                                                    */
/***************************************************************************/
/***************************************************************************/

#define BFT_BITMAP 0x4d42   /* 'BM' */
#define SIZEOF_BITMAPFILEHEADER_PACKED  (   \
    sizeof(WORD) +      /* bfType      */   \
    sizeof(DWORD) +     /* bfSize      */   \
    sizeof(WORD) +      /* bfReserved1 */   \
    sizeof(WORD) +      /* bfReserved2 */   \
    sizeof(DWORD))      /* bfOffBits   */

/* Macro to determine to round off the given value to the closest byte */
#define WIDTHBYTES(i)   ((i+31)/32*4)

WORD DibNumColors (VOID FAR * pv)
{
  int                 bits;
  LPBITMAPINFOHEADER  lpbi;
  LPBITMAPCOREHEADER  lpbc;

  lpbi = ((LPBITMAPINFOHEADER)pv);
  lpbc = ((LPBITMAPCOREHEADER)pv);

  if (lpbi->biSize != sizeof(BITMAPCOREHEADER)){
    if (lpbi->biClrUsed != 0)
      return (WORD)lpbi->biClrUsed;
    bits = lpbi->biBitCount;
  }
  else
    bits = lpbc->bcBitCount;

  switch (bits){
    case 1: return 2;
    case 4: return 16;
    case 8: return 256;
    default: return 0;
  }
}

WORD PaletteSize (VOID FAR * pv)
{
  LPBITMAPINFOHEADER lpbi;
  WORD               NumColors;

  lpbi      = (LPBITMAPINFOHEADER)pv;
  NumColors = DibNumColors(lpbi);

  if (lpbi->biSize == sizeof(BITMAPCOREHEADER))
    return (WORD)(NumColors * sizeof(RGBTRIPLE));
  else
    return (WORD)(NumColors * sizeof(RGBQUAD));
}

HANDLE DibFromBitmap (
    HBITMAP      hbm,
    DWORD            biStyle,
    WORD             biBits,
    HPALETTE     hpal)
{
    BITMAP               bm;
    BITMAPINFOHEADER     bi;
    BITMAPINFOHEADER FAR *lpbi;
    DWORD                dwLen;
    HANDLE               hdib;
    HANDLE               h;
    HDC                  hdc;

    if (!hbm)
        return NULL;

    if (hpal == NULL)
        hpal = GetStockObject(DEFAULT_PALETTE);

    GetObject(hbm,sizeof(bm),(LPSTR)&bm);

    if (biBits == 0) biBits =  bm.bmPlanes * bm.bmBitsPixel;
    if (biBits == 16) biBits = 24;

    bi.biSize               = sizeof(BITMAPINFOHEADER);
    bi.biWidth              = bm.bmWidth;
    bi.biHeight             = bm.bmHeight;
    bi.biPlanes             = 1;
    bi.biBitCount           = biBits;
    bi.biCompression        = biStyle;
    bi.biSizeImage          = 0;
    bi.biXPelsPerMeter      = 0;
    bi.biYPelsPerMeter      = 0;
    bi.biClrUsed            = 0;
    bi.biClrImportant       = 0;

    dwLen  = bi.biSize + PaletteSize(&bi);

    hdc = GetDC(NULL);
    hpal = SelectPalette(hdc,hpal,FALSE);
         RealizePalette(hdc);

    hdib = GlobalAlloc(GHND,dwLen);

    if (!hdib){
        SelectPalette(hdc,hpal,FALSE);
        ReleaseDC(NULL,hdc);
        return NULL;
    }

    lpbi = (VOID FAR *)GlobalLock(hdib);

    *lpbi = bi;

    /*  call GetDIBits with a NULL lpBits param, so it will calculate the
     *  biSizeImage field for us
     */
    GetDIBits(hdc, hbm, 0L, (DWORD)bi.biHeight,
        (LPBYTE)NULL, (LPBITMAPINFO)lpbi, (DWORD)DIB_RGB_COLORS);

    bi = *lpbi;
    GlobalUnlock(hdib);

    /* If the driver did not fill in the biSizeImage field, make one up */
    if (bi.biSizeImage == 0){
        bi.biSizeImage = WIDTHBYTES((DWORD)bm.bmWidth * biBits) * bm.bmHeight;

        if (biStyle != BI_RGB)
            bi.biSizeImage = (bi.biSizeImage * 3) / 2;
    }

    /*  realloc the buffer big enough to hold all the bits */
    dwLen = bi.biSize + PaletteSize(&bi) + bi.biSizeImage;
    if (h = GlobalReAlloc(hdib,dwLen,0))
        hdib = h;
    else{
        GlobalFree(hdib);
        hdib = NULL;

        SelectPalette(hdc,hpal,FALSE);
        ReleaseDC(NULL,hdc);
        return hdib;
    }

    /*  call GetDIBits with a NON-NULL lpBits param, and actualy get the
     *  bits this time
     */
    lpbi = (VOID FAR *)GlobalLock(hdib);

    if (GetDIBits( hdc,
                   hbm,
                   0L,
                   (DWORD)bi.biHeight,
                   (LPBYTE)lpbi + (WORD)lpbi->biSize + PaletteSize(lpbi),
                   (LPBITMAPINFO)lpbi, (DWORD)DIB_RGB_COLORS) == 0){
         GlobalUnlock(hdib);
         hdib = NULL;
         SelectPalette(hdc,hpal,FALSE);
         ReleaseDC(NULL,hdc);
         return NULL;
    }

    bi = *lpbi;
    GlobalUnlock(hdib);

    SelectPalette(hdc,hpal,FALSE);
    ReleaseDC(NULL,hdc);
    return hdib;
}

BOOL WriteDIB (
    LPSTR szFile,
    HANDLE hdib)
{
    BITMAPFILEHEADER    hdr;
    LPBITMAPINFOHEADER  lpbi;
    HFILE               fh;
    OFSTRUCT            of;

    if (!hdib)
        return FALSE;

    fh = OpenFile(szFile, &of, (UINT)OF_CREATE|OF_READWRITE);
    if (fh == -1)
        return FALSE;

    lpbi = (VOID FAR *)GlobalLock (hdib);

    /* Fill in the fields of the file header */
    hdr.bfType          = BFT_BITMAP;
    hdr.bfSize          = GlobalSize (hdib) + SIZEOF_BITMAPFILEHEADER_PACKED;
    hdr.bfReserved1     = 0;
    hdr.bfReserved2     = 0;
    hdr.bfOffBits       = (DWORD) (SIZEOF_BITMAPFILEHEADER_PACKED + lpbi->biSize +
                          PaletteSize(lpbi));

    /* Write the file header */

    /* write bfType*/
    _lwrite(fh, (LPSTR)&hdr.bfType, (UINT)sizeof (WORD));
    /* now pass over extra word, and only write next 3 DWORDS!*/
    _lwrite(fh, (LPSTR)&hdr.bfSize, sizeof(DWORD) * 3);

    /* this struct already DWORD aligned!*/
    /* Write the DIB header and the bits */
    _lwrite (fh, (LPSTR)lpbi, GlobalSize (hdib));

    GlobalUnlock (hdib);
    _lclose(fh);
    return TRUE;
}

/***************************************************************************/
/***************************************************************************/
/* Win32 COM part of drop support                                          */
/***************************************************************************/
/***************************************************************************/

/* C-Style COM ... */
typedef struct DropTarget {
  void **vtbl;
  int ref;
} DropTarget;

static DropTarget stDropTarget;

static unsigned int numDropFiles = 0;
static char** dropFiles = NULL;

static void freeDropFiles(void) {
  int i;
  if(dropFiles) {
    for(i=0; i < numDropFiles; i++) {
      free(dropFiles[i]);
    }
    free(dropFiles);
    dropFiles = NULL;
    numDropFiles = 0;
  }
}

/* Implement IUnknown */
STDMETHODIMP DropTarget_QueryInterface(DropTarget *dt,REFIID riid,PVOID *ppv) {
  DPRINTF(("DropTarget_QueryInterface\n"));
  return E_NOINTERFACE;
}

STDMETHODIMP_(ULONG)DropTarget_AddRef(DropTarget *dt) {
  DPRINTF(("DropTarget_AddRef\n"));
  return ++dt->ref;
}
STDMETHODIMP_(ULONG)DropTarget_Release(DropTarget *dt) {
  DPRINTF(("DropTarget_Release\n"));
  dt->ref--;
  if (dt->ref > 0) return dt->ref;
  return 0;
}

void signalDropEnter(POINTL pt)
{
  POINT winPt;
  winPt.x = pt.x;
  winPt.y = pt.y;
  ScreenToClient(stWindow, &winPt);
  recordDragDropEvent(stWindow, SQDragEnter, winPt.x, winPt.y, 0);
}

STDMETHODIMP DropTarget_DragEnter(DropTarget *dt, 
				  IDataObject *ido,
				  DWORD keyState,
				  POINTL pt,
				  DWORD *effect) {
  FORMATETC fmtetc;
  HRESULT hRes;

  DPRINTF(("DropTarget_DragEnter\n"));

#if 0
  /* TODO: Enumerate formats and check if 
     there's anything interesting. Eventually,
     convert graphical stuff into bitmaps and
     pass them up to Squeak... */
  {
    IEnumFORMATETC *fmt;
    hRes = ido->lpVtbl->EnumFormatEtc(ido, DATADIR_GET, &fmt);
    if(hRes == S_OK) {
      DPRINTF(("Enumerating formats\n"));
      hRes = fmt->lpVtbl->Reset(fmt);
      if(FAILED(hRes)) DPRINTF(("Reset() failed (errCode = %x)\n"));
      do {
	DWORD num;
	FORMATETC fmtEtc[1];
	FORMATETC *fmtRec = fmtEtc;
	hRes = fmt->lpVtbl->Next(fmt, 1, fmtRec, &num);
	if(hRes == S_OK) {
	  /* got it */
	  DPRINTF(("New format:\n"));
	  DPRINTF(("\tCLIPFORMAT: %d ", fmtRec->cfFormat));
	  switch(fmtRec->cfFormat) {
	  case CF_TEXT: DPRINTF(("(text)")); break;
	  case CF_BITMAP: DPRINTF(("(bitmap)")); break;
	  case CF_METAFILEPICT: DPRINTF(("(metafilepict)")); break;
	  case CF_SYLK: DPRINTF(("(symbolic link format)")); break;
	  case CF_DIF: DPRINTF(("(data interchange format)")); break;
	  case CF_TIFF: DPRINTF(("(tiff)")); break;
	  case CF_OEMTEXT: DPRINTF(("(oem text)")); break;
	  case CF_DIB: DPRINTF(("(DIB)")); break;
	  case CF_PALETTE: DPRINTF(("(palette)")); break;
	  case CF_PENDATA: DPRINTF(("(pendata)")); break;
	  case CF_RIFF: DPRINTF(("(RIFF data)")); break;
	  case CF_WAVE: DPRINTF(("(wave)")); break;
	  case CF_UNICODETEXT: DPRINTF(("(unicode text)")); break;
	  case CF_ENHMETAFILE: DPRINTF(("(enhanced metafile)")); break;
	  case CF_HDROP: DPRINTF(("(drop files)")); break;
	  case CF_LOCALE: DPRINTF(("(locale)")); break;
	  case CF_DSPTEXT: DPRINTF(("(private text)")); break;
	  case CF_DSPBITMAP: DPRINTF(("(private bitmap)")); break;
	  case CF_DSPMETAFILEPICT: DPRINTF(("(private metafilepict)")); break;
	  case CF_DSPENHMETAFILE: DPRINTF(("(private enhanced metafile)")); break;
	  }
	  DPRINTF(("\n"));
	  if(fmtRec->ptd) {
	    char *base = (char*) (fmtRec->ptd);
	    DPRINTF(("\tDriver name: %s\n",
		     base+(fmtRec->ptd->tdDriverNameOffset)));
	    DPRINTF(("\tDevice name: %s\n",
		     base+(fmtRec->ptd->tdDeviceNameOffset)));
	    DPRINTF(("\tPort name: %s\n",
		     base+(fmtRec->ptd->tdPortNameOffset)));
	  }
	  DPRINTF(("\tdwAspect: %d ",fmtRec->dwAspect));
	  if(fmtRec->dwAspect & DVASPECT_CONTENT) DPRINTF(("(content)")); 
	  if(fmtRec->dwAspect & DVASPECT_THUMBNAIL) DPRINTF(("(thumbnail)")); 
	  if(fmtRec->dwAspect & DVASPECT_ICON) DPRINTF(("(icon)")); 
	  if(fmtRec->dwAspect & DVASPECT_DOCPRINT) DPRINTF(("(docprint)")); 
	  }
	  DPRINTF(("\n"));

	  DPRINTF(("\tTYMED: %d ", fmtRec->tymed));
	  if(fmtRec->tymed & TYMED_HGLOBAL) DPRINTF(("(HGLOBAL)"));
	  if(fmtRec->tymed & TYMED_FILE) DPRINTF(("(FILE)"));
	  if(fmtRec->tymed & TYMED_ISTREAM) DPRINTF(("(IStream)"));
	  if(fmtRec->tymed & TYMED_ISTORAGE) DPRINTF(("(IStorage)"));
	  if(fmtRec->tymed & TYMED_GDI) DPRINTF(("(GDI)"));
	  if(fmtRec->tymed & TYMED_MFPICT) DPRINTF(("(MFPICT)"));
	  if(fmtRec->tymed & TYMED_ENHMF) DPRINTF(("(ENHMF)"));
	  DPRINTF(("\n"));
      } while(hRes == S_OK);
      if(FAILED(hRes)) {
	DPRINTF(("Next() failed (errCode = %x)\n"));
      }
      hRes = fmt->lpVtbl->Release(fmt);
    } else {
      DPRINTF(("EnumFormatEtc failed (errCode = %x)\n", hRes));
    }
  }
#endif
  fmtetc.cfFormat = 0;
  fmtetc.ptd = NULL;
  fmtetc.lindex = -1;
  fmtetc.dwAspect = DVASPECT_CONTENT;

  DPRINTF(("Looking for file...\n"));
  fmtetc.cfFormat = CF_HDROP;
  fmtetc.tymed = TYMED_HGLOBAL;
  hRes = ido->lpVtbl->QueryGetData(ido, &fmtetc);
  if(hRes == S_OK) {
    DPRINTF(("That works.\n"));
    *effect = DROPEFFECT_COPY; /* that's what we want */
    signalDropEnter(pt);
    return S_OK;
  }

  DPRINTF(("Looking for HDIB...\n"));
  fmtetc.cfFormat = CF_DIB;
  fmtetc.tymed = TYMED_HGLOBAL;
  hRes = ido->lpVtbl->QueryGetData(ido, &fmtetc);
  if(hRes == S_OK) {
    DPRINTF(("That works.\n"));
    *effect = DROPEFFECT_COPY; /* that's what we want */
    signalDropEnter(pt);
    return S_OK;
  }

  DPRINTF(("Looking for Bitmap...\n"));
  fmtetc.cfFormat = CF_BITMAP;
  fmtetc.tymed = TYMED_GDI;
  hRes = ido->lpVtbl->QueryGetData(ido, &fmtetc);
  if(hRes == S_OK) {
    DPRINTF(("That works.\n"));
    *effect = DROPEFFECT_COPY; /* that's what we want */
    signalDropEnter(pt);
    return S_OK;
  }

  DPRINTF(("Looking for ENHMF...\n"));
  fmtetc.cfFormat = CF_ENHMETAFILE;
  fmtetc.tymed = TYMED_ENHMF;
  hRes = ido->lpVtbl->QueryGetData(ido, &fmtetc);
  if(hRes == S_OK) {
    DPRINTF(("That works.\n"));
    *effect = DROPEFFECT_COPY; /* that's what we want */
    signalDropEnter(pt);
    return S_OK;
  }


  DPRINTF(("Not found...\n"));
  *effect = DROPEFFECT_NONE;
  return S_FALSE;
}

STDMETHODIMP DropTarget_DragOver(DropTarget *dt, 
			      DWORD keyState, 
			      POINTL pt, 
			      DWORD *effect) {
  DPRINTF(("DropTarget_DragOver\n"));
  *effect = DROPEFFECT_COPY; /* that's what we want */
  {
    POINT winPt;
    winPt.x = pt.x;
    winPt.y = pt.y;
    ScreenToClient(stWindow, &winPt);
    recordDragDropEvent(stWindow, SQDragMove, winPt.x, winPt.y, 0);
  }
  return S_OK;
}

STDMETHODIMP DropTarget_DragLeave(DropTarget *dt) {
  DPRINTF(("DropTarget_DragLeave\n"));
  recordDragDropEvent(stWindow, SQDragLeave, 0, 0, 0);
  return S_OK;
}

void signalDrop(POINTL pt)
{
  POINT winPt;
  winPt.x = pt.x;
  winPt.y = pt.y;
  ScreenToClient(stWindow, &winPt);
  recordDragDropEvent(stWindow, SQDragDrop, winPt.x, winPt.y, numDropFiles);
}

STDMETHODIMP DropTarget_Drop(DropTarget *dt,
			     IDataObject *ido,
			     DWORD keyState,
			     POINTL pt,
			     DWORD *effect) {
  STGMEDIUM medium;
  FORMATETC fmtetc;
  HRESULT hRes;

  freeDropFiles();

  DPRINTF(("DropTarget_Drop\n"));
  fmtetc.cfFormat = CF_HDROP;
  fmtetc.ptd = NULL;
  fmtetc.lindex = -1;
  fmtetc.dwAspect = DVASPECT_CONTENT;
  fmtetc.tymed = TYMED_HGLOBAL;
  DPRINTF(("Looking for file...\n"));

  hRes = ido->lpVtbl->GetData(ido, &fmtetc, &medium);
  if(hRes == S_OK) {
    HGLOBAL hDrop = medium.hGlobal;
    DWORD i;

    DPRINTF(("Success\n"));
    numDropFiles = DragQueryFile(hDrop, -1, NULL, 0);
    dropFiles = calloc(numDropFiles, sizeof(char*));
    for(i=0; i<numDropFiles; i++) {
      WCHAR *tmpPath;
      int len;
      len = DragQueryFileW(hDrop, i, NULL, 0);
      tmpPath = calloc(len+1, sizeof(WCHAR));
      DragQueryFileW(hDrop, i, tmpPath, len+1);
      len = WideCharToMultiByte(CP_UTF8, 0, tmpPath, -1, NULL, 0,NULL,NULL);
      dropFiles[i] = malloc(len);
      WideCharToMultiByte(CP_UTF8,0,tmpPath,-1,dropFiles[i],len,NULL,NULL);
      free(tmpPath);
      DPRINTF(("File: %s\n", dropFiles[i]));
    }
    DragFinish(hDrop);
    signalDrop(pt);
    if(medium.pUnkForRelease == NULL) {
      GlobalFree(hDrop);
    } else {
      medium.pUnkForRelease->lpVtbl->Release(medium.pUnkForRelease);
    }
    return S_OK;
  }

  if(FAILED(hRes)) {
    DPRINTF(("GetData failed (errCode = %x)\n", hRes));
  }

  fmtetc.cfFormat = CF_DIB;
  fmtetc.ptd = NULL;
  fmtetc.lindex = -1;
  fmtetc.dwAspect = DVASPECT_CONTENT;
  fmtetc.tymed = TYMED_HGLOBAL;
  DPRINTF(("Looking for HDIB...\n"));

  hRes = ido->lpVtbl->GetData(ido, &fmtetc, &medium);
  if(hRes == S_OK) {
    TCHAR tmpName[MAX_PATH+1];
    HANDLE hDib = medium.hGlobal;

    DPRINTF(("Success\n"));

    GetTempPath(MAX_PATH,tmpName);
    strcat(tmpName,"$$squeak$$.bmp");
    if(WriteDIB(tmpName, hDib)) {
      numDropFiles = 1;
      dropFiles = calloc(1, sizeof(void*));
      dropFiles[0] = _strdup(tmpName);
    }
    if(medium.pUnkForRelease == NULL) {
      GlobalFree(hDib);
    } else {
      medium.pUnkForRelease->lpVtbl->Release(medium.pUnkForRelease);
    }
    signalDrop(pt);
    return S_OK;
  }

  if(FAILED(hRes)) {
    DPRINTF(("GetData failed (errCode = %x)\n", hRes));
  }

  fmtetc.cfFormat = CF_BITMAP;
  fmtetc.ptd = NULL;
  fmtetc.lindex = -1;
  fmtetc.dwAspect = DVASPECT_CONTENT;
  fmtetc.tymed = TYMED_HGLOBAL;
  DPRINTF(("Looking for bitmap...\n"));

  hRes = ido->lpVtbl->GetData(ido, &fmtetc, &medium);
  if(hRes == S_OK) {
    TCHAR tmpName[MAX_PATH+1];
    HANDLE hDib;
    HBITMAP hBM = medium.hBitmap;

    DPRINTF(("Success\n"));

    GetTempPath(MAX_PATH,tmpName);
    strcat(tmpName,"$$squeak$$.bmp");
    hDib = DibFromBitmap(hBM, BI_RGB, 0, NULL);
    if(hDib) {
      if(WriteDIB(tmpName, hDib)) {
	numDropFiles = 1;
	dropFiles = calloc(1, sizeof(void*));
	dropFiles[0] = _strdup(tmpName);
      }
      DeleteObject(hDib);
    }
    if(medium.pUnkForRelease == NULL) {
      DeleteObject(hBM);
    } else {
      medium.pUnkForRelease->lpVtbl->Release(medium.pUnkForRelease);
    }
    signalDrop(pt);
    return S_OK;
  }
  if(FAILED(hRes)) {
    DPRINTF(("GetData failed (errCode = %x)\n", hRes));
  }

  fmtetc.cfFormat = CF_ENHMETAFILE;
  fmtetc.ptd = NULL;
  fmtetc.lindex = -1;
  fmtetc.dwAspect = DVASPECT_CONTENT;
  fmtetc.tymed = TYMED_ENHMF;
  DPRINTF(("Looking for ENHMF...\n"));

  hRes = ido->lpVtbl->GetData(ido, &fmtetc, &medium);
  if(hRes == S_OK) {
    TCHAR tmpName[MAX_PATH+1];
    HANDLE hMF = medium.hGlobal;
    HANDLE hDib;
    BITMAPINFO bmi;
    ENHMETAHEADER header;

    DPRINTF(("Success\n"));

    if(GetEnhMetaFileHeader(hMF, sizeof(header), &header) == 0) {
      DPRINTF(("GetEnhMetaFileHeader failed\n"));
    }
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 24;
    bmi.bmiHeader.biCompression = BI_RGB;
    bmi.bmiHeader.biWidth = header.rclBounds.right - header.rclBounds.left;
    bmi.bmiHeader.biHeight = header.rclBounds.bottom - header.rclBounds.top;
    DPRINTF(("w=%d\nh=%d\n", bmi.bmiHeader.biWidth, bmi.bmiHeader.biHeight));
    {
      HDC hDC, mDC;
      HANDLE old, hBM;
      RECT rect;

      hDC = GetDC(stWindow);
      if(!hDC) DPRINTF(("GetDC() failed\n"));
      //      hDib = CreateDIBitmap(hDC, &bmi, 0, NULL, &bmi, DIB_RGB_COLORS);
      hBM = CreateDIBSection(hDC, &bmi, DIB_RGB_COLORS, NULL, NULL, 0);
      if(!hBM) DPRINTF(("CreateDIBSection() failed\n"));
      mDC = CreateCompatibleDC(hDC);
      if(!mDC) DPRINTF(("CreateCompatibleDC() failed\n"));
      old = SelectObject(mDC, hBM);
      rect.left = rect.top = 0;
      rect.right = bmi.bmiHeader.biWidth;
      rect.bottom = bmi.bmiHeader.biHeight;
      if(!PlayEnhMetaFile(mDC, hMF, &rect))
	DPRINTF(("PlayEnhMetaFile() failed\n"));
      SelectObject(mDC, old);
      DeleteDC(mDC);
      ReleaseDC(stWindow, hDC);
      hDib = DibFromBitmap(hBM, BI_RGB, 0, NULL);
      DeleteObject(hBM);
    }

    GetTempPath(MAX_PATH,tmpName);
    strcat(tmpName,"$$squeak$$.bmp");
    if(WriteDIB(tmpName, hDib)) {
      numDropFiles = 1;
      dropFiles = calloc(1, sizeof(void*));
      dropFiles[0] = _strdup(tmpName);
    }
    GlobalFree(hDib);
    if(medium.pUnkForRelease == NULL) {
      DeleteObject(hMF);
    } else {
      medium.pUnkForRelease->lpVtbl->Release(medium.pUnkForRelease);
    }
    signalDrop(pt);
    return S_OK;
  }

  if(FAILED(hRes)) {
    DPRINTF(("GetData failed (errCode = %x)\n", hRes));
  }


  return S_OK;
}

static void *vtDropTarget[] = {
  DropTarget_QueryInterface,
  DropTarget_AddRef,
  DropTarget_Release,
  DropTarget_DragEnter,
  DropTarget_DragOver,
  DropTarget_DragLeave,
  DropTarget_Drop
};

static int isInitialized = 0;

void SetupDragAndDrop(void) {
  HRESULT hRes;
#if 0
  return;
#endif
  if(!isInitialized) {
    stDropTarget.vtbl = vtDropTarget;
    stDropTarget.ref = 0;
    isInitialized = 1;
  }
  hRes = RegisterDragDrop(stWindow, (LPDROPTARGET)&stDropTarget);
  if(hRes == S_OK) {
    DPRINTF(("Registered drop target\n"));
  } else {
    DPRINTF(("Drop registration failed (errCode: %x)\n", hRes));
  }
}

void ShutdownDragAndDrop(void) {
  if(isInitialized) {
    RevokeDragDrop(stWindow);
    isInitialized = 0;
  }
}

/***************************************************************************/
/***************************************************************************/
/* Squeak part of drop support                                             */
/***************************************************************************/
/***************************************************************************/

/* Pretend this is a drag and drop of the given file */
int dropLaunchFile(char *fileName) {
  freeDropFiles();

  numDropFiles = 1;
  dropFiles = calloc(1, sizeof(void*));
  dropFiles[0] = _strdup(fileName);

  recordDragDropEvent(stWindow, SQDragDrop, 0, 0, numDropFiles);
  return 1;
}

int dropInit(void) {
  SetupDragAndDrop();
  return 1;
}

int dropShutdown(void) {
  freeDropFiles();
  ShutdownDragAndDrop();
  return 1;
}

char *dropRequestFileName(int dropIndex) {
  DPRINTF(("dropRequestFileName(%d)\n", dropIndex));
  if(dropIndex < 1 || dropIndex > numDropFiles) return NULL;
  return dropFiles[dropIndex-1];
}

sqInt dropRequestFileHandle(sqInt dropIndex) {
  sqInt fileHandle;
  int wasBrowserMode;
  char *dropName = dropRequestFileName(dropIndex);
  if(!dropName)
    return interpreterProxy->nilObject();
  fileHandle = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), fileRecordSize());
  wasBrowserMode = fBrowserMode;
  fBrowserMode = false;
  sqFileOpen(fileValueOf(fileHandle),dropName, strlen(dropName), 0);
  fBrowserMode = wasBrowserMode;
  return fileHandle;
}
