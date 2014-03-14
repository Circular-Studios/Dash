/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Scramble;

import core.memory;
import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.random;
import std.range;
import std.string;
import std.utf;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;

string appName     = "Scramble";
string description = "Scramble";
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

enum NUM = 80;

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    static int iKeep [NUM][4];
    HDC hdcScr, hdcMem;
    int cx, cy;
    HBITMAP hBitmap;
    HWND hwnd;
    int  i, j, x1, y1, x2, y2;

    if (LockWindowUpdate(hwnd = GetDesktopWindow()))
    {
        hdcScr  = GetDCEx(hwnd, NULL, DCX_CACHE | DCX_LOCKWINDOWUPDATE);
        hdcMem  = CreateCompatibleDC(hdcScr);
        cx      = GetSystemMetrics(SM_CXSCREEN) / 10;
        cy      = GetSystemMetrics(SM_CYSCREEN) / 10;
        hBitmap = CreateCompatibleBitmap(hdcScr, cx, cy);

        SelectObject(hdcMem, hBitmap);
        
        for (i = 0; i < 2; i++)
        {
            for (j = 0; j < NUM; j++)
            {
                if (i == 0)
                {
                    iKeep[j][0] = x1 = cx * (uniform(0, 10));
                    iKeep[j][1] = y1 = cy * (uniform(0, 10));
                    iKeep[j][2] = x2 = cx * (uniform(0, 10));
                    iKeep[j][3] = y2 = cy * (uniform(0, 10));
                }
                else
                {
                    x1 = iKeep[NUM - 1 - j][0];
                    y1 = iKeep[NUM - 1 - j][1];
                    x2 = iKeep[NUM - 1 - j][2];
                    y2 = iKeep[NUM - 1 - j][3];
                }

                BitBlt(hdcMem,  0,  0, cx, cy, hdcScr, x1, y1, SRCCOPY);
                BitBlt(hdcScr, x1, y1, cx, cy, hdcScr, x2, y2, SRCCOPY);
                BitBlt(hdcScr, x2, y2, cx, cy, hdcMem,  0,  0, SRCCOPY);

                Sleep(10);
            }
        }

        DeleteDC(hdcMem);
        ReleaseDC(hwnd, hdcScr);
        DeleteObject(hBitmap);

        LockWindowUpdate(NULL);
    }

    return FALSE;
}
