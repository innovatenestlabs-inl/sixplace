# Sixplace

Cross-platform Flutter foundations for responsive layout, networking, feedback, themes, forms, storage abstractions, and Room-inspired SQLite persistence.

Sixplace helps Flutter developers build adaptive mobile, tablet, desktop, and web applications with minimal code while avoiding duplicated widget trees.

Its responsive layout system is inspired by the simplicity of Bootstrap's 12-column grid while remaining designed specifically for Flutter.

Sixplace combines six focused foundations: responsive layout, networking, feedback, theming, forms, and storage. The storage foundation now includes `SPRoom`, a Room-inspired structured SQLite layer powered by the sqflite ecosystem. Each foundation remains independently adoptable.

---

## Why Sixplace?

Responsive Flutter applications often contain repeated widget trees:

```dart
if (isMobile) {
  return MobilePage();
}

return DesktopPage();
```

This approach can duplicate:

- UI structure
- State bindings
- Loading and error states
- Navigation behavior
- Business logic
- Maintenance effort

Sixplace allows developers to define one mobile-first widget tree:

```dart
SPRow(
  gap: 16,
  children: [
    SPCol(
      md: 6,
      child: firstCard,
    ),
    SPCol(
      md: 6,
      child: secondCard,
    ),
  ],
)
```

The same layout automatically becomes:

- One column on smaller screens
- Two columns from the `md` breakpoint
- Responsive without separate mobile and desktop pages

---

# Sixplace Foundations

Sixplace is designed around six coordinated application foundations:

| Foundation | Responsibility | Status |
|---|---|---|
| `SPLayout` | Responsive grids, containers, spacing, visibility, sizing and application shell | Available |
| `SPNetwork` | HTTP requests, authentication, retry, cancellation, uploads, typed errors and reachability | Available |
| `SPFeedback` | Transient messages, alerts and blocking/embedded loaders | Available |
| `SPTheme` | Colours, typography integration, spacing, radii and design tokens | Available |
| `SPForms` | Inputs, validation, guarded submission and submit-state UI | Available |
| `SPStorage` | Preference/secure-store abstractions, bounded cache, and `SPRoom` structured SQLite persistence | Available |

All six foundations are part of the current public API. `SPRoom` belongs to the storage foundation and is also independently importable through `package:sixplace/room.dart`.

<details>
<summary><strong>AI prompt</strong> — copy this into an AI coding agent or chat assistant</summary>

