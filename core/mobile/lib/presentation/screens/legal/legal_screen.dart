import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_spacing.dart';
import '../../widgets/molecules/app_snackbar.dart';

/// Legal document type
enum LegalDocumentType {
  terms,
  privacy,
}

/// Legal screen that displays Terms of Service or Privacy Policy
/// Can display content in-app or open in a webview
class LegalScreen extends ConsumerStatefulWidget {
  final LegalDocumentType documentType;

  const LegalScreen({
    super.key,
    required this.documentType,
  });

  @override
  ConsumerState<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends ConsumerState<LegalScreen> {
  bool _useWebView = false;

  String get _title {
    switch (widget.documentType) {
      case LegalDocumentType.terms:
        return 'Terms of Service';
      case LegalDocumentType.privacy:
        return 'Privacy Policy';
    }
  }

  String get _webUrl {
    switch (widget.documentType) {
      case LegalDocumentType.terms:
        return 'https://example.com/terms';
      case LegalDocumentType.privacy:
        return 'https://example.com/privacy';
    }
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(_webUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Cannot open link',
          description: 'Unable to open the link. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(_title),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInBrowser,
            tooltip: 'Open in browser',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: widget.documentType == LegalDocumentType.terms
            ? _buildTermsContent(context)
            : _buildPrivacyContent(context),
      ),
    );
  }

  Widget _buildTermsContent(BuildContext context) {
    final lastUpdated = _formatDate(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegalHeader(
          title: 'Terms of Service',
          lastUpdated: lastUpdated,
        ),
        _LegalSection(
          number: '1',
          title: 'Acceptance of Terms',
          content:
              'By accessing or using our Services, you acknowledge that you have read, understood, and agree to be bound by these Terms. If you are using the Services on behalf of an organization, you represent and warrant that you have the authority to bind that organization to these Terms.',
        ),
        _LegalSection(
          number: '2',
          title: 'Use License',
          content:
              'Subject to these Terms, we grant you a limited, non-exclusive, non-transferable, revocable license to access and use the Services for your personal or internal business purposes.',
        ),
        _LegalSection(
          number: '3',
          title: 'User Accounts',
          content:
              'To access certain features of the Services, you must create an account. You agree to provide accurate, current, and complete information during registration and to update such information to keep it accurate, current, and complete. You are responsible for maintaining the confidentiality of your account credentials.',
        ),
        _LegalSection(
          number: '4',
          title: 'Acceptable Use',
          content:
              'You agree to use the Services only for lawful purposes and in accordance with these Terms. You agree not to use the Services in any way that violates any applicable law or regulation, or engage in any conduct that is abusive, harassing, threatening, or harmful.',
        ),
        _LegalSection(
          number: '5',
          title: 'Intellectual Property',
          content:
              'The Services and all content, features, and functionality are owned by us, our licensors, or other providers of such material and are protected by copyright, trademark, patent, trade secret, and other intellectual property laws.',
        ),
        _LegalSection(
          number: '6',
          title: 'User Content',
          content:
              'You retain all rights in any content you submit, post, or display on or through the Services. By providing User Content, you grant us a worldwide, non-exclusive, royalty-free license to use, reproduce, modify, and distribute your User Content in connection with operating and providing the Services.',
        ),
        _LegalSection(
          number: '7',
          title: 'Termination',
          content:
              'We may terminate or suspend your access to the Services immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach these Terms.',
        ),
        _LegalSection(
          number: '8',
          title: 'Disclaimers',
          content:
              'THE SERVICES ARE PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. We do not warrant that the Services will be uninterrupted, timely, secure, or error-free.',
        ),
        _LegalSection(
          number: '9',
          title: 'Limitation of Liability',
          content:
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL WE BE LIABLE FOR ANY INDIRECT, PUNITIVE, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES ARISING OUT OF OR RELATING TO THE USE OF, OR INABILITY TO USE, THE SERVICES.',
        ),
        _LegalSection(
          number: '10',
          title: 'Contact Information',
          content:
              'If you have any questions about these Terms, please contact us at legal@example.com.',
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildPrivacyContent(BuildContext context) {
    final lastUpdated = _formatDate(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LegalHeader(
          title: 'Privacy Policy',
          lastUpdated: lastUpdated,
        ),
        _LegalSection(
          number: '1',
          title: 'Introduction',
          content:
              'Your privacy is important to us. This Privacy Policy explains how we collect, use, disclose, and protect your information when you use our website and services. By using our Services, you agree to the collection and use of information in accordance with this policy.',
        ),
        _LegalSection(
          number: '2',
          title: 'Information We Collect',
          content:
              'We collect information you provide directly to us, including account information (name, email address, password), profile information, payment information (processed securely through Stripe), and communications. We also automatically collect device information, log information, location information, and usage information.',
        ),
        _LegalSection(
          number: '3',
          title: 'How We Use Your Information',
          content:
              'We use the information we collect to provide, maintain, and improve our Services; process transactions; send you technical notices and support messages; respond to your comments and questions; communicate with you about products and services; and monitor and analyze trends and usage.',
        ),
        _LegalSection(
          number: '4',
          title: 'Information Sharing',
          content:
              'We do not sell your personal information. We may share your information with service providers who perform services on our behalf, when required by law, in connection with business transfers, or with your consent.',
        ),
        _LegalSection(
          number: '5',
          title: 'Data Security',
          content:
              'We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. These measures include encryption of data in transit and at rest, regular security assessments, and access controls.',
        ),
        _LegalSection(
          number: '6',
          title: 'Your Rights (GDPR)',
          content:
              'If you are a resident of the European Economic Area, you have certain data protection rights including the right to access, rectification, erasure, restrict processing, data portability, object to processing, and withdraw consent. To exercise these rights, please contact us at privacy@example.com.',
        ),
        _LegalSection(
          number: '7',
          title: 'California Privacy Rights (CCPA)',
          content:
              'If you are a California resident, you have specific rights under the California Consumer Privacy Act including the right to know, right to delete, right to opt-out, and right to non-discrimination.',
        ),
        _LegalSection(
          number: '8',
          title: 'Cookies and Tracking',
          content:
              'We use cookies and similar tracking technologies to collect and store information about your interactions with our Services. You can control cookies through your browser settings.',
        ),
        _LegalSection(
          number: '9',
          title: 'Data Retention',
          content:
              'We retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law.',
        ),
        _LegalSection(
          number: '10',
          title: 'Contact Us',
          content:
              'If you have any questions about this Privacy Policy or our privacy practices, please contact our Data Protection Officer at privacy@example.com.',
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _LegalHeader extends StatelessWidget {
  final String title;
  final String lastUpdated;

  const _LegalHeader({
    required this.title,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Last updated: $lastUpdated',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(50),
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border(
              left: BorderSide(
                color: colorScheme.primary,
                width: 4,
              ),
            ),
          ),
          child: Text(
            'Please read this document carefully. By using our services, you agree to be bound by these terms.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String number;
  final String title;
  final String content;

  const _LegalSection({
    required this.number,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number. ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Terms of Service screen
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(documentType: LegalDocumentType.terms);
  }
}

/// Privacy Policy screen
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScreen(documentType: LegalDocumentType.privacy);
  }
}
