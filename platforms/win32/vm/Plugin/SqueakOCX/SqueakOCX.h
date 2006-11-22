#if !defined(AFX_SQUEAKOCX_H__A7D71CEA_013A_11D3_A367_AD13D006470E__INCLUDED_)
#define AFX_SQUEAKOCX_H__A7D71CEA_013A_11D3_A367_AD13D006470E__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

// SqueakOCX.h : main header file for SQUEAKOCX.DLL

#if !defined( __AFXCTL_H__ )
	#error include 'afxctl.h' before including this file
#endif

#include "resource.h"       // main symbols

/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXApp : See SqueakOCX.cpp for implementation.

class CSqueakOCXApp : public COleControlModule
{
public:
	BOOL InitInstance();
	int ExitInstance();
};

extern const GUID CDECL _tlid;
extern const WORD _wVerMajor;
extern const WORD _wVerMinor;

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_SQUEAKOCX_H__A7D71CEA_013A_11D3_A367_AD13D006470E__INCLUDED)
