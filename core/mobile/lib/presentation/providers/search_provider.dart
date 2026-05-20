import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/search_repository.dart';

/// Recent searches storage key
const String _recentSearchesKey = 'recent_searches';
const int _maxRecentSearches = 5;
const int _minQueryLength = 2;
const int _debounceMs = 300;

/// Search state
class SearchState {
  final String query;
  final SearchResults? results;
  final bool isLoading;
  final String? error;
  final List<String> recentSearches;

  const SearchState({
    this.query = '',
    this.results,
    this.isLoading = false,
    this.error,
    this.recentSearches = const [],
  });

  SearchState copyWith({
    String? query,
    SearchResults? results,
    bool? isLoading,
    String? error,
    List<String>? recentSearches,
    bool clearResults = false,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: clearResults ? null : (results ?? this.results),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }

  bool get hasResults => results != null && results!.hasResults;
  bool get showRecentSearches =>
      query.length < _minQueryLength && recentSearches.isNotEmpty;
  bool get showInitialState =>
      query.length < _minQueryLength && recentSearches.isEmpty;
}

/// Search notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchRepository _repository;
  Timer? _debounceTimer;

  SearchNotifier(this._repository) : super(const SearchState()) {
    _loadRecentSearches();
  }

  /// Load recent searches from SharedPreferences
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_recentSearchesKey) ?? [];
      state = state.copyWith(recentSearches: searches);
    } catch (_) {
      // Ignore errors
    }
  }

  /// Save recent searches to SharedPreferences
  Future<void> _saveRecentSearches(List<String> searches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentSearchesKey, searches);
    } catch (_) {
      // Ignore errors
    }
  }

  /// Update the search query with debouncing
  void updateQuery(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update query immediately
    state = state.copyWith(query: query);

    // Clear results and error if query is too short
    if (query.trim().length < _minQueryLength) {
      state = state.copyWith(
        clearResults: true,
        clearError: true,
        isLoading: false,
      );
      return;
    }

    // Set loading state
    state = state.copyWith(isLoading: true);

    // Debounce the search
    _debounceTimer = Timer(
      const Duration(milliseconds: _debounceMs),
      () => _performSearch(query),
    );
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.length < _minQueryLength) {
      return;
    }

    final result = await _repository.search(query: trimmedQuery);

    result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message,
          isLoading: false,
          clearResults: true,
        );
      },
      (results) {
        state = state.copyWith(
          results: results,
          isLoading: false,
          clearError: true,
        );
      },
    );
  }

  /// Add a search to recent searches
  void addRecentSearch(String search) {
    final trimmed = search.trim();
    if (trimmed.length < _minQueryLength) return;

    final filtered = state.recentSearches
        .where((s) => s.toLowerCase() != trimmed.toLowerCase())
        .toList();

    final newSearches = [trimmed, ...filtered].take(_maxRecentSearches).toList();
    state = state.copyWith(recentSearches: newSearches);
    _saveRecentSearches(newSearches);
  }

  /// Remove a search from recent searches
  void removeRecentSearch(String search) {
    final newSearches = state.recentSearches
        .where((s) => s.toLowerCase() != search.toLowerCase())
        .toList();
    state = state.copyWith(recentSearches: newSearches);
    _saveRecentSearches(newSearches);
  }

  /// Clear all recent searches
  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
    _saveRecentSearches([]);
  }

  /// Clear the search
  void clearSearch() {
    _debounceTimer?.cancel();
    state = state.copyWith(
      query: '',
      clearResults: true,
      clearError: true,
      isLoading: false,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Search provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(searchRepositoryProvider));
});
