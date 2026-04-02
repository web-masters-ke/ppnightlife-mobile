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
      final user = UserModel.fromJson(data['user'] ?? data);
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
      final user = UserModel.fromJson(body['user'] ?? body);
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
    if (e is Exception) {
      final str = e.toString();
      if (str.contains('401') || str.contains('Unauthorized')) return 'Invalid email or password';
      if (str.contains('409') || str.contains('already')) return 'Account already exists';
      if (str.contains('SocketException') || str.contains('Connection')) return 'No internet connection';
    }
    return 'Something went wrong. Try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
