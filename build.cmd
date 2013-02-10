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

:configureBoost
@echo ==== Configuring Boost ====
set SOURCE_DIR=%~dp0source
set SOURCE_FILE=%SOURCE_DIR%\boost_%BOOST_VERSION%.zip
if exist "%SOURCE_DIR%\boost_%BOOST_VERSION%.7z" (
  set SOURCE_FILE=%SOURCE_DIR%\boost_%BOOST_VERSION%.7z
)
set BUILD_DIR=%~dp0build\boost_%BOOST_VERSION%-%1
if not exist "%BUILD_DIR%" (
  md "%BUILD_DIR%"
  @echo Extracting "%SOURCE_FILE%" to "%BUILD_DIR%"
  "%ZIP7%" x -o"%BUILD_DIR%" "%SOURCE_FILE%" > nul
  if errorlevel 1 (
    echo Failed to extract "%SOURCE_FILE%"
	pause
	rmdir "%BUILD_DIR%"
	exit errorlevel
  )
)
pushd "%BUILD_DIR%\boost_%BOOST_VERSION%"
call bootstrap.bat
popd
goto :EOF

:main
if not exist "%~dp0build" md "%~dp0build"
call:configureWinSDK x86 release
call:configureBoost x86
call:configureWinSDK x64 release
call:configureBoost x64
pause