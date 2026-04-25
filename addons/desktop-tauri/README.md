# Desktop addon — Tauri

Native-quality Mac/Windows/Linux desktop app using Tauri (Rust shell + web UI). One codebase, ~10MB binaries. Reuses your web UI so you don't write desktop-specific code.

## What you get

- `desktop/` directory with Tauri v2 scaffold
- Reuses your existing web UI (HTMX, React, Vue, whatever) via Tauri's webview
- Native window chrome, menu bar, system tray, file dialogs, drag-drop
- `make desktop-dev`, `make desktop-build` targets
- Code signing scaffolding (commented out — fill in when you have certificates)
- CI workflow `.github/workflows/desktop.yml` for Mac/Win/Linux builds

## When to use

- You have a web UI and want a desktop wrapper that feels native
- You need OS integration (folder watching, external editor handoff, file associations)
- Solo dev — three platforms from one codebase
- Binary size matters (vs Electron's 100MB+)

## When NOT to use

- App needs heavy native UI (3D, video editing, complex graphics)
- You don't have a web UI to wrap
- You need < 1MB binary or zero-runtime
- Target users will balk at running an unsigned binary (signing requires Apple Dev ID + Windows EV cert)

## Apply

```bash
# Inside the dev container, with Rust toolchain installed (stacks/rust)
cd desktop
npm install
npm run tauri dev    # dev mode with hot reload
npm run tauri build  # production build for current platform
```

## Files

```
addons/desktop-tauri/
├── README.md
├── desktop/
│   ├── package.json
│   ├── src-tauri/
│   │   ├── Cargo.toml
│   │   ├── tauri.conf.json
│   │   └── src/main.rs
│   └── README.md
└── ci.yml.snippet
```

Add to CLAUDE.md when adopting:

```
## Desktop invariants
- Desktop app uses Tauri v2. No Electron, no Qt.
- All UI is the web UI — no desktop-specific HTML/CSS forks.
- OS integration (file watching, dialogs, tray) goes through Tauri commands in src-tauri/src/.
- Code signing certs live in CI secrets, never in the repo.
```
