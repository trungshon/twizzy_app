import 'package:flutter/foundation.dart';
import '../../models/auth/auth_models.dart';
import '../../services/auth_service/auth_service.dart';
import '../../services/search_service/search_service.dart';

class NewMessageViewModel extends ChangeNotifier {
  final AuthService _authService;
  final SearchService _searchService;

  NewMessageViewModel({
    required AuthService authService,
    required SearchService searchService,
  }) : _authService = authService,
       _searchService = searchService;

  List<User> _following = [];
  List<User> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<User> get following => _following;
  List<User> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  List<User> get displayUsers =>
      _searchQuery.isEmpty ? _following : _searchResults;

  Future<void> loadFollowing(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _following = await _authService.getFollowing(
        userId,
        limit: 100,
      );
    } catch (e) {
      debugPrint('Error loading following: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchUsers(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _searchService.searchUsers(
        content: query,
        limit: 20,
        followOnly: true,
      );
      _searchResults =
          response.users
              .map(
                (u) => User(
                  id: u.id,
                  name: u.name,
                  email: '', // Not returned in search
                  dateOfBirth: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  verify:
                      u.isVerified ? 'Verified' : 'Unverified',
                  username: u.username,
                  avatar:
                      (u.avatar != null && u.avatar!.isNotEmpty)
                          ? u.avatar
                          : null,
                ),
              )
              .toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  void clear() {
    _following = [];
    _searchResults = [];
    _isLoading = false;
    _searchQuery = '';
    notifyListeners();
  }
}
