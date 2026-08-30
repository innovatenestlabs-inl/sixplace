# Sixplace

A mobile-first, responsive application foundation for Flutter.

Sixplace helps Flutter developers create adaptive mobile, tablet, desktop, and
web interfaces with minimal code and without maintaining duplicate widget
trees.

The responsive layout system is inspired by the simplicity of Bootstrap's
12-column grid while remaining designed specifically for Flutter.

> Sixplace is under active development. The `SPLayout` foundation is currently
> available. Additional application foundations will be introduced gradually
> through carefully designed and tested APIs.

## Why Sixplace?

Responsive Flutter interfaces often contain repeated widget trees:

```dart
if (isMobile) {
  return MobilePage();
}

return DesktopPage();
```

This approach can duplicate:

- UI structure.
- State bindings.
- Loading and error states.
- Navigation behavior.
- Business logic.
- Maintenance effort.

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

The same widgets automatically become:

- One column on smaller screens.
- Two columns from the `md` breakpoint.
- Responsive without separate mobile and desktop pages.

## Sixplace foundations

Sixplace is designed around six coordinated application foundations:

| Foundation | Responsibility | Status |
|---|---|---|
| `SPLayout` | Responsive grids, containers, spacing, visibility, sizing and application shell | Available |
| `SPNetwork` | Requests, authentication, retry and error handling | Planned |
| `SPFeedback` | Toasts, alerts, loaders and messages | Planned |
| `SPTheme` | Colours, typography, spacing and design tokens | Planned |
| `SPForms` | Inputs, validation and submission handling | Planned |
| `SPStorage` | Preferences, secure storage and caching abstractions | Planned |

Only foundations marked as available should be considered part of the current
public API.

## Available layout features

The current `SPLayout` foundation includes:

- Mobile-first responsive resolution.
- Bootstrap-inspired 12-column grid.
- Six default breakpoints.
- Custom breakpoint support.
- Responsive value inheritance.
- Viewport information through `context.sp`.
- Automatic responsive width and height.
- Fixed and fluid containers.
- Responsive container padding.
- Wrapping rows with static or responsive gaps.
- Responsive column spans.
- Responsive offsets.
- Responsive visual ordering.
- Responsive padding and margin.
- Breakpoint-based visibility.
- Platform-adaptive application bar.
- Responsive application scaffold.
- Permanent desktop drawers.
- Tablet navigation rails.
- Responsive bottom-navigation visibility.
- No duplicate responsive widget trees.
- No third-party runtime dependencies.

## Installation

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
  sixplace: ^0.0.2
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

## Breakpoints

Sixplace uses familiar mobile-first breakpoint boundaries:

| Breakpoint | Minimum width | Effective range |
|---|---:|---:|
| `xs` | 0 px | 0–575.99 px |
| `sm` | 576 px | 576–767.99 px |
| `md` | 768 px | 768–991.99 px |
| `lg` | 992 px | 992–1199.99 px |
| `xl` | 1200 px | 1200–1399.99 px |
| `xxl` | 1400 px | 1400 px and above |

A responsive value continues applying until it is overridden at a larger
breakpoint.

For example:

```dart
SPCol(
  sm: 6,
  lg: 4,
  child: content,
)
```

This column occupies:

- 12 columns on `xs`.
- 6 columns on `sm` and `md`.
- 4 columns on `lg`, `xl`, and `xxl`.

## Public API overview

| API | Responsibility |
|---|---|
| `SPBreakpoint` | Identifies the active responsive tier |
| `SPBreakpoints` | Defines and resolves breakpoint boundaries |
| `SPResponsiveValue<T>` | Stores a value that changes by breakpoint |
| `SPResponsive` | Provides viewport size, breakpoint and device-category helpers |
| `context.sp` | Convenient access to `SPResponsive` |
| `SPContainer` | Provides fixed or fluid responsive content containers |
| `SPRow` | Provides a wrapping 12-column responsive row |
| `SPCol` | Defines responsive span, offset and order |
| `SPResponsiveSizedBox` | Automatically resolves responsive width and height |
| `SPPadding` | Applies responsive padding |
| `SPMargin` | Applies responsive outer spacing |
| `SPVisibility` | Shows or hides content by breakpoint |
| `SPAppBar` | Provides a platform-adaptive application bar |
| `SPScaffold` | Provides a responsive application shell |

