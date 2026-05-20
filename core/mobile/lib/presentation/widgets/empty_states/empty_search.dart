import 'package:flutter/material.dart';
import '../layout/empty_state.dart';

/// Empty state for search results.
///
/// Use this when a search returns no results to help users
/// understand what happened and what to do next.
///
/// Example:
/// ```dart
/// EmptySearch(
///   searchQuery: searchController.text,
///   onClearSearch: () {
///     searchController.clear();
///     setState(() {});
///   },
/// )
/// ```
class EmptySearch extends StatelessWidget {
  /// The search query that returned no results.
  final String? searchQuery;

  /// Callback to clear the search.
  final VoidCallback? onClearSearch;

  /// Label for the clear search button.
  final String clearLabel;

  /// Optional secondary action label.
  final String? secondaryLabel;

  /// Optional secondary action callback.
  final VoidCallback? onSecondaryAction;

  const EmptySearch({
    super.key,
    this.searchQuery,
    this.onClearSearch,
    this.clearLabel = 'Clear search',
    this.secondaryLabel,
    this.onSecondaryAction,
  });

  /// Creates an empty search state for filtered results.
  const EmptySearch.filtered({
    super.key,
    this.onClearSearch,
    this.clearLabel = 'Clear filters',
    this.secondaryLabel,
    this.onSecondaryAction,
  }) : searchQuery = null;

  String get _message {
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      return 'We couldn\'t find anything matching "$searchQuery". Try adjusting your search or filters.';
    }
    return "We couldn't find what you're looking for. Try adjusting your search or filters.";
  }

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No results found',
      message: _message,
      actionLabel: onClearSearch != null ? clearLabel : null,
      onAction: onClearSearch,
      secondaryActionLabel: secondaryLabel,
      onSecondaryAction: onSecondaryAction,
      variant: EmptyStateVariant.noResults,
    );
  }
}
