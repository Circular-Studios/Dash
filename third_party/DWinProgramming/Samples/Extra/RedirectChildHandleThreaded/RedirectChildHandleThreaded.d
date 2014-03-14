module RedirectChildHandleThreaded;

pragma(lib, "gdi32.lib");

import core.memory;
import core.runtime;
import core.thread;
import core.stdc.string;
import std.concurrency;
import std.parallelism;
import std.conv;
import std.exception;
import std.file;
import std.math;
import std.range;
import std.string;
import std.utf;
import std.process;

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

struct ProcessInfo
{
    string procName;
    HANDLE childStdinRead;
    HANDLE childStdinWrite;
    HANDLE childStdoutRead;
    HANDLE childStdoutWrite;
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

void makeProcess(size_t index, string procName)
{
    makeProcess(procName, processInfos[index]);
}

void makeProcess(string procName, ProcessInfo procInfo)
{
    // Create a child process that uses the previously created pipes for STDIN and STDOUT.
    auto szCmdline = toUTFz!(wchar*)(procName);

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
        CloseHandle(piProcInfo.hProcess);
        CloseHandle(piProcInfo.hThread);
    }
}

/*
 * Note: If you want to print out in parallel you'll have to wrap the entire
 * writefln section in a synchronized block. E.g.:
 * synchronized { writefln(); while (1) { writefln("...");  } writeln(); }
 */
void readProcessPipe(size_t index, ProcessInfo procInfo)
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
    if (!CloseHandle(procInfo.childStdoutWrite))
        ErrorExit(("StdOutWr CloseHandle"));

    writefln("Process #%s:", index);

    while (1)
    {
        bSuccess = ReadFile(procInfo.childStdoutRead, chBuf.ptr, BUFSIZE, &dwRead, NULL);

        if (!bSuccess || dwRead == 0)
            break;

        // note: don't call writeln as you'll have text broken on new lines,
        // but make sure to either flush via stdout.flush() or call writeln();
        // write/writef don't flush
        write(chBuf[0..dwRead]);
    }

    writeln();
}

__gshared ProcessInfo[50] processInfos;

/*
 * Pick between spawn or taskPool.parallel. To make them
 * both work I've had to make processInfos global and add
 * forwarding functions for spawn(), which load a process
 * info by index.
 */
version = StdConcurrency;
//~ version = StdParallelism;

void main(string[] args)
{
    // workaround: build.d tries to build stub.d if it's present
    system(`echo module stub; void main() { } > stub.d`);
    scope(exit) { std.file.remove("stub.d"); }

    foreach (ref procInfo; processInfos)
    {
        createProcessPipes(procInfo);
    }

    writeln("\n->Start of parent execution.\n");

    version (StdParallelism)
    {
        foreach (procInfo; taskPool.parallel(processInfos[], 1))
        {
            makeProcess(r"dmd stub.d", procInfo);
        }
    }
    else
    version (StdConcurrency)
    {
        foreach (index; 0 .. processInfos.length)
        {
            spawn(&makeProcess, index, r"dmd stub.d");
        }
    }
    else
    static assert("Set version to StdParallelism or StdConcurrency");

    thread_joinAll();

    // read out sequentally, if you want to do it in parallel you have to make
    // sure you don't interleave your writeln calls (see readProcessPipe)
    foreach (index, procInfo; processInfos)
    {
        readProcessPipe(index, procInfo);
    }

    writeln("\n->End of parent execution.\n");

    // The remaining open handles are cleaned up when this process terminates.
    // To avoid resource leaks in a larger application, close handles explicitly.
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

    // protip: never use exit/exitProcess, your scope() statements won't run
    // and you'll end up with garbage on the drive (temporary files), etc.
    enforce(0);
}