```text
You are assisting a Flutter developer who is using Sixplace 1.0.0.

Your job is to understand Sixplace as an application-foundation package and use it correctly when:
- starting a new Flutter project,
- introducing Sixplace into an existing Flutter project,
- migrating duplicated responsive layouts to one responsive widget tree,
- migrating direct HTTP calls to SPNetwork,
- standardizing feedback, theme tokens, forms, and storage abstractions,
- reviewing or refactoring code that already uses Sixplace,
- or planning a gradual migration without forcing unrelated architectural changes.

Treat the information below as the working contract for Sixplace 1.0.0. If the installed package source or current official Sixplace documentation conflicts with this prompt, the installed package/API is the source of truth. Do not invent Sixplace APIs that are not documented or present in the package.

PACKAGE IDENTITY
================
Package: sixplace
Stable version: 1.0.0
Flutter package: yes
Dart SDK constraint: >=3.9.0 <4.0.0
Flutter constraint: >=3.35.0
Primary platforms: Android, iOS, Linux, macOS, web, Windows
License: MIT
Repository: https://github.com/innovatenestlabs-inl/sixplace

Runtime dependencies are intentionally small and focused:
- flutter (SDK)
- http
- http_parser
- sqflite
- sqflite_common

Sixplace is not a state-management framework and does not require GetX, Riverpod, Bloc, Provider, or another state manager. It also does not own application routing, business rules, domain models, authentication state, or a platform secure-storage plugin. For structured local relational persistence it provides the optional SPRoom layer; applications still own their entities, schema design, migrations, data-retention rules, and encryption decisions.

PUBLIC IMPORTS
==============
Use the complete API when broad access is appropriate:

import 'package:sixplace/sixplace.dart';

Or import focused foundations:

import 'package:sixplace/layout.dart';
import 'package:sixplace/network.dart';
import 'package:sixplace/feedback.dart';
import 'package:sixplace/theme.dart';
import 'package:sixplace/forms.dart';
import 'package:sixplace/storage.dart';
import 'package:sixplace/room.dart';

Numeric design-scaling helpers are also available through:

import 'package:sixplace/sixplace_numeric.dart';

ARCHITECTURAL PRINCIPLE
=======================
Sixplace has six coordinated but independently adoptable foundations:

1. SPLayout   - responsive layout, grid, spacing, visibility, adaptive shell
2. SPNetwork  - UI-independent HTTP client and transport behavior
3. SPFeedback - messages, dialogs, blocking/embedded loaders
4. SPTheme    - Material themes and semantic design tokens
5. SPForms    - validators, common form fields, guarded submission
6. SPStorage  - preference/secure-store contracts, bounded cache, and SPRoom SQLite persistence

A project does not need to migrate all six foundations at once. Prefer incremental adoption. Do not rewrite working business logic merely to use Sixplace.

============================================================
1. SPLAYOUT
============================================================

PURPOSE
-------
Use SPLayout to build mobile-first responsive Flutter interfaces without maintaining separate mobile/tablet/desktop page trees.

Default breakpoints are Bootstrap-inspired:
- xs: 0+
- sm: 576+
- md: 768+
- lg: 992+
- xl: 1200+
- xxl: 1400+

Responsive values inherit forward from smaller breakpoints until overridden.

Example:

SPCol(
  sm: 6,
  lg: 4,
  child: content,
)

means:
- xs: 12 columns by default
- sm/md: 6 columns
- lg/xl/xxl: 4 columns

KEY LAYOUT TYPES
----------------
- SPBreakpoint
- SPBreakpoints
- SPResponsiveValue<T>
- SPResponsive
- context.sp
- SPContainer
- SPRow
- SPCol
- SPResponsiveSizedBox
- SPPadding
- SPMargin
- SPVisibility
- SPAppBar
- SPScaffold

CORE PATTERN
------------
Prefer one widget tree:

SPRow(
  gap: 16,
  children: [
    SPCol(
      md: 6,
      child: firstCard,
    ),
    SPCol(
      md: 6,
      child: secondCard,
    ),
  ],
)

Avoid creating a full MobilePage and DesktopPage when only structure or sizing changes. Use responsive spans, values, visibility, ordering, padding, and scaffold behavior instead.

RESOLUTION SEMANTICS
--------------------
This distinction is important:

Viewport-based:
- context.sp
- SPResponsiveValue.resolveFrom(context)
- SPResponsiveSizedBox
- SPPadding
- SPMargin
- SPVisibility
- SPScaffold

Immediate-parent-width based:
- SPContainer
- SPRow
- SPCol inside SPRow

This lets nested grids respond to their actual container width while screen-level decisions still use viewport width.

SPResponsiveValue<T> example:

const spacing = SPResponsiveValue<double>(
  base: 8,
  md: 16,
  xl: 24,
);

Missing values inherit from the nearest smaller configured breakpoint.

VIEWPORT INFORMATION
--------------------
Use:

final responsive = context.sp;

Common properties include:
- width
- height
- breakpoint
- isMobile (xs/sm)
- isTablet (md)
- isDesktop (lg+)
- isLargeDesktop (xxl+)
- atLeast(...)
- below(...)

APPLICATION SHELL
-----------------
SPScaffold can coordinate:
- normal mobile drawer,
- permanent desktop drawer,
- tablet navigation rail,
- responsive bottom navigation visibility,
- SPAppBar.

Use SPAppBar for a platform-adaptive app bar with iOS-aware presentation, automatic back handling, dark-mode-aware colors, and optional drawer action behavior.

CUSTOM BREAKPOINTS
------------------
SPBreakpoints can be customized. Keep breakpoints strictly increasing. When migrating an existing app with established breakpoints, prefer configuring Sixplace to match the existing design system rather than arbitrarily changing layout thresholds.

============================================================
NUMERIC DESIGN SCALING (RELATED CORE API)
============================================================

Sixplace also provides numeric design-draft helpers:
- value.w   -> width scaling
- value.h   -> height scaling
- value.sp  -> font scaling with system text scaling
- value.rem -> root-font-relative scaling
- value.em(context) -> inherited/parent-font-relative scaling

These helpers require SixPlace metrics initialization.

Default design size: 390 x 844
Default root font size: 16

Initialize from a valid MediaQuery context using SixPlace.init(...), or wrap the relevant subtree with SixPlaceScope.

Example concept:

SixPlaceScope(
  designSize: const Size(390, 844),
  rootFontSize: 16,
  child: appContent,
)

Do not confuse numeric design scaling with breakpoint-responsive layout. Use breakpoints for structural decisions; use numeric scaling only where design-draft proportional sizing is genuinely desired.

SPNetwork does not require SixPlace.init or SixPlaceScope.

============================================================
2. SPNETWORK
============================================================

PURPOSE
-------
SPNetwork is a persistent, UI-independent HTTP layer. It wraps package:http behavior while keeping storage, navigation, UI feedback, and business rules owned by the application.

SHARED INITIALIZATION
---------------------
Initialize a shared client once, normally during application startup:

SPNetwork.init(
  config: SPNetworkConfig(
    baseUrl: 'https://api.example.com/api/v1/',
    timeout: const Duration(seconds: 30),
    retryPolicy: SPRetryPolicy(maxAttempts: 3),
  ),
);

Then reuse:

final api = SPNetwork.instance;

SPNetwork.init throws if called again while the shared client is still active. Closing the shared client allows future initialization.

INDEPENDENT CLIENTS
-------------------
For multiple backends create separate clients:

final reportingApi = SPNetwork(
  config: SPNetworkConfig(
    baseUrl: 'https://reports.example.com/api/',
  ),
);

Reuse clients. Do not create one SPNetwork instance per request. Call close() only when the owner is permanently disposed.

CONFIGURATION
-------------
SPNetworkConfig supports concepts including:
- validated absolute HTTP(S) baseUrl,
- default headers,
- per-attempt timeout,
- SPRetryPolicy,
- tokenProvider,
- onUnauthorized callback,
- metadata-only logger,
- maxResponseBytes.

The base URL must not contain credentials, query parameters, or a fragment. Sixplace normalizes it as a directory-style base URL so relative endpoints preserve the configured path prefix.

REQUEST METHODS
---------------
SPNetwork supports:
- get
- post
- put
- patch
- delete
- head
- request
- upload
- isDeviceOnline

JSON request bodies are encoded by Sixplace. Pass Dart JSON-compatible objects. Do not jsonEncode the request body before passing it to SPNetwork.

Example:

final response = await SPNetwork.instance.post<Map<String, dynamic>>(
  'customers',
  body: {
    'name': 'Example Customer',
  },
);

TYPED DECODING
--------------
Use a decoder when mapping a successful decoded response to a model:

final response = await SPNetwork.instance.get<Customer>(
  'customers/42',
  decoder: (body) => Customer.fromJson(
    body! as Map<String, dynamic>,
  ),
);

SPNetworkResponse<T> exposes the decoded data plus statusCode, headers, bodyBytes, URI, and attempt count.

PER-REQUEST OPTIONS
-------------------
SPRequestOptions can override:
- headers,
- authenticated behavior,
- bearer token,
- timeout,
- retry policy,
- response type,
- cancellation token.

SPResponseType supports JSON, text, and raw bytes.

AUTHENTICATION
--------------
Prefer tokenProvider for current bearer-token lookup. The provider is evaluated at call time, so newly stored tokens are used without recreating the client.

For public/login requests use authenticated: false. This removes Authorization handling for that request and skips the authenticated 401 callback behavior.

The application owns token persistence and refresh/login policy. Sixplace does not decide where tokens are stored.

UNAUTHORIZED HANDLING
---------------------
An authenticated 401 can trigger the configured onUnauthorized callback once for the current auth session. After a successful login, call resetUnauthorizedState() so a future authenticated 401 can trigger the callback again.

The application owns navigation, session cleanup, user messaging, and re-authentication.

RETRIES
-------
Sixplace automatically retries only GET and HEAD according to SPRetryPolicy.

Writes are intentionally not automatically replayed by Sixplace:
- POST: one attempt
- PUT: one attempt
- PATCH: one attempt
- DELETE: one attempt
- multipart write: one attempt

This protects transactional operations from accidental duplicate writes.

A custom injected HTTP client may have its own replay policy; if one is injected, review that transport independently.

SPRetryPolicy.maxAttempts includes the first attempt. Default retryable statuses include 408, 429, 502, 503, and 504. 401 and 403 are not retry statuses.

For critical write operations such as orders, payments, invoices, or POS sales, pair client-side duplicate-submit protection with backend idempotency.

CANCELLATION
------------
Use SPCancelToken to cancel one request or multiple requests sharing the token. Cancellation is permanent; create a new token for a new operation.

UPLOADS
-------
SPUploadFile is byte-backed and works across native and web without requiring dart:io File. Read/pick bytes in application code and pass them to SPUploadFile. Upload supports POST, PUT, and PATCH.

Large streaming uploads/downloads are outside the buffered initial API. Respect maxResponseBytes when downloading files.

ERRORS
------
Catch SPNetworkException and branch on SPNetworkErrorType rather than parsing text.

Error types include:
- http
- authentication
- timeout
- connection
- cancelled
- decoding
- responseTooLarge

Potentially sensitive fields such as URI, headers, body, and underlying cause are available on the exception for controlled handling, but SPNetworkException.toString intentionally avoids exposing those values. Do not blindly log sensitive exception fields.

REACHABILITY
------------
isDeviceOnline() is a backend reachability probe, not a guarantee that the backend is healthy.

It performs an unauthenticated single-attempt HEAD request with no automatic retry. Any received HTTP response, including 401/404/500/503, proves the network path/server answered and therefore counts as reachable. DNS, socket, TLS/transport failure, or timeout returns false.

Do not call isDeviceOnline() before every write. A preflight request introduces a race condition and extra traffic. Normally send the real request and handle its typed result.

REQUEST LIFECYCLE GUIDANCE
--------------------------
Do not start network calls directly in build(). Cache futures where FutureBuilder is used. Reuse SPNetwork clients. Guard submit buttons. Keep token providers lightweight.

============================================================
3. SPFEEDBACK
============================================================

PURPOSE
-------
SPFeedback provides framework-native user feedback without requiring a router or state manager.

Key APIs:
- SPFeedback.showToast
- SPFeedback.showMessage
- SPFeedback.showAlert
- SPFeedback.showLoading
- SPBlockingLoader
- SPFeedbackLoaderHandle
- SPFeedbackType
- SPFeedbackStyle

Semantic feedback types:
- info
- success
- warning
- error

Messages use ScaffoldMessenger, so call them from a context that has the required Flutter ancestors.

Example:

SPFeedback.showMessage(
  context,
  'Saved successfully.',
  type: SPFeedbackType.success,
);

Alerts return a nullable bool so the caller can distinguish confirm, explicit cancel, and external dismissal.

Blocking loader example:

final loader = SPFeedback.showLoading(
  context,
  message: 'Saving...',
);
try {
  await save();
} finally {
  loader.close();
}

The loader handle closes only the route it created. It must not be replaced with a generic Navigator.pop that could close an unrelated route.

Use SPBlockingLoader when an inline/embedded loading surface is better than a modal route.

============================================================
4. SPTHEME
============================================================

PURPOSE
-------
SPTheme creates Material themes and installs Sixplace semantic tokens through Flutter ThemeExtension.

Key APIs:
- SPTheme.light
- SPTheme.dark
- SPTheme.withTokens
- SPThemeTokens
- SPSpacingTokens
- SPRadiusTokens
- SPTypographyTokens
- context.spTheme
- context.spSpacing
- context.spRadius
- context.spTypography

Example:

MaterialApp(
  theme: SPTheme.light(
    seedColor: const Color(0xFF5B5BD6),
  ),
  darkTheme: SPTheme.dark(
    seedColor: const Color(0xFF5B5BD6),
  ),
  home: const HomePage(),
)

Use SPTheme.withTokens(existingTheme) when the app already has a carefully configured ThemeData and only Sixplace tokens should be installed. This is preferable during migration because it avoids replacing unrelated theme configuration.

Tokens include semantic colors plus spacing, radius, and typography scales. Theme accessors have a ColorScheme-based fallback if tokens are not explicitly installed, but installing them intentionally is preferred for a consistent design system.

============================================================
5. SPFORMS
============================================================

PURPOSE
-------
SPForms provides common validators, Material form inputs, and guarded asynchronous submission. It does not impose a state-management framework.

Key APIs:
- SPValidators
- SPFormController
- SPTextFormField
- SPDropdownFormField<T>
- SPCheckboxFormField
- SPSubmitButton

Built-in validators include:
- required
- email
- minLength
- maxLength
- pattern
- minNumber
- maxNumber
- compose

Typical pattern:

final formKey = GlobalKey<FormState>();
final formController = SPFormController();

Future<void> save() async {
  await formController.submit<void>(
    formKey: formKey,
    context: context,
    action: () async {
      await SPNetwork.instance.post(
        'customers',
        body: buildPayload(),
      );
    },
  );
}

SPSubmitButton can observe the controller and prevent repeated user submission while the operation is running.

Dispose SPFormController when it is owned by a State object.

Guarding the UI is not a substitute for server-side idempotency on transactions that must never execute twice.

============================================================
6. SPSTORAGE + SPROOM
============================================================

PURPOSE
-------
SPStorage defines stable preference/secure-store interfaces without forcing a key/value or secure-storage plugin on all consumers. The same storage foundation also includes SPRoom for structured relational SQLite data.

Key APIs:
- SPPreferencesStore
- SPSecureStore
- SPMemoryPreferencesStore
- SPMemorySecureStore
- SPStorageCache
- SPStorage

Applications should adapt their chosen persistence libraries to:

SPPreferencesStore
- read
- write
- containsKey
- remove
- clear

SPSecureStore
- read
- write
- containsKey
- remove
- clear

Preference values are intentionally restricted to common primitive preference types:
- String
- bool
- int
- double
- List<String>

SPMemoryPreferencesStore and SPMemorySecureStore are useful for tests, previews, and ephemeral sessions. SPMemorySecureStore is not encrypted persistent secure storage and must never be described as equivalent to an OS-backed secure store.

SPStorageCache is a bounded in-process LRU-style cache with optional TTL expiration. It does not run a background polling timer. Expiration is handled lazily during cache access, and least-recently-used entries are evicted when capacity is exceeded.


SPROOM
------
SPRoom is Sixplace's Room-inspired SQLite persistence layer. It is intentionally modeled after the mental model used by AndroidX Room in Kotlin projects:
- database class / central database access point,
- entities/tables,
- DAOs,
- explicit schema versions,
- explicit migrations,
- transactions,
- conflict strategies,
- typed entity adapters,
- reactive query invalidation.

SPRoom uses the sqflite ecosystem underneath. On Android, iOS, and macOS the default factory comes from package:sqflite. On Linux, Windows, and web, inject a compatible DatabaseFactory from the sqflite ecosystem (for example sqflite_common_ffi on desktop or a compatible web factory) instead of assuming the mobile plugin exists.

Focused import:

import 'package:sixplace/room.dart';

Core SPRoom types:
- SPRoom
- SPRoomDatabaseBuilder<T>
- SPRoomDatabase
- SPRoomEntitySchema
- SPRoomColumn
- SPRoomIndex
- SPRoomForeignKey
- SPRoomEntityAdapter<T>
- SPRoomDao<T>
- SPRoomMigration
- SPRoomExecutor
- SPRoomInvalidationTracker
- SPRoomConflictStrategy
- SPRoomTypeConverter<T, D>

Typical architecture:

class AppDatabase extends SPRoomDatabase {
  late final UserDao users = UserDao(this);
}

class UserDao extends SPRoomDao<User> {
  UserDao(SPRoomDatabase database) : super(database, UserAdapter());
}

final db = await SPRoom.databaseBuilder<AppDatabase>(
  name: 'app.db',
  version: 1,
  create: AppDatabase.new,
  entities: const [userSchema],
).build();

Entity schemas are explicit rather than annotation-generated. Flutter/Dart does not provide Kotlin KSP semantics at runtime, so do NOT invent @Entity/@Dao annotations or claim compile-time SQL verification exists. SPRoom aims for Room-like runtime behavior and architecture while keeping the Dart API explicit, tree-shakeable, and predictable.

Entity adapter responsibilities:
- schema: declares the table schema,
- toRow(entity): maps a Dart model to SQLite-compatible values,
- fromRow(row): maps a database row back to the Dart model,
- primaryKeyOf(entity): defaults to reading declared PK fields from toRow and can be overridden.

SPRoomDao provides:
- insert / insertAll,
- upsert / upsertAll using SQLite ON CONFLICT DO UPDATE,
- update / updateAll,
- delete / deleteAll / deleteWhere,
- getAll / query,
- findById / findByPrimaryKey,
- count,
- typed rawQuery,
- rawWrite with invalidation,
- watch / watchRawQuery reactive streams.

Transaction rule:

await db.withTransaction(() async {
  await db.users.insert(user);
  await db.audit.insert(entry);
});

DAO calls inside `writeTransaction`, `withTransaction`, or `runInTransaction` automatically reuse the active sqflite transaction. Do not manually use the outer database connection from inside a transaction callback.

Migrations are explicit:

SPRoomMigration(1, 2, (db) async {
  await db.execute('ALTER TABLE users ADD COLUMN nickname TEXT');
});

Register them through addMigrations(...). If a path is missing, opening fails by default. fallbackToDestructiveMigration() is opt-in because it destroys managed data.

Schema validation is enabled by default. SPRoom checks managed table structure and explicit indexes after creation/migration/open and keeps a schema identity marker. A schema change must therefore be paired with a version bump and migration. Do not silently edit the schema while keeping the same version.

Reactive queries:

final stream = db.users.watch(orderBy: 'name');

Writes made through SPRoomDao invalidate the relevant table automatically. If custom SQL writes bypass a DAO, use db.rawWrite(...) or db.notifyTablesChanged(...) so watchers refresh. Writes from completely separate SQLite connections cannot be automatically observed by this in-process tracker.

Security and durability:
- SPRoom is SQLite persistence, not encrypted storage.
- Do not store secrets merely because the database is local.
- Use an encryption strategy appropriate to the application when at-rest confidentiality is required.
- Keep migrations tested with production-like data.
- Prefer one long-lived database instance per app process, matching Room/sqflite guidance.
- Close databases intentionally in tests/tools; normal app lifecycles usually keep the singleton open.

Do not claim SPRoom is the AndroidX Room implementation. It is an independent Dart/Flutter API inspired by Room's architecture and powered by sqflite. Room's compile-time KSP query verification and generated DAO implementations are not reproduced by Sixplace 1.0.0.

SECURITY BOUNDARIES
===================
Do not claim Sixplace provides security properties it does not own.

Sixplace does NOT automatically provide:
- encrypted persistent storage,
- OAuth/OIDC implementation,
- token refresh flows,
- certificate pinning,
- application authorization rules,
- database encryption,
- route guards,
- backend idempotency,
- connectivity guarantees,
- automatic safe replay of write requests.

Use SPStorage abstractions with an appropriate secure-storage adapter where secrets must persist. Keep authentication and authorization decisions in application/backend code.

NEW PROJECT GUIDANCE
====================
When starting a fresh Flutter project with Sixplace:

1. Add sixplace to pubspec.
2. Choose focused imports or package:sixplace/sixplace.dart.
3. Establish the app ThemeData using SPTheme or install tokens into the existing theme.
4. Decide whether numeric design scaling is actually needed; if yes, initialize SixPlace metrics from a MediaQuery context.
5. Build pages mobile-first with SPContainer, SPRow, SPCol, SPResponsiveValue, and SPScaffold.
6. Initialize SPNetwork once per backend, with application-owned token/session callbacks.
7. Use SPForms for common input/submit patterns where helpful.
8. Use SPFeedback for user-facing transient messages, alerts, and loaders.
9. Provide real persistence adapters to SPStorage when key/value data must survive restarts; use memory stores only where ephemeral behavior is intended.
10. Use SPRoom when the app needs structured relational SQLite data, and define versioned migrations before shipping schema changes.
11. Keep business/domain logic independent from presentation helpers.

EXISTING PROJECT MIGRATION GUIDANCE
===================================
When migrating an existing app, first audit before editing:

A. Responsive UI
- Find duplicated mobile/tablet/desktop widget trees.
- Identify existing breakpoints and parent-width constraints.
- Migrate page sections incrementally to SPRow/SPCol/SPResponsiveValue.
- Preserve state, controllers, and business logic while replacing only layout duplication.
- Use custom SPBreakpoints if the existing product already has established thresholds.

B. Networking
- Inventory direct http calls and any current client wrapper/interceptors.
- Identify token lookup, 401 handling, retry behavior, timeout behavior, multipart behavior, logging, and response decoding.
- Do not blindly replace a mature networking layer. Map each existing behavior to SPNetwork and keep app-specific requirements outside the package.
- Never introduce automatic replay of writes during migration.
- Use independent SPNetwork clients for genuinely different backends/origins.

C. Theme
- Preserve existing ThemeData and install Sixplace tokens with SPTheme.withTokens when a full theme replacement is unnecessary.

D. Forms
- Replace repeated validator/submit boilerplate where it improves consistency, without rewriting domain validation that belongs elsewhere.

E. Storage
- Wrap existing SharedPreferences/secure-storage implementations with Sixplace interfaces rather than replacing proven key/value persistence mechanisms solely for package conformity.
- If an existing app already uses SQLite/sqflite, migrate incrementally: model the existing tables with SPRoomEntitySchema, create adapters/DAOs around the current schema, keep the existing database version, then add explicit SPRoomMigration steps for future changes. Never drop or recreate production tables simply to adopt SPRoom.

F. Feedback
- Migrate messages/dialogs/loaders where consistent cross-platform Flutter-native behavior is desired. Preserve app-specific navigation and error policy.

MIGRATION SAFETY RULES
======================
- Do not change business behavior just to reduce line count.
- Do not introduce duplicate widget trees when responsive primitives can solve the layout.
- Do not start API calls in build().
- Do not create an SPNetwork client per request.
- Do not pre-jsonEncode request bodies for SPNetwork JSON calls.
- Do not automatically retry transactional writes.
- Do not treat isDeviceOnline() as proof that the backend is healthy.
- Do not log tokens, authorization headers, private bodies, or sensitive exception details.
- Do not represent SPMemorySecureStore as encrypted persistent storage.
- Do not force all six foundations into a project if only some solve a real problem.
- Prefer small, reviewable migration steps with tests after each step.

TESTING EXPECTATIONS
====================
When modifying a project that uses Sixplace:
- preserve existing tests,
- add tests for changed responsive behavior,
- test network success and typed failures,
- test guarded submission for transactional UI,
- test custom storage adapters,
- verify mobile/tablet/desktop breakpoints,
- verify web behavior when network or file-upload code changes.

For the Sixplace package itself, expected validation includes:
- dart format with no changes required,
- flutter analyze with no issues,
- flutter test passing,
- dependency freshness reviewed,
- pub publish dry-run with no unexpected files/warnings,
- pana review before a public release.

HOW TO ANSWER THE DEVELOPER
===========================
When the developer asks for help:

1. Identify whether the task belongs to layout, network, feedback, theme, forms, storage, numeric scaling, or application-specific code.
2. Prefer the narrowest Sixplace foundation that solves the problem.
3. Explain what Sixplace owns and what the consuming app must still own.
4. Produce compile-oriented Flutter/Dart examples using real Sixplace 1.0.0 APIs only.
5. For migration requests, first describe the current-to-target mapping and compatibility risks, then provide the implementation steps/code.
6. For architecture requests, preserve existing state management unless the developer explicitly asks to change it.
7. For network writes, prioritize duplicate-write safety and backend idempotency.
8. For responsive work, prefer one mobile-first widget tree and use parent-width vs viewport-width semantics correctly.
9. If the request depends on an API not described here, inspect the installed Sixplace source/docs before proposing code; do not guess method names.
10. If Sixplace is not the right layer for a requirement, say so and keep that responsibility in the application or backend.

REFERENCE EXAMPLE: RESPONSIVE PAGE
==================================

SPContainer.fluid(
  responsivePadding: const SPResponsiveValue<EdgeInsetsGeometry>(
    base: EdgeInsets.all(8),
    md: EdgeInsets.all(12),
    lg: EdgeInsets.all(16),
  ),
  child: SPRow(
    responsiveGap: const SPResponsiveValue<double>(
      base: 8,
      lg: 16,
    ),
    children: [
      SPCol(
        span: 12,
        lg: 8,
        child: mainContent,
      ),
      SPCol(
        span: 12,
        lg: 4,
        child: sideContent,
      ),
    ],
  ),
)

REFERENCE EXAMPLE: NETWORK + FORM + FEEDBACK
============================================

final formController = SPFormController();

Future<void> submit(BuildContext context) async {
  try {
    final saved = await formController.submit<bool>(
      formKey: formKey,
      context: context,
      action: () async {
        await SPNetwork.instance.post<Map<String, dynamic>>(
          'orders',
          body: buildOrderPayload(),
        );
        return true;
      },
    );

    if (saved == true && context.mounted) {
      SPFeedback.showMessage(
        context,
        'Order saved.',
        type: SPFeedbackType.success,
      );
    }
  } on SPNetworkException catch (error) {
    if (context.mounted) {
      SPFeedback.showMessage(
        context,
        'Unable to save the order (${error.type.name}).',
        type: SPFeedbackType.error,
      );
    }
  }
}

FINAL MENTAL MODEL
==================
Sixplace should reduce repeated application plumbing while leaving application ownership clear:

- SPLayout structures responsive UI.
- SPNetwork transports requests safely and predictably.
- SPFeedback presents framework-native feedback.
- SPTheme provides consistent Material themes and tokens.
- SPForms reduces repeated validation/submission boilerplate.
- SPStorage supplies persistence contracts and a bounded cache.
- SPRoom supplies Room-inspired SQLite entities, DAOs, migrations, transactions, and reactive invalidation within the storage foundation.

Use Sixplace as a foundation, not as a replacement for domain architecture.
```

