# AgroCare - Smart Agriculture Management App

A comprehensive Flutter application for managing crops, monitoring plant health, and providing agricultural insights using AI-powered plant identification.

**Version**: 1.0.0  
**Last Updated**: January 14, 2026  
**Status**: Active Development

## Project Overview

AgroCare is a smart agricultural application that provides end-to-end support for:
- **Plant Health Monitoring**: Analyze plant images to detect diseases and health issues
- **Crop Maintenance**: Automated maintenance scheduling for watering, fertilization, and pruning
- **Weather-Aware Guidance**: Real-time weather data for optimal crop management
- **Crop Lifecycle Tracking**: Maintain detailed records of plant growth and health progress

## ✨ Features Implemented

### 🔐 Authentication
- ✅ Email/password authentication via Supabase
- ✅ User registration with automatic profile creation
- ✅ Secure login/logout functionality
- ✅ Session persistence across app restarts
- ✅ Password change functionality

### 🌿 Plant Management
- ✅ **AI-Powered Plant Identification**: Identify plants from photos using Plant.id API
- ✅ **Add Plants**: Capture or select plant images and save to database
- ✅ **Plant Library**: View all your plants with health status indicators
- ✅ **Plant Details**: Comprehensive information including:
  - Common name and scientific name
  - Confidence score from AI identification
  - Care instructions (watering, sunlight, temperature)
  - Health status tracking
  - Image gallery

### 👤 Profile Management
- ✅ View and edit user profile
- ✅ Update profile information (name, location)
- ✅ Profile picture upload to Supabase Storage
- ✅ Change password functionality
- ✅ Profile data sync with Supabase

### 🏠 Dashboard & Navigation
- ✅ Beautiful home dashboard with statistics
- ✅ Quick access feature buttons
- ✅ Bottom navigation bar (Home, Plants, Weather, Profile)
- ✅ Responsive Material Design 3 UI
- ✅ Custom green theme for agricultural focus

### 🔧 Additional Features (UI Ready)
- 🎨 Plant health monitoring screen
- 🎨 Maintenance scheduler screen
- 🎨 Weather advisory screen
- 🎨 Crop history tracking screen
- 🎨 Staggered grid layout for plant cards

## 📂 Project Structure

```
agrocare_app/
├── lib/
│   ├── main.dart                          # App entry point with Supabase init
│   ├── config/
│   │   ├── theme.dart                    # Material Design 3 theme
│   │   └── router.dart                   # GoRouter navigation (12 routes)
│   ├── models/
│   │   ├── plant.dart                    # Plant model (updated for AI identification)
│   │   └── maintenance_task.dart         # Task model
│   ├── providers/
│   │   ├── auth_provider.dart            # Auth state (login, signup, profile)
│   │   ├── plant_provider.dart           # Plant management state
│   │   └── maintenance_provider.dart     # Task management state
│   ├── screens/
│   │   ├── splash_screen.dart            # Splash/Loading screen
│   │   ├── login_screen.dart             # Login page
│   │   ├── signup_screen.dart            # Registration page
│   │   ├── home_screen.dart              # Main dashboard
│   │   ├── add_plant_screen.dart         # ✨ NEW: AI plant identification
│   │   ├── plant_detail_screen.dart      # Individual plant details
│   │   ├── plant_health_screen.dart      # Disease analysis
│   │   ├── maintenance_scheduler_screen.dart  # Task management
│   │   ├── weather_advisory_screen.dart   # Weather info
│   │   ├── crop_history_screen.dart       # History tracking
│   │   └── profile_screen.dart            # User profile
│   ├── services/
│   │   └── plant_identification_service.dart  # ✨ NEW: Plant.id API
│   ├── widgets/
│   │   ├── custom_appbar.dart            # Custom AppBar
│   │   └── plant_card.dart               # Plant card widget
│   └── utils/
│       └── helpers.dart                  # Utility functions
├── pubspec.yaml                          # Dependencies
└── README.md                             # This file
```
└── android/                  # Android native code
```

## Dependencies

## 🛠️ Tech Stack

### Frontend
- **Framework**: Flutter 3.38.6
- **Language**: Dart 3.10.7
- **UI**: Material Design 3
- **Navigation**: go_router ^12.0.0
- **State Management**: Provider pattern

### Backend & Services
- **Backend**: Supabase (PostgreSQL + Storage + Auth)
- **Authentication**: Supabase Auth
- **Database**: PostgreSQL via Supabase
- **Storage**: Supabase Storage (S3-compatible)
- **AI Service**: Plant.id API for plant identification

### Key Dependencies
```yaml
dependencies:
  # State Management
  provider: ^6.0.0
  
  # Backend
  supabase_flutter: ^1.10.0
  
  # Navigation
  go_router: ^12.0.0
  
  # UI/UX
  google_fonts: ^6.0.0
  flutter_staggered_grid_view: ^0.7.0
  lottie: ^2.6.0
  
  # Image handling
  image_picker: ^1.0.0
  
  # HTTP requests
  http: ^1.1.0
  
  # Utilities
  shared_preferences: ^2.2.0
  intl: ^0.19.0
  uuid: ^4.0.0
