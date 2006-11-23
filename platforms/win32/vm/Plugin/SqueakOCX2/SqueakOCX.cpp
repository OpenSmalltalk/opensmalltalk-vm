// SqueakOCX.cpp : Implementation of CSqueakOCX

#include "stdafx.h"
#include "SqueakOCX2.h"
#include "SqueakOCX.h"
#include "SqueakCB.h"

/////////////////////////////////////////////////////////////////////////////
// CSqueakOCX

STDMETHODIMP CSqueakOCX::Load(LPPROPERTYBAG pPropBag, LPERRORLOG pErrorLog)
{
    CComQIPtr<IPropertyBag2> propBag2 = pPropBag;
    if (propBag2) {
        ULONG nProperties;
        propBag2->CountProperties(&nProperties);
        if (nProperties > 0) {
            PROPBAG2 *props = (PROPBAG2 *) malloc(sizeof(PROPBAG2) * nProperties);
            ULONG nRead = 0;
            propBag2->GetPropertyInfo(0, nProperties, props, &nRead);
            for (ULONG i = 0; i < nRead; i++) {
                if (props[i].vt == VT_BSTR) {
					char *key;
					char *value;
                    USES_CONVERSION;
                    CComVariant v;
                    HRESULT hr;
                    propBag2->Read(1, &props[i], NULL, &v, &hr);
					key = OLE2A(props[i].pstrName);
					value = OLE2A(v.bstrVal);
					if(stricmp(key,"imageName") == 0) {
						SqueakPluginSetImage(squeak, value);
					}
					if(stricmp(key,"vmName") == 0) {
						SqueakPluginSetVM(squeak, value);
					}
				    if(stricmp(key,"win32Params") == 0) {
						SqueakPluginSetVMParams(squeak, value);
					}
					if(stricmp(key, "pluginsPage") == 0) {
						pluginsPage = strdup(value);
					}
					SqueakPluginAddParam(squeak, key, value);
                }
                if (props[i].pstrName) {
                    CoTaskMemFree(props[i].pstrName);
                }
            }
            free(props);
        }
    }
    return IPersistPropertyBagImpl<CSqueakOCX>::Load(pPropBag, pErrorLog);
}

void CSqueakOCX::GoToPluginsPage(void) {
	if(!pluginsPage) return;
    CComPtr<IWebBrowserApp> webBrowser;
    CComQIPtr<IServiceProvider, &IID_IServiceProvider> serviceProvider = m_spClientSite;

    if (serviceProvider) {
		HRESULT hRes;
        hRes = serviceProvider->QueryService(IID_IWebBrowserApp, &webBrowser);
		if(FAILED(hRes)) {
			return;
		}
    }
	CComBSTR bstrPluginsPage = pluginsPage;
	CComVariant vFlags;
	CComVariant vTarget;
	CComVariant vPostData;
	CComVariant vHeaders;
	webBrowser->Navigate(bstrPluginsPage, &vFlags, &vTarget, &vPostData, &vHeaders);
}

void CSqueakOCX::GetURL(char *url, char *target, int id) {
	HRESULT hRes;
    CComBSTR bstrURL;
	CComBSTR bstrRelURL = url;
	CComBSTR bstrFullURL(MAX_PATH);
	LPWSTR localFile;
	DWORD sz;

	USES_CONVERSION;

    CComPtr<IWebBrowserApp> webBrowser;
    CComQIPtr<IServiceProvider, &IID_IServiceProvider> serviceProvider = m_spClientSite;

    if (serviceProvider) {
        hRes = serviceProvider->QueryService(IID_IWebBrowserApp, &webBrowser);
		if(FAILED(hRes)) {
			SqueakPluginStreamState(squeak, url, 0);
			return;
		}
    }

    hRes = webBrowser->get_LocationURL(&bstrURL);
    if(FAILED(hRes)) {
		MessageBox("Failed to get_LocationURL", "Squeak");
		SqueakPluginStreamState(squeak, url, 0);
		return;
	}
    hRes = CoInternetCombineUrl(bstrURL, bstrRelURL, 0, bstrFullURL, MAX_PATH, &sz, 0);
    if(FAILED(hRes)) hRes = CoInternetCombineUrl(bstrURL, bstrRelURL, 0, bstrFullURL, sz, &sz, 0);
    if(FAILED(hRes)) {
		MessageBox("Failed to CoInternetCombineURL", "Squeak");
		SqueakPluginStreamState(squeak, url, 0);
		return;
	}

	if(target) {
        CComVariant vFlags;
		CComVariant vTarget;
        CComVariant vPostData;
        CComVariant vHeaders;

		vTarget = target;
        hRes = webBrowser->Navigate(bstrFullURL, &vFlags, &vTarget, &vPostData, &vHeaders);
		if(FAILED(hRes)) {
			SqueakPluginStreamState(squeak, url, 0);
		} else {
			SqueakPluginStreamFile(squeak, url, "",id);
		}
	} else {
		localFile = CSqueakStatusCallback::Download(this, bstrFullURL, m_spClientSite, NULL, 0, FALSE);
		if(localFile) {
			SqueakPluginStreamFile(squeak, url, OLE2A(localFile),id);
			CoTaskMemFree(localFile);
		} else {
			SqueakPluginStreamState(squeak, url, 0);
		}
	}
}

