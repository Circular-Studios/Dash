/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module KBMidi;

import core.memory;
import core.runtime;
import core.thread;
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

string appName     = "KBMidi";
string description = "Keyboard MIDI Player";
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

enum IDM_OPEN    = 0x100;
enum IDM_CLOSE   = 0x101;
enum IDM_DEVICE  = 0x200;
enum IDM_CHANNEL = 0x300;
enum IDM_VOICE   = 0x400;

HMIDIOUT hMidiOut;
int iDevice = MIDIMAPPER, iChannel = 0, iVoice = 0, iVelocity = 64;
int cxCaps, cyChar, xOffset, yOffset;

// Structures and data for showing families and instruments on menu
struct INSTRUMENT
{
    string szInst;
    int iVoice;
}

struct FAMILY
{
    string szFam;
    INSTRUMENT[8] inst;
}

FAMILY[16] fam =
[
    FAMILY("Piano",
           [INSTRUMENT("Acoustic Grand Piano", 0),
            INSTRUMENT("Bright Acoustic Piano", 1),
            INSTRUMENT("Electric Grand Piano", 2),
            INSTRUMENT("Honky-tonk Piano", 3),
            INSTRUMENT("Rhodes Piano", 4),
            INSTRUMENT("Chorused Piano", 5),
            INSTRUMENT("Harpsichord", 6),
            INSTRUMENT("Clavinet", 7)]),

    FAMILY("Chromatic Percussion",
           [INSTRUMENT("Celesta", 8),
            INSTRUMENT("Glockenspiel", 9),
            INSTRUMENT("Music Box", 10),
            INSTRUMENT("Vibraphone", 11),
            INSTRUMENT("Marimba", 12),
            INSTRUMENT("Xylophone", 13),
            INSTRUMENT("Tubular Bells", 14),
            INSTRUMENT("Dulcimer", 15)]),

    FAMILY("Organ",
           [INSTRUMENT("Hammond Organ", 16),
            INSTRUMENT("Percussive Organ", 17),
            INSTRUMENT("Rock Organ", 18),
            INSTRUMENT("Church Organ", 19),
            INSTRUMENT("Reed Organ", 20),
            INSTRUMENT("Accordian", 21),
            INSTRUMENT("Harmonica", 22),
            INSTRUMENT("Tango Accordian", 23)]),

    FAMILY("Guitar",
           [INSTRUMENT("Acoustic Guitar (nylon)", 24),
            INSTRUMENT("Acoustic Guitar (steel)", 25),
            INSTRUMENT("Electric Guitar (jazz)", 26),
            INSTRUMENT("Electric Guitar (clean)", 27),
            INSTRUMENT("Electric Guitar (muted)", 28),
            INSTRUMENT("Overdriven Guitar", 29),
            INSTRUMENT("Distortion Guitar", 30),
            INSTRUMENT("Guitar Harmonics", 31)]),

    FAMILY("Bass",
           [INSTRUMENT("Acoustic Bass", 32),
            INSTRUMENT("Electric Bass (finger)", 33),
            INSTRUMENT("Electric Bass (pick)", 34),
            INSTRUMENT("Fretless Bass", 35),
            INSTRUMENT("Slap Bass 1", 36),
            INSTRUMENT("Slap Bass 2", 37),
            INSTRUMENT("Synth Bass 1", 38),
            INSTRUMENT("Synth Bass 2", 39)]),

    FAMILY("Strings",
           [INSTRUMENT("Violin", 40),
            INSTRUMENT("Viola", 41),
            INSTRUMENT("Cello", 42),
            INSTRUMENT("Contrabass", 43),
            INSTRUMENT("Tremolo Strings", 44),
            INSTRUMENT("Pizzicato Strings", 45),
            INSTRUMENT("Orchestral Harp", 46),
            INSTRUMENT("Timpani", 47)]),

    FAMILY("Ensemble",
           [INSTRUMENT("String Ensemble 1", 48),
            INSTRUMENT("String Ensemble 2", 49),
            INSTRUMENT("Synth Strings 1", 50),
            INSTRUMENT("Synth Strings 2", 51),
            INSTRUMENT("Choir Aahs", 52),
            INSTRUMENT("Voice Oohs", 53),
            INSTRUMENT("Synth Voice", 54),
            INSTRUMENT("Orchestra Hit", 55)]),

    FAMILY("Brass",
           [INSTRUMENT("Trumpet", 56),
            INSTRUMENT("Trombone", 57),
            INSTRUMENT("Tuba", 58),
            INSTRUMENT("Muted Trumpet", 59),
            INSTRUMENT("French Horn", 60),
            INSTRUMENT("Brass Section", 61),
            INSTRUMENT("Synth Brass 1", 62),
            INSTRUMENT("Synth Brass 2", 63)]),

    FAMILY("Reed",
           [INSTRUMENT("Soprano Sax", 64),
            INSTRUMENT("Alto Sax", 65),
            INSTRUMENT("Tenor Sax", 66),
            INSTRUMENT("Baritone Sax", 67),
            INSTRUMENT("Oboe", 68),
            INSTRUMENT("English Horn", 69),
            INSTRUMENT("Bassoon", 70),
            INSTRUMENT("Clarinet", 71)]),

    FAMILY("Pipe",
           [INSTRUMENT("Piccolo", 72),
            INSTRUMENT("Flute", 73),
            INSTRUMENT("Recorder", 74),
            INSTRUMENT("Pan Flute", 75),
            INSTRUMENT("Bottle Blow", 76),
            INSTRUMENT("Shakuhachi", 77),
            INSTRUMENT("Whistle", 78),
            INSTRUMENT("Ocarina", 79)]),

    FAMILY("Synth Lead",
           [INSTRUMENT("Lead 1 (square)", 80),
            INSTRUMENT("Lead 2 (sawtooth)", 81),
            INSTRUMENT("Lead 3 (caliope lead)", 82),
            INSTRUMENT("Lead 4 (chiff lead)", 83),
            INSTRUMENT("Lead 5 (charang)", 84),
            INSTRUMENT("Lead 6 (voice)", 85),
            INSTRUMENT("Lead 7 (fifths)", 86),
            INSTRUMENT("Lead 8 (brass + lead)", 87)]),

    FAMILY("Synth Pad",
           [INSTRUMENT("Pad 1 (new age)", 88),
            INSTRUMENT("Pad 2 (warm)", 89),
            INSTRUMENT("Pad 3 (polysynth)", 90),
            INSTRUMENT("Pad 4 (choir)", 91),
            INSTRUMENT("Pad 5 (bowed)", 92),
            INSTRUMENT("Pad 6 (metallic)", 93),
            INSTRUMENT("Pad 7 (halo)", 94),
            INSTRUMENT("Pad 8 (sweep)", 95)]),

    FAMILY("Synth Effects",
           [INSTRUMENT("FX 1 (rain)", 96),
            INSTRUMENT("FX 2 (soundtrack)", 97),
            INSTRUMENT("FX 3 (crystal)", 98),
            INSTRUMENT("FX 4 (atmosphere)", 99),
            INSTRUMENT("FX 5 (brightness)", 100),
            INSTRUMENT("FX 6 (goblins)", 101),
            INSTRUMENT("FX 7 (echoes)", 102),
            INSTRUMENT("FX 8 (sci-fi)", 103)]),

    FAMILY("Ethnic",
           [INSTRUMENT("Sitar", 104),
            INSTRUMENT("Banjo", 105),
            INSTRUMENT("Shamisen", 106),
            INSTRUMENT("Koto", 107),
            INSTRUMENT("Kalimba", 108),
            INSTRUMENT("Bagpipe", 109),
            INSTRUMENT("Fiddle", 110),
            INSTRUMENT("Shanai", 111)]),

    FAMILY("Percussive",
           [INSTRUMENT("Tinkle Bell", 112),
            INSTRUMENT("Agogo", 113),
            INSTRUMENT("Steel Drums", 114),
            INSTRUMENT("Woodblock", 115),
            INSTRUMENT("Taiko Drum", 116),
            INSTRUMENT("Melodic Tom", 117),
            INSTRUMENT("Synth Drum", 118),
            INSTRUMENT("Reverse Cymbal", 119)]),

    FAMILY("Sound Effects",
           [INSTRUMENT("Guitar Fret Noise", 120),
            INSTRUMENT("Breath Noise", 121),
            INSTRUMENT("Seashore", 122),
            INSTRUMENT("Bird Tweet", 123),
            INSTRUMENT("Telephone Ring", 124),
            INSTRUMENT("Helicopter", 125),
            INSTRUMENT("Applause", 126),
            INSTRUMENT("Gunshot", 127)])
];

