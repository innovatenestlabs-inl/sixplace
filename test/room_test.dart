import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sixplace/room.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Todo {
  const _Todo({this.id, required this.title, this.done = false});

  final int? id;
  final String title;
  final bool done;
}

const _todoSchema = SPRoomEntitySchema(
  tableName: 'todos',
  columns: <SPRoomColumn>[
    SPRoomColumn(
      name: 'id',
      type: SPRoomSqlType.integer,
      primaryKey: true,
      autoIncrement: true,
    ),
    SPRoomColumn(name: 'title', type: SPRoomSqlType.text),
    SPRoomColumn(
      name: 'done',
      type: SPRoomSqlType.integer,
      defaultValueSql: '0',
    ),
  ],
  indices: <SPRoomIndex>[
    SPRoomIndex(name: 'idx_todos_done', columns: <String>['done']),
  ],
);

const _todoSchemaV1 = SPRoomEntitySchema(
  tableName: 'todos',
  columns: <SPRoomColumn>[
    SPRoomColumn(
      name: 'id',
      type: SPRoomSqlType.integer,
      primaryKey: true,
      autoIncrement: true,
    ),
    SPRoomColumn(name: 'title', type: SPRoomSqlType.text),
  ],
);

class _TodoAdapter extends SPRoomEntityAdapter<_Todo> {
  @override
  SPRoomEntitySchema get schema => _todoSchema;

  @override
  _Todo fromRow(Map<String, Object?> row) => _Todo(
    id: (row['id'] as num?)?.toInt(),
    title: row['title']! as String,
    done: (row['done'] as num? ?? 0).toInt() != 0,
  );

  @override
  Map<String, Object?> toRow(_Todo entity) => <String, Object?>{
    'id': entity.id,
    'title': entity.title,
    'done': entity.done ? 1 : 0,
  };
}

class _TodoAdapterV1 extends SPRoomEntityAdapter<_Todo> {
  @override
  SPRoomEntitySchema get schema => _todoSchemaV1;

  @override
  _Todo fromRow(Map<String, Object?> row) =>
      _Todo(id: (row['id'] as num?)?.toInt(), title: row['title']! as String);

  @override
  Map<String, Object?> toRow(_Todo entity) => <String, Object?>{
    'id': entity.id,
    'title': entity.title,
  };
}

class _TestDatabase extends SPRoomDatabase {
  late final SPRoomDao<_Todo> todos = SPRoomDao<_Todo>(this, _TodoAdapter());
}

class _TestDatabaseV1 extends SPRoomDatabase {
  late final SPRoomDao<_Todo> todos = SPRoomDao<_Todo>(this, _TodoAdapterV1());
}

