# GitHub Library and Mobile App Development Guide

This guide covers how to:

1. Prepare the Jyotish library for GitHub distribution
2. Create a standalone mobile application using the library
3. Bundle native libraries for Android and iOS

## Part 1: Preparing the Library for GitHub Distribution

### Step 1: Prepare Your Package

1. **Update `pubspec.yaml`** with correct information:

   ```yaml
   name: jyotish
   description: Production-ready Flutter library for Vedic astrology calculations using Swiss Ephemeris
   version: 1.0.0
   homepage: https://github.com/yourusername/jyotish
   repository: https://github.com/yourusername/jyotish
   ```

2. **Verify package structure**:

   ```
   jyotish/
   ├── lib/
   │   ├── jyotish.dart          # Main export file
   │   └── src/                   # Implementation files
   ├── test/                      # Tests
   ├── example/                   # Example app
   ├── README.md                  # Documentation
   ├── CHANGELOG.md               # Version history
   ├── LICENSE                    # License file
   └── pubspec.yaml               # Package configuration
   ```

3. **Run package checks**:

   ```bash
   cd /Users/sanjibacharya/Developer/jyotish

   # Check for issues
   flutter pub publish --dry-run

   # Analyze code
   flutter analyze

   # Run tests
   flutter test

   # Format code
   dart format .
   ```

### Step 2: Bundle Native Libraries

**IMPORTANT**: For a published package, you need to include pre-compiled native libraries for all platforms.

#### Option A: Include Pre-compiled Libraries (Recommended)

Create platform-specific folders:

```
jyotish/
├── android/
│   └── src/main/jniLibs/
│       ├── arm64-v8a/libswisseph.so
│       ├── armeabi-v7a/libswisseph.so
│       ├── x86/libswisseph.so
│       └── x86_64/libswisseph.so
├── ios/
│   └── Frameworks/
│       └── libswisseph.framework/
├── macos/
│   └── Frameworks/
│       └── libswisseph.dylib
├── linux/
│   └── lib/
│       └── libswisseph.so
└── windows/
    └── lib/
        └── swisseph.dll
```

#### Option B: Build Script Approach

Create a build script that compiles Swiss Ephemeris for each platform during package installation.

### Step 3: Prepare for GitHub Distribution

1. **Tag your release**:

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Create a GitHub release**:

   - Go to https://github.com/rajsanjib/jyotish-flutter-library
   - Click "Releases" → "Create a new release"
   - Select your tag (v1.0.0)
   - Add release notes from CHANGELOG.md
   - Publish the release

3. **Test GitHub installation**:

   ```bash
   dart pub login
   ```

4. **Publish the package**:

   ```bash
   dart pub publish
   ```

5. **Confirm publication** by typing 'y' when prompted

---

## Part 2: Creating a Standalone Mobile Application

### Option 1: Use the Existing Example App

The `example/` folder already contains a working Flutter app. You can build on this:

1. **Navigate to example folder**:

   ```bash
   cd /Users/sanjibacharya/Developer/jyotish/example
   ```

2. **Update `pubspec.yaml`** to use local library:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     jyotish:
       path: ../ # Uses local package during development
   ```

3. **Build for Android**:

   ```bash
   flutter build apk --release
   # Output: build/app/outputs/flutter-apk/app-release.apk

   # Or build App Bundle for Play Store:
   flutter build appbundle --release
   # Output: build/app/outputs/bundle/release/app-release.aab
   ```

4. **Build for iOS**:
   ```bash
   flutter build ios --release
   # Then open in Xcode to sign and archive
   open ios/Runner.xcworkspace
   ```

### Option 2: Create a New Mobile App Project

If you want to create a completely separate app:

1. **Create a new Flutter app**:

   ```bash
   cd ~/Developer
   flutter create jyotish_app
   cd jyotish_app
   ```

2. **Add the Jyotish library** to `pubspec.yaml`:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     jyotish:
       path: ../jyotish # Local development
       # OR after publishing:
       # jyotish: ^1.0.0
   ```