// Data for translating scan codes to octaves and notes
struct Key
{
    int iOctave;
    int iNote;
    int yPos;
    int xPos;
    string szKey;
}

Key[] key =
[
    // Scan  Char  Oct  Note
    // ----  ----  ---  ----
    Key(-1, -1, -1, -1, null),      //   0   None
    Key(-1, -1, -1, -1, null),      //   1   Esc
    Key(-1, -1, 0, 0, ""),          //   2     1
    Key(5, 1, 0, 2, "C#"),          //   3     2    5    C#
    Key(5, 3, 0, 4, "D#"),          //   4     3    5    D#
    Key(-1, -1, 0, 6, ""),          //   5     4
    Key(5, 6, 0, 8, "F#"),          //   6     5    5    F#
    Key(5, 8, 0, 10, "G#"),         //   7     6    5    G#
    Key(5, 10, 0, 12, "A#"),        //   8     7    5    A#
    Key(-1, -1, 0, 14, ""),         //   9     8
    Key(6, 1, 0, 16, "C#"),         //  10     9    6    C#
    Key(6, 3, 0, 18, "D#"),         //  11     0    6    D#
    Key(-1, -1, 0, 20, ""),         //  12     -
    Key(6, 6, 0, 22, "F#"),         //  13     =    6    F#
    Key(-1, -1, -1, -1, null),      //  14    Back

    Key(-1, -1, -1, -1, null),      //  15    Tab
    Key(5, 0, 1, 1, "C"),           //  16     q    5    C
    Key(5, 2, 1, 3, "D"),           //  17     w    5    D
    Key(5, 4, 1, 5, "E"),           //  18     e    5    E
    Key(5, 5, 1, 7, "F"),           //  19     r    5    F
    Key(5, 7, 1, 9, "G"),           //  20     t    5    G
    Key(5, 9, 1, 11, "A"),          //  21     y    5    A
    Key(5, 11, 1, 13, "B"),         //  22     u    5    B
    Key(6, 0, 1, 15, "C"),          //  23     i    6    C
    Key(6, 2, 1, 17, "D"),          //  24     o    6    D
    Key(6, 4, 1, 19, "E"),          //  25     p    6    E
    Key(6, 5, 1, 21, "F"),          //  26     [    6    F
    Key(6, 7, 1, 23, "G"),          //  27     ]    6    G
    Key(-1, -1, -1, -1, null),      //  28    Ent

    Key(-1, -1, -1, -1, null),      //  29    Ctrl
    Key(3, 8, 2, 2, "G#"),          //  30     a    3    G#
    Key(3, 10, 2, 4, "A#"),         //  31     s    3    A#
    Key(-1, -1, 2, 6, ""),          //  32     d
    Key(4, 1, 2, 8, "C#"),          //  33     f    4    C#
    Key(4, 3, 2, 10, "D#"),         //  34     g    4    D#
    Key(-1, -1, 2, 12, ""),         //  35     h
    Key(4, 6, 2, 14, "F#"),         //  36     j    4    F#
    Key(4, 8, 2, 16, "G#"),         //  37     k    4    G#
    Key(4, 10, 2, 18, "A#"),        //  38     l    4    A#
    Key(-1, -1, 2, 20, ""),         //  39     ;
    Key(5, 1, 2, 22, "C#"),         //  40     '    5    C#
    Key(-1, -1, -1, -1, null),      //  41     `

    Key(-1, -1, -1, -1, null),      //  42    Shift
    Key(-1, -1, -1, -1, null),      //  43     \  (not line continuation)
    Key(3, 9, 3, 3, "A"),           //  44     z    3    A
    Key(3, 11, 3, 5, "B"),          //  45     x    3    B
    Key(4, 0, 3, 7, "C"),           //  46     c    4    C
    Key(4, 2, 3, 9, "D"),           //  47     v    4    D
    Key(4, 4, 3, 11, "E"),          //  48     b    4    E
    Key(4, 5, 3, 13, "F"),          //  49     n    4    F
    Key(4, 7, 3, 15, "G"),          //  50     m    4    G
    Key(4, 9, 3, 17, "A"),          //  51     ,    4    A
    Key(4, 11, 3, 19, "B"),         //  52     .    4    B
    Key(5, 0, 3, 21, "C")           //  53     /    5    C
];


