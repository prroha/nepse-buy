import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/export_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/atoms/app_button.dart';
import '../../widgets/empty_states/empty_list.dart';
import '../../widgets/empty_states/empty_search.dart';
import '../../widgets/layout/error_state.dart';
import '../../widgets/molecules/app_snackbar.dart';

/// User List Item Widget - uses theme system colors
class UserListItem extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final bool isUpdating;

  const UserListItem({
    super.key,
    required this.user,
    required this.onToggleStatus,
    required this.onEdit,
    required this.isUpdating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: AppSpacing.cardContentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: user.isAdmin
                      ? Colors.orange.withAlpha(51)
                      : colorScheme.primaryContainer,
                  child: Text(
                    (user.name?.isNotEmpty == true
                            ? user.name![0]
                            : user.email[0])
                        .toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: user.isAdmin ? Colors.orange : colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                AppSpacing.gapHMd,
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name ?? 'No name',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildRoleBadge(context),
                    AppSpacing.gapXs,
                    _buildStatusBadge(context),
                  ],
                ),
              ],
            ),
            AppSpacing.gapMd,
            // Created date
            Text(
              'Joined: ${_formatDate(user.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.gapMd,
            // Actions - Edit is primary, status toggle is secondary
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Edit',
                    onPressed: isUpdating ? null : onEdit,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.small,
                    icon: Icons.edit,
                  ),
                ),
                AppSpacing.gapHMd,
                Expanded(
                  child: user.isActive
                      ? OutlinedButton.icon(
                          onPressed: isUpdating ? null : onToggleStatus,
                          icon: isUpdating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.block, size: 14),
                          label: const Text('Deactivate', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSpacing.borderRadiusMd,
                            ),
                          ),
                        )
                      : AppButton(
                          label: 'Activate',
                          onPressed: isUpdating ? null : onToggleStatus,
                          variant: AppButtonVariant.secondary,
                          size: AppButtonSize.small,
                          icon: Icons.check_circle,
                          isLoading: isUpdating,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: user.isAdmin
            ? Colors.orange.withAlpha(26)
            : colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        user.role,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: user.isAdmin ? Colors.orange : colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: user.isActive
            ? Colors.green.withAlpha(26)
            : colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        user.isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: user.isActive ? Colors.green : colorScheme.error,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Edit User Dialog - uses theme system colors
class EditUserDialog extends StatefulWidget {
  final AdminUser user;
  final Function(String role) onSave;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.onSave,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Edit User'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.user.email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapMd,
          Text(
            'Role',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          AppSpacing.gapSm,
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'USER', child: Text('User')),
              DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
              DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Super Admin')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedRole = value;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_selectedRole);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Admin Users Screen
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminUsersProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleExportUsers() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final exportService = ref.read(exportServiceProvider);
      final result = await exportService.exportAndShareUsers();

      if (!mounted) return;

      result.fold(
        (failure) {
          AppSnackbar.error(
            context,
            'Export failed',
            description: failure.message,
          );
        },
        (_) {
          AppSnackbar.success(
            context,
            'Users exported',
            description: 'User data has been exported and shared.',
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showEditDialog(AdminUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => EditUserDialog(
        user: user,
        onSave: (role) async {
          final success = await ref
              .read(adminUsersProvider.notifier)
              .updateUserRole(user.id, role);

          if (mounted) {
            final colorScheme = Theme.of(context).colorScheme;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success ? 'User updated successfully' : 'Failed to update user',
                ),
                backgroundColor: success ? Colors.green : colorScheme.error,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _toggleUserStatus(AdminUser user) async {
    final colorScheme = Theme.of(context).colorScheme;
    final success =
        await ref.read(adminUsersProvider.notifier).toggleUserStatus(user);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'User ${user.isActive ? 'deactivated' : 'activated'} successfully'
                : 'Failed to update user status',
          ),
          backgroundColor: success ? Colors.green : colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Manage Users'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isExporting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                : const Icon(Icons.download_outlined),
            onPressed: _isExporting ? null : _handleExportUsers,
            tooltip: 'Export Users',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminUsersProvider.notifier).loadUsers();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            color: colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search - with real-time search on text change for better UX
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(adminUsersProvider.notifier)
                                  .setSearch('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    // Update UI to show/hide clear button
                    setState(() {});
                  },
                  onSubmitted: (value) {
                    ref.read(adminUsersProvider.notifier).setSearch(value);
                  },
                  textInputAction: TextInputAction.search,
                ),
                AppSpacing.gapMd,
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: state.roleFilter,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: 'USER', child: Text('User')),
                          DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                          DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('Super Admin')),
                        ],
                        onChanged: (value) {
                          ref
                              .read(adminUsersProvider.notifier)
                              .setRoleFilter(value);
                        },
                      ),
                    ),
                    AppSpacing.gapHMd,
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        value: state.statusFilter,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('All')),
                          DropdownMenuItem(value: true, child: Text('Active')),
                          DropdownMenuItem(
                              value: false, child: Text('Inactive')),
                        ],
                        onChanged: (value) {
                          ref
                              .read(adminUsersProvider.notifier)
                              .setStatusFilter(value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: state.error != null
                ? ErrorStateWidget(
                    message: state.error!,
                    onRetry: () {
                      ref.read(adminUsersProvider.notifier).loadUsers();
                    },
                  )
                : state.isLoading && state.users.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.users.isEmpty
                        ? _buildEmptyState(state)
                        : RefreshIndicator(
                            onRefresh: () async {
                              await ref
                                  .read(adminUsersProvider.notifier)
                                  .loadUsers();
                            },
                            child: ListView.builder(
                              padding: AppSpacing.screenPadding,
                              itemCount: state.users.length + 1,
                              itemBuilder: (context, index) {
                                if (index == state.users.length) {
                                  // Pagination controls
                                  return _buildPagination(state);
                                }

                                final user = state.users[index];
                                return UserListItem(
                                  user: user,
                                  onToggleStatus: () => _toggleUserStatus(user),
                                  onEdit: () => _showEditDialog(user),
                                  isUpdating: state.isUpdating,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AdminUsersState state) {
    // Check if any filters are active
    final hasFilters = state.search.isNotEmpty ||
        state.roleFilter != null ||
        state.statusFilter != null;

    if (hasFilters) {
      return EmptySearch(
        searchQuery: state.search.isNotEmpty ? state.search : null,
        onClearSearch: () {
          _searchController.clear();
          ref.read(adminUsersProvider.notifier).setSearch('');
          ref.read(adminUsersProvider.notifier).setRoleFilter(null);
          ref.read(adminUsersProvider.notifier).setStatusFilter(null);
        },
        clearLabel: 'Clear filters',
      );
    }

    return const EmptyList.users();
  }

  Widget _buildPagination(AdminUsersState state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.totalPages <= 1) return AppSpacing.gapMd;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: state.hasPrev
                ? () => ref.read(adminUsersProvider.notifier).prevPage()
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          AppSpacing.gapHMd,
          Text(
            'Page ${state.page} of ${state.totalPages}',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapHMd,
          IconButton(
            onPressed: state.hasNext
                ? () => ref.read(adminUsersProvider.notifier).nextPage()
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
