@echo off
:: Usage: build.cmd x.y.z mingw|msvc2010 x86|x64
:: Font: Consolas 12; Layout: 140x70.

set BOOST_VERSION=1_53_0
set WIN_SDK_VERSION=7.1
set ZIP7=%PROGRAMFILES%\7-zip\7z.exe

:: I like to copy %WIN_SDK%\Bin\SetEnv.cmd to %WIN_SDK%\Bin\SetEnvNc.cmd to
:: remove the two "COLOR 0x" calls and the CLS call - just for nicer output.
set WIN_SDK=%PROGRAMFILES%\Microsoft SDKs\Windows\v%WIN_SDK_VERSION%
set SET_ENV=%WIN_SDK%\Bin\SetEnvNc.cmd
if not exist "%SET_ENV%" set SET_ENV=%WIN_SDK%\Bin\SetEnv.cmd
goto main

:: usage: call:configureWinSDK x86|x64|ia64 debug|release [/vista^|/xp^|/2003^|/2008^|/win7]
:configureWinSDK
@echo ==== Configuring WinSDK %~1 %~2 %~3 ====
set TARGET_ARCH=/%1
set MODE=/%2
if "%3" == "" ( set TARGET_OS=/xp ) else set TARGET_OS=%3
call "%SET_ENV%" %MODE% %TARGET_ARCH% %TARGET_OS%
goto :EOF

:: usage: call:extractsource build_dir
:extractSource
set SOURCE_DIR=%~dp0source
set SOURCE_FILE=%SOURCE_DIR%\boost_%BOOST_VERSION%.zip
if exist "%SOURCE_DIR%\boost_%BOOST_VERSION%.7z" (
  set SOURCE_FILE=%SOURCE_DIR%\boost_%BOOST_VERSION%.7z
)
if not exist "%~1" (
  @echo ==== Extracting Boost Source ====
  @echo Extracting "%SOURCE_FILE%" to "%~1"
  "%ZIP7%" x -o"%~1" "%SOURCE_FILE%" > nul
  if errorlevel 1 (
    echo Failed to extract "%SOURCE_FILE%"
	pause
	rmdir "%~1"
	exit errorlevel
  )
)
goto :EOF

:: usage: call:bootstrap boost_dir
:bootstrap
@echo ==== Bootstrapping Boost %~1 ====
pushd "%~1"
call bootstrap.bat
popd
goto :EOF

:: usage: call:build x86|x64|ia64 debug|release
:build
call:configureWinSDK %~1 %~2
set BUILD_DIR=%~dp0build\boost_%BOOST_VERSION%-%~1
if not exist "%BUILD_DIR%" call:extractSource %BUILD_DIR%
set BOOST_DIR=%BUILD_DIR%\boost_%BOOST_VERSION%
if not exist "%BOOST_DIR%\b2.exe" call:bootstrap %BOOST_DIR%
:: @todo
goto :EOF

:main
if not exist "%~dp0build" md "%~dp0build"
call:build x86 release
call:build x64 release
pause