// SqueakOCXPpg.cpp : Implementation of the CSqueakOCXPropPage property page class.

#include "stdafx.h"
#include "SqueakOCX.h"
#include "SqueakOCXPpg.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif


IMPLEMENT_DYNCREATE(CSqueakOCXPropPage, COlePropertyPage)


/////////////////////////////////////////////////////////////////////////////
// Message map

BEGIN_MESSAGE_MAP(CSqueakOCXPropPage, COlePropertyPage)
	//{{AFX_MSG_MAP(CSqueakOCXPropPage)
	// NOTE - ClassWizard will add and remove message map entries
	//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// Initialize class factory and guid

IMPLEMENT_OLECREATE_EX(CSqueakOCXPropPage, "SQUEAKOCX.SqueakOCXPropPage.1",
	0xa7d71ce5, 0x13a, 0x11d3, 0xa3, 0x67, 0xad, 0x13, 0xd0, 0x6, 0x47, 0xe)


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXPropPage::CSqueakOCXPropPageFactory::UpdateRegistry -
// Adds or removes system registry entries for CSqueakOCXPropPage

BOOL CSqueakOCXPropPage::CSqueakOCXPropPageFactory::UpdateRegistry(BOOL bRegister)
{
	if (bRegister)
		return AfxOleRegisterPropertyPageClass(AfxGetInstanceHandle(),
			m_clsid, IDS_SQUEAKOCX_PPG);
	else
		return AfxOleUnregisterClass(m_clsid, NULL);
}


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXPropPage::CSqueakOCXPropPage - Constructor

CSqueakOCXPropPage::CSqueakOCXPropPage() :
	COlePropertyPage(IDD, IDS_SQUEAKOCX_PPG_CAPTION)
{
	//{{AFX_DATA_INIT(CSqueakOCXPropPage)
	// NOTE: ClassWizard will add member initialization here
	//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_DATA_INIT
}


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXPropPage::DoDataExchange - Moves data between page and properties

void CSqueakOCXPropPage::DoDataExchange(CDataExchange* pDX)
{
	//{{AFX_DATA_MAP(CSqueakOCXPropPage)
	// NOTE: ClassWizard will add DDP, DDX, and DDV calls here
	//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_DATA_MAP
	DDP_PostProcessing(pDX);
}


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXPropPage message handlers
