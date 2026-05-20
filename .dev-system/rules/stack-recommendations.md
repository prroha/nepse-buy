# Stack Recommendation Engine

Use this knowledge base to recommend the optimal tech stack for new projects.
Match user requirements to the best-fit technologies with clear reasoning.

## Step 1: Gather Requirements

Ask the user these questions (adapt based on context — skip irrelevant ones):

1. **What are you building?** (Brief description of the app/system)
2. **Project type?** web-app | mobile-app | api | full-stack | CLI tool
3. **Key requirements?** (select all that apply)
   - Real-time features (chat, live updates, collaboration)
   - Offline support
   - SEO / public-facing content
   - Heavy computation / data processing
   - File uploads / media handling
   - Authentication / multi-tenancy
   - Payment processing
   - Third-party API integrations
   - Background jobs / queues
   - Search (full-text, vector/semantic)
4. **Scale expectations?** Hobby/MVP | Startup (1K-100K users) | Growth (100K-1M) | Scale (1M+)
5. **Team context?** Solo dev | Small team (2-5) | Larger team (5+)
6. **Deployment preference?** Serverless (Vercel/Netlify) | Container (Docker/K8s) | VPS | Edge | No preference
7. **Timeline?** Prototype/hackathon | MVP (weeks) | Production (months)
8. **Any hard constraints?** (existing infra, team expertise, client requirements, budget)

## Step 2: Recommend Stack

Use the decision matrix below. Recommend the **single best-fit stack**, with a brief runner-up and reasoning.

---

### Frontend Framework Decision

| Requirement | Best Fit | Why |
|---|---|---|
| SEO + content-heavy + fast time-to-market | **Next.js** (App Router) | SSR/SSG built-in, React ecosystem, Vercel deployment |
| SPA, dashboard, internal tool | **React** (Vite) | Simpler setup, no SSR overhead, large ecosystem |
| SEO + lighter weight + performance | **Nuxt 4** (Vue) | Vue's simpler mental model, excellent SSR |
| SPA + simpler learning curve | **Vue** (Vite) | Easier onboarding, great docs, smaller bundle |
| Enterprise, large team, strict typing | **Angular** | Opinionated structure, built-in DI/routing/forms/HTTP |
| Content site, blog, docs, marketing | **Astro** | Zero JS by default, content collections, any UI framework |

### Backend Framework Decision

| Requirement | Best Fit | Why |
|---|---|---|
| Rapid API development, Python team | **FastAPI** | Auto docs, async, Pydantic validation, excellent DX |
| Full-featured web app, Python team | **Django** | Batteries-included (admin, ORM, auth, migrations) |
| JS/TS full-stack, unified language | **Next.js API Routes** or **tRPC** | End-to-end type safety, no separate backend |
| Standalone API, JS/TS team | **Hono** | Lightweight, edge-ready, works everywhere |
| Standalone API, Express familiarity | **Express** + **tRPC** or **Express** + **Zod** | Mature ecosystem, lots of middleware |
| High performance, systems-level | **Rust (Axum)** | Memory safety, zero-cost abstractions, best perf |
| High concurrency, microservices | **Go (stdlib or Chi)** | Goroutines, fast compile, simple deployment |
| Real-time heavy (WebSockets) | **Elixir (Phoenix)** or **Go** | Built for concurrent connections |

### Database Decision

| Requirement | Best Fit | Why |
|---|---|---|
| Relational data, ACID, general purpose | **PostgreSQL** | Most versatile, JSON support, extensions (pgvector, PostGIS) |
| Simple app, local-first, embedded | **SQLite** (via Turso/Litestream for production) | Zero config, surprisingly capable, great for edge |
| Document-oriented, flexible schema | **MongoDB** | Schema flexibility, good for rapid prototyping |
| Key-value, caching, sessions | **Redis** | In-memory speed, pub/sub, queues |
| Real-time sync, auth included | **Supabase** (PostgreSQL) | Firebase alternative with SQL, auth, realtime, storage |
| Firebase ecosystem, mobile-first | **Firebase** (Firestore) | Real-time sync, offline, Google auth integration |
| Vector/semantic search + relational | **PostgreSQL + pgvector** | Single DB for both relational and vector data |
| Time-series, IoT, metrics | **TimescaleDB** (PostgreSQL) or **InfluxDB** | Optimized for time-series queries |
| Graph relationships | **Neo4j** or **PostgreSQL + Apache AGE** | Native graph traversal |

### ORM / Query Builder Decision

