module ThemedSimpleWakeUp;

// Same as ThemedWakeUp, except it uses a precompiled manifest file.

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
pragma(lib, "comctl32.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.commdlg;
import win32.mmsystem;
import win32.commctrl;

string appName     = "WakeUp";
string description = "WakeUp";
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
    wndclass.hbrBackground = cast(HBRUSH) GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = appName.toUTF16z;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass))
    {
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

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

// ID values for 3 child windows
enum ID_TIMEPICK = 0;
enum ID_CHECKBOX = 1;
enum ID_PUSHBTN  = 2;

// Timer ID
enum ID_TIMER = 1;

// Number of 100-nanosecond increments (ie FILETIME ticks) in an hour
enum FTTICKSPERHOUR = (60 * 60 * cast(LONGLONG)10000000);

// Defines and structure for waveform "file"
enum SAMPRATE  = 11025;
enum NUMSAMPS  = (3 * SAMPRATE);
enum HALFSAMPS = (NUMSAMPS / 2);

struct WAVEFORM
{
    char[4] chRiff;
    DWORD dwRiffSize;
    char[4] chWave;
    char[4] chFmt;
    DWORD dwFmtSize;
    PCMWAVEFORMAT pwf;
    char[4] chData;
    DWORD dwDataSize;
    BYTE[HALFSAMPS] byData;
}

// Original window procedure addresses for the subclassed windows
WNDPROC[3] SubbedProc;

// The current child window with the input focus
HWND hwndFocus;

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static HWND hwndDTP, hwndCheck, hwndPush;
    static WAVEFORM waveform = WAVEFORM("RIFF", NUMSAMPS + 0x24, "WAVE", "fmt ",
                                  PCMWAVEFORMAT.sizeof, PCMWAVEFORMAT(WAVEFORMAT(1, 1, SAMPRATE,
                                  SAMPRATE, 1), 8), "data", NUMSAMPS);
    FILETIME  ft;
    HINSTANCE hInstance;
    INITCOMMONCONTROLSEX icex;
    int i, cxChar, cyChar;
    LARGE_INTEGER li;
    SYSTEMTIME st;

    switch (message)
    {
        case WM_CREATE:
            // Some initialization stuff

            hInstance = cast(HINSTANCE)GetWindowLongPtr(hwnd, GWL_HINSTANCE);

            icex.dwSize = icex.sizeof;
            icex.dwICC  = ICC_DATE_CLASSES;
            InitCommonControlsEx(&icex);

            // Create the waveform file with alternating square waves
            //~ waveform  = cast(typeof(waveform))GC.malloc(WAVEFORM.sizeof + NUMSAMPS);
            //~ *waveform = waveform;

            for (i = 0; i < HALFSAMPS; i++)
            {
                if (i % 600 < 300)
                {
                    if (i % 16 < 8)
                        waveform.byData[i] = 25;
                    else
                        waveform.byData[i] = 230;
                }
                else if (i % 8 < 4)
                    waveform.byData[i] = 25;
                else
                    waveform.byData[i] = 230;
            }

            // Get character size and set a fixed window size.
            cxChar = LOWORD(GetDialogBaseUnits());
            cyChar = HIWORD(GetDialogBaseUnits());

            SetWindowPos(hwnd, NULL, 0, 0,
                         42 * cxChar,
                         10 * cyChar / 3 + 2 * GetSystemMetrics(SM_CYBORDER) +
                         GetSystemMetrics(SM_CYCAPTION),
                         SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);

            // Create the three child windows
            hwndDTP = CreateWindow((DATETIMEPICK_CLASS ~ 0).ptr, "",
                                   WS_BORDER | WS_CHILD | WS_VISIBLE | DTS_TIMEFORMAT,
                                   2 * cxChar, cyChar, 12 * cxChar, 4 * cyChar / 3,
                                   hwnd, cast(HMENU)ID_TIMEPICK, hInstance, NULL);

            hwndCheck = CreateWindow("Button", "Set Alarm",
                                     WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
                                     16 * cxChar, cyChar, 12 * cxChar, 4 * cyChar / 3,
                                     hwnd, cast(HMENU)ID_CHECKBOX, hInstance, NULL);

            hwndPush = CreateWindow("Button", "Turn Off",
                                    WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON | WS_DISABLED,
                                    28 * cxChar, cyChar, 12 * cxChar, 4 * cyChar / 3,
                                    hwnd, cast(HMENU)ID_PUSHBTN, hInstance, NULL);

            hwndFocus = hwndDTP;

            // Subclass the three child windows
            SubbedProc[ID_TIMEPICK] = cast(WNDPROC)SetWindowLongPtr(hwndDTP, GWL_WNDPROC, cast(LONG)&SubProc);
            SubbedProc[ID_CHECKBOX] = cast(WNDPROC)SetWindowLongPtr(hwndCheck, GWL_WNDPROC, cast(LONG)&SubProc);
            SubbedProc[ID_PUSHBTN]  = cast(WNDPROC)SetWindowLongPtr(hwndPush, GWL_WNDPROC, cast(LONG)&SubProc);

            // Set the date and time picker control to the current time
            // plus 9 hours, rounded down to next lowest hour
            GetLocalTime(&st);
            SystemTimeToFileTime(&st, &ft);
            li = *cast(LARGE_INTEGER*) & ft;
            li.QuadPart += 9 * FTTICKSPERHOUR;
            ft = *cast(FILETIME*) & li;
            FileTimeToSystemTime(&ft, &st);
            st.wMinute = st.wSecond = st.wMilliseconds = 0;
            
            SendMessage(hwndDTP, DTM_SETSYSTEMTIME, 0, cast(LPARAM)&st);
            return 0;

        case WM_SETFOCUS:
            SetFocus(hwndFocus);
            return 0;

        case WM_COMMAND:

            switch (LOWORD(wParam))     // control ID
            {
                case ID_CHECKBOX:

                    // When the user checks the "Set Alarm" button, get the
                    // time in the date and time control and subtract from
                    // it the current PC time.

                    if (SendMessage(hwndCheck, BM_GETCHECK, 0, 0))
                    {
                        SendMessage(hwndDTP, DTM_GETSYSTEMTIME, 0, cast(LPARAM)&st);
                        SystemTimeToFileTime(&st, &ft);
                        li = *cast(LARGE_INTEGER*)&ft;

                        GetLocalTime(&st);
                        SystemTimeToFileTime(&st, &ft);
                        li.QuadPart -= (cast(LARGE_INTEGER*)&ft).QuadPart;

                        // Make sure the time is between 0 and 24 hours!
                        // These little adjustments let us completely ignore
                        // the date part of the SYSTEMTIME structures.

                        while (li.QuadPart < 0)
                            li.QuadPart += 24 * FTTICKSPERHOUR;

                        li.QuadPart %= 24 * FTTICKSPERHOUR;

                        // Set a one-shot timer! (See you in the morning.)

                        SetTimer(hwnd, ID_TIMER, cast(int)(li.QuadPart / 10000), null);
                    }
                    else
                    {
                        // If button is being unchecked, kill the timer.
                        KillTimer(hwnd, ID_TIMER);
                    }

                    return 0;

                // The "Turn Off" button turns off the ringing alarm, and also
                // unchecks the "Set Alarm" button and disables itself.
                case ID_PUSHBTN:
                    PlaySound(NULL, NULL, 0);
                    SendMessage(hwndCheck, BM_SETCHECK, 0, 0);
                    EnableWindow(hwndDTP, TRUE);
                    EnableWindow(hwndCheck, TRUE);
                    EnableWindow(hwndPush, FALSE);
                    SetFocus(hwndDTP);
                    return 0;
                
                default:
            }

            return 0;

        // The WM_NOTIFY message comes from the date and time picker.
        // If the user has checked "Set Alarm" and then gone back to
        // change the alarm time, there might be a discrepancy between
        // the displayed time and the one-shot timer. So the program
        // unchecks "Set Alarm" and kills any outstanding timer.
        case WM_NOTIFY:

            switch (wParam)        // control ID
            {
                case ID_TIMEPICK:

                    switch ((cast(NMHDR*)lParam).code)    // notification code
                    {
                        case DTN_DATETIMECHANGE:

                            if (SendMessage(hwndCheck, BM_GETCHECK, 0, 0))
                            {
                                KillTimer(hwnd, ID_TIMER);
                                SendMessage(hwndCheck, BM_SETCHECK, 0, 0);
                            }

                            return 0;
                            
                        default:
                    }
                    break;
                    
                default:
            }

            return 0;

        // The WM_COMMAND message comes from the two buttons.

        case WM_TIMER:

            // When the timer message comes, kill the timer (because we only
            // want a one-shot) and start the annoying alarm noise going.

            KillTimer(hwnd, ID_TIMER);
            PlaySound(cast(PTSTR)&waveform, NULL,
                      SND_MEMORY | SND_LOOP | SND_ASYNC);

            // Let the sleepy user turn off the timer by slapping the
            // space bar. If the window is minimized, it's restored; then it's
            // brought to the forefront; then the pushbutton is enabled and
            // given the input focus.
            EnableWindow(hwndDTP, FALSE);
            EnableWindow(hwndCheck, FALSE);
            EnableWindow(hwndPush, TRUE);

            hwndFocus = hwndPush;
            ShowWindow(hwnd, SW_RESTORE);
            SetForegroundWindow(hwnd);
            return 0;

        // Clean up if the alarm is ringing or the timer is still set.
        case WM_DESTROY:
            //~ GC.free(waveform);

            if (IsWindowEnabled(hwndPush))
                PlaySound(NULL, NULL, 0);

            if (SendMessage(hwndCheck, BM_GETCHECK, 0, 0))
                KillTimer(hwnd, ID_TIMER);

            PostQuitMessage(0);
            return 0;
            
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

extern (Windows)
LRESULT SubProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    int idNext, id = GetWindowLongPtr(hwnd, GWL_ID);

    switch (message)
    {
        case WM_CHAR:

            if (wParam == '\t')
            {
                idNext = id;

                do
                {
                    idNext = (idNext + (GetKeyState(VK_SHIFT) < 0 ? 2 : 1)) % 3;
                }
                while (!IsWindowEnabled(GetDlgItem(GetParent(hwnd), idNext)));

                SetFocus(GetDlgItem(GetParent(hwnd), idNext));
                return 0;
            }

            break;

        case WM_SETFOCUS:
            hwndFocus = hwnd;
            break;
        
        default:
    }

    return CallWindowProc(SubbedProc[id], hwnd, message, wParam, lParam);
}
