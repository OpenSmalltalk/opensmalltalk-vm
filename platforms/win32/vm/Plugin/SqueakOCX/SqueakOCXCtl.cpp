// SqueakOCXCtl.cpp : Implementation of the CSqueakOCXCtrl ActiveX Control class.

#include "stdafx.h"
#include "SqueakOCX.h"
#include "../sqWin32Plugin.h"
#include "SqueakOCXCtl.h"
#include "SqueakOCXPpg.h"


#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif


IMPLEMENT_DYNCREATE(CSqueakOCXCtrl, COleControl)


/////////////////////////////////////////////////////////////////////////////
// Message map

BEGIN_MESSAGE_MAP(CSqueakOCXCtrl, COleControl)
	//{{AFX_MSG_MAP(CSqueakOCXCtrl)
	ON_WM_CREATE()
	ON_WM_SIZE()
	//}}AFX_MSG_MAP
	ON_OLEVERB(AFX_IDS_VERB_PROPERTIES, OnProperties)
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// Dispatch map

BEGIN_DISPATCH_MAP(CSqueakOCXCtrl, COleControl)
	//{{AFX_DISPATCH_MAP(CSqueakOCXCtrl)
	// NOTE - ClassWizard will add and remove dispatch map entries
	//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_DISPATCH_MAP
END_DISPATCH_MAP()


/////////////////////////////////////////////////////////////////////////////
// Event map

BEGIN_EVENT_MAP(CSqueakOCXCtrl, COleControl)
	//{{AFX_EVENT_MAP(CSqueakOCXCtrl)
	// NOTE - ClassWizard will add and remove event map entries
	//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_EVENT_MAP
END_EVENT_MAP()


/////////////////////////////////////////////////////////////////////////////
// Property pages

// TODO: Add more property pages as needed.  Remember to increase the count!
BEGIN_PROPPAGEIDS(CSqueakOCXCtrl, 1)
	PROPPAGEID(CSqueakOCXPropPage::guid)
END_PROPPAGEIDS(CSqueakOCXCtrl)


/////////////////////////////////////////////////////////////////////////////
// Initialize class factory and guid

IMPLEMENT_OLECREATE_EX(CSqueakOCXCtrl, "SQUEAKOCX.SqueakOCXCtrl.1",
	0xf164125, 0x40, 0x11d3, 0xa3, 0x67, 0x85, 0xfd, 0xba, 0x5d, 0x2, 0xda)


/////////////////////////////////////////////////////////////////////////////
// Type library ID and version

IMPLEMENT_OLETYPELIB(CSqueakOCXCtrl, _tlid, _wVerMajor, _wVerMinor)


/////////////////////////////////////////////////////////////////////////////
// Interface IDs

const IID BASED_CODE IID_DSqueakOCX =
		{ 0xa7d71ce3, 0x13a, 0x11d3, { 0xa3, 0x67, 0xad, 0x13, 0xd0, 0x6, 0x47, 0xe } };
const IID BASED_CODE IID_DSqueakOCXEvents =
		{ 0xa7d71ce4, 0x13a, 0x11d3, { 0xa3, 0x67, 0xad, 0x13, 0xd0, 0x6, 0x47, 0xe } };


/////////////////////////////////////////////////////////////////////////////
// Control type information

static const DWORD BASED_CODE _dwSqueakOCXOleMisc =
	OLEMISC_ACTIVATEWHENVISIBLE |
	OLEMISC_SETCLIENTSITEFIRST |
	OLEMISC_INSIDEOUT |
	OLEMISC_CANTLINKINSIDE |
	OLEMISC_RECOMPOSEONRESIZE;

IMPLEMENT_OLECTLTYPE(CSqueakOCXCtrl, IDS_SQUEAKOCX, _dwSqueakOCXOleMisc)


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXCtrl::CSqueakOCXCtrlFactory::UpdateRegistry -
// Adds or removes system registry entries for CSqueakOCXCtrl

BOOL CSqueakOCXCtrl::CSqueakOCXCtrlFactory::UpdateRegistry(BOOL bRegister)
{
	// TODO: Verify that your control follows apartment-model threading rules.
	// Refer to MFC TechNote 64 for more information.
	// If your control does not conform to the apartment-model rules, then
	// you must modify the code below, changing the 6th parameter from
	// afxRegApartmentThreading to 0.

	if (bRegister)
		return AfxOleRegisterControlClass(
			AfxGetInstanceHandle(),
			m_clsid,
			m_lpszProgID,
			IDS_SQUEAKOCX,
			IDB_SQUEAKOCX,
			afxRegApartmentThreading,
			_dwSqueakOCXOleMisc,
			_tlid,
			_wVerMajor,
			_wVerMinor);
	else
		return AfxOleUnregisterClass(m_clsid, m_lpszProgID);
}


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXCtrl::CSqueakOCXCtrl - Constructor

