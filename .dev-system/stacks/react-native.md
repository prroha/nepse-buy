# React Native Stack Rules

## General
- All React rules apply (see `react.md`).
- Follow the mobile app architecture template.
- Expo SDK preferred over bare React Native for most projects.

## Navigation
- Expo Router (file-based) or React Navigation with typed routes.
- Type-safe navigation params.
- Deep linking configuration.

## Styling
- `StyleSheet.create()` for all styles (not inline objects).
- Design tokens for colors, spacing, typography.
- Responsive: use `Dimensions` or `useWindowDimensions` hook.
- No web-specific CSS (no `hover`, no `cursor`).

## Performance
- FlatList/FlashList for dynamic lists (never ScrollView with map).
- `React.memo` for list item components.
- Avoid unnecessary re-renders in list items.
- Image caching (expo-image or fast-image).
- Hermes engine enabled.

## Platform-Specific
- `Platform.select()` for small differences.
- `.ios.tsx` / `.android.tsx` for platform-specific implementations.
- Test on both platforms regularly.

## Native Features
- `expo-secure-store` for sensitive data (not AsyncStorage).
- `SafeAreaView` or `useSafeAreaInsets` for all screens.
- `KeyboardAvoidingView` for forms.
- Haptic feedback for important interactions.
