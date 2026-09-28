# Sixplace example

This example application demonstrates the public Sixplace foundations without
requiring production credentials or external services.

## Layout and numeric sizing

```bash
flutter run -t lib/main.dart
```

## Networking

The networking demo uses an injected mock HTTP transport and does not call an
external server.

```bash
flutter run -t lib/network_main.dart
```

## Feedback, theme, forms and storage

This demo combines `SPFeedback`, `SPTheme`, `SPForms` and `SPStorage`. The
storage example intentionally uses the included in-memory adapters so no native
plugin configuration is required.

```bash
flutter run -t lib/foundations_main.dart
```
