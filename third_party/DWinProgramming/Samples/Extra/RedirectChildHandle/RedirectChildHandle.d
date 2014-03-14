module RedirectChildHandle;

// Note: See the Pipe sample instead, which is a minimal pipe example
// with an execute() API same as the upcoming std.process module.

pragma(lib, "gdi32.lib");

import core.memory;
import core.runtime;
import core.thread;
import core.stdc.string;
import std.conv;
import std.math;
import std.range;
import std.string;
import std.utf;

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;

import std.algorithm;
import std.array;
import std.stdio;
import std.conv;
import std.typetuple;
import std.typecons;
import std.traits;

enum BUFSIZE = 4096;

// Todo: Comment from NG:
// in RedirectChildHandle.d, CreateChildProcess, you should be closing childStdoutWrite and childStdinRead after CreateProcess.  If you don't you get 2 copies of them, one in the child and one in the parent.  If the child closes its copy the parent will not notice the pipe close (when reading from the other end of the pipe - for example).  If you close it, it will mean that you will actually drop out of a blocking read in the parent immediately (when the child terminates), rather than timing out and then discovering the child has terminated (using the thread or process handle).

HANDLE childStdinRead;
HANDLE childStdinWrite;
HANDLE childStdoutRead;
HANDLE childStdoutWrite;

HANDLE hInputFile;

wstring fromUTF16z(const wchar* s)
{
    if (s is null) return null;

    wchar* ptr;
    for (ptr = cast(wchar*)s; *ptr; ++ptr) {}

    return to!wstring(s[0..ptr-s]);
}

auto toUTF16z(S)(S s)
{
    return toUTFz!(const(wchar)*)(s);
}

// console
void main(string[] args)
{
    string[] argv = ["RedirectStdChildProcess.exe", "empty.txt"];  // simulate args
    
    SECURITY_ATTRIBUTES saAttr;

    writeln("\n->Start of parent execution.\n");

    // Set the bInheritHandle flag so pipe handles are inherited.
    saAttr.nLength        = SECURITY_ATTRIBUTES.sizeof;
    saAttr.bInheritHandle = true;

    // Create a pipe for the child process's STDOUT.
    if (!CreatePipe(/* out */ &childStdoutRead, /* out */ &childStdoutWrite, &saAttr, 0) )
        ErrorExit(("StdoutRd CreatePipe"));

    // Ensure the read handle to the pipe for STDOUT is not inherited (sets to 0)
    if (!SetHandleInformation(childStdoutRead, HANDLE_FLAG_INHERIT, 0) )
        ErrorExit(("Stdout SetHandleInformation"));

    // Create a pipe for the child process's STDIN.
    if (!CreatePipe(&childStdinRead, &childStdinWrite, &saAttr, 0))
        ErrorExit(("Stdin CreatePipe"));

    // Ensure the write handle to the pipe for STDIN is not inherited. (sets to 0)
    if (!SetHandleInformation(childStdinWrite, HANDLE_FLAG_INHERIT, 0) )
        ErrorExit(("Stdin SetHandleInformation"));

    // Create the child process.
    CreateChildProcess();

    // Read from pipe that is the standard output for child process.
    writeln("\n->Contents of child process STDOUT:\n\n", argv[1]);
    ReadFromPipe();

    writeln("\n->End of parent execution.\n");

    // The remaining open handles are cleaned up when this process terminates.
    // To avoid resource leaks in a larger application, close handles explicitly.
}

