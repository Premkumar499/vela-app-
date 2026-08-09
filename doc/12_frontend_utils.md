# 12. Frontend — Utils & Constants

Location: `billing_system/frontend/flutter_application/lib/utils/`

## 12.1 `constants.dart`

```dart
class AppConstants {
  static const String baseUrl = 'http://localhost:5000';
  static const Duration timeout = Duration(seconds: 15);
  static const int defaultPageSize = 50;
  // …page titles, storage paths, API endpoint strings…
}
```

- `baseUrl` — Flask backend base (change to LAN IP for device testing).
- Central API endpoint string constants used by `ApiService` / `InvoiceExportService`.
- Various UI constants (page sizes, storage paths) shared across screens.

## 12.2 `theme.dart`

App-wide light/dark `ThemeData`:

- Primary navy/blue accent; Material 3 seeded `ColorScheme`.
- Light and dark variants; `ThemeMode` switcher driven from `SettingsScreen`.
- Defines card styles, `InputDecorationTheme`, app-bar theme, elevated-button theme for
  a consistent POS look.

## 12.3 `pos_theme.dart`

POS-specific theming on top of the base theme:

- Dark cart/panel colors, product-grid tile styling, category chip palette.
- Tight spacing constants and small-size table styles used only inside the billing
  screen (keeps POS dense on desktop-width windows).

## 12.4 `currency_formatter.dart`

Indian rupee formatting:

- `formatCurrency(double)` → **₹ 1,37,960.71** (Indian digit grouping: lakhs/crores).
- `formatCompact(double)` → `₹1.4L`, `₹2.3K` style compact labels for cards.
- Parsing helpers (`tryParse`, remove ₹ / commas) used by quantity/price inputs.

## 12.5 `number_to_words.dart`

Indian-system number-to-words conversion:

- `convertAmountToWords(double)` → `"One Lakh Thirty Seven Thousand Nine Hundred
  Sixty Rupees and Seventy One Paise Only"`.
- Handles the lakh/crore grouping; paise always included.
- Used for the amount-in-words line on the company invoice preview and for the
  bilingual receipt.

## Summary table

| File | Responsibility |
|------|----------------|
| `constants.dart` | Base URL, endpoints, shared constants |
| `theme.dart` | Global light/dark theme |
| `pos_theme.dart` | POS-specific dark theme & sizing |
| `currency_formatter.dart` | ₹ Indian-grouping currency formatting |
| `number_to_words.dart` | Indian-system amount → words |

## Related docs

- [01 — Project Overview](01_project_overview.md)
- [10 — Frontend Screens](10_frontend_screens.md)
- [11 — Frontend Widgets](11_frontend_widgets.md)
