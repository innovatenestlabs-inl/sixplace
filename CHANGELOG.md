## 1.0.0

### First stable release

- Promoted Sixplace to its first stable public release with all six foundations available: responsive layout, networking, feedback, theming, forms, and storage abstractions.
- Kept the public foundations independently importable so applications can adopt Sixplace incrementally without changing their state-management, routing, persistence, or domain architecture.
- Added a collapsible `AI prompt` section to `README.md` that gives AI coding assistants a structured Sixplace 1.0.0 architecture and migration context for fresh projects and existing Flutter applications.
- Added `SPRoom`, a Room-inspired structured SQLite persistence layer under the storage foundation, powered by the sqflite ecosystem.
- Added declarative entity schemas, typed entity adapters, generic/subclassable DAOs, single/bulk CRUD/upsert/query APIs, explicit migrations, Room-style transaction aliases, transaction-aware DAO execution, schema validation/identity checks, reactive invalidation streams, in-memory builders, and sqflite-compatible factory injection.
- Added an SPRoom example and focused database tests covering CRUD, transactions, invalidation, migration and schema preservation.
- Isolated SPRoom transaction contexts between database instances and validated `WITHOUT ROWID` integer primary keys, with rollback and missing-migration preservation tests.
- Corrected theme-extension preservation and form test setup, and kept the main example compact with an offline HTTP transport.
- Added acknowledgements thanking AndroidX Room (Kotlin/Android Room) for the Database/Entity/DAO/Migration/Transaction architecture inspiration and sqflite for the underlying SQLite ecosystem.

### Package quality and compatibility

- Targets Dart `>=3.9.0 <4.0.0` and Flutter `>=3.35.0`.
- Keeps Sixplace core APIs compatible across Android, iOS, Linux, macOS, web, and Windows; SPRoom uses sqflite automatically on Android/iOS/macOS and accepts an injected sqflite-compatible factory on Linux/Windows/web.
- Keeps runtime dependencies focused on Flutter, `http`, `http_parser`, `sqflite`, and `sqflite_common`.
- Retains focused examples, tests, API documentation, publication checks, and `pana` guidance for pub.dev quality validation.

## 0.0.5

### Added

- Added the `SPFeedback` foundation with cross-platform toast-like/transient messages,
  alert dialogs, route-specific blocking loader handles and an embeddable loader.
- Added the `SPTheme` foundation with light/dark theme factories, semantic color
  tokens, spacing tokens, radius tokens, typography tokens and `BuildContext` accessors.
- Added the `SPForms` foundation with validators, guarded form submission, text,
  dropdown and checkbox fields, and a submission-aware button.
- Added the `SPStorage` foundation with preference and secure-store interfaces,
  in-memory implementations for tests/session data, and a bounded TTL/LRU cache.
- Added focused tests for feedback, theme, forms and storage foundations.
- Added standalone public entry points: `feedback.dart`, `theme.dart`,
  `forms.dart`, and `storage.dart`.

### Changed

- `sixplace.dart` now exports all six foundations.
- Updated the package documentation and foundation matrix so all six foundations
  are documented as available.
- Updated the network configuration documentation to clarify that Sixplace does
  not retry writes, while an injected custom transport may implement its own
  replay behavior.
- Updated `flutter_lints` to `^6.0.0` and the test constraint to remain compatible
  with supported and latest stable Dart/Flutter toolchains.
- Added pub.dev topics and corrected the changelog history so the published
  `0.0.4` release is represented by its own heading.

### Platform support

- The new foundations use Flutter/Dart APIs only and do not import `dart:io` or
  `dart:html`, preserving Android, iOS, Linux, macOS, web and Windows support.
- `SPStorage` intentionally uses injectable persistence abstractions instead of
  imposing a platform plugin, so applications can choose the storage provider
  appropriate for their deployment.

## 0.0.4

### Added

- Added the `SPNetwork` foundation with shared initialization and independent,
  injectable clients. Network initialization is separate from `SixPlaceScope`.
- Added GET, POST, PUT, PATCH, DELETE and HEAD helpers, typed model decoding,
  JSON/text/byte responses and byte-backed multipart uploads for native and web.
- Added runtime-validated backend configuration, query merging, header
  overrides, dynamic bearer-token providers and an app-owned unauthorized hook.
- Added typed `SPNetworkException` failures, response status/header access,
  empty-response handling and preserved backend validation details.
- Added bounded GET/HEAD retries with Retry-After support, full-response
  per-attempt deadlines, cancellation, client shutdown and a response size limit.
- Added credential-safe relative endpoint resolution, disabled automatic
  redirects, metadata-only opt-in logs and once-per-session 401 callbacks.
- Added network tests and a runnable, offline network demo entry point.
- Added `isDeviceOnline()` for one-attempt, unauthenticated backend reachability checks.

