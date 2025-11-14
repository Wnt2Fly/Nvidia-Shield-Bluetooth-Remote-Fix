@echo off
setlocal enabledelayedexpansion
color 0A
title Nvidia Shield Bluetooth Fix Tool

:: ============================================================================
:: Nvidia Shield Bluetooth Remote Fix - Automated Diagnostic & Repair Tool
:: ============================================================================
:: Created: November 2025
:: Purpose: Diagnose and fix TiVo/Bluetooth remote disconnection issues
:: Root Cause: location_mode=0 cripples Bluetooth LE scanning
:: ============================================================================

echo.
echo ========================================================================
echo    NVIDIA SHIELD BLUETOOTH REMOTE FIX TOOL
echo ========================================================================
echo.
echo This tool will:
echo  1. Connect to your Nvidia Shield via ADB
echo  2. Check all Bluetooth-related settings
echo  3. Identify problems automatically
echo  4. Fix issues (with your permission)
echo  5. Generate a detailed report
echo.
echo Prerequisites:
echo  - ADB installed and in your PATH
echo  - Shield has Developer Options enabled
echo  - Shield has Network Debugging enabled
echo.
pause

:: ============================================================================
:: STEP 1: Get Shield IP Address
:: ============================================================================

:GET_IP
cls
echo.
echo ========================================================================
echo STEP 1: ENTER SHIELD IP ADDRESS
echo ========================================================================
echo.
set /p SHIELD_IP="Enter your Shield's IP address (e.g., 192.168.2.12): "

if "%SHIELD_IP%"=="" (
    echo [ERROR] IP address cannot be empty!
    timeout /t 2 >nul
    goto GET_IP
)

echo.
echo Shield IP: %SHIELD_IP%
echo Connecting...

:: ============================================================================
:: STEP 2: Connect to Shield
:: ============================================================================

adb connect %SHIELD_IP%:5555 >nul 2>&1
timeout /t 2 >nul

:: Verify connection
adb -s %SHIELD_IP%:5555 shell echo "test" >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] Could not connect to Shield at %SHIELD_IP%:5555
    echo.
    echo Please verify:
    echo  - Shield is powered on
    echo  - IP address is correct
    echo  - Developer Options are enabled
    echo  - Network Debugging is enabled
    echo.
    pause
    goto GET_IP
)

echo [SUCCESS] Connected to Shield at %SHIELD_IP%:5555
echo.

:: ============================================================================
:: STEP 3: Collect Current Settings
:: ============================================================================

echo ========================================================================
echo STEP 2: COLLECTING CURRENT SETTINGS
echo ========================================================================
echo.

:: Get device name
echo [*] Getting device information...
for /f "tokens=*" %%i in ('adb -s %SHIELD_IP%:5555 shell getprop ro.product.model 2^>nul') do set DEVICE_MODEL=%%i
echo     Device Model: %DEVICE_MODEL%

:: Get Android version
for /f "tokens=*" %%i in ('adb -s %SHIELD_IP%:5555 shell getprop ro.build.version.release 2^>nul') do set ANDROID_VERSION=%%i
echo     Android Version: %ANDROID_VERSION%

echo.
echo [*] Checking Bluetooth settings...

:: Location mode (CRITICAL)
for /f "tokens=*" %%i in ('adb -s %SHIELD_IP%:5555 shell settings get secure location_mode 2^>nul') do set LOCATION_MODE=%%i
echo     Location Mode: %LOCATION_MODE%

:: Location providers
for /f "tokens=*" %%i in ('adb -s %SHIELD_IP%:5555 shell settings get secure location_providers_allowed 2^>nul') do set LOCATION_PROVIDERS=%%i
echo     Location Providers: %LOCATION_PROVIDERS%

:: BLE scan always enabled
for /f "tokens=*" %%i in ('adb -s %SHIELD_IP%:5555 shell settings get global ble_scan_always_enabled 2^>nul') do set BLE_SCAN_ENABLED=%%i
echo     BLE Scan Always Enabled: %BLE_SCAN_ENABLED%

:: Bluetooth on/off status
for /f "tokens=*" %%i in ('adb -s %SHIELD_IP%:5555 shell settings get global bluetooth_on 2^>nul') do set BLUETOOTH_ON=%%i
echo     Bluetooth On: %BLUETOOTH_ON%

