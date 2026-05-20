/// Empty state widgets for various scenarios.
///
/// This library provides pre-configured empty state widgets for common
/// scenarios like empty lists, no search results, and connection issues.
///
/// These widgets are built on top of the [EmptyState] widget and provide
/// friendly, conversational copy to guide users on what to do next.
///
/// Example:
/// ```dart
/// import 'package:your_app/presentation/widgets/empty_states/empty_states.dart';
///
/// // No items in list
/// EmptyList.users(onAdd: () => inviteUser())
///
/// // Search returned no results
/// EmptySearch(
///   searchQuery: 'test',
///   onClearSearch: () => clearSearch(),
/// )
///
/// // Network connection lost
/// NoConnection(onRetry: () => fetchData())
/// ```
library empty_states;

export 'empty_list.dart';
export 'empty_search.dart';
export 'no_connection.dart';
