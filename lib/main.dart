import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_settings.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettings(),
      child: const AgenticStudyAssistantApp(),
    ),
  );
}

class AgenticStudyAssistantApp extends StatelessWidget {
  const AgenticStudyAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Exeter Brand Colors
    const exeterDarkGreen = Color(0xFF003C3C);
    const exeterDeepGreen = Color(0xFF007D69);
    const exeterBrightGreen = Color(0xFF00C896);

    return MaterialApp(
      title: 'Exeter Study Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: exeterDarkGreen,
          primary: exeterDarkGreen,
          secondary: exeterDeepGreen,
          tertiary: exeterBrightGreen,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: exeterDarkGreen,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: exeterDarkGreen,
          primary: exeterBrightGreen, // Brighter green for dark mode primary
          secondary: exeterDeepGreen,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MainNavigationScreen(),
    );
  }
}
