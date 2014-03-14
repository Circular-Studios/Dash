module RedirectStdoutGui;

/*
    This is an initial attempt at a realtime GUI-based stdout redirection.
    This app spawns another app with redirected stdout. The child
    app prints some strings to stdout at regular intervals (via a timer).
    We capture the strings and draw them to the screen via DrawText.

    This isn't an ideal solution, but it's a start. The upcoming std.io
    replacement should come with stable IO redirection which will make
    this app much easier to write.
*/

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
import std.path;
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

__gshared string stdoutString;
__gshared string[20] capturedLines;
__gshared size_t capLineIndex;
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

        foreach (line; chBuf[0..dwRead].splitter("\n"))
        {
            if (capLineIndex == capturedLines.length)
                capLineIndex = 0;

            synchronized
            {
                capturedLines[capLineIndex++] = line.idup;
            }
        }

        //~ synchronized
        //~ {
            //~ stdoutString = chBuf[0..dwRead].idup;
        //~ }
    }
}

__gshared ProcessInfo[1] processInfos;

/*
 * Pick between spawn or taskPool.parallel. To make them
 * both work I've had to make processInfos global and add
 * forwarding functions for spawn(), which load a process
 * info by index.
 */
version = StdConcurrency;
//~ version = StdParallelism;

string exeString = r"subprocess\subprocess.exe";

void executeProcReadPipes()
{
    foreach (ref procInfo; processInfos)
    {
        createProcessPipes(procInfo);
    }

    writeln("\n->Start of child execution.\n");

    makeProcess(0, exeString);

    //~ Thread.sleep(dur!("seconds")(1));

    // read out sequentally, if you want to do it in parallel you have to make
    // sure you don't interleave your writeln calls (see readProcessPipe)
    foreach (index, procInfo; processInfos)
    {
        writeln("\n->Start readProcessPipe.\n");
        readProcessPipe(index, procInfo);
        writeln("\n->End readProcessPipe.\n");
    }

    writeln("\n->End of child execution.\n");

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

import core.runtime;
import std.string;
import std.stdio;
import std.utf;

pragma(lib, "gdi32.lib");
pragma(lib, "winmm.lib");

import win32.mmsystem;
import win32.windef;
import win32.winuser;
import win32.wingdi;

extern(Windows)
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
    catch(Throwable o)
    {
        win32.winuser.MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

int myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow)
{
    if (!exists(exeString))
    {
        import std.file;
        import std.exception;

        string path = buildPath(".".absolutePath, r"Samples\Extra\RedirectStdoutGui\subprocess");
        enforce(path.exists, path);
        chdir(path);
        system(`..\..\..\..\build.exe "%CD%"`);
        chdir(r"..\");
    }

    string appName = "HelloWin";
    HWND hwnd;
    MSG  msg;
    WNDCLASS wndclass;

    wndclass.style         = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc   = &WndProc;
    wndclass.cbClsExtra    = 0;
    wndclass.cbWndExtra    = 0;
    wndclass.hInstance     = hInstance;
    wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH)GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName  = NULL;
    wndclass.lpszClassName = appName.toUTF16z;

    if(!RegisterClass(&wndclass))
    {
        win32.winuser.MessageBox(NULL, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z,      // window class name
                         "Redirecter",  // window caption
                         WS_OVERLAPPEDWINDOW,  // window style
                         200,        // initial x position
                         200,        // initial y position
                         250,        // initial x size
                         250,        // initial y size
                         NULL,                 // parent window handle
                         NULL,                 // window menu handle
                         hInstance,            // program instance handle
                         NULL);                // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return msg.wParam;
}

extern(Windows)
LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    HDC hdc;
    PAINTSTRUCT ps;
    RECT rect;
    enum ID_TIMER = 1;

    switch (message)
    {
        case WM_CREATE:
        {
            SetTimer(hwnd, ID_TIMER, 200, NULL);
            spawn(&executeProcReadPipes);
            return 0;
        }

        case WM_TIMER:
        {
            InvalidateRect(hwnd, NULL, FALSE);
            return 0;
        }

        case WM_PAINT:
        {
            hdc = BeginPaint(hwnd, &ps);
            scope(exit) EndPaint(hwnd, &ps);

            GetClientRect(hwnd, &rect);

            rect.top = 0;
            foreach (line; capturedLines)
            {
                DrawText(hdc, toUTF16z(line), -1, &rect, DT_SINGLELINE);
                rect.top += 10;
            }

            return 0;
        }

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;

        default:
    }

    return DefWindowProc(hwnd, message, wParam, lParam);
}