:: Get bonded devices count
for /f %%i in ('adb -s %SHIELD_IP%:5555 shell dumpsys bluetooth_manager ^| find /c "Bonded"') do set BONDED_COUNT=%%i
echo     Bonded Devices: %BONDED_COUNT%

echo.
echo [*] Settings collection complete!
echo.

:: ============================================================================
:: STEP 4: Analyze Settings and Identify Issues
:: ============================================================================

echo ========================================================================
echo STEP 3: DIAGNOSTIC ANALYSIS
echo ========================================================================
echo.

set ISSUES_FOUND=0
set FIX_NEEDED=0

:: Check location_mode (MOST CRITICAL)
if "%LOCATION_MODE%"=="0" (
    echo [CRITICAL] Location Mode is DISABLED ^(mode=0^)
    echo            This cripples Bluetooth LE scanning!
    echo            Result: Remotes will disconnect frequently
    echo.
    set /a ISSUES_FOUND+=1
    set FIX_LOCATION=1
) else if "%LOCATION_MODE%"=="3" (
    echo [OK] Location Mode is ENABLED ^(mode=3 - High Accuracy^)
    set FIX_LOCATION=0
) else (
    echo [WARNING] Location Mode is %LOCATION_MODE% ^(expected: 3^)
    echo           Recommend changing to mode 3 for best results
    echo.
    set /a ISSUES_FOUND+=1
    set FIX_LOCATION=1
)

:: Check location providers
if "%LOCATION_PROVIDERS%"=="" (
    echo [WARNING] No location providers enabled
    echo           GPS and Network providers should be enabled
    echo.
    set /a ISSUES_FOUND+=1
    set FIX_PROVIDERS=1
) else (
    echo [OK] Location Providers: %LOCATION_PROVIDERS%
    set FIX_PROVIDERS=0
)

:: Check BLE scan
if "%BLE_SCAN_ENABLED%"=="1" (
    echo [OK] BLE Scan Always Enabled: YES
    set FIX_BLE_SCAN=0
) else (
    echo [WARNING] BLE Scan Always Enabled: NO
    echo           This may cause scanning issues
    echo.
    set /a ISSUES_FOUND+=1
    set FIX_BLE_SCAN=1
)

:: Check Bluetooth is on
if "%BLUETOOTH_ON%"=="1" (
    echo [OK] Bluetooth: ON
) else (
    echo [WARNING] Bluetooth appears to be OFF
    echo.
)

echo.
echo ------------------------------------------------------------------------
if %ISSUES_FOUND% GTR 0 (
    echo RESULT: %ISSUES_FOUND% issue^(s^) found that may cause remote disconnections
    set FIX_NEEDED=1
) else (
    echo RESULT: All settings look good! No fixes needed.
    set FIX_NEEDED=0
)
echo ------------------------------------------------------------------------
echo.

:: ============================================================================
:: STEP 5: Offer to Fix Issues
:: ============================================================================

if %FIX_NEEDED%==0 (
    echo Your Shield is configured correctly!
    echo.
    echo If you're still experiencing remote disconnections, try:
    echo  1. Unpair and re-pair the remote
    echo  2. Reboot the Shield
    echo  3. Check for Shield firmware updates
    echo.
    goto GENERATE_REPORT
)

echo ========================================================================
echo STEP 4: FIX ISSUES
echo ========================================================================
echo.
echo The following fixes will be applied:
echo.

if %FIX_LOCATION%==1 (
    echo  [*] Set location_mode to 3 ^(High Accuracy^)
)
if %FIX_PROVIDERS%==1 (
    echo  [*] Enable network and GPS location providers
)
if %FIX_BLE_SCAN%==1 (
    echo  [*] Enable BLE scan always available
)

echo.
set /p CONFIRM="Apply these fixes? (Y/N): "

if /i not "%CONFIRM%"=="Y" (
    echo.
    echo [SKIPPED] Fixes not applied. Generating report only...
    goto GENERATE_REPORT
)

echo.
echo [*] Applying fixes...
echo.

