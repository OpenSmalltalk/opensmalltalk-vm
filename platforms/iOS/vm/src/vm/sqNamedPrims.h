/* Automatically generated from Squeak on #(15 May 2008 3:27:04 pm)
by VMMaker 3.8b6
 */
/* This is an automatically generated table of all builtin modules in the VM */

extern sqExport vm_exports[];
extern sqExport os_exports[];
extern sqExport ADPCMCodecPlugin_exports[];
extern sqExport Squeak3D_exports[];
extern sqExport B2DPlugin_exports[];
extern sqExport BitBltPlugin_exports[];
extern sqExport BMPReadWriterPlugin_exports[];
extern sqExport ClipboardExtendedPlugin_exports[];
extern sqExport ZipPlugin_exports[];
extern sqExport DSAPrims_exports[];
extern sqExport SqueakFFIPrims_exports[];
extern sqExport FFTPlugin_exports[];
extern sqExport FilePlugin_exports[];
extern sqExport FloatArrayPlugin_exports[];
extern sqExport GeniePlugin_exports[];
extern sqExport HostWindowPlugin_exports[];
extern sqExport JPEGReaderPlugin_exports[];
extern sqExport JPEGReadWriter2Plugin_exports[];
extern sqExport Klatt_exports[];
extern sqExport LargeIntegers_exports[];
extern sqExport Matrix2x3Plugin_exports[];
#if 0
extern sqExport MacMenubarPlugin_exports[];
#endif
extern sqExport MiscPrimitivePlugin_exports[];
extern sqExport ObjectiveCPlugin_exports[];
extern sqExport RePlugin_exports[];
extern sqExport SecurityPlugin_exports[];
extern sqExport SocketPlugin_exports[];
extern sqExport SoundCodecPrims_exports[];
extern sqExport SoundGenerationPlugin_exports[];
extern sqExport SoundPlugin_exports[];
extern sqExport StarSqueakPlugin_exports[];
extern sqExport SurfacePlugin_exports[];
extern sqExport UUIDPlugin_exports[];
#ifdef BUILD_FOR_OSX
extern sqExport DropPlugin_exports[];
#endif

sqExport *pluginExports[] = {
	vm_exports,
	os_exports,
	ADPCMCodecPlugin_exports,
	Squeak3D_exports,
	B2DPlugin_exports,
	BitBltPlugin_exports,
	BMPReadWriterPlugin_exports,
	ClipboardExtendedPlugin_exports,
	ZipPlugin_exports,
	DSAPrims_exports,
	SqueakFFIPrims_exports,
	FFTPlugin_exports,
	FilePlugin_exports,
	FloatArrayPlugin_exports,
	GeniePlugin_exports,
	HostWindowPlugin_exports,
	JPEGReaderPlugin_exports,
	JPEGReadWriter2Plugin_exports,
	Klatt_exports,
	LargeIntegers_exports,
#if 0
	MacMenubarPlugin_exports,
#endif
	Matrix2x3Plugin_exports,
	MiscPrimitivePlugin_exports,
	ObjectiveCPlugin_exports,
	RePlugin_exports,
	SecurityPlugin_exports,
#ifndef TARGET_OS_IS_IPHONE
	SocketPlugin_exports,
#endif
	SoundCodecPrims_exports,
	SoundGenerationPlugin_exports,
	SoundPlugin_exports,
	StarSqueakPlugin_exports,
	SurfacePlugin_exports,
	UUIDPlugin_exports,
#ifdef BUILD_FOR_OSX
	DropPlugin_exports,
#endif
	NULL
};
