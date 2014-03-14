module Record1;

/+
 + Note: This app was not properly tested.
 + I'd appreciate if someone could test this (& fix and pull?) and get back to me.
 + 
 + See README for contact details.
 +/

import core.memory;
import core.runtime;
import core.thread;
import std.algorithm;
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

string appName     = "Record1";
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
    if (DialogBox(hInstance, "Record".toUTF16z, NULL, &DlgProc) == -1)
    {
        MessageBox(NULL, "This program requires Windows NT!",
                   appName.toUTF16z, MB_ICONERROR);
    }

    return 0;
}

enum INP_BUFFER_SIZE = 16384;

extern (Windows)
BOOL DlgProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    static BOOL bRecording, bPlaying, bReverse, bPaused, bEnding, bTerminating;
    static DWORD dwDataLength, dwRepetitions = 1;
    static HWAVEIN  hWaveIn;
    static HWAVEOUT hWaveOut;
    static ubyte[] pBuffer1, pBuffer2, pSaveBuffer, pNewBuffer;
    static PWAVEHDR pWaveHdr1, pWaveHdr2;
    static string szOpenError = "Error opening waveform audio!";
    static string szMemError  = "Error allocating memory!";
    static WAVEFORMATEX waveform;

    switch (message)
    {
        case WM_INITDIALOG:
            // Allocate memory for wave header
            pWaveHdr1 = cast(typeof(pWaveHdr1))GC.malloc(WAVEHDR.sizeof);
            pWaveHdr2 = cast(typeof(pWaveHdr2))GC.malloc(WAVEHDR.sizeof);

            // Allocate memory for save buffer
            pSaveBuffer.length = 1;
            return TRUE;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDC_RECORD_BEG:
                    // Allocate buffer memory
                    pBuffer1.length = INP_BUFFER_SIZE;
                    pBuffer2.length = INP_BUFFER_SIZE;

                    // Open waveform audio for input
                    waveform.wFormatTag      = WAVE_FORMAT_PCM;
                    waveform.nChannels       = 1;
                    waveform.nSamplesPerSec  = 11025;
                    waveform.nAvgBytesPerSec = 11025;
                    waveform.nBlockAlign     = 1;
                    waveform.wBitsPerSample  = 8;
                    waveform.cbSize          = 0;

                    if (waveInOpen(&hWaveIn, WAVE_MAPPER, &waveform, cast(DWORD)hwnd, 0, CALLBACK_WINDOW))
                    {
                        MessageBeep(MB_ICONEXCLAMATION);
                        MessageBox(hwnd, szOpenError.toUTF16z, appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
                    }

                    // Set up headers and prepare them
                    pWaveHdr1.lpData = cast(typeof(pWaveHdr1.lpData))pBuffer1.ptr;
                    pWaveHdr1.dwBufferLength  = INP_BUFFER_SIZE;
                    pWaveHdr1.dwBytesRecorded = 0;
                    pWaveHdr1.dwUser          = 0;
                    pWaveHdr1.dwFlags         = 0;
                    pWaveHdr1.dwLoops         = 1;
                    pWaveHdr1.lpNext          = NULL;
                    pWaveHdr1.reserved        = 0;

                    waveInPrepareHeader(hWaveIn, pWaveHdr1, WAVEHDR.sizeof);

                    pWaveHdr2.lpData = cast(typeof(pWaveHdr2.lpData))pBuffer2.ptr;
                    pWaveHdr2.dwBufferLength  = INP_BUFFER_SIZE;
                    pWaveHdr2.dwBytesRecorded = 0;
                    pWaveHdr2.dwUser          = 0;
                    pWaveHdr2.dwFlags         = 0;
                    pWaveHdr2.dwLoops         = 1;
                    pWaveHdr2.lpNext          = NULL;
                    pWaveHdr2.reserved        = 0;

                    waveInPrepareHeader(hWaveIn, pWaveHdr2, WAVEHDR.sizeof);
                    return TRUE;

                case IDC_RECORD_END:
                    // Reset input to return last buffer
                    bEnding = TRUE;
                    waveInReset(hWaveIn);
                    return TRUE;

                case IDC_PLAY_BEG:
                    // Open waveform audio for output
                    waveform.wFormatTag      = WAVE_FORMAT_PCM;
                    waveform.nChannels       = 1;
                    waveform.nSamplesPerSec  = 11025;
                    waveform.nAvgBytesPerSec = 11025;
                    waveform.nBlockAlign     = 1;
                    waveform.wBitsPerSample  = 8;
                    waveform.cbSize          = 0;

                    if (waveOutOpen(&hWaveOut, WAVE_MAPPER, &waveform, cast(DWORD)hwnd, 0, CALLBACK_WINDOW))
                    {
                        MessageBeep(MB_ICONEXCLAMATION);
                        MessageBox(hwnd, szOpenError.toUTF16z, appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
                    }

                    return TRUE;

                case IDC_PLAY_PAUSE:
                    // Pause or restart output
                    if (!bPaused)
                    {
                        waveOutPause(hWaveOut);
                        SetDlgItemText(hwnd, IDC_PLAY_PAUSE, "Resume");
                        bPaused = TRUE;
                    }
                    else
                    {
                        waveOutRestart(hWaveOut);
                        SetDlgItemText(hwnd, IDC_PLAY_PAUSE, "Pause");
                        bPaused = FALSE;
                    }

                    return TRUE;

                case IDC_PLAY_END:
                    // Reset output for close preparation
                    bEnding = TRUE;
                    waveOutReset(hWaveOut);
                    return TRUE;

                case IDC_PLAY_REV:
                    // Reverse save buffer and play
                    bReverse = TRUE;
                
                    auto arr = pSaveBuffer[0..dwDataLength];
                    reverse(arr);

                    SendMessage(hwnd, WM_COMMAND, IDC_PLAY_BEG, 0);
                    return TRUE;

                case IDC_PLAY_REP:
                    // Set infinite repetitions and play
                    dwRepetitions = -1;
                    SendMessage(hwnd, WM_COMMAND, IDC_PLAY_BEG, 0);
                    return TRUE;

                case IDC_PLAY_SPEED:
                    // Open waveform audio for fast output
                    waveform.wFormatTag      = WAVE_FORMAT_PCM;
                    waveform.nChannels       = 1;
                    waveform.nSamplesPerSec  = 22050;
                    waveform.nAvgBytesPerSec = 22050;
                    waveform.nBlockAlign     = 1;
                    waveform.wBitsPerSample  = 8;
                    waveform.cbSize          = 0;

                    if (waveOutOpen(&hWaveOut, 0, &waveform, cast(DWORD)hwnd, 0, CALLBACK_WINDOW))
                    {
                        MessageBeep(MB_ICONEXCLAMATION);
                        MessageBox(hwnd, szOpenError.toUTF16z, appName.toUTF16z,
                                   MB_ICONEXCLAMATION | MB_OK);
                    }

                    return TRUE;
                    
                default:
            }

            break;

        case MM_WIM_OPEN:
            // Shrink down the save buffer
            pSaveBuffer.length = 1;

            // Enable and disable Buttons
            EnableWindow(GetDlgItem(hwnd, IDC_RECORD_BEG), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_RECORD_END), TRUE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_BEG), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_PAUSE), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_END), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_REV), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_REP), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_SPEED), FALSE);
            SetFocus(GetDlgItem(hwnd, IDC_RECORD_END));

            // Add the buffers
            waveInAddBuffer(hWaveIn, pWaveHdr1, WAVEHDR.sizeof);
            waveInAddBuffer(hWaveIn, pWaveHdr2, WAVEHDR.sizeof);

            // Begin sampling
            bRecording   = TRUE;
            bEnding      = FALSE;
            dwDataLength = 0;
            waveInStart(hWaveIn);
            return TRUE;

        case MM_WIM_DATA:

            // Reallocate save buffer memory
            pSaveBuffer.length = dwDataLength + (cast(PWAVEHDR)lParam).dwBytesRecorded;
            pNewBuffer = pSaveBuffer;

            if (pNewBuffer is null)
            {
                waveInClose(hWaveIn);
                MessageBeep(MB_ICONEXCLAMATION);
                MessageBox(hwnd, szMemError.toUTF16z, appName.toUTF16z, MB_ICONEXCLAMATION | MB_OK);
                return TRUE;
            }

            pSaveBuffer = pNewBuffer;
            
            // this is broken
            pSaveBuffer[0 .. dwDataLength] = cast(ubyte[])((cast(PWAVEHDR)lParam).lpData)[0 .. (cast(PWAVEHDR)lParam).dwBytesRecorded];

            dwDataLength += (cast(PWAVEHDR)lParam).dwBytesRecorded;

            if (bEnding)
            {
                waveInClose(hWaveIn);
                return TRUE;
            }

            // Send out a new buffer
            waveInAddBuffer(hWaveIn, cast(PWAVEHDR)lParam, WAVEHDR.sizeof);
            return TRUE;

        case MM_WIM_CLOSE:
            // Free the buffer memory
            waveInUnprepareHeader(hWaveIn, pWaveHdr1, WAVEHDR.sizeof);
            waveInUnprepareHeader(hWaveIn, pWaveHdr2, WAVEHDR.sizeof);

            // Enable and disable buttons
            EnableWindow(GetDlgItem(hwnd, IDC_RECORD_BEG), TRUE);
            EnableWindow(GetDlgItem(hwnd, IDC_RECORD_END), FALSE);
            SetFocus(GetDlgItem(hwnd, IDC_RECORD_BEG));

            if (dwDataLength > 0)
            {
                EnableWindow(GetDlgItem(hwnd, IDC_PLAY_BEG), TRUE);
                EnableWindow(GetDlgItem(hwnd, IDC_PLAY_PAUSE), FALSE);
                EnableWindow(GetDlgItem(hwnd, IDC_PLAY_END), FALSE);
                EnableWindow(GetDlgItem(hwnd, IDC_PLAY_REP), TRUE);
                EnableWindow(GetDlgItem(hwnd, IDC_PLAY_REV), TRUE);
                EnableWindow(GetDlgItem(hwnd, IDC_PLAY_SPEED), TRUE);
                SetFocus(GetDlgItem(hwnd, IDC_PLAY_BEG));
            }

            bRecording = FALSE;

            if (bTerminating)
                SendMessage(hwnd, WM_SYSCOMMAND, SC_CLOSE, 0L);

            return TRUE;

        case MM_WOM_OPEN:
            // Enable and disable buttons
            EnableWindow(GetDlgItem(hwnd, IDC_RECORD_BEG), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_RECORD_END), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_BEG), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_PAUSE), TRUE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_END), TRUE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_REP), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_REV), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_SPEED), FALSE);
            SetFocus(GetDlgItem(hwnd, IDC_PLAY_END));

            // Set up header
            pWaveHdr1.lpData = cast(typeof(pWaveHdr1.lpData))pSaveBuffer.ptr;
            pWaveHdr1.dwBufferLength  = dwDataLength;
            pWaveHdr1.dwBytesRecorded = 0;
            pWaveHdr1.dwUser          = 0;
            pWaveHdr1.dwFlags         = WHDR_BEGINLOOP | WHDR_ENDLOOP;
            pWaveHdr1.dwLoops         = dwRepetitions;
            pWaveHdr1.lpNext          = NULL;
            pWaveHdr1.reserved        = 0;

            // Prepare and write
            waveOutPrepareHeader(hWaveOut, pWaveHdr1, WAVEHDR.sizeof);
            waveOutWrite(hWaveOut, pWaveHdr1, WAVEHDR.sizeof);

            bEnding  = FALSE;
            bPlaying = TRUE;
            return TRUE;

        case MM_WOM_DONE:
            waveOutUnprepareHeader(hWaveOut, pWaveHdr1, WAVEHDR.sizeof);
            waveOutClose(hWaveOut);
            return TRUE;

        case MM_WOM_CLOSE:
            // Enable and disable buttons
            EnableWindow(GetDlgItem(hwnd, IDC_RECORD_BEG), TRUE);
            EnableWindow(GetDlgItem(hwnd, IDC_RECORD_END), TRUE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_BEG), TRUE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_PAUSE), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_END), FALSE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_REV), TRUE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_REP), TRUE);
            EnableWindow(GetDlgItem(hwnd, IDC_PLAY_SPEED), TRUE);
            SetFocus(GetDlgItem(hwnd, IDC_PLAY_BEG));

            SetDlgItemText(hwnd, IDC_PLAY_PAUSE, "Pause");
            bPaused       = FALSE;
            dwRepetitions = 1;
            bPlaying      = FALSE;

            if (bReverse)
            {
                auto arr = pSaveBuffer[0 .. dwDataLength];
                reverse(arr);
                bReverse = FALSE;
            }

            if (bTerminating)
                SendMessage(hwnd, WM_SYSCOMMAND, SC_CLOSE, 0L);

            return TRUE;

        case WM_SYSCOMMAND:

            switch (LOWORD(wParam))
            {
                case SC_CLOSE:

                    if (bRecording)
                    {
                        bTerminating = TRUE;
                        bEnding      = TRUE;
                        waveInReset(hWaveIn);
                        return TRUE;
                    }

                    if (bPlaying)
                    {
                        bTerminating = TRUE;
                        bEnding      = TRUE;
                        waveOutReset(hWaveOut);
                        return TRUE;
                    }

                    EndDialog(hwnd, 0);
                    return TRUE;
                    
                default:
            }

            break;
            
        default:
    }

    return FALSE;
}
