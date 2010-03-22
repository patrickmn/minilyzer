@echo off
::::::
::
:: Minilyzer -- easily generate a Windows Minidump report using
:: Microsoft Debugging Tools for Windows (x86 and x64).
::
:: Version 1.1 -- January 25th, 2009
:: http://patrickmylund.com/projects/minilyzer/
:: by Patrick Mylund - patrick@patrickmylund.com
::
::::
::
:: Usage:
::   - Method 1: Simply run minilyzer.cmd, and it will try to analyze the newest DMP file
::               in the %WinDir%\Minidump folder.
::   - Method 2: Drag and drop a Minidump file onto minilyzer.cmd
::   - Method 3: From a command prompt, type e.g.: minilyzer.cmd "C:\Windows\Minidump\Mini012309-01.dmp"
::   - Method 4: Change 'minidump_file' below to a predefined file and run minilyzer.cmd
::
:: Requirements:
::   - Windows 2000 or later.
::   - Microsoft Debugging Tools for Windows (x86 or x64) installed.
::     Get it at: http://www.microsoft.com/whdc/devtools/debugging/
::
:: Notice:
::   - Keep the symbol cache folder in the same folder as minilyzer.cmd for speedier future debugging.
::   - Minilyzer will, by default, not have read rights on the DMP files in %WinDir%\Minidump on Windows
::     with UAC enabled. Simply copy the Minidump file to your desktop first or give yourself read rights
::     in the file's Security settings to get around this.
::   - Minilyzer with Debugging Tools for Intel Itanium (IA-64) Native has not yet been tested.
::
::::
::
:: Minilyzer is released under the MIT License:
::
:: Copyright (c) 2009 Patrick Mylund
::
:: Permission is hereby granted, free of charge, to any person obtaining a copy
:: of this software and associated documentation files (the "Software"), to deal
:: in the Software without restriction, including without limitation the rights
:: to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
:: copies of the Software, and to permit persons to whom the Software is
:: furnished to do so, subject to the following conditions:
::
:: The above copyright notice and this permission notice shall be included in
:: all copies or substantial portions of the Software.
::
:: THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
:: IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
:: FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
:: AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
:: LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
:: OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
:: THE SOFTWARE.
::
::::::

:: Change to e.g. set minidump_file="C:\Windows\Minidump\Mini012309-01.dmp" to analyze that specific file.
:: Access to system folders will not work on Windows Vista or Windows 7 without elevated rights, or UAC disabled.
:: minidump_file=%1 uses the first argument given to the script; if that argument is empty, Minilyzer will
:: try to find the most recent DMP file in %WinDir%\Minidump and analyze that.
set minidump_file=%1

:: Where to put the report and symbol cache folder, e.g.: set working_dir="C:\Minilyzer"
:: set working_dir="%~dp0" to use minilyzer.cmd's current directory.
set working_dir="%~dp0"

:: Change this if Debugging Tools is installed in a custom folder, e.g.: set x64dbg_path=M:\dbgtools
:: If you are on a 64-bit system and want to use the 32-bit Debugging Tools, do:
:: set x86dbg_path=%ProgramFiles(x86)%\Debugging Tools for Windows (x86)
set x86dbg_path=%ProgramFiles%\Debugging Tools for Windows (x86)
set x64dbg_path=%ProgramFiles%\Debugging Tools for Windows (x64)

:: Modify this to change the report's file format. If you remove %hh% and %mm%, remove
:: the for loop as well (next 4 lines), as it'll have no use.
for /f "tokens=1-2 delims=/: " %%a in ('time /t') do (
set hh=%%a
set mm=%%b
)
set logfile=minilyzer_%date%_%hh%-%mm%.log

:: What should the drumroll command be? This is the last command executed, whether there
:: was an error or not. Leave blank to disable; "set drumroll_command="
set drumroll_command=start notepad %logfile%

