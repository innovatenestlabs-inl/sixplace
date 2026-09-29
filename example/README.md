# Sixplace example

This example application demonstrates the public Sixplace foundations without
requiring production credentials or external services.

## Compact foundations example

The main example combines responsive layout, numeric sizing and typography,
theme tokens, a validated form, an offline HTTP request, feedback, and in-memory
preferences/cache. On Android, iOS and macOS it also saves notes through SPRoom
and displays a reactive query. Its schema and adapter are shared with
`lib/room_main.dart`. Other platforms can use the form without SQLite or inject
a compatible database factory as described in the package README.

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

## SPRoom

The Room-style SQLite example demonstrates an entity schema, typed adapter,
DAO, database builder, inserts and a reactive `watch()` query.

On Android, iOS and macOS, SPRoom uses `sqflite` automatically:

```bash
flutter run -t lib/room_main.dart
```

For Linux, Windows or web, inject a compatible sqflite database factory as
described in the package README before running this target.
