import 'package:flutter/material.dart';
import '../layout/empty_state.dart';

/// Empty state for generic lists.
///
/// Use this when a list/collection is empty and you want to guide
/// the user to add their first item.
///
/// Example:
/// ```dart
/// EmptyList(
///   title: 'No items yet',
///   message: 'Add your first item to get started.',
///   onAdd: () => showAddItemDialog(),
///   addLabel: 'Add Item',
/// )
/// ```
class EmptyList extends StatelessWidget {
  /// Title to display.
  final String title;

  /// Optional description message.
  final String? message;

  /// Callback when add button is pressed.
  final VoidCallback? onAdd;

  /// Label for the add button.
  final String addLabel;

  /// Icon to display.
  final IconData icon;

  const EmptyList({
    super.key,
    this.title = 'Nothing here yet',
    this.message = 'This list is empty. Add some items to get started.',
    this.onAdd,
    this.addLabel = 'Add Item',
    this.icon = Icons.folder_open_outlined,
  });

  /// Creates an empty state for user lists.
  const EmptyList.users({
    super.key,
    this.onAdd,
    this.addLabel = 'Invite User',
  })  : title = 'No users found',
        message = 'There are no users to display yet. When users sign up, they will appear here.',
        icon = Icons.people_outline;

  /// Creates an empty state for document/file lists.
  const EmptyList.documents({
    super.key,
    this.onAdd,
    this.addLabel = 'Upload File',
  })  : title = 'No files yet',
        message = 'Upload files to see them here. Tap the button below to get started.',
        icon = Icons.insert_drive_file_outlined;

  /// Creates an empty state for task/todo lists.
  const EmptyList.tasks({
    super.key,
    this.onAdd,
    this.addLabel = 'Add Task',
  })  : title = 'All done!',
        message = 'You have no tasks. Create a new task to stay organized.',
        icon = Icons.check_circle_outline;

  /// Creates an empty state for message/chat lists.
  const EmptyList.messages({
    super.key,
    this.onAdd,
    this.addLabel = 'Start Chat',
  })  : title = 'No messages yet',
        message = 'Start a conversation to see messages here.',
        icon = Icons.chat_bubble_outline;

  /// Creates an empty state for favorites/bookmarks.
  const EmptyList.favorites({
    super.key,
    this.onAdd,
    this.addLabel = 'Browse Items',
  })  : title = 'No favorites yet',
        message = 'Items you favorite will appear here for quick access.',
        icon = Icons.favorite_outline;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: icon,
      title: title,
      message: message,
      actionLabel: onAdd != null ? addLabel : null,
      onAction: onAdd,
      variant: EmptyStateVariant.noData,
    );
  }
}
