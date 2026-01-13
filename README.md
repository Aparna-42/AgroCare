# agrocare_app

A new Flutter project.

# AgroCare - Intelligent Plant Maintenance Platform

An Android Flutter application designed to help users manage their plants and crops with intelligent disease detection, maintenance scheduling, weather-aware guidance, and comprehensive crop monitoring.

## Project Overview

AgroCare is a smart agricultural application that provides end-to-end support for:
- **Plant Health Monitoring**: Analyze plant images to detect diseases and health issues
- **Crop Maintenance**: Automated maintenance scheduling for watering, fertilization, and pruning
- **Weather-Aware Guidance**: Real-time weather data for optimal crop management
- **Crop Lifecycle Tracking**: Maintain detailed records of plant growth and health progress

## Features

### 1. **Authentication System**
- User login and registration
- Secure session management
- Profile management

### 2. **Home Dashboard**
- Overview of all plants
- Quick stats (total plants, health status, pending tasks)
- Quick access to main features
- Upcoming maintenance tasks

### 3. **Plant Health Analysis**
- Upload or capture plant images
- AI-powered disease detection (using CNN)
- Health status assessment
- Detailed treatment recommendations
- Plant type identification

### 4. **Maintenance Scheduler**
- Smart maintenance scheduling
- Task creation and management
- Task filtering (all, pending, completed)
- Automated reminders for watering, fertilization, and pruning
- Historical task tracking

### 5. **Weather Advisory**
- Real-time weather data integration
- 5-day weather forecast
- Agricultural weather advisories
- UV index monitoring
- Rainfall and humidity tracking

### 6. **Crop History & Monitoring**
- Comprehensive crop lifecycle tracking
- Historical data analysis
- Plant growth progress monitoring
- Disease history
- Long-term trend analysis

### 7. **User Profile**
- Profile management
- Account settings
- App preferences
- Support and information
- Logout functionality

## Project Structure

```
agrocare_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/
│   │   ├── theme.dart           # App theme and colors
│   │   └── router.dart          # Navigation routing
│   ├── models/
│   │   ├── user.dart            # User model
│   │   ├── plant.dart           # Plant model
│   │   ├── weather_data.dart    # Weather model
│   │   └── maintenance_task.dart # Task model
│   ├── providers/
│   │   ├── auth_provider.dart    # Authentication state
│   │   ├── plant_provider.dart   # Plant management state
│   │   └── maintenance_provider.dart # Task management state
│   ├── screens/
│   │   ├── splash_screen.dart         # Splash/Loading screen
│   │   ├── login_screen.dart          # Login page
│   │   ├── signup_screen.dart         # Registration page
│   │   ├── home_screen.dart           # Main dashboard
│   │   ├── plant_detail_screen.dart   # Individual plant details
│   │   ├── plant_health_screen.dart   # Disease analysis
│   │   ├── maintenance_scheduler_screen.dart # Task management
│   │   ├── weather_advisory_screen.dart      # Weather info
│   │   ├── crop_history_screen.dart          # History tracking
│   │   └── profile_screen.dart               # User profile
│   ├── widgets/
│   │   ├── custom_appbar.dart              # Custom AppBar
│   │   ├── plant_card.dart                 # Plant card widget
│   │   └── health_status_indicator.dart    # Health status widget
│   └── utils/
│       └── helpers.dart                    # Utility functions
├── pubspec.yaml              # Dependencies
└── android/                  # Android native code
```

## Dependencies

The app uses the following key packages:

- **provider**: State management
- **go_router**: Navigation and routing
- **google_fonts**: Typography
- **http**: API requests
- **image_picker**: Image capture and upload
- **intl**: Internationalization
- **shared_preferences**: Local storage
- **flutter_staggered_grid_view**: Responsive layouts
- **lottie**: Animations

## Design & UI

### Color Scheme
- **Primary Green**: #2D7A3E (Main brand color)
- **Accent Green**: #4CAF50 (Highlights)
- **Light Green**: #E8F5E9 (Backgrounds)
- **Dark Green**: #1B5E20 (Text)
- **Warm Brown**: #8D6E63 (Secondary)
- **Error Red**: #E53935 (Critical alerts)
- **Warning Orange**: #FFA726 (Warnings)

### Typography
- **Font Family**: Poppins
- **Headlines**: Bold, 24-32px
- **Body**: Regular, 12-16px

### UI Components
- Modern Material Design 3
- Rounded corners (12-16px borders)
- Soft shadows for depth
- Gradient backgrounds for headers
- Icon-based navigation

