# Include necessary headers.
!include "MUI2.nsh"   ; NSIS Modern User Interface.
!include "WinVer.nsh" ; LogicLib extensions for handling Windows versions and service packs.

# Map Boost / installer version to Microsft VersionInfo version parts.
!define VERSION_MAJOR    "1"  ; Boost major version.
!define VERSION_MINOR    "53" ; Boost minor version.
!define VERSION_BUILD    "0"  ; Boost maintencance version.
!define VERSION_REVISION "0"  ; Installer release version.

!define BOOST_BUILD_DIR32 "..\build\boost_${VERSION_MAJOR}_${VERSION_MINOR}_${VERSION_BUILD}-x86-${VARIANT}\install"
!define BOOST_BUILD_DIR64 "..\build\boost_${VERSION_MAJOR}_${VERSION_MINOR}_${VERSION_BUILD}-x64-${VARIANT}\install"
!define OUTPUT_FILENAME   "Boost-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_BUILD}-${COMPILER}-${VARIANT}-${VERSION_REVISION}.exe"
!define REGISTRY_KEY      "Software\Boost\${VERSION_MAJOR}.${VERSION_MINOR}-${COMPILER}-${VARIANT}"
!define TEST_PREFIX       "" ; // Only headers / libs starting with this prefix will be packaged - just for dev speed.
!define UNINSTALLER       "Uninstall-${VERSION_MAJOR}.${VERSION_MINOR}-${COMPILER}-${VARIANT}-${VERSION_REVISION}.exe"

# Installer Attributes: General Attributes.
InstallDir "$PROGRAMFILES\Boost\${VERSION_MAJOR}.${VERSION_MINOR}" ; Default only; see .onInit below.
InstallDirRegKey HKLM "Software\Boost\${VERSION_MAJOR}.${VERSION_MINOR}-${COMPILER}-${VARIANT}" "installDir"
Name "Boost ${VERSION_MAJOR}.${VERSION_MINOR}"
OutFile "${OUTPUT_FILENAME}"
SetCompressor lzma
XPStyle on

# Modern UI2 Interface Configuration.
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "header.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "welcome.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "welcome.bmp"
!define MUI_ABORTWARNING
!define MUI_ICON "boost.ico"
;!define MUI_UNICON "..."
!define MUI_COMPONENTSPAGE_NODESC

# Modern UI2 Install Pages.
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\build\boost_${VERSION_MAJOR}_${VERSION_MINOR}_${VERSION_BUILD}-x64-${VARIANT}\boost_${VERSION_MAJOR}_${VERSION_MINOR}_${VERSION_BUILD}\LICENSE_1_0.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

# Modern UI2 Uninstall Pages.
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

# Modern UI2 Languages.
!insertmacro MUI_LANGUAGE "English"

# Install types (these are not shown to the user unless MUI_PAGE_COMPONENTS is enabled above).
# Note: these installation types are indexed with a 0-base by SetCurInstType, but a 1-base by SectionIn!
InstType "Complete"
InstType "Dynamic libraries"
InstType "Static libraries"
InstType "Runtime DLLs only"

# Callback functions.

Function .onInit
	# Check if this 32-bit installer is running under WOW64.
	Var /GLOBAL isWow64
	Call detectWow64

	# Set the initial installation directory (the user can still override if they wish).
	Push $0
	ReadRegStr $0 HKLM "${REGISTRY_KEY}" "installDir"
	${IfNot} $0 == ""
		StrCpy $INSTDIR $0
	${ElseIf} $isWow64 != 0
		StrCpy $INSTDIR "$PROGRAMFILES64\Boost\${VERSION_MAJOR}.${VERSION_MINOR}"
	;Else, leave $INSTDIR unchanged, ie default to the InstallDir value defined above.
	${EndIf}
	Pop $0

    SetCurInstType 1 ; Dynamic libraries.
FunctionEnd

Function un.onInit
	# Check if this 32-bit uninstaller is running under WOW64.
	Call un.detectWow64
	IntCmpU $isWow64 0 0 +2 +2
		ReadRegStr $INSTDIR HKLM "${REGISTRY_KEY}" "installDir" ; Re-apply the InstallDirRegKey value, since we've now switched to the 64-bit registry view.
FunctionEnd

# Functions to be used by install / uninstall sections.

