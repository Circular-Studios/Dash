/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module FormFeed;

import core.memory;
import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.utf;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");
pragma(lib, "winspool.lib");

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.winspool;

string appName     = "FormFeed";
string description = "FormFeed";
enum ID_TIMER = 1;
HINSTANCE hinst;

extern (Windows)
int WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    int result;
    void exceptionHandler(Throwable e) { throw e; }

    try
    {
        Runtime.initialize(&exceptionHandler);
        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, iCmdShow);
        Runtime.terminate(&exceptionHandler);
    }
    catch (Throwable o)
    {
        MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

HDC GetPrinterDC()
{
    DWORD dwNeeded, dwReturned;
    HDC hdc;
    PRINTER_INFO_4* pinfo4;
    PRINTER_INFO_5* pinfo5;

    if (GetVersion() & 0x80000000)           // Windows 98
    {
        EnumPrinters(PRINTER_ENUM_DEFAULT, NULL, 5, NULL, 0, &dwNeeded, &dwReturned);

        pinfo5 = cast(typeof(pinfo5))GC.malloc(dwNeeded);
        EnumPrinters(PRINTER_ENUM_DEFAULT, NULL, 5, cast(PBYTE)pinfo5, dwNeeded, &dwNeeded, &dwReturned);
        hdc = CreateDC(NULL, pinfo5.pPrinterName, NULL, NULL);
        GC.free(pinfo5);
    }
    else                                     // Windows NT
    {
        EnumPrinters(PRINTER_ENUM_LOCAL, NULL, 4, NULL, 0, &dwNeeded, &dwReturned);
        pinfo4 = cast(typeof(pinfo4))GC.malloc(dwNeeded);
        EnumPrinters(PRINTER_ENUM_LOCAL, NULL, 4, cast(PBYTE)pinfo4, dwNeeded, &dwNeeded, &dwReturned);
        hdc = CreateDC(NULL, pinfo4.pPrinterName, NULL, NULL);
        GC.free(pinfo4);
    }

    return hdc;
}

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    static DOCINFO di = DOCINFO(DOCINFO.sizeof, "FormFeed");
    HDC hdcPrint      = GetPrinterDC();

    if (hdcPrint != NULL)
    {
        if (StartDoc(hdcPrint, &di) > 0)
            if (StartPage(hdcPrint) > 0 && EndPage(hdcPrint) > 0)
                EndDoc(hdcPrint);

        DeleteDC(hdcPrint);
    }

    return 0;
}
