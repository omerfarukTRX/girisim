import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:girisim/routes/routes.dart';
import 'package:girisim/theme/girisim_flutter_theme.dart';
import 'package:provider/provider.dart';
import 'data/presentation/providers/auth_provider.dart';
import 'data/presentation/providers/theme_provider.dart';

class GirisimApp extends StatelessWidget {
  const GirisimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, _) {
        return MaterialApp.router(
          title: 'GirişİM',
          debugShowCheckedModeBanner: false,
          theme: GirisimTheme.lightTheme,
          darkTheme: GirisimTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter.router(authProvider),
        );
      },
    );
  }
}