```

## 🎨 Design System

### Color Scheme
- **Primary Green**: `#2D6A4F` - Main brand color
- **Accent Green**: `#52B788` - Secondary actions
- **Success Green**: `#40916C` - Success states
- **Background**: `#F8F9FA` - App background
- **Text Primary**: `#1B263B` - Primary text
- **Text Gray**: `#6C757D` - Secondary text

### Typography
- **Font Family**: Google Fonts (system default with fallback)
- **Heading**: Bold, larger sizes (20-32px)
- **Body**: Regular weight, readable sizes (14-16px)
- **Caption**: Smaller, muted colors (12px)

## 🗄️ Database Schema

### Users Table (Supabase Auth)
```sql
-- Extended user profile table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email VARCHAR NOT NULL,
  name VARCHAR,
  location VARCHAR,
  profile_image_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Plants Table
```sql
CREATE TABLE plants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plant_name VARCHAR(255) NOT NULL,
  scientific_name VARCHAR(255),
  nickname VARCHAR(255),
  image_url TEXT,
  confidence FLOAT,
  care_water TEXT,
  care_sunlight TEXT,
  care_temperature TEXT,
  health_status VARCHAR(50) DEFAULT 'healthy',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- RLS Policies
ALTER TABLE plants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own plants"
ON plants FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own plants"
ON plants FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own plants"
ON plants FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own plants"
ON plants FOR DELETE
USING (auth.uid() = user_id);
```

### Storage Buckets
- **plant-images/**: Plant photos uploaded by users
- **profile-pictures/**: User profile pictures
- **disease-reports/**: Plant disease documentation

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.38.6 or higher
- Dart SDK 3.10.7 or higher
- Supabase account
- Plant.id API key (optional, for plant identification)

### Installation

1. **Navigate to the project directory**
   ```bash
   cd agrocare_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a project at https://supabase.com
   - Copy your project URL and anon key
   - Update `lib/main.dart` with your credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

4. **Set up Database**
   - Go to Supabase SQL Editor
   - Run the SQL scripts above to create tables
   - Create storage buckets: `plant-images`, `profile-pictures`, `disease-reports`

5. **Configure Plant.id API (Optional)**
   - Get API key from https://plant.id
   - Update `lib/services/plant_identification_service.dart`:
   ```dart
   static const String _plantIdApiKey = 'YOUR_API_KEY_HERE';
   ```

6. **Run the app**
   ```bash
   flutter run -d chrome  # For web
   flutter run            # For mobile/Android
   ```

### Build for Production

**Web:**
```bash
flutter build web --release
```

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

## 📱 Usage Guide

### Getting Started
1. **Sign Up**: Create a new account with email and password
2. **Login**: Access your dashboard
3. **Add Plants**: Click "Add Plant" → Select image → AI identifies → Save
4. **View Plants**: Browse your plant library on home screen
5. **Monitor Health**: Track plant health status and care tips
6. **Update Profile**: Customize profile with photo and details

### Key Workflows

#### Adding a Plant
```
Home → "Add Plant" Button → Select Image (Camera/Gallery) → 
"Identify Plant" → View Results → Edit Nickname → "Add Plant" → Success!
```

#### Managing Profile
```
Profile Tab → "Edit Profile" → Update name/location → 
Upload Photo → "Change Password" (optional) → Save
```

#### Viewing Plant Details
```
Home → Click Plant Card → View Details →
See care info, health status, confidence score
```

## 🔧 Known Issues & Solutions

### Issue 1: Profile Updates Not Saving
**Problem**: Profile updates don't persist in Supabase  
**Cause**: RLS (Row Level Security) policies blocking UPDATE  
**Solution**:
```sql
-- Create UPDATE policy in Supabase
CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
```

### Issue 2: Plant Identification Requires API Key
**Problem**: Plant identification fails  
**Cause**: Missing Plant.id API key  
**Solution**: Get free API key from https://plant.id and configure in `plant_identification_service.dart`

### Issue 3: Image Display on Web
**Problem**: `Image.file()` not supported on web  
**Solution**: ✅ Already fixed - uses `Image.memory()` with `FutureBuilder`

## 🧪 Testing

### Test User
- **Email**: shahma@gmail.com
- **Password**: (your configured password)

### Test Scenarios
1. ✅ Login/Logout
2. ✅ Profile update (name, location)
3. ✅ Password change
4. ✅ Image upload (profile picture)
5. ✅ Navigation between screens
6. ⚠️ Plant identification (requires API key)
7. ⚠️ Plant storage (requires database setup)

