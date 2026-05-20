/// Widget library following atomic design principles.
///
/// This library exports all widget categories:
/// - [atoms] - Primitive UI building blocks (buttons, icons, text, badges)
/// - [molecules] - Composed UI components (form fields, cards, search bars)
/// - [organisms] - Complex UI components (headers, drawers, avatars)
/// - [layout] - Structural components (scaffolds, overlays, states)
/// - [empty_states] - Pre-configured empty state widgets
///
/// Example:
/// ```dart
/// import 'package:your_app/presentation/widgets/widgets.dart';
///
/// // Use atoms
/// AppButton(label: 'Submit', onPressed: handleSubmit);
/// AppText.heading1('Welcome');
///
/// // Use molecules
/// AppTextField(label: 'Email', hint: 'Enter email');
/// AppCard(child: content);
///
/// // Use organisms
/// AppHeader(title: 'Settings');
/// UserAvatar(name: 'John Doe');
///
/// // Use layout
/// ScreenScaffold(title: 'Home', body: content);
/// LoadingOverlay(isLoading: true, child: content);
///
/// // Use empty states
/// EmptyList.users(onAdd: () => inviteUser());
/// EmptySearch(searchQuery: 'test', onClearSearch: clearSearch);
/// NoConnection(onRetry: () => fetchData());
/// ```
library widgets;

export 'atoms/atoms.dart';
export 'empty_states/empty_states.dart';
export 'layout/layout.dart';
export 'molecules/molecules.dart';
export 'organisms/organisms.dart';
export 'settings/settings.dart';
export 'theme_selector.dart';
