import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

// Brand colours
const kNavyDark   = Color(0xFF0B1426);
const kNavy       = Color(0xFF1B2A4A);
const kNavyLight  = Color(0xFF2D3F6B);
const kWhite      = Color(0xFFFFFFFF);
const kOffWhite   = Color(0xFFE8EDF5);
const kAccent     = Color(0xFF4A90D9);   // bright navy-blue accent
const kErrorRed   = Color(0xFFCF6679);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: kNavyDark,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const TheGhostApp());
}

class TheGhostApp extends StatelessWidget {
  const TheGhostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TheGhost',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme() {
    final base = ColorScheme.dark(
      primary: kAccent,
      onPrimary: kWhite,
      primaryContainer: kNavyLight,
      onPrimaryContainer: kWhite,
      secondary: kAccent,
      onSecondary: kWhite,
      secondaryContainer: kNavy,
      onSecondaryContainer: kOffWhite,
      surface: kNavy,
      onSurface: kWhite,
      surfaceContainerHighest: kNavyLight,
      error: kErrorRed,
      onError: kWhite,
      outline: const Color(0xFF5A7AAF),
      outlineVariant: const Color(0xFF2D3F6B),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base,
      scaffoldBackgroundColor: kNavyDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: kNavyDark,
        foregroundColor: kWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: kWhite,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kNavyDark,
        selectedItemColor: kAccent,
        unselectedItemColor: Color(0xFF5A7AAF),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: kNavyDark,
        indicatorColor: kNavyLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: kAccent);
          }
          return const IconThemeData(color: Color(0xFF5A7AAF));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: Color(0xFF5A7AAF), fontSize: 12);
        }),
      ),
      cardTheme: CardThemeData(
        color: kNavy,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kNavyLight, width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: kWhite,
        iconColor: kAccent,
      ),
      dividerTheme: const DividerThemeData(color: kNavyLight),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kNavy,
        hintStyle: const TextStyle(color: Color(0xFF5A7AAF)),
        prefixIconColor: const Color(0xFF5A7AAF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kNavyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kNavyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kAccent, width: 2),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kAccent,
        foregroundColor: kWhite,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: kWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: kWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: kNavy,
        selectedColor: kNavyLight,
        labelStyle: const TextStyle(color: kWhite, fontSize: 12),
        side: const BorderSide(color: kNavyLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: kAccent,
        unselectedLabelColor: Color(0xFF5A7AAF),
        indicatorColor: kAccent,
        dividerColor: kNavyLight,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kAccent,
        linearTrackColor: kNavyLight,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: kNavyLight,
        contentTextStyle: TextStyle(color: kWhite),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: kWhite),
        displayMedium: TextStyle(color: kWhite),
        displaySmall: TextStyle(color: kWhite),
        headlineLarge: TextStyle(color: kWhite),
        headlineMedium: TextStyle(color: kWhite),
        headlineSmall: TextStyle(color: kWhite, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: kWhite, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: kWhite, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: kOffWhite),
        bodyLarge: TextStyle(color: kWhite),
        bodyMedium: TextStyle(color: kOffWhite),
        bodySmall: TextStyle(color: Color(0xFF8AAAD4)),
        labelLarge: TextStyle(color: kWhite, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: kOffWhite),
        labelSmall: TextStyle(color: Color(0xFF8AAAD4)),
      ),
    );
  }
}
