@echo off
setlocal EnableDelayedExpansion

set thisPath=%~dp0
set binPath=%thisPath%\bin
cd %thisPath%..

set import_libs=comctl32.lib ole32.lib
set subsystem=-L/SUBSYSTEM:WINDOWS:5.01

if [%1]==[] goto :error
if [%2]==[] goto :error
goto :next

:error
echo Error: Must pass project name and source name as arguments.
goto :eof

:next

set FileName=%1
set SourceFile=%2

rdmd -g -w %subsystem% %versions% -Ilib %import_libs% -of%binPath%\%FileName%.exe list_clipboard\dataobjview.res %SourceFile%