// Create the program's menu (called from WndProc, WM_CREATE)
HMENU CreateTheMenu(int iNumDevs)
{
    string szBuffer;
    HMENU hMenu, hMenuPopup, hMenuSubPopup;
    int i, iFam, iIns;
    MIDIOUTCAPS moc;

    hMenu = CreateMenu();

    // Create "On/Off" popup menu
    hMenuPopup = CreateMenu();

    AppendMenu(hMenuPopup, MF_STRING, IDM_OPEN, "&Open");
    AppendMenu(hMenuPopup, MF_STRING | MF_CHECKED, IDM_CLOSE, "&Closed");

    AppendMenu(hMenu, MF_STRING | MF_POPUP, cast(UINT)hMenuPopup, "&Status");

    // Create "Device" popup menu
    hMenuPopup = CreateMenu();

    // Put MIDI Mapper on menu if it's installed
    if (!midiOutGetDevCaps(MIDIMAPPER, &moc, moc.sizeof))
        AppendMenu(hMenuPopup, MF_STRING, IDM_DEVICE + cast(int)MIDIMAPPER, moc.szPname.ptr);
    else
        iDevice = 0;

    // Add the rest of the MIDI devices
    for (i = 0; i < iNumDevs; i++)
    {
        midiOutGetDevCaps(i, &moc, moc.sizeof);
        AppendMenu(hMenuPopup, MF_STRING, IDM_DEVICE + i, moc.szPname.ptr);
    }

    CheckMenuItem(hMenuPopup, 0, MF_BYPOSITION | MF_CHECKED);
    AppendMenu(hMenu, MF_STRING | MF_POPUP, cast(UINT)hMenuPopup, "&Device");

    // Create "Channel" popup menu
    hMenuPopup = CreateMenu();

    for (i = 0; i < 16; i++)
    {
        szBuffer = format("%s", i+1);
        AppendMenu(hMenuPopup, MF_STRING | (i ? MF_UNCHECKED : MF_CHECKED), IDM_CHANNEL + i, szBuffer.toUTF16z);
    }

    AppendMenu(hMenu, MF_STRING | MF_POPUP, cast(UINT)hMenuPopup, "&Channel");

    // Create "Voice" popup menu
    hMenuPopup = CreateMenu();

    for (iFam = 0; iFam < 16; iFam++)
    {
        hMenuSubPopup = CreateMenu();

        for (iIns = 0; iIns < 8; iIns++)
        {
            szBuffer = format("&%s,\t%s", iIns + 1, fam[iFam].inst[iIns].szInst);
            AppendMenu(hMenuSubPopup,
                       MF_STRING | (fam[iFam].inst[iIns].iVoice ?
                                    MF_UNCHECKED : MF_CHECKED),
                       fam[iFam].inst[iIns].iVoice + IDM_VOICE,
                       szBuffer.toUTF16z);
        }

        szBuffer = format("&%s.\t%s", cast(char)('A' + iFam), fam[iFam].szFam);
        AppendMenu(hMenuPopup, MF_STRING | MF_POPUP, cast(UINT)hMenuSubPopup, szBuffer.toUTF16z);
    }

    AppendMenu(hMenu, MF_STRING | MF_POPUP, cast(UINT)hMenuPopup, "&Voice");
    return hMenu;
}

