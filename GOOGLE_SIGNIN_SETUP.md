# Google Sign-In Setup Guide for SkyMojo

## 🍎 iOS Configuration

### 1. Get Google Sign-In Credentials
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth client ID**
5. Select **iOS** as application type
6. Bundle ID: `com.example.skymojo` (or your custom bundle ID)
7. Download the `GoogleService-Info.plist` file

### 2. Add iOS Configuration
1. Add `GoogleService-Info.plist` to `ios/Runner/`
2. Open `ios/Runner/Info.plist`
3. Add this configuration:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 3. Update iOS Runner
Add to `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import GoogleSignIn

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  @available(iOS 9.0, *)
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return GoogleSignIn.sharedInstance.handle(url)
  }
}
```

## 🤖 Android Configuration

### 1. Get Google Sign-In Credentials
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Go to **APIs & Services** → **Credentials**
3. Click **Create Credentials** → **OAuth client ID**
4. Select **Android** as application type
5. Package name: `com.example.skymojo` (or your custom package name)
6. SHA-1: Get this with `keytool -list -v -keystore ~/.android/debug.keystore`
7. Download the configuration

### 2. Add Android Configuration
1. Add `google-services.json` to `android/app/`
2. Update `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'
```

3. Update `android/build.gradle`:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

## 🔧 Supabase Configuration

### 1. Enable Google Provider
1. Go to your Supabase project: https://ffgqgjhramaktrvyodyb.supabase.co
2. Go to **Authentication** → **Providers**
3. Enable **Google** provider
4. Add your Google OAuth Client ID and Secret
5. Add your redirect URL: `https://ffgqgjhramaktrvyodyb.supabase.co/auth/v1/callback`

### 2. Update Redirect URLs
In Supabase Authentication Settings, add:
- `io.supabase.flutterquickstart://login-callback`
- Your app's custom URL scheme

## 📱 Testing Google Sign-In

### Features Added:
- ✅ Google Sign-In button on login screen
- ✅ Seamless integration with Supabase auth
- ✅ OAuth token handling
- ✅ Error handling and user feedback
- ✅ Loading states

### Test Flow:
1. Launch app
2. Click "Sign in with Google"
3. Select Google account
4. Authenticate with Google
5. Auto-redirect to SkyMojo dashboard
6. User profile created in Supabase

## 🎯 Benefits
- **Faster Sign-Up**: No password required
- **Better UX**: Familiar Google authentication
- **Secure**: OAuth 2.0 security
- **Cross-Platform**: Works on iOS and Android
- **Profile Data**: Auto-import user info

## 🚀 Ready to Use
Once configured, users can:
- Sign in with Google account
- Access all SkyMojo features
- Have profiles created automatically
- Use saved locations and settings

Your SkyMojo app now supports both email/password and Google Sign-In authentication!
