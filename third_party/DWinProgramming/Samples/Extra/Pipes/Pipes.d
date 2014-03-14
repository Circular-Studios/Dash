module Pipes;

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

struct ProcessInfo
{
    HANDLE procHandle;
    string procName;
    HANDLE childStdinRead;
    HANDLE childStdinWrite;
    HANDLE childStdoutRead;
    HANDLE childStdoutWrite;    
}

int getReturnCode(ref ProcessInfo procInfo)
{
    WaitForSingleObject(procInfo.procHandle, INFINITE);
    DWORD exitCode = 0;

    if (GetExitCodeProcess(procInfo.procHandle, &exitCode))
    {
        // successfully retrieved exit code
        return exitCode;
    }
    else
    {
        writeln("failed to get return code.");
        //~ ErrorExit("CreateProcess");
    }
    CloseHandle(procInfo.procHandle);
    
    return exitCode;
}

ProcessInfo createProcessPipes()
{
    ProcessInfo pi;
    createProcessPipes(pi);
    return pi;
}

void createProcessPipes(ref ProcessInfo procInfo)
{
    SECURITY_ATTRIBUTES saAttr;

    // Set the bInheritHandle flag so pipe handles are inherited.
    saAttr.nLength        = SECURITY_ATTRIBUTES.sizeof;
    saAttr.bInheritHandle = true;

    with (procInfo)
    {
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
    }
}

string readProcessPipeString(ProcessInfo procInfo)
{
    // Read output from the child process's pipe for STDOUT
    // and write to the parent process's pipe for STDOUT.
    // Stop when there is no more data.
    DWORD  dwRead, dwWritten;
    CHAR[BUFSIZE]   chBuf;
    BOOL   bSuccess      = false;
    HANDLE hParentStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
    string buffer;
    buffer.reserve(4096 * 16);
    
    // Close the write end of the pipe before reading from the
    // read end of the pipe, to control child process execution.
    // The pipe is assumed to have enough buffer space to hold the
    // data the child process has already written to it.
    if (!CloseHandle(procInfo.childStdoutWrite))
        ErrorExit(("StdOutWr CloseHandle"));
    
    while (1)
    {
        bSuccess = ReadFile(procInfo.childStdoutRead, chBuf.ptr, BUFSIZE, &dwRead, NULL);

        if (!bSuccess || dwRead == 0)
            break;

        buffer ~= chBuf[0..dwRead];
    }
    
    return buffer;
}

// Create a child process that uses the previously created pipes for STDIN and STDOUT.
void runProcess(string command, ref ProcessInfo procInfo)
{
    auto szCmdline = toUTFz!(wchar*)(command);

    PROCESS_INFORMATION piProcInfo;
    STARTUPINFO siStartInfo;
    BOOL bSuccess = false;

    // Set up members of the STARTUPINFO structure.
    // This structure specifies the STDIN and STDOUT handles for redirection.
    siStartInfo.cb         = STARTUPINFO.sizeof;
    siStartInfo.hStdError  = procInfo.childStdoutWrite;  // we should replace this
    siStartInfo.hStdOutput = procInfo.childStdoutWrite;
    siStartInfo.hStdInput  = procInfo.childStdinRead;
    siStartInfo.dwFlags |= STARTF_USESTDHANDLES;

    if (CreateProcess(NULL,
                      szCmdline,    // command line
                      NULL,         // process security attributes
                      NULL,         // primary thread security attributes
                      true,         // handles are inherited
                      0,            // creation flags
                      NULL,         // use parent's environment
                      NULL,         // use parent's current directory
                      &siStartInfo, // STARTUPINFO pointer
                      &piProcInfo) == 0) // receives PROCESS_INFORMATION
    {
        ErrorExit("CreateProcess");
    }
    else
    {
        procInfo.procHandle = OpenProcess(SYNCHRONIZE | PROCESS_QUERY_INFORMATION, FALSE, piProcInfo.dwProcessId);
    }
}

Tuple!(int, "status", string, "output") execute(string command)
{
    auto procInfo = createProcessPipes();
    runProcess(command, procInfo);

    typeof(return) r;
    r.output = readProcessPipeString(procInfo);
    r.status = getReturnCode(procInfo);
    return r;
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

void main(string[] args)
{
    auto pc = execute("dmd test.d");
    writeln("status: ", pc.status);
    writeln(pc.output);
}

