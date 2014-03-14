/+
 + Copyright (c) Charles Petzold, 1998.
 + Ported to the D Programming Language by Andrej Mitrovic, 2011.
 +/

module AddSynth;

import core.memory;
import core.runtime;
import core.thread;
import std.array : replicate;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.exception;
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

import resource;
import WaveTable;

string appName     = "AddSynth";
string description = "AddSynth";
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
        MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
    }

    return 0;
}

enum ID_TIMER     = 1;
enum SAMPLE_RATE  = 22050;
enum MAX_PARTIALS = 21;

double SineGenerator(double dFreq, ref double pdAngle)
{
    double dAmp;

    dAmp      = sin(pdAngle);
    pdAngle  += 2 * PI * dFreq / SAMPLE_RATE;

    if (pdAngle >= 2 * PI)
        pdAngle -= 2 * PI;

    return dAmp;
}

// Fill a buffer with a composite waveform
VOID FillBuffer(INS ins, ref PBYTE pBuffer, int iNumSamples)
{
    static double[MAX_PARTIALS] dAngle;
    dAngle[] = 0.0;
    
    double dAmp, dFrq, dComp, dFrac;
    int i, iPrt, iMsecTime, iCompMaxAmp, iMaxAmp, iSmp;

    // Calculate the composite maximum amplitude
    iCompMaxAmp = 0;

    for (iPrt = 0; iPrt < ins.pprt.length; iPrt++)
    {
        iMaxAmp = 0;

        for (i = 0; i < ins.pprt[iPrt].ampArray.length; i++)
            iMaxAmp = max(iMaxAmp, ins.pprt[iPrt].ampArray[i].iValue);

        iCompMaxAmp += iMaxAmp;
    }

    // Loop through each sample
    for (iSmp = 0; iSmp < iNumSamples; iSmp++)
    {
        dComp     = 0;
        iMsecTime = cast(int)(1000 * iSmp / SAMPLE_RATE);

        // Loop through each partial
        for (iPrt = 0; iPrt < ins.pprt.length; iPrt++)
        {
            dAmp = 0;
            dFrq = 0;

            for (i = 0; i < ins.pprt[iPrt].ampArray.length - 1; i++)
            {
                if (iMsecTime >= ins.pprt[iPrt].ampArray[i].iTime &&
                    iMsecTime <= ins.pprt[iPrt].ampArray[i + 1].iTime)
                {
                    dFrac = cast(double)(iMsecTime -
                            ins.pprt[iPrt].ampArray[i].iTime) /
                            (ins.pprt[iPrt].ampArray[i + 1].iTime -
                             ins.pprt[iPrt].ampArray[i].iTime);

                    dAmp = dFrac * ins.pprt[iPrt].ampArray[i + 1].iValue +
                           (1 - dFrac) * ins.pprt[iPrt].ampArray[i].iValue;

                    break;
                }
            }

            for (i = 0; i < ins.pprt[iPrt].freqArray.length - 1; i++)
            {
                if (iMsecTime >= ins.pprt[iPrt].freqArray[i  ].iTime &&
                    iMsecTime <= ins.pprt[iPrt].freqArray[i + 1].iTime)
                {
                    dFrac = cast(double)(iMsecTime - ins.pprt[iPrt].freqArray[i  ].iTime) /
                            (ins.pprt[iPrt].freqArray[i + 1].iTime -
                             ins.pprt[iPrt].freqArray[i  ].iTime);

                    dFrq = dFrac * ins.pprt[iPrt].freqArray[i + 1].iValue +
                           (1 - dFrac) * ins.pprt[iPrt].freqArray[i  ].iValue;

                    break;
                }
            }

            dComp += dAmp * SineGenerator(dFrq, dAngle[iPrt]);
        }

        pBuffer[iSmp] = cast(BYTE)(127 + 127 * dComp / iCompMaxAmp);
    }
}

