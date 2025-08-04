// lib/presentation/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/presentation/providers/auth_provider.dart';
import 'package:girisim/data/presentation/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../core/constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      // Hata mesajını göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Giriş başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  height: size.height - MediaQuery.of(context).padding.top,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Logo
                      _buildLogo(
                        isDarkMode,
                      ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),

                      const SizedBox(height: 48),

                      // Form
                      _buildLoginForm(theme)
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),

                      const Spacer(flex: 2),

                      // Alt bilgi
                      _buildFooter(
                        theme,
                      ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo(bool isDarkMode) {
    return Column(
      children: [
        // Logo (CustomPaint veya Image)
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFF1E3A5F).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.door_front_door,
              size: 60,
              color: isDarkMode ? Colors.white : const Color(0xFF1E3A5F),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'GirişİM',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Akıllı Kapı Kontrol Sistemi',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode
                ? Colors.white.withOpacity(0.7)
                : const Color(0xFF1E3A5F).withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'E-posta',
              hintText: 'ornek@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: Validators.email,
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'Şifre',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: Validators.password,
          ),
          const SizedBox(height: 12),

          // Remember me & Forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Beni hatırla', style: theme.textTheme.bodyMedium),
                ],
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed('forgotPassword');
                },
                child: const Text('Şifremi unuttum'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Login button
          FilledButton(
            onPressed: _handleLogin,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Giriş Yap',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        Text(
          '© 2024 GirişİM',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'v${AppConstants.appVersion}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