// Routines for simplifying MIDI output
DWORD MidiOutMessage(HMIDIOUT hMidi, int iStatus, int iChannel, int iData1, int iData2)
{
    DWORD dwMessage;
    dwMessage = iStatus | iChannel | (iData1 << 8) | (iData2 << 16);
    return midiOutShortMsg(hMidi, dwMessage);
}

DWORD MidiNoteOff(HMIDIOUT hMidi, int iChannel, int iOct, int iNote, int iVel)
{
    return MidiOutMessage(hMidi, 0x080, iChannel, 12 * iOct + iNote, iVel);
}

DWORD MidiNoteOn(HMIDIOUT hMidi, int iChannel, int iOct, int iNote, int iVel)
{
    return MidiOutMessage(hMidi, 0x090, iChannel, 12 * iOct + iNote, iVel);
}

DWORD MidiSetPatch(HMIDIOUT hMidi, int iChannel, int iVoice)
{
    return MidiOutMessage(hMidi, 0x0C0, iChannel, iVoice, 0);
}

DWORD MidiPitchBend(HMIDIOUT hMidi, int iChannel, int iBend)
{
    return MidiOutMessage(hMidi, 0x0E0, iChannel, iBend & 0x7F, iBend >> 7);
}

// Draw a single key on window
VOID DrawKey(HDC hdc, int iScanCode, BOOL fInvert)
{
    RECT rc;

    rc.left   = 3 * cxCaps * key[iScanCode].xPos / 2 + xOffset;
    rc.top    = 3 * cyChar * key[iScanCode].yPos / 2 + yOffset;
    rc.right  = rc.left + 3 * cxCaps;
    rc.bottom = rc.top + 3 * cyChar / 2;

    SetTextColor(hdc, fInvert ? 0x00FF_FFFF : 0x0000_0000);
    SetBkColor(hdc, fInvert ? 0x0000_0000 : 0x00FF_FFFF);

    FillRect(hdc, &rc, GetStockObject(fInvert ? BLACK_BRUSH : WHITE_BRUSH));

    DrawText(hdc, key[iScanCode].szKey.toUTF16z, -1, &rc, DT_SINGLELINE | DT_CENTER | DT_VCENTER);

    FrameRect(hdc, &rc, GetStockObject(BLACK_BRUSH));
}

