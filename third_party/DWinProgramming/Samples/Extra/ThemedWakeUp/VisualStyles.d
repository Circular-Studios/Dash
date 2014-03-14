/+
 + Taken from DFL. See license.txt
 + DFL is Copyright (C) 2004-2010 Christopher E. Miller
 + Official DFL website: http://www.dprogramming.com/dfl.php
 + 
 + Init function for visual styles.
 +/

module VisualStyles;

import core.memory;
import core.runtime;
import core.thread;
import std.conv;
import std.math;
import std.exception;
import std.range;
import std.string;
import std.utf;
import std.stdio;

pragma(lib, "gdi32.lib");

import win32.windef;
import win32.winuser;
import win32.wingdi;
import win32.winbase;
import win32.aclapi;
import win32.commctrl;
pragma(lib, "comctl32.lib");
pragma(lib, "advapi32.lib");

UINT DWP_Msg;
static this()
{
    DWP_Msg = RegisterWindowMessageA("WM_DWP");

    if (!DWP_Msg) DWP_Msg = WM_USER + 0x7CD;
}

private extern (Windows)
{
    alias UINT function(LPCWSTR lpPathName, LPCWSTR lpPrefixString, UINT uUnique,
                        LPWSTR lpTempFileName) GetTempFileNameWProc;
    alias DWORD function(DWORD nBufferLength, LPWSTR lpBuffer) GetTempPathWProc;
    alias HANDLE function(PACTCTXW pActCtx) CreateActCtxWProc;
    alias BOOL function(HANDLE hActCtx, ULONG_PTR* lpCookie) ActivateActCtxProc;
    alias BOOL function(LPINITCOMMONCONTROLSEX lpInitCtrls) InitCommonControlsExProc;
}

void _initCommonControls(DWORD dwControls)
{
    version (SUPPORTS_COMMON_CONTROLS_EX)
    {
        pragma(msg, "DFL: extended common controls supported at compile time");
        alias InitCommonControlsEx initProc;
    }
    else
    {
        // Make sure InitCommonControlsEx() is in comctl32.dll,
        // otherwise use the old InitCommonControls().

        HMODULE hmodCommonControls;
        InitCommonControlsExProc initProc;

        hmodCommonControls = LoadLibraryA("comctl32.dll");

        if (!hmodCommonControls)
            //	throw new DflException("Unable to load 'comctl32.dll'");
            goto no_comctl32;

        initProc = cast(InitCommonControlsExProc) GetProcAddress(hmodCommonControls, "InitCommonControlsEx");

        if (!initProc)
        {
            //FreeLibrary(hmodCommonControls);
no_comctl32:
            InitCommonControls();
            return;
        }
    }

    INITCOMMONCONTROLSEX icce;
    icce.dwSize = INITCOMMONCONTROLSEX.sizeof;
    icce.dwICC  = dwControls;
    initProc(&icce);
}

// Taken from DFL, written by Christopher E. Miller
void enableVisualStyles()
{
    enum MANIFEST = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` "\r\n"
                    `<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">` "\r\n"
                    `<description>DFL manifest</description>` "\r\n"
                    `<dependency>` "\r\n"
                    `<dependentAssembly>` "\r\n"
                    `<assemblyIdentity `
                    `type="win32" `
                    `name="Microsoft.Windows.Common-Controls" `
                    `version="6.0.0.0" `
                    `processorArchitecture="X86" `
                    `publicKeyToken="6595b64144ccf1df" `
                    `language="*" `
                    `/>` "\r\n"
                    `</dependentAssembly>` "\r\n"
                    `</dependency>` "\r\n"
                    `</assembly>` "\r\n";

    HMODULE kernel32;
    kernel32 = GetModuleHandleA("kernel32.dll");

    //if(kernel32)
    enforce(kernel32 !is null);
    {
        CreateActCtxWProc createActCtxW;
        createActCtxW = cast(CreateActCtxWProc) GetProcAddress(kernel32, "CreateActCtxW");

        if (createActCtxW)
        {
            //~ writeln("createActCtxW");
            GetTempPathWProc getTempPathW;
            GetTempFileNameWProc getTempFileNameW;
            ActivateActCtxProc activateActCtx;

            getTempPathW = cast(GetTempPathWProc) GetProcAddress(kernel32, "GetTempPathW");
            assert(getTempPathW !is null);
            getTempFileNameW = cast(GetTempFileNameWProc) GetProcAddress(kernel32, "GetTempFileNameW");
            assert(getTempFileNameW !is null);
            activateActCtx = cast(ActivateActCtxProc) GetProcAddress(kernel32, "ActivateActCtx");
            assert(activateActCtx !is null);

            DWORD pathlen;
            wchar[MAX_PATH] pathbuf = void;

            //if(pathbuf)
            {
                pathlen = getTempPathW(pathbuf.length, pathbuf.ptr);

                if (pathlen)
                {
                    //~ writeln("pathlen");
                    DWORD manifestlen;
                    wchar[MAX_PATH] manifestbuf = void;

                    //if(manifestbuf)
                    {
                        manifestlen = getTempFileNameW(pathbuf.ptr, "dmf", 0, manifestbuf.ptr);

                        if (manifestlen)
                        {
                            //~ writeln("manifestlen");
                            HANDLE hf;
                            hf = CreateFileW(manifestbuf.ptr, GENERIC_WRITE, 0, null, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_SEQUENTIAL_SCAN, HANDLE.init);

                            if (hf != INVALID_HANDLE_VALUE)
                            {
                                //~ writeln("hf != INVALID_HANDLE_VALUE");
                                DWORD written;

                                if (WriteFile(hf, MANIFEST.ptr, MANIFEST.length, &written, null))
                                {
                                    //~ writeln("WriteFile(hf, MANIFEST.ptr, MANIFEST.length, &written, null)");
                                    CloseHandle(hf);

                                    ACTCTXW ac;
                                    HANDLE  hac;

                                    ac.cbSize = ACTCTXW.sizeof;

                                    //ac.dwFlags = 4; // ACTCTX_FLAG_ASSEMBLY_DIRECTORY_VALID
                                    ac.dwFlags  = 0;
                                    ac.lpSource = manifestbuf.ptr;

                                    //ac.lpAssemblyDirectory = pathbuf; // ?

                                    hac = createActCtxW(&ac);

                                    if (hac != INVALID_HANDLE_VALUE)
                                    {
                                        //~ writeln("hac != INVALID_HANDLE_VALUE");
                                        ULONG_PTR ul;
                                        activateActCtx(hac, &ul);

                                        _initCommonControls(ICC_STANDARD_CLASSES); // Yes.
                                        //InitCommonControls(); // No. Doesn't work with common controls version 6!

                                        // Ensure the actctx is actually associated with the message queue...
                                        PostMessageA(null, DWP_Msg, 0, 0);
                                        {
                                            MSG msg;
                                            PeekMessageA(&msg, null, DWP_Msg, DWP_Msg, PM_REMOVE);
                                        }
                                    }
                                    else
                                    {
                                        debug (APP_PRINT)
                                            cprintf("CreateActCtxW failed.\n");
                                    }
                                }
                                else
                                {
                                    CloseHandle(hf);
                                }
                            }

                            DeleteFileW(manifestbuf.ptr);
                        }
                    }
                }
            }
        }
    }
}