void CSqueakOCX::PostURL(char* url, char *target, char *postData, int id) {
	HRESULT hRes;
    CComBSTR bstrURL;
	CComBSTR bstrRelURL = url;
	CComBSTR bstrFullURL(MAX_PATH);
	LPWSTR localFile;
	DWORD sz;

	USES_CONVERSION;

    CComPtr<IWebBrowserApp> webBrowser;
    CComQIPtr<IServiceProvider, &IID_IServiceProvider> serviceProvider = m_spClientSite;

    if (serviceProvider) {
        hRes = serviceProvider->QueryService(IID_IWebBrowserApp, &webBrowser);
		if(FAILED(hRes)) {
			SqueakPluginStreamState(squeak, url, 0);
			return;
		}
    }

    hRes = webBrowser->get_LocationURL(&bstrURL);
    if(FAILED(hRes)) {
		MessageBox("Failed to get_LocationURL", "Squeak");
		SqueakPluginStreamState(squeak, url, 0);
		return;
	}
    hRes = CoInternetCombineUrl(bstrURL, bstrRelURL, 0, bstrFullURL, MAX_PATH, &sz, 0);
    if(FAILED(hRes)) hRes = CoInternetCombineUrl(bstrURL, bstrRelURL, 0, bstrFullURL, sz, &sz, 0);
    if(FAILED(hRes)) {
		MessageBox("Failed to CoInternetCombineURL", "Squeak");
		SqueakPluginStreamState(squeak, url, 0);
		return;
	}

	if(target) {
        CComVariant vFlags;
		CComVariant vTarget;
        CComVariant vPostData;
        CComVariant vHeaders;

		SAFEARRAYBOUND saBound[1];
		saBound[0].lLbound = 0;
		saBound[0].cElements = strlen(postData);
		vPostData.vt = VT_ARRAY | VT_UI1;
		vPostData.parray = SafeArrayCreate(VT_UI1, 1, saBound);
		SafeArrayLock(vPostData.parray);
		memcpy(vPostData.parray->pvData, postData, saBound[0].cElements);
		SafeArrayUnlock(vPostData.parray);

		vTarget = target;
        hRes = webBrowser->Navigate(bstrFullURL, &vFlags, &vTarget, &vPostData, &vHeaders);
		if(FAILED(hRes)) {
			SqueakPluginStreamState(squeak, url, 0);
		} else {
			SqueakPluginStreamFile(squeak, url, "",id);
		}
	} else {
		localFile = CSqueakStatusCallback::Download(this, bstrFullURL, m_spClientSite, postData, strlen(postData)+1, FALSE);
		if(localFile) {
			SqueakPluginStreamFile(squeak, url, OLE2A(localFile),id);
			CoTaskMemFree(localFile);
		} else {
			SqueakPluginStreamState(squeak, url, 0);
		}
	}
}

void SqueakPluginRequestStream(void *instance, char *url, char *target, int id)
{
	((CSqueakOCX*)instance)->GetURL(url, target, id);
}

void SqueakPluginPostData(void *instance, char *url, char *target, char *data, int id)
{
	((CSqueakOCX*)instance)->PostURL(url, target, data, id);
}
