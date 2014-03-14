@echo off
setlocal EnableDelayedExpansion

set thisPath=%~dp0
set binPath=%thisPath%\bin
cd %thisPath%

set import_libs=comctl32.lib ole32.lib

if [%1]==[] goto :error
if [%2]==[] goto :error
goto :next

:error
echo Error: Must pass project name and source name as arguments.
goto :eof

:next

set FileName=%1
set SourceFile=%2

rdmd -g -w -L/SUBSYSTEM:WINDOWS:5.01 %versions% -Ilib %import_libs% -of%binPath%\%FileName%.exe %SourceFile%
