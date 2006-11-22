/* this file contains the actual definitions of */
/* the IIDs and CLSIDs */

/* link this file in with the server and any clients */


/* File created by MIDL compiler version 5.01.0164 */
/* at Sat Apr 20 16:54:56 2002
 */
/* Compiler settings for C:\Dokumente und Einstellungen\andreas\Eigene Dateien\Bander\Home\andreasr\dev\Squeak\3.0\src\win32\Plugin\SqueakOCX2\SqueakOCX2.idl:
    Oicf (OptLev=i2), W1, Zp8, env=Win32, ms_ext, c_ext
    error checks: allocation ref bounds_check enum stub_data 
*/
//@@MIDL_FILE_HEADING(  )
#ifdef __cplusplus
extern "C"{
#endif 


#ifndef __IID_DEFINED__
#define __IID_DEFINED__

typedef struct _IID
{
    unsigned long x;
    unsigned short s1;
    unsigned short s2;
    unsigned char  c[8];
} IID;

#endif // __IID_DEFINED__

#ifndef CLSID_DEFINED
#define CLSID_DEFINED
typedef IID CLSID;
#endif // CLSID_DEFINED

const IID IID_ISqueakOCX = {0x24A4DFFA,0x3C16,0x487D,{0xBF,0x4F,0x0A,0x63,0x24,0x71,0x76,0x19}};


const IID LIBID_SQUEAKOCX2Lib = {0x9163DD61,0x8348,0x4660,{0x91,0x7B,0x94,0x30,0x0F,0xAE,0x69,0x79}};


const CLSID CLSID_SqueakOCX = {0x2BE9C39E,0x8386,0x4435,{0xB3,0x37,0xFC,0xDA,0xD8,0xEA,0xB0,0x06}};


#ifdef __cplusplus
}
#endif

