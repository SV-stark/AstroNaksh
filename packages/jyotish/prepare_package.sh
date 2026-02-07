#!/bin/bash

# Package Preparation Script for GitHub Distribution
# This script prepares your Jyotish library for GitHub release

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}   Jyotish Library - GitHub Release Preparation${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"

# Step 1: Format code
echo -e "${YELLOW}📝 Formatting code...${NC}"
dart format .
echo -e "${GREEN}✅ Code formatted${NC}\n"

# Step 2: Analyze code
echo -e "${YELLOW}🔍 Analyzing code...${NC}"
flutter analyze
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Analysis found issues. Please fix them before publishing.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ No analysis issues${NC}\n"

# Step 3: Run tests
echo -e "${YELLOW}🧪 Running tests...${NC}"
flutter test
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Tests failed. Please fix them before publishing.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ All tests passed${NC}\n"

# Step 4: Check dependencies
echo -e "${YELLOW}📦 Checking dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies resolved${NC}\n"

# Step 5: Check package structure
echo -e "${YELLOW}� Checking package structure...${NC}"
required_dirs=("lib" "test" "example")
for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo -e "${RED}❌ Missing directory: $dir${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ $dir/ exists${NC}"
    fi
done
echo ""

# Step 6: Check documentation
echo -e "${YELLOW}📚 Checking documentation files...${NC}"
required_files=("README.md" "CHANGELOG.md" "LICENSE" "pubspec.yaml")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Missing required file: $file${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ $file exists${NC}"
    fi
done
echo ""

# Step 7: Summary
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Package is ready for GitHub distribution!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}To distribute via GitHub:${NC}"
echo -e "1. Commit and push all changes: ${BLUE}git add . && git commit -m 'Release v1.0.0'${NC}"
echo -e "2. Tag the release: ${BLUE}git tag v1.0.0 && git push origin v1.0.0${NC}"
echo -e "3. Create a GitHub release with release notes\n"

echo -e "${YELLOW}⚠️  Important reminders:${NC}"
echo -e "• Update version in pubspec.yaml before tagging"
echo -e "• Update CHANGELOG.md with release notes"
echo -e "• Users can install with: jyotish: git: url: https://github.com/rajsanjib/jyotish-flutter-library.git"
echo -e "• Consider bundling native libraries for all platforms"
echo -e "• Test the example app before releasing\n"

read -p "Do you want to create a git tag now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}Creating git tag...${NC}"
    current_version=$(grep "version:" pubspec.yaml | sed 's/version: //')
    git tag "v$current_version"
    echo -e "${GREEN}✅ Created tag v$current_version${NC}"
    echo -e "${YELLOW}Don't forget to push: ${BLUE}git push origin v$current_version${NC}"
else
    echo -e "\n${GREEN}Skipping tag creation. Create manually when ready.${NC}"
fi
