import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/places_provider.dart';
import 'providers/cities_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/city_chat_provider.dart';
import 'services/firestore_service.dart';
import 'screens/home_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
  @override
  _AppStartupState createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  bool _isLoading = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final places = Provider.of<PlacesProvider>(context, listen: false);
    final cities = Provider.of<CitiesProvider>(context, listen: false);
    final notifications =
        Provider.of<NotificationsProvider>(context, listen: false);
    final firestore = FirestoreService();

    try {
      await firestore.seedInitialData();
      await cities.fetchCities();
      await auth.tryAutoLogin();
      if (auth.isAuthenticated) {
        await auth.syncUserSession(
          placesProvider: places,
          notificationsProvider: notifications,
        );
      }
    } catch (e) {
      debugPrint('App startup failed: $e');
      _initError = e.toString();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
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