Var /GLOBAL rc
!macro detectWow64 un
Function ${un}detectWow64 ; Will set $isWow64 to non-zero if under WOW64, zero otherwise.
	# Find out if this 32-bit uninstaller is running under WOW64, if so (and only if so) this *must* be 64-bit Windows.
	${If} ${AtLeastWinXP}
		System::Call "kernel32::GetCurrentProcess() i .s"        ; Requires Win2K+.
		System::Call "kernel32::IsWow64Process(i s, *i .s) i .s" ; Requires XP SP2 or later.
		Pop $rc
		Pop $isWow64
		${If} $rc == error # System::Call failed - perhaps IsWow64Process does not exist on this system?
		${OrIf} $rc == 0   # IsWow64Process failed, perhaps because the process handle was invalid?
			StrCpy $isWow64 0 # In either case, assume we are *not* running under WOW64.
		${EndIf}
	${Else}
		StrCpy $isWow64 0 # Pre-Windows XP does not support WOW64.
	${EndIf}

	# If this is, indeed, WOW64, then switch the 64-bit registry view.
	${If} $isWow64 != 0
		SetRegView 64 ; Use the 64-bit registry view.
	${EndIf}
FunctionEnd
!macroend
!insertmacro detectWow64 ""    ; A version for use by the installer.
!insertmacro detectWow64 "un." ; A version for use by the uninstaller.

# Sections to install.

Section "-Common" ; Hidden section.
	# Log our 32/64 detection (might help in debugging if we ever detect wrongly).
	${If} $isWow64 == 0
		DetailPrint "Detected 32-bit platform ($isWow64)."
	${Else}
		DetailPrint "Detected 64-bit platform ($isWow64)."
	${EndIf}
    
	# Write the necessary registry key values.
	WriteRegStr HKLM "${REGISTRY_KEY}" "installDir" $INSTDIR
	Push $0
	GetCurInstType $0
	WriteRegDWORD HKLM "${REGISTRY_KEY}" "installType" $0
	Pop $0
	
	# Write the uninstaller.
	SetOutPath $INSTDIR
	WriteUninstaller "${UNINSTALLER}"
SectionEnd

Section "Source Headers"
  SectionIn 1 ; Complete.
  SectionIn 2 ; Dynamic libraries.
  SectionIn 3 ; Static libraries
  SetOutPath $INSTDIR\include
  File /r "${BOOST_BUILD_DIR64}\include\boost-${VERSION_MAJOR}_${VERSION_MINOR}\boost\${TEST_PREFIX}*"
SectionEnd

SectionGroup "Mulit-threaded Dynamic Libraries"
Section "32-bit Dynamic Import Libraries"
  SectionIn 1 ; Complete.
  SectionIn 2 ; Dynamic libraries.
  SetOutPath $INSTDIR\lib32
  File "${BOOST_BUILD_DIR32}\lib\boost_${TEST_PREFIX}*-mt-*.lib"
SectionEnd
Section "32-bit Runtime DLLs"
  SectionIn 1 ; Complete.
  SectionIn 2 ; Dynamic libraries.
  SectionIn 4 ; Runtime DLLs.
  SetOutPath $INSTDIR\lib32
  File "${BOOST_BUILD_DIR32}\lib\boost_${TEST_PREFIX}*.dll"
SectionEnd
Section "64-bit Dynamic Import Libraries"
  SectionIn 1 ; Complete.
  SectionIn 2 ; Dynamic libraries.
  SetOutPath $INSTDIR\lib64
  File "${BOOST_BUILD_DIR64}\lib\boost_${TEST_PREFIX}*-mt-*.lib"
SectionEnd
Section "64-bit Runtime DLLs"
  SectionIn 1 ; Complete.
  SectionIn 2 ; Dynamic libraries.
  SectionIn 4 ; Runtime DLLs.
  SetOutPath $INSTDIR\lib64
  File "${BOOST_BUILD_DIR64}\lib\boost_${TEST_PREFIX}*.dll"
SectionEnd
SectionGroupEnd

SectionGroup "Mulit-threaded Static Libraries"
Section "32-bit Static Libraries"
  SectionIn 1 ; Complete.
  SectionIn 3 ; Static libraries.
  SetOutPath $INSTDIR\lib32
  File "${BOOST_BUILD_DIR32}\lib\libboost_${TEST_PREFIX}*-mt-*.lib"
SectionEnd
Section "64-bit Static Libraries"
  SectionIn 1 ; Complete.
  SectionIn 3 ; Static libraries.
  SetOutPath $INSTDIR\lib64
  File "${BOOST_BUILD_DIR64}\lib\libboost_${TEST_PREFIX}*-mt-*.lib"
SectionEnd
SectionGroupEnd

SectionGroup "Single Threaded Static Libraries"
Section "32-bit Single Threaded Static Libraries"
  SectionIn 1 ; Complete.
  SetOutPath $INSTDIR\lib32
  File /x *-mt-* "${BOOST_BUILD_DIR32}\lib\libboost_${TEST_PREFIX}*.lib"
SectionEnd
Section "64-bit Single Threaded Static Libraries"
  SectionIn 1 ; Complete.
  SetOutPath $INSTDIR\lib64
  File /x *-mt-* "${BOOST_BUILD_DIR64}\lib\libboost_${TEST_PREFIX}*.lib" 
