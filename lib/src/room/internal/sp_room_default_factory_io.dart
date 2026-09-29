import 'dart:io';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqlite_api.dart';

DatabaseFactory? spRoomDefaultDatabaseFactory() {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    return sqflite.databaseFactory;
  }
  return null;
}
