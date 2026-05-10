import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;

  static const _noValue = Object();

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    Object? errorMessage = _noValue,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _noValue)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  Future<void> signIn({required String email, required String password}) async {
    _setLoading(true);
    state = state.copyWith(errorMessage: null);

    await Future<void>.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(isLoggedIn: true);
    _setLoading(false);
  }

  Future<void> signUp({required String email, required String password}) async {
    _setLoading(true);
    state = state.copyWith(errorMessage: null);

    await Future<void>.delayed(const Duration(milliseconds: 900));
    state = state.copyWith(isLoggedIn: true);
    _setLoading(false);
  }

  Future<void> signOut() async {
    _setLoading(true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(isLoggedIn: false);
    _setLoading(false);
  }

  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
