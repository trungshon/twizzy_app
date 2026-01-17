import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';
import 'services/api/api_client.dart';
import 'services/local_storage/storage_service.dart';
import 'services/local_storage/token_storage.dart';
import 'services/auth_service/auth_service.dart';
import 'services/google_auth/google_auth_service.dart';
import 'services/twizz_service/twizz_service.dart';
import 'services/search_service/search_service.dart';
import 'services/like_service/like_service.dart';
import 'services/bookmark_service/bookmark_service.dart';
import 'viewmodels/auth/auth_viewmodel.dart';
import 'viewmodels/twizz/create_twizz_viewmodel.dart';
import 'viewmodels/newsfeed/newsfeed_viewmodel.dart';
import 'viewmodels/profile/profile_viewmodel.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize services
  final storageService = StorageService();
  final tokenStorage = TokenStorage(storageService);
  final apiClient = ApiClient(tokenStorage);
  final authService = AuthService(apiClient, tokenStorage);
  final twizzService = TwizzService(apiClient);
  final searchService = SearchService(apiClient);
  final likeService = LikeService(apiClient);
  final bookmarkService = BookmarkService(apiClient);

  // Initialize view models
  final authViewModel = AuthViewModel(authService);
  final createTwizzViewModel = CreateTwizzViewModel(
    twizzService,
    searchService,
  );
  final newsFeedViewModel = NewsFeedViewModel(
    twizzService,
    likeService,
    bookmarkService,
  );
  final profileViewModel = ProfileViewModel(
    twizzService,
    likeService,
    bookmarkService,
  );

  // Initialize Google Auth Service
  // Web Client ID (dùng cho serverClientId để lấy idToken) - lấy từ env
  final googleWebClientId = dotenv.get('GOOGLE_WEB_CLIENT_ID');
  GoogleAuthService().initialize(webClientId: googleWebClientId);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: tokenStorage),
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProvider.value(
          value: createTwizzViewModel,
        ),
        ChangeNotifierProvider.value(value: newsFeedViewModel),
        ChangeNotifierProvider.value(value: profileViewModel),
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
      initialRoute: RouteNames.authCheck,
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
