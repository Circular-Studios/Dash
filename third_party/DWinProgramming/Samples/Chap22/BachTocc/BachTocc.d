/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module BachTocc;

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
pragma(lib, "comdlg32.lib");
pragma(lib, "winmm.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.commdlg;
import win32.mmsystem;

string appName     = "BachTocc";
string description = "Bach Toccata in D Minor (First Bar)";
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

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    hinst = hInstance;
    HACCEL hAccel;
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
    wndclass.lpszMenuName  = appName.toUTF16z;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    MessageBox(null, "Reduce the volume on your speakers or in the volume control panel before you continue.", "Warning", MB_OK | MB_ICONWARNING);

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        description.toUTF16z,          // window caption
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

enum ID_TIMER = 1;

DWORD MidiOutMessage(HMIDIOUT hMidi, int iStatus, int iChannel, int iData1, int iData2)
{
    DWORD dwMessage = (iStatus | iChannel | (iData1 << 8) | (iData2 << 16));

    return midiOutShortMsg(hMidi, dwMessage);
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    struct NoteSeq
    {
        int iDur;
        int[2] iNote;
    }
    
    enum noteseq = [NoteSeq(110, [69, 81]), NoteSeq(110, [67, 79]), NoteSeq(990,  [69, 81]),  NoteSeq(220,  [-1, -1]),
                    NoteSeq(110, [67, 79]), NoteSeq(110, [65, 77]), NoteSeq(110,  [64, 76]),  NoteSeq(110,  [62, 74]),
                    NoteSeq(220, [61, 73]), NoteSeq(440, [62, 74]), NoteSeq(1980, [-1, -1]),  NoteSeq(110,  [57, 69]),
                    NoteSeq(110, [55, 67]), NoteSeq(990, [57, 69]), NoteSeq(220,  [-1, -1]),  NoteSeq(220,  [52, 64]),
                    NoteSeq(220, [53, 65]), NoteSeq(220, [49, 61]), NoteSeq(440,  [50, 62]),  NoteSeq(1980, [-1, -1])];

    static HMIDIOUT hMidiOut;
    static int iIndex;
    int i;

    switch (message)
    {
        case WM_CREATE:
            // Open MIDIMAPPER device
            if (midiOutOpen(&hMidiOut, MIDIMAPPER, 0, 0, 0))
            {
                MessageBeep(MB_ICONEXCLAMATION);
                MessageBox(hwnd, "Cannot open MIDI output device!",
                           appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
                return -1;
            }

            // Send Program Change messages for "Church Organ"
            MidiOutMessage(hMidiOut, 0xC0, 0, 19, 0);
            SetTimer(hwnd, ID_TIMER, 1000, NULL);
            return 0;

        case WM_TIMER:
            // Loop for 2-note polyphony
            for (i = 0; i < 2; i++)
            {
                // Note Off messages for previous note
                if (iIndex != 0 && noteseq[iIndex - 1].iNote[i] != -1)
                {
                    MidiOutMessage(hMidiOut, 0x80, 0,
                                   noteseq[iIndex - 1].iNote[i], 0);
                }

                // Note On messages for new note
                if (iIndex != noteseq.length && noteseq[iIndex].iNote[i] != -1)
                {
                    MidiOutMessage(hMidiOut, 0x90, 0, noteseq[iIndex].iNote[i], 127);
                }
            }

            if (iIndex != noteseq.length)
            {
                SetTimer(hwnd, ID_TIMER, noteseq[iIndex++].iDur - 1, NULL);
            }
            else
            {
                KillTimer(hwnd, ID_TIMER);
                DestroyWindow(hwnd);
            }

            return 0;

        case WM_DESTROY:
            midiOutReset(hMidiOut);
            midiOutClose(hMidiOut);
            PostQuitMessage(0);
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
