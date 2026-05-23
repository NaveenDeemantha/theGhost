import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

// ── Hacker Terminal Palette ──────────────────────────────────────────────────
const kTerminalBg   = Color(0xFF0A0A0A);   // pure terminal black
const kTerminalCard = Color(0xFF0F0F0F);   // card surface
const kTerminalBorder = Color(0xFF1C1C1C); // subtle border
const kGreen        = Color(0xFF00FF41);   // Matrix green (primary)
const kGreenDim     = Color(0xFF00A025);   // dimmer green
const kGreenFaint   = Color(0xFF003310);   // very dark green tint
const kCyan         = Color(0xFF00FFFF);   // cyan (info / secondary)
const kOrange       = Color(0xFFFF6600);   // warning / cameras
const kRed          = Color(0xFFFF0033);   // error / danger
const kWhiteText    = Color(0xFFE8E8E8);   // primary text
const kGrayText     = Color(0xFF707070);   // secondary text
const kDimText      = Color(0xFF404040);   // disabled / dim

// Aliases used by older widgets so we don't have to rename every reference
const kNavyDark   = kTerminalBg;
const kNavy       = kTerminalCard;
const kNavyLight  = kTerminalBorder;
const kAccent     = kGreen;
const kWhite      = kWhiteText;
const kOffWhite   = Color(0xFFB0C8B0);     // slightly greenish white
const kErrorRed   = kRed;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: kTerminalBg,
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
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme() {
    final cs = ColorScheme.dark(
      primary: kGreen,
      onPrimary: kTerminalBg,
      primaryContainer: kGreenFaint,
      onPrimaryContainer: kGreen,
      secondary: kCyan,
      onSecondary: kTerminalBg,
      secondaryContainer: const Color(0xFF001A1A),
      onSecondaryContainer: kCyan,
      surface: kTerminalCard,
      onSurface: kWhiteText,
      surfaceContainerHighest: kTerminalBorder,
      error: kRed,
      onError: kWhiteText,
      outline: const Color(0xFF2A2A2A),
      outlineVariant: const Color(0xFF1A1A1A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: kTerminalBg,
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        backgroundColor: kTerminalBg,
        foregroundColor: kGreen,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: kGreen,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          letterSpacing: 2,
        ),
        iconTheme: IconThemeData(color: kGreen),
        actionsIconTheme: IconThemeData(color: kGreen),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: kTerminalBg,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: kTerminalCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: kTerminalBorder, width: 1),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: kWhiteText,
        iconColor: kGreen,
      ),
      dividerTheme: const DividerThemeData(
          color: kTerminalBorder, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D0D0D),
        hintStyle: const TextStyle(color: kDimText, fontFamily: 'monospace'),
        prefixIconColor: kGrayText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: kTerminalBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: kTerminalBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: kGreen, width: 1),
        ),
        labelStyle: const TextStyle(color: kGrayText, fontFamily: 'monospace'),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kGreen,
        foregroundColor: kTerminalBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kGreenFaint,
          foregroundColor: kGreen,
          side: const BorderSide(color: kGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontFamily: 'monospace', letterSpacing: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kGreen,
          foregroundColor: kTerminalBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(
              fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kGreen,
          side: const BorderSide(color: kGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontFamily: 'monospace', letterSpacing: 1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kGreen,
          textStyle: const TextStyle(fontFamily: 'monospace'),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: kGreenFaint,
        selectedColor: kGreenFaint,
        labelStyle: const TextStyle(color: kGreen, fontSize: 11, fontFamily: 'monospace'),
        side: const BorderSide(color: kGreenDim),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: kGreen,
        unselectedLabelColor: kGrayText,
        indicatorColor: kGreen,
        dividerColor: kTerminalBorder,
        labelStyle: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kGreen,
        linearTrackColor: kTerminalBorder,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kTerminalCard,
        contentTextStyle: const TextStyle(color: kGreen, fontFamily: 'monospace', fontSize: 12),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: kGreenDim)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: kTerminalCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: kGreen)),
        titleTextStyle: const TextStyle(
            color: kGreen, fontFamily: 'monospace',
            fontWeight: FontWeight.bold, fontSize: 15),
        contentTextStyle: const TextStyle(
            color: kWhiteText, fontFamily: 'monospace', fontSize: 13),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: kTerminalCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          side: BorderSide(color: kGreenDim),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge:  TextStyle(color: kWhiteText, fontFamily: 'monospace'),
        displayMedium: TextStyle(color: kWhiteText, fontFamily: 'monospace'),
        displaySmall:  TextStyle(color: kWhiteText, fontFamily: 'monospace'),
        headlineLarge: TextStyle(color: kWhiteText, fontFamily: 'monospace'),
        headlineMedium:TextStyle(color: kWhiteText, fontFamily: 'monospace'),
        headlineSmall: TextStyle(color: kGreen, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        titleLarge:    TextStyle(color: kGreen, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        titleMedium:   TextStyle(color: kGreen, fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.5),
        titleSmall:    TextStyle(color: kGrayText, fontFamily: 'monospace', fontSize: 12),
        bodyLarge:     TextStyle(color: kWhiteText, fontFamily: 'monospace'),
        bodyMedium:    TextStyle(color: kOffWhite, fontFamily: 'monospace', fontSize: 13),
        bodySmall:     TextStyle(color: kGrayText, fontFamily: 'monospace', fontSize: 11),
        labelLarge:    TextStyle(color: kGreen, fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1),
        labelMedium:   TextStyle(color: kOffWhite, fontFamily: 'monospace', fontSize: 12),
        labelSmall:    TextStyle(color: kDimText, fontFamily: 'monospace', fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }
}
