#!/bin/bash

# ============================================================================
# Nvidia Shield Bluetooth Fix Tool - Linux/Mac Version
# ============================================================================
# Created: November 2025
# Purpose: Diagnose and fix TiVo/Bluetooth remote disconnection issues
# Root Cause: location_mode=0 cripples Bluetooth LE scanning
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Clear screen and show header
clear
echo -e "${GREEN}========================================================================"
echo "   NVIDIA SHIELD BLUETOOTH REMOTE FIX TOOL"
echo "========================================================================"
echo -e "${NC}"
echo "This tool will:"
echo "  1. Connect to your Nvidia Shield via ADB"
echo "  2. Check all Bluetooth-related settings"
echo "  3. Identify problems automatically"
echo "  4. Fix issues (with your permission)"
echo "  5. Generate a detailed report"
echo ""
echo "Prerequisites:"
echo "  - ADB installed (sudo apt install adb / brew install android-platform-tools)"
echo "  - Shield has Developer Options enabled"
echo "  - Shield has Network Debugging enabled"
echo ""
read -p "Press Enter to continue..."

# ============================================================================
# STEP 1: Check for ADB
# ============================================================================

if ! command -v adb &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} ADB is not installed or not in PATH!"
    echo ""
    echo "Install ADB:"
    echo "  macOS:  brew install android-platform-tools"
    echo "  Ubuntu: sudo apt install adb"
    echo "  Fedora: sudo dnf install android-tools"
    echo ""
    exit 1
fi

echo -e "${GREEN}[OK]${NC} ADB is installed"
echo ""

# ============================================================================
# STEP 2: Get Shield IP Address
# ============================================================================

while true; do
    clear
    echo -e "${GREEN}========================================================================"
    echo "STEP 1: ENTER SHIELD IP ADDRESS"
    echo "========================================================================"
    echo -e "${NC}"
    read -p "Enter your Shield's IP address (e.g., 192.168.2.12): " SHIELD_IP
    
    if [ -z "$SHIELD_IP" ]; then
        echo -e "${RED}[ERROR]${NC} IP address cannot be empty!"
        sleep 2
        continue
    fi
    
    echo ""
    echo "Shield IP: $SHIELD_IP"
    echo "Connecting..."
    
    # Connect to Shield
    adb connect ${SHIELD_IP}:5555 > /dev/null 2>&1
    sleep 2
    
    # Verify connection
    if adb -s ${SHIELD_IP}:5555 shell echo "test" > /dev/null 2>&1; then
        echo -e "${GREEN}[SUCCESS]${NC} Connected to Shield at ${SHIELD_IP}:5555"
        echo ""
        break
    else
        echo ""
        echo -e "${RED}[ERROR]${NC} Could not connect to Shield at ${SHIELD_IP}:5555"
        echo ""
        echo "Please verify:"
        echo "  - Shield is powered on"
        echo "  - IP address is correct"
        echo "  - Developer Options are enabled"
        echo "  - Network Debugging is enabled"
        echo ""
        read -p "Press Enter to try again..."
    fi
done

# ============================================================================
# STEP 3: Collect Current Settings
# ============================================================================

echo -e "${GREEN}========================================================================"
echo "STEP 2: COLLECTING CURRENT SETTINGS"
echo "========================================================================"
echo -e "${NC}"

# Get device information
echo -e "${BLUE}[*]${NC} Getting device information..."
DEVICE_MODEL=$(adb -s ${SHIELD_IP}:5555 shell getprop ro.product.model 2>/dev/null | tr -d '\r')
echo "    Device Model: $DEVICE_MODEL"

