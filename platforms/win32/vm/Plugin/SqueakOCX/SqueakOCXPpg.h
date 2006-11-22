#if !defined(AFX_SQUEAKOCXPPG_H__A7D71CF3_013A_11D3_A367_AD13D006470E__INCLUDED_)
#define AFX_SQUEAKOCXPPG_H__A7D71CF3_013A_11D3_A367_AD13D006470E__INCLUDED_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

// SqueakOCXPpg.h : Declaration of the CSqueakOCXPropPage property page class.

////////////////////////////////////////////////////////////////////////////
// CSqueakOCXPropPage : See SqueakOCXPpg.cpp.cpp for implementation.

class CSqueakOCXPropPage : public COlePropertyPage
{
	DECLARE_DYNCREATE(CSqueakOCXPropPage)
	DECLARE_OLECREATE_EX(CSqueakOCXPropPage)

// Constructor
public:
	CSqueakOCXPropPage();

// Dialog Data
	//{{AFX_DATA(CSqueakOCXPropPage)
	enum { IDD = IDD_PROPPAGE_SQUEAKOCX };
		// NOTE - ClassWizard will add data members here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_DATA

// Implementation
protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

// Message maps
protected:
	//{{AFX_MSG(CSqueakOCXPropPage)
		// NOTE - ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()

};

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_SQUEAKOCXPPG_H__A7D71CF3_013A_11D3_A367_AD13D006470E__INCLUDED)