void main() {
  setUpAll(sqfliteFfiInit);

  Future<_TestDatabase> openMemoryDatabase() =>
      SPRoom.inMemoryDatabaseBuilder<_TestDatabase>(
        version: 1,
        create: _TestDatabase.new,
        entities: const <SPRoomEntitySchema>[_todoSchema],
        factory: databaseFactoryFfi,
      ).build();

  test('WITHOUT ROWID integer primary keys validate and reject null', () async {
    const schema = SPRoomEntitySchema(
      tableName: 'entries',
      withoutRowId: true,
      columns: [
        SPRoomColumn(name: 'id', type: SPRoomSqlType.integer, primaryKey: true),
      ],
    );
    final db = await SPRoom.inMemoryDatabaseBuilder<_TestDatabase>(
      version: 1,
      create: _TestDatabase.new,
      entities: const [schema],
      factory: databaseFactoryFfi,
    ).build();
    addTearDown(db.close);
    await db.rawWrite([
      'entries',
    ], (executor) => executor.insert('entries', {'id': 1}));
    await expectLater(
      db.rawWrite([
        'entries',
      ], (executor) => executor.insert('entries', {'id': null})),
      throwsA(isA<DatabaseException>()),
    );
    final rows = await db.rawRead((executor) => executor.query('entries'));
    expect(rows.single['id'], 1);
  });

  test(
    'transactions keep separate database writes and invalidations isolated',
    () async {
      final first = await openMemoryDatabase();
      final second = await openMemoryDatabase();
      addTearDown(first.close);
      addTearDown(second.close);
      final firstChanges = <Set<String>>[];
      final secondChanges = <Set<String>>[];
      final firstSubscription = first.invalidationTracker.changes.listen(
        firstChanges.add,
      );
      final secondSubscription = second.invalidationTracker.changes.listen(
        secondChanges.add,
      );
      addTearDown(firstSubscription.cancel);
      addTearDown(secondSubscription.cancel);

      await first.writeTransaction(() async {
        await first.todos.insert(const _Todo(title: 'First database'));
        await second.writeTransaction(() async {
          await second.todos.insert(const _Todo(title: 'Second database'));
          await first.todos.insert(const _Todo(title: 'Still first database'));
        });
        expect(firstChanges, isEmpty);
        expect(secondChanges, hasLength(1));
      });

      expect(
        (await first.todos.getAll(orderBy: 'id')).map((row) => row.title),
        ['First database', 'Still first database'],
      );
      expect((await second.todos.getAll()).single.title, 'Second database');
      expect(firstChanges, hasLength(1));
      expect(secondChanges, hasLength(1));
    },
  );

  test(
    'failed transactions roll back rows without emitting invalidations',
    () async {
      final db = await openMemoryDatabase();
      addTearDown(db.close);
      final changes = <Set<String>>[];
      final subscription = db.invalidationTracker.changes.listen(changes.add);
      addTearDown(subscription.cancel);

      await expectLater(
        db.writeTransaction<void>(() async {
          await db.todos.insert(const _Todo(title: 'Rolled back'));
          throw StateError('Abort transaction');
        }),
        throwsStateError,
      );

      expect(await db.todos.count(), 0);
      expect(changes, isEmpty);
      await db.todos.insert(const _Todo(title: 'Committed'));
      expect(await db.todos.count(), 1);
      expect(changes, hasLength(1));
    },
  );

  test(
    'missing migrations fail while preserving the original database',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'sixplace_room_missing_',
      );
      addTearDown(() => temp.delete(recursive: true));
      final path = '${temp.path}${Platform.pathSeparator}migration.db';
      Future<_TestDatabaseV1> openV1() =>
          SPRoom.databaseBuilder<_TestDatabaseV1>(
            name: 'migration.db',
            version: 1,
            create: _TestDatabaseV1.new,
            entities: const [_todoSchemaV1],
            factory: databaseFactoryFfi,
          ).databasePath(path).build();
      final original = await openV1();
      await original.todos.insert(const _Todo(title: 'Preserved'));
      await original.close();

      await expectLater(
        SPRoom.databaseBuilder<_TestDatabase>(
          name: 'migration.db',
          version: 2,
          create: _TestDatabase.new,
          entities: const [_todoSchema],
          factory: databaseFactoryFfi,
        ).databasePath(path).build(),
        throwsA(isA<SPRoomMissingMigrationException>()),
      );

      final reopened = await openV1();
      addTearDown(reopened.close);
      expect((await reopened.todos.getAll()).single.title, 'Preserved');
      expect(reopened.version, 1);
    },
  );

  test(
    'SPRoom provides Room-style CRUD, transactions and reactive queries',
    () async {
      final db = await SPRoom.inMemoryDatabaseBuilder<_TestDatabase>(
        version: 1,
        create: _TestDatabase.new,
        entities: const <SPRoomEntitySchema>[_todoSchema],
        factory: databaseFactoryFfi,
      ).build();
      addTearDown(db.close);

      final firstId = await db.todos.insert(const _Todo(title: 'First'));
      expect(firstId, greaterThan(0));

      final first = await db.todos.findById(firstId);
      expect(first?.title, 'First');
      expect(first?.done, isFalse);

      await db.todos.update(_Todo(id: firstId, title: 'First', done: true));
      expect((await db.todos.findById(firstId))?.done, isTrue);

      final emissions = db.todos.watch(orderBy: 'id').take(2).toList();
      await Future<void>.delayed(Duration.zero);
      await db.todos.insert(const _Todo(title: 'Second'));
      final snapshots = await emissions;
      expect(snapshots.first.length, 1);
      expect(snapshots.last.length, 2);

      await db.writeTransaction<void>(() async {
        await db.todos.insert(const _Todo(title: 'Third'));
        await db.todos.insert(const _Todo(title: 'Fourth'));
      });
      expect(await db.todos.count(), 4);

      await db.clearAllTables();
      expect(await db.todos.count(), 0);
    },
  );

  test(
    'SPRoom applies explicit migrations and validates the target schema',
    () async {
      final temp = await Directory.systemTemp.createTemp('sixplace_room_test_');
      addTearDown(() async {
        await temp.delete(recursive: true);
      });
      final path = '${temp.path}${Platform.pathSeparator}migration.db';

      final v1 = await SPRoom.databaseBuilder<_TestDatabaseV1>(
        name: 'migration.db',
        version: 1,
        create: _TestDatabaseV1.new,
        entities: const <SPRoomEntitySchema>[_todoSchemaV1],
        factory: databaseFactoryFfi,
      ).databasePath(path).build();
      await v1.todos.insert(const _Todo(title: 'Preserved'));
      await v1.close();

      final v2 =
          await SPRoom.databaseBuilder<_TestDatabase>(
            name: 'migration.db',
            version: 2,
            create: _TestDatabase.new,
            entities: const <SPRoomEntitySchema>[_todoSchema],
            factory: databaseFactoryFfi,
          ).databasePath(path).addMigrations(<SPRoomMigration>[
            SPRoomMigration(1, 2, (database) async {
              await database.execute(
                'ALTER TABLE todos ADD COLUMN done INTEGER NOT NULL DEFAULT 0',
              );
              await database.execute(
                'CREATE INDEX IF NOT EXISTS idx_todos_done ON todos (done)',
              );
            }),
          ]).build();
      addTearDown(v2.close);

      final rows = await v2.todos.getAll();
      expect(rows, hasLength(1));
      expect(rows.single.title, 'Preserved');
      expect(rows.single.done, isFalse);
    },
  );
}