void CreateChildProcess()
{
    // Create a child process that uses the previously created pipes for STDIN and STDOUT.
    auto szCmdline = toUTFz!(wchar*)("dmd");

    PROCESS_INFORMATION piProcInfo;
    STARTUPINFO siStartInfo;
    BOOL bSuccess = false;

    // Set up members of the STARTUPINFO structure.
    // This structure specifies the STDIN and STDOUT handles for redirection.
    siStartInfo.cb         = STARTUPINFO.sizeof;
    siStartInfo.hStdError  = childStdoutWrite;  // we should replace this
    siStartInfo.hStdOutput = childStdoutWrite;
    siStartInfo.hStdInput  = childStdinRead;
    siStartInfo.dwFlags |= STARTF_USESTDHANDLES;

    // Create the child process.
    bSuccess = CreateProcess(NULL,
                             szCmdline,    // command line
                             NULL,         // process security attributes
                             NULL,         // primary thread security attributes
                             true,         // handles are inherited
                             0,            // creation flags
                             NULL,         // use parent's environment
                             NULL,         // use parent's current directory
                             &siStartInfo, // STARTUPINFO pointer
                             &piProcInfo); // receives PROCESS_INFORMATION

    // If an error occurs, exit the application.
    if (!bSuccess)
        ErrorExit(("CreateProcess"));
    else
    {
        // Close handles to the child process and its primary thread.
        // Some applications might keep these handles to monitor the status
        // of the child process, for example.

        // close 
        CloseHandle(childStdoutWrite);
        CloseHandle(childStdinRead);
        
        CloseHandle(piProcInfo.hProcess);
        CloseHandle(piProcInfo.hThread);
    }
}

void WriteToPipe()
{
    // Read from a file and write its contents to the pipe for the child's STDIN.
    // Stop when there is no more data.
    DWORD dwRead, dwWritten;
    CHAR[BUFSIZE]  chBuf;
    BOOL  bSuccess = false;

    while (1)
    {
        bSuccess = ReadFile(hInputFile, chBuf.ptr, BUFSIZE, &dwRead, NULL);

        if (!bSuccess || dwRead == 0)
            break;

        bSuccess = WriteFile(childStdinWrite, chBuf.ptr, dwRead, &dwWritten, NULL);

        if (!bSuccess)
            break;
    }

    // Close the pipe handle so the child process stops reading.

    if (!CloseHandle(childStdinWrite) )
        ErrorExit(("StdInWr CloseHandle"));
}

void ReadFromPipe()
{
    // Read output from the child process's pipe for STDOUT
    // and write to the parent process's pipe for STDOUT.
    // Stop when there is no more data.
    DWORD  dwRead, dwWritten;
    CHAR[BUFSIZE]   chBuf;
    BOOL   bSuccess      = false;
    HANDLE hParentStdOut = GetStdHandle(STD_OUTPUT_HANDLE);

    // Close the write end of the pipe before reading from the
    // read end of the pipe, to control child process execution.
    // The pipe is assumed to have enough buffer space to hold the
    // data the child process has already written to it.
    CloseHandle(childStdoutWrite);
    //~ if (!CloseHandle(childStdoutWrite))
        //~ ErrorExit(("StdOutWr CloseHandle"));

    while (1)
    {
        bSuccess = ReadFile(childStdoutRead, chBuf.ptr, BUFSIZE, &dwRead, NULL);

        if (!bSuccess || dwRead == 0)
            break;

        // here we would synchronously write
        bSuccess = WriteFile(hParentStdOut, chBuf.ptr, dwRead, &dwWritten, NULL);

        if (!bSuccess)
            break;
    }
}

void ErrorExit(string lpszFunction)
{
    // Format a readable error message, display a message box,
    // and exit from the application.
    LPVOID lpMsgBuf;
    LPVOID lpDisplayBuf;
    DWORD  dw = GetLastError();

    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        cast(LPTSTR)&lpMsgBuf,
        0, NULL);    
    
    lpDisplayBuf = cast(LPVOID)LocalAlloc(LMEM_ZEROINIT,
                                      (lstrlen(cast(LPCTSTR)lpMsgBuf) + lstrlen(cast(LPCTSTR)lpszFunction) + 40) * (TCHAR.sizeof));
    
    auto str = format("%s failed with error %s: %s",
                      lpszFunction,
                      dw,
                      fromUTF16z(cast(wchar*)lpMsgBuf)
                      );
    writeln(str);
    ExitProcess(1);
}
