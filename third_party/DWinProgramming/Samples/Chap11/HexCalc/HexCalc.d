/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module HexCalc;

import core.runtime;
import core.thread;
import std.conv;
import std.ascii;
import std.math;
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
import win32.winnt;

import resource;

string appName     = "HexCalc";
string description = "Hex Calculator";
enum ID_TIMER = 1;
HINSTANCE hinst;

const MAXDWORD = 0xffffffff;

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

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    hinst = hInstance;
    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = DLGWINDOWEXTRA;     // Note!
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH)(COLOR_BTNFACE + 1);
    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = appName.toUTF16z;

     if (!RegisterClass (&wndclass))
     {
          MessageBox(NULL, "This program requires Windows NT!",
                     appName.toUTF16z, MB_ICONERROR);
          return 0;
     }

     hwnd = CreateDialog (hInstance, appName.toUTF16z, null, NULL);

     ShowWindow (hwnd, iCmdShow);

     while (GetMessage (&msg, NULL, 0, 0))
     {
          TranslateMessage (&msg);
          DispatchMessage (&msg);
     }
     return msg.wParam;
}

void ShowNumber(HWND hwnd, UINT iNumber)
{
    TCHAR[20] szBuffer;

    auto result = format("%x", iNumber);
    SetDlgItemText(hwnd, VK_ESCAPE, result.toUTF16z);
}

DWORD CalcIt(UINT iFirstNum, int iOperation, UINT iNum)
{
    switch (iOperation)
    {
        case '=':
            return iNum;

        case '+':
            return iFirstNum + iNum;

        case '-':
            return iFirstNum - iNum;

        case '*':
            return iFirstNum * iNum;

        case '&':
            return iFirstNum & iNum;

        case '|':
            return iFirstNum | iNum;

        case '^':
            return iFirstNum ^ iNum;

        case '<':
            return iFirstNum << iNum;

        case '>':
            return iFirstNum >> iNum;

        case '/':
            return iNum ? iFirstNum / iNum : MAXDWORD;

        case '%':
            return iNum ? iFirstNum % iNum : MAXDWORD;

        default:
            return 0;
    }
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BOOL bNewNumber = TRUE;
    static int  iOperation = '=';
    static UINT iNumber, iFirstNum;
    HWND hButton;

    switch (message)
    {
        case WM_KEYDOWN:                // left arrow --> backspace

            if (wParam != VK_LEFT)
                break;

            wParam = VK_BACK;
            goto case WM_CHAR;

        case WM_CHAR:

            if ((wParam = cast(WPARAM)CharUpper(cast(TCHAR *)wParam)) == VK_RETURN)
                wParam = '=';

            hButton = GetDlgItem(hwnd, wParam);
            if (hButton)
            {
                SendMessage(hButton, BM_SETSTATE, 1, 0);
                Thread.sleep( dur!"msecs"( 100 ) );
                SendMessage(hButton, BM_SETSTATE, 0, 0);
            }
            else
            {
                MessageBeep(0);
                break;
            }

            goto case WM_COMMAND;

        case WM_COMMAND:
            SetFocus(hwnd);

            if (LOWORD(wParam) == VK_BACK)        // backspace
                ShowNumber(hwnd, iNumber /= 16);

            else if (LOWORD(wParam) == VK_ESCAPE) // escape
                ShowNumber(hwnd, iNumber = 0);

            else if (isHexDigit(LOWORD(wParam)))    // hex digit
            {
                if (bNewNumber)
                {
                    iFirstNum = iNumber;
                    iNumber   = 0;
                }

                bNewNumber = FALSE;

                if (iNumber <= MAXDWORD >> 4)
                    ShowNumber(hwnd, iNumber = 16 * iNumber + wParam -
                                               (isDigit(wParam) ? '0' : 'A' - 10));
                else
                    MessageBeep(0);
            }
            else                                  // operation
            {
                if (!bNewNumber)
                    ShowNumber(hwnd, iNumber =
                                   CalcIt(iFirstNum, iOperation, iNumber));

                bNewNumber = TRUE;
                iOperation = LOWORD(wParam);
            }

            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
