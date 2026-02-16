import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/plant_detail_screen.dart';
import '../screens/plant_health_screen.dart';
import '../screens/maintenance_scheduler_screen.dart';
import '../screens/weather_advisory_screen.dart';
import '../screens/crop_history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/add_plant_screen.dart';
import '../screens/plant_disease_detection_screen.dart';
import '../screens/my_plants_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/plant/:id',
      builder: (context, state) {
        final plantId = state.pathParameters['id']!;
        return PlantDetailScreen(plantId: plantId);
      },
    ),
    GoRoute(
      path: '/plant-health',
      builder: (context, state) => const PlantHealthScreen(),
    ),
    GoRoute(
      path: '/maintenance',
      builder: (context, state) => const MaintenanceSchedulerScreen(),
    ),
    GoRoute(
      path: '/weather',
      builder: (context, state) => const WeatherAdvisoryScreen(),
    ),
    GoRoute(
      path: '/crop-history',
      builder: (context, state) => const CropHistoryScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/add-plant',
      builder: (context, state) => const AddPlantScreen(),
    ),
    GoRoute(
      path: '/disease-detection',
      builder: (context, state) => const PlantDiseaseDetectionScreen(),
    ),
    GoRoute(
      path: '/my-plants',
      builder: (context, state) => const MyPlantsScreen(),
    ),
    GoRoute(
      path: '/my-plants',
      builder: (context, state) => const MyPlantsScreen(),
    ),
  ],
);
