# Sixplace

A mobile-first, responsive application foundation for Flutter.

Sixplace helps Flutter developers create adaptive mobile, tablet, desktop, and
web interfaces with minimal code and without maintaining duplicate widget
trees.

The responsive layout system is inspired by the simplicity of Bootstrap's
12-column grid while remaining designed specifically for Flutter.

> Sixplace is currently under active development. The responsive layout
> foundation is the first available pillar. Other pillars will be introduced
> gradually with stable and carefully designed APIs.

## Why Sixplace?

Responsive Flutter interfaces often contain repeated widget trees:

```dart
if (isMobile) {
  return MobilePage();
}

return DesktopPage();
```

Sixplace allows developers to define the layout once:

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
- Responsive without rebuilding separate mobile and desktop pages.

## Sixplace pillars

Sixplace is being designed around six coordinated application foundations:

| Pillar | Responsibility | Status |
|---|---|---|
| `SPLayout` | Responsive grid, containers, spacing, visibility and application shell | Active development |
| `SPNetwork` | Requests, authentication, retry and error handling | Planned |
| `SPFeedback` | Toasts, alerts, loaders and messages | Planned |
| `SPTheme` | Colours, typography, spacing and design tokens | Planned |
| `SPForms` | Inputs, validation and submission handling | Planned |
| `SPStorage` | Preferences, secure storage and caching abstractions | Planned |

Only features marked as available should be considered part of the current
public API.

## Available features

The current `SPLayout` foundation includes:

- Mobile-first responsive resolution.
- Bootstrap-inspired 12-column grid.
- Six default breakpoints.
- Responsive value inheritance.
- Fixed and fluid containers.
- Wrapping rows with configurable gutters.
- Responsive column spans.
- Platform-adaptive application bar.
- No duplicate responsive widget trees.
- Zero third-party runtime dependency goal.

## Breakpoints

Sixplace uses familiar mobile-first breakpoint boundaries:

| Breakpoint | Minimum width |
|---|---:|
| `xs` | 0 px |
| `sm` | 576 px |
| `md` | 768 px |
| `lg` | 992 px |
| `xl` | 1200 px |
| `xxl` | 1400 px |

A value continues applying until it is overridden at a larger breakpoint.

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

## Getting started

After Sixplace is published, install it with:

```bash
flutter pub add sixplace
```

When using FVM:

```bash
fvm flutter pub add sixplace
```

For local package development:

```yaml
dependencies:
  sixplace:
    path: ../
```

Import the complete public API:

```dart
import 'package:sixplace/sixplace.dart';
```

Or import only the layout API:

```dart
import 'package:sixplace/layout.dart';
```

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

This is equivalent to the following Bootstrap structure:

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

### Platform-adaptive app bar

```dart
Scaffold(
  appBar: const SPAppBar(
    title: 'Sixplace',
  ),
  body: const YourPageContent(),
)
```

`SPAppBar` automatically applies:

- Material styling on Android, web, and desktop.
- iOS-style height, colours, typography, alignment, and separator on iOS.
- Dark-mode-aware colours.
- Automatic back and drawer handling.

You can override the automatic title alignment:

```dart
SPAppBar(
  title: 'Sixplace',
  centerTitle: false,
)
```

## Design principles

Sixplace follows these principles:

1. Mobile-first responsive behaviour.
2. One widget tree for every screen size.
3. Minimal and readable APIs.
4. Predictable breakpoint inheritance.
5. Flutter-first implementation.
6. Zero unnecessary runtime dependencies.
7. Tested public behaviour.
8. Backward-compatible APIs whenever possible.

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

Resize the browser window to test the responsive breakpoints.

## Contributing

Contributions are welcome.

You can contribute by:

- Reporting bugs.
- Suggesting features.
- Improving documentation.
- Adding tests.
- Fixing valid issues.
- Improving performance or accessibility.
- Submitting carefully scoped pull requests.

Recommended workflow:

1. Fork this repository.
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

For large features or architectural changes, please open an issue before
starting implementation.

Pull requests are reviewed for correctness, test coverage, API consistency,
maintainability, and alignment with the Sixplace architecture. Valid
contributions will be accepted at the maintainer's discretion.

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