CSqueakOCXCtrl::CSqueakOCXCtrl()
{
	InitializeIIDs(&IID_DSqueakOCX, &IID_DSqueakOCXEvents);

	// TODO: Initialize your control's instance data here.
	SqueakPluginInitialize();
	squeak = SqueakPluginNew(AfxGetInstanceHandle(), NULL);
}


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXCtrl::~CSqueakOCXCtrl - Destructor

CSqueakOCXCtrl::~CSqueakOCXCtrl()
{
	// TODO: Cleanup your control's instance data here.
	SqueakPluginDestroy(squeak);
}


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXCtrl::OnDraw - Drawing function

void CSqueakOCXCtrl::OnDraw(
			CDC* pdc, const CRect& rcBounds, const CRect& rcInvalid)
{
	/* Don't draw anything here */
}


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXCtrl::DoPropExchange - Persistence support

void CSqueakOCXCtrl::DoPropExchange(CPropExchange* pPX)
{
	CString temp;
	ExchangeVersion(pPX, MAKELONG(_wVerMinor, _wVerMajor));
	COleControl::DoPropExchange(pPX);
	// TODO: Call PX_ functions for each persistent custom property.
	
	PX_String(pPX, _T("imageName"), _T(temp), _T(""));
	SqueakPluginSetImage(squeak,(char*)(LPCTSTR)temp);
	SqueakPluginAddParam(squeak,"imageName", (char*)(LPCTSTR)temp);
	
	PX_String(pPX, _T("vmName"), _T(temp), _T(""));
	SqueakPluginSetVM(squeak,(char*)(LPCTSTR)temp);
	SqueakPluginAddParam(squeak,"vmName", (char*)(LPCTSTR)temp);

	PX_String(pPX, _T("win32Params"), _T(temp), _T(""));
	SqueakPluginSetVMParams(squeak,(char*)(LPCTSTR)temp);
	SqueakPluginAddParam(squeak,"win32Params", (char*)(LPCTSTR)temp);

	PX_String(pPX, _T("src"), _T(temp), _T(""));
	SqueakPluginAddParam(squeak,"src", (char*)(LPCTSTR)temp);

	PX_String(pPX, _T("update"), _T(temp), _T(""));
	SqueakPluginAddParam(squeak,"update", (char*)(LPCTSTR)temp);
	
	PX_String(pPX, _T("win32"), _T(temp), _T(""));
	SqueakPluginAddParam(squeak,"update", (char*)(LPCTSTR)temp);
	
	PX_String(pPX, _T("loader_url"), _T(temp), _T(""));
	SqueakPluginAddParam(squeak,"loader_url", (char*)(LPCTSTR)temp);
	
	PX_String(pPX, _T("pluginspage"), _T(temp), _T(""));
	SqueakPluginAddParam(squeak,"pluginspage", (char*)(LPCTSTR)temp);

	if(m_hWnd) SqueakPluginRun(squeak, m_hWnd, 1);
}


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXCtrl::OnResetState - Reset control to default state

void CSqueakOCXCtrl::OnResetState()
{
	COleControl::OnResetState();  // Resets defaults found in DoPropExchange

	// TODO: Reset any other control state here.
}


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXCtrl message handlers

int CSqueakOCXCtrl::OnCreate(LPCREATESTRUCT lpCreateStruct) 
{
	if (COleControl::OnCreate(lpCreateStruct) == -1)
		return -1;

	SqueakPluginRun(squeak, m_hWnd, 1);

	return 0;
}

void CSqueakOCXCtrl::OnSize(UINT nType, int cx, int cy) 
{
	COleControl::OnSize(nType, cx, cy);
	
	if(SqueakPluginActive(squeak))
		SqueakPluginResize(squeak,m_hWnd);
}


IWebBrowserApp* CSqueakOCXCtrl::GetBrowser()
{
	HRESULT hRes;
	LPOLECLIENTSITE clientSite;
	LPSERVICEPROVIDER sp;
	IWebBrowserApp *browser;

	clientSite = GetClientSite();
	if(!clientSite) return NULL;
	hRes = clientSite->QueryInterface(IID_IServiceProvider, (void**)&sp);
	if(FAILED(hRes)) return NULL;
	hRes = sp->QueryService(IID_IWebBrowserApp, &browser);
	if(FAILED(hRes)) return NULL;
	browser->AddRef();
	return browser;
}


void SqueakPluginRequestStream(void *instance, char *url, char *target, int id)
{
}

void SqueakPluginPostData(void *instance, char *url, char *target, char *data, int id)
{
}
