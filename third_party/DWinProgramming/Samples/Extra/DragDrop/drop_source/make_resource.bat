@echo off
set rc="C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin\RC.exe"
%rc% /i"C:\Program Files\Microsoft SDKs\Windows\v7.1\Include" /i"C:\Program Files\Microsoft Visual Studio 10.0\VC\include" /i"C:\Program Files\Microsoft Visual Studio 10.0\VC\atlmfc\include" resource.rc
