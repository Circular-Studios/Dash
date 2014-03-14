/*----------------------------------------
   RECORD3.C -- Waveform Audio Recorder
                (c) Charles Petzold, 1998
  ----------------------------------------*/

#include <windows.h>
#include "..\\record1\\resource.h"

BOOL CALLBACK DlgProc (HWND, UINT, WPARAM, LPARAM) ;

TCHAR szAppName [] = "Record3" ;

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

BOOL mciExecute (LPCTSTR szCommand)
{
     MCIERROR error ;
     TCHAR    szErrorStr [1024] ;

     if (error = mciSendString (szCommand, NULL, 0, NULL))
     {
          mciGetErrorString (error, szErrorStr, 
                             sizeof (szErrorStr) / sizeof (TCHAR)) ;
          MessageBeep (MB_ICONEXCLAMATION) ;
          MessageBox (NULL, szErrorStr, "MCI Error", 
                      MB_OK | MB_ICONEXCLAMATION) ;
     }
     return error == 0 ;
}

BOOL CALLBACK DlgProc (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
     static BOOL bRecording, bPlaying, bPaused ;
     
     switch (message)
     {
     case WM_COMMAND:
          switch (wParam)
          {
          case IDC_RECORD_BEG:
                    // Delete existing waveform file
               
               DeleteFile "record3.wav" ;
               
                    // Open waveform audio and record
               
               if (!mciExecute "open new type waveaudio alias mysound")
                    return TRUE ;
               
               mciExecute "record mysound" ;
               
                    // Enable and disable buttons
               
               EnableWindow (GetDlgItem (hwnd, IDC_RECORD_BEG), FALSE);
               EnableWindow (GetDlgItem (hwnd, IDC_RECORD_END), TRUE) ;
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_BEG),   FALSE);
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_PAUSE), FALSE);
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_END),   FALSE);
               SetFocus (GetDlgItem (hwnd, IDC_RECORD_END)) ;
               
               bRecording = TRUE ;
               return TRUE ;
               
          case IDC_RECORD_END:
                    // Stop, save, and close recording
               
               mciExecute "stop mysound" ;
               mciExecute "save mysound record3.wav" ;
               mciExecute "close mysound" ;
               
                    // Enable and disable buttons
               
               EnableWindow (GetDlgItem (hwnd, IDC_RECORD_BEG), TRUE) ;
               EnableWindow (GetDlgItem (hwnd, IDC_RECORD_END), FALSE);
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_BEG),   TRUE) ;
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_PAUSE), FALSE);
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_END),   FALSE);
               SetFocus (GetDlgItem (hwnd, IDC_PLAY_BEG)) ;
               
               bRecording = FALSE ;
               return TRUE ;
               
          case IDC_PLAY_BEG:
                    // Open waveform audio and play
               
               if (!mciExecute "open record3.wav alias mysound")
                    return TRUE ;
               
               mciExecute "play mysound" ;
               
                    // Enable and disable buttons
               
               EnableWindow (GetDlgItem (hwnd, IDC_RECORD_BEG), FALSE);
               EnableWindow (GetDlgItem (hwnd, IDC_RECORD_END), FALSE);
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_BEG),   FALSE);
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_PAUSE), TRUE) ;
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_END),   TRUE) ;
               SetFocus (GetDlgItem (hwnd, IDC_PLAY_END)) ;
               
               bPlaying = TRUE ;
               return TRUE ;
               
          case IDC_PLAY_PAUSE:
               if (!bPaused)
                         // Pause the play
               {
                    mciExecute "pause mysound" ;
                    SetDlgItemText (hwnd, IDC_PLAY_PAUSE, "Resume") ;
                    bPaused = TRUE ;
               }
               else
                         // Begin playing again
               {
                    mciExecute "play mysound" ;
                    SetDlgItemText (hwnd, IDC_PLAY_PAUSE, "Pause") ;
                    bPaused = FALSE ;
               }
               
               return TRUE ;
               
          case IDC_PLAY_END:
                    // Stop and close
               
               mciExecute "stop mysound" ;
               mciExecute "close mysound" ;
               
                    // Enable and disable buttons
               
               EnableWindow (GetDlgItem (hwnd, IDC_RECORD_BEG), TRUE) ;
               EnableWindow (GetDlgItem (hwnd, IDC_RECORD_END), FALSE);
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_BEG),   TRUE) ;
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_PAUSE), FALSE);
               EnableWindow (GetDlgItem (hwnd, IDC_PLAY_END),   FALSE);
               SetFocus (GetDlgItem (hwnd, IDC_PLAY_BEG)) ;
               
               bPlaying = FALSE ;
               bPaused  = FALSE ;
               return TRUE ;
          }
          break ;
     
     case WM_SYSCOMMAND:
          switch (wParam)
          {
          case SC_CLOSE:
               if (bRecording)
                    SendMessage (hwnd, WM_COMMAND, IDC_RECORD_END, 0L);
               
               if (bPlaying)
                    SendMessage (hwnd, WM_COMMAND, IDC_PLAY_END, 0L) ;
               
               EndDialog (hwnd, 0) ;
               return TRUE ;
          }
          break ;
     }
     return FALSE ;
}