</details>

---

# Installation

Add Sixplace to your Flutter project:

```bash
flutter pub add sixplace
```

When using FVM:

```bash
fvm flutter pub add sixplace
```

Or add it manually:

```yaml
dependencies:
  sixplace: ^1.0.0
```

For local package development:

```yaml
dependencies:
  sixplace:
    path: ../sixplace
```

Import the complete public API:

```dart
import 'package:sixplace/sixplace.dart';
```

Or import only the layout API:

```dart
import 'package:sixplace/layout.dart';
```

Or import a single foundation:

```dart
import 'package:sixplace/network.dart';
import 'package:sixplace/feedback.dart';
import 'package:sixplace/theme.dart';
import 'package:sixplace/forms.dart';
import 'package:sixplace/storage.dart';
import 'package:sixplace/room.dart';
```

---

# SPNetwork

`SPNetwork` is Sixplace's UI-independent networking foundation.

Applications can use Sixplace instead of directly calling `http.get`, `http.post`, and related transport APIs throughout the application.

Internally, Sixplace uses `package:http` for native/browser transport and `http_parser` for MIME types and HTTP date handling.

`SPNetwork` does not depend on:

- `BuildContext`
- GetX
- Riverpod
- Bloc
- Provider
- Secure-storage packages
- Navigation packages
- Toast packages

Your application remains responsible for storage, navigation, UI messages, business rules, and state management.

---

## Initialize Once

Initialize the shared client before `runApp()`:

```dart
import 'package:flutter/material.dart';
import 'package:sixplace/network.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SPNetwork.init(
    config: SPNetworkConfig(
      baseUrl: 'https://your-api.example/api/v2/',
      timeout: const Duration(seconds: 30),
      retryPolicy: SPRetryPolicy(
        maxAttempts: 3,
      ),
    ),
  );

  runApp(const MyApp());
}
```

Replace the example URL with your real API.

If your `tokenProvider` depends on plugin-backed storage, initialize that storage before calling `SPNetwork.init()`.

`SPNetwork` is independent from `SixPlace.init()` and `SixPlaceScope`.

No layout initialization is required for networking.

---

## Shared Client

After initialization:

```dart
final network = SPNetwork.instance;
```

`SPNetwork.instance` throws if `SPNetwork.init()` has not been called.

Calling `SPNetwork.init()` a second time while the shared instance is active also throws instead of silently replacing the existing client.

This prevents accidental creation of multiple shared network clients.

---

## Independent Clients

For applications communicating with more than one backend:

```dart
final primaryApi = SPNetwork(
  config: SPNetworkConfig(
    baseUrl: 'https://api.example.com/v1/',
  ),
);

final reportingApi = SPNetwork(
  config: SPNetworkConfig(
    baseUrl: 'https://reports.example.com/api/',
  ),
);
```

Reuse each client instead of constructing a new client for every request.

When an independently owned client is no longer required:

```dart
primaryApi.close();
```

---

## Client Lifecycle

Sixplace creates and reuses one `http.Client` per `SPNetwork` instance by default.

That allows the underlying transport to reuse persistent HTTP connections efficiently.

Do not create a new `SPNetwork` instance for every API request.

Recommended:

```dart
final api = SPNetwork.instance;

await api.get('products');
await api.get('customers');
await api.post(
  'sales',
  body: sale,
);
```

Avoid:

```dart
await SPNetwork(
  config: config,
).get('products');

await SPNetwork(
  config: config,
).get('customers');
```

Call `close()` only when the owner of the client is being permanently disposed.

```dart
api.close();
```

Closing the shared instance also allows a future `SPNetwork.init()` call to create a new shared client.

---

# JSON Requests

## GET

```dart
final response =
    await SPNetwork.instance.get<Map<String, dynamic>>(
  'products',
  queryParameters: {
    'page': 1,
    'search': 'LED lamp',
  },
);

final data = response.data;
final statusCode = response.statusCode;
```

---

## POST

```dart
final response =
    await SPNetwork.instance.post<Map<String, dynamic>>(
  'products',
  body: {
    'name': 'LED lamp',
    'quantity': 10,
  },
);
```

Pass JSON-compatible objects directly.

Do not call `jsonEncode()` yourself:

```dart
// Correct
body: {
  'name': 'LED lamp',
}

// Avoid
body: jsonEncode({
  'name': 'LED lamp',
})
```

Sixplace performs JSON encoding once.

---

## PUT

```dart
await SPNetwork.instance.put<Map<String, dynamic>>(
  'products/100',
  body: {
    'name': 'Updated LED lamp',
  },
);
```

---

## PATCH

```dart
await SPNetwork.instance.patch<Map<String, dynamic>>(
  'products/100',
  body: {
    'quantity': 20,
  },
);
```

---

## DELETE

```dart
await SPNetwork.instance.delete<Object?>(
  'products/100',
);
```

An optional JSON body is also supported.

---

## HEAD

```dart
final response = await SPNetwork.instance.head(
  'health',
);

print(response.statusCode);
print(response.headers);
```

