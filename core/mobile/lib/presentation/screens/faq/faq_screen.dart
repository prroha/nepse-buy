import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';

/// FAQ data model
class FAQItem {
  final String question;
  final String answer;

  const FAQItem({
    required this.question,
    required this.answer,
  });
}

/// FAQ category model
class FAQCategory {
  final String name;
  final IconData icon;
  final List<FAQItem> items;

  const FAQCategory({
    required this.name,
    required this.icon,
    required this.items,
  });
}

/// FAQ screen with expandable items organized by category
class FAQScreen extends ConsumerStatefulWidget {
  const FAQScreen({super.key});

  @override
  ConsumerState<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends ConsumerState<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  static const List<FAQCategory> _faqData = [
    FAQCategory(
      name: 'Getting Started',
      icon: Icons.rocket_launch,
      items: [
        FAQItem(
          question: 'What is Fullstack Starter?',
          answer:
              'Fullstack Starter is a comprehensive template for building modern full-stack applications. It includes a Next.js web app, React Native mobile app, Node.js backend with Express, and a PostgreSQL database with Prisma ORM. Everything is pre-configured with authentication, theming, and best practices.',
        ),
        FAQItem(
          question: 'How do I get started with the template?',
          answer:
              'Clone the repository, install dependencies with npm install in each directory (backend, web, mobile), set up your environment variables, run database migrations, and start the development servers. Check the README.md for detailed step-by-step instructions.',
        ),
        FAQItem(
          question: 'What technologies are used?',
          answer:
              'The stack includes Next.js 14+ with App Router for web, React Native with Expo for mobile, Node.js with Express and TypeScript for the backend, PostgreSQL with Prisma for the database, and Tailwind CSS for styling.',
        ),
      ],
    ),
    FAQCategory(
      name: 'Account & Security',
      icon: Icons.security,
      items: [
        FAQItem(
          question: 'How do I create an account?',
          answer:
              'Tap the "Sign Up" or "Register" button on the login screen. Fill in your email address, create a password, and complete the registration form. You will receive a verification email to confirm your account.',
        ),
        FAQItem(
          question: 'How do I reset my password?',
          answer:
              'Go to the login screen and tap "Forgot Password". Enter your email address and we will send you a password reset link. Tap the link in the email and follow the instructions to create a new password.',
        ),
        FAQItem(
          question: 'Can I delete my account?',
          answer:
              'Yes, you can delete your account from the Settings screen. Go to Settings > Account > Delete Account. Please note that this action is permanent and will remove all your data from our systems.',
        ),
        FAQItem(
          question: 'How is my data protected?',
          answer:
              'We use industry-standard encryption for data in transit and at rest. Your password is hashed using bcrypt, and we implement secure session management with JWT tokens. We also support two-factor authentication for additional security.',
        ),
      ],
    ),
    FAQCategory(
      name: 'Features',
      icon: Icons.apps,
      items: [
        FAQItem(
          question: 'How do I change the app theme?',
          answer:
              'Go to Settings > Appearance > Theme. You can choose between Light, Dark, or System (which follows your device settings). The change takes effect immediately.',
        ),
        FAQItem(
          question: 'Is offline mode supported?',
          answer:
              'Yes, the app supports offline functionality for certain features. Data is cached locally and synced when you reconnect to the internet. You will see an indicator when you are offline.',
        ),
        FAQItem(
          question: 'How do I enable push notifications?',
          answer:
              'Push notifications can be enabled in Settings > Notifications. Make sure you have granted the app permission to send notifications in your device settings.',
        ),
      ],
    ),
    FAQCategory(
      name: 'Technical Support',
      icon: Icons.support_agent,
      items: [
        FAQItem(
          question: 'How do I report a bug?',
          answer:
              'You can report bugs through the Contact Us option in Settings, or by opening an issue on our GitHub repository. Please include detailed steps to reproduce the issue and any relevant screenshots.',
        ),
        FAQItem(
          question: 'Where can I find documentation?',
          answer:
              'Documentation is available in the docs folder of the repository. It covers installation, configuration, architecture, API reference, and common use cases. You can also visit our website for online documentation.',
        ),
        FAQItem(
          question: 'How do I contact support?',
          answer:
              'You can reach our support team by email at support@example.com, or through the Contact Us option in Settings. We aim to respond within 24-48 hours.',
        ),
      ],
    ),
  ];

  List<FAQCategory> get _filteredData {
    if (_searchQuery.isEmpty && _selectedCategory == null) {
      return _faqData;
    }

    final query = _searchQuery.toLowerCase();

    return _faqData
        .where((category) =>
            _selectedCategory == null || category.name == _selectedCategory)
        .map((category) => FAQCategory(
              name: category.name,
              icon: category.icon,
              items: category.items
                  .where((item) =>
                      _searchQuery.isEmpty ||
                      item.question.toLowerCase().contains(query) ||
                      item.answer.toLowerCase().contains(query))
                  .toList(),
            ))
        .where((category) => category.items.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredData = _filteredData;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('FAQ'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search questions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppSpacing.borderRadiusMd,
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(100),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                _CategoryChip(
                  label: 'All',
                  icon: Icons.all_inclusive,
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: AppSpacing.sm),
                ..._faqData.map((category) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _CategoryChip(
                        label: category.name,
                        icon: category.icon,
                        isSelected: _selectedCategory == category.name,
                        onTap: () =>
                            setState(() => _selectedCategory = category.name),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // FAQ List
          Expanded(
            child: filteredData.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: filteredData.length,
                    itemBuilder: (context, categoryIndex) {
                      final category = filteredData[categoryIndex];
                      return _FAQCategorySection(category: category);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.onSurfaceVariant.withAlpha(100),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No questions found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try adjusting your search or filter',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
      borderRadius: AppSpacing.borderRadiusFull,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusFull,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQCategorySection extends StatelessWidget {
  final FAQCategory category;

  const _FAQCategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(25),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  category.icon,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                category.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // FAQ Items
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppSpacing.borderRadiusMd,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppSpacing.borderRadiusMd,
            child: Column(
              children: category.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == category.items.length - 1;

                return Column(
                  children: [
                    _FAQExpansionTile(item: item),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                        color: colorScheme.outlineVariant.withAlpha(100),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _FAQExpansionTile extends StatelessWidget {
  final FAQItem item;

  const _FAQExpansionTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      childrenPadding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Text(
        item.question,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      iconColor: colorScheme.onSurfaceVariant,
      collapsedIconColor: colorScheme.onSurfaceVariant,
      children: [
        Text(
          item.answer,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
