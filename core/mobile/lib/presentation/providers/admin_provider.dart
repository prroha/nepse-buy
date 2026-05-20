import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/admin_repository.dart';

/// Admin dashboard state
class AdminDashboardState {
  final bool isLoading;
  final String? error;
  final DashboardStats? stats;

  const AdminDashboardState({
    this.isLoading = false,
    this.error,
    this.stats,
  });

  AdminDashboardState copyWith({
    bool? isLoading,
    String? error,
    DashboardStats? stats,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

/// Admin dashboard notifier
class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  final AdminRepository _repository;

  AdminDashboardNotifier(this._repository) : super(const AdminDashboardState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getStats();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (stats) => state = state.copyWith(
        isLoading: false,
        stats: stats,
      ),
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Admin dashboard provider
final adminDashboardProvider =
    StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminDashboardNotifier(repository);
});

/// Admin users state
class AdminUsersState {
  final bool isLoading;
  final bool isUpdating;
  final String? error;
  final List<AdminUser> users;
  final int page;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;
  final String search;
  final String? roleFilter;
  final bool? statusFilter;

  const AdminUsersState({
    this.isLoading = false,
    this.isUpdating = false,
    this.error,
    this.users = const [],
    this.page = 1,
    this.totalPages = 1,
    this.hasNext = false,
    this.hasPrev = false,
    this.search = '',
    this.roleFilter,
    this.statusFilter,
  });

  AdminUsersState copyWith({
    bool? isLoading,
    bool? isUpdating,
    String? error,
    List<AdminUser>? users,
    int? page,
    int? totalPages,
    bool? hasNext,
    bool? hasPrev,
    String? search,
    String? roleFilter,
    bool? statusFilter,
    bool clearRoleFilter = false,
    bool clearStatusFilter = false,
  }) {
    return AdminUsersState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error,
      users: users ?? this.users,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
      search: search ?? this.search,
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

/// Admin users notifier
class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final AdminRepository _repository;

  AdminUsersNotifier(this._repository) : super(const AdminUsersState());

  Future<void> loadUsers({int? page}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      page: page,
    );

    final result = await _repository.getUsers(
      page: page ?? state.page,
      search: state.search.isNotEmpty ? state.search : null,
      role: state.roleFilter,
      isActive: state.statusFilter,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (paginatedUsers) => state = state.copyWith(
        isLoading: false,
        users: paginatedUsers.users,
        page: paginatedUsers.page,
        totalPages: paginatedUsers.totalPages,
        hasNext: paginatedUsers.hasNext,
        hasPrev: paginatedUsers.hasPrev,
      ),
    );
  }

  Future<void> setSearch(String search) async {
    state = state.copyWith(search: search, page: 1);
    await loadUsers(page: 1);
  }

  Future<void> setRoleFilter(String? role) async {
    state = state.copyWith(
      roleFilter: role,
      page: 1,
      clearRoleFilter: role == null,
    );
    await loadUsers(page: 1);
  }

  Future<void> setStatusFilter(bool? isActive) async {
    state = state.copyWith(
      statusFilter: isActive,
      page: 1,
      clearStatusFilter: isActive == null,
    );
    await loadUsers(page: 1);
  }

  Future<void> nextPage() async {
    if (state.hasNext) {
      await loadUsers(page: state.page + 1);
    }
  }

  Future<void> prevPage() async {
    if (state.hasPrev) {
      await loadUsers(page: state.page - 1);
    }
  }

  Future<bool> toggleUserStatus(AdminUser user) async {
    state = state.copyWith(isUpdating: true, error: null);

    final result = await _repository.updateUser(
      user.id,
      isActive: !user.isActive,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isUpdating: false, error: failure.message);
        return false;
      },
      (updatedUser) {
        // Update the user in the list
        final updatedUsers = state.users.map((u) {
          return u.id == updatedUser.id ? updatedUser : u;
        }).toList();
        state = state.copyWith(isUpdating: false, users: updatedUsers);
        return true;
      },
    );
  }

