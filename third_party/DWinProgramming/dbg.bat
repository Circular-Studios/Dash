@echo off
setlocal EnableDelayedExpansion
set "exe="
FOR /F "tokens=*" %%i in ('where %1') do SET exe=%%i 
echo %exe%
ddbg %exe% %*
