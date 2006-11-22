#ifndef __SQUEAK_CB_H
#define __SQUEAK_CB_H

#include "resource.h"       // main symbols
#include <atlctl.h>

class ATL_NO_VTABLE CSqueakStatusCallback :
	public CComObjectRootEx<CSqueakOCX::_ThreadModel::ThreadModelNoCS>,
	public IBindStatusCallback
{
public:

BEGIN_COM_MAP(CSqueakStatusCallback)
	COM_INTERFACE_ENTRY(IBindStatusCallback)
END_COM_MAP()

CSqueakStatusCallback() :
		m_spMoniker(NULL),
		m_spBindCtx(NULL),
		m_spBinding(NULL),
		m_spStream(NULL),
		m_pT(NULL),
		m_hPostData(NULL),
		done(0),
		localName(NULL)
	{
	}
	~CSqueakStatusCallback()
	{
		if(m_hPostData) GlobalFree(m_hPostData);
		ATLTRACE2(atlTraceControls,2,_T("~CBindStatusCallback\n"));
	}

	STDMETHOD(OnStartBinding)(DWORD dwReserved, IBinding *pBinding)
	{
		ATLTRACE2(atlTraceControls,2,_T("CBindStatusCallback::OnStartBinding\n"));
		m_spBinding = pBinding;
		return S_OK;
	}

	STDMETHOD(GetPriority)(LONG *pnPriority)
	{
		ATLTRACE2(atlTraceControls,2,_T("CBindStatusCallback::GetPriority"));
		HRESULT hr = S_OK;
		if (pnPriority)
			*pnPriority = THREAD_PRIORITY_NORMAL;
		else
			hr = E_INVALIDARG;
		return S_OK;
	}

	STDMETHOD(OnLowResource)(DWORD reserved)
	{
		ATLTRACE2(atlTraceControls,2,_T("CBindStatusCallback::OnLowResource"));
		return S_OK;
	}

	STDMETHOD(OnProgress)(ULONG ulProgress, ULONG ulProgressMax, ULONG ulStatusCode, LPCWSTR szStatusText)
	{
		ATLTRACE2(atlTraceControls,2,_T("CBindStatusCallback::OnProgress"));
		return S_OK;
	}

	STDMETHOD(OnStopBinding)(HRESULT hresult, LPCWSTR szError)
	{
		ATLTRACE2(atlTraceControls,2,_T("CBindStatusCallback::OnStopBinding\n"));
		if(SUCCEEDED(hresult)) {
			/* pass stream name back to plugin if it exists */
		} else {
			CoTaskMemFree(localName);
			localName = NULL;
		}
		m_spBinding.Release();
		m_spBindCtx.Release();
		m_spMoniker.Release();
		done = 1;
		return S_OK;
	}

	STDMETHOD(GetBindInfo)(DWORD *pgrfBINDF, BINDINFO *pbindInfo)
	{
		ATLTRACE2(atlTraceControls,2,_T("CBindStatusCallback::GetBindInfo\n"));

		if (pbindInfo==NULL || pbindInfo->cbSize==0 || pgrfBINDF==NULL)
			return E_INVALIDARG;

		*pgrfBINDF = BINDF_ASYNCHRONOUS | BINDF_ASYNCSTORAGE /* | BINDF_GETNEWESTVERSION */;
#if 0
		*pgrfBINDF = BINDF_ASYNCHRONOUS | BINDF_ASYNCSTORAGE |
			BINDF_GETNEWESTVERSION | BINDF_NOWRITECACHE;
#endif
		ULONG cbSize = pbindInfo->cbSize;		// remember incoming cbSize
		memset(pbindInfo, 0, cbSize);			// zero out structure
		pbindInfo->cbSize = cbSize;				// restore cbSize
		if (m_hPostData) {
			pbindInfo->dwBindVerb = BINDVERB_POST;
			pbindInfo->stgmedData.tymed = TYMED_HGLOBAL;
			pbindInfo->stgmedData.hGlobal = m_hPostData;
		} else {
			pbindInfo->dwBindVerb = BINDVERB_GET;
		}
		return S_OK;
	}

	STDMETHOD(OnDataAvailable)(DWORD grfBSCF, DWORD dwSize, FORMATETC *pformatetc, STGMEDIUM *pstgmed)
	{
		ATLTRACE2(atlTraceControls,2,_T("CBindStatusCallback::OnDataAvailable\n"));
		// Get the Stream passed
		if (BSCF_FIRSTDATANOTIFICATION & grfBSCF)
		{
			STATSTG stat;
			if (!m_spStream && pstgmed->tymed == TYMED_ISTREAM) {
				m_spStream = pstgmed->pstm;
				m_spStream->Stat(&stat, 0);
				localName = stat.pwcsName;
			}
		}
		if (BSCF_LASTDATANOTIFICATION & grfBSCF) {
			m_spStream.Release();
		}
		return S_OK;
	}

	STDMETHOD(OnObjectAvailable)(REFIID riid, IUnknown *punk)
	{
		ATLTRACE2(atlTraceControls,2,_T("CBindStatusCallback::OnObjectAvailable"));
		return S_OK;
	}

	LPWSTR _StartAsyncDownload(BSTR bstrURL, IUnknown* pUnkContainer, BOOL bRelative)
	{

		HRESULT hr = S_OK;
		AddRef();
		CComQIPtr<IServiceProvider, &IID_IServiceProvider> spServiceProvider(pUnkContainer);
		CComPtr<IBindHost>	spBindHost;
		if (spServiceProvider)
			spServiceProvider->QueryService(SID_IBindHost, IID_IBindHost, (void**)&spBindHost);

		if (spBindHost == NULL)
		{
			if (bRelative)
				return NULL;  // relative asked for, but no IBindHost

			hr = CreateURLMoniker(NULL, bstrURL, &m_spMoniker);
			if (SUCCEEDED(hr))
				hr = CreateBindCtx(0, &m_spBindCtx);

			if (SUCCEEDED(hr))
				hr = RegisterBindStatusCallback(m_spBindCtx, static_cast<IBindStatusCallback*>(this), 0, 0L);
			else
				m_spMoniker.Release();

			if (SUCCEEDED(hr)) {

				hr = m_spMoniker->BindToStorage(m_spBindCtx, 0, IID_IStream, (void**)&m_spStream);
			}
		}
		else
		{
			hr = CreateBindCtx(0, &m_spBindCtx);
			if (SUCCEEDED(hr))
				hr = RegisterBindStatusCallback(m_spBindCtx, static_cast<IBindStatusCallback*>(this), 0, 0L);

			if (SUCCEEDED(hr))
			{

				if (bRelative)
					hr = spBindHost->CreateMoniker(bstrURL, m_spBindCtx, &m_spMoniker, 0);
				else
					hr = CreateURLMoniker(NULL, bstrURL, &m_spMoniker);
			}

			if (SUCCEEDED(hr))
			{

				hr = spBindHost->MonikerBindToStorage(m_spMoniker, m_spBindCtx, static_cast<IBindStatusCallback*>(this), IID_IStream, (void**)&m_spStream);
				ATLTRACE2(atlTraceControls,2,_T("Bound"));
			}
		}
		if(hr == MK_S_ASYNCHRONOUS) {
			while(!done) {
		        MSG msg;
				if(PeekMessage(&msg, NULL, 0, 0, PM_NOREMOVE)) {
					GetMessage(&msg, NULL, 0, 0);
					DispatchMessage(&msg);
				}
			}
		}
		if(FAILED(hr)) return NULL;
		return localName;
	}

	LPWSTR StartAsyncDownload(CSqueakOCX* pT, BSTR bstrURL, IUnknown* pUnkContainer = NULL, LPVOID postData = NULL, DWORD postDataSize = 0, BOOL bRelative = FALSE)
	{
		if(postData) {
			m_hPostData = GlobalAlloc(GHND, postDataSize);
			if (m_hPostData) {
				void *pPostData = GlobalLock(m_hPostData);
				ATLASSERT(pPostData);
				memcpy(pPostData, postData, postDataSize);
				GlobalUnlock(m_hPostData);
			}
		}
		m_pT = pT;
		LPWSTR result = _StartAsyncDownload(bstrURL, pUnkContainer, bRelative);
		Release();
		return result;
	}

	static LPWSTR Download(CSqueakOCX* pT, BSTR bstrURL, IUnknown* pUnkContainer = NULL, LPVOID postData = NULL, DWORD postDataSize = 0, BOOL bRelative = FALSE)
	{
		CComObject<CSqueakStatusCallback> *pbsc;
		HRESULT hRes = CComObject<CSqueakStatusCallback>::CreateInstance(&pbsc);
		if (FAILED(hRes))
			return NULL;
		return pbsc->StartAsyncDownload(pT, bstrURL, pUnkContainer, postData, postDataSize, bRelative);
	}

	CComPtr<IMoniker> m_spMoniker;
	CComPtr<IBindCtx> m_spBindCtx;
	CComPtr<IBinding> m_spBinding;
	CComPtr<IStream> m_spStream;
	CSqueakOCX* m_pT;
    HGLOBAL m_hPostData;
	int done;
	LPWSTR localName;
};


#endif __SQUEAK_CB_H