  Future<bool> updateUserRole(String userId, String role) async {
    state = state.copyWith(isUpdating: true, error: null);

    final result = await _repository.updateUser(userId, role: role);

    return result.fold(
      (failure) {
        state = state.copyWith(isUpdating: false, error: failure.message);
        return false;
      },
      (updatedUser) {
        // Update the user in the list
        final updatedUsers = state.users.map((u) {
          return u.id == updatedUser.id ? updatedUser : u;
        }).toList();
        state = state.copyWith(isUpdating: false, users: updatedUsers);
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Admin users provider
final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminUsersNotifier(repository);
});

/// Admin audit logs state
class AdminAuditLogsState {
  final bool isLoading;
  final String? error;
  final List<AuditLog> logs;
  final int page;
  final int totalPages;
  final int total;
  final bool hasNext;
  final bool hasPrev;
  final String search;
  final AuditAction? actionFilter;
  final String? entityFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<AuditAction> availableActions;
  final List<String> availableEntities;
  final String? expandedLogId;

  const AdminAuditLogsState({
    this.isLoading = false,
    this.error,
    this.logs = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.hasNext = false,
    this.hasPrev = false,
    this.search = '',
    this.actionFilter,
    this.entityFilter,
    this.startDate,
    this.endDate,
    this.availableActions = const [],
    this.availableEntities = const [],
    this.expandedLogId,
  });

  AdminAuditLogsState copyWith({
    bool? isLoading,
    String? error,
    List<AuditLog>? logs,
    int? page,
    int? totalPages,
    int? total,
    bool? hasNext,
    bool? hasPrev,
    String? search,
    AuditAction? actionFilter,
    String? entityFilter,
    DateTime? startDate,
    DateTime? endDate,
    List<AuditAction>? availableActions,
    List<String>? availableEntities,
    String? expandedLogId,
    bool clearActionFilter = false,
    bool clearEntityFilter = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearExpandedLogId = false,
  }) {
    return AdminAuditLogsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      logs: logs ?? this.logs,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
      search: search ?? this.search,
      actionFilter: clearActionFilter ? null : (actionFilter ?? this.actionFilter),
      entityFilter: clearEntityFilter ? null : (entityFilter ?? this.entityFilter),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      availableActions: availableActions ?? this.availableActions,
      availableEntities: availableEntities ?? this.availableEntities,
      expandedLogId: clearExpandedLogId ? null : (expandedLogId ?? this.expandedLogId),
    );
  }

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      actionFilter != null ||
      entityFilter != null ||
      startDate != null ||
      endDate != null;
}

/// Admin audit logs notifier
class AdminAuditLogsNotifier extends StateNotifier<AdminAuditLogsState> {
  final AdminRepository _repository;

  AdminAuditLogsNotifier(this._repository) : super(const AdminAuditLogsState());

  Future<void> initialize() async {
    await Future.wait([
      loadLogs(),
      loadFilterOptions(),
    ]);
  }

  Future<void> loadFilterOptions() async {
    final actionsResult = await _repository.getAuditLogActionTypes();
    final entitiesResult = await _repository.getAuditLogEntityTypes();

    actionsResult.fold(
      (_) {}, // Silently fail
      (actions) => state = state.copyWith(availableActions: actions),
    );

    entitiesResult.fold(
      (_) {}, // Silently fail
      (entities) => state = state.copyWith(availableEntities: entities),
    );
  }

  Future<void> loadLogs({int? page}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      page: page,
    );

    final result = await _repository.getAuditLogs(
      page: page ?? state.page,
      search: state.search.isNotEmpty ? state.search : null,
      action: state.actionFilter,
      entity: state.entityFilter,
      startDate: state.startDate,
      endDate: state.endDate,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (paginatedLogs) => state = state.copyWith(
        isLoading: false,
        logs: paginatedLogs.logs,
        page: paginatedLogs.page,
        totalPages: paginatedLogs.totalPages,
        total: paginatedLogs.total,
        hasNext: paginatedLogs.hasNext,
        hasPrev: paginatedLogs.hasPrev,
      ),
    );
  }

  Future<void> setSearch(String search) async {
    state = state.copyWith(search: search, page: 1);
    await loadLogs(page: 1);
  }

  Future<void> setActionFilter(AuditAction? action) async {
    state = state.copyWith(
      actionFilter: action,
      page: 1,
      clearActionFilter: action == null,
    );
    await loadLogs(page: 1);
  }

  Future<void> setEntityFilter(String? entity) async {
    state = state.copyWith(
      entityFilter: entity,
      page: 1,
      clearEntityFilter: entity == null || entity.isEmpty,
    );
    await loadLogs(page: 1);
  }

  Future<void> setDateRange(DateTime? start, DateTime? end) async {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      page: 1,
      clearStartDate: start == null,
      clearEndDate: end == null,
    );
    await loadLogs(page: 1);
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      search: '',
      page: 1,
      clearActionFilter: true,
      clearEntityFilter: true,
      clearStartDate: true,
      clearEndDate: true,
    );
    await loadLogs(page: 1);
  }

  void toggleExpandedLog(String logId) {
    if (state.expandedLogId == logId) {
      state = state.copyWith(clearExpandedLogId: true);
    } else {
      state = state.copyWith(expandedLogId: logId);
    }
  }

  Future<void> nextPage() async {
    if (state.hasNext) {
      await loadLogs(page: state.page + 1);
    }
  }

  Future<void> prevPage() async {
    if (state.hasPrev) {
      await loadLogs(page: state.page - 1);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Admin audit logs provider
final adminAuditLogsProvider =
    StateNotifierProvider<AdminAuditLogsNotifier, AdminAuditLogsState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminAuditLogsNotifier(repository);
});
