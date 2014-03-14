/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module Drum;

import core.memory;
import core.runtime;
import core.thread;
import std.algorithm : min, max;

import std.conv;
import std.math;
import std.range;
import std.string;
import std.utf : count, toUTFz;

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

import resource;

string appName     = "Drum";
string description = "MIDI Drum Machine";
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

    hwnd = CreateWindow(appName.toUTF16z,              // window class name
                        description.toUTF16z,          // window caption
                        WS_OVERLAPPEDWINDOW | WS_CAPTION | WS_SYSMENU |
                        WS_MINIMIZEBOX | WS_HSCROLL | WS_VSCROLL,  // window style
                        CW_USEDEFAULT,                 // initial x position
                        CW_USEDEFAULT,                 // initial y position
                        CW_USEDEFAULT,                 // initial x size
                        CW_USEDEFAULT,                 // initial y size
                        NULL,                          // parent window handle
                        NULL,                          // window menu handle
                        hInstance,                     // program instance handle
                        lpCmdLine);                    // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

import DrumTime;
import DrumFile;

string[NUM_PERC] szPerc =
[
    "Acoustic Bass Drum", "Bass Drum 1",
    "Side Stick", "Acoustic Snare",
    "Hand Clap", "Electric Snare",
    "Low Floor Tom", "Closed High Hat",
    "High Floor Tom", "Pedal High Hat",
    "Low Tom", "Open High Hat",
    "Low-Mid Tom", "High-Mid Tom",
    "Crash Cymbal 1", "High Tom",
    "Ride Cymbal 1", "Chinese Cymbal",
    "Ride Bell", "Tambourine",
    "Splash Cymbal", "Cowbell",
    "Crash Cymbal 2", "Vibraslap",
    "Ride Cymbal 2", "High Bongo",
    "Low Bongo", "Mute High Conga",
    "Open High Conga", "Low Conga",
    "High Timbale", "Low Timbale",
    "High Agogo", "Low Agogo",
    "Cabasa", "Maracas",
    "Short Whistle", "Long Whistle",
    "Short Guiro", "Long Guiro",
    "Claves", "High Wood Block",
    "Low Wood Block", "Mute Cuica",
    "Open Cuica", "Mute Triangle",
    "Open Triangle"
];

string szUntitled = "(Untitled)";
string szBuffer;
HANDLE hInst;
int cxChar, cyChar;

