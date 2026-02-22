# SkyMojo - Supabase Setup Instructions

## 1. Create Supabase Project ✅ COMPLETED
You've already created your Supabase project at: `https://ffgqgjhramaktrvyodyb.supabase.co`

## 2. Get Your Supabase Credentials ✅ COMPLETED
Your credentials are already configured in `lib/config/supabase_config.dart`

## 3. Set Up Authentication ✅ COMPLETED
1. In Supabase dashboard, go to Authentication → Settings
2. Enable Email/Password authentication (should be enabled by default)
3. Add your app URL to Site URL and Redirect URLs:
   - Site URL: `io.supabase.flutterquickstart://login-callback`
   - Redirect URLs: `io.supabase.flutterquickstart://login-callback`

## 4. Set Up Database Schema 🆕 NEW
1. In Supabase dashboard, go to **SQL Editor**
2. Copy and paste the entire contents of `database_setup.sql`
3. Click **Run** to execute the schema

This will create:
- `user_profiles` - User preferences and settings
- `favorite_locations` - Saved weather locations
- `weather_cache` - Cached weather data (30min expiry)
- `weather_alerts` - Custom weather alerts
- `user_settings` - App preferences
- Row Level Security policies for data protection

## 5. Android Configuration
Add this to `android/app/src/main/AndroidManifest.xml` inside `<activity>`:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.supabase.flutterquickstart" />
</intent-filter>
```

## 6. iOS Configuration
Add this to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>io.supabase.flutterquickstart</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>io.supabase.flutterquickstart</string>
        </array>
    </dict>
</array>
```

## 7. Run the App
```bash
flutter run
```

## 🎉 Features Added

### Authentication ✅
- Email/Password Authentication
- Sign In/Sign Up functionality  
- Automatic session management
- Sign out functionality
- Beautiful login screen with SkyMojo branding

### Database Services ✅
- **Profile Service** (`lib/services/profile_service.dart`)
  - User profile management
  - Temperature unit preferences (celsius/fahrenheit)
  - Theme preferences (light/dark/auto)
  - Default location settings

- **Location Service** (`lib/services/location_service.dart`)
  - Save favorite weather locations
  - Set default location
  - Manage location list
  - GPS coordinates storage

- **Weather Service** (`lib/services/weather_service.dart`)
  - Weather data caching (30min)
  - Custom weather alerts
  - Cache cleanup automation
  - Alert management

- **Settings Service** (`lib/services/settings_service.dart`)
  - Push notification preferences
  - Email alert settings
  - Weather refresh intervals
  - Auto-location toggle

### Database Schema ✅
- **5 Tables** with proper relationships
- **Row Level Security** for data protection
- **Automatic triggers** for timestamps
- **Indexes** for performance
- **Default settings** for new users

## 🚀 Next Steps
1. **Run the SQL schema** in Supabase dashboard
2. **Configure deep linking** for iOS/Android
3. **Test the app** with real authentication
4. **Integrate weather APIs** with the cache system
5. **Build location management UI**
6. **Add weather alert notifications**

## 📱 What to Expect Now
- **First launch**: Login screen with SkyMojo branding
- **Sign up**: Creates user profile automatically
- **Sign in**: Access weather dashboard with preferences
- **Data persistence**: All settings saved to Supabase
- **Security**: Row-level security protects user data

Your SkyMojo app now has a complete backend infrastructure ready for production!
