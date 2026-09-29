import 'package:sqflite_common/sqlite_api.dart';

import 'sp_room_default_factory_stub.dart'
    if (dart.library.io) 'sp_room_default_factory_io.dart'
    as platform;

DatabaseFactory? spRoomDefaultDatabaseFactory() =>
    platform.spRoomDefaultDatabaseFactory();
