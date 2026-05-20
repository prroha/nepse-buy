# Next.js Stack Rules

## App Router
- Server Components by default. Add `"use client"` only when needed (interactivity, hooks, browser APIs).
- `layout.tsx` for shared layout. `page.tsx` for route content. `loading.tsx` for suspense. `error.tsx` for error boundaries.
- Route groups `(groupName)` for organization without affecting URL.
- Parallel routes `@slot` for simultaneous rendering.
- Intercepting routes `(.)path` for modals.

## Data Fetching
- Server Components: `async` function with direct data access (db, API).
- Client Components: React Query / SWR with server-defined API routes.
- Never fetch in `useEffect` for initial data — use server components or React Query.
- Revalidation: `revalidatePath()` / `revalidateTag()` after mutations.

## Server Actions
- Use for form submissions and mutations.
- Validate input with Zod at the top of every action.
- Return typed results: `{ success: true, data }` or `{ success: false, error }`.
- Progressive enhancement: forms should work without JavaScript.

## API Routes
- `route.ts` in app/api/ directory.
- Export named functions: `GET`, `POST`, `PUT`, `DELETE`.
- Validate request body with Zod schemas.
- Return `NextResponse.json()` with appropriate status codes.

## Performance
- Use `<Image>` component for all images (automatic optimization).
- Use `<Link>` for all internal navigation (prefetching).
- Dynamic imports for heavy client components.
- Metadata API for SEO (`generateMetadata`).

## Environment Variables
- `NEXT_PUBLIC_*` prefix for client-accessible variables.
- Server-only variables: no prefix, accessed only in server components/actions/routes.
- Never expose server secrets to the client.

## Storybook
- All `shared/components/ui/` components must have `.stories.tsx` files.
- Use CSF3 format with `meta` default export.
- Server Components cannot be rendered in Storybook directly — create a client wrapper or mock server-only dependencies.
- Use `@storybook/nextjs` framework for automatic Next.js integration (Image, Link, router mocking).
- Stories for layout components should show them at multiple viewport sizes.
- Use `nextjs.appDirectory` parameter for App Router compatibility.

## OpenAPI Documentation (When Using API Routes)
- Use `next-swagger-doc` or `zod-openapi` to generate OpenAPI 3.1 from Zod route schemas.
- Serve Swagger UI at `/api/docs` using a dedicated API route.
- Every API route must define Zod schemas for request body, query params, and response — these feed the spec.
- If using tRPC instead of REST routes, use `trpc-openapi` to expose OpenAPI-compatible endpoints.
- Export `openapi.json` at `/api/openapi.json` for client generation tooling.

## Middleware
- `middleware.ts` at project root for auth redirects, i18n, etc.
- Keep middleware lightweight — no heavy computation.
