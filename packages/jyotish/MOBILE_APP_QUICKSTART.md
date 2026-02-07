# Quick Start Guide: From Library to Mobile App

This guide will get you from the Jyotish library to a published mobile app in the shortest time possible.

## 🚀 Option 1: Quick Mobile App (Using Example App)

The fastest way to get a mobile app running:

### Step 1: Test the Example App (2 minutes)

```bash
cd /Users/sanjibacharya/Developer/jyotish/example
flutter pub get
flutter run
```

Your app should now be running on your connected device or emulator!

### Step 2: Customize the App (10-30 minutes)

Edit `example/lib/main.dart` to customize:

- App name and title
- Colors and theme
- Features and screens
- Default location

### Step 3: Build for Production (5 minutes)

**For Android:**

```bash
flutter build apk --release
```

**For iOS:**

```bash
flutter build ios --release
open ios/Runner.xcworkspace  # Then archive in Xcode
```

Your APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

**Done!** You now have a working mobile app. 🎉

---

## 📦 Option 2: Create New App Using GitHub Library

Create a new app and use the library directly from GitHub:

### Step 1: Create New Flutter Project (5 minutes)

```bash
cd ~/Developer
flutter create my_jyotish_app
cd my_jyotish_app
```

### Step 2: Add Jyotish Library from GitHub (2 minutes)

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  jyotish:
    git:
      url: https://github.com/rajsanjib/jyotish-flutter-library.git
      ref: main # or use a specific tag like v1.0.0
```

### Step 3: Get Dependencies and Run (2 minutes)

```bash
flutter pub get
flutter run
```

**Done!** You now have a new app using the GitHub library. 🎉

---

## 🎯 Option 3: Complete Custom App (1-2 hours)

For a fully customized application:

### Step 1: Create New Flutter Project

```bash
cd ~/Developer
flutter create jyotish_pro
cd jyotish_pro
```

### Step 2: Add Jyotish Library

In `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  jyotish:
    git:
      url: https://github.com/rajsanjib/jyotish-flutter-library.git
      ref: main
    # OR for local development:
    # path: /Users/sanjibacharya/Developer/jyotish
```

### Step 3: Design Your App

Plan your app features:

- [ ] Birth chart calculator
- [ ] Daily horoscope
- [ ] Transit predictions
- [ ] Compatibility matching
- [ ] Muhurta (auspicious timing)
- [ ] Panchang (daily calendar)
- [ ] Premium features (subscription)

### Step 4: Implement Core Features

Create these files:

**lib/screens/birth_chart_screen.dart**:

```dart
import 'package:flutter/material.dart';
import 'package:jyotish/jyotish.dart';

class BirthChartScreen extends StatefulWidget {
  @override
  _BirthChartScreenState createState() => _BirthChartScreenState();
}

class _BirthChartScreenState extends State<BirthChartScreen> {
  final Jyotish _jyotish = Jyotish();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _jyotish.initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Your UI here
    return Scaffold(
      appBar: AppBar(title: Text('Birth Chart')),
      body: Container(),
    );
  }
}
```

**lib/models/user_profile.dart**:

```dart
class UserProfile {
  final String name;
  final DateTime birthDate;
  final GeographicLocation birthLocation;

  UserProfile({
    required this.name,
    required this.birthDate,
    required this.birthLocation,
  });
}
```

**lib/services/chart_service.dart**:

```dart
import 'package:jyotish/jyotish.dart';

class ChartService {
  final Jyotish _jyotish = Jyotish();

  Future<void> initialize() async {
    await _jyotish.initialize();
  }

