import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/project_service.dart';
import 'ui/screens/home/home_screen.dart';
import 'ui/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final projectService = await ProjectService.create();

    // DEFINITIVE FIX: Wrap the app in a MultiProvider to handle all providers.
    runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<ProjectService>.value(value: projectService),
      ],
      child: const MyApp(),
    ));
  } catch (e) {
    runApp(ErrorApp(error: e));
  }
}

// CORRECTED: MyApp no longer needs to manage the project service directly.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to rebuild MaterialApp when the theme changes.
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'BBox Annotator',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode, // DYNAMIC theme mode
          home: const HomeScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// ErrorApp remains unchanged.
class ErrorApp extends StatelessWidget {
  final Object error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Critical Error during App Initialization:\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
