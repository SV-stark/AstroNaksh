#!/bin/bash

# Build script for Jyotish mobile application
# This script helps you build Android and iOS versions of your app

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$PROJECT_DIR/example"

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Jyotish Mobile App - Build Script${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"

# Function to display menu
show_menu() {
    echo -e "${GREEN}What would you like to build?${NC}\n"
    echo "1) Android APK (Debug)"
    echo "2) Android APK (Release)"
    echo "3) Android App Bundle (Release - for Play Store)"
    echo "4) iOS (Release - requires macOS & Xcode)"
    echo "5) Run on connected device/emulator"
    echo "6) Run tests"
    echo "7) Check for issues (analyze & test)"
    echo "8) Exit"
    echo ""
}

# Function to run tests
run_tests() {
    echo -e "\n${YELLOW}Running tests...${NC}"
    cd "$PROJECT_DIR"
    flutter test
    echo -e "${GREEN}✅ Tests completed${NC}"
}

# Function to analyze code
analyze_code() {
    echo -e "\n${YELLOW}Analyzing code...${NC}"
    cd "$PROJECT_DIR"
    flutter analyze
    echo -e "${GREEN}✅ Analysis completed${NC}"
}

# Function to build Android APK (Debug)
build_android_debug() {
    echo -e "\n${YELLOW}Building Android APK (Debug)...${NC}"
    cd "$EXAMPLE_DIR"
    flutter build apk --debug
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Android APK (Debug) built successfully!${NC}"
        echo -e "Location: ${BLUE}$EXAMPLE_DIR/build/app/outputs/flutter-apk/app-debug.apk${NC}"
    else
        echo -e "${RED}❌ Build failed${NC}"
        exit 1
    fi
}

# Function to build Android APK (Release)
build_android_release() {
    echo -e "\n${YELLOW}Building Android APK (Release)...${NC}"
    cd "$EXAMPLE_DIR"
    flutter build apk --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Android APK (Release) built successfully!${NC}"
        echo -e "Location: ${BLUE}$EXAMPLE_DIR/build/app/outputs/flutter-apk/app-release.apk${NC}"
        
        # Get APK size
        apk_size=$(du -h "$EXAMPLE_DIR/build/app/outputs/flutter-apk/app-release.apk" | cut -f1)
        echo -e "Size: ${YELLOW}$apk_size${NC}"
    else
        echo -e "${RED}❌ Build failed${NC}"
        exit 1
    fi
}

# Function to build Android App Bundle
build_android_bundle() {
    echo -e "\n${YELLOW}Building Android App Bundle (Release)...${NC}"
    cd "$EXAMPLE_DIR"
    flutter build appbundle --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Android App Bundle built successfully!${NC}"
        echo -e "Location: ${BLUE}$EXAMPLE_DIR/build/app/outputs/bundle/release/app-release.aab${NC}"
        echo -e "${YELLOW}This file can be uploaded to Google Play Console${NC}"
    else
        echo -e "${RED}❌ Build failed${NC}"
        exit 1
    fi
}

# Function to build iOS
build_ios() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}❌ iOS build requires macOS${NC}"
        exit 1
    fi
    
    echo -e "\n${YELLOW}Building iOS (Release)...${NC}"
    cd "$EXAMPLE_DIR"
    flutter build ios --release --no-codesign
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ iOS build completed!${NC}"
        echo -e "${YELLOW}To sign and archive:${NC}"
        echo -e "1. Open Xcode: ${BLUE}open $EXAMPLE_DIR/ios/Runner.xcworkspace${NC}"
        echo -e "2. Select your development team"
        echo -e "3. Product → Archive"
        echo -e "4. Distribute to App Store or TestFlight"
    else
        echo -e "${RED}❌ Build failed${NC}"
        exit 1
    fi
}

# Function to run on device
run_on_device() {
    echo -e "\n${YELLOW}Checking connected devices...${NC}"
    flutter devices
    
    echo -e "\n${YELLOW}Running app on connected device/emulator...${NC}"
    cd "$EXAMPLE_DIR"
    flutter run
}

# Function to check for issues
check_issues() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}   Running comprehensive checks...${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    
    analyze_code
    run_tests
    
    echo -e "\n${GREEN}✅ All checks completed!${NC}"
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice [1-8]: " choice
    
    case $choice in
        1)
            build_android_debug
            ;;
        2)
            build_android_release
            ;;
        3)
            build_android_bundle
            ;;
        4)
            build_ios
            ;;
        5)
            run_on_device
            ;;
        6)
            run_tests
            ;;
        7)
            check_issues
            ;;
        8)
            echo -e "\n${GREEN}Goodbye!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}\n"
            ;;
    esac
    
    echo -e "\n${BLUE}────────────────────────────────────────────────────────${NC}\n"
    read -p "Press Enter to continue..."
    clear
done