### Mock Data
The app includes sample data for testing:
- 3 demo plants (displayed on home screen)
- Health status indicators
- Sample maintenance tasks

## 📊 State Management

The app uses **Provider** pattern for state management with 3 main providers:

### Providers

**1. AuthProvider** (`lib/providers/auth_provider.dart`)
- Manages user authentication state
- Handles login, signup, logout
- Profile updates and password changes
- Session persistence

**2. PlantProvider** (`lib/providers/plant_provider.dart`)
- Manages plant data
- CRUD operations for plants
- Plant health status tracking
- Mock data for testing

**3. MaintenanceProvider** (`lib/providers/maintenance_provider.dart`)
- Manages maintenance tasks
- Task scheduling
- Task filtering (pending/completed)

### Navigation (GoRouter)
- 12 routes configured
- Declarative routing with deep linking
- Bottom navigation: Home, Plants, Weather, Profile
- Proper navigation stack with `context.push()` and `context.pop()`

## 🚧 Future Enhancements

### Planned Features
- [ ] Real-time weather integration with API
- [ ] Disease detection with ML model
- [ ] Maintenance task notifications
- [ ] Crop yield tracking
- [ ] Community features (share plants, tips)
- [ ] Offline mode support
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] IoT sensor integration
- [ ] Analytics dashboard

### Technical Improvements
- [ ] Unit tests coverage
- [ ] Integration tests
- [ ] Performance optimization
- [ ] Error tracking (Sentry/Firebase Crashlytics)
- [ ] Analytics integration (Firebase/Mixpanel)

## 📖 API Documentation

### Plant.id API
**Endpoint**: `https://api.plant.id/v2/identify`

**Request**:
```json
{
  "images": ["base64_encoded_image"],
  "modifiers": ["similar_images"],
  "plant_details": [
    "watering",
    "sunlight",
    "propagation_methods",
    "common_names",
    "description"
  ]
}
```

**Response**:
```json
{
  "plant_name": "Tomato",
  "scientific_name": "Solanum lycopersicum",
  "confidence": 95.5,
  "watering": "Regular watering required",
  "sunlight": "Full sun (6-8 hours)",
  "temperature": "18-27°C"
}
```

## 🛡️ Security Features

- ✅ Row Level Security (RLS) on all tables
- ✅ User-specific data isolation
- ✅ Secure authentication with Supabase
- ✅ Password hashing (handled by Supabase)
- ✅ Session management
- ✅ Storage access control
- ✅ Environment variable protection

## 📝 Development Notes

### Navigation Pattern
- Use `context.push()` for feature screens (creates navigation stack)
- Use `context.go()` only for home route (replaces current route)
- Always check `context.canPop()` before calling `context.pop()`

### Image Handling
- **Web**: Use `Image.memory()` with `FutureBuilder` for async loading
- **Mobile**: Can use `Image.file()` directly
- Always handle loading states

### Error Handling
- All API calls wrapped in try-catch
- User-friendly error messages via SnackBar
- Console logging for debugging (`print()` statements)
- Comprehensive error states in UI

## 🔗 Resources & Links

- **Supabase Dashboard**: https://app.supabase.com
- **Project URL**: https://uasqfoyqkrstkbfqphgd.supabase.co
- **Plant.id API**: https://plant.id
- **Flutter Documentation**: https://docs.flutter.dev
- **Material Design 3**: https://m3.material.io
- **Provider Package**: https://pub.dev/packages/provider
- **GoRouter Package**: https://pub.dev/packages/go_router

## 🐛 Troubleshooting

### Common Issues

**Issue: App crashes on startup**
- Solution: Run `flutter clean` && `flutter pub get`

**Issue: Supabase connection fails**
- Solution: Verify URL and anon key in `main.dart`

**Issue: Images not displaying**
- Solution: Check internet connectivity and storage bucket permissions

**Issue: Provider state not updating**
- Solution: Ensure `notifyListeners()` is called after state changes

**Issue: "Unsupported operation: _Namespace" on web**
- Solution: ✅ Already fixed - using `Image.memory()` instead of `Image.file()`

## 🤝 Contributing

This is an educational project. Areas for contribution:
1. Bug fixes
2. UI/UX improvements
3. New feature implementations
4. Documentation updates
5. Test coverage improvements

## 📄 License

This project is developed for educational purposes.

## 👥 Credits

**Project**: AgroCare Agriculture Management App  
**Built with**: Flutter & Supabase  
**AI Integration**: Plant.id API  
**Developer**: Learning Project

---

**Last Updated**: January 14, 2026  
**Version**: 1.0.0  
**Status**: Active Development ✨
- Consult Provider documentation: https://pub.dev/packages/provider

---

**App Version**: 1.0.0  
**Last Updated**: January 13, 2026  
**Flutter Version**: 3.38.6  
**Dart Version**: 3.10.7