BOOL MakeWaveFile(INS ins, string szFileName)
{
    DWORD  dwWritten;
    HANDLE hFile;
    int iChunkSize, iPcmSize, iNumSamples;
    PBYTE pBuffer;
    WAVEFORMATEX waveform;

    hFile = CreateFile(szFileName.toUTF16z, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    enforce(hFile != NULL);

    iNumSamples = (cast(int)ins.iMsecTime * SAMPLE_RATE / 1000 + 1) / 2 * 2;
    iPcmSize    = PCMWAVEFORMAT.sizeof;
    iChunkSize  = 12 + iPcmSize + 8 + iNumSamples;

    pBuffer = cast(typeof(pBuffer))GC.malloc(iNumSamples);
    if (pBuffer is null)
    {
        CloseHandle(hFile);
        throw new Exception("Can't allocate buffer.");
    }

    FillBuffer(ins, pBuffer, iNumSamples);
    
    waveform.wFormatTag      = WAVE_FORMAT_PCM;
    waveform.nChannels       = 1;
    waveform.nSamplesPerSec  = SAMPLE_RATE;
    waveform.nAvgBytesPerSec = SAMPLE_RATE;
    waveform.nBlockAlign     = 1;
    waveform.wBitsPerSample  = 8;
    waveform.cbSize          = 0;

    // Note: WriteFile doesn't know anything about UTF8+, have to use ASCII
    // to write the file section names.
    string RIFF = "RIFF";
    string WAVEfmt = "WAVEfmt ";
    string DATA = "data";
    
    WriteFile(hFile, cast(void*)(RIFF.toStringz), 4, &dwWritten, NULL);
    WriteFile(hFile, &iChunkSize, 4, &dwWritten, NULL);
    WriteFile(hFile, cast(void*)(WAVEfmt.toStringz), 8, &dwWritten, NULL);
    WriteFile(hFile, &iPcmSize, 4, &dwWritten, NULL);
    WriteFile(hFile, &waveform, WAVEFORMATEX.sizeof - 2, &dwWritten, NULL);
    WriteFile(hFile, cast(void*)(DATA.toStringz), 4, &dwWritten, NULL);
    WriteFile(hFile, &iNumSamples, 4, &dwWritten, NULL);
    WriteFile(hFile, pBuffer, iNumSamples, &dwWritten, NULL);

    CloseHandle(hFile);
    GC.free(pBuffer);

    if (cast(int)dwWritten != iNumSamples)
    {
        DeleteFile(szFileName.toUTF16z);
        return FALSE;
    }

    return TRUE;
}

void TestAndCreateFile(HWND hwnd, INS ins, string szFileName, int idButton)
{
    if (GetFileAttributes(szFileName.toUTF16z) != -1)
        EnableWindow(GetDlgItem(hwnd, idButton), TRUE);
    else
    {
        if (MakeWaveFile(ins, szFileName))
            EnableWindow(GetDlgItem(hwnd, idButton), TRUE);
        else
        {
            string message = format("Could not create %s.", szFileName);
            MessageBeep(MB_ICONEXCLAMATION);
            MessageBox(hwnd, message.toUTF16z, appName.toUTF16z, MB_OK | MB_ICONEXCLAMATION);
        }
    }
}

extern (Windows)
BOOL DlgProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    string szTrum = "Trumpet.wav";
    string szOboe = "Oboe.wav";
    string szClar = "Clarinet.wav";

    switch (message)
    {
        case WM_INITDIALOG:
            SetTimer(hwnd, ID_TIMER, 1, NULL);
            return TRUE;

        case WM_TIMER:
            KillTimer(hwnd, ID_TIMER);
            SetCursor(LoadCursor(NULL, IDC_WAIT));
            ShowCursor(TRUE);

            TestAndCreateFile(hwnd, insTrum, szTrum, IDC_TRUMPET);
            TestAndCreateFile(hwnd, insOboe, szOboe, IDC_OBOE);
            TestAndCreateFile(hwnd, insClar, szClar, IDC_CLARINET);

            SetDlgItemText(hwnd, IDC_TEXT, " ");
            SetFocus(GetDlgItem(hwnd, IDC_TRUMPET));

            ShowCursor(FALSE);
            SetCursor(LoadCursor(NULL, IDC_ARROW));
            return TRUE;

        case WM_COMMAND:

            switch (LOWORD(wParam))
            {
                case IDC_TRUMPET:
                    PlaySound(szTrum.toUTF16z, NULL, SND_FILENAME | SND_SYNC);
                    return TRUE;

                case IDC_OBOE:
                    PlaySound(szOboe.toUTF16z, NULL, SND_FILENAME | SND_SYNC);
                    return TRUE;

                case IDC_CLARINET:
                    PlaySound(szClar.toUTF16z, NULL, SND_FILENAME | SND_SYNC);
                    return TRUE;
                
                default:
            }

            break;

        case WM_SYSCOMMAND:

            switch (LOWORD(wParam))
            {
                case SC_CLOSE:
                    EndDialog(hwnd, 0);
                    return TRUE;
                
                default:
            }

            break;
            
        default:
    }

    return FALSE;
}