## Resolution behavior

Sixplace intentionally distinguishes between viewport-responsive and
parent-responsive behavior.

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
| `SPCol` inside an `SPRow` | `SPRow` parent width |

This distinction allows nested grids to respond to their actual available
space while screen-level behavior continues to use the viewport.

## Usage

### Responsive two-column layout

```dart
import 'package:flutter/material.dart';
import 'package:sixplace/sixplace.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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

This is conceptually equivalent to:

```html
<div class="row g-3">
  <div class="col-12 col-md-6">First card</div>
  <div class="col-12 col-md-6">Second card</div>
</div>
```

### Three-column responsive layout

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

This produces:

- One column on extra-small screens.
- Two columns from `sm`.
- Three columns from `lg`.

### Responsive dashboard cards

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

### Responsive values

`SPResponsiveValue<T>` stores one value that can change across breakpoints:

```dart
const chartHeight = SPResponsiveValue<double?>(
  base: null,
  lg: 350,
);
```

Missing breakpoint values inherit from the nearest configured smaller
breakpoint.

For example:

```dart
const spacing = SPResponsiveValue<double>(
  base: 8,
  md: 16,
  xl: 24,
);
```

This resolves to:

- `8` on `xs` and `sm`.
- `16` on `md` and `lg`.
- `24` on `xl` and `xxl`.

### Resolve a responsive value from context

Use `resolveFrom(context)` when a normal Flutter property needs a responsive
value:

```dart
final borderRadius = const SPResponsiveValue<double>(
  base: 8,
  md: 12,
  lg: 16,
).resolveFrom(context);
```

This avoids application-level `MediaQuery` boilerplate.

### Responsive width and height

Use `SPResponsiveSizedBox` when width or height changes by viewport
breakpoint:

```dart
SPResponsiveSizedBox(
  height: const SPResponsiveValue<double?>(
    base: null,
    lg: 350,
  ),
  child: StockOverviewChart(),
)
```

The example applies:

- Natural child height below `lg`.
- A fixed height of `350` from `lg` upward.

Responsive width and height can be combined:

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

### Viewport information with `context.sp`

Use `context.sp` for breakpoint information and non-layout responsive
decisions:

```dart
final responsive = context.sp;

responsive.width;
responsive.height;
responsive.breakpoint;

responsive.isMobile;
responsive.isTablet;
responsive.isDesktop;
responsive.isLargeDesktop;
```

Device-category behavior is:

- `isMobile`: `xs` and `sm`.
- `isTablet`: `md`.
- `isDesktop`: `lg` and above.
- `isLargeDesktop`: `xxl` and above.

`isDesktop` remains true on large desktops.

You can also perform explicit breakpoint checks:

```dart
final responsive = context.sp;

if (responsive.atLeast(SPBreakpoint.lg)) {
  // Desktop-specific non-layout behavior.
}

