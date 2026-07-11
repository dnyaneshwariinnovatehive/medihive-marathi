# Localization Foundation — Architecture Report

## Summary

Implemented a centralized Localization Service that bridges the Flutter
app with the backend SettingsManager.  The existing ARB files, generated
classes, MaterialApp configuration, `LocaleProvider`, and
`LanguageToggleButton` were already in place; this work adds the
persistence layer that connects them to the backend.

---

## Files Created (1)

| # | File | Lines | Purpose |
|---|------|-------|---------|
| 1 | `lib/services/localization_service.dart` | 90 | Singleton — loads/saves locale from backend SettingsManager + SharedPreferences fallback |

## Files Modified (3)

| # | File | Change |
|---|------|--------|
| 1 | `lib/providers/locale_provider.dart` | Removed constructor-based `_loadLocale()`. Now delegates `loadLocale()` and `saveLocale()` to `LocalizationService`. |
| 2 | `lib/services/api_service.dart` | Added `getSettings()` and `updateSettings()` static methods for the backend `/api/settings` endpoint. |
| 3 | `lib/main.dart` | `LocaleProvider` creation now calls `lp.loadLocale()` (async) after construction instead of the old constructor-based load. |

No screen or widget files were modified.

---

## Localization Architecture

```
                    ┌────────────────────────────────────┐
                    │          Flutter App                │
                    │                                    │
                    │  ┌──────────────────────────────┐  │
                    │  │      MaterialApp.router       │  │
                    │  │  locale: localeProvider.locale│  │
                    │  │  localizationsDelegates: [...]│  │
                    │  │  supportedLocales: [en, mr]   │  │
                    │  └──────────┬───────────────────┘  │
                    │             │ Consumer2 rebuilds   │
                    │             ▼                      │
                    │  ┌──────────────────────────────┐  │
                    │  │      LocaleProvider           │  │
                    │  │  (ChangeNotifier)             │  │
                    │  │  _locale → notifyListeners()  │  │
                    │  └──────────┬───────────────────┘  │
                    │             │ delegates to         │
                    │             ▼                      │
                    │  ┌──────────────────────────────┐  │
                    │  │    LocalizationService         │  │
                    │  │  (singleton)                   │  │
                    │  │  loadLocale() → saveLocale()   │  │
                    │  └──────┬──────────────┬────────┘  │
                    │         │              │           │
                    │         ▼              ▼           │
                    │  ┌──────────┐  ┌──────────────┐   │
                    │  │ SharedPrefs│  │  ApiService  │   │
                    │  │ (offline) │  │  getSettings │   │
                    │  │           │  │  updateSet.  │   │
                    │  └──────────┘  └──────┬───────┘   │
                    └──────────────────────┼────────────┘
                                           │ HTTP
                                           ▼
                              ┌────────────────────────┐
                              │   Flask Backend         │
                              │   /api/settings         │
                              │   SettingsManager       │
                              │   SettingsModel         │
                              │   settings table        │
                              └────────────────────────┘
```

### Data Flow

| Action | Path |
|--------|------|
| **Startup (load)** | `main.dart` → `LocaleProvider.loadLocale()` → `LocalizationService.loadLocale()` → tries `ApiService.getSettings()` → falls back to `SharedPreferences` → falls back to `Locale('en')` |
| **User switches** | `LanguageToggleButton` → `localeProvider.setLocale(Locale('mr'))` → `notifyListeners()` (rebuilds MaterialApp) → `localizationService.saveLocale(locale)` → `SharedPreferences` (immediate) + `ApiService.updateSettings({'language': 'mr'})` (async best-effort) |
| **Locale read** | `MaterialApp.router` → `localeProvider.locale` → Flutter's `AppLocalizations.of(context)` resolves strings from `app_localizations_en.dart` or `app_localizations_mr.dart` |

---

## Services/Layers

### LocalizationService (`lib/services/localization_service.dart`)

A singleton service with two public methods:

| Method | Returns | Behavior |
|--------|---------|----------|
| `loadLocale()` | `Future<Locale>` | Loads from: (1) backend SettingsManager, (2) SharedPreferences, (3) English default |
| `saveLocale(Locale)` | `Future<void>` | Persists locally (immediate) + best-effort backend (async) |
| `currentLocale` | `Locale` | Cached in-memory locale (no I/O) |

### LocaleProvider (`lib/providers/locale_provider.dart`)

A `ChangeNotifier` that:
- Holds the current `Locale` in memory
- Calls `notifyListeners()` on change → rebuilds `Consumer2` → rebuilds `MaterialApp`
- Delegates all I/O to `LocalizationService`

### ApiService (`lib/services/api_service.dart`)

Two new static methods:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `getSettings()` | `GET /api/settings` | Returns `Map<String, dynamic>` of all settings |
| `updateSettings(settings)` | `PUT /api/settings` | Sends partial update `{'settings': {...}}` |

---

## How New Strings Will Be Added

1. Open `lib/l10n/app_en.arb` and add a new key-value pair:
   ```json
   "new_feature_title": "New Feature"
   ```
2. Open `lib/l10n/app_mr.arb` and add the Marathi translation:
   ```json
   "new_feature_title": "नवीन वैशिष्ट्य"
   ```
3. Run `flutter gen-l10n` to regenerate `app_localizations.dart`,
   `app_localizations_en.dart`, and `app_localizations_mr.dart`.
4. Use in any widget:
   ```dart
   Text(AppLocalizations.of(context)!.newFeatureTitle)
   ```
   (the generated class converts `snake_case` keys to `camelCase` getters)

No manual wiring is needed — the generated delegate already registers
itself in `localizationsDelegates`.

---

## How Future Languages Will Be Added

1. Create a new ARB file, e.g. `lib/l10n/app_hi.arb` for Hindi.
2. Translate every key from `app_en.arb` into the new language.
3. Add the locale to `supportedLocales` in `MaterialApp` (in `main.dart`):
   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('mr'),
     Locale('hi'),   // ← new
   ],
   ```
4. Update `LocalizationService._isSupported()`:
   ```dart
   bool _isSupported(String code) =>
       code == 'en' || code == 'mr' || code == 'hi';
   ```
5. Run `flutter gen-l10n` — the generator automatically discovers the
   new ARB file and generates the implementation class.
6. No changes to any screen, widget, or provider are needed.

Adding a new language is entirely data-driven: new ARB file + one-line
registration in `supportedLocales` + one-line update in `_isSupported()`.

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Singleton LocalizationService** | One locale for the whole app; no benefit to multiple instances. Singleton matches existing service patterns (`SyncManager`, `ApiService`, etc.). |
| **Backend-first, SharedPrefs fallback** | SettingsManager (backend) is the source of truth. SharedPreferences provides offline resilience. Both are always kept in sync. |
| **Fire-and-forget backend save** | Language switching is UX-critical — never block the UI waiting for a network request. If the backend is unreachable, the change is still persisted locally. |
| **LocaleProvider remains the ChangeNotifier** | Minimal refactor. LocalizationService is the persistence layer, not the state layer. Provider pattern stays intact. |
| **`loadLocale()` called explicitly in `main.dart`** | The old constructor-based load was hidden; explicit call makes the async dependency visible. |
| **LanguageToggleButton unchanged** | Already correctly delegates to `localeProvider.setLocale()` which now flows through `LocalizationService`. No code change needed. |
