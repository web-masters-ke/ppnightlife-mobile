import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'http://18.218.205.73:4000/api/v1';

  late final Dio _dio;
  final _storage = StorageService();
  bool _refreshing = false;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && !_refreshing) {
          _refreshing = true;
          try {
            final refresh = await _storage.getRefreshToken();
            if (refresh != null) {
              final res = await _dio.post('/auth/refresh', data: {'refreshToken': refresh});
              final newToken = res.data['accessToken'];
              await _storage.saveAccessToken(newToken);
              error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
              final retry = await _dio.fetch(error.requestOptions);
              _refreshing = false;
              return handler.resolve(retry);
            }
          } catch (_) {}
          _refreshing = false;
          await _storage.clearAll();
        }
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  // ── Auth ──────────────────────────────────────────────────────────────────
  Future<Response> login(String emailOrPhone, String password) =>
      _dio.post('/auth/login', data: {'phone_or_email': emailOrPhone, 'password': password});

  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);

  Future<Response> validateSession() => _dio.get('/auth/validate');

  Future<Response> logout() => _dio.post('/auth/logout');

  // ── Users ─────────────────────────────────────────────────────────────────
  Future<Response> getMe() => _dio.get('/users/me');
  Future<Response> getUser(String id) => _dio.get('/users/$id');
  Future<Response> updateUser(String id, Map<String, dynamic> data) => _dio.put('/users/$id', data: data);
  Future<Response> uploadProfilePhoto(String id, List<int> bytes, String filename, String mimeType) {
    final formData = FormData.fromMap({
      'photo': MultipartFile.fromBytes(bytes, filename: filename, contentType: DioMediaType.parse(mimeType)),
    });
    return _dio.post('/users/$id/photo', data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));
  }
  Future<Response> followUser(String id) => _dio.post('/users/$id/follow');
  Future<Response> unfollowUser(String id) => _dio.delete('/users/$id/follow');
  Future<Response> getFollowStatus(String id) => _dio.get('/users/$id/follow-status');
  Future<Response> getFollowers(String id) => _dio.get('/users/$id/followers');
  Future<Response> getFollowing(String id) => _dio.get('/users/$id/following');
  Future<Response> searchUsers({String q = '', int limit = 20, int offset = 0}) =>
      _dio.get('/users/search', queryParameters: {'q': q, 'limit': limit, 'offset': offset});
  Future<Response> getUserPosts(String id, {int limit = 20, int offset = 0}) =>
      _dio.get('/users/$id/posts', queryParameters: {'limit': limit, 'offset': offset});

  // ── Feed ──────────────────────────────────────────────────────────────────
  Future<Response> getFeed({int page = 1, int limit = 20}) =>
      _dio.get('/feed', queryParameters: {'page': page, 'limit': limit});
  Future<Response> getPost(String postId) => _dio.get('/feed/$postId');
  Future<Response> createPost(Map<String, dynamic> data) => _dio.post('/feed/post', data: data);
  Future<Response> reactPost(String postId, String reactionType) =>
      _dio.post('/feed/$postId/react', data: {'reaction': reactionType});
  Future<Response> getComments(String postId) => _dio.get('/feed/$postId/comments');
  Future<Response> addComment(String postId, String content) =>
      _dio.post('/feed/$postId/comment', data: {'content': content});
  Future<Response> deletePost(String postId) => _dio.delete('/feed/$postId');
  Future<Response> getStatuses() => _dio.get('/feed/statuses');
  Future<Response> viewStatus(String postId) => _dio.post('/feed/statuses/$postId/view');
  Future<Response> getStatusViewers(String postId) => _dio.get('/feed/statuses/$postId/viewers');
  Future<Response> uploadPostMedia(List<int> bytes, String filename, String mimeType) {
    final formData = FormData.fromMap({
      'media': MultipartFile.fromBytes(bytes, filename: filename, contentType: DioMediaType.parse(mimeType)),
    });
    return _dio.post('/feed/upload', data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));
  }

  // ── Venues ────────────────────────────────────────────────────────────────
  Future<Response> getVenues({String? area, String? search, int limit = 20, int offset = 0}) =>
      _dio.get('/venues', queryParameters: {
        if (area != null) 'area': area,
        if (search != null && search.isNotEmpty) 'search': search,
        'limit': limit,
        'offset': offset,
      });
  Future<Response> getVenue(String id) => _dio.get('/venues/$id');
  Future<Response> getNearbyVenues(double lat, double lng, {double radius = 5000}) =>
      _dio.get('/venues/nearby', queryParameters: {'lat': lat, 'lng': lng, 'radius': radius});
  Future<Response> createVenue(Map<String, dynamic> data) => _dio.post('/venues', data: data);
  Future<Response> updateVenue(String id, Map<String, dynamic> data) =>
      _dio.put('/venues/$id', data: data);
  Future<Response> getOwnedVenues() => _dio.get('/venues/mine');
  Future<Response> getVenueAnalytics(String venueId) => _dio.get('/venues/$venueId/analytics');

  // ── Check-in ──────────────────────────────────────────────────────────────
  Future<Response> getCheckinStatus() => _dio.get('/checkin/status');
  Future<Response> checkIn(String venueId, {
    String method = 'app',
    double? latitude,
    double? longitude,
  }) => _dio.post('/checkin', data: {
        'venueId': venueId,
        'method': method,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      });
  Future<Response> checkOut(String venueId) =>
      _dio.post('/checkin/out', data: {'venueId': venueId});
  Future<Response> getCheckinHistory() => _dio.get('/checkin/history');
  Future<Response> getVenueCheckins(String venueId, {String filter = 'today'}) =>
      _dio.get('/checkin/venue/$venueId', queryParameters: {'filter': filter});
  Future<Response> getGuestFrequency(String venueId) =>
      _dio.get('/checkin/venue/$venueId/frequency');

  // ── DJ ────────────────────────────────────────────────────────────────────
  Future<Response> getLiveDJs() => _dio.get('/dj/live');
  Future<Response> getDJQueue({String? venueId}) =>
      _dio.get('/dj/queue', queryParameters: venueId != null ? {'venueId': venueId} : null);
  Future<Response> requestSong(Map<String, dynamic> data) => _dio.post('/dj/request', data: data);
  Future<Response> voteSongRequest(String id, String voteType) =>
      _dio.post('/dj/request/$id/vote', data: {'voteType': voteType});
  Future<Response> tipDJ(String requestId, int amount) =>
      _dio.post('/dj/request/$requestId/tip', data: {'amount': amount});
  Future<Response> goLive(String venueId) => _dio.post('/dj/go-live', data: {'venueId': venueId});
  Future<Response> endSet() => _dio.post('/dj/end-set');
  Future<Response> respondToRequest(String id, String action) =>
      _dio.post('/dj/respond', data: {'requestId': id, 'action': action});
  Future<Response> markPlaying(String id) => _dio.post('/dj/request/$id/play');
  Future<Response> markComplete(String id) => _dio.post('/dj/request/$id/complete');
  Future<Response> removeRequest(String id) => _dio.delete('/dj/request/$id');
  Future<Response> reorderQueue(List<String> ids) =>
      _dio.patch('/dj/queue/reorder', data: {'order': ids});
  Future<Response> getDJEarnings() => _dio.get('/dj/earnings');
  Future<Response> getDJPlaylist() => _dio.get('/dj/playlist');
  Future<Response> deleteDJTrack(String id) => _dio.delete('/dj/playlist/$id');
  Future<Response> selfAddSong(Map<String, dynamic> data) => _dio.post('/dj/self-add', data: data);
  Future<Response> getDJProfile() => _dio.get('/dj/profile');

  // ── Wallet ────────────────────────────────────────────────────────────────
  Future<Response> getWalletBalance() => _dio.get('/wallet/balance');
  Future<Response> topUpWallet(Map<String, dynamic> data) => _dio.post('/wallet/topup', data: data);
  Future<Response> confirmTopUp(String transactionId) => _dio.post('/wallet/topup/$transactionId/confirm');
  Future<Response> sendMoney(Map<String, dynamic> data) => _dio.post('/wallet/pay', data: data);
  Future<Response> withdraw(Map<String, dynamic> data) => _dio.post('/wallet/withdraw', data: data);
  Future<Response> getTransactionHistory({String? type, String? startDate, String? endDate, int limit = 50, int offset = 0}) =>
      _dio.get('/wallet/history', queryParameters: {
        if (type != null) 'type': type,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        'limit': limit,
        'offset': offset,
      });
  Future<Response> getTopTippers({int limit = 5}) =>
      _dio.get('/wallet/top-tippers', queryParameters: {'limit': limit});

  // ── Chat ──────────────────────────────────────────────────────────────────
  Future<Response> getChatRooms() => _dio.get('/chat/rooms');
  Future<Response> openChat(String targetUserId) =>
      _dio.post('/chat/rooms', data: {'targetUserId': targetUserId});
  Future<Response> getMessages(String roomId, {int limit = 50, String? before}) =>
      _dio.get('/chat/rooms/$roomId/messages', queryParameters: {
        'limit': limit,
        if (before != null) 'before': before,
      });
  Future<Response> sendMessage(String roomId, {String? content, Map<String, dynamic>? attachment}) =>
      _dio.post('/chat/rooms/$roomId/messages', data: {
        if (content != null) 'content': content,
        if (attachment != null) 'attachment': attachment,
      });
  Future<Response> getUnreadCount() => _dio.get('/chat/unread');
  Future<Response> uploadChatFile(List<int> bytes, String filename, String mimeType) {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename, contentType: DioMediaType.parse(mimeType)),
    });
    return _dio.post('/chat/upload', data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));
  }
  Future<Response> uploadVoiceNote(List<int> bytes, String mimeType) {
    final formData = FormData.fromMap({
      'voice': MultipartFile.fromBytes(bytes, filename: 'voice-note.webm', contentType: DioMediaType.parse(mimeType)),
    });
    return _dio.post('/chat/voice', data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<Response> getNotifications({int limit = 30, int offset = 0}) =>
      _dio.get('/notifications', queryParameters: {'limit': limit, 'offset': offset});
  Future<Response> markNotificationRead(String id) => _dio.post('/notifications/$id/read');
  Future<Response> markAllNotificationsRead() => _dio.post('/notifications/read-all');
  Future<Response> deleteNotification(String id) => _dio.delete('/notifications/$id');
  Future<Response> getUnreadNotificationsCount() => _dio.get('/notifications/unread-count');

  // ── Merchant (Venue Owner) ────────────────────────────────────────────────
  Future<Response> getMerchantVenues() => _dio.get('/venues/mine');
  Future<Response> getMerchantCheckins(String venueId, {String filter = 'today'}) =>
      _dio.get('/checkin/venue/$venueId', queryParameters: {'filter': filter});
  Future<Response> getMerchantDJBookings(String venueId) => _dio.get('/dj/bookings/$venueId');
  Future<Response> getVenueOffers(String venueId) => _dio.get('/venues/$venueId/offers');
  Future<Response> createVenueOffer(String venueId, Map<String, dynamic> data) =>
      _dio.post('/venues/$venueId/offers', data: data);
  Future<Response> updateVenueOffer(String venueId, String offerId, Map<String, dynamic> data) =>
      _dio.put('/venues/$venueId/offers/$offerId', data: data);
  Future<Response> deleteVenueOffer(String venueId, String offerId) =>
      _dio.delete('/venues/$venueId/offers/$offerId');

  // ── Advertiser ────────────────────────────────────────────────────────────
  Future<Response> getAdvertiserOverview() => _dio.get('/advertiser/overview');
  Future<Response> getCampaigns() => _dio.get('/advertiser/campaigns');
  Future<Response> createCampaign(Map<String, dynamic> data) =>
      _dio.post('/advertiser/campaigns', data: data);
  Future<Response> getCampaign(String id) => _dio.get('/advertiser/campaigns/$id');
  Future<Response> updateCampaign(String id, Map<String, dynamic> data) =>
      _dio.put('/advertiser/campaigns/$id', data: data);
  Future<Response> pauseCampaign(String id) => _dio.post('/advertiser/campaigns/$id/pause');
  Future<Response> resumeCampaign(String id) => _dio.post('/advertiser/campaigns/$id/resume');
  Future<Response> getCampaignAnalytics(String id) =>
      _dio.get('/advertiser/campaigns/$id/analytics');
  Future<Response> getTargetingOptions() => _dio.get('/advertiser/targeting/options');
  Future<Response> getAdvertiserBilling() => _dio.get('/advertiser/billing');
  Future<Response> uploadCampaignMedia(List<int> bytes, String filename, String mimeType) {
    final formData = FormData.fromMap({
      'media': MultipartFile.fromBytes(bytes, filename: filename, contentType: DioMediaType.parse(mimeType)),
    });
    return _dio.post('/advertiser/campaigns/upload', data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}));
  }
}
