import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixplace/feedback.dart';
import 'package:sixplace/forms.dart';
import 'package:sixplace/network.dart';
import 'package:sixplace/room.dart';
import 'package:sixplace/sixplace.dart' as sixplace;
import 'package:sixplace/storage.dart';
import 'package:sixplace/theme.dart';

void main() {
  test('umbrella entry point exports SPRoom', () {
    expect(sixplace.SPRoomSqlType.integer, SPRoomSqlType.integer);
    const schema = sixplace.SPRoomEntitySchema(
      tableName: 'sample',
      columns: [
        sixplace.SPRoomColumn(name: 'id', type: sixplace.SPRoomSqlType.integer),
      ],
    );
    expect(schema, isA<SPRoomEntitySchema>());
  });

  test('foundation entry points expose their public APIs', () {
    expect(SPFeedbackType.values, isNotEmpty);
    expect(SPTheme.light(), isA<ThemeData>());
    expect(SPValidators.required()(''), isNotNull);

    final storage = SPStorage(
      preferences: SPMemoryPreferencesStore(),
      secure: SPMemorySecureStore(),
    );
    expect(storage.cache.maxEntries, greaterThan(0));

    final network = SPNetworkConfig(baseUrl: 'https://example.com/api/');
    expect(network.baseUri.host, 'example.com');

    const roomEntity = SPRoomEntitySchema(
      tableName: 'sample',
      columns: <SPRoomColumn>[
        SPRoomColumn(name: 'id', type: SPRoomSqlType.integer, primaryKey: true),
      ],
    );
    expect(roomEntity.tableName, 'sample');
  });
}
