/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module DrumTime;

import core.memory;
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
pragma(lib, "comdlg32.lib");
pragma(lib, "winmm.lib");
import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.commdlg;
import win32.mmsystem;

enum NUM_PERC         = 47;
enum WM_USER_NOTIFY   = (WM_USER + 1);
enum WM_USER_FINISHED = (WM_USER + 2);
enum WM_USER_ERROR    = (WM_USER + 3);

align(2) struct DRUM
{
    short iMsecPerBeat;
    short iVelocity;
    short iNumBeats;
    DWORD[NUM_PERC] dwSeqPerc;
    DWORD[NUM_PERC] dwSeqPian;
}
alias DRUM* PDRUM;

auto minmax(T1, T2, T3) (T1 a, T2 x, T3 b)
{
    return min(max(x, a), b);
}

enum TIMER_RES = 5;

__gshared BOOL bSequenceGoing, bEndSequence;
__gshared DRUM drum;
__gshared HMIDIOUT hMidiOut;
__gshared HWND hwndNotify;
__gshared int  iIndex;
__gshared UINT uTimerRes, uTimerID;

DWORD MidiOutMessage(HMIDIOUT hMidi, int iStatus, int iChannel, int iData1, int iData2)
{
    DWORD dwMessage;
    dwMessage = iStatus | iChannel | (iData1 << 8) | (iData2 << 16);
    return midiOutShortMsg(hMidi, dwMessage);
}

void DrumSetParams(PDRUM pdrum)
{
    drum = *pdrum;
}

BOOL DrumBeginSequence(HWND hwnd)
{
    TIMECAPS tc;

    hwndNotify = hwnd;             // Save window handle for notification
    DrumEndSequence(TRUE);         // Stop current sequence if running

    // Open the MIDI Mapper output port
    if (midiOutOpen(&hMidiOut, MIDIMAPPER, 0, 0, 0))
        return FALSE;

    // Send Program Change messages for channels 9 and 0
    MidiOutMessage(hMidiOut, 0xC0, 9, 0, 0);
    MidiOutMessage(hMidiOut, 0xC0, 0, 0, 0);

    // Begin sequence by setting a timer event
    timeGetDevCaps(&tc, TIMECAPS.sizeof);
    uTimerRes = minmax(tc.wPeriodMin, TIMER_RES, tc.wPeriodMax);
    timeBeginPeriod(uTimerRes);

    uTimerID = timeSetEvent(max(cast(UINT)uTimerRes, cast(UINT)drum.iMsecPerBeat),
                            uTimerRes, &DrumTimerFunc, 0, TIME_ONESHOT);

    if (uTimerID == 0)
    {
        timeEndPeriod(uTimerRes);
        midiOutClose(hMidiOut);
        return FALSE;
    }

    iIndex         = -1;
    bEndSequence   = FALSE;
    bSequenceGoing = TRUE;

    return TRUE;
}

void DrumEndSequence(BOOL bRightAway)
{
    if (bRightAway)
    {
        if (bSequenceGoing)
        {
            // stop the timer
            if (uTimerID)
                timeKillEvent(uTimerID);

            timeEndPeriod(uTimerRes);

            // turn off all notes
            MidiOutMessage(hMidiOut, 0xB0, 9, 123, 0);
            MidiOutMessage(hMidiOut, 0xB0, 0, 123, 0);

            // close the MIDI port
            midiOutClose(hMidiOut);
            bSequenceGoing = FALSE;
        }
    }
    else
        bEndSequence = TRUE;
}

extern (Windows)
void DrumTimerFunc(UINT uID, UINT uMsg, DWORD dwUser, DWORD dw1, DWORD dw2)
{
    static DWORD[NUM_PERC] dwSeqPercLast, dwSeqPianLast;
    int i;

    // Note Off messages for channels 9 and 0
    if (iIndex != -1)
    {
        for (i = 0; i < NUM_PERC; i++)
        {
            if (dwSeqPercLast[i] & 1 << iIndex)
                MidiOutMessage(hMidiOut, 0x80, 9, i + 35, 0);

            if (dwSeqPianLast[i] & 1 << iIndex)
                MidiOutMessage(hMidiOut, 0x80, 0, i + 35, 0);
        }
    }

    // Increment index and notify window to advance bouncing ball
    iIndex = (iIndex + 1) % drum.iNumBeats;
    PostMessage(hwndNotify, WM_USER_NOTIFY, iIndex, timeGetTime());

    // Check if ending the sequence
    if (bEndSequence && iIndex == 0)
    {
        PostMessage(hwndNotify, WM_USER_FINISHED, 0, 0L);
        return;
    }

    // Note On messages for channels 9 and 0
    for (i = 0; i < NUM_PERC; i++)
    {
        if (drum.dwSeqPerc[i] & 1 << iIndex)
            MidiOutMessage(hMidiOut, 0x90, 9, i + 35, drum.iVelocity);

        if (drum.dwSeqPian[i] & 1 << iIndex)
            MidiOutMessage(hMidiOut, 0x90, 0, i + 35, drum.iVelocity);

        dwSeqPercLast[i] = drum.dwSeqPerc[i];
        dwSeqPianLast[i] = drum.dwSeqPian[i];
    }

    // Set a new timer event
    uTimerID = timeSetEvent(max(cast(int)uTimerRes, drum.iMsecPerBeat),
                            uTimerRes, &DrumTimerFunc, 0, TIME_ONESHOT);

    if (uTimerID == 0)
    {
        PostMessage(hwndNotify, WM_USER_ERROR, 0, 0);
    }
}
