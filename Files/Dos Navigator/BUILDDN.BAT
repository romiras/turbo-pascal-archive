@echo off
set tvar=

set multi=Y
set bppath=\bp\bin\
set outpath=out

rem ------------------------------------------------------------------
rem BUILDDN [help] [resource] [asm] [nobpc] [nolite] [ver]
rem ------------------------------------------------------------------
rem ctty con
if .%1.==.. builddn help resource nolite

:Loop
if .%1.==.asm. goto asm
if .%1.==.ver. goto cmpver
if .%1.==.resource. goto resource
if .%1.==.help. goto help
if .%1.==.nolite. set lite=off
if .%1.==.nolite. shift

:Done
if .%1.==.nobpc. goto SkipBPC
%bppath%bpc dn /dDN /GP /Q /B %1 %2 %3 %4 %5 %6 %7 %8 %9
if errorlevel 1 goto Quit

if .%lite%.==.off. goto SkipLite
pklite exe\dn.exe
if errorlevel 1 goto Quit
:SkipLite
copy exe\dn.ovr %outpath%
copy exe\dn.exe %outpath%\*.PRG

:SkipBPC
goto Quit

:resource
if not .%Q%.==.. %bppath%bpc rcp /q
if not .%Q%.==.. goto :r
if not exist exe\rcp.exe %bppath%bpc rcp /q
:r
if errorlevel 1 goto Quit
if not exist exe\rcp.exe goto Quit
shift
exe\rcp
if errorlevel 1 goto Quit

copy exe\dn*.lng %outpath%
copy exe\dn*.dlg %outpath%
set Q=
goto Loop

:help
shift
%bppath%bpc tvhc /q
if errorlevel 1 goto Quit
if not exist exe\tvhc.exe goto Quit

exe\tvhc resource\english\dnhelp.htx exe\dn.hlp dnhelp.pas
if errorlevel 1 goto Quit
copy exe\dn.hlp %outpath%

exe\tvhc resource\russian\dnhelp.htx exe\dnrus.hlp dnhelp.pas
if errorlevel 1 goto Quit
copy exe\dnrus.hlp %outpath%

set Q=Y
goto Loop

:asm
shift
%bppath%tasm /t /x /m /q *.asm
if errorlevel 1 goto Quit
%bppath%tlink /t /x dn.obj, exe\dn.com
if errorlevel 1 goto Quit
del dn.obj
copy exe\dn.com %outpath%
goto Loop

:cmpver
shift
%bppath%bpc version
exe\version
goto Loop

:Quit
