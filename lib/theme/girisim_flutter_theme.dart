import 'package:flutter/material.dart';

class GirisimTheme {
  // Marka Renkleri
  static const Color primaryBlue = Color(0xFF1E3A5F);
  static const Color accentOrange = Color(0xFFFF8C00);
  static const Color darkNavy = Color(0xFF0F1F3A);
  static const Color lightBlue = Color(0xFF4A6FA5);
  static const Color lightOrange = Color(0xFFFFB347);

  // Nötr Renkler
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textDark = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFFE0E0E0);

  // Açık Tema
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Renk Şeması
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: accentOrange,
      onSecondary: Colors.white,
      tertiary: lightBlue,
      surface: surfaceLight,
      onSurface: textDark,
      error: Color(0xFFE74C3C),
      onError: Colors.white,
    ),

    // AppBar Teması
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Elevated Button Teması
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Text Button Teması
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    // Floating Action Button Teması
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentOrange,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // Card Teması
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Input Decoration Teması
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE74C3C)),
      ),
      labelStyle: const TextStyle(color: textDark),
      hintStyle: TextStyle(color: textDark.withOpacity(0.6)),
    ),

    // Bottom Navigation Bar Teması
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),

    // Chip Teması
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade100,
      selectedColor: accentOrange.withOpacity(0.2),
      labelStyle: const TextStyle(color: textDark),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );

  // Koyu Tema
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Renk Şeması
    colorScheme: ColorScheme.dark(
      primary: lightBlue,
      onPrimary: Colors.white,
      secondary: accentOrange,
      onSecondary: Colors.white,
      tertiary: lightOrange,
      surface: surfaceDark,
      onSurface: textLight,
      error: const Color(0xFFE74C3C),
      onError: Colors.white,
    ),

    // AppBar Teması
    appBarTheme: const AppBarTheme(
      backgroundColor: darkNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Elevated Button Teması
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Text Button Teması
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightOrange,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),

    // Floating Action Button Teması
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentOrange,
      foregroundColor: Colors.white,
      elevation: 4,
    ),

    // Card Teması
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Input Decoration Teması
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: lightBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE74C3C)),
      ),
      labelStyle: const TextStyle(color: textLight),
      hintStyle: TextStyle(color: textLight.withOpacity(0.6)),
    ),

    // Bottom Navigation Bar Teması
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkNavy,
      selectedItemColor: accentOrange,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),

    // Chip Teması
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2A2A2A),
      selectedColor: accentOrange.withOpacity(0.3),
      labelStyle: const TextStyle(color: textLight),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

// Kullanım Örneği
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GirişİM',
      debugShowCheckedModeBanner: false,
      theme: GirisimTheme.lightTheme,
      darkTheme: GirisimTheme.darkTheme,
      themeMode: ThemeMode.system, // Sistem temasını takip eder
      home: const HomePage(),
    );
  }
}

// Örnek Sayfa
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GirişİM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş Geldiniz',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Site kapılarınızı güvenle kontrol edin.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Ara',
                hintText: 'Kapı veya bölge ara...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Ana Kapıyı Aç'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () {}, child: const Text('Giriş Kayıtları')),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: const Text('A Blok'), onDeleted: () {}),
                const Chip(label: Text('B Blok')),
                const Chip(label: Text('Otopark')),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.qr_code_scanner),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.door_front_door),
            label: 'Kapılar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Sakinler'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