:: Where to fetch debugging symbols?
set symbol_url=http://msdl.microsoft.com/download/symbols

:: What to call the symbol cache folder?
set symbol_folder=Minilyzer Debugging Symbols

:: Parameters for the Kernel Debugger (kd.exe), excluding "-z %minidump-file%"
set dbg_params=-y "srv*%symbol_folder%*%symbol_url%" -loga %logfile%

:: Command to feed kd.exe
set dbg_cmd=!analyze -v;r;kv;lmnt;q

:: Color output? See 'color /?' for color codes.
color 9F

:::::::::::::::::::::::::::::::::::::::::::::::::
:::::::: No need to change anything else ::::::::
:::::::::::::::::::::::::::::::::::::::::::::::::

cd /d %working_dir%
echo Minilyzer 1.1 starting... > %logfile%
echo ----- >> %logfile%
echo. >> %logfile%
if [%minidump_file%] ==  [] goto findfile
if not exist %minidump_file% goto filefail
goto finddbg

:findfile
:: Performance-conscious programming ;-)
for /f %%i in ('dir %WinDir%\Minidump\*.dmp /b') do (
set minidump_file="%WinDir%\Minidump\%%i"
)
if [%minidump_file%] == [] goto filefail
goto finddbg

:finddbg
if exist "%x86dbg_path%\kd.exe" goto x86
if exist "%x64dbg_path%\kd.exe" goto x64
goto toolfail

:x86
title Minilyzer (x86): %minidump_file%
echo %dbg_cmd% | "%x86dbg_path%\kd.exe" %dbg_params% -z %minidump_file%
if %errorlevel% neq 0 goto confused
goto finished

:x64
title Minilyzer (x64): %minidump_file%
echo %dbg_cmd% | "%x64dbg_path%\kd.exe" %dbg_params% -z %minidump_file%
if %errorlevel% neq 0 goto confused
goto finished

:filefail
echo Analysis failed; No Minidump file specified, or it was not found (%minidump_file%). >> %logfile%
echo Specify it as a parameter or drag and drop it onto the script to analyze. >> %logfile%
echo If Minilyzer is run without parameters, the newest DMP file in %WinDir%\Minidump will be analyzed. >> %logfile%
echo. >> %logfile%
echo Note: You can also change 'minidump_file' in this script to predefine a Minidump file. >> %logfile%
goto drumroll

:toolfail
echo Analysis failed; Debugging Tools for Windows is not installed. >> %logfile%
echo Get it at: http://www.microsoft.com/whdc/devtools/debugging/ >> %logfile%
echo. >> %logfile%
echo Note: If you are using 32-bit Debugging Tools on 64-bit Windows, change x86dbg_path in this script. >> %logfile%
echo       If your Debugging Tools are in a custom directory, change the dbg_path variables in this script. >> %logfile%
echo       Debugging Tools for Intel Itanium (IA-64) Native has not yet been tested. >> %logfile%
goto drumroll

:confused
echo. >> %logfile%
echo ----- >> %logfile%
echo Analysis failed; The specified file (%minidump_file%) >> %logfile%
echo is not a valid Minidump file, or it could not be read. >> %logfile%
echo. >> %logfile%
echo Note: On Windows Vista or Windows 7, copy the Minidump file to e.g. the desktop and try again, >> %logfile%
echo       or run Minilyzer from an elevated command prompt. >> %logfile%
goto drumroll

:finished
echo. >> %logfile%
echo ----- >> %logfile%
echo Minilyzer 1.1 analysis of %minidump_file% complete! >> %logfile%
echo. >> %logfile%
findstr /b "DEFAULT_BUCKET_ID" %logfile% >> %logfile%
findstr /b "MODULE_NAME" %logfile% >> %logfile%
findstr /b "IMAGE_NAME" %logfile% >> %logfile%
goto drumroll

:drumroll
%drumroll_command%
goto end

:end
color