if (responsive.below(SPBreakpoint.md)) {
  // Mobile-specific non-layout behavior.
}
```

Prefer `SPRow`, `SPCol`, `SPVisibility`, and `SPScaffold` for layout changes.
Do not use `context.sp` to rebuild separate full mobile and desktop pages.

### Responsive container padding

Use `responsivePadding` when container padding changes according to its
available parent width:

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

The original static padding API remains available:

```dart
SPContainer.fluid(
  padding: const EdgeInsets.all(16),
  child: content,
)
```

When `responsivePadding` is provided, it takes precedence over `padding`.

### Responsive row gaps

Use a static gap:

```dart
SPRow(
  gap: 16,
  children: columns,
)
```

Or use a responsive gap:

```dart
SPRow(
  responsiveGap: const SPResponsiveValue<double>(
    base: 8,
    md: 12,
    lg: 16,
  ),
  children: columns,
)
```

An explicit `horizontalGap` or `verticalGap` overrides `responsiveGap` for
that axis:

```dart
SPRow(
  horizontalGap: 20,
  responsiveGap: const SPResponsiveValue<double>(
    base: 8,
    lg: 16,
  ),
  children: columns,
)
```

In this example:

- Horizontal gap always remains `20`.
- Vertical gap changes from `8` to `16` at `lg`.

### Responsive offset

Offsets reserve empty grid columns before a column:

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

From `md`, the content occupies eight columns with two empty columns before
it.

### Responsive visual order

Use responsive order to change visual position without duplicating widgets:

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

The sidebar appears first on smaller screens and moves after the main content
from `lg`.

### Responsive visibility

Use `SPVisibility` to show or hide a specific interface element:

```dart
SPVisibility(
  hiddenXs: true,
  hiddenSm: true,
  child: desktopAction,
)
```

Use a replacement when necessary:

```dart
SPVisibility(
  hiddenLg: true,
  hiddenXl: true,
  hiddenXxl: true,
  replacement: const Text('Desktop navigation'),
  child: const Text('Mobile navigation'),
)
```

Avoid using visibility to maintain two complete versions of the same page.

### Responsive padding

```dart
SPPadding(
  base: const EdgeInsets.all(8),
  md: const EdgeInsets.all(16),
  lg: const EdgeInsets.all(24),
  child: content,
)
```

### Responsive margin

```dart
SPMargin(
  base: const EdgeInsets.only(bottom: 8),
  md: const EdgeInsets.only(bottom: 16),
  child: content,
)
```

### Platform-adaptive app bar

```dart
Scaffold(
  appBar: const SPAppBar(
    title: 'Sixplace',
  ),
  body: const YourPageContent(),
)
```

`SPAppBar` automatically provides:

- Material styling on Android, web, and desktop.
- iOS-style height, colors, typography, alignment, and separator on iOS.
- Dark-mode-aware colors.
- Automatic back-navigation handling.
- Optional drawer-button handling.

Override the automatic title alignment when necessary:

```dart
SPAppBar(
  title: 'Sixplace',
  centerTitle: false,
)
```

Display a drawer button explicitly:

```dart
SPAppBar(
  title: 'Dashboard',
  showDrawerIcon: true,
  onDrawerPressed: openDrawer,
)
```

### Responsive application shell

`SPScaffold` can reuse the same navigation widgets across screen sizes:

```dart
SPScaffold(
  appBar: const SPAppBar(
    title: 'Dashboard',
  ),
  drawer: const AppDrawer(),
  permanentDrawerBreakpoint: SPBreakpoint.lg,
  navigationRail: const AppNavigationRail(),
  navigationRailBreakpoint: SPBreakpoint.md,
  bottomNavigationBar: const AppBottomNavigation(),
  hideBottomNavBreakpoint: SPBreakpoint.md,
  body: const DashboardContent(),
)
```

Behavior:

- Mobile: fly-out drawer and bottom navigation.
- Tablet: navigation rail.
- Desktop: permanent drawer.
- The navigation rail is hidden when the permanent drawer becomes active.
- Bottom navigation is hidden from the configured breakpoint.

### Real-world chart layout

```dart
SPContainer.fluid(
  responsivePadding:
      const SPResponsiveValue<EdgeInsetsGeometry>(
    base: EdgeInsets.all(8),
    lg: EdgeInsets.all(16),
  ),
  child: SPRow(
    responsiveGap: const SPResponsiveValue<double>(
      base: 12,
      lg: 16,
    ),
    children: [
      SPCol(
        span: 12,
        lg: 6,
        child: SPResponsiveSizedBox(
          height: const SPResponsiveValue<double?>(
            base: null,
            lg: 350,
          ),
          child: InventoryCompositionChart(),
        ),
      ),
      SPCol(
        span: 12,
        lg: 6,
        child: SPResponsiveSizedBox(
          height: const SPResponsiveValue<double?>(
            base: null,
            lg: 350,
          ),
          child: StockOverviewChart(),
        ),
      ),
    ],
  ),
)
```

This layout provides:

- One chart per row below `lg`.
- Two charts per row from `lg`.
- Responsive page padding.
- Responsive grid gaps.
- Automatic chart-height resolution.
- No direct `MediaQuery` usage.
- No duplicate mobile and desktop widget trees.

## Custom breakpoints

Create a custom breakpoint configuration:

```dart
const customBreakpoints = SPBreakpoints(
  sm: 500,
  md: 700,
  lg: 900,
  xl: 1100,
  xxl: 1300,
);
```

Apply it to a grid:

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

Apply it to responsive viewport information:

```dart
final responsive = SPResponsive.of(
  context,
  breakpoints: customBreakpoints,
);
```

Apply it to responsive sizing:

```dart
SPResponsiveSizedBox(
  breakpoints: customBreakpoints,
  height: const SPResponsiveValue<double?>(
    base: null,
    lg: 350,
  ),
  child: content,
)
```

Keep the same breakpoint configuration across related widgets to ensure
predictable behavior.

## Performance

Sixplace uses:

- `LayoutBuilder` where immediate parent width is required.
- `MediaQuery.sizeOf` where viewport size is required.
- Immutable responsive configuration objects.
- Breakpoint inheritance without maintaining duplicated widget trees.
- Flutter-native layout widgets.
- No third-party runtime dependencies.

For best performance:

- Declare responsive values as `const` where possible.
- Avoid deeply nesting responsive wrappers unnecessarily.
- Keep large lists lazy using `ListView.builder` or equivalent widgets.
- Avoid creating separate full-page trees based on `context.sp`.
- Preserve stateful children instead of rebuilding equivalent mobile and
  desktop versions.

## Migration from 0.0.1

Version `0.0.2` is backward-compatible with the `0.0.1` layout API.

Existing code remains valid:

```dart
SPContainer.fluid(
  padding: const EdgeInsets.all(16),
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

New APIs are optional:

```dart
final responsive = context.sp;
```

```dart
final value = responsiveValue.resolveFrom(context);
```

```dart
SPResponsiveSizedBox(
  height: responsiveHeight,
  child: content,
)
```

```dart
SPContainer.fluid(
  responsivePadding: responsivePadding,
  child: content,
)
```

```dart
SPRow(
  responsiveGap: responsiveGap,
  children: columns,
)
```

No existing `SPRow`, `SPCol`, `SPContainer`, `SPResponsiveValue`,
`SPPadding`, `SPMargin`, `SPVisibility`, `SPAppBar`, or `SPScaffold` usage
needs to be rewritten.

## Design principles

Sixplace follows these principles:

1. Mobile-first responsive behavior.
2. One widget tree for every screen size.
3. Minimal and readable APIs.
4. Predictable breakpoint inheritance.
5. Flutter-first implementation.
6. Zero unnecessary runtime dependencies.
7. Tested public behavior.
8. Backward-compatible APIs whenever possible.
9. Clear separation between viewport and parent-width resolution.
10. Reduced cognitive complexity instead of line-count optimization.

## Development

Format and validate the package before submitting changes:

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

Resize the browser window to verify breakpoint transitions.

Before publishing:

```bash
fvm flutter pub publish --dry-run
```

Publish after the dry run completes successfully:

```bash
fvm flutter pub publish
```

## Contributing

Contributions are welcome.

You can contribute by:

- Reporting bugs.
- Suggesting focused features.
- Improving documentation.
- Adding tests.
- Fixing valid issues.
- Improving performance or accessibility.
- Submitting carefully scoped pull requests.

Recommended workflow:

1. Fork the repository.
2. Create a branch from `main`.
3. Implement a focused change.
4. Add or update tests.
5. Run formatting, analysis, and tests.
6. Submit a pull request with a clear description.

```bash
git checkout -b feature/short-description

fvm dart format .
fvm flutter analyze
fvm flutter test
```

For large features or architectural changes, open an issue before starting
implementation.

Pull requests are reviewed for correctness, test coverage, API consistency,
maintainability, backward compatibility, and alignment with the Sixplace
architecture.

By submitting a contribution, you agree that your contribution may be
distributed under the MIT License used by this project.

## Bootstrap inspiration

Sixplace is inspired by responsive grid concepts popularized by Bootstrap.

Sixplace is an independent Flutter implementation and is not affiliated with,
sponsored by, or endorsed by Bootstrap or its maintainers. The Sixplace source
code is implemented independently in Dart and Flutter.

## License

Sixplace is available under the [MIT License](LICENSE).

## Maintainer

**Innovate Nest Labs**  
Digital Solutions, Bangladesh