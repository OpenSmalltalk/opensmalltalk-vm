
SqueakOCX2ps.dll: dlldata.obj SqueakOCX2_p.obj SqueakOCX2_i.obj
	link /dll /out:SqueakOCX2ps.dll /def:SqueakOCX2ps.def /entry:DllMain dlldata.obj SqueakOCX2_p.obj SqueakOCX2_i.obj \
		kernel32.lib rpcndr.lib rpcns4.lib rpcrt4.lib oleaut32.lib uuid.lib \

.c.obj:
	cl /c /Ox /DWIN32 /D_WIN32_WINNT=0x0400 /DREGISTER_PROXY_DLL \
		$<

clean:
	@del SqueakOCX2ps.dll
	@del SqueakOCX2ps.lib
	@del SqueakOCX2ps.exp
	@del dlldata.obj
	@del SqueakOCX2_p.obj
	@del SqueakOCX2_i.obj
