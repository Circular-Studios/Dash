/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Typer;

import core.runtime;
import core.thread;
import std.algorithm : min, max;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.stdio;
import std.utf;

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

pragma(lib, "gdi32.lib");

import win32.windef;
import win32.winuser;
import win32.wingdi;

extern(Windows)
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
    catch(Throwable o)
    {
        MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    string appName = "Typer";

    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH)GetStockObject(WHITE_BRUSH);

    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        "Typing Program",              // window caption
                        WS_OVERLAPPEDWINDOW,           // window style
                        CW_USEDEFAULT,                 // initial x position
                        CW_USEDEFAULT,                 // initial y position
                        CW_USEDEFAULT,                 // initial x size
                        CW_USEDEFAULT,                 // initial y size
                        NULL,                          // parent window handle
                        NULL,                          // window menu handle
                        hInstance,                     // program instance handle
                        NULL);                         // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static DWORD dwCharSet = DEFAULT_CHARSET;
    static int cxChar, cyChar, cxClient, cyClient, cxBuffer, cyBuffer, xCaret, yCaret;
    static wchar[][] textBuffer;

    HDC hdc;
    int x;
    PAINTSTRUCT ps;
    TEXTMETRIC  tm;

    switch (message)
    {
        case WM_INPUTLANGCHANGE:
        {
            dwCharSet = wParam;
            goto case WM_CREATE;
        }

        case WM_CREATE:
        {
            hdc = GetDC(hwnd);
            scope(exit) ReleaseDC(hwnd, hdc);

            SelectObject(hdc, CreateFont(0, 0, 0, 0, 0, 0, 0, 0, dwCharSet, 0, 0, 0, FIXED_PITCH, NULL));
            scope(exit) DeleteObject(SelectObject(hdc, GetStockObject(SYSTEM_FONT)));

            GetTextMetrics(hdc, &tm);
            cxChar = tm.tmAveCharWidth;
            cyChar = tm.tmHeight;

            goto case WM_SIZE;
        }

        case WM_SIZE:
        {
            // obtain window size in pixels
            if (message == WM_SIZE)
            {
                cxClient = LOWORD(lParam);
                cyClient = HIWORD(lParam);
            }

            // calculate window size in characters
            cxBuffer = max(1, cxClient / cxChar);
            cyBuffer = max(1, cyClient / cyChar);

            textBuffer = new wchar[][](cyBuffer, cxBuffer);
            foreach (ref wchar[] line; textBuffer)
            {
                line[] = ' ';
            }

            // set caret to upper left corner
            xCaret = 0;
            yCaret = 0;

            if (hwnd == GetFocus())
                SetCaretPos(xCaret * cxChar, yCaret * cyChar);

            InvalidateRect(hwnd, NULL, TRUE);
            return 0;
        }

        case WM_SETFOCUS:
        {
            CreateCaret(hwnd, NULL, cxChar, cyChar);
            SetCaretPos(xCaret * cxChar, yCaret * cyChar);
            ShowCaret(hwnd);
            return 0;
        }

        case WM_KILLFOCUS:
        {
            HideCaret(hwnd);
            DestroyCaret();
            return 0;
        }

        case WM_KEYDOWN:
        {
            switch (wParam)
            {
                case VK_HOME:
                    xCaret = 0;
                    break;

                case VK_END:
                    xCaret = cxBuffer - 1;
                    break;

                case VK_PRIOR:
                    yCaret = 0;
                    break;

                case VK_NEXT:
                    yCaret = cyBuffer - 1;
                    break;

                case VK_LEFT:
                    xCaret = max(xCaret - 1, 0);
                    break;

                case VK_RIGHT:
                    xCaret = min(xCaret + 1, cxBuffer - 1);
                    break;

                case VK_UP:
                    yCaret = max(yCaret - 1, 0);
                    break;

                case VK_DOWN:
                    yCaret = min(yCaret + 1, cyBuffer - 1);
                    break;

                case VK_DELETE:
                {
                    textBuffer[yCaret] = textBuffer[yCaret][1..$] ~ ' ';
                    HideCaret(hwnd);

                    hdc = GetDC(hwnd);
                    scope(exit) ReleaseDC(hwnd, hdc);

                    SelectObject(hdc, CreateFont(0, 0, 0, 0, 0, 0, 0, 0, dwCharSet, 0, 0, 0, FIXED_PITCH, NULL));
                    scope(exit) DeleteObject(SelectObject(hdc, GetStockObject(SYSTEM_FONT)));

                    TextOut(hdc, xCaret * cxChar, yCaret * cyChar, &textBuffer[yCaret][xCaret], cxBuffer - xCaret);
                    ShowCaret(hwnd);
                    break;
                }

                default:
            }

            SetCaretPos(xCaret * cxChar, yCaret * cyChar);
            return 0;
        }

        case WM_CHAR:
        {
            // lParam stores the repeat count of a character
            foreach (i; 0 .. cast(int)LOWORD(lParam))
            {
                switch (wParam)
                {
                    case '\b':
                    {
                        if (xCaret > 0)
                        {
                            xCaret--;
                            SendMessage(hwnd, WM_KEYDOWN, VK_DELETE, 1);
                        }
                        break;
                    }

                    case '\t':
                    {
                        do
                        {
                            SendMessage(hwnd, WM_CHAR, ' ', 1);
                        }
                        while (xCaret % 4 != 0);

                        break;
                    }

                    case '\n':
                    {
                        if (++yCaret == cyBuffer)
                            yCaret = 0;

                        break;
                    }

                    case '\r':
                    {
                        xCaret = 0;

                        if (++yCaret == cyBuffer)
                            yCaret = 0;

                        break;
                    }

                    case '\x1B':  // escape
                    {
                        foreach (ref wchar[] line; textBuffer)
                        {
                            line[] = ' ';
                        }

                        xCaret = 0;
                        yCaret = 0;

                        InvalidateRect(hwnd, NULL, FALSE);
                        break;
                    }

                    default:  // other chars
                    {
                        textBuffer[yCaret][xCaret] = cast(char)wParam;
                        HideCaret(hwnd);

                        hdc = GetDC(hwnd);
                        scope(exit) ReleaseDC(hwnd, hdc);

                        SelectObject(hdc, CreateFont(0, 0, 0, 0, 0, 0, 0, 0, dwCharSet, 0, 0, 0, FIXED_PITCH, NULL));
                        scope(exit) DeleteObject(SelectObject(hdc, GetStockObject(SYSTEM_FONT)));

                        TextOut(hdc, xCaret * cxChar, yCaret * cyChar,
                                    &textBuffer[yCaret][xCaret], 1);

                        ShowCaret(hwnd);

                        if (++xCaret == cxBuffer)
                        {
                            xCaret = 0;

                            if (++yCaret == cyBuffer)
                                yCaret = 0;
                        }

                        break;
                    }
                }
            }

            SetCaretPos(xCaret * cxChar, yCaret * cyChar);
            return 0;
        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);
            scope(exit) EndPaint(hwnd, &ps);

            SelectObject(hdc, CreateFont(0, 0, 0, 0, 0, 0, 0, 0, dwCharSet, 0, 0, 0, FIXED_PITCH, NULL));
            scope(exit) DeleteObject(SelectObject(hdc, GetStockObject(SYSTEM_FONT)));

            foreach (y; 0 .. cyBuffer)
            {
                TextOut(hdc, 0, y * cyChar, textBuffer[y].ptr, cxBuffer);
            }

            return 0;
        }

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