| Stack | Best Fit | Why |
|---|---|---|
| TypeScript + PostgreSQL/MySQL/SQLite | **Drizzle** | Type-safe, SQL-like API, lightweight, great migrations |
| TypeScript + any SQL DB (rapid dev) | **Prisma** | Best DX, auto-generated types, visual studio |
| Python + any SQL DB | **SQLAlchemy 2.0** | Industry standard, flexible, async support |
| Python + Django | **Django ORM** | Built-in, tightly integrated, excellent migrations |
| Rust | **sqlx** | Compile-time checked SQL, no ORM overhead |
| Go | **sqlc** | Generate Go from SQL, type-safe, fast |

### Styling Decision

| Requirement | Best Fit | Why |
|---|---|---|
| Utility-first, rapid UI development | **Tailwind CSS v4** | Fast iteration, consistent design, small bundle |
| Pre-built components, fast MVP | **shadcn/ui** (Tailwind + Radix) | Copy-paste components, fully customizable, accessible |
| Material Design, enterprise | **MUI** (React) or **Vuetify** (Vue) | Complete component library, theming |
| CSS-in-JS, dynamic styling | **styled-components** or **Emotion** | Runtime theming, component-scoped |
| Mobile (React Native) | **NativeWind** (Tailwind for RN) or **Tamagui** | Cross-platform styling |

### Mobile Decision

| Requirement | Best Fit | Why |
|---|---|---|
| Cross-platform, JS/TS team | **React Native** (Expo) | Largest ecosystem, OTA updates, Expo simplifies everything |
| Cross-platform, high performance UI | **Flutter** | Custom rendering engine, consistent across platforms |
| iOS only, best native experience | **SwiftUI** | Apple's official, best iOS integration |
| Android only | **Kotlin + Jetpack Compose** | Google's official, best Android integration |
| Web app that feels native | **PWA** (Next.js/Nuxt + service workers) | No app store, instant updates, web tech |

### Authentication Decision

| Requirement | Best Fit | Why |
|---|---|---|
| Full-stack Next.js | **NextAuth.js (Auth.js)** or **Clerk** | Tight integration, many providers |
| BaaS with auth included | **Supabase Auth** or **Firebase Auth** | No separate auth service needed |
| Self-hosted, maximum control | **Lucia** or custom JWT | Full control, no vendor lock-in |
| Enterprise SSO, SAML | **WorkOS** or **Auth0** | Enterprise features out of the box |

### Deployment Decision

| Requirement | Best Fit | Why |
|---|---|---|
| Next.js / frontend-heavy | **Vercel** | Zero-config, preview deploys, edge functions |
| Static sites, Jamstack | **Netlify** or **Cloudflare Pages** | Global CDN, serverless functions |
| Containers, full control | **Fly.io** or **Railway** | Simple container deploy, global edge |
| Self-hosted, budget | **Coolify** (on VPS) or **Dokku** | Self-hosted PaaS, Docker-based |
| Enterprise, complex infra | **AWS / GCP / Azure** | Full service catalog, compliance |

---

## Step 3: Present Recommendation

Format the recommendation as:

```
## Recommended Stack for [Project Name]

Based on your requirements ([key factors]), here's the optimal stack:

| Layer | Choice | Why |
|---|---|---|
| Frontend | ... | ... |
| Backend | ... | ... |
| Database | ... | ... |
| ORM | ... | ... |
| Styling | ... | ... |
| Auth | ... | ... |
| Testing | ... | ... |
| Deployment | ... | ... |

### Why This Stack?
[2-3 sentences on the overall rationale — why these pieces fit together well]

### Alternatives Considered
- **[Alternative]**: Would be better if [condition]. Chose [recommended] because [reason].

### Trade-offs to Know
- [Any downsides or things to watch out for with this stack]
```

## Step 4: Confirm with User

Present the recommendation and ask:
- Does this look right?
- Want to adjust any layer?
- Any constraints I missed?

Once confirmed, proceed with writing `config.json` and the rest of `/init`.

---

## Common Stack Combos (Quick Reference)

### "Modern SaaS" (TypeScript full-stack)
Next.js + Tailwind + shadcn/ui + Drizzle + PostgreSQL + NextAuth + Vercel

### "Fast MVP" (Ship in days)
Next.js + Tailwind + shadcn/ui + Supabase (DB + Auth + Storage) + Vercel

### "Python API"
FastAPI + SQLAlchemy + PostgreSQL + Alembic + pytest + Docker

### "High-Performance API"
Rust (Axum) + sqlx + PostgreSQL + Docker

### "Mobile App"
React Native (Expo) + NativeWind + Supabase + EAS

### "Content/Marketing Site"
Astro + Tailwind + MDX + Cloudflare Pages

### "Enterprise Dashboard"
Angular + Material + NestJS + PostgreSQL + Prisma + Docker/K8s

### "Real-time App" (Chat, collab)
Next.js + Tailwind + Supabase Realtime (or Socket.io + Redis) + PostgreSQL
