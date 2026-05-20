import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/molecules/offline_banner.dart';
import '../../widgets/notifications/notification_bell.dart';
import '../signals/signals_screen.dart';
import '../watchlist/watchlist_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../discover/discover_screen.dart';
import '../profile/profile_screen.dart';

/// Bottom-tabbed home for the nepse-buy app. Three tabs: Today, Watchlist, Profile.
/// Uses IndexedStack to preserve tab state when switching.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _tabs = [
    _Tab(label: 'Today', icon: Icons.today_outlined, activeIcon: Icons.today, title: 'nepse-buy'),
    _Tab(label: 'Discover', icon: Icons.explore_outlined, activeIcon: Icons.explore, title: 'Discover'),
    _Tab(label: 'Watchlist', icon: Icons.bookmark_border, activeIcon: Icons.bookmark, title: 'Watchlist'),
    _Tab(label: 'Portfolio', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, title: 'Portfolio'),
    _Tab(label: 'Profile', icon: Icons.person_outline, activeIcon: Icons.person, title: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(tab.title),
        actions: const [NotificationBell(), SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [SignalsScreen(), DiscoverScreen(), WatchlistScreen(), PortfolioScreen(), ProfileScreen()],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.activeIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String title;
  const _Tab({required this.label, required this.icon, required this.activeIcon, required this.title});
}