HEAD responses always return `null` data.

---

# Backend Reachability

Sixplace provides a lightweight reachability check:

```dart
final bool online =
    await SPNetwork.instance.isDeviceOnline();
```

Or specify a dedicated health endpoint:

```dart
final bool online =
    await SPNetwork.instance.isDeviceOnline(
  endpoint: 'health',
);
```

The default timeout is three seconds:

```dart
final bool online =
    await SPNetwork.instance.isDeviceOnline(
  endpoint: 'health',
  timeout: const Duration(seconds: 5),
);
```

## What `isDeviceOnline()` Means

`isDeviceOnline()` checks whether the configured backend can currently be reached.

It performs:

- An unauthenticated `HEAD` request
- One transport attempt
- No automatic retry

A received HTTP response means the backend/network path was reachable.

Therefore responses such as:

```text
200 -> true
204 -> true
401 -> true
404 -> true
500 -> true
503 -> true
```

still return `true`.

Those responses prove that an HTTP server answered.

Failures such as:

- DNS failure
- Socket connection failure
- TLS/transport failure
- Request timeout

return:

```dart
false
```

This method is intentionally a **reachability check**, not a backend-health guarantee.

For example:

```text
HTTP 500
```

means:

```text
Backend reachable: yes
Backend healthy: not necessarily
```

---

## Recommended Health Endpoint

Production applications should preferably expose a lightweight endpoint such as:

```text
HEAD /api/health
```

or:

```text
GET /api/health
```

Then:

```dart
final reachable =
    await SPNetwork.instance.isDeviceOnline(
  endpoint: 'health',
);
```

Using a dedicated endpoint avoids relying on whether the backend supports `HEAD` on its root URL.

---

# Important POS and Transactional Usage

`isDeviceOnline()` should not normally be called before every POST request.

Avoid:

```dart
if (await SPNetwork.instance.isDeviceOnline(
  endpoint: 'health',
)) {
  await SPNetwork.instance.post(
    'sales',
    body: sale.toJson(),
  );
}
```

That intentionally creates two HTTP requests:

```text
HEAD /health
POST /sales
```

For normal transactional operations, send the actual request and handle connection failures:

```dart
try {
  await SPNetwork.instance.post<Object?>(
    'sales',
    body: sale.toJson(),
  );
} on SPNetworkException catch (error) {
  if (error.type == SPNetworkErrorType.connection ||
      error.type == SPNetworkErrorType.timeout) {
    await saveSaleOffline(sale);
    return;
  }

  rethrow;
}
```

Use `isDeviceOnline()` for scenarios such as:

- Showing an online/offline indicator
- User-initiated connectivity checks
- Deciding whether to start offline synchronization
- Checking connectivity when an application resumes
- Checking before a large synchronization operation
- Retrying an offline queue

Remember that connectivity can change immediately after any reachability check.

---

# Typed Models

Sixplace can decode API responses directly into application models.

```dart
class Product {
  const Product(
    this.id,
    this.name,
  );

  final int id;
  final String name;

  factory Product.fromJson(
    Map<String, dynamic> json,
  ) {
    return Product(
      json['id'] as int,
      json['name'] as String,
    );
  }
}
```

Use a decoder:

```dart
Future<Product?> loadProduct(int id) async {
  final response =
      await SPNetwork.instance.get<Product>(
    'products/$id',
    decoder: (json) {
      return Product.fromJson(
        json as Map<String, dynamic>,
      );
    },
  );

  return response.data;
}
```

Sixplace does not require a specific backend response envelope.

If your server returns:

```json
{
  "data": {
    "id": 1,
    "name": "LED lamp"
  }
}
```

unwrap it inside the decoder:

```dart
decoder: (json) {
  final map = json as Map<String, dynamic>;

  return Product.fromJson(
    map['data'] as Map<String, dynamic>,
  );
},
```

Business-level failures returned using HTTP `200` remain application-level business logic.

---

# Endpoint Resolution

Given:

```dart
SPNetworkConfig(
  baseUrl: 'https://api.example.com/api/v2/',
)
```

both:

```dart
'products'
```

and:

```dart
'/products'
```

resolve inside:

```text
https://api.example.com/api/v2/
```

Absolute endpoint URLs are rejected.

For example, this is not allowed:

```dart
await SPNetwork.instance.get(
  'https://other.example.com/products',
);
```

Path traversal is also rejected.

This prevents request endpoints from escaping the configured backend.

---

## Query Parameters

```dart
await SPNetwork.instance.get(
  'products',
  queryParameters: {
    'page': 1,
    'search': 'LED',
    'categoryIds': [1, 2, 3],
    'optional': null,
  },
);
```

Null query values are omitted.

Iterable values are supported.

For dynamic URL path segments, use:

```dart
Uri.encodeComponent(value)
```

where appropriate.

---

# Authentication

## Bearer Token Provider

Applications can supply a token provider:

```dart
SPNetwork.init(
  config: SPNetworkConfig(
    baseUrl: 'https://api.example.com/api/',
    tokenProvider: () async {
      return readAccessToken();
    },
  ),
);
```

The provider is evaluated for authenticated requests.

The token is not permanently captured when `SPNetwork` is initialized.

---

## Keep Token Providers Lightweight

A token provider should normally retrieve an already stored credential.

Recommended:

```dart
tokenProvider: () async {
  return secureStorage.read(
    key: 'access_token',
  );
},
```

Avoid implementing recursive network calls inside `tokenProvider`.

For example, do not make the token provider call the same authenticated API client in order to obtain its own token.

Authentication refresh workflows should be managed explicitly by the consuming application.

---

## Public Requests

Login, registration, password-reset and similar public requests can disable authentication:

```dart
final response =
    await SPNetwork.instance.post<Map<String, dynamic>>(
  'auth/login',
  body: {
    'username': username,
    'password': password,
  },
  options: const SPRequestOptions(
    authenticated: false,
  ),
);
```

After successful login and token storage:

```dart
SPNetwork.instance.resetUnauthorizedState();
```

---

# Unauthorized Session Handling

Configure an unauthorized callback:

```dart
SPNetwork.init(
  config: SPNetworkConfig(
    baseUrl: 'https://api.example.com/api/',
    tokenProvider: readAccessToken,
    onUnauthorized: (error) async {
      await clearAuthSession();
      showLogin();
    },
  ),
);
```

Your application controls:

- Secure storage
- Session removal
- Login navigation
- Toasts/messages
- State reset

Sixplace does not import a navigation or state-management framework.

---

## GetX Example

For example:

```dart
void configureApi({
  required Future<String?> Function() readAccessToken,
  required Future<void> Function() clearAuthSession,
}) {
  SPNetwork.init(
    config: SPNetworkConfig(
      baseUrl: 'https://api.example.com/api/',
      tokenProvider: readAccessToken,
      onUnauthorized: (error) async {
        await clearAuthSession();

        Get.offAllNamed(
          AppRoutes.authLogin,
        );
      },
    ),
  );
}
```

The Sixplace package itself does not depend on GetX.

---

## Authentication Rules

- `authenticated: false` does not call the token provider.
- `authenticated: false` removes the Authorization header.
- `authenticated: false` skips the unauthorized-session callback.
- `options.token` overrides the configured token provider.
- An empty token removes bearer authentication.
- An explicitly supplied Authorization header can override provider behavior when no option token is supplied.
- HTTP `401` triggers `onUnauthorized` only when Authorization was actually sent.
- HTTP `403` is treated as forbidden, not automatically as an expired login.
- Concurrent `401` responses do not repeatedly execute the unauthorized callback.
- `resetUnauthorizedState()` re-arms the callback after successful login or an externally completed refresh.
- A failed request still throws its original typed exception.
- Sixplace does not automatically refresh a token and replay an authenticated write.

---

# Typed Errors

Sixplace exposes failures through `SPNetworkException`.

```dart
try {
  await SPNetwork.instance.get<Object?>(
    'profile',
  );
} on SPNetworkException catch (error) {
  switch (error.type) {
    case SPNetworkErrorType.connection:
      // Unable to reach the backend.
      break;

    case SPNetworkErrorType.timeout:
      // Request deadline exceeded.
      break;

    case SPNetworkErrorType.http:
      // Server returned a non-2xx status.
      break;

    case SPNetworkErrorType.cancelled:
      // Caller cancelled the request.
      break;

    default:
      break;
  }
}
```

Available error categories:

| Type | Meaning |
|---|---|
| `http` | Backend returned a non-2xx HTTP status |
| `authentication` | Token provider failed or did not finish within its deadline |
| `connection` | Transport failure such as DNS, TLS, socket, CORS or connection loss |
| `timeout` | Request/send/body-read deadline expired |
| `cancelled` | Request was cancelled or the network client was closed |
| `decoding` | Successful response could not be decoded |
| `responseTooLarge` | Buffered response exceeded the configured maximum |

For HTTP failures, Sixplace retains information such as:

- Status code
- Response headers
- Decoded JSON error body when valid
- Plain-text error body when JSON is unavailable

Example:

```dart
try {
  await SPNetwork.instance.post<Object?>(
    'orders',
    body: order,
  );
} on SPNetworkException catch (error) {
  if (error.type == SPNetworkErrorType.http &&
      error.statusCode == 422) {
    final validation = error.body;

    // Map backend validation to your UI.
  }
}
```

Malformed HTML/plain-text error pages are not incorrectly reported as JSON decoding errors.

---

# Retry Policy

By default, only `GET` and `HEAD` requests are eligible for automatic Sixplace retries.

| Setting | Default behavior |
|---|---|
| Eligible methods | GET and HEAD |
| Total attempts | 3 |
| Additional retries | Maximum 2 |
| Retryable transport failures | Connection failure and timeout |
| Retryable HTTP statuses | 408, 429, 502, 503, 504 |
| Backoff | 400 ms, then 800 ms |
| Maximum backoff | 5 seconds |
| `Retry-After` | Supported for seconds and HTTP dates |
| Timeout | 30 seconds per attempt by default |
| POST retry | Never by Sixplace |
| PUT retry | Never by Sixplace |
| PATCH retry | Never by Sixplace |
| DELETE retry | Never by Sixplace |
| Upload retry | Never by Sixplace |

The retry count is bounded.

Sixplace does not contain a background retry loop.

---

## Disable Retries Globally

```dart
SPNetwork.init(
  config: SPNetworkConfig(
    baseUrl: 'https://api.example.com/',
    retryPolicy: SPRetryPolicy.none,
  ),
);
```

---

## Disable Retries for One Request

```dart
await SPNetwork.instance.get<Object?>(
  'report',
  options: const SPRequestOptions(
    retryPolicy: SPRetryPolicy.none,
  ),
);
```

---

# Write Request Safety

Sixplace itself does **not automatically retry or replay**:

- POST
- PUT
- PATCH
- DELETE
- Multipart uploads

For these methods, one Sixplace API invocation creates one Sixplace transport send attempt.

Example:

```dart
await SPNetwork.instance.post(
  'sales',
  body: sale,
);
```

Sixplace itself does not transform that call into:

```text
POST
POST
POST
POST
...
```

---

## Important: Injected HTTP Clients

Sixplace allows advanced users to inject a custom `http.Client`:

```dart
final api = SPNetwork(
  config: config,
  client: customClient,
);
```

Sixplace cannot control additional retry/replay behavior implemented internally by that custom client.

For example, a retrying transport can potentially resend a request after Sixplace has handed the request to it.

Therefore:

> Sixplace itself never retries POST, PUT, PATCH, DELETE, or multipart uploads. If you inject a custom `http.Client`, verify that the injected transport does not independently retry or replay transactional write requests.

For strict transactional behavior, prefer the default Sixplace transport unless you fully understand the behavior of the custom transport being injected.

---

# Avoid Accidental Repeated API Calls

A networking package can send only the requests that the application asks it to send.

