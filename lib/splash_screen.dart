import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Status bar'ı şeffaf yap
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Logo animasyon controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text animasyon controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Logo scale animasyonu
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Logo fade animasyonu
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Text fade animasyonu
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Text slide animasyonu
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // Animasyonları başlat
    _logoController.forward().then((_) {
      _textController.forward();
    });

    // 3 saniye sonra ana sayfaya git
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: ScaleTransition(
                    scale: _logoScaleAnimation,
                    child: CustomPaint(
                      size: const Size(200, 200),
                      painter: GirisimLogoPainter(isDarkMode: isDarkMode),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // Text
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _textFadeAnimation,
                  child: SlideTransition(
                    position: _textSlideAnimation,
                    child: Column(
                      children: [
                        Text(
                          'GirişİM',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1E3A5F),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Akıllı Kapı Kontrol Sistemi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: isDarkMode
                                ? Colors.white70
                                : const Color(0xFF1E3A5F).withOpacity(0.7),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Logo'yu kod ile çizen painter
class GirisimLogoPainter extends CustomPainter {
  final bool isDarkMode;

  GirisimLogoPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Sol çubuk (koyu mavi)
    paint.color = isDarkMode
        ? const Color(0xFF4A6FA5)
        : const Color(0xFF1E3A5F);
    final leftBar = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.1,
        size.width * 0.2,
        size.height * 0.8,
      ),
      const Radius.circular(25),
    );
    canvas.drawRRect(leftBar, paint);

    // Orta çubuk (turuncu)
    paint.color = const Color(0xFFFF8C00);
    final middleBar = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.4,
        size.height * 0.2,
        size.width * 0.2,
        size.height * 0.6,
      ),
      const Radius.circular(25),
    );
    canvas.drawRRect(middleBar, paint);

    // Sağ çubuk (koyu mavi)
    paint.color = isDarkMode
        ? const Color(0xFF4A6FA5)
        : const Color(0xFF1E3A5F);
    final rightBar = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.65,
        size.height * 0.1,
        size.width * 0.2,
        size.height * 0.8,
      ),
      const Radius.circular(25),
    );
    canvas.drawRRect(rightBar, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Alternatif: Resim dosyası kullanmak isterseniz
class SplashScreenWithImage extends StatefulWidget {
  const SplashScreenWithImage({super.key});

  @override
  State<SplashScreenWithImage> createState() => _SplashScreenWithImageState();
}

class _SplashScreenWithImageState extends State<SplashScreenWithImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo resmi (assets klasöründen)
                // Kendi logo dosya isimlerinizi buraya yazın
                Image.asset(
                  isDarkMode
                      ? 'assets/images/girisim_logo_dark.png' // Koyu tema logo dosyanız
                      : 'assets/images/girisim_logo_light.png', // Açık tema logo dosyanız
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 20),
                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDarkMode
                          ? const Color(0xFFFF8C00)
                          : const Color(0xFF1E3A5F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Shimmer efektli versiyon
class ShimmerSplashScreen extends StatefulWidget {
  const ShimmerSplashScreen({super.key});

  @override
  State<ShimmerSplashScreen> createState() => _ShimmerSplashScreenState();
}

class _ShimmerSplashScreenState extends State<ShimmerSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? const Color(0xFF121212)
          : const Color(0xFFF5F7FA),
      body: Center(
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white,
                    Colors.white.withOpacity(0.5),
                  ],
                  stops: [
                    _shimmerController.value - 0.3,
                    _shimmerController.value,
                    _shimmerController.value + 0.3,
                  ],
                  transform: const GradientRotation(0.5),
                ).createShader(bounds);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: GirisimLogoPainter(isDarkMode: isDarkMode),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'GirişİM',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.white
                          : const Color(0xFF1E3A5F),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