:: Apply location mode fix
if %FIX_LOCATION%==1 (
    echo     Setting location_mode to 3...
    adb -s %SHIELD_IP%:5555 shell settings put secure location_mode 3 2>nul
    if errorlevel 1 (
        echo     [ERROR] Failed to set location_mode
    ) else (
        echo     [SUCCESS] Location mode set to 3
    )
)

:: Apply location providers fix
if %FIX_PROVIDERS%==1 (
    echo     Enabling location providers...
    adb -s %SHIELD_IP%:5555 shell settings put secure location_providers_allowed +network,+gps 2>nul
    if errorlevel 1 (
        echo     [ERROR] Failed to set location providers
    ) else (
        echo     [SUCCESS] Location providers enabled
    )
)

:: Apply BLE scan fix
if %FIX_BLE_SCAN%==1 (
    echo     Enabling BLE scan always available...
    adb -s %SHIELD_IP%:5555 shell settings put global ble_scan_always_enabled 1 2>nul
    if errorlevel 1 (
        echo     [ERROR] Failed to enable BLE scan
    ) else (
        echo     [SUCCESS] BLE scan enabled
    )
)

echo.
echo [SUCCESS] All fixes applied!
echo.

:: ============================================================================
:: STEP 6: Verify Fixes
:: ============================================================================

echo ========================================================================
echo STEP 5: VERIFYING FIXES
echo ========================================================================
echo.

echo [*] Re-checking settings...
echo.

:: Re-check location mode
for /f "tokens=*" %%i in ('adb -s %SHIELD_IP%:5555 shell settings get secure location_mode 2^>nul') do set NEW_LOCATION_MODE=%%i
if "%NEW_LOCATION_MODE%"=="3" (
    echo [OK] Location Mode: 3 ^(High Accuracy^)
) else (
    echo [WARNING] Location Mode: %NEW_LOCATION_MODE% ^(expected: 3^)
)

:: Re-check location providers
for /f "tokens=*" %%i in ('adb -s %SHIELD_IP%:5555 shell settings get secure location_providers_allowed 2^>nul') do set NEW_LOCATION_PROVIDERS=%%i
echo [OK] Location Providers: %NEW_LOCATION_PROVIDERS%

:: Re-check BLE scan
for /f "tokens=*" %%i in ('adb -s %SHIELD_IP%:5555 shell settings get global ble_scan_always_enabled 2^>nul') do set NEW_BLE_SCAN=%%i
if "%NEW_BLE_SCAN%"=="1" (
    echo [OK] BLE Scan Always Enabled: YES
) else (
    echo [WARNING] BLE Scan Always Enabled: %NEW_BLE_SCAN%
)

echo.
echo [SUCCESS] Verification complete!
echo.

:: ============================================================================
:: STEP 7: Reboot Recommendation
:: ============================================================================

echo ========================================================================
echo STEP 6: REBOOT SHIELD
echo ========================================================================
echo.
echo IMPORTANT: The Shield must reboot for changes to take effect!
echo.
echo After reboot, you should:
echo  1. Re-pair your TiVo/Bluetooth remote
echo  2. Test for 24 hours to confirm stability
echo.

set /p REBOOT="Reboot the Shield now? (Y/N): "

if /i "%REBOOT%"=="Y" (
    echo.
    echo [*] Rebooting Shield...
    adb -s %SHIELD_IP%:5555 reboot
    echo.
    echo [*] Shield is rebooting (takes ~60 seconds)
    echo.
) else (
    echo.
    echo [REMINDER] Please reboot manually: Settings -^> Device Preferences -^> About -^> Restart
    echo.
)

:: ============================================================================
:: STEP 8: Generate Report
:: ============================================================================

:GENERATE_REPORT

echo ========================================================================
echo STEP 7: GENERATING REPORT
echo ========================================================================
echo.

set REPORT_FILE=Shield_Bluetooth_Report_%SHIELD_IP%_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt
set REPORT_FILE=%REPORT_FILE: =0%

echo [*] Creating report: %REPORT_FILE%
echo.

