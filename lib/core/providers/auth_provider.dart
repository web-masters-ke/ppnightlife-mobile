import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({this.status = AuthStatus.unknown, this.user, this.error});

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    error: error,
  );

  bool get isLoggedIn => status == AuthStatus.authenticated && user != null;
  String get role => user?.role ?? '';
}

class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = StorageService();
  final _api = ApiService();

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.getAccessToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final res = await _api.getMe();
      if (res.statusCode == 200) {
        final body = res.data;
        final user = UserModel.fromJson(body['data'] ?? body['user'] ?? body);
        await _storage.saveUserId(user.userId);
        await _storage.saveUserRole(user.role);
        await _storage.saveUserName(user.name);
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        await _storage.clearAll();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      // No network — restore from local cache
      final id = await _storage.getUserId();
      final role = await _storage.getUserRole();
      final name = await _storage.getUserName();
      if (id != null && role != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: UserModel(userId: id, name: name ?? '', email: '', role: role),
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await _api.login(email, password);
      final data = res.data['data'] ?? res.data;
      await _storage.saveAccessToken(data['accessToken']);
      if (data['refreshToken'] != null) await _storage.saveRefreshToken(data['refreshToken']);
      // Fetch full profile from /users/me — login response only contains tokens + userRole
      final meRes = await _api.getMe();
      final meBody = meRes.data['data'] ?? meRes.data['user'] ?? meRes.data;
      final user = UserModel.fromJson(meBody);
      await _storage.saveUserId(user.userId);
      await _storage.saveUserRole(user.role);
      await _storage.saveUserName(user.name);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return null;
    } catch (e) {
      final msg = _errorMessage(e);
      state = state.copyWith(status: AuthStatus.unauthenticated, error: msg);
      return msg;
    }
  }

  Future<String?> register(Map<String, dynamic> data) async {
    try {
      final res = await _api.register(data);
      final body = res.data['data'] ?? res.data;
      await _storage.saveAccessToken(body['accessToken']);
      if (body['refreshToken'] != null) await _storage.saveRefreshToken(body['refreshToken']);
      // Fetch full profile from /users/me — register response only contains tokens
      final meRes = await _api.getMe();
      final meBody = meRes.data['data'] ?? meRes.data['user'] ?? meRes.data;
      final user = UserModel.fromJson(meBody);
      await _storage.saveUserId(user.userId);
      await _storage.saveUserRole(user.role);
      await _storage.saveUserName(user.name);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return null;
    } catch (e) {
      return _errorMessage(e);
    }
  }

  Future<void> logout() async {
    try { await _api.logout(); } catch (_) {}
    await _storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  String _errorMessage(dynamic e) {
    if (e is DioException) {
      // Network-level error (no connection, timeout)
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'No internet connection. Check your network and try again.';
      }
      // API returned an error response — extract the message
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['error']?['message'] as String? ??
            data['message'] as String?;
        if (msg != null && msg.isNotEmpty) return msg;
      }
      final status = e.response?.statusCode;
      if (status == 401) return 'Invalid email or password';
      if (status == 409) return 'Account already exists';
    }
    final str = e.toString();
    if (str.contains('SocketException') || str.contains('Connection refused')) {
      return 'Cannot reach server. Try again later.';
    }
    return 'Something went wrong. Try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
