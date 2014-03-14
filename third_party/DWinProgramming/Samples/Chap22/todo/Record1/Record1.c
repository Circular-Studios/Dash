/*----------------------------------------
   RECORD1.C -- Waveform Audio Recorder
                (c) Charles Petzold, 1998
  ----------------------------------------*/

#include <windows.h>
#include "resource.h"

#define INP_BUFFER_SIZE 16384

BOOL CALLBACK DlgProc (HWND, UINT, WPARAM, LPARAM) ;

TCHAR szAppName [] = "Record1" ;

int WINAPI WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    PSTR szCmdLine, int iCmdShow)
{
     if (-1 == DialogBox (hInstance, "Record", NULL, DlgProc))
     {
          MessageBox (NULL, "This program requires Windows NT!",
                      szAppName, MB_ICONERROR) ;
     }
     return 0 ;
}

void ReverseMemory (BYTE * pBuffer, int iLength)
{
     BYTE b ;
     int  i ;
     
     for (i = 0 ; i < iLength / 2 ; i++)
     {
          b = pBuffer [i] ;
          pBuffer [i] = pBuffer [iLength - i - 1] ;
          pBuffer [iLength - i - 1] = b ;
     }
}

BOOL CALLBACK DlgProc (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
     static BOOL         bRecording, bPlaying, bReverse, bPaused,
                         bEnding, bTerminating ;
     static DWORD        dwDataLength, dwRepetitions = 1 ;
     static HWAVEIN      hWaveIn ;
     static HWAVEOUT     hWaveOut ;
     static PBYTE        pBuffer1, pBuffer2, pSaveBuffer, pNewBuffer ;
     static PWAVEHDR     pWaveHdr1, pWaveHdr2 ;
     static TCHAR        szOpenError[] = "Error opening waveform audio!";
     static TCHAR        szMemError [] = "Error allocating memory!" ;
     static WAVEFORMATEX waveform ;
     
     switch (message)
     {
     case WM_INITDIALOG:
               // Allocate memory for wave header
          
          pWaveHdr1 = malloc (sizeof (WAVEHDR)) ;
          pWaveHdr2 = malloc (sizeof (WAVEHDR)) ;
          
               // Allocate memory for save buffer
          
          pSaveBuffer = malloc (1) ;
          return TRUE ;
          
     case WM_COMMAND:
          switch (LOWORD (wParam))
          {
          case IDC_RECORD_BEG:
                    // Allocate buffer memory

               pBuffer1 = malloc (INP_BUFFER_SIZE) ;
               pBuffer2 = malloc (INP_BUFFER_SIZE) ;
               
               if (!pBuffer1 || !pBuffer2)
               {
                    if (pBuffer1) free (pBuffer1) ;
                    if (pBuffer2) free (pBuffer2) ;

                    MessageBeep (MB_ICONEXCLAMATION) ;
                    MessageBox (hwnd, szMemError, szAppName,
                                      MB_ICONEXCLAMATION | MB_OK) ;
                    return TRUE ;
               }
               
                    // Open waveform audio for input
               
               waveform.wFormatTag      = WAVE_FORMAT_PCM ;
               waveform.nChannels       = 1 ;
               waveform.nSamplesPerSec  = 11025 ;
               waveform.nAvgBytesPerSec = 11025 ;
               waveform.nBlockAlign     = 1 ;
               waveform.wBitsPerSample  = 8 ;
               waveform.cbSize          = 0 ;
               
               if (waveInOpen (&hWaveIn, WAVE_MAPPER, &waveform, 
                               (DWORD) hwnd, 0, CALLBACK_WINDOW))
               {
                    free (pBuffer1) ;
                    free (pBuffer2) ;
                    MessageBeep (MB_ICONEXCLAMATION) ;
                    MessageBox (hwnd, szOpenError, szAppName,
                                      MB_ICONEXCLAMATION | MB_OK) ;
               }
                    // Set up headers and prepare them
               
               pWaveHdr1->lpData          = pBuffer1 ;
               pWaveHdr1->dwBufferLength  = INP_BUFFER_SIZE ;
               pWaveHdr1->dwBytesRecorded = 0 ;
               pWaveHdr1->dwUser          = 0 ;
               pWaveHdr1->dwFlags         = 0 ;
               pWaveHdr1->dwLoops         = 1 ;
               pWaveHdr1->lpNext          = NULL ;
               pWaveHdr1->reserved        = 0 ;

               waveInPrepareHeader (hWaveIn, pWaveHdr1, sizeof (WAVEHDR)) ;
          
               pWaveHdr2->lpData          = pBuffer2 ;
               pWaveHdr2->dwBufferLength  = INP_BUFFER_SIZE ;
               pWaveHdr2->dwBytesRecorded = 0 ;
               pWaveHdr2->dwUser          = 0 ;
               pWaveHdr2->dwFlags         = 0 ;
               pWaveHdr2->dwLoops         = 1 ;
               pWaveHdr2->lpNext          = NULL ;
               pWaveHdr2->reserved        = 0 ;
          
               waveInPrepareHeader (hWaveIn, pWaveHdr2, sizeof (WAVEHDR)) ;
               return TRUE ;
               
          case IDC_RECORD_END:
                    // Reset input to return last buffer
               
               bEnding = TRUE ;
               waveInReset (hWaveIn) ;
               return TRUE ;
               
          case IDC_PLAY_BEG:
                    // Open waveform audio for output
               
               waveform.wFormatTag      = WAVE_FORMAT_PCM ;
               waveform.nChannels       = 1 ;
               waveform.nSamplesPerSec  = 11025 ;
               waveform.nAvgBytesPerSec = 11025 ;
               waveform.nBlockAlign     = 1 ;
               waveform.wBitsPerSample  = 8 ;
               waveform.cbSize          = 0 ;
               
               if (waveOutOpen (&hWaveOut, WAVE_MAPPER, &waveform, 
                                (DWORD) hwnd, 0, CALLBACK_WINDOW))
               {
                    MessageBeep (MB_ICONEXCLAMATION) ;
                    MessageBox (hwnd, szOpenError, szAppName,
                         MB_ICONEXCLAMATION | MB_OK) ;
               }
               return TRUE ;
               
          case IDC_PLAY_PAUSE:
                    // Pause or restart output
               
               if (!bPaused)
               {
                    waveOutPause (hWaveOut) ;
                    SetDlgItemText (hwnd, IDC_PLAY_PAUSE, "Resume") ;
                    bPaused = TRUE ;
               }
               else
               {
                    waveOutRestart (hWaveOut) ;
                    SetDlgItemText (hwnd, IDC_PLAY_PAUSE, "Pause") ;
                    bPaused = FALSE ;
               }
               return TRUE ;
               
          case IDC_PLAY_END:
                    // Reset output for close preparation
               
               bEnding = TRUE ;
               waveOutReset (hWaveOut) ;
               return TRUE ;
               
          case IDC_PLAY_REV:
                    // Reverse save buffer and play
               
               bReverse = TRUE ;
               ReverseMemory (pSaveBuffer, dwDataLength) ;
               
               SendMessage (hwnd, WM_COMMAND, IDC_PLAY_BEG, 0) ;
               return TRUE ;
               
          case IDC_PLAY_REP:
                    // Set infinite repetitions and play
               
               dwRepetitions = -1 ;
               SendMessage (hwnd, WM_COMMAND, IDC_PLAY_BEG, 0) ;
               return TRUE ;
               
          case IDC_PLAY_SPEED:
                    // Open waveform audio for fast output
               
               waveform.wFormatTag      = WAVE_FORMAT_PCM ;
               waveform.nChannels       = 1 ;
               waveform.nSamplesPerSec  = 22050 ;
               waveform.nAvgBytesPerSec = 22050 ;
               waveform.nBlockAlign     = 1 ;
               waveform.wBitsPerSample  = 8 ;
               waveform.cbSize          = 0 ;
               
               if (waveOutOpen (&hWaveOut, 0, &waveform, (DWORD) hwnd, 0,
                                           CALLBACK_WINDOW))
               {
                    MessageBeep (MB_ICONEXCLAMATION) ;
                    MessageBox (hwnd, szOpenError, szAppName,
                                      MB_ICONEXCLAMATION | MB_OK) ;
               }
               return TRUE ;
          }
          break ;
               
     case MM_WIM_OPEN:
               // Shrink down the save buffer
          
          pSaveBuffer = realloc (pSaveBuffer, 1) ;
          
               // Enable and disable Buttons
          
          EnableWindow (GetDlgItem (hwnd, IDC_RECORD_BEG), FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_RECORD_END), TRUE)  ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_BEG),   FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_PAUSE), FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_END),   FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_REV),   FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_REP),   FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_SPEED), FALSE) ;
          SetFocus (GetDlgItem (hwnd, IDC_RECORD_END)) ;

               // Add the buffers
          
          waveInAddBuffer (hWaveIn, pWaveHdr1, sizeof (WAVEHDR)) ;
          waveInAddBuffer (hWaveIn, pWaveHdr2, sizeof (WAVEHDR)) ;
          
               // Begin sampling
          
          bRecording = TRUE ;
          bEnding = FALSE ;
          dwDataLength = 0 ;
          waveInStart (hWaveIn) ;
          return TRUE ;
          
     case MM_WIM_DATA:
         
               // Reallocate save buffer memory
          
          pNewBuffer = realloc (pSaveBuffer, dwDataLength +
                                   ((PWAVEHDR) lParam)->dwBytesRecorded) ;
          
          if (pNewBuffer == NULL)
          {
               waveInClose (hWaveIn) ;
               MessageBeep (MB_ICONEXCLAMATION) ;
               MessageBox (hwnd, szMemError, szAppName,
                                 MB_ICONEXCLAMATION | MB_OK) ;
               return TRUE ;
          }
          
          pSaveBuffer = pNewBuffer ;
          CopyMemory (pSaveBuffer + dwDataLength, ((PWAVEHDR) lParam)->lpData,
                         ((PWAVEHDR) lParam)->dwBytesRecorded) ;
          
          dwDataLength += ((PWAVEHDR) lParam)->dwBytesRecorded ;
          
          if (bEnding)
          {
               waveInClose (hWaveIn) ;
               return TRUE ;
          }
          
               // Send out a new buffer
          
          waveInAddBuffer (hWaveIn, (PWAVEHDR) lParam, sizeof (WAVEHDR)) ;
          return TRUE ;
          
     case MM_WIM_CLOSE:
               // Free the buffer memory

          waveInUnprepareHeader (hWaveIn, pWaveHdr1, sizeof (WAVEHDR)) ;
          waveInUnprepareHeader (hWaveIn, pWaveHdr2, sizeof (WAVEHDR)) ;

          free (pBuffer1) ;
          free (pBuffer2) ;
          
               // Enable and disable buttons
          
          EnableWindow (GetDlgItem (hwnd, IDC_RECORD_BEG), TRUE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_RECORD_END), FALSE) ;
          SetFocus (GetDlgItem (hwnd, IDC_RECORD_BEG)) ;
          
          if (dwDataLength > 0)
          {
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_BEG),   TRUE)  ;
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_PAUSE), FALSE) ;
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_END),   FALSE) ;
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_REP),   TRUE)  ;
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_REV),   TRUE)  ;
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_SPEED), TRUE)  ;
               SetFocus (GetDlgItem (hwnd, IDC_PLAY_BEG)) ;
          }
          bRecording = FALSE ;
          
          if (bTerminating)
               SendMessage (hwnd, WM_SYSCOMMAND, SC_CLOSE, 0L) ;
          
          return TRUE ;
          
     case MM_WOM_OPEN:
               // Enable and disable buttons
          
          EnableWindow (GetDlgItem (hwnd, IDC_RECORD_BEG), FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_RECORD_END), FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_BEG),   FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_PAUSE), TRUE)  ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_END),   TRUE)  ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_REP),   FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_REV),   FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_SPEED), FALSE) ;
          SetFocus (GetDlgItem (hwnd, IDC_PLAY_END)) ;
          
               // Set up header
          
          pWaveHdr1->lpData          = pSaveBuffer ;
          pWaveHdr1->dwBufferLength  = dwDataLength ;
          pWaveHdr1->dwBytesRecorded = 0 ;
          pWaveHdr1->dwUser          = 0 ;
          pWaveHdr1->dwFlags         = WHDR_BEGINLOOP | WHDR_ENDLOOP ;
          pWaveHdr1->dwLoops         = dwRepetitions ;
          pWaveHdr1->lpNext          = NULL ;
          pWaveHdr1->reserved        = 0 ;
          
               // Prepare and write
          
          waveOutPrepareHeader (hWaveOut, pWaveHdr1, sizeof (WAVEHDR)) ;
          waveOutWrite (hWaveOut, pWaveHdr1, sizeof (WAVEHDR)) ;
          
          bEnding = FALSE ;
          bPlaying = TRUE ;
          return TRUE ;
          
     case MM_WOM_DONE:
          waveOutUnprepareHeader (hWaveOut, pWaveHdr1, sizeof (WAVEHDR)) ;
          waveOutClose (hWaveOut) ;
          return TRUE ;
          
     case MM_WOM_CLOSE:
               // Enable and disable buttons
          
          EnableWindow (GetDlgItem (hwnd, IDC_RECORD_BEG), TRUE)  ;
          EnableWindow (GetDlgItem (hwnd, IDC_RECORD_END), TRUE)  ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_BEG),   TRUE)  ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_PAUSE), FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_END),   FALSE) ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_REV),   TRUE)  ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_REP),   TRUE)  ;
          EnableWindow (GetDlgItem (hwnd, IDC_PLAY_SPEED), TRUE)  ;
          SetFocus (GetDlgItem (hwnd, IDC_PLAY_BEG)) ;
          
          SetDlgItemText (hwnd, IDC_PLAY_PAUSE, "Pause") ;
          bPaused = FALSE ;
          dwRepetitions = 1 ;
          bPlaying = FALSE ;
          
          if (bReverse)
          {
               ReverseMemory (pSaveBuffer, dwDataLength) ;
               bReverse = FALSE ;
          }
          
          if (bTerminating)
               SendMessage (hwnd, WM_SYSCOMMAND, SC_CLOSE, 0L) ;
          
          return TRUE ;
          
     case WM_SYSCOMMAND:
          switch (LOWORD (wParam))
          {
          case SC_CLOSE:
               if (bRecording)
               {
                    bTerminating = TRUE ;
                    bEnding = TRUE ;
                    waveInReset (hWaveIn) ;
                    return TRUE ;
               }
               
               if (bPlaying)
               {
                    bTerminating = TRUE ;
                    bEnding = TRUE ;
                    waveOutReset (hWaveOut) ;
                    return TRUE ;
               }
               
               free (pWaveHdr1) ;
               free (pWaveHdr2) ;
               free (pSaveBuffer) ;
               EndDialog (hwnd, 0) ;
               return TRUE ;
          }
          break ;
     }
     return FALSE ;
}
