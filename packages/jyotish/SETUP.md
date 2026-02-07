# Jyotish Library - Setup Instructions

This document provides setup instructions for the Jyotish library.

## Prerequisites

1. **Flutter SDK**: Version 3.0.0 or higher
2. **Dart SDK**: Version 3.0.0 or higher
3. **Swiss Ephemeris Library**: The native Swiss Ephemeris shared library files

## Installing Swiss Ephemeris Native Libraries

The Jyotish library uses FFI (Foreign Function Interface) to call the Swiss Ephemeris C library. You need to install the appropriate shared library for your platform.

### Option 1: Build from Source

1. Download Swiss Ephemeris source from: https://www.astro.com/ftp/swisseph/
2. Extract and compile for your platform:

#### macOS/Linux:

```bash
cd src
gcc -shared -o libswisseph.so *.c -lm
# On macOS, use .dylib extension:
gcc -shared -o libswisseph.dylib *.c -lm
```

#### Windows:

```bash
gcc -shared -o swisseph.dll *.c
```

3. Place the compiled library in the appropriate location:
   - **macOS**: `/usr/local/lib/` or app bundle
   - **Linux**: `/usr/lib/` or `/usr/local/lib/`
   - **Windows**: System32 or app directory
   - **iOS**: Include in app bundle
   - **Android**: Place in `android/app/src/main/jniLibs/[arch]/`

### Option 2: Use Pre-compiled Binaries

Download pre-compiled libraries from the Swiss Ephemeris website or use package managers:

#### macOS (using Homebrew):

```bash
brew install swisseph
```

#### Linux (Ubuntu/Debian):

```bash
sudo apt-get install libswe-dev
```

## Setting Up Ephemeris Data Files

For accurate calculations, you need Swiss Ephemeris data files:

1. Download ephemeris files from: https://www.astro.com/ftp/swisseph/ephe/

   Recommended files:

   - `seas_18.se1` (main planets, 1800-2399 AD)
   - `semo_18.se1` (moon, 1800-2399 AD)
   - `sepl_18.se1` (outer planets, 1800-2399 AD)

2. For better accuracy over a longer time span, download additional files.

3. Place the files in your app:

   **Flutter App:**

   ```
   assets/
     ephe/
       seas_18.se1
       semo_18.se1
       sepl_18.se1
   ```

4. Update `pubspec.yaml`:

   ```yaml
   flutter:
     assets:
       - assets/ephe/
   ```

5. Initialize with the path:

   ```dart
   import 'package:flutter/services.dart' show rootBundle;
   import 'dart:io';
   import 'package:path_provider/path_provider.dart';

   Future<String> setupEphemerisFiles() async {
     final appDir = await getApplicationDocumentsDirectory();
     final ephePath = '${appDir.path}/ephe';

     // Create directory
     final dir = Directory(ephePath);
     if (!await dir.exists()) {
       await dir.create(recursive: true);
     }

     // Copy files from assets
     final files = ['seas_18.se1', 'semo_18.se1', 'sepl_18.se1'];
     for (final file in files) {
       final data = await rootBundle.load('assets/ephe/$file');
       final bytes = data.buffer.asUint8List();
       await File('$ephePath/$file').writeAsBytes(bytes);
     }

     return ephePath;
   }

   // Use in your app
   final ephePath = await setupEphemerisFiles();
   await jyotish.initialize(ephemerisPath: ephePath);
   ```

## Platform-Specific Setup

### Android

1. Create `android/app/src/main/jniLibs/` directory structure:

   ```
   jniLibs/
     arm64-v8a/
       libswisseph.so
     armeabi-v7a/
       libswisseph.so
     x86/
       libswisseph.so
     x86_64/
       libswisseph.so
   ```

2. Update `android/app/build.gradle`:
   ```gradle
   android {
       // ...
       sourceSets {
           main {
               jniLibs.srcDirs = ['src/main/jniLibs']
           }
       }
   }
   ```

### iOS

1. Add the compiled library to your iOS project
2. Ensure it's included in the app bundle
3. Update `ios/Runner/Info.plist` if needed

### macOS

1. Place `libswisseph.dylib` in your app's Resources folder
2. Or install system-wide in `/usr/local/lib/`

### Linux

1. Install system-wide:
   ```bash
   sudo cp libswisseph.so /usr/local/lib/
   sudo ldconfig
   ```

### Windows

1. Place `swisseph.dll` in your app's directory
2. Or add to System32 (not recommended)

## Verification

To verify your setup:

```dart
import 'package:jyotish/jyotish.dart';

void main() async {
  try {
    final jyotish = Jyotish();
    await jyotish.initialize();

    print('✅ Jyotish initialized successfully!');

    // Test calculation
    final position = await jyotish.getPlanetPosition(
      planet: Planet.sun,
      dateTime: DateTime.now(),
      location: GeographicLocation(latitude: 0, longitude: 0),
    );

    print('✅ Calculation successful: ${position.formattedPosition}');

    jyotish.dispose();
  } catch (e) {
    print('❌ Setup failed: $e');
  }
}
```

## Troubleshooting

### Library not found

- **Error**: `DynamicLibrary.open failed`
- **Solution**: Ensure the shared library is in the correct location and has proper permissions

### Calculation errors

- **Error**: Calculation returns null or errors
- **Solution**: Verify ephemeris data files are correctly placed and the path is set

### Permission errors

- **Solution**: Ensure the library file has execute permissions:
  ```bash
  chmod +x libswisseph.so  # or .dylib on macOS
  ```

## License Considerations

- Swiss Ephemeris is dual-licensed (GPL v2+ or commercial)
- For commercial applications, consider purchasing a Swiss Ephemeris Professional License
- See: https://www.astro.com/swisseph/ for details

## Additional Resources

- Swiss Ephemeris Documentation: https://www.astro.com/swisseph/swisseph.htm
- Swiss Ephemeris Programmer's Manual: https://www.astro.com/swisseph/swephprg.htm
- Jyotish API Documentation: [Link to your docs]

## Support

If you encounter issues:

1. Check the error message carefully
2. Verify all setup steps
3. Ensure proper file permissions
4. Create an issue on GitHub with details

---

Happy Calculating! 🌟
