import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'data/presentation/providers/auth_provider.dart';
import 'data/presentation/providers/site_provider.dart';
import 'data/presentation/providers/device_provider.dart';
import 'data/presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<AuthProvider, SiteProvider>(
          create: (_) => SiteProvider(),
          update: (_, auth, site) => site!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DeviceProvider>(
          create: (_) => DeviceProvider(),
          update: (_, auth, device) => device!..updateAuth(auth),
        ),
      ],
      child: const GirisimApp(),
    ),
  );
}
