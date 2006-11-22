/* this ALWAYS GENERATED file contains the definitions for the interfaces */


/* File created by MIDL compiler version 5.01.0164 */
/* at Sat Apr 20 16:54:56 2002
 */
/* Compiler settings for C:\Dokumente und Einstellungen\andreas\Eigene Dateien\Bander\Home\andreasr\dev\Squeak\3.0\src\win32\Plugin\SqueakOCX2\SqueakOCX2.idl:
    Oicf (OptLev=i2), W1, Zp8, env=Win32, ms_ext, c_ext
    error checks: allocation ref bounds_check enum stub_data 
*/
//@@MIDL_FILE_HEADING(  )


/* verify that the <rpcndr.h> version is high enough to compile this file*/
#ifndef __REQUIRED_RPCNDR_H_VERSION__
#define __REQUIRED_RPCNDR_H_VERSION__ 440
#endif

#include "rpc.h"
#include "rpcndr.h"

#ifndef __RPCNDR_H_VERSION__
#error this stub requires an updated version of <rpcndr.h>
#endif // __RPCNDR_H_VERSION__

#ifndef COM_NO_WINDOWS_H
#include "windows.h"
#include "ole2.h"
#endif /*COM_NO_WINDOWS_H*/

#ifndef __SqueakOCX2_h__
#define __SqueakOCX2_h__

