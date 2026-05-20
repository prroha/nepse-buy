import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/search_repository.dart';
import '../../providers/search_provider.dart';
import '../../widgets/molecules/search_bar.dart';

/// Search screen with debounced search and recent searches
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // Autofocus the search bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    ref.read(searchProvider.notifier).updateQuery(query);
  }

  void _onClear() {
    _controller.clear();
    ref.read(searchProvider.notifier).clearSearch();
    _focusNode.requestFocus();
  }

  void _onRecentSearchTap(String search) {
    _controller.text = search;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: search.length),
    );
    ref.read(searchProvider.notifier).updateQuery(search);
  }

  void _onResultTap(String query) {
    ref.read(searchProvider.notifier).addRecentSearch(query);
    // Navigate to user detail or close
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: AppSpacing.screenPadding,
              child: AppSearchBar(
                controller: _controller,
                focusNode: _focusNode,
                hint: 'Search users...',
                onChanged: _onQueryChanged,
                onClear: _onClear,
                autofocus: true,
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(searchState, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SearchState state, ThemeData theme) {
    // Loading state
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (state.error != null) {
      return _buildErrorState(state.error!, theme);
    }

    // Show results if we have them
    if (state.hasResults) {
      return _buildResults(state, theme);
    }

    // Show recent searches if query is short
    if (state.showRecentSearches) {
      return _buildRecentSearches(state.recentSearches, theme);
    }

    // Initial state or no results
    if (state.showInitialState) {
      return _buildInitialState(theme);
    }

    // No results found
    if (state.query.isNotEmpty && state.results != null) {
      return _buildNoResults(state.query, theme);
    }

    return const SizedBox.shrink();
  }

  Widget _buildInitialState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          AppSpacing.gapMd,
          Text(
            'Search the app',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          AppSpacing.gapSm,
          Text(
            'Type at least 2 characters to search',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches(List<String> searches, ThemeData theme) {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(searchProvider.notifier).clearRecentSearches();
              },
              child: const Text('Clear all'),
            ),
          ],
        ),
        AppSpacing.gapSm,
        ...searches.map((search) => _buildRecentSearchItem(search, theme)),
      ],
    );
  }

  Widget _buildRecentSearchItem(String search, ThemeData theme) {
    return ListTile(
      leading: Icon(
        Icons.history,
        color: theme.colorScheme.outline,
      ),
      title: Text(search),
      trailing: IconButton(
        icon: Icon(
          Icons.close,
          size: 18,
          color: theme.colorScheme.outline,
        ),
        onPressed: () {
          ref.read(searchProvider.notifier).removeRecentSearch(search);
        },
      ),
      onTap: () => _onRecentSearchTap(search),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildResults(SearchState state, ThemeData theme) {
    final results = state.results!;

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        // Users section
        if (results.hasUsers) ...[
          _buildSectionHeader('Users', Icons.people, theme),
          AppSpacing.gapSm,
          ...results.users!.map(
            (user) => _buildUserResult(user, state.query, theme),
          ),
        ],

        // Total results count
        AppSpacing.gapLg,
        Center(
          child: Text(
            '${results.totalResults} result${results.totalResults != 1 ? 's' : ''} found',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.outline,
        ),
        AppSpacing.gapHSm,
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildUserResult(
    UserSearchResult user,
    String query,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withAlpha(25),
          child: Text(
            user.initials,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name ?? 'No name',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user.role == 'ADMIN' || user.role == 'SUPER_ADMIN')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: user.role == 'SUPER_ADMIN'
                      ? theme.colorScheme.error.withAlpha(25)
                      : theme.colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  user.role == 'SUPER_ADMIN' ? 'Super Admin' : 'Admin',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: user.role == 'SUPER_ADMIN'
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
            if (!user.isActive)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Inactive',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          user.email,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => _onResultTap(query),
      ),
    );
  }

  Widget _buildNoResults(String query, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          AppSpacing.gapMd,
          Text(
            'No results found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          AppSpacing.gapSm,
          Text(
            'No results found for "$query"',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          AppSpacing.gapMd,
          Text(
            'Search failed',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          AppSpacing.gapSm,
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