  Future<VedicChart> calculateChart(
    DateTime dateTime,
    GeographicLocation location,
  ) async {
    return await _jyotish.calculateVedicChart(
      dateTime: dateTime,
      location: location,
    );
  }
}
```

### Step 5: Build and Test

```bash
flutter run
```

### Step 6: Add Native Libraries

Follow the instructions in [PUBLISHING_GUIDE.md](PUBLISHING_GUIDE.md) to bundle Swiss Ephemeris for Android and iOS.

### Step 7: Release

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## 🛠️ Using the Helper Scripts

Two helper scripts are provided to make your life easier:

### 1. Build App Script

```bash
cd /Users/sanjibacharya/Developer/jyotish
./build_app.sh
```

Interactive menu to:

- Build Android APK (Debug/Release)
- Build Android App Bundle
- Build iOS
- Run on device
- Run tests

### 2. Prepare Package Script

```bash
cd /Users/sanjibacharya/Developer/jyotish
./prepare_package.sh
```

Automatically:

- Formats code
- Runs analysis
- Runs tests
- Performs dry-run publish
- Checks documentation

---

## 📱 Platform-Specific Setup

### Android Setup (One-time)

1. **Install Android Studio** (if not already installed)
2. **Accept licenses**:
   ```bash
   flutter doctor --android-licenses
   ```
3. **Create signing key** (for release builds):
   ```bash
   keytool -genkey -v -keystore ~/jyotish-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias jyotish
   ```

### iOS Setup (One-time, macOS only)

1. **Install Xcode** from App Store
2. **Install CocoaPods**:
   ```bash
   sudo gem install cocoapods
   ```
3. **Set up development team** in Xcode
4. **Configure signing** in Xcode project settings

---

## 🎨 Customization Checklist

Before publishing your app:

- [ ] Change app name in `pubspec.yaml`
- [ ] Update app icon (use https://appicon.co)
- [ ] Create splash screen
- [ ] Update colors and theme
- [ ] Add your branding
- [ ] Write app description
- [ ] Take screenshots for store listings
- [ ] Create privacy policy
- [ ] Test on multiple devices
- [ ] Set up analytics (Firebase, etc.)
- [ ] Implement crash reporting
- [ ] Add in-app purchases (if monetizing)

---

## 📊 App Size Optimization

To keep your app size small:

```bash
# Build with split APKs (creates separate APKs per architecture)
flutter build apk --split-per-abi

# Results in smaller APKs:
# - app-armeabi-v7a-release.apk
# - app-arm64-v8a-release.apk
# - app-x86_64-release.apk
```

For App Bundle (recommended for Play Store):

```bash
flutter build appbundle --release
```

The Play Store will automatically serve the optimal APK to each device.

---

## 🐛 Common Issues & Solutions

### Issue: "Swiss Ephemeris library not found"

**Solution**: Make sure native library is bundled correctly

For Android:

```bash
mkdir -p android/app/src/main/jniLibs/arm64-v8a
cp path/to/libswisseph.so android/app/src/main/jniLibs/arm64-v8a/
```

For iOS:

```bash
mkdir -p ios/Frameworks
cp -r path/to/libswisseph.framework ios/Frameworks/
```

### Issue: "Calculation failed"

**Solution**: Ensure ephemeris data files are included

Add to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/ephe/
```

### Issue: Large app size

**Solution**:

- Use `--split-per-abi` for Android
- Bundle only essential ephemeris files
- Enable ProGuard/R8 minification

---

## 📈 Next Steps

After getting your app running:

1. **Test thoroughly** on real devices
2. **Gather feedback** from beta testers
3. **Iterate on UI/UX**
4. **Add advanced features**
5. **Set up CI/CD** (GitHub Actions, Codemagic)
6. **Publish to stores**
7. **Market your app**
8. **Monitor analytics and crashes**
9. **Release updates regularly**

---

## 🎯 Recommended Timeline

| Phase      | Time          | Tasks                                                    |
| ---------- | ------------- | -------------------------------------------------------- |
| **Week 1** | Setup         | Install tools, test example app, customize basic UI      |
| **Week 2** | Core Features | Implement main screens, chart calculations, data storage |
| **Week 3** | Polish        | UI refinement, error handling, loading states            |
| **Week 4** | Testing       | Beta testing, bug fixes, performance optimization        |
| **Week 5** | Release Prep  | Screenshots, descriptions, store listings                |
| **Week 6** | Launch        | Submit to stores, soft launch, marketing                 |

---

## 🆘 Need Help?

- **Library issues**: GitHub Issues
- **Flutter questions**: https://flutter.dev/docs
- **Vedic astrology questions**: Consult traditional texts or experts
- **App Store guidelines**:
  - [Google Play](https://play.google.com/console/about/guides/releasehelp/)
  - [App Store](https://developer.apple.com/app-store/review/guidelines/)

---

## 💡 Pro Tips

1. **Start simple**: Launch with basic features, add more later
2. **Use version control**: Commit often, use meaningful messages
3. **Test on real devices**: Emulators don't catch everything
4. **Get feedback early**: Beta test with real users
5. **Monitor performance**: Use Flutter DevTools
6. **Plan for monetization**: Ads, subscriptions, or one-time purchase
7. **Build community**: Social media, website, blog
8. **Stay updated**: Follow Flutter and Jyotish library updates

---

**Ready to build your app?** Start with Option 1 above and iterate from there! 🚀
