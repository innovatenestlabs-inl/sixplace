/// Sixplace's Room-inspired SQLite persistence layer.
///
/// SPRoom follows the Database / Entity / DAO / Migration / Transaction model
/// familiar from AndroidX Room in Kotlin Android projects while using the
/// sqflite ecosystem underneath.
///
/// Design acknowledgement: special thanks to the AndroidX Room team for the
/// persistence architecture that inspired this API, and to the sqflite
/// maintainers/contributors for the Flutter/Dart SQLite foundation used by
/// SPRoom.
library;

export 'src/room/sp_room.dart';
