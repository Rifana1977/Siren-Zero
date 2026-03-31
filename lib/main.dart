import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runanywhere/runanywhere.dart';
import 'package:runanywhere_llamacpp/runanywhere_llamacpp.dart';
import 'package:runanywhere_onnx/runanywhere_onnx.dart';

import 'package:siren_zero/services/model_service.dart';
import 'package:siren_zero/theme/app_theme.dart';
import 'package:siren_zero/theme/theme_provider.dart';
import 'package:siren_zero/views/siren_zero_home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the RunAnywhere SDK
  await RunAnywhere.initialize();

  // Register backends
  await LlamaCpp.register();
  await Onnx.register();

  // Register models
  ModelService.registerDefaultModels();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModelService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const RunAnywhereStarterApp(),
    ),
  );
}

class RunAnywhereStarterApp extends StatelessWidget {
  const RunAnywhereStarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Siren-Zero',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const SirenZeroHomeView(),
        );
      },
    );
  }
}
