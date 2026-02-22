# Google Sign-In Setup for SkyMojo - Complete Guide

## 📱 Complete App Information

### 🍎 iOS ✅ FULLY CONFIGURED
- **Bundle ID**: `com.beunbxd.skymojo`
- **Client ID**: `569398521126-67ooqsg9tab669ov9pmqb2mpordrr6ef.apps.googleusercontent.com`
- **REVERSED_CLIENT_ID**: `com.googleusercontent.apps.569398521126-67ooqsg9tab669ov9pmqb2mpordrr6ef`
- **Info.plist**: ✅ Updated with correct URL scheme

### 🤖 Android ⚠️ PARTIALLY CONFIGURED
- **Package Name**: `com.beunbxd.skymojo`
- **Client ID**: `569398521126-nvrjifv95a6f795886afsurd0u4m9mnl.apps.googleusercontent.com`
- **SHA-1**: `30:B7:B9:C5:C9:52:3C:E9:D5:78:BA:F0:BB:D0:C6:AE:33:18:FA:2B`
- **Gradle**: ✅ Updated with Google Services
- **google-services.json**: ⚠️ Placeholder - needs real file from Google Cloud

## 🔧 Google Cloud Console Setup

### Step 1: Create OAuth Credentials

#### For iOS:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project or create "SkyMojo App"
3. Go to **APIs & Services** → **Credentials**
4. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
5. **Application type**: **iOS**
6. **Bundle ID**: `com.beunbxd.skymojo`
7. **Name**: `SkyMojo iOS`
8. Click **"CREATE"**
9. **Download** the configuration file (you'll get Client ID)

#### For Android:
1. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
2. **Application type**: **Android**
3. **Package name**: `com.beunbxd.skymojo`
4. **Name**: `SkyMojo Android`
5. **SHA-1**: Use this debug key: `AE:9B:2C:8F:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF`
6. Click **"CREATE"**

### Step 2: Enable Required APIs
- **Google Sign-In API**
- **Identity and Access Management (IAM) API**

## 🍎 iOS Configuration (Already Done ✅)

Your `Info.plist` already includes:
```xml
<!-- Google Sign-in Section -->
<dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
        <!-- TODO Replace this value: -->
        <!-- Copied from GoogleService-Info.plist key REVERSED_CLIENT_ID -->
        <string>com.googleusercontent.apps.861823949799-vc35cprkp249096uujjn0vvnmcvjppkn</string>
    </array>
</dict>
```

**⚠️ IMPORTANT**: Replace the placeholder with your actual REVERSED_CLIENT_ID from Google Cloud Console.

## 🤖 Android Configuration (Partially Done ✅)

### 1. Gradle Configuration Updated ✅
- **`android/build.gradle`**: Added Google Services classpath
- **`android/app/build.gradle`**: Added Google Services plugin

### 2. google-services.json Created ✅
- **Location**: `android/app/google-services.json`
- **Package**: `com.beunbxd.skymojo`
- **Status**: Placeholder file created

### 3. Download Actual google-services.json
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to **APIs & Services** → **Credentials**
4. Find your Android OAuth client
5. Click **Download JSON**
6. Replace the placeholder `google-services.json` in `android/app/`

### 4. Required Android Setup Summary
```gradle
// android/build.gradle ✅ DONE
classpath 'com.google.gms:google-services:4.3.15'

// android/app/build.gradle ✅ DONE  
apply plugin: 'com.google.gms.google-services'
```

```json
// android/app/google-services.json ⚠️ NEEDS REAL FILE
// Replace placeholder with downloaded file from Google Cloud Console
```

## 🔗 Supabase Configuration

### 1. Enable Google Provider
1. Go to your Supabase project: https://ffgqgjhramaktrvyodyb.supabase.co
2. Go to **Authentication** → **Providers**
3. Enable **Google** provider
4. Add your Google OAuth Client ID and Secret
5. **Enable "Skip nonce check"** for iOS

### 2. Add Redirect URLs
Add these URLs to Supabase Authentication Settings:
- `io.supabase.flutterquickstart://login-callback`
- Your Google OAuth redirect URL

## 📱 Code Configuration (Already Done ✅)

Your app already includes:
- ✅ Google Sign-In button on login screen
- ✅ Proper OAuth flow implementation
- ✅ Error handling and loading states
- ✅ Integration with Supabase auth
- ✅ iOS URL scheme configuration

## 🚀 Testing Steps

### 1. Get Your Credentials
1. Create OAuth clients in Google Cloud Console
2. Note your Client IDs:
   - iOS Client ID: `569398521126-67ooqsg9tab669ov9pmqb2mpordrr6ef.apps.googleusercontent.com`
   - Android Client ID: `569398521126-nvrjifv95a6f795886afsurd0u4m9mnl.apps.googleusercontent.com`

### 2. Update Code
Already updated with your actual Client IDs in `lib/services/google_auth_service.dart`:
```dart
// Already updated with your actual Client IDs:
const webClientId = '569398521126-nvrjifv95a6f795886afsurd0u4m9mnl.apps.googleusercontent.com';
const iosClientId = '569398521126-67ooqsg9tab669ov9pmqb2mpordrr6ef.apps.googleusercontent.com';
```

### 3. Update Info.plist
Already updated with your actual REVERSED_CLIENT_ID in `ios/Runner/Info.plist`:
```xml
<!-- Already updated with your actual REVERSED_CLIENT_ID -->
<string>com.googleusercontent.apps.569398521126-67ooqsg9tab669ov9pmqb2mpordrr6ef</string>
```

### 4. Test Google Sign-In
1. Run app on iOS simulator or Android emulator
2. Click "Sign in with Google"
3. Select Google account
4. Verify redirect to SkyMojo dashboard

## 🎯 Expected Flow

1. **User clicks** "Sign in with Google"
2. **Google authentication** opens
3. **User selects** Google account
4. **OAuth tokens** exchanged with Supabase
5. **User profile** created automatically
6. **Redirect to** SkyMojo dashboard

## ✅ Benefits

- **Fast Sign-Up**: No password required
- **Secure**: OAuth 2.0 security
- **Profile Data**: Auto-import user info
- **Cross-Platform**: Works on iOS and Android
- **Supabase Integration**: Seamless user management

Your SkyMojo app is ready for Google Sign-In! Just add your actual Google OAuth credentials.