// Process a Key Up or Key Down message
VOID ProcessKey(HDC hdc, UINT message, LPARAM lParam)
{
    int iScanCode, iOctave, iNote;

    iScanCode = 0x0FF & HIWORD(lParam);

    if (iScanCode >= key.length)                        // No scan codes over 53
        return;

    if ((iOctave = key[iScanCode].iOctave) == -1)     // Non-music key
        return;

    if (GetKeyState(VK_SHIFT) < 0)
        iOctave += 0x20000000 & lParam ? 2 : 1;

    if (GetKeyState(VK_CONTROL) < 0)
        iOctave -= 0x20000000 & lParam ? 2 : 1;

    iNote = key[iScanCode].iNote;

    if (message == WM_KEYUP)                            // For key up
    {
        MidiNoteOff(hMidiOut, iChannel, iOctave, iNote, 0);       // Note off
        DrawKey(hdc, iScanCode, FALSE);
        return;
    }

    if (0x40000000 & lParam)                           // ignore typematics
        return;

    MidiNoteOn(hMidiOut, iChannel, iOctave, iNote, iVelocity);    // Note on
    DrawKey(hdc, iScanCode, TRUE);                    // Draw the inverted key
}

extern (Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BOOL bOpened = FALSE;
    HDC hdc;
    HMENU hMenu;
    int i, iNumDevs, iPitchBend, cxClient, cyClient;
    MIDIOUTCAPS moc;
    PAINTSTRUCT ps;
    SIZE  size;
    string szBuffer;

    switch (message)
    {
        case WM_CREATE:
            // Get size of capital letters in system font
            hdc = GetDC(hwnd);

            GetTextExtentPoint(hdc, "M", 1, &size);
            cxCaps = size.cx;
            cyChar = size.cy;

            ReleaseDC(hwnd, hdc);

            // Initialize "Volume" scroll bar
            SetScrollRange(hwnd, SB_HORZ, 1, 127, FALSE);
            SetScrollPos(hwnd, SB_HORZ, iVelocity, TRUE);

            // Initialize "Pitch Bend" scroll bar
            SetScrollRange(hwnd, SB_VERT, 0, 16383, FALSE);
            SetScrollPos(hwnd, SB_VERT, 8192, TRUE);

            // Get number of MIDI output devices and set up menu
            iNumDevs = midiOutGetNumDevs();
            if (iNumDevs == 0)
            {
                MessageBeep(MB_ICONSTOP);
                MessageBox(hwnd, "No MIDI output devices!", appName.toUTF16z, MB_OK | MB_ICONSTOP);
                return -1;
            }

            SetMenu(hwnd, CreateTheMenu(iNumDevs));
            return 0;

        case WM_SIZE:
            cxClient = LOWORD(lParam);
            cyClient = HIWORD(lParam);

            xOffset = (cxClient - 25 * 3 * cxCaps / 2) / 2;
            yOffset = (cyClient - 11 * cyChar) / 2 + 5 * cyChar;
            return 0;

        case WM_COMMAND:
            hMenu = GetMenu(hwnd);

            // "Open" menu command
            if (LOWORD(wParam) == IDM_OPEN && !bOpened)
            {
                if (midiOutOpen(&hMidiOut, iDevice, 0, 0, 0))
                {
                    MessageBeep(MB_ICONEXCLAMATION);
                    MessageBox(hwnd, "Cannot open MIDI device",
                               appName.toUTF16z, MB_OK | MB_ICONEXCLAMATION);
                }
                else
                {
                    CheckMenuItem(hMenu, IDM_OPEN, MF_CHECKED);
                    CheckMenuItem(hMenu, IDM_CLOSE, MF_UNCHECKED);

                    MidiSetPatch(hMidiOut, iChannel, iVoice);
                    bOpened = TRUE;
                }
            }

            // "Close" menu command
            else if (LOWORD(wParam) == IDM_CLOSE && bOpened)
            {
                CheckMenuItem(hMenu, IDM_OPEN, MF_UNCHECKED);
                CheckMenuItem(hMenu, IDM_CLOSE, MF_CHECKED);

                // Turn all keys off and close device
                for (i = 0; i < 16; i++)
                    MidiOutMessage(hMidiOut, 0xB0, i, 123, 0);

                midiOutClose(hMidiOut);
                bOpened = FALSE;
            }

            // Change MIDI "Device" menu command
            else if (LOWORD(wParam) >= IDM_DEVICE - 1 &&
                     LOWORD(wParam) < IDM_CHANNEL)
            {
                CheckMenuItem(hMenu, IDM_DEVICE + iDevice, MF_UNCHECKED);
                iDevice = LOWORD(wParam) - IDM_DEVICE;
                CheckMenuItem(hMenu, IDM_DEVICE + iDevice, MF_CHECKED);

                // Close and reopen MIDI device
                if (bOpened)
                {
                    SendMessage(hwnd, WM_COMMAND, IDM_CLOSE, 0L);
                    SendMessage(hwnd, WM_COMMAND, IDM_OPEN, 0L);
                }
            }

            // Change MIDI "Channel" menu command
            else if (LOWORD(wParam) >= IDM_CHANNEL &&
                     LOWORD(wParam) < IDM_VOICE)
            {
                CheckMenuItem(hMenu, IDM_CHANNEL + iChannel, MF_UNCHECKED);
                iChannel = LOWORD(wParam) - IDM_CHANNEL;
                CheckMenuItem(hMenu, IDM_CHANNEL + iChannel, MF_CHECKED);

                if (bOpened)
                    MidiSetPatch(hMidiOut, iChannel, iVoice);
            }

            // Change MIDI "Voice" menu command
            else if (LOWORD(wParam) >= IDM_VOICE)
            {
                CheckMenuItem(hMenu, IDM_VOICE + iVoice, MF_UNCHECKED);
                iVoice = LOWORD(wParam) - IDM_VOICE;
                CheckMenuItem(hMenu, IDM_VOICE + iVoice, MF_CHECKED);

                if (bOpened)
                    MidiSetPatch(hMidiOut, iChannel, iVoice);
            }

            InvalidateRect(hwnd, NULL, TRUE);
            return 0;

        // Process a Key Up or Key Down message
        case WM_KEYUP:
        case WM_KEYDOWN:
            hdc = GetDC(hwnd);

            if (bOpened)
                ProcessKey(hdc, message, lParam);

            ReleaseDC(hwnd, hdc);
            return 0;

        // For Escape, turn off all notes and repaint
        case WM_CHAR:

            if (bOpened && wParam == 27)
            {
                for (i = 0; i < 16; i++)
                    MidiOutMessage(hMidiOut, 0xB0, i, 123, 0);

                InvalidateRect(hwnd, NULL, TRUE);
            }

            return 0;

        // Horizontal scroll: Velocity
        case WM_HSCROLL:

            switch (LOWORD(wParam))
            {
                case SB_LINEUP:
                    iVelocity -= 1;  break;

                case SB_LINEDOWN:
                    iVelocity += 1;  break;

                case SB_PAGEUP:
                    iVelocity -= 8;  break;

                case SB_PAGEDOWN:
                    iVelocity += 8;  break;

                case SB_THUMBPOSITION:
                    iVelocity = HIWORD(wParam);  break;

                default:
                    return 0;
            }

            iVelocity = max(1, min(iVelocity, 127));
            SetScrollPos(hwnd, SB_HORZ, iVelocity, TRUE);
            return 0;

        // Vertical scroll:  Pitch Bend
        case WM_VSCROLL:

            switch (LOWORD(wParam))
            {
                case SB_THUMBTRACK:
                    iPitchBend = 16383 - HIWORD(wParam);  break;

                case SB_THUMBPOSITION:
                    iPitchBend = 8191;                     break;

                default:
                    return 0;
            }

            iPitchBend = max(0, min(iPitchBend, 16383));
            SetScrollPos(hwnd, SB_VERT, 16383 - iPitchBend, TRUE);

            if (bOpened)
                MidiPitchBend(hMidiOut, iChannel, iPitchBend);

            return 0;

        case WM_PAINT:
            hdc = BeginPaint(hwnd, &ps);

            for (i = 0; i < key.length; i++)
                if (key[i].xPos != -1)
                    DrawKey(hdc, i, FALSE);

            midiOutGetDevCaps(iDevice, &moc, MIDIOUTCAPS.sizeof);
            szBuffer = format("Channel %s", iChannel + 1);

            TextOut(hdc, cxCaps, 1 * cyChar,
                    bOpened ? ("Open\0"w.dup.ptr) : ("Closed\0"w.dup.ptr),
                    bOpened ? 4 : 6);
            
                
            auto deviceName = to!string(fromWStringz(moc.szPname.ptr));

            TextOut(hdc, cxCaps, 2 * cyChar, deviceName.toUTF16z, deviceName.count);
            TextOut(hdc, cxCaps, 2 * cyChar, moc.szPname.ptr, 0);
            TextOut(hdc, cxCaps, 3 * cyChar, szBuffer.toUTF16z, szBuffer.count);
            TextOut(hdc, cxCaps, 4 * cyChar,
                    fam[iVoice / 8].inst[iVoice % 8].szInst.toUTF16z,
                    fam[iVoice / 8].inst[iVoice % 8].szInst.count);

            EndPaint(hwnd, &ps);
            return 0;

        case WM_DESTROY:
            SendMessage(hwnd, WM_COMMAND, IDM_CLOSE, 0L);
            PostQuitMessage(0);
            return 0;
        
        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}

wstring fromWStringz(const wchar* s)
{
    if (s is null) return null;

    wchar* ptr;
    for (ptr = cast(wchar*)s; *ptr; ++ptr) {}

    return to!wstring(s[0..ptr-s]);
}