## Getting Started

### Prerequisites
- Flutter SDK 3.10.7 or higher
- Android SDK
- Android Studio or VS Code with Flutter extension

### Installation

1. **Navigate to the project directory**
   ```bash
   cd agrocare_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Build for Android

**Debug APK:**
```bash
flutter build apk --debug
```

**Release APK:**
```bash
flutter build apk --release
```

The APK will be generated in `build/app/outputs/apk/`

## Backend Integration Notes

The app is currently built with mock data. To integrate with a real backend:

### API Endpoints to Implement:

1. **Authentication**
   - `POST /api/auth/login`
   - `POST /api/auth/register`
   - `POST /api/auth/logout`

2. **Plant Management**
   - `GET /api/plants` - Get all user plants
   - `POST /api/plants` - Add new plant
   - `GET /api/plants/:id` - Get plant details
   - `PUT /api/plants/:id` - Update plant
   - `DELETE /api/plants/:id` - Delete plant

3. **Disease Detection**
   - `POST /api/plants/analyze` - Upload image for analysis
   - `GET /api/diseases/:id` - Get disease information

4. **Maintenance Tasks**
   - `GET /api/tasks` - Get all tasks
   - `POST /api/tasks` - Create task
   - `PUT /api/tasks/:id` - Update task
   - `DELETE /api/tasks/:id` - Delete task

5. **Weather Data**
   - `GET /api/weather` - Get current weather
   - `GET /api/weather/forecast` - Get 5-day forecast

### Making API Calls

Replace mock data in providers with HTTP requests:

```dart
// Example in plant_provider.dart
Future<void> fetchPlants() async {
  try {
    final response = await http.get(
      Uri.parse('https://your-api.com/api/plants'),
      headers: {'Authorization': 'Bearer $authToken'},
    );
    if (response.statusCode == 200) {
      // Parse and update plants list
      notifyListeners();
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

## Features To Be Implemented

The following features are currently using mock data and require backend integration:

1. **Image Analysis with ML**
   - Integrate with TensorFlow or ML Kit for disease detection
   - Train CNN model for plant disease classification

2. **Real-time Weather API**
   - Integrate with OpenWeatherMap or similar service
   - Real-time location-based weather

3. **Push Notifications**
   - Task reminders
   - Weather alerts
   - Plant health warnings

4. **Database**
   - User authentication and authorization
   - Plant data storage
   - Historical records
   - Image storage

5. **Cloud Storage**
   - Plant images
   - User profiles
   - Backup and sync

## Testing

### Mock Data Structure

The app includes pre-populated mock data for testing:
- 3 sample plants (Tomato, Rose, Basil)
- 3 maintenance tasks
- Sample weather data

### Test Credentials

- Email: `test@agrocare.com`
- Password: `123456`

## Architecture

### State Management (Provider)
- **AuthProvider**: Manages user authentication state
- **PlantProvider**: Manages all plant data
- **MaintenanceProvider**: Manages maintenance tasks

### Navigation (GoRouter)
- Declarative routing with deep linking support
- Bottom navigation between main sections
- Stack-based navigation for detail screens

## Future Enhancements

1. **Machine Learning**
   - On-device disease detection model
   - Crop yield prediction
   - Optimal harvest timing

2. **Community Features**
   - Share experiences with other farmers
   - Community Q&A
   - Expert advice channel

3. **IoT Integration**
   - Connect with soil moisture sensors
   - Weather station integration
   - Automated watering systems

4. **Multi-language Support**
   - Regional language support
   - Localized recommendations

5. **Analytics Dashboard**
   - Advanced crop analytics
   - Production trends
   - Resource optimization

## Troubleshooting

### Common Issues

**Issue: App crashes on startup**
- Solution: Run `flutter clean` and `flutter pub get` again

**Issue: Images not displaying**
- Solution: Check image asset paths and ensure internet connectivity

**Issue: Provider state not updating**
- Solution: Ensure all consumers are wrapped properly and providers are declared in main.dart

## Contributing

For backend API development, follow these guidelines:
- RESTful API design
- JSON response format
- Proper error handling
- Authentication using JWT

## License

This project is developed for educational purposes.

## Support

For issues or questions:
- Check the Flutter documentation: https://flutter.dev
- Review the GoRouter documentation: https://pub.dev/packages/go_router
- Consult Provider documentation: https://pub.dev/packages/provider

---

**App Version**: 1.0.0  
**Last Updated**: January 13, 2026  
**Flutter Version**: 3.38.6  
**Dart Version**: 3.10.7
