# DWinProgramming - D WinAPI programming
This is a collection of samples from Charles Petzold's Programming Windows book,
translated into the D programming language. It also contains a small collection
of other Windows API samples.

See examples.txt for a description of the samples.

This project has been created by Andrej Mitrovic.
Project Homepage: https://github.com/AndrejMitrovic/DWinProgramming

## Building Requirements
- Windows XP or newer.
- Compiler: [DMD] v2.063+ or [GDC] 2.063+.

[DMD]: http://www.digitalmars.com/d/download.html
[GDC]: https://bitbucket.org/goshawk/gdc/downloads

## Building

**NOTE**: At least two samples will fail to build on 2.063 due to these issues:

- [Issue 10468](http://d.puremagic.com/issues/show_bug.cgi?id=10468) - Regression (2.063): Lockstep no longer works with iota
- [Issue 10469](http://d.puremagic.com/issues/show_bug.cgi?id=10469) - WinAPI declarations in std.process should be moved to core.sys.windows.windows

Compile the build script:

    $ make_build.bat

To build via DMD:

    $ build.exe

To build via GDC:

    $ build.exe GDC
    Building all samples is quite slow with GDC at the moment.

To build only a single example, CD to its directory and run:

    $ ..\..\..\build.exe filename.d (filename being the main file)

Other options are: clean, debug.

## Useful Scripts
- Use `dbg.bat` to quickly invoke the ddbg debugger on an executable. ('dbg main.exe')
- Use `gdmd.bat` to invoke the GDMD perl script. ('gdmd main.d -ofmain.exe')
- Use `where.bat` to find out the location of an exe/batch file. ('where dmd')

## Optional Tools
- HTOD: http://www.digitalmars.com/d/2.0/htod.html
    HTOD needs to be in your PATH. It's probably best to put it in the \DMD2\Windows\Bin
    directory.

- Microsoft RC compiler and header files. Without these the build script will use
  precompiled .res files.
    - Unless you have Visual Studio installed, get it from:
    http://www.microsoft.com/downloads/en/details.aspx?FamilyID=c17ba869-9671-4330-a63e-1fd44e0e2505&displaylang=en
    - RC needs to be in your PATH if you want to compile resources. If you have Visual Studio installed, you can use the Visual Studio Command Prompt.

    Note: This is a big download, depending on what you select in the setup.
    Note: DigitalMars has a resource compiler, but it still requires header files.
          See the "Using Resources in D" Tutorial in the Links section.

    - Create the RCINCLUDES environment variable and add paths to the header files needed
      by the RC resource compiler.
      On an XP system these paths could be:
        C:\Program Files\Microsoft SDKs\Windows\v7.1\Include
        C:\Program Files\Microsoft Visual Studio 10.0\VC\include
        C:\Program Files\Microsoft Visual Studio 10.0\VC\atlmfc\include

      Typically the include paths for resource header files are different on each system,
      so you will have to adjust these.

    Note: The build script will attempt to find these default paths if you don't have
          RCINCLUDES already set up.
    Note: Setting up an environment variable might require you to log off and log on
          again before the build script can pick up the new changes.

- The uncrustify executable bundled with UniversalIndentGUI could be outdated compared to
  the latest Uncrustify version.
  Please see the Uncrustify homepage in the Links section in this Readme to get the
  latest binary or to compile from source.

## Contact
Please do not e-mail Charles Petzold about bugs in these examples,
any bugs in these samples are entirely my fault.
File bugs here: https://github.com/AndrejMitrovic/DWinProgramming/issues

## Acknowledgments
Thanks to the authors of the WindowsAPI translation project:
http://dsource.org/projects/bindings/wiki/WindowsApi

Big Thanks to Charles Petzold for writing a great Windows API programming book and
for allowing me to host these code samples online.

## Contributors
Simen Endsjø tested the project on an x64 Win7 system and found several issues.
Leonardo Maffi created a Python script that got rid of stray parens.

Thanks goes out to all contributors.

## Licensing
All code examples copyright belongs to Charles Petzold.
Also see the answer to the 3rd question here:
http://www.charlespetzold.com/faq.html

## Links
D2 Programming Language Homepage: http://d-programming-language.org/

Code samples of using Win32 API and Cairo: https://github.com/AndrejMitrovic/cairoDSamples

How to make extensionless files open in your editor in WinXP: http://perishablepress.com/press/2006/08/08/associate-extensionless-files-with-notepad/
    Note: Also, make sure you hit the 'Open with' button and select your editor.

How to make extensionless files open in your editor in Windows 7 and Windows 8 (and probably XP):
Run this in the command prompt:
    assoc .="No Extension"
    ftype "No Extension"="C:\path\to\your editor.exe" "%1"
Also see http://superuser.com/a/13947/47065

Programming Windows Homepage: http://www.charlespetzold.com/pw5/

Programming Windows C Code Samples: http://www.charlespetzold.com/books.html
(search for ProgWin5.zip)

Charles Petzold FAQ: http://www.charlespetzold.com/faq.html

Programming Windows Errata #1: http://www.computersciencelab.com/PetzoldErrata.htm

Programming Windows Errata #2: http://www.jasondoucette.com/books/pw5/pw5errata.html

MSDN GDI page: http://msdn.microsoft.com/en-us/library/dd145203%28v=vs.85%29.aspx

MSDN list of Windows APIs: http://msdn.microsoft.com/en-us/library/ff818516.aspx

Windows API bindings: http://dsource.org/projects/bindings/wiki/WindowsApi

RDMD: http://www.digitalmars.com/d/2.0/rdmd.html

RDMD@github: https://github.com/D-Programming-Language/tools

HTOD: http://www.digitalmars.com/d/2.0/htod.html

DDBG D Debugger: http://ddbg.mainia.de/doc.html

Uncrustify - Code Beautifier: http://sourceforge.net/projects/uncrustify/develop

UniversalIndentGUI - GUI Frontend for Code Beautifiers:

http://universalindent.sourceforge.net/

Using Resources in D Tutorial: http://prowiki.org/wiki4d/wiki.cgi?D__Tutorial/WindowsResources

Unicode Character Viewer: http://rishida.net/scripts/uniview/

Environment Variables: http://www.computerhope.com/issues/ch000549.htm

Environment Editor: http://www.rapidee.com/