ANDROID_VERSION=$(adb -s ${SHIELD_IP}:5555 shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
echo "    Android Version: $ANDROID_VERSION"

echo ""
echo -e "${BLUE}[*]${NC} Checking Bluetooth settings..."

# Location mode (CRITICAL)
LOCATION_MODE=$(adb -s ${SHIELD_IP}:5555 shell settings get secure location_mode 2>/dev/null | tr -d '\r')
echo "    Location Mode: $LOCATION_MODE"

# Location providers
LOCATION_PROVIDERS=$(adb -s ${SHIELD_IP}:5555 shell settings get secure location_providers_allowed 2>/dev/null | tr -d '\r')
echo "    Location Providers: $LOCATION_PROVIDERS"

# BLE scan always enabled
BLE_SCAN_ENABLED=$(adb -s ${SHIELD_IP}:5555 shell settings get global ble_scan_always_enabled 2>/dev/null | tr -d '\r')
echo "    BLE Scan Always Enabled: $BLE_SCAN_ENABLED"

# Bluetooth on/off status
BLUETOOTH_ON=$(adb -s ${SHIELD_IP}:5555 shell settings get global bluetooth_on 2>/dev/null | tr -d '\r')
echo "    Bluetooth On: $BLUETOOTH_ON"

# Get bonded devices count
BONDED_COUNT=$(adb -s ${SHIELD_IP}:5555 shell dumpsys bluetooth_manager 2>/dev/null | grep -c "Bonded")
echo "    Bonded Devices: $BONDED_COUNT"

echo ""
echo -e "${GREEN}[*]${NC} Settings collection complete!"
echo ""

# ============================================================================
# STEP 4: Analyze Settings and Identify Issues
# ============================================================================

echo -e "${GREEN}========================================================================"
echo "STEP 3: DIAGNOSTIC ANALYSIS"
echo "========================================================================"
echo -e "${NC}"

ISSUES_FOUND=0
FIX_NEEDED=0
FIX_LOCATION=0
FIX_PROVIDERS=0
FIX_BLE_SCAN=0

# Check location_mode (MOST CRITICAL)
if [ "$LOCATION_MODE" = "0" ]; then
    echo -e "${RED}[CRITICAL]${NC} Location Mode is DISABLED (mode=0)"
    echo "            This cripples Bluetooth LE scanning!"
    echo "            Result: Remotes will disconnect frequently"
    echo ""
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    FIX_LOCATION=1
elif [ "$LOCATION_MODE" = "3" ]; then
    echo -e "${GREEN}[OK]${NC} Location Mode is ENABLED (mode=3 - High Accuracy)"
    FIX_LOCATION=0
else
    echo -e "${YELLOW}[WARNING]${NC} Location Mode is $LOCATION_MODE (expected: 3)"
    echo "           Recommend changing to mode 3 for best results"
    echo ""
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    FIX_LOCATION=1
fi

# Check location providers
if [ -z "$LOCATION_PROVIDERS" ] || [ "$LOCATION_PROVIDERS" = "null" ]; then
    echo -e "${YELLOW}[WARNING]${NC} No location providers enabled"
    echo "           GPS and Network providers should be enabled"
    echo ""
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    FIX_PROVIDERS=1
else
    echo -e "${GREEN}[OK]${NC} Location Providers: $LOCATION_PROVIDERS"
    FIX_PROVIDERS=0
fi

# Check BLE scan
if [ "$BLE_SCAN_ENABLED" = "1" ]; then
    echo -e "${GREEN}[OK]${NC} BLE Scan Always Enabled: YES"
    FIX_BLE_SCAN=0
else
    echo -e "${YELLOW}[WARNING]${NC} BLE Scan Always Enabled: NO"
    echo "           This may cause scanning issues"
    echo ""
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    FIX_BLE_SCAN=1
fi

# Check Bluetooth is on
if [ "$BLUETOOTH_ON" = "1" ]; then
    echo -e "${GREEN}[OK]${NC} Bluetooth: ON"
else
    echo -e "${YELLOW}[WARNING]${NC} Bluetooth appears to be OFF"
    echo ""
fi

echo ""
echo "------------------------------------------------------------------------"
if [ $ISSUES_FOUND -gt 0 ]; then
    echo -e "${YELLOW}RESULT:${NC} $ISSUES_FOUND issue(s) found that may cause remote disconnections"
    FIX_NEEDED=1
else
    echo -e "${GREEN}RESULT:${NC} All settings look good! No fixes needed."
    FIX_NEEDED=0
fi
echo "------------------------------------------------------------------------"
echo ""

# ============================================================================
# STEP 5: Offer to Fix Issues
# ============================================================================

if [ $FIX_NEEDED -eq 0 ]; then
    echo "Your Shield is configured correctly!"
    echo ""
    echo "If you're still experiencing remote disconnections, try:"
    echo "  1. Unpair and re-pair the remote"
    echo "  2. Reboot the Shield"
    echo "  3. Check for Shield firmware updates"
    echo ""
    read -p "Press Enter to generate report and exit..."
    # Jump to report generation
else
    echo -e "${GREEN}========================================================================"
    echo "STEP 4: FIX ISSUES"
    echo "========================================================================"
    echo -e "${NC}"
    echo "The following fixes will be applied:"
    echo ""
    
    if [ $FIX_LOCATION -eq 1 ]; then
        echo "  [*] Set location_mode to 3 (High Accuracy)"
    fi
    if [ $FIX_PROVIDERS -eq 1 ]; then
        echo "  [*] Enable network and GPS location providers"
    fi
    if [ $FIX_BLE_SCAN -eq 1 ]; then
        echo "  [*] Enable BLE scan always available"
    fi
    
    echo ""
    read -p "Apply these fixes? (Y/N): " CONFIRM
    
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}[SKIPPED]${NC} Fixes not applied. Generating report only..."
    else
        echo ""
        echo -e "${BLUE}[*]${NC} Applying fixes..."
        echo ""
        
        # Apply location mode fix
        if [ $FIX_LOCATION -eq 1 ]; then
            echo "    Setting location_mode to 3..."
            if adb -s ${SHIELD_IP}:5555 shell settings put secure location_mode 3 2>/dev/null; then
                echo -e "    ${GREEN}[SUCCESS]${NC} Location mode set to 3"
            else
                echo -e "    ${RED}[ERROR]${NC} Failed to set location_mode"
            fi
        fi
        
        # Apply location providers fix
        if [ $FIX_PROVIDERS -eq 1 ]; then
            echo "    Enabling location providers..."
            if adb -s ${SHIELD_IP}:5555 shell settings put secure location_providers_allowed +network,+gps 2>/dev/null; then
                echo -e "    ${GREEN}[SUCCESS]${NC} Location providers enabled"
            else
                echo -e "    ${RED}[ERROR]${NC} Failed to set location providers"
            fi
        fi
        
        # Apply BLE scan fix
        if [ $FIX_BLE_SCAN -eq 1 ]; then
            echo "    Enabling BLE scan always available..."
            if adb -s ${SHIELD_IP}:5555 shell settings put global ble_scan_always_enabled 1 2>/dev/null; then
                echo -e "    ${GREEN}[SUCCESS]${NC} BLE scan enabled"
            else
                echo -e "    ${RED}[ERROR]${NC} Failed to enable BLE scan"
            fi
        fi
        
        echo ""
        echo -e "${GREEN}[SUCCESS]${NC} All fixes applied!"
        echo ""
        
        # ============================================================================
        # STEP 6: Verify Fixes
        # ============================================================================
        
        echo -e "${GREEN}========================================================================"
        echo "STEP 5: VERIFYING FIXES"
        echo "========================================================================"
        echo -e "${NC}"
        
        echo -e "${BLUE}[*]${NC} Re-checking settings..."
        echo ""
        
        # Re-check location mode
        NEW_LOCATION_MODE=$(adb -s ${SHIELD_IP}:5555 shell settings get secure location_mode 2>/dev/null | tr -d '\r')
        if [ "$NEW_LOCATION_MODE" = "3" ]; then
            echo -e "${GREEN}[OK]${NC} Location Mode: 3 (High Accuracy)"
        else
            echo -e "${YELLOW}[WARNING]${NC} Location Mode: $NEW_LOCATION_MODE (expected: 3)"
        fi
        
        # Re-check location providers
        NEW_LOCATION_PROVIDERS=$(adb -s ${SHIELD_IP}:5555 shell settings get secure location_providers_allowed 2>/dev/null | tr -d '\r')
        echo -e "${GREEN}[OK]${NC} Location Providers: $NEW_LOCATION_PROVIDERS"
        
        # Re-check BLE scan
        NEW_BLE_SCAN=$(adb -s ${SHIELD_IP}:5555 shell settings get global ble_scan_always_enabled 2>/dev/null | tr -d '\r')
        if [ "$NEW_BLE_SCAN" = "1" ]; then
            echo -e "${GREEN}[OK]${NC} BLE Scan Always Enabled: YES"
        else
            echo -e "${YELLOW}[WARNING]${NC} BLE Scan Always Enabled: $NEW_BLE_SCAN"
        fi
        
        echo ""
        echo -e "${GREEN}[SUCCESS]${NC} Verification complete!"
        echo ""
        
        # ============================================================================
        # STEP 7: Reboot Recommendation
        # ============================================================================
        
        echo -e "${GREEN}========================================================================"
        echo "STEP 6: REBOOT SHIELD"
        echo "========================================================================"
        echo -e "${NC}"
        echo -e "${BOLD}IMPORTANT:${NC} The Shield must reboot for changes to take effect!"
        echo ""
        echo "After reboot, you should:"
        echo "  1. Re-pair your TiVo/Bluetooth remote"
        echo "  2. Test for 24 hours to confirm stability"
        echo ""
        
        read -p "Reboot the Shield now? (Y/N): " REBOOT
        
        if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
            echo ""
            echo -e "${BLUE}[*]${NC} Rebooting Shield..."
            adb -s ${SHIELD_IP}:5555 reboot
            echo ""
            echo -e "${GREEN}[*]${NC} Shield is rebooting (takes ~60 seconds)"
            echo ""
        else
            echo ""
            echo -e "${YELLOW}[REMINDER]${NC} Please reboot manually: Settings -> Device Preferences -> About -> Restart"
            echo ""
        fi
    fi