#ifdef __cplusplus
extern "C"{
#endif 

/* Forward Declarations */ 

#ifndef __ISqueakOCX_FWD_DEFINED__
#define __ISqueakOCX_FWD_DEFINED__
typedef interface ISqueakOCX ISqueakOCX;
#endif 	/* __ISqueakOCX_FWD_DEFINED__ */


#ifndef __SqueakOCX_FWD_DEFINED__
#define __SqueakOCX_FWD_DEFINED__

#ifdef __cplusplus
typedef class SqueakOCX SqueakOCX;
#else
typedef struct SqueakOCX SqueakOCX;
#endif /* __cplusplus */

#endif 	/* __SqueakOCX_FWD_DEFINED__ */


/* header files for imported files */
#include "oaidl.h"
#include "ocidl.h"

void __RPC_FAR * __RPC_USER MIDL_user_allocate(size_t);
void __RPC_USER MIDL_user_free( void __RPC_FAR * ); 

#ifndef __ISqueakOCX_INTERFACE_DEFINED__
#define __ISqueakOCX_INTERFACE_DEFINED__

/* interface ISqueakOCX */
/* [unique][helpstring][dual][uuid][object] */ 


EXTERN_C const IID IID_ISqueakOCX;

#if defined(__cplusplus) && !defined(CINTERFACE)
    
    MIDL_INTERFACE("24A4DFFA-3C16-487D-BF4F-0A6324717619")
    ISqueakOCX : public IDispatch
    {
    public:
    };
    
#else 	/* C style interface */

    typedef struct ISqueakOCXVtbl
    {
        BEGIN_INTERFACE
        
        HRESULT ( STDMETHODCALLTYPE __RPC_FAR *QueryInterface )( 
            ISqueakOCX __RPC_FAR * This,
            /* [in] */ REFIID riid,
            /* [iid_is][out] */ void __RPC_FAR *__RPC_FAR *ppvObject);
        
        ULONG ( STDMETHODCALLTYPE __RPC_FAR *AddRef )( 
            ISqueakOCX __RPC_FAR * This);
        
        ULONG ( STDMETHODCALLTYPE __RPC_FAR *Release )( 
            ISqueakOCX __RPC_FAR * This);
        
        HRESULT ( STDMETHODCALLTYPE __RPC_FAR *GetTypeInfoCount )( 
            ISqueakOCX __RPC_FAR * This,
            /* [out] */ UINT __RPC_FAR *pctinfo);
        
        HRESULT ( STDMETHODCALLTYPE __RPC_FAR *GetTypeInfo )( 
            ISqueakOCX __RPC_FAR * This,
            /* [in] */ UINT iTInfo,
            /* [in] */ LCID lcid,
            /* [out] */ ITypeInfo __RPC_FAR *__RPC_FAR *ppTInfo);
        
        HRESULT ( STDMETHODCALLTYPE __RPC_FAR *GetIDsOfNames )( 
            ISqueakOCX __RPC_FAR * This,
            /* [in] */ REFIID riid,
            /* [size_is][in] */ LPOLESTR __RPC_FAR *rgszNames,
            /* [in] */ UINT cNames,
            /* [in] */ LCID lcid,
            /* [size_is][out] */ DISPID __RPC_FAR *rgDispId);
        
        /* [local] */ HRESULT ( STDMETHODCALLTYPE __RPC_FAR *Invoke )( 
            ISqueakOCX __RPC_FAR * This,
            /* [in] */ DISPID dispIdMember,
            /* [in] */ REFIID riid,
            /* [in] */ LCID lcid,
            /* [in] */ WORD wFlags,
            /* [out][in] */ DISPPARAMS __RPC_FAR *pDispParams,
            /* [out] */ VARIANT __RPC_FAR *pVarResult,
            /* [out] */ EXCEPINFO __RPC_FAR *pExcepInfo,
            /* [out] */ UINT __RPC_FAR *puArgErr);
        
        END_INTERFACE
    } ISqueakOCXVtbl;

    interface ISqueakOCX
    {
        CONST_VTBL struct ISqueakOCXVtbl __RPC_FAR *lpVtbl;
    };

    

#ifdef COBJMACROS


#define ISqueakOCX_QueryInterface(This,riid,ppvObject)	\
    (This)->lpVtbl -> QueryInterface(This,riid,ppvObject)

#define ISqueakOCX_AddRef(This)	\
    (This)->lpVtbl -> AddRef(This)

#define ISqueakOCX_Release(This)	\
    (This)->lpVtbl -> Release(This)


#define ISqueakOCX_GetTypeInfoCount(This,pctinfo)	\
    (This)->lpVtbl -> GetTypeInfoCount(This,pctinfo)

#define ISqueakOCX_GetTypeInfo(This,iTInfo,lcid,ppTInfo)	\
    (This)->lpVtbl -> GetTypeInfo(This,iTInfo,lcid,ppTInfo)

#define ISqueakOCX_GetIDsOfNames(This,riid,rgszNames,cNames,lcid,rgDispId)	\
    (This)->lpVtbl -> GetIDsOfNames(This,riid,rgszNames,cNames,lcid,rgDispId)

#define ISqueakOCX_Invoke(This,dispIdMember,riid,lcid,wFlags,pDispParams,pVarResult,pExcepInfo,puArgErr)	\
    (This)->lpVtbl -> Invoke(This,dispIdMember,riid,lcid,wFlags,pDispParams,pVarResult,pExcepInfo,puArgErr)


#endif /* COBJMACROS */


#endif 	/* C style interface */




#endif 	/* __ISqueakOCX_INTERFACE_DEFINED__ */



#ifndef __SQUEAKOCX2Lib_LIBRARY_DEFINED__
#define __SQUEAKOCX2Lib_LIBRARY_DEFINED__

/* library SQUEAKOCX2Lib */
/* [helpstring][version][uuid] */ 


EXTERN_C const IID LIBID_SQUEAKOCX2Lib;

EXTERN_C const CLSID CLSID_SqueakOCX;

#ifdef __cplusplus

class DECLSPEC_UUID("2BE9C39E-8386-4435-B337-FCDAD8EAB006")
SqueakOCX;
#endif
#endif /* __SQUEAKOCX2Lib_LIBRARY_DEFINED__ */

/* Additional Prototypes for ALL interfaces */

/* end of Additional Prototypes */

#ifdef __cplusplus
}
#endif

#endif
