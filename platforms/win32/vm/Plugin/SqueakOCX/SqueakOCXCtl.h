#if !defined(AFX_SQUEAKOCXCTL_H__A7D71CF1_013A_11D3_A367_AD13D006470E__INCLUDED_)
#define AFX_SQUEAKOCXCTL_H__A7D71CF1_013A_11D3_A367_AD13D006470E__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

// SqueakOCXCtl.h : Declaration of the CSqueakOCXCtrl ActiveX Control class.

/////////////////////////////////////////////////////////////////////////////
// CSqueakOCXCtrl : See SqueakOCXCtl.cpp for implementation.

class CSqueakOCXCtrl : public COleControl
{
	DECLARE_DYNCREATE(CSqueakOCXCtrl)

protected:
	SqueakPlugin *squeak;

// Constructor
public:
	CSqueakOCXCtrl();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CSqueakOCXCtrl)
	public:
	virtual void OnDraw(CDC* pdc, const CRect& rcBounds, const CRect& rcInvalid);
	virtual void DoPropExchange(CPropExchange* pPX);
	virtual void OnResetState();
	//}}AFX_VIRTUAL

// Implementation
protected:
	~CSqueakOCXCtrl();

	DECLARE_OLECREATE_EX(CSqueakOCXCtrl)    // Class factory and guid
	DECLARE_OLETYPELIB(CSqueakOCXCtrl)      // GetTypeInfo
	DECLARE_PROPPAGEIDS(CSqueakOCXCtrl)     // Property page IDs
	DECLARE_OLECTLTYPE(CSqueakOCXCtrl)		// Type name and misc status

// Message maps
	//{{AFX_MSG(CSqueakOCXCtrl)
	afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
	afx_msg void OnSize(UINT nType, int cx, int cy);
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()

// Dispatch maps
	//{{AFX_DISPATCH(CSqueakOCXCtrl)
		// NOTE - ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_DISPATCH
	DECLARE_DISPATCH_MAP()

// Event maps
	//{{AFX_EVENT(CSqueakOCXCtrl)
		// NOTE - ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_EVENT
	DECLARE_EVENT_MAP()

// Dispatch and event IDs
public:
	IWebBrowserApp* GetBrowser(void);
	enum {
	//{{AFX_DISP_ID(CSqueakOCXCtrl)
		// NOTE: ClassWizard will add and remove enumeration elements here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_DISP_ID
	};
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_SQUEAKOCXCTL_H__A7D71CF1_013A_11D3_A367_AD13D006470E__INCLUDED)
