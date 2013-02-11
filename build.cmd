@echo off
:: Dependancies:
::  * Microsoft Visual Studio / C++
::  * Microsoft WinSDK
::  * Microsoft HPC Pack 2008 R2 MS-MPI Redistributed Package (optional)
::    * Not the 2012 versions; they don't include the headers / libs.

set BOOST_TOOLSET=msvc-10.0
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
@echo Bootstrapping %~1
pushd "%~1"
call bootstrap.bat
popd
set MPI_JAM=%~1\tools\build\v2\tools\mpi.jam
set MPI_TMP=%MPI_JAM%.tmp
if exist "%PROGRAMFILES%\Microsoft HPC Pack 2008 R2" (
  powershell -Command "get-content %MPI_JAM% | ForEach-Object {$_ -replace \"Microsoft Compute Cluster Pack\",\"Microsoft HPC Pack 2008 R2\"} | set-content %MPI_TMP%" && move /y "%MPI_TMP%" "%MPI_JAM%"
  if not exist "%PROGRAMFILES%\Microsoft HPC Pack 2008 R2\Include" (
    if  exist "%PROGRAMFILES%\Microsoft HPC Pack 2008 R2\Inc" (
      powershell -Command "get-content %MPI_JAM% | ForEach-Object {$_ -replace '(cluster_pack_path.*Inc)lude', '$1'} | set-content %MPI_TMP%" && move /y "%MPI_TMP%" "%MPI_JAM%"
	)
  )
  echo( >> "%~1\tools\build\v2\user-config.jam" && echo using mpi ; >> "%~1\tools\build\v2\user-config.jam"
)
goto :EOF

:: usage: call:buildBoost boost_dir install_dir x86|x64|ia64 debug|release
:buildBoost
if /I "%~3" EQU "ia64" ( set BOOST_ARCH=ia64 ) else set BOOST_ARCH=x86
if /I "%~3" EQU "x86" ( set BOOST_ADDR=32 ) else set BOOST_ADDR=64
pushd "%~1"
b2.exe -d0 -j %NUMBER_OF_PROCESSORS% --prefix="%~2" architecture=%BOOST_ARCH% address-model=%BOOST_ADDR% link=shared,static runtime-link=shared threading=multi toolset=%BOOST_TOOLSET% variant=%~4 install
popd
goto :EOF

:: usage: call:build x86|x64|ia64 debug|release
:build
@echo ==== Building %~1 %~2 ====
call:configureWinSDK %~1 %~2
set BUILD_DIR=%~dp0build\boost_%BOOST_VERSION%-%~1
if not exist "%BUILD_DIR%" call:extractSource %BUILD_DIR%
set BOOST_DIR=%BUILD_DIR%\boost_%BOOST_VERSION%
if not exist "%BOOST_DIR%\b2.exe" call:bootstrap %BOOST_DIR%
set INSTALL_DIR=%BUILD_DIR%\install
call:buildBoost %BOOST_DIR% %INSTALL_DIR% %~1 %~2
goto :EOF

:main
if not exist "%~dp0build" md "%~dp0build"
call:build x86 release
call:build x64 release
pause