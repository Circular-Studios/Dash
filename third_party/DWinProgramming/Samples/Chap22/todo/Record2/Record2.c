/*----------------------------------------
   RECORD2.C -- Waveform Audio Recorder
                (c) Charles Petzold, 1998
------------------------------------------*/

#include <windows.h>
#include "..\\record1\\resource.h"

BOOL CALLBACK DlgProc (HWND, UINT, WPARAM, LPARAM) ;

TCHAR szAppName [] = "Record2" ;

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

void ShowError (HWND hwnd, DWORD dwError)
{
     TCHAR szErrorStr [1024] ;
     
     mciGetErrorString (dwError, szErrorStr, 
                        sizeof (szErrorStr) / sizeof (TCHAR)) ;
     MessageBeep (MB_ICONEXCLAMATION) ;
     MessageBox (hwnd, szErrorStr, szAppName, MB_OK | MB_ICONEXCLAMATION) ;
}

BOOL CALLBACK DlgProc (HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
     static BOOL       bRecording, bPlaying, bPaused ;
     static TCHAR      szFileName[] = "record2.wav" ;
     static WORD       wDeviceID ;
     DWORD             dwError ;
     MCI_GENERIC_PARMS mciGeneric ;
     MCI_OPEN_PARMS    mciOpen ;
     MCI_PLAY_PARMS    mciPlay ;
     MCI_RECORD_PARMS  mciRecord ;
     MCI_SAVE_PARMS    mciSave ;
     
     switch (message)
     {
     case WM_COMMAND:
          switch (wParam)
          {
          case IDC_RECORD_BEG:
                    // Delete existing waveform file
               
               DeleteFile (szFileName) ;
               
                    // Open waveform audio
               
               mciOpen.dwCallback       = 0 ;
               mciOpen.wDeviceID        = 0 ;
               mciOpen.lpstrDeviceType  = "waveaudio" ;
               mciOpen.lpstrElementName = "" ; 
               mciOpen.lpstrAlias       = NULL ;
               
               dwError = mciSendCommand (0, MCI_OPEN, 
                                   MCI_WAIT | MCI_OPEN_TYPE | MCI_OPEN_ELEMENT,
                                   (DWORD) (LPMCI_OPEN_PARMS) &mciOpen) ;
               if (dwError != 0)
               {
                    ShowError (hwnd, dwError) ;
                    return TRUE ;
               }
                    // Save the device ID
               
               wDeviceID = mciOpen.wDeviceID ;
               
                    // Begin recording
               
               mciRecord.dwCallback = (DWORD) hwnd ;
               mciRecord.dwFrom     = 0 ;
               mciRecord.dwTo       = 0 ;
               
               mciSendCommand (wDeviceID, MCI_RECORD, MCI_NOTIFY,
                               (DWORD) (LPMCI_RECORD_PARMS) &mciRecord) ;
               
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
                    // Stop recording
               
               mciGeneric.dwCallback = 0 ;
               
               mciSendCommand (wDeviceID, MCI_STOP, MCI_WAIT,
                               (DWORD) (LPMCI_GENERIC_PARMS) &mciGeneric) ;
               
                    // Save the file

               mciSave.dwCallback = 0 ;
               mciSave.lpfilename = szFileName ;
               
               mciSendCommand (wDeviceID, MCI_SAVE, MCI_WAIT | MCI_SAVE_FILE,
                               (DWORD) (LPMCI_SAVE_PARMS) &mciSave) ;
               
                    // Close the waveform device
               
               mciSendCommand (wDeviceID, MCI_CLOSE, MCI_WAIT,
                               (DWORD) (LPMCI_GENERIC_PARMS) &mciGeneric) ;
               
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
                    // Open waveform audio
               
               mciOpen.dwCallback       = 0 ;
               mciOpen.wDeviceID        = 0 ;
               mciOpen.lpstrDeviceType  = NULL ;
               mciOpen.lpstrElementName = szFileName ;
               mciOpen.lpstrAlias       = NULL ;
               
               dwError = mciSendCommand (0, MCI_OPEN,
                                         MCI_WAIT | MCI_OPEN_ELEMENT,
                                         (DWORD) (LPMCI_OPEN_PARMS) &mciOpen) ;
               
               if (dwError != 0)
               {
                    ShowError (hwnd, dwError) ;
                    return TRUE ;
               }
                    // Save the device ID
               
               wDeviceID = mciOpen.wDeviceID ;
               
                    // Begin playing
               
               mciPlay.dwCallback = (DWORD) hwnd ;
               mciPlay.dwFrom     = 0 ;
               mciPlay.dwTo       = 0 ;
               
               mciSendCommand (wDeviceID, MCI_PLAY, MCI_NOTIFY,
                               (DWORD) (LPMCI_PLAY_PARMS) &mciPlay) ;
               
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
                    mciGeneric.dwCallback = 0 ;
                    
                    mciSendCommand (wDeviceID, MCI_PAUSE, MCI_WAIT,
                                    (DWORD) (LPMCI_GENERIC_PARMS) & mciGeneric);
                    
                    SetDlgItemText (hwnd, IDC_PLAY_PAUSE, "Resume") ;
                    bPaused = TRUE ;
               }
               else
                         // Begin playing again
               {
                    mciPlay.dwCallback = (DWORD) hwnd ;
                    mciPlay.dwFrom     = 0 ;
                    mciPlay.dwTo       = 0 ;
                    
                    mciSendCommand (wDeviceID, MCI_PLAY, MCI_NOTIFY,
                                    (DWORD) (LPMCI_PLAY_PARMS) &mciPlay) ;
                    
                    SetDlgItemText (hwnd, IDC_PLAY_PAUSE, "Pause") ;
                    bPaused = FALSE ;
               }
               
               return TRUE ;
               
          case IDC_PLAY_END:
                    // Stop and close
               
               mciGeneric.dwCallback = 0 ;
               
               mciSendCommand (wDeviceID, MCI_STOP, MCI_WAIT,
                               (DWORD) (LPMCI_GENERIC_PARMS) &mciGeneric) ;
               
               mciSendCommand (wDeviceID, MCI_CLOSE, MCI_WAIT,
                               (DWORD) (LPMCI_GENERIC_PARMS) &mciGeneric) ;
               
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
               
     case MM_MCINOTIFY:
          switch (wParam)
          {
          case MCI_NOTIFY_SUCCESSFUL:
               if (bPlaying)
                    SendMessage (hwnd, WM_COMMAND, IDC_PLAY_END, 0) ;
               
               if (bRecording)
                    SendMessage (hwnd, WM_COMMAND, IDC_RECORD_END, 0);
               
               return TRUE ;
          }
          break ;
     
     case WM_SYSCOMMAND:
          switch (wParam)
          {
          case SC_CLOSE:
               if (bRecording)
                    SendMessage (hwnd, WM_COMMAND, IDC_RECORD_END, 0L) ;
               
               if (bPlaying)
                    SendMessage (hwnd, WM_COMMAND, IDC_PLAY_END, 0L) ;
               
               EndDialog (hwnd, 0) ;
               return TRUE ;
          }
          break ;
     }
     return FALSE ;
}