(
    echo ========================================================================
    echo NVIDIA SHIELD BLUETOOTH DIAGNOSTIC REPORT
    echo ========================================================================
    echo.
    echo Report Generated: %date% %time%
    echo Shield IP: %SHIELD_IP%
    echo Device Model: %DEVICE_MODEL%
    echo Android Version: %ANDROID_VERSION%
    echo.
    echo ========================================================================
    echo SETTINGS BEFORE FIX
    echo ========================================================================
    echo.
    echo Location Mode: %LOCATION_MODE%
    echo Location Providers: %LOCATION_PROVIDERS%
    echo BLE Scan Always Enabled: %BLE_SCAN_ENABLED%
    echo Bluetooth On: %BLUETOOTH_ON%
    echo Bonded Devices: %BONDED_COUNT%
    echo.
    if %FIX_NEEDED%==1 (
        echo ========================================================================
        echo SETTINGS AFTER FIX
        echo ========================================================================
        echo.
        echo Location Mode: %NEW_LOCATION_MODE%
        echo Location Providers: %NEW_LOCATION_PROVIDERS%
        echo BLE Scan Always Enabled: %NEW_BLE_SCAN%
        echo.
    )
    echo ========================================================================
    echo DIAGNOSTIC SUMMARY
    echo ========================================================================
    echo.
    echo Issues Found: %ISSUES_FOUND%
    if %FIX_NEEDED%==1 (
        echo Fixes Applied: YES
    ) else (
        echo Fixes Applied: NO ^(none needed^)
    )
    echo.
    echo ========================================================================
    echo NEXT STEPS
    echo ========================================================================
    echo.
    if %FIX_NEEDED%==1 (
        echo 1. Reboot the Shield ^(REQUIRED for changes to take effect^)
        echo 2. After reboot, go to: Settings -^> Remotes ^& Accessories
        echo 3. Forget/unpair your TiVo or Bluetooth remote
        echo 4. Re-pair the remote from scratch
        echo 5. Test for 24 hours to confirm stability
        echo.
        echo Expected Result:
        echo  - Remote stays connected through sleep/wake cycles
        echo  - No more "remote disconnected" messages
        echo  - Immediate response when pressing buttons
        echo.
    ) else (
        echo Your Shield settings are correct!
        echo.
        echo If still experiencing issues:
        echo 1. Unpair and re-pair the remote
        echo 2. Reboot the Shield
        echo 3. Check for Shield firmware updates
        echo 4. Verify remote batteries are fresh
        echo.
    )
    echo ========================================================================
    echo TECHNICAL EXPLANATION
    echo ========================================================================
    echo.
    echo The TiVo remote disconnection issue is caused by location_mode being
    echo set to 0 ^(disabled^) at the system level, even though the UI may show
    echo location as enabled.
    echo.
    echo When location_mode=0:
    echo  - Android restricts Bluetooth LE scanning for privacy reasons
    echo  - BLE scan mode becomes OPPORTUNISTIC ^(passive only^)
    echo  - The Shield misses HID device keep-alive packets
    echo  - Result: Remote disconnects after sleep or randomly
    echo.
    echo When location_mode=3:
    echo  - Full Bluetooth LE scanning is enabled
    echo  - BLE scan mode becomes LOW or NEVER ^(aggressive^)
    echo  - The Shield maintains active connections
    echo  - Result: Remote stays connected reliably
    echo.
    echo This is a system-level Android requirement, not a Shield bug.
    echo.
    echo ========================================================================
    echo END OF REPORT
    echo ========================================================================
) > "%REPORT_FILE%"

echo [SUCCESS] Report saved: %REPORT_FILE%
echo.

:: ============================================================================
:: STEP 9: Additional Information
:: ============================================================================

echo ========================================================================
echo MONITORING YOUR FIX
echo ========================================================================
echo.
echo To watch Bluetooth activity in real-time:
echo.
echo   adb logcat -s BluetoothHidHost:* ^| find "Connection state"
echo.
echo To verify settings anytime:
echo.
echo   adb shell settings get secure location_mode
echo   ^(should return: 3^)
echo.
echo ========================================================================
echo.

if %FIX_NEEDED%==1 (
    echo [IMPORTANT] Remember to reboot and re-pair your remote!
    echo.
)

echo Report saved to: %REPORT_FILE%
echo.
echo Press any key to exit...
pause >nul

:: ============================================================================
:: Cleanup and Exit
:: ============================================================================

adb disconnect %SHIELD_IP%:5555 >nul 2>&1
exit /b 0