__gshared wchar[MAX_PATH] szFileName  = 0;
__gshared wchar[MAX_PATH] szTitleName = 0;
__gshared BOOL  bNeedSave;
__gshared DRUM  drum;
__gshared HMENU hMenu;

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static int iTempo = 50, iIndexLast;
    
    HDC hdc;
    int i, x, y;
    PAINTSTRUCT ps;
    POINT  point;
    RECT   rect;
    TCHAR* szError;

    switch (message)
    {
        case WM_CREATE:
            // Initialize DRUM structure
            drum.iMsecPerBeat = 100;
            drum.iVelocity    =  64;
            drum.iNumBeats    =  32;

            DrumSetParams(&drum);

            // Other initialization
            cxChar = LOWORD(GetDialogBaseUnits());
            cyChar = HIWORD(GetDialogBaseUnits());

            GetWindowRect(hwnd, &rect);
            MoveWindow(hwnd, rect.left, rect.top, 77 * cxChar, 29 * cyChar, FALSE);

            hMenu = GetMenu(hwnd);

            // Initialize "Volume" scroll bar
            SetScrollRange(hwnd, SB_HORZ, 1, 127, FALSE);
            SetScrollPos(hwnd, SB_HORZ, drum.iVelocity, TRUE);

            // Initialize "Tempo" scroll bar
            SetScrollRange(hwnd, SB_VERT, 0, 100, FALSE);
            SetScrollPos(hwnd, SB_VERT, iTempo, TRUE);

            DoCaption(hwnd, to!string(fromWStringz(szTitleName.ptr)));
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDM_FILE_NEW:

                    if (bNeedSave && IDCANCEL == AskAboutSave(hwnd, to!string(fromWStringz(szTitleName.ptr))))
                        return 0;

                    // Clear drum pattern
                    for (i = 0; i < NUM_PERC; i++)
                    {
                        drum.dwSeqPerc [i] = 0;
                        drum.dwSeqPian [i] = 0;
                    }

                    InvalidateRect(hwnd, NULL, FALSE);
                    DrumSetParams(&drum);
                    bNeedSave = FALSE;
                    return 0;

                case IDM_FILE_OPEN:
                    // Save previous file
                    if (bNeedSave && IDCANCEL == AskAboutSave(hwnd, to!string(fromWStringz(szTitleName.ptr))))
                        return 0;

                    szFileName = 0;
                    szTitleName = 0;
                    
                    // Open a drm file
                    if (DrumFileOpenDlg(hwnd, szFileName.ptr, szTitleName.ptr))
                    {
                        szError = DrumFileRead(&drum, szFileName.ptr);
                        if (szError != NULL)
                        {
                            ErrorMessage(hwnd, to!string(fromWStringz(szError)), to!string(fromWStringz(szTitleName.ptr)));
                            szTitleName[0] = 0;
                        }
                        else
                        {
                            // Set new parameters
                            iTempo = cast(int)(50 * (log10(drum.iMsecPerBeat) - 1));

                            SetScrollPos(hwnd, SB_VERT, iTempo, TRUE);
                            SetScrollPos(hwnd, SB_HORZ, drum.iVelocity, TRUE);
                            
                            DrumSetParams(&drum);
                            InvalidateRect(hwnd, NULL, FALSE);
                            bNeedSave = FALSE;
                        }

                        DoCaption(hwnd, to!string(fromWStringz(szTitleName.ptr)));
                    }

                    return 0;

                case IDM_FILE_SAVE:
                case IDM_FILE_SAVE_AS:
                    // Save the selected file
                    if ((LOWORD(wParam) == IDM_FILE_SAVE && szTitleName[0]) ||
                        DrumFileSaveDlg(hwnd, szFileName.ptr, szTitleName.ptr))
                    {
                        szError = DrumFileWrite(&drum, szFileName.ptr);

                        if (szError != NULL)
                        {
                            ErrorMessage(hwnd, to!string(fromWStringz(szError)), to!string(fromWStringz(szTitleName.ptr)));
                            szTitleName[0] = 0;
                        }
                        else
                            bNeedSave = FALSE;

                        DoCaption(hwnd, to!string(fromWStringz(szTitleName.ptr)));
                    }

                    return 0;

                case IDM_APP_EXIT:
                    SendMessage(hwnd, WM_SYSCOMMAND, SC_CLOSE, 0L);
                    return 0;

                case IDM_SEQUENCE_RUNNING:
                    // Begin sequence
                    if (!DrumBeginSequence(hwnd))
                    {
                        ErrorMessage(hwnd,
                                     "Could not start MIDI sequence -- MIDI Mapper device is unavailable!",
                                     to!string(fromWStringz(szTitleName.ptr)));
                    }
                    else
                    {
                        CheckMenuItem(hMenu, IDM_SEQUENCE_RUNNING, MF_CHECKED);
                        CheckMenuItem(hMenu, IDM_SEQUENCE_STOPPED, MF_UNCHECKED);
                    }

                    return 0;

                case IDM_SEQUENCE_STOPPED:
                    // Finish at end of sequence
                    DrumEndSequence(FALSE);
                    return 0;

                case IDM_APP_ABOUT:
                    DialogBox(hInst, "AboutBox", hwnd, &AboutProc);
                    return 0;
                
                default:
            }

            return 0;

        case WM_LBUTTONDOWN:
        case WM_RBUTTONDOWN:
            hdc = GetDC(hwnd);

            // Convert mouse coordinates to grid coordinates
            x =     LOWORD(lParam) / cxChar - 40;
            y = 2 * HIWORD(lParam) / cyChar - 2;

            // Set a new number of beats of sequence
            if (x > 0 && x <= 32 && y < 0)
            {
                SetTextColor(hdc, RGB(255, 255, 255));
                TextOut(hdc, (40 + drum.iNumBeats) * cxChar, 0, ":|", 2);
                SetTextColor(hdc, RGB(0, 0, 0));

                if (drum.iNumBeats % 4 == 0)
                    TextOut(hdc, (40 + drum.iNumBeats) * cxChar, 0, ".", 1);

                drum.iNumBeats = cast(short)x;

                TextOut(hdc, (40 + drum.iNumBeats) * cxChar, 0, ":|", 2);

                bNeedSave = TRUE;
            }

            // Set or reset a percussion instrument beat
            if (x >= 0 && x < 32 && y >= 0 && y < NUM_PERC)
            {
                if (message == WM_LBUTTONDOWN)
                    drum.dwSeqPerc[y] ^= (1 << x);
                else
                    drum.dwSeqPian[y] ^= (1 << x);

                DrawRectangle(hdc, x, y, drum.dwSeqPerc.ptr, drum.dwSeqPian.ptr);

                bNeedSave = TRUE;
            }

            ReleaseDC(hwnd, hdc);
            DrumSetParams(&drum);
            return 0;

        case WM_HSCROLL:
            // Change the note velocity
            switch (LOWORD(wParam))
            {
                case SB_LINEUP:
                    drum.iVelocity -= 1;  break;

                case SB_LINEDOWN:
                    drum.iVelocity += 1;  break;

                case SB_PAGEUP:
                    drum.iVelocity -= 8;  break;

                case SB_PAGEDOWN:
                    drum.iVelocity += 8;  break;

                case SB_THUMBPOSITION:
                    drum.iVelocity = HIWORD(wParam);
                    break;

                default:
                    return 0;
            }

            drum.iVelocity = cast(short)max(1, min(drum.iVelocity, 127));
            SetScrollPos(hwnd, SB_HORZ, drum.iVelocity, TRUE);
            DrumSetParams(&drum);
            bNeedSave = TRUE;
            return 0;

        case WM_VSCROLL:
            // Change the tempo
            switch (LOWORD(wParam))
            {
                case SB_LINEUP:
                    iTempo -=  1;  break;

                case SB_LINEDOWN:
                    iTempo +=  1;  break;

                case SB_PAGEUP:
                    iTempo -= 10;  break;

                case SB_PAGEDOWN:
                    iTempo += 10;  break;

                case SB_THUMBPOSITION:
                    iTempo = HIWORD(wParam);
                    break;

                default:
                    return 0;
            }

            iTempo = max(0, min(iTempo, 100));
            SetScrollPos(hwnd, SB_VERT, iTempo, TRUE);

            drum.iMsecPerBeat = cast(WORD)(10 * pow(100, iTempo / 100.0));

            DrumSetParams(&drum);
            bNeedSave = TRUE;
            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            SetTextAlign(hdc, TA_UPDATECP);
            SetBkMode(hdc, TRANSPARENT);

            // Draw the text strings and horizontal lines
            for (i = 0; i < NUM_PERC; i++)
            {
                MoveToEx(hdc, i & 1 ? 20 * cxChar : cxChar,
                         (2 * i + 3) * cyChar / 4, NULL);

                TextOut(hdc, 0, 0, szPerc[i].toUTF16z, szPerc[i].count);

                GetCurrentPositionEx(hdc, &point);

                MoveToEx(hdc, point.x + cxChar, point.y + cyChar / 2, NULL);
                LineTo(hdc, 39 * cxChar, point.y + cyChar / 2);
            }

            SetTextAlign(hdc, 0);

            // Draw rectangular grid, repeat mark, and beat marks
            for (x = 0; x < 32; x++)
            {
                for (y = 0; y < NUM_PERC; y++)
                    DrawRectangle(hdc, x, y, drum.dwSeqPerc.ptr, drum.dwSeqPian.ptr);

                SetTextColor(hdc, x == drum.iNumBeats - 1 ?
                             RGB(0, 0, 0) : RGB(255, 255, 255));

                TextOut(hdc, (41 + x) * cxChar, 0, ":|", 2);

                SetTextColor(hdc, RGB(0, 0, 0));

                if (x % 4 == 0)
                    TextOut(hdc, (40 + x) * cxChar, 0, ".", 1);
            }

            EndPaint(hwnd, &ps);
            return 0;

        case WM_USER_NOTIFY:
            // Draw the "bouncing ball"
            hdc = GetDC(hwnd);

            SelectObject(hdc, GetStockObject(NULL_PEN));
            SelectObject(hdc, GetStockObject(WHITE_BRUSH));

            for (i = 0; i < 2; i++)
            {
                x = iIndexLast;
                y = NUM_PERC + 1;

                Ellipse(hdc, (x + 40) * cxChar, (2 * y + 3) * cyChar / 4,
                        (x + 41) * cxChar, (2 * y + 5) * cyChar / 4);

                iIndexLast = wParam;
                SelectObject(hdc, GetStockObject(BLACK_BRUSH));
            }

            ReleaseDC(hwnd, hdc);
            return 0;

        case WM_USER_ERROR:
            ErrorMessage(hwnd, "Can't set timer event for tempo",
                         to!string(fromWStringz(szTitleName.ptr)));
            goto case;
        
        case WM_USER_FINISHED:
            DrumEndSequence(TRUE);
            CheckMenuItem(hMenu, IDM_SEQUENCE_RUNNING, MF_UNCHECKED);
            CheckMenuItem(hMenu, IDM_SEQUENCE_STOPPED, MF_CHECKED);
            return 0;

        case WM_CLOSE:
            if (!bNeedSave || IDCANCEL != AskAboutSave(hwnd, to!string(fromWStringz(szTitleName.ptr))))
                DestroyWindow(hwnd);

            return 0;

        case WM_QUERYENDSESSION:
            if (!bNeedSave || IDCANCEL != AskAboutSave(hwnd, to!string(fromWStringz(szTitleName.ptr))))
                return 1L;

            return 0;

        case WM_DESTROY:
            DrumEndSequence(TRUE);
            PostQuitMessage(0);
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern (Windows)
BOOL AboutProc(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
        case WM_INITDIALOG:
            return TRUE;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDOK:
                    EndDialog(hDlg, 0);
                    return TRUE;
                
                default:
            }

            break;
            
        default:
    }

    return FALSE;
}