Repeated application lifecycle calls can therefore create repeated backend requests even when the networking client contains no automatic polling.

## Do Not Start Requests in `build()`

Avoid:

```dart
@override
Widget build(BuildContext context) {
  loadProducts();

  return const ProductPage();
}
```

Flutter can call `build()` many times.

That can unintentionally trigger repeated API traffic.

Instead, start work from an appropriate lifecycle method, controller, event, command, state notifier, or explicitly cached future.

---

## FutureBuilder

Avoid constructing the network Future directly during every rebuild:

```dart
FutureBuilder(
  future: SPNetwork.instance.get(
    'products',
  ),
  builder: ...
)
```

Prefer storing the Future:

```dart
late Future<SPNetworkResponse<Object?>> productsFuture;

@override
void initState() {
  super.initState();

  productsFuture =
      SPNetwork.instance.get<Object?>(
    'products',
  );
}
```

Then:

```dart
FutureBuilder(
  future: productsFuture,
  builder: ...
)
```

The same principle applies to:

- GetX reactive builders
- Bloc builders
- Riverpod providers
- Provider consumers
- Repeated lifecycle callbacks

Do not trigger transactional requests merely because a widget rebuilds.

---

# Prevent Duplicate User Submission

Applications should disable or guard transactional actions while the current operation is in progress.

Example:

```dart
bool submitting = false;

Future<void> submitSale() async {
  if (submitting) {
    return;
  }

  submitting = true;

  try {
    await SPNetwork.instance.post<Object?>(
      'sales',
      body: sale.toJson(),
    );
  } finally {
    submitting = false;
  }
}
```

This prevents repeated taps from creating multiple independent application calls.

This behavior belongs to application/business state, not the network transport.

---

# Transactional Idempotency

Network failures create an important ambiguity.

Consider:

```text
POS                     SERVER

POST /sale  ---------->
                        Sale committed

     connection lost

POS receives timeout
```

The client cannot always know whether the server committed the transaction before the connection disappeared.

A manual retry could therefore create a duplicate transaction.

For important operations such as:

- POS sales
- Payments
- Invoices
- Stock movements
- Order placement
- Money transfers
- Ledger entries

use backend-supported idempotency.

Example:

```dart
await SPNetwork.instance.post<Object?>(
  'sales',
  body: sale.toJson(),
  options: SPRequestOptions(
    headers: {
      'Idempotency-Key':
          sale.localTransactionId,
    },
  ),
);
```

The backend must actually implement the idempotency contract.

Another common approach is to include a unique client transaction identifier:

```json
{
  "clientTransactionId": "SALE-DEVICE01-20260928-000001",
  "amount": 1250
}
```

and enforce uniqueness on the server/database.

Client-side "no automatic retries" alone cannot guarantee exactly-once business execution after an ambiguous network failure.

---

# Timeout Behavior

Default timeout:

```dart
const Duration(seconds: 30)
```

The timeout applies per transport attempt.

Because GET/HEAD can retry, total wall-clock duration can exceed one attempt timeout.

Example:

```text
GET attempt 1
timeout
backoff
GET attempt 2
timeout
backoff
GET attempt 3
```

Configure a custom timeout globally:

```dart
SPNetworkConfig(
  baseUrl: 'https://api.example.com/',
  timeout: const Duration(seconds: 15),
)
```

Or per request:

```dart
await SPNetwork.instance.get(
  'large-report',
  options: const SPRequestOptions(
    timeout: Duration(seconds: 60),
  ),
);
```

A timed-out write request may already have reached and completed on the server.

Do not assume:

```text
timeout == transaction did not happen
```

Use idempotency or query the backend transaction state when necessary.

---

# Cancellation

Create a cancellation token:

```dart
final cancellation = SPCancelToken();
```

Attach it to a request:

```dart
final request =
    SPNetwork.instance.get<Object?>(
  'report',
  options: SPRequestOptions(
    cancelToken: cancellation,
  ),
);
```

Cancel it:

```dart
cancellation.cancel();
```

Handle cancellation normally:

```dart
try {
  await request;
} on SPNetworkException catch (error) {
  if (error.type ==
      SPNetworkErrorType.cancelled) {
    return;
  }

  rethrow;
}
```

Cancellation interrupts:

- Retry waits
- Request processing
- Response-body reads

Sixplace uses abortable requests where supported by the underlying `package:http` transport.

Cancellation cannot undo server-side work that has already completed.

---

# Multipart Uploads

```dart
await SPNetwork.instance.upload<Map<String, dynamic>>(
  'attachments',
  fields: {
    'description': 'Invoice receipt',
  },
  files: [
    SPUploadFile(
      field: 'file',
      filename: 'receipt.png',
      bytes: selectedImageBytes,
      contentType: 'image/png',
    ),
  ],
);
```

Supported upload methods:

- POST
- PUT
- PATCH

Sixplace creates fresh multipart parts for each upload request.

The multipart boundary is generated by the HTTP transport.

Uploads are not automatically retried by Sixplace.

---

# Text Responses

```dart
final response =
    await SPNetwork.instance.get<String>(
  'health',
  options: const SPRequestOptions(
    responseType: SPResponseType.text,
  ),
);

print(response.data);
```

---

# Binary Responses

```dart
final response =
    await SPNetwork.instance.get<List<int>>(
  'report.pdf',
  options: const SPRequestOptions(
    responseType: SPResponseType.bytes,
  ),
);

final bytes = response.data;
```

The current networking implementation buffers response data in memory.

For very large downloads, use a specialized streaming solution until streaming support is added to Sixplace.

---

# Response Size Protection

Sixplace limits buffered response size.

The default maximum response size is:

```text
20 MiB
```

This limit helps prevent unexpectedly large responses from consuming excessive client memory.

It can be configured using the network configuration when your application requires a different maximum.

---

# Redirect Behavior

Automatic redirects are intentionally disabled.

Use the backend's canonical URL, including the correct trailing slash where required.

This prevents Authorization credentials from being unexpectedly forwarded to another location.

On native transports, redirect responses normally surface as HTTP errors.

Browser behavior can differ because browser security policies are also involved.

---

# Logging

Network logging is disabled unless a logger is configured.

Example:

```dart
SPNetworkConfig(
  baseUrl: 'https://api.example.com/',
  logger: (event) {
    debugPrint('$event');
  },
)
```

Sixplace diagnostic events contain only metadata such as:

- HTTP method
- Lifecycle phase
- Attempt number
- Status code
- Error category

Sixplace does not intentionally include:

- Access tokens
- Authorization headers
- Request bodies
- Response bodies
- Query values
- Full request URLs

in normal diagnostic logs.

Application code should still avoid blindly logging exception fields because backend error bodies may contain private business information.

---

# Security

For production applications:

- Use HTTPS.
- Do not disable certificate validation.
- Store credentials using an appropriate secure-storage solution.
- Do not log bearer tokens.
- Do not blindly log API response bodies.
- Keep API authorization rules enforced on the server.
- Use backend-side validation.
- Use idempotency for important transactional operations.
- Use short-lived or otherwise appropriately managed authentication credentials.
- Configure CORS correctly for Flutter Web.

Sixplace does not provide certificate bypass logic.

---

# Platform Notes

## Android

Applications using networking need Internet permission.

Most Flutter Android applications already include the appropriate network permission configuration, but verify your final Android manifest.

Development HTTP endpoints may also require cleartext-network configuration.

Production APIs should use HTTPS.

---

## iOS

Use HTTPS unless your application has a justified and correctly configured App Transport Security exception.

---

## macOS

Network-client entitlement may be required depending on application sandbox configuration.

---

## Web

Flutter Web networking remains subject to browser security rules such as:

- CORS
- Mixed-content restrictions
- Forbidden headers
- Browser cookie policies

Sixplace cannot bypass CORS.

Configure CORS on the backend.

---

# Diagnostics and Server Load

Sixplace contains no automatic background polling loop.

The networking package does not automatically issue repeated POST requests.

However, server load can still increase when:

- Application code repeatedly calls an API
- Requests are triggered from widget rebuilds
- Users repeatedly tap a submit action
- A consuming application injects a retrying custom transport
- GET/HEAD retries occur during backend overload
- Many devices retry simultaneously
- Application code implements its own polling

For high-scale deployments, monitor:

- Request rate
- Concurrent requests
- Error rate
- 429 responses
- 503 responses
- Database connection utilization
- API latency
- Memory consumption
- CPU consumption

Backends under load should return suitable HTTP statuses and, where appropriate:

```http
Retry-After
```

Sixplace respects bounded retry behavior for eligible GET/HEAD requests.

---

# SPNetwork Feature Summary

`SPNetwork` currently provides:

- Shared or independent HTTP clients
- GET
- POST
- PUT
- PATCH
- DELETE
- HEAD
- JSON request encoding
- JSON response decoding
- Custom model decoders
- Query parameters
- Bearer authentication
- Optional public/unauthenticated requests
- Unauthorized callback
- Bounded GET/HEAD retries
- `Retry-After` handling
- Request timeout
- Cancellation
- Multipart upload
- Text responses
- Binary responses
- Typed network exceptions
- Response-size protection
- Backend reachability through `isDeviceOnline()`
- Safe base-URL resolution
- Redirect rejection
- Minimal diagnostic logging
- Native and browser transport support

Sixplace currently does not provide:

- Automatic token refresh
- Automatic write retry
- Background polling
- HTTP caching
- WebSockets
- Large-file streaming
- Upload progress callbacks
- Download progress callbacks
- General interceptor chains
- Persistent secure token storage implementation
- Application routing
- Feedback inside the network layer (use `SPFeedback` separately)

These responsibilities remain outside `SPNetwork`. Use the relevant Sixplace foundation where available, or keep application-specific policy in your app.

---

# SPFeedback

`SPFeedback` provides framework-native messages, dialogs and loading surfaces without requiring a routing or state-management package.

## Toast-like messages

```dart
SPFeedback.showToast(
  context,
  'Connected.',
  type: SPFeedbackType.info,
);
```

`showToast` uses Flutter's own `ScaffoldMessenger` rather than a platform-specific native toast, keeping behavior consistent on mobile, web and desktop. For actions or longer messages, use `showMessage`.

## Transient messages

```dart
SPFeedback.showMessage(
  context,
  'Sale saved successfully.',
  type: SPFeedbackType.success,
);
```

Available semantic types are `info`, `success`, `warning`, and `error`. Messages use `ScaffoldMessenger`, so they work consistently across Flutter platforms.

Actions are optional:

```dart
SPFeedback.showMessage(
  context,
  'Draft deleted.',
  type: SPFeedbackType.warning,
  actionLabel: 'Undo',
  onAction: restoreDraft,
);
```

## Alerts

```dart
final confirmed = await SPFeedback.showAlert(
  context,
  title: 'Delete invoice?',
  message: 'This action cannot be undone.',
  confirmLabel: 'Delete',
  cancelLabel: 'Cancel',
  type: SPFeedbackType.error,
);

if (confirmed == true) {
  await deleteInvoice();
}
```

## Blocking loader

```dart
final loader = SPFeedback.showLoading(
  context,
  message: 'Submitting invoice…',
);

try {
  await submitInvoice();
} finally {
  loader.close();
}
```

The loader handle removes only the route it created, avoiding accidental pops of unrelated screens. For inline workflows, use `SPBlockingLoader` directly in the widget tree.

---

# SPTheme

`SPTheme` builds Material themes and attaches Sixplace semantic design tokens through Flutter's `ThemeExtension` mechanism.

```dart
MaterialApp(
  theme: SPTheme.light(
    seedColor: const Color(0xFF5B5BD6),
  ),
  darkTheme: SPTheme.dark(
    seedColor: const Color(0xFF5B5BD6),
  ),
  home: const HomePage(),
)
```

Read the current tokens from context:

