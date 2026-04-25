# Mobile addon — React Native (Expo)

Cross-platform iOS + Android app sharing one codebase. Recommended for projects where the mobile app is a thin client over an API and you don't need bleeding-edge native performance.

## What you get

- `mobile/` directory at repo root with Expo + TypeScript scaffold
- React Navigation (stack + tabs) preconfigured
- API client structure (`mobile/src/api/`) with typed fetch helpers
- ESLint + Prettier matching the Node stack
- `make mobile-test`, `make mobile-lint`, `make mobile-build` Makefile targets
- CI workflow `.github/workflows/mobile.yml` that runs lint + test + EAS build (when configured)

## When to use

- Solo dev or small team
- API-first product where the app is mostly screens over data
- You want App Store + Play Store coverage without two codebases

## When NOT to use

- Photo/video apps where scroll smoothness matters above all
- Apps where camera/sensor access drives the UX
- You have separate iOS and Android dev capacity

## Apply

```bash
# This is a placeholder — copy contents of addons/mobile-rn/scaffold/ into mobile/
# Then run inside the container:
cd mobile && npm install && npx expo prebuild
```

## Files

```
addons/mobile-rn/
├── README.md (this file)
├── scaffold/
│   ├── package.json
│   ├── app.json
│   ├── tsconfig.json
│   ├── babel.config.js
│   ├── App.tsx
│   ├── eas.json
│   └── src/
│       ├── api/client.ts
│       ├── navigation/RootStack.tsx
│       └── screens/HomeScreen.tsx
└── ci.yml.snippet
```

Add to your CLAUDE.md when you adopt this addon:

```
## Mobile invariants
- Mobile app is a thin client. Business logic lives in the API.
- Use React Query for server state. No global stores for API data.
- Type all API responses; never use `any`.
- Test with React Testing Library, not Detox at unit level.
```
