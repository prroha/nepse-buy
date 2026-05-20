import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';
import 'base_repository.dart';

/// Search repository provider
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(dio: ref.watch(dioProvider));
});

/// Search type enum
enum SearchType { all, users }

/// User search result model
class UserSearchResult {
  final String id;
  final String email;
  final String? name;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  const UserSearchResult({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.trim().split(' ');
      if (parts.length > 1) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return name!.substring(0, name!.length > 1 ? 2 : 1).toUpperCase();
    }
    return email.substring(0, email.length > 1 ? 2 : 1).toUpperCase();
  }
}

/// Search results model
class SearchResults {
  final List<UserSearchResult>? users;
  final String query;
  final int totalResults;

  const SearchResults({
    this.users,
    required this.query,
    required this.totalResults,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    final results = data['results'] as Map<String, dynamic>? ?? data;

    List<UserSearchResult>? users;
    if (results['users'] != null) {
      users = (results['users'] as List<dynamic>)
          .map((u) => UserSearchResult.fromJson(u as Map<String, dynamic>))
          .toList();
    }

    return SearchResults(
      users: users,
      query: results['query'] as String? ?? '',
      totalResults: results['totalResults'] as int? ?? 0,
    );
  }

  bool get hasResults => totalResults > 0;
  bool get hasUsers => users != null && users!.isNotEmpty;
}

/// Search repository interface
abstract class SearchRepository {
  /// Search across entities
  Future<Either<Failure, SearchResults>> search({
    required String query,
    SearchType type = SearchType.all,
    int limit = PaginationConfig.searchLimit,
  });
}

/// Search repository implementation
class SearchRepositoryImpl with BaseRepository implements SearchRepository {
  final Dio _dio;

  SearchRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Either<Failure, SearchResults>> search({
    required String query,
    SearchType type = SearchType.all,
    int limit = PaginationConfig.searchLimit,
  }) async {
    return safeCall(() async {
      final response = await _dio.get(
        ApiConstants.search,
        queryParameters: {
          'q': query,
          'type': type.name,
          'limit': limit,
        },
      );
      return SearchResults.fromJson(response.data);
    });
  }
}
