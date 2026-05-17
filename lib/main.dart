import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/places_provider.dart';
import 'providers/cities_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/city_chat_provider.dart';
import 'providers/review_provider.dart';
import 'providers/reminder_provider.dart';
import 'services/cache_service.dart';
import 'services/nearby_notification_service.dart';
import 'services/push_notification_service.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SharedPreferences.getInstance();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PlacesProvider()),
        ChangeNotifierProvider(create: (_) => CitiesProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => CityChatProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: MaterialApp(
        title: 'LikeALocal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: AppStartup(),
      ),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  bool _isLoading = true;
  String? _initError;
  final NearbyNotificationService _nearbyService = NearbyNotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _nearbyService.stopMonitoring();
    super.dispose();
  }

  Future<void> _initialize() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final places = Provider.of<PlacesProvider>(context, listen: false);
    final cities = Provider.of<CitiesProvider>(context, listen: false);
    final notifications =
        Provider.of<NotificationsProvider>(context, listen: false);
    final reminders = Provider.of<ReminderProvider>(context, listen: false);

    try {
      await cities.fetchCities();
      await auth.tryAutoLogin();
      if (auth.isAuthenticated) {
        await auth.syncUserSession(
          placesProvider: places,
          notificationsProvider: notifications,
        );
        await reminders.loadReminders(auth.currentUser!.id);

        // Cache premium status locally
        await CacheService.instance.savePremiumStatus(auth.currentUser!.isPro);
        await CacheService.instance.savePinnedPlaces(auth.currentUser!.pinnedPlaceIds);

        // Check for super user promotion
        await auth.checkAndPromoteToSuperUser();

        // Initialize push notifications
        await PushNotificationService().initialize(auth.currentUser!.id);

        // Start nearby monitoring
        _startNearbyMonitoring(auth, places, notifications);
      }
    } catch (e) {
      debugPrint('App startup failed: $e');
      _initError = e.toString();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _startNearbyMonitoring(
    AuthProvider auth,
    PlacesProvider places,
    NotificationsProvider notifications,
  ) {
    final allPlaces = places.getAllPlaces();
    if (allPlaces.isEmpty) return;

    _nearbyService.startMonitoring(
      userId: auth.currentUser!.id,
      places: allPlaces,
      onNearbyPlace: (title, message) {
        notifications.loadForUser(auth.currentUser!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(title),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(label: 'View', onPressed: () {}),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF2F6E7E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LikeALocal',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Could not connect to Firestore.\n\n$_initError',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return HomeShell();
  }
}