```dart
final tokens = context.spTheme;

final successColor = tokens.success;
final pagePadding = context.spSpacing.md;
final cardRadius = context.spRadius.lg;
final bodySize = context.spTypography.body;
```

Customize token scales:

```dart
final theme = SPTheme.light(
  spacing: const SPSpacingTokens(
    xs: 4,
    sm: 8,
    md: 18,
    lg: 28,
    xl: 36,
    xxl: 52,
  ),
  radius: const SPRadiusTokens(
    sm: 6,
    md: 12,
    lg: 18,
    xl: 28,
    pill: 999,
  ),
  typography: const SPTypographyTokens(
    display: 34,
    headline: 26,
    title: 20,
    body: 16,
    label: 14,
    caption: 12,
  ),
);
```

To add Sixplace tokens to an existing `ThemeData` without replacing other theme configuration:

```dart
final theme = SPTheme.withTokens(existingTheme);
```

`SPTheme.light` and `SPTheme.dark` apply the configured `SPTypographyTokens` to Flutter's `TextTheme` while preserving each base style's remaining properties. Pass a complete custom `textTheme` when the application needs full typography control. `SPTheme.withTokens` preserves an existing `TextTheme` by default; set `applyTypography: true` to apply the token sizes.

---

# SPForms

`SPForms` provides validators, common Material form inputs and guarded asynchronous submission. It does not require GetX, Bloc, Riverpod, Provider, or another state manager.

## Validators

```dart
final emailValidator = SPValidators.compose<String>([
  SPValidators.required(),
  SPValidators.email(),
]);
```

Other built-in validators include:

- `minLength`
- `maxLength`
- `pattern`
- `minNumber`
- `maxNumber`
- `compose`

## Inputs

```dart
final formKey = GlobalKey<FormState>();

Form(
  key: formKey,
  child: Column(
    children: [
      SPTextFormField(
        label: 'Email',
        keyboardType: TextInputType.emailAddress,
        validator: SPValidators.compose([
          SPValidators.required(),
          SPValidators.email(),
        ]),
      ),
      SPDropdownFormField<int>(
        label: 'Customer type',
        items: const [
          DropdownMenuItem(value: 1, child: Text('Retail')),
          DropdownMenuItem(value: 2, child: Text('Dealer')),
        ],
        onChanged: (value) {},
        validator: (value) => value == null ? 'Choose a type.' : null,
      ),
      SPCheckboxFormField(
        title: 'I confirm the information is correct',
        validator: (value) => value == true ? null : 'Confirmation is required.',
      ),
    ],
  ),
)
```

## Guarded submission

`SPFormController.submit` validates the form and rejects concurrent submissions, helping prevent duplicate actions caused by repeated taps.

```dart
final formController = SPFormController();

Future<void> save() async {
  await formController.submit<void>(
    formKey: formKey,
    context: context,
    action: () async {
      await SPNetwork.instance.post(
        'customers',
        body: buildCustomerPayload(),
      );
    },
  );
}
```

Use a submission-aware button:

```dart
SPSubmitButton(
  controller: formController,
  label: 'Save',
  busyLabel: 'Saving…',
  onPressed: save,
)
```

Dispose controllers owned by a `State` object:

```dart
@override
void dispose() {
  formController.dispose();
  super.dispose();
}
```

For transaction safety, UI duplicate-submit protection should still be paired with backend idempotency where business operations must not be duplicated.

---

# SPStorage

`SPStorage` defines stable storage interfaces without forcing a particular persistence or secure-storage plugin on every application. This keeps Sixplace platform-neutral and lets apps choose providers that match their deployment and security requirements.

## Storage facade

```dart
final storage = SPStorage(
  preferences: MyPreferencesAdapter(),
  secure: MySecureStorageAdapter(),
);

await storage.writePreference('pageSize', 25);
final pageSize = await storage.readPreference<int>('pageSize');

await storage.writeSecure('accessToken', token);
final savedToken = await storage.readSecure('accessToken');
```

Implement these interfaces around your preferred persistence packages:

```dart
abstract interface class SPPreferencesStore {
  Future<Object?> read(String key);
  Future<void> write(String key, Object value);
  Future<bool> containsKey(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

abstract interface class SPSecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<bool> containsKey(String key);
  Future<void> remove(String key);
  Future<void> clear();
}
```

Preference values are intentionally limited to `String`, `bool`, `int`, `double`, and `List<String>` so adapters can map cleanly to common preference stores.

## In-memory providers

Sixplace includes:

```dart
SPMemoryPreferencesStore();
SPMemorySecureStore();
```

These are useful for tests, previews and ephemeral sessions. `SPMemorySecureStore` does **not** provide encrypted persistent storage and should not be represented as an OS-backed secure store.

## Bounded cache

`SPStorageCache` is an in-process LRU-style cache with optional TTL expiration. It creates no background polling timer.

```dart
final cache = SPStorageCache(maxEntries: 200);

cache.put(
  'dashboard',
  dashboardModel,
  ttl: const Duration(minutes: 5),
);

final cached = cache.get<DashboardModel>('dashboard');
```

Expired values are removed lazily during cache access. When the capacity is exceeded, the least recently used entry is evicted.

---

# SPRoom

`SPRoom` is Sixplace's Room-inspired SQLite layer for structured local data. It follows the familiar **Database → Entity → DAO → Migration → Transaction** model used by AndroidX Room while using the sqflite ecosystem underneath.

`SPRoom` is part of Sixplace's storage foundation, but it has a focused import:

```dart
import 'package:sixplace/room.dart';
```

## What SPRoom provides

- Declarative table schemas through `SPRoomEntitySchema`
- Typed model mapping through `SPRoomEntityAdapter<T>`
- Generic/subclassable `SPRoomDao<T>` CRUD APIs
- `insert`, `insertAll`, `update`, `delete`, `upsert`, query and count helpers
- Composite and auto-increment primary keys
- Explicit indexes and foreign keys
- Explicit versioned migrations
- Missing-migration failure by default
- Opt-in destructive migration fallback
- Schema validation after create/migrate/open
- Schema identity tracking
- Transaction-aware DAO calls
- Reactive `watch()` and `watchRawQuery()` streams
- Raw SQL escape hatches with explicit invalidation
- In-memory database builders for tests
- sqflite-compatible factory injection for desktop/web/testing

## Entity + adapter

```dart
class User {
  const User({this.id, required this.name});

  final int? id;
  final String name;
}

const userSchema = SPRoomEntitySchema(
  tableName: 'users',
  columns: <SPRoomColumn>[
    SPRoomColumn(
      name: 'id',
      type: SPRoomSqlType.integer,
      primaryKey: true,
      autoIncrement: true,
    ),
    SPRoomColumn(name: 'name', type: SPRoomSqlType.text),
  ],
  indices: <SPRoomIndex>[
    SPRoomIndex(name: 'idx_users_name', columns: <String>['name']),
  ],
);

class UserAdapter extends SPRoomEntityAdapter<User> {
  @override
  SPRoomEntitySchema get schema => userSchema;

  @override
  Map<String, Object?> toRow(User user) => <String, Object?>{
    'id': user.id,
    'name': user.name,
  };

  @override
  User fromRow(Map<String, Object?> row) => User(
    id: (row['id'] as num?)?.toInt(),
    name: row['name']! as String,
  );
}
```

## DAO + database

```dart
class UserDao extends SPRoomDao<User> {
  UserDao(SPRoomDatabase database) : super(database, UserAdapter());

  Future<List<User>> findByName(String text) => query(
    where: 'name LIKE ?',
    whereArgs: <Object?>['%$text%'],
    orderBy: 'name',
  );
}

class AppDatabase extends SPRoomDatabase {
  late final UserDao users = UserDao(this);
}
```

Open it once and reuse the instance:

```dart
final db = await SPRoom.databaseBuilder<AppDatabase>(
  name: 'app.db',
  version: 1,
  create: AppDatabase.new,
  entities: const <SPRoomEntitySchema>[userSchema],
).build();

final id = await db.users.insert(const User(name: 'Mehedi'));
final user = await db.users.findById(id);
```

## Reactive queries

```dart
final users = db.users.watch(orderBy: 'name');

StreamBuilder<List<User>>(
  stream: users,
  builder: (context, snapshot) {
    // rebuilds after writes performed through SPRoom
    return const SizedBox.shrink();
  },
);
```

`SPRoomDao` writes automatically invalidate their table. For custom SQL writes, use `db.rawWrite(...)` or call `db.notifyTablesChanged(...)` after the write.

## Transactions

```dart
await db.writeTransaction(() async {
  await db.users.insert(firstUser);
  await db.users.insert(secondUser);
});
```

DAO operations automatically reuse the active sqflite transaction. `withTransaction()` and `runInTransaction()` are aliases for the same transaction behavior. This prevents the common sqflite deadlock mistake of using the outer `Database` object from inside a transaction callback.

## Migrations

```dart
final migration1To2 = SPRoomMigration(1, 2, (db) async {
  await db.execute(
    'ALTER TABLE users ADD COLUMN email TEXT',
  );
});

final db = await SPRoom.databaseBuilder<AppDatabase>(
  name: 'app.db',
  version: 2,
  create: AppDatabase.new,
  entities: const <SPRoomEntitySchema>[userSchemaV2],
).addMigrations(<SPRoomMigration>[
  migration1To2,
]).build();
```

If a migration path is missing, SPRoom throws `SPRoomMissingMigrationException`. `fallbackToDestructiveMigration()` is intentionally opt-in because it deletes managed data.

## Platform database factories

Android, iOS, and macOS use `package:sqflite` automatically.

For Linux/Windows unit tests or desktop applications, add a compatible sqflite factory such as `sqflite_common_ffi` in the consuming app and inject it:

```dart
sqfliteFfiInit();

final db = await SPRoom.databaseBuilder<AppDatabase>(
  name: 'app.db',
  version: 1,
  create: AppDatabase.new,
  entities: const <SPRoomEntitySchema>[userSchema],
  factory: databaseFactoryFfi,
).build();
```

For web, inject a compatible sqflite web factory and complete that factory's required web/wasm setup. Sixplace intentionally does not force desktop/web SQLite binaries into every consuming application.

pub.dev's automatic platform detection can omit Windows and Linux because the
default factory imports the mobile/macOS `sqflite` plugin. Desktop SPRoom usage
requires an injected factory; its database tests run with `sqflite_common_ffi`.
The layout, networking, feedback, theme, forms and key/value storage entrypoints
do not require a native SQLite factory.

## Important parity note

SPRoom deliberately adopts the **architecture and runtime behavior patterns** developers know from AndroidX Room, but it is not a port of AndroidX Room and does not claim Kotlin/KSP compile-time code generation. Sixplace 1.0.0 uses explicit Dart schemas/adapters instead of fake annotations or runtime mirrors. SQL inside custom DAO methods is therefore the application's responsibility to test.

---

# SPLayout

The `SPLayout` foundation provides mobile-first responsive UI primitives for Flutter.

Current layout features include:

- Mobile-first responsive resolution
- Bootstrap-inspired 12-column grid
- Six default breakpoints
- Custom breakpoint support
- Responsive value inheritance
- Viewport information through `context.sp`
- Automatic responsive width and height
- Fixed and fluid containers
- Responsive container padding
- Wrapping rows with static or responsive gaps
- Responsive column spans
- Responsive offsets
- Responsive visual ordering
- Responsive padding and margin
- Breakpoint-based visibility
- Platform-adaptive application bar
- Responsive application scaffold
- Permanent desktop drawers
- Tablet navigation rails
- Responsive bottom-navigation visibility
- No duplicate responsive widget trees
- No required third-party state manager

---

# Breakpoints

Sixplace uses the following mobile-first breakpoints:

| Breakpoint | Minimum width | Effective range |
|---|---:|---:|
| `xs` | 0 px | 0–575.99 px |
| `sm` | 576 px | 576–767.99 px |
| `md` | 768 px | 768–991.99 px |
| `lg` | 992 px | 992–1199.99 px |
| `xl` | 1200 px | 1200–1399.99 px |
| `xxl` | 1400 px | 1400 px and above |

