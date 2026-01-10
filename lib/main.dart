import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'views/auth/auth_check_screen.dart';
import 'services/api/api_client.dart';
import 'services/local_storage/storage_service.dart';
import 'services/local_storage/token_storage.dart';
import 'services/auth_service/auth_service.dart';
import 'viewmodels/auth/auth_viewmodel.dart';

void main() {
  // Initialize services
  final storageService = StorageService();
  final tokenStorage = TokenStorage(storageService);
  final apiClient = ApiClient(tokenStorage);
  final authService = AuthService(apiClient, tokenStorage);
  final authViewModel = AuthViewModel(authService);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: tokenStorage),
        ChangeNotifierProvider.value(value: authViewModel),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Twizzy',
      // Theme tự động theo theme của thiết bị
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Tự động theo system theme
      // Localization delegates for DatePicker and other Material widgets
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('vi', 'VN'), // Vietnamese
      ],
      home: const AuthCheckScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
