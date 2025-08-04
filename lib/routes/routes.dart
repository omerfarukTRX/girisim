// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:girisim/data/presentation/providers/auth_provider.dart';
import 'package:girisim/data/presentation/screens/add_site_screen.dart';
import 'package:girisim/data/presentation/screens/admin_dashboard_screen.dart';
import 'package:girisim/data/presentation/screens/device_list_screen.dart';
import 'package:girisim/data/presentation/screens/forgot_password_screen.dart';
import 'package:girisim/data/presentation/screens/login_screen.dart';
import 'package:girisim/data/presentation/screens/site_detail_screen.dart';
import 'package:girisim/data/presentation/screens/sites_list_screen.dart';
import 'package:girisim/splash_screen.dart';
import 'package:go_router/go_router.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/global_admin/admin_dashboard_screen.dart';
import '../presentation/screens/global_admin/sites/sites_list_screen.dart';
import '../presentation/screens/global_admin/sites/add_site_screen.dart';
import '../presentation/screens/global_admin/sites/site_detail_screen.dart';
import '../presentation/screens/global_admin/devices/device_list_screen.dart';
import '../presentation/screens/global_admin/devices/add_device_screen.dart';
import '../presentation/screens/site_admin/site_admin_dashboard.dart';
import '../presentation/screens/site_admin/users/users_list_screen.dart';
import '../presentation/screens/site_admin/users/add_user_screen.dart';
import '../presentation/screens/site_admin/logs/access_logs_screen.dart';
import '../presentation/screens/user/user_home_screen.dart';
import '../presentation/screens/user/door_control_screen.dart';
import '../presentation/screens/user/guest_qr_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/profile/change_password_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../data/models/user_model.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      debugLogDiagnostics: true,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthenticating =
            authProvider.status == AuthStatus.authenticating;
        final isOnAuthPage = state.matchedLocation.startsWith('/auth');
        final isOnSplash = state.matchedLocation == '/splash';

        // Splash ekranında ise bekle
        if (isOnSplash) {
          if (isAuthenticating) return null;
          if (isAuthenticated) {
            return _getHomeRouteForUser(authProvider.currentUser);
          }
          return '/auth/login';
        }

        // Giriş yapmamışsa ve auth sayfasında değilse
        if (!isAuthenticated && !isOnAuthPage) {
          return '/auth/login';
        }

        // Giriş yapmışsa ve auth sayfasındaysa
        if (isAuthenticated && isOnAuthPage) {
          return _getHomeRouteForUser(authProvider.currentUser);
        }

        // Yetki kontrolü
        if (isAuthenticated) {
          final user = authProvider.currentUser;
          if (user != null) {
            // Global Admin rotaları
            if (state.matchedLocation.startsWith('/admin') &&
                !user.isGlobalAdmin) {
              return _getHomeRouteForUser(user);
            }

            // Site Admin rotaları
            if (state.matchedLocation.startsWith('/site-admin') &&
                !user.isSiteAdmin &&
                !user.isGlobalAdmin) {
              return _getHomeRouteForUser(user);
            }
          }
        }

        return null;
      },
      routes: [
        // Splash
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Auth Routes
        GoRoute(
          path: '/auth',
          redirect: (_, __) => '/auth/login',
          routes: [
            GoRoute(
              path: 'login',
              name: 'login',
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              path: 'forgot-password',
              name: 'forgotPassword',
              builder: (context, state) => const ForgotPasswordScreen(),
            ),
          ],
        ),

        // Global Admin Routes
        GoRoute(
          path: '/admin',
          name: 'adminDashboard',
          builder: (context, state) => const AdminDashboardScreen(),
          routes: [
            // Sites
            GoRoute(
              path: 'sites',
              name: 'sitesList',
              builder: (context, state) => const SitesListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'addSite',
                  builder: (context, state) => const AddSiteScreen(),
                ),
                GoRoute(
                  path: ':siteId',
                  name: 'siteDetail',
                  builder: (context, state) =>
                      SiteDetailScreen(siteId: state.pathParameters['siteId']!),
                  routes: [
                    // Devices
                    GoRoute(
                      path: 'devices',
                      name: 'siteDevices',
                      builder: (context, state) => DeviceListScreen(
                        siteId: state.pathParameters['siteId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'add',
                          name: 'addDevice',
                          builder: (context, state) => AddDeviceScreen(
                            siteId: state.pathParameters['siteId']!,
                          ),
                        ),
                      ],
                    ),
                    // Users
                    GoRoute(
                      path: 'users',
                      name: 'siteUsers',
                      builder: (context, state) => UsersListScreen(
                        siteId: state.pathParameters['siteId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'add',
                          name: 'addSiteUser',
                          builder: (context, state) => AddUserScreen(
                            siteId: state.pathParameters['siteId']!,
                          ),
                        ),
                      ],
                    ),
                    // Logs
                    GoRoute(
                      path: 'logs',
                      name: 'siteLogs',
                      builder: (context, state) => AccessLogsScreen(
                        siteId: state.pathParameters['siteId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Site Admin Routes
        GoRoute(
          path: '/site-admin',
          name: 'siteAdminDashboard',
          builder: (context, state) => const SiteAdminDashboard(),
          routes: [
            GoRoute(
              path: 'users',
              name: 'manageUsers',
              builder: (context, state) =>
                  UsersListScreen(siteId: state.extra as String? ?? ''),
              routes: [
                GoRoute(
                  path: 'add',
                  name: 'addUser',
                  builder: (context, state) =>
                      AddUserScreen(siteId: state.extra as String? ?? ''),
                ),
              ],
            ),
            GoRoute(
              path: 'logs',
              name: 'viewLogs',
              builder: (context, state) =>
                  AccessLogsScreen(siteId: state.extra as String? ?? ''),
            ),
          ],
        ),

        // User Routes
        GoRoute(
          path: '/home',
          name: 'userHome',
          builder: (context, state) => const UserHomeScreen(),
          routes: [
            GoRoute(
              path: 'control',
              name: 'doorControl',
              builder: (context, state) => const DoorControlScreen(),
            ),
            GoRoute(
              path: 'guest',
              name: 'guestQR',
              builder: (context, state) => const GuestQRScreen(),
            ),
          ],
        ),

        // Profile Routes
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'change-password',
              name: 'changePassword',
              builder: (context, state) => const ChangePasswordScreen(),
            ),
          ],
        ),

        // Settings
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
      errorBuilder: (context, state) => ErrorPage(error: state.error),
    );
  }

  // Kullanıcı rolüne göre ana sayfa
  static String _getHomeRouteForUser(UserModel? user) {
    if (user == null) return '/auth/login';

    switch (user.role) {
      case UserRole.globalAdmin:
        return '/admin';
      case UserRole.siteAdmin:
        return '/site-admin';
      case UserRole.user:
        return '/home';
    }
  }
}

// Hata sayfası
class ErrorPage extends StatelessWidget {
  final Exception? error;

  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hata')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Bir hata oluştu',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Bilinmeyen hata',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    );
  }
}

// Route Extensions
extension GoRouterExtension on BuildContext {
  void goNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) => GoRouter.of(this).goNamed(
    name,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
    extra: extra,
  );

  void pushNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) => GoRouter.of(this).pushNamed(
    name,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
    extra: extra,
  );

  void pushReplacementNamed(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) => GoRouter.of(this).pushReplacementNamed(
    name,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
    extra: extra,
  );
}
