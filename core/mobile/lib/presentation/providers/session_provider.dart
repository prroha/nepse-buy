import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/session_repository.dart';

/// Session list state
class SessionsState {
  final bool isLoading;
  final String? error;
  final List<Session> sessions;
  final String? revokingSessionId;
  final bool isRevokingAll;

  const SessionsState({
    this.isLoading = false,
    this.error,
    this.sessions = const [],
    this.revokingSessionId,
    this.isRevokingAll = false,
  });

  SessionsState copyWith({
    bool? isLoading,
    String? error,
    List<Session>? sessions,
    String? revokingSessionId,
    bool? isRevokingAll,
    bool clearError = false,
    bool clearRevokingSessionId = false,
  }) {
    return SessionsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      sessions: sessions ?? this.sessions,
      revokingSessionId: clearRevokingSessionId
          ? null
          : (revokingSessionId ?? this.revokingSessionId),
      isRevokingAll: isRevokingAll ?? this.isRevokingAll,
    );
  }

  /// Count of non-current sessions
  int get otherSessionsCount => sessions.where((s) => !s.isCurrent).length;
}

/// Session state notifier for managing user sessions
class SessionsNotifier extends StateNotifier<SessionsState> {
  final SessionRepository _sessionRepository;

  SessionsNotifier(this._sessionRepository) : super(const SessionsState());

  /// Load all sessions
  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _sessionRepository.getSessions();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (sessions) {
        state = state.copyWith(
          isLoading: false,
          sessions: sessions,
        );
      },
    );
  }

  /// Revoke a specific session
  Future<bool> revokeSession(String sessionId) async {
    state = state.copyWith(revokingSessionId: sessionId, clearError: true);

    final result = await _sessionRepository.revokeSession(sessionId);

    return result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message,
          clearRevokingSessionId: true,
        );
        return false;
      },
      (_) {
        // Remove session from list
        final updatedSessions =
            state.sessions.where((s) => s.id != sessionId).toList();
        state = state.copyWith(
          sessions: updatedSessions,
          clearRevokingSessionId: true,
        );
        return true;
      },
    );
  }

  /// Revoke all other sessions
  Future<int> revokeAllOtherSessions() async {
    state = state.copyWith(isRevokingAll: true, clearError: true);

    final result = await _sessionRepository.revokeAllOtherSessions();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isRevokingAll: false,
          error: failure.message,
        );
        return 0;
      },
      (response) {
        // Keep only current session
        final updatedSessions =
            state.sessions.where((s) => s.isCurrent).toList();
        state = state.copyWith(
          isRevokingAll: false,
          sessions: updatedSessions,
        );
        return response.revokedCount;
      },
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh sessions
  Future<void> refresh() async {
    await loadSessions();
  }
}

/// Sessions provider
final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, SessionsState>((ref) {
  final sessionRepository = ref.watch(sessionRepositoryProvider);
  return SessionsNotifier(sessionRepository);
});
