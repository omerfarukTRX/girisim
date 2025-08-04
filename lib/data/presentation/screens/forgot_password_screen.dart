// lib/presentation/screens/auth/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:girisim/data/presentation/providers/auth_provider.dart';
import 'package:girisim/data/presentation/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isEmailSent = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'İşlem başarısız'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // İkon ve başlık
                    _buildHeader(
                      theme,
                      isDarkMode,
                    ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),

                    const SizedBox(height: 48),

                    // İçerik
                    if (_isEmailSent)
                      _buildSuccessContent(theme)
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.2, end: 0)
                    else
                      _buildResetForm(theme)
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDarkMode) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isEmailSent ? Icons.mark_email_read : Icons.lock_reset,
            size: 50,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isEmailSent ? 'E-posta Gönderildi' : 'Şifremi Unuttum',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isEmailSent
              ? 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi'
              : 'E-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
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
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _handleResetPassword,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Şifre Sıfırlama Bağlantısı Gönder',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Giriş sayfasına dön'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colors.green.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'E-postanızı kontrol edin ve bağlantıya tıklayarak şifrenizi sıfırlayın.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        OutlinedButton(
          onPressed: () {
            setState(() {
              _isEmailSent = false;
              _emailController.clear();
            });
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Tekrar Gönder'),
        ),

        const SizedBox(height: 12),

        FilledButton(
          onPressed: () => context.go('/auth/login'),
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

        const SizedBox(height: 24),

        Text(
          'Not: Spam klasörünü de kontrol etmeyi unutmayın.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
