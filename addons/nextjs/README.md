# Web addon — Next.js (App Router)

Modern React app with server components, TypeScript, Tailwind. For projects where the web app is the primary surface (vs a thin admin UI on top of an API).

## What you get

- `web/` directory with Next.js 15 + App Router scaffold
- Tailwind CSS preconfigured
- Type-safe API client (assumes you have a backend exposing OpenAPI)
- Auth scaffolding (placeholder — wire to your auth provider)
- `make web-dev`, `make web-build`, `make web-test` targets
- CI workflow for type-checking and build

## Requires

- `stacks/node` applied first (for ESLint/Prettier baselines)

## When to use

- The web app is a real product (not just a dashboard for an API)
- You want SSR/SSG for SEO or first-paint performance
- Your team already knows React

## When NOT to use

- Backend serves a small admin UI — use HTMX + Alpine instead (smaller, simpler)
- You don't need React's component model

## Apply

```bash
cp -r addons/nextjs/scaffold/web .
cd web && npm install
npm run dev  # http://localhost:3000
```

Add to CLAUDE.md:

```
## Web invariants
- Next.js App Router. No pages/ directory.
- Server Components by default. "use client" only when needed.
- Tailwind for styling. No CSS-in-JS.
- API client generated from OpenAPI; hand-written fetches are reviewed.
```
