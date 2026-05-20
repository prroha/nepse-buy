# Mobile App Architecture Template

## Recommended Structure (React Native / Expo)
```
src/
├── app/                    # Screens / navigation (Expo Router)
│   ├── (tabs)/             # Tab navigation group
│   ├── (auth)/             # Auth flow screens
│   ├── (modals)/           # Modal screens
│   ├── _layout.tsx         # Root layout / navigation config
│   └── index.tsx           # Entry screen
├── features/               # Feature modules
│   └── <feature>/
│       ├── components/     # Feature-specific components
│       ├── hooks/
│       ├── services/
│       ├── types.ts
│       └── index.ts
├── shared/
│   ├── components/
│   │   ├── ui/             # Primitive components (Button, Text, Card)
│   │   └── layout/         # Layout components (SafeArea, Container)
│   ├── hooks/
│   ├── lib/
│   ├── services/
│   ├── types/
│   └── utils/
├── styles/                 # Theme, design tokens, typography
├── config/                 # App config, constants
└── assets/                 # Images, fonts, animations
```

## Key Patterns
- **Screen vs Component**: Screens handle data fetching + layout. Components handle presentation.
- **Navigation**: File-based routing (Expo Router) or React Navigation with typed routes.
- **Offline-first**: Cache API responses. Queue mutations for retry.
- **Platform-specific**: `.ios.tsx` / `.android.tsx` suffixes only when truly needed.
- **Touch targets**: Minimum 44x44px for all interactive elements.
- **Lists**: FlatList/FlashList with proper keyExtractor, never ScrollView for dynamic lists.

## Native Considerations
- Use `SafeAreaView` for all screens.
- Handle keyboard avoidance for forms.
- Deep linking configuration.
- Push notification handling.
- Secure storage for sensitive data (not AsyncStorage).