Responsive values inherit forward until overridden.

Example:

```dart
SPCol(
  sm: 6,
  lg: 4,
  child: content,
)
```

This produces:

- 12 columns on `xs`
- 6 columns on `sm` and `md`
- 4 columns on `lg`, `xl`, and `xxl`

---

# Responsive Two-Column Layout

```dart
import 'package:flutter/material.dart';
import 'package:sixplace/sixplace.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SPAppBar(
        title: 'Dashboard',
      ),
      body: SingleChildScrollView(
        child: SPContainer.fluid(
          padding: const EdgeInsets.all(16),
          child: const SPRow(
            gap: 16,
            children: [
              SPCol(
                md: 6,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('First card'),
                  ),
                ),
              ),
              SPCol(
                md: 6,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Second card'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Conceptually:

```html
<div class="row">
  <div class="col-12 col-md-6">
    First card
  </div>

  <div class="col-12 col-md-6">
    Second card
  </div>
</div>
```

---

# Three-Column Responsive Layout

```dart
SPRow(
  gap: 16,
  children: [
    SPCol(
      sm: 6,
      lg: 4,
      child: firstCard,
    ),
    SPCol(
      sm: 6,
      lg: 4,
      child: secondCard,
    ),
    SPCol(
      sm: 6,
      lg: 4,
      child: thirdCard,
    ),
  ],
)
```

Result:

- One column on extra-small screens
- Two columns from `sm`
- Three columns from `lg`

---

# Responsive Dashboard Cards

```dart
SPRow(
  responsiveGap: const SPResponsiveValue<double>(
    base: 8,
    md: 12,
    lg: 16,
  ),
  children: [
    SPCol(
      span: 12,
      sm: 6,
      xl: 3,
      child: firstCard,
    ),
    SPCol(
      span: 12,
      sm: 6,
      xl: 3,
      child: secondCard,
    ),
    SPCol(
      span: 12,
      sm: 6,
      xl: 3,
      child: thirdCard,
    ),
    SPCol(
      span: 12,
      sm: 6,
      xl: 3,
      child: fourthCard,
    ),
  ],
)
```

---

# Responsive Values

`SPResponsiveValue<T>` stores one value that changes across breakpoints.

```dart
const spacing =
    SPResponsiveValue<double>(
  base: 8,
  md: 16,
  xl: 24,
);
```

This resolves to:

- `8` on `xs` and `sm`
- `16` on `md` and `lg`
- `24` on `xl` and `xxl`

Missing breakpoint values inherit from the nearest configured smaller breakpoint.

---

## Resolve from Context

```dart
final borderRadius =
    const SPResponsiveValue<double>(
  base: 8,
  md: 12,
  lg: 16,
).resolveFrom(context);
```

This avoids application-level `MediaQuery` boilerplate for many responsive properties.

---

# Responsive Width and Height

```dart
SPResponsiveSizedBox(
  height: const SPResponsiveValue<double?>(
    base: null,
    lg: 350,
  ),
  child: StockOverviewChart(),
)
```

Below `lg`, natural child height is used.

From `lg`, the height becomes `350`.

Width and height can be combined:

```dart
SPResponsiveSizedBox(
  width: const SPResponsiveValue<double?>(
    base: double.infinity,
    lg: 480,
  ),
  height: const SPResponsiveValue<double?>(
    base: 240,
    lg: 350,
  ),
  child: content,
)
```

---

# Viewport Information

Use:

```dart
final responsive = context.sp;
```

Available information includes:

```dart
responsive.width;
responsive.height;
responsive.breakpoint;

responsive.isMobile;
responsive.isTablet;
responsive.isDesktop;
responsive.isLargeDesktop;
```

Device-category behavior:

- `isMobile`: `xs` and `sm`
- `isTablet`: `md`
- `isDesktop`: `lg` and above
- `isLargeDesktop`: `xxl` and above

`isDesktop` remains true on larger desktop breakpoints.

Explicit breakpoint checks are also supported:

```dart
if (context.sp.atLeast(
  SPBreakpoint.lg,
)) {
  // Desktop-specific behavior.
}
```

```dart
if (context.sp.below(
  SPBreakpoint.md,
)) {
  // Small-screen behavior.
}
```

Prefer layout widgets such as `SPRow`, `SPCol`, `SPVisibility`, and `SPScaffold` for structural layout changes instead of rebuilding complete mobile and desktop pages.

---

# Responsive Container Padding

```dart
SPContainer.fluid(
  responsivePadding:
      const SPResponsiveValue<EdgeInsetsGeometry>(
    base: EdgeInsets.all(8),
    md: EdgeInsets.all(12),
    lg: EdgeInsets.all(16),
  ),
  child: content,
)
```

Static padding remains supported:

```dart
SPContainer.fluid(
  padding: const EdgeInsets.all(16),
  child: content,
)
```

When `responsivePadding` is provided, it takes precedence over static `padding`.

---

# Responsive Row Gaps

Static gap:

```dart
SPRow(
  gap: 16,
  children: columns,
)
```

Responsive gap:

```dart
SPRow(
  responsiveGap:
      const SPResponsiveValue<double>(
    base: 8,
    md: 12,
    lg: 16,
  ),
  children: columns,
)
```

Explicit horizontal or vertical values can override the responsive gap for that axis.

```dart
SPRow(
  horizontalGap: 20,
  responsiveGap:
      const SPResponsiveValue<double>(
    base: 8,
    lg: 16,
  ),
  children: columns,
)
```

In this example:

- Horizontal gap remains `20`
- Vertical gap changes responsively

---

# Responsive Offset

```dart
SPRow(
  children: [
    SPCol(
      span: 12,
      md: 8,
      offsetMd: 2,
      child: centeredContent,
    ),
  ],
)
```

From `md`, the content occupies eight columns with two empty columns before it.

---

# Responsive Visual Order

```dart
SPRow(
  gap: 16,
  children: [
    SPCol(
      span: 12,
      lg: 8,
      order: 2,
      orderLg: 1,
      child: mainContent,
    ),
    SPCol(
      span: 12,
      lg: 4,
      order: 1,
      orderLg: 2,
      child: sidebar,
    ),
  ],
)
```

The sidebar appears first on smaller screens and after the main content from `lg`.

---

# Responsive Visibility

```dart
SPVisibility(
  hiddenXs: true,
  hiddenSm: true,
  child: desktopAction,
)
```

Use replacements where necessary:

```dart
SPVisibility(
  hiddenLg: true,
  hiddenXl: true,
  hiddenXxl: true,
  replacement:
      const Text('Desktop navigation'),
  child:
      const Text('Mobile navigation'),
)
```

Avoid using visibility to maintain two complete copies of the same page.

---

# Responsive Padding

```dart
SPPadding(
  base: const EdgeInsets.all(8),
  md: const EdgeInsets.all(16),
  lg: const EdgeInsets.all(24),
  child: content,
)
```

---

# Responsive Margin

```dart
SPMargin(
  base: const EdgeInsets.only(
    bottom: 8,
  ),
  md: const EdgeInsets.only(
    bottom: 16,
  ),
  child: content,
)
```

---

# Platform-Adaptive App Bar

```dart
Scaffold(
  appBar: const SPAppBar(
    title: 'Sixplace',
  ),
  body: const YourPageContent(),
)
```

`SPAppBar` provides:

- Material styling on Android, web and desktop
- iOS-style presentation on iOS
- Dark-mode-aware colors
- Automatic back-navigation handling
- Optional drawer-button handling

Override title alignment when required:

```dart
SPAppBar(
  title: 'Sixplace',
  centerTitle: false,
)
```

Show a drawer button:

```dart
SPAppBar(
  title: 'Dashboard',
  showDrawerIcon: true,
  onDrawerPressed: openDrawer,
)
```

---

# Responsive Application Shell

```dart
SPScaffold(
  appBar: const SPAppBar(
    title: 'Dashboard',
  ),
  drawer: const AppDrawer(),
  permanentDrawerBreakpoint:
      SPBreakpoint.lg,
  navigationRail:
      const AppNavigationRail(),
  navigationRailBreakpoint:
      SPBreakpoint.md,
  bottomNavigationBar:
      const AppBottomNavigation(),
  hideBottomNavBreakpoint:
      SPBreakpoint.md,
  body: const DashboardContent(),
)
```

Typical behavior:

- Mobile: fly-out drawer and bottom navigation
- Tablet: navigation rail
- Desktop: permanent drawer
- Navigation rail hides when the permanent drawer becomes active
- Bottom navigation hides from the configured breakpoint

---

# Real-World Chart Layout

```dart
SPContainer.fluid(
  responsivePadding:
      const SPResponsiveValue<EdgeInsetsGeometry>(
    base: EdgeInsets.all(8),
    lg: EdgeInsets.all(16),
  ),
  child: SPRow(
    responsiveGap:
        const SPResponsiveValue<double>(
      base: 12,
      lg: 16,
    ),
    children: [
      SPCol(
        span: 12,
        lg: 6,
        child: SPResponsiveSizedBox(
          height:
              const SPResponsiveValue<double?>(
            base: null,
            lg: 350,
          ),
          child:
              InventoryCompositionChart(),
        ),
      ),
      SPCol(
        span: 12,
        lg: 6,
        child: SPResponsiveSizedBox(
          height:
              const SPResponsiveValue<double?>(
            base: null,
            lg: 350,
          ),
          child:
              StockOverviewChart(),
        ),
      ),
    ],
  ),
)
```

This provides:

- One chart per row below `lg`
- Two charts per row from `lg`
- Responsive page padding
- Responsive grid gaps
- Automatic chart-height resolution
- No duplicate desktop/mobile widget trees

---

# Custom Breakpoints

```dart
const customBreakpoints =
    SPBreakpoints(
  sm: 500,
  md: 700,
  lg: 900,
  xl: 1100,
  xxl: 1300,
);
```

Apply to a grid:

```dart
SPRow(
  breakpoints: customBreakpoints,
  children: [
    SPCol(
      md: 6,
      child: content,
    ),
  ],
)
```

Apply to viewport information:

```dart
final responsive =
    SPResponsive.of(
  context,
  breakpoints: customBreakpoints,
);
```

Apply to responsive sizing:

```dart
SPResponsiveSizedBox(
  breakpoints: customBreakpoints,
  height:
      const SPResponsiveValue<double?>(
    base: null,
    lg: 350,
  ),
  child: content,
)
```

Keep related widgets on the same breakpoint configuration for predictable behavior.

---

# Numeric Design Scaling

Sixplace also includes numeric design-scaling helpers.

The current implementation uses uncapped design scaling.

## Width

```text
n.w = n × (logicalScreenWidth / designWidth)
```

## Height

```text
n.h = n × (logicalScreenHeight / designHeight)
```

These calculations use logical Flutter pixels rather than physical device pixels.

Initialize:

```dart
SixPlace.init(
  context,
  designSize:
      const Size(390, 844),
  rootFontSize: 16,
);
```

Use:

```dart
final cardWidth = 100.w;
final heroHeight = 48.h;
```

Use the responsive grid for structural desktop/web layouts rather than relying only on design scaling.

---

# Typography

The numeric typography API includes accessibility scaling.

Conceptually:

```text
n.sp =
  textScaler.scale(
    n × fontScale
  )
```

and:

```text
n.rem =
  textScaler.scale(
    n × rootFontSize × fontScale
  )
