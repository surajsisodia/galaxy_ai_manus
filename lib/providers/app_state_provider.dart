import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppState {
  const AppState({this.isInitialized = false});

  final bool isInitialized;

  AppState copyWith({bool? isInitialized}) {
    return AppState(isInitialized: isInitialized ?? this.isInitialized);
  }
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    return const AppState();
  }

  Future<void> initialize() async {
    if (state.isInitialized) return;
    await Future<void>.delayed(const Duration(seconds: 1));
    state = state.copyWith(isInitialized: true);
  }
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);