SectionEnd
SectionGroupEnd

Section "-Control Panel info" ; Programs and Features (aka Add/Remove Programs) information.
    !define UNINSTALL_REGISTRY_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\Boost ${VERSION_MAJOR}.${VERSION_MINOR} ${COMPILER} ${VARIANT}"
    WriteRegStr HKLM "${UNINSTALL_REGISTRY_KEY}" "DisplayName" "Boost ${VERSION_MAJOR}.${VERSION_MINOR}"
    WriteRegStr HKLM "${UNINSTALL_REGISTRY_KEY}" "DisplayIcon" "$\"$INSTDIR\${UNINSTALLER}$\",0"
    WriteRegStr HKLM "${UNINSTALL_REGISTRY_KEY}" "DisplayVersion" "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_BUILD}-${COMPILER}-${VARIANT}-${VERSION_REVISION}"
    WriteRegStr HKLM "${UNINSTALL_REGISTRY_KEY}" "Publisher" "Paul Colby"
    WriteRegStr HKLM "${UNINSTALL_REGISTRY_KEY}" "URLInfoAbout" "http://colby.id.au/boost-for-windows"
    WriteRegStr HKLM "${UNINSTALL_REGISTRY_KEY}" "UninstallString" "$\"$INSTDIR\${UNINSTALLER}$\""
    WriteRegStr HKLM "${UNINSTALL_REGISTRY_KEY}" "QuietUninstallString" "$\"$INSTDIR\${UNINSTALLER}$\" /S"
    WriteRegDword HKLM "${UNINSTALL_REGISTRY_KEY}" "NoModify" 1
    WriteRegDword HKLM "${UNINSTALL_REGISTRY_KEY}" "NoRepair" 1
SectionEnd

# Sections to uninstall.

Section "un.Registry Settings"
  DeleteRegValue HKLM "${REGISTRY_KEY}" "installDir"
  DeleteRegValue HKLM "${REGISTRY_KEY}" "installType"
  DeleteRegKey /ifempty HKLM "${REGISTRY_KEY}"
  DeleteRegKey /ifempty HKLM "Software\Boost"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Boost ${VERSION_MAJOR}.${VERSION_MINOR} ${COMPILER} ${VARIANT}"
SectionEnd

Section "un.Application Files"
    # Delete the relevant library files.
	${if} ${VARIANT} == "debug"
	    Delete "$INSTDIR\lib32\*-${COMPILER}-*gd-${VERSION_MAJOR}_${VERSION_MINOR}.*"
	    Delete "$INSTDIR\lib64\*-${COMPILER}-*gd-${VERSION_MAJOR}_${VERSION_MINOR}.*"
    ${Else}
        Delete "$INSTDIR\lib32\*-${COMPILER}-mt-${VERSION_MAJOR}_${VERSION_MINOR}.*"
        Delete "$INSTDIR\lib64\*-${COMPILER}-mt-${VERSION_MAJOR}_${VERSION_MINOR}.*"
        Delete "$INSTDIR\lib32\*-${COMPILER}-*s-${VERSION_MAJOR}_${VERSION_MINOR}.*"
        Delete "$INSTDIR\lib64\*-${COMPILER}-*s-${VERSION_MAJOR}_${VERSION_MINOR}.*"
	${EndIf}

	# Delete the library directories, if empty (ie no other ${COMPILER} versions installed).
	RMDir "$INSTDIR\lib32"
	RMDir "$INSTDIR\lib64"
	
	# Removed the include directory, but only if we succeeded in removing the library directories above
	${IfNot} ${FileExists} "$INSTDIR\lib*"
	    RMDir /r "$INSTDIR\include"
    ${EndIf}
	
	# Remove the uninstaller.
	Delete "$INSTDIR\${UNINSTALLER}"
	
	# Remove installation directory, if empty.
	RMDir "$INSTDIR"
SectionEnd

# Installer Attributes: Version Information.
VIProductVersion "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_BUILD}.${VERSION_REVISION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "Boost C++ Libraries"
VIAddVersionKey /LANG=${LANG_ENGLISH} "Comments" "http://colby.id.au/boost-for-windows"
;VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" ""
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Copyright (c) 2013 Paul Colby."
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "Boost ${VERSION_MAJOR}.${VERSION_MINOR} Installer"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_BUILD}.${VERSION_REVISION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductVersion" "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_BUILD}.${VERSION_REVISION}"
;VIAddVersionKey /LANG=${LANG_ENGLISH} "InternalName" ""
;VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalTrademarks" ""
VIAddVersionKey /LANG=${LANG_ENGLISH} "OriginalFilename" "${OUTPUT_FILENAME}"
;VIAddVersionKey /LANG=${LANG_ENGLISH} "PrivateBuild" ""
;VIAddVersionKey /LANG=${LANG_ENGLISH} "SpecialBuild" ""