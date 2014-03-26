/***********************************************************************\
*                                 ole2.d                                *
*                                                                       *
*                       Windows API header module                       *
*                                                                       *
*                 Translated from MinGW Windows headers                 *
*                                                                       *
*                       Placed into public domain                       *
\***********************************************************************/
module win32.ole2;
pragma(lib, "ole32.lib");

public import win32.basetyps, win32.objbase, win32.oleauto, win32.olectlid,
  win32.oleidl, win32.unknwn, win32.winerror, win32.uuid;
private import win32.objfwd, win32.objidl, win32.windef, win32.wtypes;
private import win32.winuser; // for LPMSG

const E_DRAW = VIEW_E_DRAW;

const DATA_E_FORMATETC = DV_E_FORMATETC;

enum {
	OLEIVERB_PRIMARY = 0,
	OLEIVERB_SHOW = -1,
	OLEIVERB_OPEN = -2,
	OLEIVERB_HIDE = -3,
	OLEIVERB_UIACTIVATE = -4,
	OLEIVERB_INPLACEACTIVATE = -5,
	OLEIVERB_DISCARDUNDOSTATE = -6
}

const EMBDHLP_INPROC_HANDLER = 0x0000L;
const EMBDHLP_INPROC_SERVER  = 0x0001L;
const EMBDHLP_CREATENOW      = 0x00000000L;
const EMBDHLP_DELAYCREATE    = 0x00010000L;

align(8):
struct OLESTREAM {
	LPOLESTREAMVTBL lpstbl;
}
alias OLESTREAM* LPOLESTREAM;

extern (Windows) {
	struct OLESTREAMVTBL {
		DWORD function (LPOLESTREAM, void*, DWORD) Get;
		DWORD function (LPOLESTREAM, CPtr!(void), DWORD) Put;
	}
}
alias OLESTREAMVTBL* LPOLESTREAMVTBL;