```

Example:

```dart
Text(
  'Large heading',
  style: TextStyle(
    fontSize: 16.sp,
  ),
  textScaler:
      TextScaler.noScaling,
)
```

The returned numeric value already contains the accessibility scaling calculated by Sixplace.

Using `TextScaler.noScaling` with a font size produced by `.sp` or `.rem` prevents Flutter from applying an additional scale to that already scaled value.

Sixplace does not globally disable system text scaling.

---

# Parent-Relative `em`

```dart
DefaultTextStyle(
  style: const TextStyle(
    fontSize: 18,
  ),
  child: Builder(
    builder: (textContext) {
      return Text(
        'Inherited size',
        style: TextStyle(
          fontSize:
              1.5.em(textContext),
        ),
        textScaler:
            TextScaler.noScaling,
      );
    },
  ),
)
```

If no inherited font size is available, Sixplace falls back to the configured root font size.

---

# Public API Overview

| API | Responsibility |
|---|---|
| `SPBreakpoint` | Active responsive tier |
| `SPBreakpoints` | Breakpoint boundaries and resolution |
| `SPResponsiveValue<T>` | Breakpoint-dependent values |
| `SPResponsive` | Viewport and device-category information |
| `context.sp` | Convenient responsive context access |
| `SPContainer` | Fixed/fluid responsive containers |
| `SPRow` | Wrapping 12-column responsive row |
| `SPCol` | Responsive span, offset and order |
| `SPResponsiveSizedBox` | Responsive width/height |
| `SPPadding` | Responsive internal spacing |
| `SPMargin` | Responsive external spacing |
| `SPVisibility` | Breakpoint-based visibility |
| `SPAppBar` | Platform-adaptive application bar |
| `SPScaffold` | Responsive application shell |
| `SPNetwork` | Network client |
| `SPNetworkConfig` | Network configuration |
| `SPRequestOptions` | Per-request options |
| `SPNetworkResponse<T>` | Successful response model |
| `SPNetworkException` | Typed network failure |
| `SPRetryPolicy` | Bounded GET/HEAD retry policy |
| `SPCancelToken` | Request cancellation |
| `SPUploadFile` | Multipart file model |
| `isDeviceOnline()` | Backend reachability check |
| `SPFeedback` | Messages, alerts and blocking loaders |
| `SPFeedbackLoaderHandle` | Route-specific loader lifecycle |
| `SPTheme` | Light/dark theme factories and token installation |
| `SPThemeTokens` | Semantic colors, spacing and radius tokens |
| `SPSpacingTokens` | Spacing design-token scale |
| `SPRadiusTokens` | Radius design-token scale |
| `SPTypographyTokens` | Typography design-token scale |
| `SPValidators` | Reusable form validators |
| `SPFormController` | Validation and guarded async submission |
| `SPTextFormField` | Text input wrapper |
| `SPDropdownFormField<T>` | Dropdown form input |
| `SPCheckboxFormField` | Boolean form input |
| `SPSubmitButton` | Submission-aware Material button |
| `SPStorage` | Preference, secure-store and cache facade |
| `SPPreferencesStore` | Preference persistence abstraction |
| `SPSecureStore` | Secure string persistence abstraction |
| `SPStorageCache` | Bounded in-memory TTL/LRU cache |
| `SPRoom` | Room-inspired SQLite database builder |
| `SPRoomDatabase` | Base database lifecycle and transaction owner |
| `SPRoomEntitySchema` | Declarative SQLite table schema |
| `SPRoomEntityAdapter<T>` | Typed entity/row mapper |
| `SPRoomDao<T>` | CRUD, query, upsert and reactive DAO base |
| `SPRoomMigration` | Explicit schema-version migration |
| `SPRoomInvalidationTracker` | Reactive table-change stream |

---

# Resolution Behavior

Sixplace intentionally distinguishes viewport-responsive and parent-responsive behavior.

| API | Resolution basis |
|---|---|
| `context.sp` | Viewport width |
| `SPResponsiveValue.resolveFrom(context)` | Viewport width |
| `SPResponsiveSizedBox` | Viewport width |
| `SPPadding` | Viewport width |
| `SPMargin` | Viewport width |
| `SPVisibility` | Viewport width |
| `SPScaffold` | Viewport width |
| `SPContainer` | Immediate parent width |
| `SPRow` | Immediate parent width |
| `SPCol` inside `SPRow` | `SPRow` parent width |

This allows nested grids to adapt to actual available space while screen-level decisions remain based on the viewport.

---

# Performance

Sixplace uses Flutter-native primitives such as:

- `LayoutBuilder` where immediate parent width is required
- `MediaQuery.sizeOf` where viewport information is required
- Immutable responsive configuration objects
- Breakpoint inheritance
- Standard Flutter widgets
- Persistent `http.Client` reuse in `SPNetwork`

Recommended practices:

- Declare responsive values `const` where possible.
- Avoid unnecessary deeply nested responsive wrappers.
- Use lazy lists such as `ListView.builder`.
- Avoid maintaining duplicate full-page widget trees.
- Avoid starting API requests from `build()`.
- Reuse `SPNetwork` clients.
- Guard write buttons against duplicate submission.
- Use backend idempotency for critical transactional writes.

---

# Runnable Example and Tests

Run the application example:

```bash
cd example
fvm flutter pub get
fvm flutter run -d chrome
```

If your checkout includes the dedicated networking demo:

```bash
cd example
fvm flutter run \
  -t lib/network_main.dart \
  -d chrome
```

The networking example can use an injected mock transport and therefore does not require a real backend, API key, or production account.

Run the feedback/theme/forms/storage demo:

```bash
cd example
fvm flutter run \
  -t lib/foundations_main.dart \
  -d chrome
```

The storage portion uses only the included in-memory adapters, so the demo needs no platform-specific storage plugin configuration.

Run the dedicated SPRoom example on Android, iOS, or macOS (where sqflite is automatic):

```bash
cd example
fvm flutter run -t lib/room_main.dart -d <device>
```

For Linux/Windows/web, inject a compatible sqflite database factory as described in the SPRoom platform section.

---

# Testing

From the package root:

```bash
fvm flutter pub get
fvm dart format .
fvm flutter analyze
fvm flutter test
```

Network-only tests:

```bash
fvm flutter test test/network
```

SPRoom tests use a sqflite-compatible FFI factory and cover CRUD, transactions, reactive invalidation, and migration/schema validation.

The networking tests should cover areas including:

- GET requests
- POST requests
- PUT requests
- PATCH requests
- DELETE requests
- HEAD requests
- JSON encoding
- JSON decoding
- Typed models
- Authentication
- Unauthorized handling
- URL resolution
- Query parameters
- Retries
- No replay of writes
- Cancellation
- Timeout behavior
- Multipart uploads
- Response-size limits
- `isDeviceOnline()`
- Single-attempt reachability behavior

---

# Before Publishing to pub.dev

pub.dev's scoring model evolves over time, so do not optimize for a hard-coded
point total. Validate the categories pub.dev currently evaluates: package file
conventions and secure metadata URLs, API/example documentation, detected
platform support (including modern web/Wasm readiness where applicable), static
analysis, and compatibility with current SDKs/dependencies.

For the `1.0.0` release, run the complete validation sequence from the package
root:

```bash
fvm flutter pub get
fvm dart format --set-exit-if-changed .
fvm flutter analyze
fvm flutter test
fvm flutter pub outdated
fvm dart pub publish --dry-run
```

Carefully review the dry-run file list. A library package should not accidentally
publish local build output, editor caches, credentials, generated temporary
files, or other development-only artifacts.

pub.dev calculates pub points with `pana`. Run the latest `pana` against a
**copy** of the package because the analyzer may modify the directory it checks:

```bash
fvm dart pub global activate pana
fvm dart pub global run pana <path-to-a-copy-of-sixplace>
```

Before publishing, verify all of these release gates:

```text
version     -> pubspec.yaml and CHANGELOG.md agree on 1.0.0
format      -> pass with no generated diff
analyze     -> no errors, warnings, or unexpected lints
tests       -> all pass
outdated    -> reviewed; supported dependency constraints are current
platforms   -> verify Sixplace core remains Android/iOS/Linux/macOS/web/Windows compatible; verify SPRoom default/injected factory notes are accurate
docs        -> README example + public API documentation remain available
metadata    -> LICENSE present; homepage/repository/issue URLs use valid HTTPS
pana        -> no unexpected pub-point findings
dry-run     -> no warnings and only intended publish files
```

Only after those checks pass, publish the immutable `1.0.0` release:

```bash
fvm dart pub publish
```

---

# Migration

Existing Sixplace layout code remains compatible with the current layout API.

For example:

```dart
SPContainer.fluid(
  padding:
      const EdgeInsets.all(16),
  child: SPRow(
    gap: 16,
    children: [
      SPCol(
        md: 6,
        child: firstCard,
      ),
      SPCol(
        md: 6,
        child: secondCard,
      ),
    ],
  ),
)
```

New APIs are additive and can be adopted gradually.

Networking is also independently importable:

```dart
import 'package:sixplace/network.dart';
```

Existing layout-only applications do not need to initialize `SPNetwork` or `SPRoom`. Existing sqflite applications can adopt SPRoom incrementally by modeling the current schema first and introducing explicit migrations only for future schema versions.

---

# Design Principles

Sixplace follows these principles:

1. Mobile-first responsive behavior
2. One widget tree for every screen size
3. Minimal and readable public APIs
4. Predictable breakpoint inheritance
5. Flutter-first implementation
6. Avoid unnecessary runtime dependencies
7. Tested public behavior
8. Backward-compatible APIs whenever practical
9. Clear viewport/parent-width semantics
10. UI-independent networking
11. Bounded and predictable retry behavior
12. No automatic replay of transactional writes by Sixplace
13. Separation of transport, application state and business logic
14. Reduced cognitive complexity instead of line-count optimization
15. Versioned, explicit relational schema evolution for SPRoom
16. No destructive database migration unless the application opts in

---

# Development

Format and validate before submitting changes:

```bash
fvm dart format .
fvm flutter analyze
fvm flutter test
```

Run the visual example:

```bash
cd example
fvm flutter pub get
fvm flutter run -d chrome
```

Resize the browser window to verify responsive transitions.

---

# Contributing

Contributions are welcome.

You can contribute by:

- Reporting bugs
- Suggesting focused features
- Improving documentation
- Adding tests
- Fixing reproducible issues
- Improving performance
- Improving accessibility
- Submitting carefully scoped pull requests

Recommended workflow:

```bash
git checkout -b feature/short-description

fvm dart format .
fvm flutter analyze
fvm flutter test
```

Then submit a pull request with a clear description of the change.

Large features or architectural changes should preferably be discussed before implementation.

Pull requests should be evaluated for:

- Correctness
- Test coverage
- Public API consistency
- Maintainability
- Backward compatibility
- Security
- Predictable runtime behavior
- Alignment with the Sixplace architecture

By contributing, you agree that your contribution may be distributed under the project's MIT License.

---

# Acknowledgements

`SPRoom` is an independent Sixplace implementation inspired by the architecture and developer experience of **AndroidX Room (Kotlin/Android Room)**. Special thanks to the Room team and Kotlin/Android Room ecosystem for the clear Database / Entity / DAO / Migration / Transaction model that informed SPRoom's design.

SPRoom is powered by the **sqflite ecosystem** for SQLite access in Flutter/Dart. Special thanks to the sqflite maintainers and contributors for the stable database API, transaction support, version-management hooks, and cross-platform factory ecosystem that make this layer possible.

- AndroidX Room: https://developer.android.com/training/data-storage/room
- sqflite: https://pub.dev/packages/sqflite

Sixplace is not affiliated with, sponsored by, or endorsed by Google/AndroidX or the sqflite maintainers.

---

# Bootstrap Inspiration

Sixplace is inspired by responsive-grid concepts popularized by Bootstrap.

Sixplace is an independent Flutter implementation and is not affiliated with, sponsored by, or endorsed by Bootstrap or its maintainers.

The implementation is written independently in Dart and Flutter.

---

# License

Sixplace is available under the [MIT License](LICENSE).

---

# Maintainer

**Innovate Nest Labs**

Digital Solutions, Bangladesh