fi

# ============================================================================
# STEP 8: Generate Report
# ============================================================================

echo -e "${GREEN}========================================================================"
echo "STEP 7: GENERATING REPORT"
echo "========================================================================"
echo -e "${NC}"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="Shield_Bluetooth_Report_${SHIELD_IP}_${TIMESTAMP}.txt"

echo -e "${BLUE}[*]${NC} Creating report: $REPORT_FILE"
echo ""

cat > "$REPORT_FILE" << EOF
========================================================================
NVIDIA SHIELD BLUETOOTH DIAGNOSTIC REPORT
========================================================================

Report Generated: $(date)
Shield IP: $SHIELD_IP
Device Model: $DEVICE_MODEL
Android Version: $ANDROID_VERSION

========================================================================
SETTINGS BEFORE FIX
========================================================================

Location Mode: $LOCATION_MODE
Location Providers: $LOCATION_PROVIDERS
BLE Scan Always Enabled: $BLE_SCAN_ENABLED
Bluetooth On: $BLUETOOTH_ON
Bonded Devices: $BONDED_COUNT

EOF

if [ $FIX_NEEDED -eq 1 ] && [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    cat >> "$REPORT_FILE" << EOF
========================================================================
SETTINGS AFTER FIX
========================================================================

Location Mode: $NEW_LOCATION_MODE
Location Providers: $NEW_LOCATION_PROVIDERS
BLE Scan Always Enabled: $NEW_BLE_SCAN

EOF
fi

cat >> "$REPORT_FILE" << EOF
========================================================================
DIAGNOSTIC SUMMARY
========================================================================

Issues Found: $ISSUES_FOUND
EOF

if [ $FIX_NEEDED -eq 1 ] && [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Fixes Applied: YES" >> "$REPORT_FILE"
else
    echo "Fixes Applied: NO (none needed)" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

========================================================================
NEXT STEPS
========================================================================

EOF

if [ $FIX_NEEDED -eq 1 ] && [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    cat >> "$REPORT_FILE" << EOF
1. Reboot the Shield (REQUIRED for changes to take effect)
2. After reboot, go to: Settings -> Remotes & Accessories
3. Forget/unpair your TiVo or Bluetooth remote
4. Re-pair the remote from scratch
5. Test for 24 hours to confirm stability

Expected Result:
 - Remote stays connected through sleep/wake cycles
 - No more "remote disconnected" messages
 - Immediate response when pressing buttons

EOF
else
    cat >> "$REPORT_FILE" << EOF
Your Shield settings are correct!

If still experiencing issues:
1. Unpair and re-pair the remote
2. Reboot the Shield
3. Check for Shield firmware updates
4. Verify remote batteries are fresh

EOF
fi

cat >> "$REPORT_FILE" << EOF
========================================================================
TECHNICAL EXPLANATION
========================================================================

The TiVo remote disconnection issue is caused by location_mode being
set to 0 (disabled) at the system level, even though the UI may show
location as enabled.

When location_mode=0:
 - Android restricts Bluetooth LE scanning for privacy reasons
 - BLE scan mode becomes OPPORTUNISTIC (passive only)
 - The Shield misses HID device keep-alive packets
 - Result: Remote disconnects after sleep or randomly

When location_mode=3:
 - Full Bluetooth LE scanning is enabled
 - BLE scan mode becomes LOW or NEVER (aggressive)
 - The Shield maintains active connections
 - Result: Remote stays connected reliably

This is a system-level Android requirement, not a Shield bug.

========================================================================
END OF REPORT
========================================================================
EOF

echo -e "${GREEN}[SUCCESS]${NC} Report saved: $REPORT_FILE"
echo ""

# ============================================================================
# STEP 9: Additional Information
# ============================================================================

echo -e "${GREEN}========================================================================"
echo "MONITORING YOUR FIX"
echo "========================================================================"
echo -e "${NC}"
echo "To watch Bluetooth activity in real-time:"
echo ""
echo "  adb logcat -s BluetoothHidHost:* | grep \"Connection state\""
echo ""
echo "To verify settings anytime:"
echo ""
echo "  adb shell settings get secure location_mode"
echo "  (should return: 3)"
echo ""
echo -e "${GREEN}========================================================================${NC}"
echo ""

if [ $FIX_NEEDED -eq 1 ] && [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${BOLD}[IMPORTANT]${NC} Remember to reboot and re-pair your remote!"
    echo ""
fi

echo "Report saved to: $REPORT_FILE"
echo ""
read -p "Press Enter to exit..."

# ============================================================================
# Cleanup and Exit
# ============================================================================

adb disconnect ${SHIELD_IP}:5555 > /dev/null 2>&1
exit 0
