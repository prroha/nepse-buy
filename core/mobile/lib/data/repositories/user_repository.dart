import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../../presentation/providers/auth_provider.dart';
import 'base_repository.dart';

/// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref: ref);
});

/// User profile model
class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final profile = data['profile'] as Map<String, dynamic>? ?? data;

    return UserProfile(
      id: profile['id'] as String,
      email: profile['email'] as String,
      name: profile['name'] as String?,
      role: profile['role'] as String,
      isActive: profile['isActive'] as bool,
      createdAt: DateTime.parse(profile['createdAt'] as String),
      updatedAt: DateTime.parse(profile['updatedAt'] as String),
    );
  }
}

/// User avatar model
class UserAvatar {
  final String? url;
  final String initials;

  const UserAvatar({
    this.url,
    required this.initials,
  });

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final avatar = data['avatar'] as Map<String, dynamic>? ?? data;

    return UserAvatar(
      url: avatar['url'] as String?,
      initials: avatar['initials'] as String,
    );
  }
}

/// Update profile request model
class UpdateProfileRequest {
  final String? name;
  final String? email;

  const UpdateProfileRequest({this.name, this.email});

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (email != null) 'email': email,
    };
  }
}

/// User repository interface
abstract class UserRepository {
  /// Get current user profile
  Future<Either<Failure, UserProfile>> getProfile();

  /// Update current user profile
  Future<Either<Failure, UserProfile>> updateProfile(UpdateProfileRequest request);

  /// Get current user avatar
  Future<Either<Failure, UserAvatar>> getAvatar();

  /// Upload user avatar
  Future<Either<Failure, String>> uploadAvatar(
    File file, {
    void Function(int sent, int total)? onProgress,
  });

  /// Delete user avatar
  Future<Either<Failure, void>> deleteAvatar();
}

/// User repository implementation.
///
/// Post-v0.9 pivot: the REST backend is gone. Reads synthesize a profile
/// from local auth state (see `auth_provider.dart`) so the Profile screen
/// loads instantly without a network call. Writes are accepted optimistically
/// but not persisted anywhere yet — the local "user" is just the anon shell
/// initialised by `AuthNotifier`. Avatar upload/delete return a clear failure
/// since there's no storage backend to talk to.
class UserRepositoryImpl with BaseRepository implements UserRepository {
  final Ref _ref;

  UserRepositoryImpl({required Ref ref}) : _ref = ref;

  UserProfile _synthesizeProfile({String? overrideName, String? overrideEmail}) {
    final auth = _ref.read(authProvider);
    final now = DateTime.now();
    return UserProfile(
      id: auth.userId ?? 'local-user',
      email: overrideEmail ?? auth.email ?? 'anon@nepse-buy.local',
      name: overrideName,
      role: auth.role ?? 'USER',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Either<Failure, UserProfile>> getProfile() async {
    return Right(_synthesizeProfile());
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile(
    UpdateProfileRequest request,
  ) async {
    return Right(_synthesizeProfile(
      overrideName: request.name,
      overrideEmail: request.email,
    ));
  }

  @override
  Future<Either<Failure, UserAvatar>> getAvatar() async {
    final auth = _ref.read(authProvider);
    final source = auth.email ?? '';
    final initials = source.isNotEmpty ? source.substring(0, 1).toUpperCase() : 'U';
    return Right(UserAvatar(url: null, initials: initials));
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    return const Left(
      NetworkFailure('Avatar upload is unavailable in this local-only build.'),
    );
  }

  @override
  Future<Either<Failure, void>> deleteAvatar() async {
    return const Left(
      NetworkFailure('Avatar removal is unavailable in this local-only build.'),
    );
  }
}
