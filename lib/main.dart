import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:twizzy_app/viewmodels/auth/change_password_viewmodel.dart';
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
import 'services/twizz_service/twizz_sync_service.dart';
import 'viewmodels/auth/auth_viewmodel.dart';
import 'viewmodels/twizz/create_twizz_viewmodel.dart';
import 'viewmodels/newsfeed/newsfeed_viewmodel.dart';
import 'viewmodels/profile/profile_viewmodel.dart';
import 'viewmodels/profile/edit_profile_viewmodel.dart';
import 'viewmodels/theme/theme_viewmodel.dart';
import 'viewmodels/search/search_viewmodel.dart';
import 'viewmodels/main/main_viewmodel.dart';

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
  final twizzSyncService = TwizzSyncService();

  // Initialize view models
  final authViewModel = AuthViewModel(authService);
  final createTwizzViewModel = CreateTwizzViewModel(
    twizzService,
    searchService,
    twizzSyncService,
  );
  final newsFeedViewModel = NewsFeedViewModel(
    twizzService,
    likeService,
    bookmarkService,
    twizzSyncService,
  );
  final profileViewModel = ProfileViewModel(
    twizzService,
    likeService,
    bookmarkService,
    twizzSyncService,
  );
  final editProfileViewModel = EditProfileViewModel(
    authService,
    twizzService,
  );
  final changePasswordViewModel = ChangePasswordViewModel(
    authService,
  );
  final themeViewModel = ThemeViewModel(storageService);
  final mainViewModel = MainViewModel();
  final searchViewModel = SearchViewModel(
    searchService,
    authService,
    likeService,
    bookmarkService,
    twizzService,
    twizzSyncService,
  );

  // Initialize Google Auth Service
  // Web Client ID (dùng cho serverClientId để lấy idToken) - lấy từ env
  final googleWebClientId = dotenv.get('GOOGLE_WEB_CLIENT_ID');
  GoogleAuthService().initialize(webClientId: googleWebClientId);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: tokenStorage),
        Provider.value(value: authService),
        Provider.value(value: twizzService),
        Provider.value(value: searchService),
        Provider.value(value: likeService),
        Provider.value(value: bookmarkService),
        Provider.value(value: twizzSyncService),
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProvider.value(
          value: createTwizzViewModel,
        ),
        ChangeNotifierProvider.value(value: newsFeedViewModel),
        ChangeNotifierProvider.value(value: profileViewModel),
        ChangeNotifierProvider.value(
          value: editProfileViewModel,
        ),
        ChangeNotifierProvider.value(
          value: changePasswordViewModel,
        ),
        ChangeNotifierProvider.value(value: searchViewModel),
        ChangeNotifierProvider.value(value: themeViewModel),
        ChangeNotifierProvider.value(value: mainViewModel),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeViewModel = Provider.of<ThemeViewModel>(context);

    return MaterialApp(
      title: 'Twizzy',
      // Theme tự động theo theme của thiết bị
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          themeViewModel
              .themeMode, // Tự động theo theme của viewmodel
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
