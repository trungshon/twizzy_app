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
import 'services/socket_service/socket_service.dart';
import 'services/chat_service/chat_service.dart';
import 'services/notification_service/notification_service.dart';
import 'services/local_notification_service/local_notification_service.dart';
import 'services/report_service/report_service.dart';
import 'viewmodels/auth/auth_viewmodel.dart';
import 'viewmodels/notification/notification_viewmodel.dart';
import 'viewmodels/twizz/create_twizz_viewmodel.dart';
import 'viewmodels/newsfeed/newsfeed_viewmodel.dart';
import 'viewmodels/profile/profile_viewmodel.dart';
import 'viewmodels/profile/edit_profile_viewmodel.dart';
import 'viewmodels/theme/theme_viewmodel.dart';
import 'viewmodels/search/search_viewmodel.dart';
import 'viewmodels/main/main_viewmodel.dart';
import 'viewmodels/chat/chat_viewmodel.dart';
import 'viewmodels/chat/new_message_viewmodel.dart';
import 'viewmodels/report/report_viewmodel.dart';

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
  final socketService = SocketService();
  final chatService = ChatService(apiClient);
  final notificationService = NotificationService(apiClient);
  final reportService = ReportService(apiClient);

  // Auto connect socket if already logged in
  final initialAccessToken = await authService.getAccessToken();
  if (initialAccessToken != null) {
    socketService.connect(initialAccessToken);
  }

  // Initialize local notification service
  final localNotificationService = LocalNotificationService();
  await localNotificationService.initialize();

  // Initialize view models
  final authViewModel = AuthViewModel(
    authService,
    socketService,
  );
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
  final chatViewModel = ChatViewModel(
    socketService,
    chatService,
    localNotificationService,
  );
  final notificationViewModel = NotificationViewModel(
    notificationService,
    socketService,
    localNotificationService,
  );
  final reportViewModel = ReportViewModel(reportService);

  // Link ApiClient callbacks for automatic socket reconnection and logout
  apiClient.onTokenRefreshed = (token) {
    debugPrint('Token refreshed, reconnecting socket...');
    socketService.connect(token);
  };

  apiClient.onRefreshTokenFailed = () {
    debugPrint('Refresh token failed, logging out...');
    authViewModel.logout();
  };

  final newMessageViewModel = NewMessageViewModel(
    authService: authService,
    searchService: searchService,
  );

  // Link global data clearing to logout
  authViewModel.onLogout = () {
    debugPrint('Global clear triggered from logout');
    createTwizzViewModel.clear();
    newsFeedViewModel.clear();
    profileViewModel.clear();
    editProfileViewModel.clear();
    searchViewModel.clear();
    chatViewModel.clear();
    newMessageViewModel.clear();
    changePasswordViewModel.clear();
    reportViewModel.clear();
    notificationViewModel.loadNotifications(
      refresh: true,
    ); // Reload or clear notifications
  };

  // Link Socket auth errors to token refresh
  socketService.onAuthError = () {
    debugPrint(
      'Socket auth error detected, refreshing token...',
    );
    authViewModel.refreshToken();
  };

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
        Provider.value(value: socketService),
        Provider.value(value: chatService),
        Provider.value(value: reportService),
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
        ChangeNotifierProvider.value(value: chatViewModel),
        ChangeNotifierProvider.value(value: newMessageViewModel),
        ChangeNotifierProvider.value(
          value: notificationViewModel,
        ),
        ChangeNotifierProvider.value(value: reportViewModel),
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
      navigatorKey: navigatorKey,
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
