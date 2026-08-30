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