extern (Windows) {
	HRESULT CreateDataAdviseHolder(LPDATAADVISEHOLDER*);
	DWORD OleBuildVersion();
	HRESULT ReadClassStg(LPSTORAGE, CLSID*);
	HRESULT WriteClassStg(LPSTORAGE, REFCLSID);
	HRESULT ReadClassStm(LPSTREAM, CLSID*);
	HRESULT WriteClassStm(LPSTREAM, REFCLSID);
	HRESULT WriteFmtUserTypeStg(LPSTORAGE, CLIPFORMAT, LPOLESTR);
	HRESULT ReadFmtUserTypeStg(LPSTORAGE, CLIPFORMAT*, LPOLESTR*);
	HRESULT OleInitialize(PVOID);
	void OleUninitialize();
	HRESULT OleQueryLinkFromData(LPDATAOBJECT);
	HRESULT OleQueryCreateFromData(LPDATAOBJECT);
	HRESULT OleCreate(REFCLSID, REFIID, DWORD, LPFORMATETC, LPOLECLIENTSITE, LPSTORAGE, PVOID*);
	HRESULT OleCreateFromData(LPDATAOBJECT, REFIID, DWORD, LPFORMATETC, LPOLECLIENTSITE, LPSTORAGE, PVOID*);
	HRESULT OleCreateLinkFromData(LPDATAOBJECT, REFIID, DWORD, LPFORMATETC, LPOLECLIENTSITE, LPSTORAGE, PVOID*);
	HRESULT OleCreateStaticFromData(LPDATAOBJECT, REFIID, DWORD, LPFORMATETC, LPOLECLIENTSITE, LPSTORAGE, PVOID*);
	HRESULT OleCreateLink(LPMONIKER, REFIID, DWORD, LPFORMATETC, LPOLECLIENTSITE, LPSTORAGE, PVOID*);
	HRESULT OleCreateLinkToFile(LPCOLESTR, REFIID, DWORD, LPFORMATETC, LPOLECLIENTSITE, LPSTORAGE, PVOID*);
	HRESULT OleCreateFromFile(REFCLSID, LPCOLESTR, REFIID, DWORD, LPFORMATETC, LPOLECLIENTSITE, LPSTORAGE, PVOID*);
	HRESULT OleLoad(LPSTORAGE, REFIID, LPOLECLIENTSITE, PVOID*);
	HRESULT OleSave(LPPERSISTSTORAGE, LPSTORAGE, BOOL);
	HRESULT OleLoadFromStream(LPSTREAM, REFIID, PVOID*);
	HRESULT OleSaveToStream(LPPERSISTSTREAM, LPSTREAM);
	HRESULT OleSetContainedObject(LPUNKNOWN, BOOL);
	HRESULT OleNoteObjectVisible(LPUNKNOWN, BOOL);
	HRESULT RegisterDragDrop(HWND, LPDROPTARGET);
	HRESULT RevokeDragDrop(HWND);
	HRESULT DoDragDrop(LPDATAOBJECT, LPDROPSOURCE, DWORD, PDWORD);
	HRESULT OleSetClipboard(LPDATAOBJECT);
	HRESULT OleGetClipboard(LPDATAOBJECT*);
	HRESULT OleFlushClipboard();
	HRESULT OleIsCurrentClipboard(LPDATAOBJECT);
	HOLEMENU OleCreateMenuDescriptor(HMENU, LPOLEMENUGROUPWIDTHS);
	HRESULT OleSetMenuDescriptor(HOLEMENU, HWND, HWND, LPOLEINPLACEFRAME, LPOLEINPLACEACTIVEOBJECT);
	HRESULT OleDestroyMenuDescriptor(HOLEMENU);
	HRESULT OleTranslateAccelerator(LPOLEINPLACEFRAME, LPOLEINPLACEFRAMEINFO, LPMSG);
	HANDLE OleDuplicateData(HANDLE, CLIPFORMAT, UINT);
	HRESULT OleDraw(LPUNKNOWN, DWORD, HDC, LPCRECT);
	HRESULT OleRun(LPUNKNOWN);
	BOOL OleIsRunning(LPOLEOBJECT);
	HRESULT OleLockRunning(LPUNKNOWN, BOOL, BOOL);
	void ReleaseStgMedium(LPSTGMEDIUM);
	HRESULT CreateOleAdviseHolder(LPOLEADVISEHOLDER*);
	HRESULT OleCreateDefaultHandler(REFCLSID, LPUNKNOWN, REFIID, PVOID*);
	HRESULT OleCreateEmbeddingHelper(REFCLSID, LPUNKNOWN, DWORD, LPCLASSFACTORY, REFIID, PVOID*);
	BOOL IsAccelerator(HACCEL, int, LPMSG, WORD*);
	HGLOBAL OleGetIconOfFile(LPOLESTR, BOOL);
	HGLOBAL OleGetIconOfClass(REFCLSID, LPOLESTR, BOOL);
	HGLOBAL OleMetafilePictFromIconAndLabel(HICON, LPOLESTR, LPOLESTR, UINT);
	HRESULT OleRegGetUserType(REFCLSID, DWORD, LPOLESTR*);
	HRESULT OleRegGetMiscStatus(REFCLSID, DWORD, DWORD*);
	HRESULT OleRegEnumFormatEtc (REFCLSID, DWORD, LPENUMFORMATETC*);
	HRESULT OleRegEnumVerbs (REFCLSID, LPENUMOLEVERB*);
	HRESULT OleConvertOLESTREAMToIStorage(LPOLESTREAM, LPSTORAGE, CPtr!(DVTARGETDEVICE));
	HRESULT OleConvertIStorageToOLESTREAM(LPSTORAGE, LPOLESTREAM);
	HRESULT GetHGlobalFromILockBytes(LPLOCKBYTES, HGLOBAL*);
	HRESULT CreateILockBytesOnHGlobal(HGLOBAL, BOOL, LPLOCKBYTES*);
	HRESULT GetHGlobalFromStream(LPSTREAM, HGLOBAL*);
	HRESULT CreateStreamOnHGlobal(HGLOBAL, BOOL, LPSTREAM*);
	HRESULT OleDoAutoConvert(LPSTORAGE, LPCLSID);
	HRESULT OleGetAutoConvert(REFCLSID, LPCLSID);
	HRESULT OleSetAutoConvert(REFCLSID, REFCLSID);
	HRESULT GetConvertStg(LPSTORAGE);
	HRESULT SetConvertStg(LPSTORAGE, BOOL);
	HRESULT OleConvertIStorageToOLESTREAMEx(LPSTORAGE, CLIPFORMAT, LONG, LONG, DWORD, LPSTGMEDIUM, LPOLESTREAM);
	HRESULT OleConvertOLESTREAMToIStorageEx(LPOLESTREAM, LPSTORAGE, CLIPFORMAT*, LONG*, LONG*, DWORD*, LPSTGMEDIUM);
}
