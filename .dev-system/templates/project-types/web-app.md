# Web App Architecture Template

## Recommended Structure
```
src/
├── app/                    # Pages / routes (Next.js App Router, or equivalent)
│   ├── (auth)/             # Route group: authenticated pages
│   ├── (public)/           # Route group: public pages
│   ├── api/                # API routes (if using full-stack framework)
│   ├── layout.tsx          # Root layout
│   └── page.tsx            # Home page
├── features/               # Feature modules (self-contained)
│   └── <feature>/
│       ├── components/     # Feature-specific components
│       ├── hooks/          # Feature-specific hooks
│       ├── services/       # Feature-specific API calls
│       ├── types.ts        # Feature types
│       └── index.ts        # Public API
├── shared/                 # Cross-feature shared code
│   ├── components/
│   │   ├── ui/             # Primitive UI components (Button, Input, Modal)
│   │   └── layout/         # Layout components (Header, Footer, Sidebar)
│   ├── hooks/              # Shared custom hooks
│   ├── lib/                # Utilities and helpers
│   ├── services/           # Shared API service layer
│   ├── types/              # Global type definitions
│   └── utils/              # Pure utility functions
├── styles/                 # Global styles, theme, design tokens
└── config/                 # App configuration, constants
```

## Key Patterns
- **Feature-based organization**: Each feature is self-contained with its own components, hooks, services.
- **Shared layer**: Only truly cross-cutting concerns go in `shared/`.
- **API layer**: Centralized HTTP client with typed request/response.
- **State management**: Local state first (useState/useReducer), then context, then external store (Zustand/Jotai) only when needed.
- **Error boundaries**: At route level and around critical features.
- **Loading states**: Skeleton/spinner at component level, not page level.

## Authentication Pattern
- Auth provider wrapping the app
- Protected route wrapper/middleware
- Token storage in httpOnly cookies (never localStorage for auth tokens)
- Auth service with login/logout/refresh methods

## Data Fetching
- Server components for initial data (if SSR framework)
- Client-side: React Query/SWR for cache, deduplication, optimistic updates
- API client: single configured instance with interceptors for auth, error handling
