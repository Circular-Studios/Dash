/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module SineWave;

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

import resource;

string appName     = "SineWave";
string description = "";
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
    if (DialogBox(hInstance, appName.toUTF16z, NULL, &DlgProc) == -1)
    {
        MessageBox(NULL, "This program requires Windows NT!",
                   appName.toUTF16z, MB_ICONERROR);
    }

    return 0;
}

enum SAMPLE_RATE     = 11025;
enum FREQ_MIN        =    20;
enum FREQ_MAX        =  5000;
enum FREQ_INIT       =   440;
enum OUT_BUFFER_SIZE =  4096;

VOID FillBuffer(ref char* pBuffer, int iFreq)
{
    static double fAngle = 0.0;

    foreach (index; 0 .. OUT_BUFFER_SIZE)
    {
        pBuffer[index] = cast(char)(127 + 127 * sin(fAngle));

        fAngle += 2 * PI * iFreq / SAMPLE_RATE;

        if (fAngle > 2 * PI)
            fAngle -= 2 * PI;
    }
}

VOID FillBuffer(ref ubyte[] pBuffer, int iFreq)
{
    static double fAngle = 0.0;

    foreach (ref sample; pBuffer)
    {
        sample = cast(ubyte)(127 + 127 * sin(fAngle));

        fAngle += 2 * PI * iFreq / SAMPLE_RATE;

        if (fAngle > 2 * PI)
            fAngle -= 2 * PI;
    }
}

