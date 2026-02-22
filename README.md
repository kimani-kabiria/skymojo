# SkyMojo 🌙☀️

A comprehensive Weather and Sky View Flutter application that combines real-time weather data with astronomical information, user authentication, and personalized features.

## ✨ Features

- **🌤️ Real-time Weather**: Current weather conditions and forecasts
- **🌙 Sky Views**: Moon phases and astronomical information
- **📍 Location Services**: Save and manage favorite locations
- **🔐 User Authentication**: Secure login with Google Sign-In and email/password
- **👤 User Profiles**: Personalized settings and preferences
- **📱 Beautiful UI**: Modern interface with custom navigation and animations
- **🔔 Weather Alerts**: Customizable notifications for weather changes
- **💾 Data Persistence**: Cloud storage with Supabase backend

## 🛠️ Tech Stack

- **Framework**: Flutter
- **Backend**: Supabase (Authentication, Database, Storage)
- **Authentication**: Google Sign-In, Email/Password
- **Weather API**: OpenWeatherMap
- **Location Services**: Geolocator, Geocoding
- **UI Components**: Curved Navigation Bar, Animated Splash Screen
- **Icons**: Unicons
- **State Management**: GetX

## 📱 Screens

- **Home**: Main dashboard with navigation
- **Weather**: Current conditions and forecasts
- **Nightly**: Moon phases and astronomical data
- **Profile**: User settings and preferences
- **Dashboard**: Comprehensive weather overview

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.2.0)
- Dart SDK
- Android Studio / Xcode
- Supabase account
- Google Developer Console (for Google Sign-In)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd skymojo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Setup**
   
   Create a `.env` file in the root directory:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   GOOGLE_SIGN_IN_CLIENT_ID=your_google_client_id
   ```

4. **Database Setup**
   
   Follow the complete setup guide in [SETUP_COMPLETE.md](./SETUP_COMPLETE.md):
   
   - Run the database schema from `database_setup.sql` in your Supabase project
   - Configure authentication URLs and redirect handlers
   - Set up Google Sign-In credentials

5. **Run the app**
   ```bash
   flutter run
   ```

## 📋 Setup Instructions

For detailed setup instructions, including:
- Database schema configuration
- Authentication setup
- Google Sign-In integration
- Deep linking configuration

See: [SETUP_COMPLETE.md](./SETUP_COMPLETE.md)

Additional setup guides:
- [Google Sign-In Setup](./GOOGLE_SIGNIN_SETUP.md)
- [Supabase Setup](./SUPABASE_SETUP.md)

## 🏗️ Project Structure

```
lib/
├── auth/                 # Authentication screens and gates
├── components/           # Reusable UI components
├── config/              # Configuration files
├── models/              # Data models
├── screens/             # Main app screens
│   ├── home.dart
│   ├── weather.dart
│   ├── nightly.dart
│   └── profile.dart
├── services/            # Business logic and API services
└── main.dart           # App entry point
```

## 🔧 Services

- **AuthService**: User authentication management
- **GoogleAuthService**: Google Sign-In integration
- **UserProfileService**: User profile management
- **WeatherService**: Weather data fetching and caching
- **LocationService**: Location management and geocoding

## 🎨 UI Features

- Custom animated splash screen
- Curved navigation bar
- Weather-themed icons and assets
- Custom fonts (Bellota)
- Responsive design for mobile and tablet

## 📊 Database Schema

The app uses 5 main tables:
- `profiles` - User information and preferences
- `locations` - Saved user locations
- `weather_alerts` - Weather notification settings
- `app_settings` - Application preferences
- `user_sessions` - Authentication session management

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
