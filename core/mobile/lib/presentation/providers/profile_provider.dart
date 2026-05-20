import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/user_repository.dart';

/// Profile state class
class ProfileState {
  final bool isLoading;
  final String? error;
  final UserProfile? profile;
  final UserAvatar? avatar;
  final bool isSaving;
  final bool isUploadingAvatar;
  final double uploadProgress;

  const ProfileState({
    this.isLoading = false,
    this.error,
    this.profile,
    this.avatar,
    this.isSaving = false,
    this.isUploadingAvatar = false,
    this.uploadProgress = 0,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? error,
    UserProfile? profile,
    UserAvatar? avatar,
    bool? isSaving,
    bool? isUploadingAvatar,
    double? uploadProgress,
    bool clearError = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      profile: profile ?? this.profile,
      avatar: avatar ?? this.avatar,
      isSaving: isSaving ?? this.isSaving,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}

/// Profile state notifier for managing user profile
class ProfileNotifier extends StateNotifier<ProfileState> {
  final UserRepository _userRepository;

  ProfileNotifier(this._userRepository) : super(const ProfileState());

  /// Load user profile and avatar
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Fetch profile
    final profileResult = await _userRepository.getProfile();

    await profileResult.fold(
      (failure) async {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (profile) async {
        // Fetch avatar after profile is loaded
        final avatarResult = await _userRepository.getAvatar();

        avatarResult.fold(
          (failure) {
            state = state.copyWith(
              isLoading: false,
              profile: profile,
              // Avatar error is non-critical, don't show as main error
            );
          },
          (avatar) {
            state = state.copyWith(
              isLoading: false,
              profile: profile,
              avatar: avatar,
            );
          },
        );
      },
    );
  }

  /// Update user profile
  Future<bool> updateProfile({String? name, String? email}) async {
    // Validate at least one field is provided
    if (name == null && email == null) {
      state = state.copyWith(error: 'At least one field must be provided');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    final result = await _userRepository.updateProfile(
      UpdateProfileRequest(name: name, email: email),
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSaving: false,
          error: failure.message,
        );
        return false;
      },
      (profile) {
        // Update avatar initials if name changed
        UserAvatar? newAvatar = state.avatar;
        if (name != null && name.isNotEmpty) {
          final nameParts = name.trim().split(RegExp(r'\s+'));
          String initials;
          if (nameParts.length > 1) {
            initials = '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'
                .toUpperCase();
          } else {
            initials = name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
          }
          newAvatar = UserAvatar(url: state.avatar?.url, initials: initials);
        }

        state = state.copyWith(
          isSaving: false,
          profile: profile,
          avatar: newAvatar,
        );
        return true;
      },
    );
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh profile data
  Future<void> refresh() async {
    await loadProfile();
  }

  /// Upload avatar
  Future<bool> uploadAvatar(File file) async {
    state = state.copyWith(
      isUploadingAvatar: true,
      uploadProgress: 0,
      clearError: true,
    );

    final result = await _userRepository.uploadAvatar(
      file,
      onProgress: (sent, total) {
        final progress = (sent / total) * 100;
        state = state.copyWith(uploadProgress: progress);
      },
    );

    return result.fold(
      (failure) {
        state = state.copyWith(
          isUploadingAvatar: false,
          uploadProgress: 0,
          error: failure.message,
        );
        return false;
      },
      (avatarUrl) {
        // Update avatar with new URL
        state = state.copyWith(
          isUploadingAvatar: false,
          uploadProgress: 0,
          avatar: UserAvatar(
            url: avatarUrl,
            initials: state.avatar?.initials ?? 'U',
          ),
        );
        return true;
      },
    );
  }

  /// Delete avatar
  Future<bool> deleteAvatar() async {
    state = state.copyWith(isSaving: true, clearError: true);

    final result = await _userRepository.deleteAvatar();

    return result.fold(
      (failure) {
        state = state.copyWith(
          isSaving: false,
          error: failure.message,
        );
        return false;
      },
      (_) {
        // Update avatar to remove URL
        state = state.copyWith(
          isSaving: false,
          avatar: UserAvatar(
            url: null,
            initials: state.avatar?.initials ?? 'U',
          ),
        );
        return true;
      },
    );
  }
}

/// Profile provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return ProfileNotifier(userRepository);
});
