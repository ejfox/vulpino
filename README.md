# Vulpino

**JSON → Beautiful Widget in 60 Seconds**

Vulpino turns any JSON API endpoint into a beautiful iOS widget. No code. No design skills. Just paste a URL, pick your data, choose a template, and deploy to your home screen.

*Vulpino dice no* to customization theater. *Vulpino dice sì* to your data, presented with respect.

---

## Features

- **Five-tap flow**: URL → Select Data → Template → Customize → Done
- **7 typographic templates**: Mono Stat, Dual Stat, Stat Stack, Headline, List, Grid, Timestamp
- **All widget sizes**: Small (2×2), Medium (4×2), Large (4×4)
- **Secure headers**: API keys stored in Keychain
- **Offline-first**: Cached data with stale indicators
- **Deep links**: Tap widget to open custom URL or edit in app

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Building

1. Clone this repository
2. Open `Vulpino.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Update the App Group identifier if needed (`group.com.vulpino.widgets`)
5. Build and run on device or simulator

### App Icon

Add a 1024×1024 app icon to `VulpinoApp/Assets.xcassets/AppIcon.appiconset/`.

The icon should embody the fox: minimal, geometric, typographic. Black on cream. No gradients.

## Architecture

```
vulpino/
├── Shared/                    # Shared between app and widget
│   └── Sources/
│       ├── JSONValue.swift    # Recursive JSON parser
│       ├── WidgetConfig.swift # Widget configuration model
│       ├── WidgetTemplate.swift
│       ├── TemplateViews.swift
│       └── Formatters.swift   # Number/date formatting
├── VulpinoApp/
│   └── Sources/
│       ├── VulpinoApp.swift   # App entry + deep linking
│       ├── Views/
│       │   ├── OnboardingView.swift
│       │   ├── WidgetListView.swift
│       │   ├── WidgetEditorView.swift
│       │   ├── WidgetCreatedView.swift
│       │   ├── JSONTreeView.swift
│       │   └── TemplatePickerView.swift
│       ├── ViewModels/
│       │   └── WidgetEditorViewModel.swift
│       └── Services/
│           ├── APIService.swift
│           ├── StorageService.swift
│           ├── KeychainService.swift
│           └── HapticService.swift
└── VulpinoWidget/
    └── Sources/
        ├── VulpinoWidget.swift
        └── SelectWidgetIntent.swift
```

## Templates

| Template | Best For |
|----------|----------|
| **Mono Stat** | Single hero number (visitors, revenue, uptime) |
| **Dual Stat** | Comparing two values (today vs yesterday) |
| **Stat Stack** | Dashboard summary (3-5 key metrics) |
| **Headline** | Latest status, most recent entry |
| **List** | Recent items, top 5, task list |
| **Grid** | Multi-metric dashboard (2×2 or 3×2) |
| **Timestamp** | Value with "as of" time (stock price, weather) |

## Design Philosophy

> "The fox sees the scattered data of the forest—every leaf, every shadow, every scent—and knows instantly which path leads to the rabbit. He does not deliberate. He does not customize. He *sees* and he *acts*."

Typography is the feature. Templates are opinionated. Users pick from well-designed options—they don't pick fonts, colors, or padding. The constraint is the product.

See [ETYMOLOGY.md](ETYMOLOGY.md) for the full story of the brass fox.

## Example Endpoints

Try these public APIs:

- **GitHub Status**: `https://www.githubstatus.com/api/v2/status.json`
- **Bitcoin Price**: `https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd`
- **Cat Facts**: `https://catfact.ninja/fact`
- **JSONPlaceholder**: `https://jsonplaceholder.typicode.com/todos/1`

## URL Scheme

Vulpino registers the `vulpino://` URL scheme:

- `vulpino://` — Open app
- `vulpino://widget/{uuid}` — Open widget editor for specific widget

Widgets use custom tap URLs (configured per widget) or fall back to deep linking into the app.

---

*Room 302 Studio • 2025*