extern (Windows)
BOOL DlgProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BOOL bShutOff, bClosing;
    static HWAVEOUT hWaveOut;
    static HWND  hwndScroll;
    static int   iFreq = FREQ_INIT;
    static ubyte[] pBuffer1, pBuffer2;
    static PWAVEHDR pWaveHdr1, pWaveHdr2;
    static WAVEFORMATEX waveformat;
    int iDummy;

    switch (message)
    {
        case WM_INITDIALOG:
            hwndScroll = GetDlgItem(hwnd, IDC_SCROLL);
            SetScrollRange(hwndScroll, SB_CTL, FREQ_MIN, FREQ_MAX, FALSE);
            SetScrollPos(hwndScroll, SB_CTL, FREQ_INIT, TRUE);
            SetDlgItemInt(hwnd, IDC_TEXT, FREQ_INIT, FALSE);

            return TRUE;

        case WM_HSCROLL:

            switch (LOWORD(wParam))
            {
                case SB_LINELEFT:
                    iFreq -=  1;  break;

                case SB_LINERIGHT:
                    iFreq +=  1;  break;

                case SB_PAGELEFT:
                    iFreq /=  2;  break;

                case SB_PAGERIGHT:
                    iFreq *=  2;  break;

                case SB_THUMBTRACK:
                    iFreq = HIWORD(wParam);
                    break;

                case SB_TOP:
                    GetScrollRange(hwndScroll, SB_CTL, &iFreq, &iDummy);
                    break;

                case SB_BOTTOM:
                    GetScrollRange(hwndScroll, SB_CTL, &iDummy, &iFreq);
                    break;
                
                default:
            }

            iFreq = max(FREQ_MIN, min(FREQ_MAX, iFreq));

            SetScrollPos(hwndScroll, SB_CTL, iFreq, TRUE);
            SetDlgItemInt(hwnd, IDC_TEXT, iFreq, FALSE);
            return TRUE;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDC_ONOFF:
                    // If turning on waveform, hWaveOut is NULL
                    if (hWaveOut == NULL)
                    {
                        // Allocate memory for 2 headers and 2 buffers
                        pWaveHdr1 = cast(typeof(pWaveHdr1))GC.malloc(WAVEHDR.sizeof);
                        pWaveHdr2 = cast(typeof(pWaveHdr1))GC.malloc(WAVEHDR.sizeof);
                        pBuffer1.length = OUT_BUFFER_SIZE;
                        pBuffer2.length = OUT_BUFFER_SIZE;

                        // Variable to indicate Off button pressed
                        bShutOff = FALSE;

                        // Open waveform audio for output
                        waveformat.wFormatTag      = WAVE_FORMAT_PCM;
                        waveformat.nChannels       = 1;
                        waveformat.nSamplesPerSec  = SAMPLE_RATE;
                        waveformat.nAvgBytesPerSec = SAMPLE_RATE;
                        waveformat.nBlockAlign     = 1;
                        waveformat.wBitsPerSample  = 8;
                        waveformat.cbSize          = 0;

                        if (waveOutOpen(&hWaveOut, WAVE_MAPPER, &waveformat, cast(DWORD)hwnd, 0, CALLBACK_WINDOW)
                            != MMSYSERR_NOERROR)
                        {
                            hWaveOut = cast(typeof(hWaveOut))NULL;
                            MessageBeep(MB_ICONEXCLAMATION);
                            MessageBox(hwnd,
                                       "Error opening waveform audio device!",
                                       appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
                            return TRUE;
                        }

                        // Set up headers and prepare them
                        pWaveHdr1.lpData = cast(typeof(pWaveHdr1.lpData))pBuffer1.ptr;
                        pWaveHdr1.dwBufferLength  = OUT_BUFFER_SIZE;
                        pWaveHdr1.dwBytesRecorded = 0;
                        pWaveHdr1.dwUser          = 0;
                        pWaveHdr1.dwFlags         = 0;
                        pWaveHdr1.dwLoops         = 1;
                        pWaveHdr1.lpNext          = NULL;
                        pWaveHdr1.reserved        = 0;

                        waveOutPrepareHeader(hWaveOut, pWaveHdr1,
                                             WAVEHDR.sizeof);

                        pWaveHdr2.lpData = cast(typeof(pWaveHdr2.lpData))pBuffer2.ptr;
                        pWaveHdr2.dwBufferLength  = OUT_BUFFER_SIZE;
                        pWaveHdr2.dwBytesRecorded = 0;
                        pWaveHdr2.dwUser          = 0;
                        pWaveHdr2.dwFlags         = 0;
                        pWaveHdr2.dwLoops         = 1;
                        pWaveHdr2.lpNext          = NULL;
                        pWaveHdr2.reserved        = 0;

                        waveOutPrepareHeader(hWaveOut, pWaveHdr2,
                                             WAVEHDR.sizeof);
                    }
                    // If turning off waveform, reset waveform audio
                    else
                    {
                        bShutOff = TRUE;
                        waveOutReset(hWaveOut);
                    }

                    return TRUE;
                    
                default:
            }

            break;

        // Message generated from waveOutOpen call
        case MM_WOM_OPEN:
            SetDlgItemText(hwnd, IDC_ONOFF, "Turn Off");

            // Send two buffers to waveform output device
            FillBuffer(pBuffer1, iFreq);
            waveOutWrite(hWaveOut, pWaveHdr1, WAVEHDR.sizeof);

            FillBuffer(pBuffer2, iFreq);
            waveOutWrite(hWaveOut, pWaveHdr2, WAVEHDR.sizeof);
            return TRUE;

        // Message generated when a buffer is finished
        case MM_WOM_DONE:

            if (bShutOff)
            {
                waveOutClose(hWaveOut);
                return TRUE;
            }

            FillBuffer((cast(PWAVEHDR)lParam).lpData, iFreq);
            waveOutWrite(hWaveOut, cast(PWAVEHDR)lParam, WAVEHDR.sizeof);
            return TRUE;

        case MM_WOM_CLOSE:
            waveOutUnprepareHeader(hWaveOut, pWaveHdr1, WAVEHDR.sizeof);
            waveOutUnprepareHeader(hWaveOut, pWaveHdr2, WAVEHDR.sizeof);

            SetDlgItemText(hwnd, IDC_ONOFF, "Turn On");

            hWaveOut = cast(typeof(hWaveOut))NULL;
        
            if (bClosing)
                EndDialog(hwnd, 0);

            return TRUE;

        case WM_SYSCOMMAND:

            switch (wParam)
            {
                case SC_CLOSE:

                    if (hWaveOut != NULL)
                    {
                        bShutOff = TRUE;
                        bClosing = TRUE;

                        waveOutReset(hWaveOut);
                    }
                    else
                        EndDialog(hwnd, 0);

                    return TRUE;
                    
                default:
            }

            break;
            
        default:
    }

    return FALSE;
}