void DrawRectangle(HDC hdc, int x, int y, DWORD* dwSeqPerc, DWORD* dwSeqPian)
{
    int iBrush;

    if (dwSeqPerc[y] & dwSeqPian[y] & (1L << x))
        iBrush = BLACK_BRUSH;

    else if (dwSeqPerc [y] & (1L << x))
        iBrush = DKGRAY_BRUSH;

    else if (dwSeqPian [y] & (1L << x))
        iBrush = LTGRAY_BRUSH;

    else
        iBrush = WHITE_BRUSH;

    SelectObject(hdc, GetStockObject(iBrush));

    Rectangle(hdc, (x + 40) * cxChar, (2 * y + 4) * cyChar / 4,
             (x + 41) * cxChar + 1, (2 * y + 6) * cyChar / 4 + 1);
}

wstring fromWStringz(const wchar* s)
{
    if (s is null) return null;

    wchar* ptr;
    for (ptr = cast(wchar*)s; *ptr; ++ptr) {}

    return to!wstring(s[0..ptr-s]);
}

void ErrorMessage(HWND hwnd, string szError, string szTitleName)
{
    szBuffer = format(szError, (szTitleName.length ? szTitleName : szUntitled));
    MessageBeep(MB_ICONEXCLAMATION);
    MessageBox(hwnd, szBuffer.toUTF16z, appName.toUTF16z, MB_OK | MB_ICONEXCLAMATION);
}

void DoCaption(HWND hwnd, string szTitleName)
{
    szBuffer = format("MIDI Drum Machine - %s", (szTitleName.length ? szTitleName : szUntitled));
    SetWindowText(hwnd, szBuffer.toUTF16z);
}

int AskAboutSave(HWND hwnd, string szTitleName)
{
    int iReturn;
    
    szBuffer = format("Save current changes in %s?", (szTitleName.length ? szTitleName : szUntitled));
    iReturn = MessageBox(hwnd, szBuffer.toUTF16z, appName.toUTF16z, MB_YESNOCANCEL | MB_ICONQUESTION);

    if (iReturn == IDYES)
    {
        if (!SendMessage(hwnd, WM_COMMAND, IDM_FILE_SAVE, 0))
            iReturn = IDCANCEL;
    }

    return iReturn;
}