### Dependencies and compatibility

- Added `http` and `http_parser` runtime dependencies; application code uses
  Sixplace's API, while these packages provide transport and HTTP parsing.
- Added `test` as a development dependency for pure-Dart networking tests.
- Existing layout and numeric-sizing source behavior is unchanged. The earlier
  capped-scaling proposal is not implemented by this network update.
- No GetX, storage, navigation, toast, connectivity plugin or token-refresh
  implementation is imposed on consuming applications.

## 0.0.3

### Added

- Added design-scaled numeric sizing helpers through `.w`, `.h`, `.sp`,
  `.rem`, and `.em(context)`.
- Added shared Sixplace initialization with `SixPlace.init(context, ...)` and
  `SixPlaceScope` for design-size and root-font configuration.
- Added support for context-free numeric sizing and typography metrics that
  respond to viewport resize and `TextScaler` updates.
- Added `SixPlaceMetrics` for validation, design scaling, and root-relative
  typography calculations.
- Added numeric sizing and typography examples to the sample app.
- Added focused tests for initialization, design scaling, root-relative sizing,
  and parent-relative `em` resolution.

### Changed

- The root package now exposes both the original responsive layout API and the
  numeric sizing/typography helpers.
- User-facing documentation clarifies the distinction between breakpoint-based
  layout design and design-draft scaling.

## 0.0.2

### Added

- Added `SPResponsive` for centralized viewport-responsive information.
- Added the `context.sp` extension for convenient access to:
  - Current viewport width.
  - Current viewport height.
  - Active breakpoint.
  - Mobile detection.
  - Tablet detection.
  - Desktop detection.
  - Large-desktop detection.
  - Minimum-breakpoint checks.
  - Below-breakpoint checks.
- Added `SPResponsiveValue.resolveFrom(context)` to resolve responsive values
  without manually reading `MediaQuery`.
- Added `SPResponsiveSizedBox`.
- Added automatic responsive width resolution.
- Added automatic responsive height resolution.
- Added nullable responsive size support.
- Added responsive container padding through
  `SPContainer.responsivePadding`.
- Added responsive row gaps through `SPRow.responsiveGap`.
- Added tests for:
  - Viewport classifications.
  - Breakpoint helper methods.
  - Custom breakpoint resolution.
  - Nullable responsive values.
  - `context.sp`.
  - `resolveFrom(context)`.
  - Responsive width and height.
  - Responsive container padding.
  - Responsive row gaps.
  - Static axis-gap precedence.

### Improved

- Reduced application-level `MediaQuery` boilerplate.
- Improved support for responsive charts, dashboards, tables, and other
  size-sensitive widgets.
- Clarified the distinction between viewport-responsive and
  parent-width-responsive behavior.
- Improved API documentation and real-world examples.
- Expanded documentation for:
  - Breakpoints.
  - Responsive values.
  - Responsive sizing.
  - Responsive spacing.
  - Column offsets.
  - Visual ordering.
  - Visibility.
  - Application shells.
  - Custom breakpoints.
  - Performance.
  - Migration from `0.0.1`.

### Compatibility

- This release is backward-compatible with `0.0.1`.
- Existing `SPRow`, `SPCol`, `SPContainer`, `SPResponsiveValue`,
  `SPPadding`, `SPMargin`, `SPVisibility`, `SPAppBar`, and `SPScaffold`
  usage remains supported.
- Existing static `SPRow.gap`, `horizontalGap`, and `verticalGap` behavior
  remains supported.
- Existing static `SPContainer.padding` behavior remains supported.
- No migration is required for existing applications.

## 0.0.1

### Added

- Initial release of Sixplace.
- Added the mobile-first responsive layout foundation.
- Added Bootstrap-inspired 12-column grid behavior.
- Added six default responsive breakpoints:
  - `xs`
  - `sm`
  - `md`
  - `lg`
  - `xl`
  - `xxl`
- Added customizable breakpoint definitions through `SPBreakpoints`.
- Added responsive value inheritance through `SPResponsiveValue<T>`.
- Added responsive column specifications through `SPColumnSpec`.
- Added `SPRow`.
- Added `SPCol`.
- Added responsive column spans.
- Added responsive column offsets.
- Added responsive visual ordering.
- Added fixed and fluid `SPContainer` layouts.
- Added configurable row gutters.
- Added `SPPadding`.
- Added `SPMargin`.
- Added `SPVisibility`.
- Added the platform-adaptive `SPAppBar`.
- Added the responsive `SPScaffold`.
- Added permanent desktop drawer support.
- Added permanent end-drawer support.
- Added tablet navigation-rail support.
- Added responsive bottom-navigation visibility.
- Added nested-grid support using immediate parent width.
- Added initial breakpoint and responsive-row test coverage.
