@echo off
:: Dependencies:
::  * Microsoft Visual Studio / C++
::  * Microsoft WinSDK
::  * Microsoft HPC Pack 2008 R2 MS-MPI Redistributed Package (optional)
::  * (Optional) bzip2 library http://www.bzip.org/
::  * (Optional) zlib library http://www.zlib.net/

:: The following are all required; adjust to match your setup.
set BOOST_TOOLSET=msvc-10.0
set BOOST_VERSION=1_53_0
set WIN_SDK_VERSION=7.1
set ZIP7=%PROGRAMFILES%\7-zip\7z.exe

:: The following are all optional; comment out if not needed.
set BZIP_VERSION=1.0.6
set ZLIB_FILE_VERSION=127
set ZLIB_VERSION=1.2.7

:: I like to copy %WIN_SDK%\Bin\SetEnv.cmd to %WIN_SDK%\Bin\SetEnvNc.cmd to
:: remove the two "COLOR 0x" calls and the CLS call - just for nicer output.
set WIN_SDK=%PROGRAMFILES%\Microsoft SDKs\Windows\v%WIN_SDK_VERSION%
set SET_ENV=%WIN_SDK%\Bin\SetEnvNc.cmd
if not exist "%SET_ENV%" set SET_ENV=%WIN_SDK%\Bin\SetEnv.cmd
goto main

:: usage: call:extract input-file output-dir
:extract
@echo Extracting "%~1" to "%~2"
"%ZIP7%" x -o"%~2" "%~1" > nul
if errorlevel 1 (
  echo Failed to extract "%~1"
  pause
  exit errorlevel
)
goto :EOF

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
if not exist "%~1" call:extract %SOURCE_FILE% %~1
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
if "%BZIP_VERSION%" NEQ "" set sBZIP2=-sBZIP2_SOURCE="%~dp0source\bzip2-%BZIP_VERSION%"
if "%ZLIB_FILE_VERSION%" NEQ "" set sZLIB=-sZLIB_SOURCE="%~dp0source\zlib-%ZLIB_VERSION%"
pushd "%~1"
b2.exe --build-type=complete -d0 -j %NUMBER_OF_PROCESSORS% --prefix="%~2" -q %sBZIP2% %sZLIB% architecture=%BOOST_ARCH% address-model=%BOOST_ADDR% toolset=%BOOST_TOOLSET% variant=%~4 install
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
if not exist "%INSTALL_DIR%" call:buildBoost %BOOST_DIR% %INSTALL_DIR% %~1 %~2
goto :EOF

:main
if "%BZIP_VERSION%" NEQ "" (
  if not exist "%~dp0source\bzip2-%BZIP_VERSION%.tar" call:extract %~dp0source\bzip2-%BZIP_VERSION%.tar.gz %~dp0source
  if not exist "%~dp0source\bzip2-%BZIP_VERSION%" call:extract %~dp0source\bzip2-%BZIP_VERSION%.tar %~dp0source
)
if "%ZLIB_FILE_VERSION%" NEQ "" (
  if not exist "%~dp0source\zlib-%ZLIB_VERSION%" call:extract %~dp0source\zlib%ZLIB_FILE_VERSION%.zip %~dp0source
)
if not exist "%~dp0build" md "%~dp0build"
call:build x64 release
call:build x86 release
pause