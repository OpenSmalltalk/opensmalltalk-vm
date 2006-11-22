// SqueakOCX.h : Declaration of the CSqueakOCX

#ifndef __SQUEAKOCX_H_
#define __SQUEAKOCX_H_

#include "resource.h"       // main symbols
#include <atlctl.h>
#include "../sqWin32Plugin.h"


/////////////////////////////////////////////////////////////////////////////
// CSqueakOCX
class ATL_NO_VTABLE CSqueakOCX : 
	public CComObjectRootEx<CComSingleThreadModel>,
	public IDispatchImpl<ISqueakOCX, &IID_ISqueakOCX, &LIBID_SQUEAKOCX2Lib>,
	public CComControl<CSqueakOCX>,
	public IPersistStreamInitImpl<CSqueakOCX>,
	public IOleControlImpl<CSqueakOCX>,
	public IOleObjectImpl<CSqueakOCX>,
	public IOleInPlaceActiveObjectImpl<CSqueakOCX>,
	public IViewObjectExImpl<CSqueakOCX>,
    public IPersistPropertyBagImpl<CSqueakOCX>,
	public IOleInPlaceObjectWindowlessImpl<CSqueakOCX>,
	public CComCoClass<CSqueakOCX, &CLSID_SqueakOCX>
{
public:
DECLARE_REGISTRY_RESOURCEID(IDR_SQUEAKOCX)

DECLARE_PROTECT_FINAL_CONSTRUCT()

BEGIN_COM_MAP(CSqueakOCX)
	COM_INTERFACE_ENTRY(ISqueakOCX)
	COM_INTERFACE_ENTRY(IDispatch)
	COM_INTERFACE_ENTRY(IViewObjectEx)
	COM_INTERFACE_ENTRY(IViewObject2)
	COM_INTERFACE_ENTRY(IViewObject)
	COM_INTERFACE_ENTRY(IOleInPlaceObjectWindowless)
	COM_INTERFACE_ENTRY(IOleInPlaceObject)
	COM_INTERFACE_ENTRY2(IOleWindow, IOleInPlaceObjectWindowless)
	COM_INTERFACE_ENTRY(IOleInPlaceActiveObject)
	COM_INTERFACE_ENTRY(IOleControl)
	COM_INTERFACE_ENTRY(IOleObject)
	COM_INTERFACE_ENTRY(IPersistStreamInit)
	COM_INTERFACE_ENTRY2(IPersist, IPersistStreamInit)
    COM_INTERFACE_ENTRY(IPersistPropertyBag)
END_COM_MAP()

BEGIN_PROP_MAP(CSqueakOCX)
	PROP_DATA_ENTRY("_cx", m_sizeExtent.cx, VT_UI4)
	PROP_DATA_ENTRY("_cy", m_sizeExtent.cy, VT_UI4)
	// Example entries
	// PROP_ENTRY("Property Description", dispid, clsid)
	// PROP_PAGE(CLSID_StockColorPage)
END_PROP_MAP()

BEGIN_MSG_MAP(CSqueakOCX)
	CHAIN_MSG_MAP(CComControl<CSqueakOCX>)
	DEFAULT_REFLECTION_HANDLER()
	MESSAGE_HANDLER(WM_CREATE, OnCreate)
	MESSAGE_HANDLER(WM_SIZE, OnSize)
END_MSG_MAP()
// Handler prototypes:
//  LRESULT MessageHandler(UINT uMsg, WPARAM wParam, LPARAM lParam, BOOL& bHandled);
//  LRESULT CommandHandler(WORD wNotifyCode, WORD wID, HWND hWndCtl, BOOL& bHandled);
//  LRESULT NotifyHandler(int idCtrl, LPNMHDR pnmh, BOOL& bHandled);



// IViewObjectEx
	DECLARE_VIEW_STATUS(0)

// IPersistPropertyBag override
	STDMETHOD(Load)(LPPROPERTYBAG pPropBag, LPERRORLOG pErrorLog);

// ISqueakOCX
public:
	char *pluginsPage;
	SqueakPlugin *squeak;

	CSqueakOCX()
	{
		pluginsPage = NULL;
		m_bWindowOnly = TRUE;
		SqueakPluginInitialize();
		SqueakPluginSetIEMode();
		squeak = SqueakPluginNew(_Module.GetModuleInstance(), (void*)this);
	}

	~CSqueakOCX()
	{
		if(squeak) SqueakPluginDestroy(squeak);
	}

	void GetURL(char *url, char *target, int id);
	void PostURL(char *url, char *target, char* postData, int id);
	void GoToPluginsPage(void);

	HRESULT OnDraw(ATL_DRAWINFO& di)
	{
		RECT& rc = *(RECT*)di.prcBounds;
		Rectangle(di.hdcDraw, rc.left, rc.top, rc.right, rc.bottom);

		SetTextAlign(di.hdcDraw, TA_CENTER|TA_BASELINE);
		LPCTSTR pszText = _T("Squeak Plugin <inactive>");
		TextOut(di.hdcDraw, 
			(rc.left + rc.right) / 2, 
			(rc.top + rc.bottom) / 2, 
			pszText, 
			lstrlen(pszText));

		return S_OK;
	}
	LRESULT OnCreate(UINT uMsg, WPARAM wParam, LPARAM lParam, BOOL& bHandled)
	{
		if(squeak) {
			if(!SqueakPluginRun(squeak, m_hWndCD, 0)) {
				GoToPluginsPage();
			}
		}
		return 0;
	}
	LRESULT OnSize(UINT uMsg, WPARAM wParam, LPARAM lParam, BOOL& bHandled)
	{
		if(squeak) SqueakPluginResize(squeak, m_hWndCD);
		return 0;
	}
};

#endif //__SQUEAKOCX_H_
