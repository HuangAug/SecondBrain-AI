import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';

class AuthState {
  const AuthState({this.isAuthenticated = false, this.nickname, this.userId});

  final bool isAuthenticated;
  final String? nickname;
  final String? userId;

  AuthState copyWith({bool? isAuthenticated, String? nickname, String? userId}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      nickname: nickname ?? this.nickname,
      userId: userId ?? this.userId,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage, this._api) : super(const AuthState()) {
    _loadSession();
  }

  final SecureStorageService _storage;
  final ApiClient _api;

  Future<void> _loadSession() async {
    final loggedIn = await _storage.isLoggedIn();
    if (loggedIn) {
      final nickname = await _storage.read(AppConstants.nicknameKey);
      final userId = await _storage.read(AppConstants.userIdKey);
      state = AuthState(isAuthenticated: true, nickname: nickname, userId: userId);
    }
  }

  Future<void> sendCode(String phone) async {
    await _api.dio.post('/auth/send-code', data: {'phone': phone});
  }

  Future<void> verify(String phone, String code) async {
    final resp = await _api.dio.post('/auth/verify', data: {'phone': phone, 'code': code});
    final data = resp.data as Map<String, dynamic>;
    await _storage.write(AppConstants.tokenKey, data['access_token'] as String);
    await _storage.write(AppConstants.userIdKey, data['user_id'] as String);
    await _storage.write(AppConstants.nicknameKey, data['nickname'] as String);
    state = AuthState(
      isAuthenticated: true,
      nickname: data['nickname'] as String,
      userId: data['user_id'] as String,
    );
  }

  Future<void> logout() async {
    await _storage.clearAuth();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(secureStorageProvider), ref.watch(apiClientProvider));
});