3. **Copy and enhance the example app**:
   ```bash
   # Copy the example main.dart as a starting point
   cp ../jyotish/example/lib/main.dart lib/main.dart
   ```

---

## Part 3: Bundling Native Libraries in Mobile Apps

### For Android

1. **Create JNI library folders**:

   ```bash
   mkdir -p android/app/src/main/jniLibs/{arm64-v8a,armeabi-v7a,x86,x86_64}
   ```

2. **Copy compiled libraries** (you'll need to compile for each architecture):

   ```bash
   # Example structure
   android/app/src/main/jniLibs/
   ├── arm64-v8a/libswisseph.so    # 64-bit ARM (most modern devices)
   ├── armeabi-v7a/libswisseph.so  # 32-bit ARM
   ├── x86/libswisseph.so          # 32-bit Intel (emulators)
   └── x86_64/libswisseph.so       # 64-bit Intel (emulators)
   ```

3. **Update `android/app/build.gradle`**:

   ```gradle
   android {
       // ... other config

       sourceSets {
           main {
               jniLibs.srcDirs = ['src/main/jniLibs']
           }
       }
   }
   ```

### For iOS

1. **Create Frameworks folder**:

   ```bash
   mkdir -p ios/Frameworks
   ```

2. **Copy the compiled framework**:

   ```bash
   cp -r path/to/libswisseph.framework ios/Frameworks/
   ```

3. **Update `ios/Runner.xcodeproj`** in Xcode:
   - Open project in Xcode
   - Go to Target → General → Frameworks, Libraries, and Embedded Content
   - Add `libswisseph.framework`
   - Set to "Embed & Sign"

### Bundling Ephemeris Data Files

1. **Add data files to assets** in `pubspec.yaml`:

   ```yaml
   flutter:
     assets:
       - assets/ephe/
   ```

2. **Copy ephemeris files**:

   ```bash
   mkdir -p assets/ephe
   # Copy ephemeris files from Swiss Ephemeris
   cp native/swisseph/swisseph-master/ephe/*.se1 assets/ephe/
   ```

3. **Access in code**:

   ```dart
   import 'package:flutter/services.dart';
   import 'package:path_provider/path_provider.dart';

   Future<String> getEphemerisPath() async {
     final appDir = await getApplicationDocumentsDirectory();
     final ephePath = '${appDir.path}/ephe';

     // Copy from assets on first run
     final dir = Directory(ephePath);
     if (!await dir.exists()) {
       await dir.create(recursive: true);
       // Copy files from assets
       final manifestContent = await rootBundle.loadString('AssetManifest.json');
       final Map<String, dynamic> manifestMap = json.decode(manifestContent);
       final ephemerisAssets = manifestMap.keys
           .where((String key) => key.contains('assets/ephe/'))
           .toList();

       for (final asset in ephemerisAssets) {
         final data = await rootBundle.load(asset);
         final fileName = asset.split('/').last;
         final file = File('$ephePath/$fileName');
         await file.writeAsBytes(data.buffer.asUint8List());
       }
     }

     return ephePath;
   }
   ```

---

## Part 4: Compiling Swiss Ephemeris for Mobile Platforms

### For Android (Cross-compilation)

You'll need Android NDK. Here's a basic approach:

```bash
# Install Android NDK
# Download from: https://developer.android.com/ndk/downloads

# Set NDK path
export NDK_ROOT=/path/to/android-ndk

# Compile for ARM64
$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android21-clang \
  -shared -o libswisseph.so \
  swephexp.c swehouse.c swejpl.c swemmoon.c swemplan.c \
  swepcalc.c swepdate.c sweph.c swephlib.c

# Repeat for other architectures (armeabi-v7a, x86, x86_64)
```

### For iOS (Universal Framework)

```bash
# Compile for iOS devices (ARM64)
clang -arch arm64 \
  -isysroot $(xcrun --sdk iphoneos --show-sdk-path) \
  -mios-version-min=12.0 \
  -dynamiclib \
  -o libswisseph_arm64.dylib \
  swephexp.c swehouse.c swejpl.c swemmoon.c swemplan.c \
  swepcalc.c swepdate.c sweph.c swephlib.c

# Compile for iOS Simulator (x86_64 and arm64)
clang -arch x86_64 -arch arm64 \
  -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) \
  -mios-version-min=12.0 \
  -dynamiclib \
  -o libswisseph_sim.dylib \
  swephexp.c swehouse.c swejpl.c swemmoon.c swemplan.c \
  swepcalc.c swepdate.c sweph.c swephlib.c

# Create XCFramework
xcodebuild -create-xcframework \
  -library libswisseph_arm64.dylib \
  -library libswisseph_sim.dylib \
  -output libswisseph.xcframework
```

---

## Part 5: App Store Distribution

### Android - Google Play Store

1. **Update `android/app/build.gradle`**:

   ```gradle
   android {
       defaultConfig {
           applicationId "com.yourcompany.jyotish_app"
           minSdkVersion 21
           targetSdkVersion 34
           versionCode 1
           versionName "1.0.0"
       }

       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }

       buildTypes {
           release {
               signingConfig signingConfigs.release
               minifyEnabled true
               shrinkResources true
           }
       }
   }
   ```

2. **Generate signing key**:

   ```bash
   keytool -genkey -v -keystore ~/jyotish-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias jyotish
   ```

3. **Create `android/key.properties`**:

   ```properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=jyotish
   storeFile=/Users/sanjibacharya/jyotish-release-key.jks
   ```

4. **Build release**:

   ```bash
   flutter build appbundle --release
   ```

5. **Upload to Play Console** at https://play.google.com/console

### iOS - App Store

1. **Open in Xcode**:

   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configure signing**:

   - Select Runner target
   - Go to Signing & Capabilities
   - Select your team
   - Set bundle identifier (e.g., `com.yourcompany.jyotish`)

3. **Archive and upload**:
   - Product → Archive
   - Distribute App → App Store Connect
   - Upload

---

## Quick Start Commands

### For Library Development:

```bash
# Test the library
flutter test

# Publish to pub.dev
dart pub publish --dry-run
dart pub publish
```

### For App Development:

```bash
# Run on device/emulator
flutter run

# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release

# Build for iOS
flutter build ios --release

# Install on connected device
flutter install
```

---

## Next Steps

1. ✅ **Test thoroughly** on real devices (Android & iOS)
2. ✅ **Add app icons and splash screens**
3. ✅ **Write comprehensive documentation**
4. ✅ **Create screenshots for store listings**
5. ✅ **Set up CI/CD** for automated builds
6. ✅ **Consider monetization** (ads, in-app purchases, premium features)

---

## Troubleshooting

### Native Library Not Found

**Issue**: App crashes with "library not found" error

**Solution**:

- Verify library files are in correct folders
- Check library loading code in `swisseph_bindings.dart`
- Use `DynamicLibrary.process()` for iOS
- For Android, ensure libraries are in `jniLibs` folder

### Ephemeris Data Files Missing

**Issue**: Calculations fail or return errors

**Solution**:

- Bundle ephemeris files in assets
- Copy to app documents directory on first launch
- Initialize library with correct path

### Large APK/IPA Size

**Issue**: App size is too large

**Solution**:

- Use `flutter build apk --split-per-abi` for Android
- Bundle only required ephemeris files (not all)
- Enable ProGuard/R8 minification
- Use App Bundle format for Play Store

---

## Resources

- **Flutter Documentation**: https://docs.flutter.dev
- **pub.dev Publishing**: https://dart.dev/tools/pub/publishing
- **Swiss Ephemeris**: https://www.astro.com/swisseph/
- **Android NDK**: https://developer.android.com/ndk
- **Xcode**: https://developer.apple.com/xcode

---

**Need Help?** Open an issue at: https://github.com/yourusername/jyotish/issues
