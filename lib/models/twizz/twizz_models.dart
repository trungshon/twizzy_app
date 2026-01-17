import '../auth/auth_models.dart';
import '../../core/utils/media_url_helper.dart';

/// TwizzType enum
/// Các loại twizz: bài viết gốc, retwizz, comment, quote
enum TwizzType {
  twizz, // 0
  retwizz, // 1
  comment, // 2
  quoteTwizz, // 3
}

/// TwizzAudience enum
/// Đối tượng có thể xem twizz: mọi người hoặc twizz circle
enum TwizzAudience {
  everyone, // 0
  twizzCircle, // 1
}

/// MediaType enum
/// Loại media: ảnh hoặc video
enum MediaType {
  image, // 0
  video, // 1
}

/// Media class
/// Thông tin media (ảnh/video)
class Media {
  final String url;
  final MediaType type;

  Media({required this.url, required this.type});

  factory Media.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url'] as String;
    return Media(
      url: MediaUrlHelper.normalizeUrl(rawUrl),
      type: MediaType.values[json['type'] as int],
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'type': type.index};
  }
}

/// Create Twizz Request
class CreateTwizzRequest {
  final TwizzType type;
  final TwizzAudience audience;
  final String content;
  final String? parentId;
  final List<String> hashtags;
  final List<String> mentions; // User IDs
  final List<Media> medias;

  CreateTwizzRequest({
    this.type = TwizzType.twizz,
    required this.audience,
    required this.content,
    this.parentId,
    this.hashtags = const [],
    this.mentions = const [],
    this.medias = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'audience': audience.index,
      'content': content,
      'parent_id': parentId,
      'hashtags': hashtags,
      'mentions': mentions,
      'medias': medias.map((m) => m.toJson()).toList(),
    };
  }
}

/// Twizz Model
class Twizz {
  final String id;
  final String userId;
  final TwizzType type;
  final TwizzAudience audience;
  final String content;
  final String? parentId;
  final List<dynamic> hashtags;
  final List<dynamic> mentions;
  final List<Media> medias;
  final int guestViews;
  final int userViews;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final int? bookmarks;
  final int? likes;
  final int? retwizzCount;
  final int? commentCount;
  final int? quoteCount;
  final bool isLiked;
  final bool isBookmarked;

  Twizz({
    required this.id,
    required this.userId,
    required this.type,
    required this.audience,
    required this.content,
    this.parentId,
    this.hashtags = const [],
    this.mentions = const [],
    this.medias = const [],
    this.guestViews = 0,
    this.userViews = 0,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.bookmarks,
    this.likes,
    this.retwizzCount,
    this.commentCount,
    this.quoteCount,
    this.isLiked = false,
    this.isBookmarked = false,
  });

  factory Twizz.fromJson(Map<String, dynamic> json) {
    return Twizz(
      id: json['_id'] as String,
      userId: json['user_id'] as String,
      type: TwizzType.values[json['type'] as int],
      audience: TwizzAudience.values[json['audience'] as int],
      content: json['content'] as String,
      parentId: json['parent_id'] as String?,
      hashtags: json['hashtags'] as List<dynamic>? ?? [],
      mentions: json['mentions'] as List<dynamic>? ?? [],
      medias:
          (json['medias'] as List<dynamic>?)
              ?.map(
                (m) => Media.fromJson(m as Map<String, dynamic>),
              )
              .toList() ??
          [],
      guestViews: json['guest_views'] as int? ?? 0,
      userViews: json['user_views'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      user:
          json['user'] != null
              ? User.fromJson(
                json['user'] as Map<String, dynamic>,
              )
              : null,
      bookmarks: json['bookmarks'] as int?,
      likes: json['likes'] as int?,
      retwizzCount: json['retwizz_count'] as int?,
      commentCount: json['comment_count'] as int?,
      quoteCount: json['quote_count'] as int?,
      isLiked: json['is_liked'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
    );
  }

  /// Create a copy with updated like/bookmark status
  Twizz copyWith({
    bool? isLiked,
    bool? isBookmarked,
    int? likes,
    int? bookmarks,
  }) {
    return Twizz(
      id: id,
      userId: userId,
      type: type,
      audience: audience,
      content: content,
      parentId: parentId,
      hashtags: hashtags,
      mentions: mentions,
      medias: medias,
      guestViews: guestViews,
      userViews: userViews,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user,
      bookmarks: bookmarks ?? this.bookmarks,
      likes: likes ?? this.likes,
      retwizzCount: retwizzCount,
      commentCount: commentCount,
      quoteCount: quoteCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

/// Create Twizz Response
class CreateTwizzResponse {
  final String message;
  final Twizz result;

  CreateTwizzResponse({
    required this.message,
    required this.result,
  });

  factory CreateTwizzResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return CreateTwizzResponse(
      message: json['message'] as String,
      result: Twizz.fromJson(
        json['result'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Upload Media Response
class UploadMediaResponse {
  final String message;
  final List<Media> result;

  UploadMediaResponse({
    required this.message,
    required this.result,
  });

  factory UploadMediaResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return UploadMediaResponse(
      message: json['message'] as String,
      result:
          (json['result'] as List<dynamic>)
              .map(
                (m) => Media.fromJson(m as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

/// Search User Result (for mentions)
class SearchUserResult {
  final String id;
  final String name;
  final String username;
  final String? avatar;
  final bool isVerified;

  SearchUserResult({
    required this.id,
    required this.name,
    required this.username,
    this.avatar,
    this.isVerified = false,
  });

  factory SearchUserResult.fromJson(Map<String, dynamic> json) {
    return SearchUserResult(
      id: json['_id'] as String,
      name: json['name'] as String,
      username: json['username'] as String? ?? '',
      avatar: json['avatar'] as String?,
      isVerified: json['verify'] == 1,
    );
  }
}

/// Search Users Response
class SearchUsersResponse {
  final List<SearchUserResult> users;
  final int totalPage;
  final int limit;
  final int page;

  SearchUsersResponse({
    required this.users,
    this.totalPage = 0,
    this.limit = 10,
    this.page = 1,
  });

  factory SearchUsersResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final result = json['result'] as Map<String, dynamic>;
    return SearchUsersResponse(
      users:
          (result['users'] as List<dynamic>)
              .map(
                (u) => SearchUserResult.fromJson(
                  u as Map<String, dynamic>,
                ),
              )
              .toList(),
      totalPage: result['total_page'] as int? ?? 0,
      limit: result['limit'] as int? ?? 10,
      page: result['page'] as int? ?? 1,
    );
  }
}

/// NewFeeds Response
class NewFeedsResponse {
  final String message;
  final List<Twizz> twizzs;
  final int limit;
  final int page;
  final int totalPage;

  NewFeedsResponse({
    required this.message,
    required this.twizzs,
    required this.limit,
    required this.page,
    required this.totalPage,
  });

  factory NewFeedsResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>;
    return NewFeedsResponse(
      message: json['message'] as String? ?? '',
      twizzs:
          (result['twizzs'] as List<dynamic>)
              .map(
                (t) => Twizz.fromJson(t as Map<String, dynamic>),
              )
              .toList(),
      limit: result['limit'] as int? ?? 10,
      page: result['page'] as int? ?? 1,
      totalPage: result['total_page'] as int? ?? 0,
    );
  }
}
