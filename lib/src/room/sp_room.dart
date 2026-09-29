import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';

import 'internal/sp_room_default_factory.dart';

/// SQLite storage class used by [SPRoomColumn].
enum SPRoomSqlType {
  /// INTEGER affinity.
  integer('INTEGER'),

  /// REAL affinity.
  real('REAL'),

  /// TEXT affinity.
  text('TEXT'),

  /// BLOB affinity.
  blob('BLOB'),

  /// NUMERIC affinity.
  numeric('NUMERIC');

  const SPRoomSqlType(this.sql);

  /// SQLite type declaration emitted into CREATE TABLE statements.
  final String sql;
}

/// Foreign-key action supported by SQLite.
enum SPRoomForeignKeyAction {
  /// NO ACTION.
  noAction('NO ACTION'),

  /// RESTRICT.
  restrict('RESTRICT'),

  /// SET NULL.
  setNull('SET NULL'),

  /// SET DEFAULT.
  setDefault('SET DEFAULT'),

  /// CASCADE.
  cascade('CASCADE');

  const SPRoomForeignKeyAction(this.sql);

  /// SQL fragment emitted for this action.
  final String sql;
}

/// Conflict strategy for insert/update operations.
enum SPRoomConflictStrategy {
  /// Abort the statement and preserve the transaction.
  abort,

  /// Fail the current statement.
  fail,

  /// Ignore the conflicting row.
  ignore,

  /// Replace the conflicting row.
  replace,

  /// Roll back the current transaction.
  rollback,
}

/// Declarative column metadata for an [SPRoomEntitySchema].
class SPRoomColumn {
  /// Creates a column definition.
  const SPRoomColumn({
    required this.name,
    required this.type,
    this.nullable = false,
    this.primaryKey = false,
    this.autoIncrement = false,
    this.unique = false,
    this.defaultValueSql,
    this.checkSql,
  });

  /// Column name.
  final String name;

  /// SQLite affinity.
  final SPRoomSqlType type;

  /// Whether NULL values are accepted.
  final bool nullable;

  /// Whether this column is part of the table primary key.
  final bool primaryKey;

  /// Whether an INTEGER single-column primary key uses AUTOINCREMENT.
  final bool autoIncrement;

  /// Whether the column has a UNIQUE constraint.
  final bool unique;

  /// Optional raw SQL default expression, for example `0` or `CURRENT_TIMESTAMP`.
  final String? defaultValueSql;

  /// Optional raw CHECK expression without the surrounding `CHECK (...)`.
  final String? checkSql;
}

/// Declarative foreign-key metadata.
class SPRoomForeignKey {
  /// Creates a foreign key.
  const SPRoomForeignKey({
    required this.columns,
    required this.referencedTable,
    required this.referencedColumns,
    this.onDelete = SPRoomForeignKeyAction.noAction,
    this.onUpdate = SPRoomForeignKeyAction.noAction,
    this.deferred = false,
  });

  /// Local columns participating in the key.
  final List<String> columns;

  /// Referenced table name.
  final String referencedTable;

  /// Referenced columns, in the same order as [columns].
  final List<String> referencedColumns;

  /// Action when the referenced row is deleted.
  final SPRoomForeignKeyAction onDelete;

  /// Action when the referenced key is updated.
  final SPRoomForeignKeyAction onUpdate;

  /// Whether constraint checking is deferred until transaction commit.
  final bool deferred;
}

/// Declarative SQLite index metadata.
class SPRoomIndex {
  /// Creates an index definition.
  const SPRoomIndex({
    required this.name,
    required this.columns,
    this.unique = false,
    this.whereSql,
  });

  /// Stable index name.
  final String name;

  /// Indexed columns, in order.
  final List<String> columns;

  /// Whether duplicate indexed values are rejected.
  final bool unique;

  /// Optional raw partial-index WHERE expression.
  final String? whereSql;
}

/// Describes one SQLite table managed by SPRoom.
///
/// This is the Dart equivalent of the schema information that Android Room
/// normally derives from `@Entity` declarations at compile time. Flutter does
/// not provide Kotlin/KSP-style reflection, so Sixplace keeps the schema
/// explicit and strongly structured rather than relying on fragile runtime
/// mirrors.
class SPRoomEntitySchema {
  /// Creates an entity/table schema.
  const SPRoomEntitySchema({
    required this.tableName,
    required this.columns,
    this.foreignKeys = const <SPRoomForeignKey>[],
    this.indices = const <SPRoomIndex>[],
    this.withoutRowId = false,
  });

  /// SQLite table name.
  final String tableName;

  /// Columns in declaration order.
  final List<SPRoomColumn> columns;

  /// Foreign-key constraints.
  final List<SPRoomForeignKey> foreignKeys;

  /// Explicit secondary indices.
  final List<SPRoomIndex> indices;

  /// Emits `WITHOUT ROWID` for compatible schemas.
  final bool withoutRowId;

  /// Primary-key columns in declaration order.
  List<SPRoomColumn> get primaryKeyColumns =>
      columns.where((column) => column.primaryKey).toList(growable: false);

  /// SQL statement that creates this table.
  String get createTableSql {
    _validateDefinition();
    final primaryKeys = primaryKeyColumns;
    final singlePrimaryKey = primaryKeys.length == 1
        ? primaryKeys.single
        : null;
    final definitions = <String>[];

    for (final column in columns) {
      final buffer = StringBuffer()
        ..write(_quoteIdentifier(column.name))
        ..write(' ')
        ..write(column.type.sql);

      if (identical(column, singlePrimaryKey)) {
        buffer.write(' PRIMARY KEY');
        if (column.autoIncrement) {
          buffer.write(' AUTOINCREMENT');
        }
      }
      if (!column.nullable &&
          !(!withoutRowId &&
              identical(column, singlePrimaryKey) &&
              column.type == SPRoomSqlType.integer)) {
        buffer.write(' NOT NULL');
      }
      if (column.unique) {
        buffer.write(' UNIQUE');
      }
      if (column.defaultValueSql != null) {
        buffer.write(' DEFAULT ${column.defaultValueSql}');
      }
      if (column.checkSql != null) {
        buffer.write(' CHECK (${column.checkSql})');
      }
      definitions.add(buffer.toString());
    }

    if (primaryKeys.length > 1) {
      definitions.add(
        'PRIMARY KEY (${primaryKeys.map((e) => _quoteIdentifier(e.name)).join(', ')})',
      );
    }

    for (final key in foreignKeys) {
      final local = key.columns.map(_quoteIdentifier).join(', ');
      final remote = key.referencedColumns.map(_quoteIdentifier).join(', ');
      final buffer = StringBuffer()
        ..write('FOREIGN KEY ($local) REFERENCES ')
        ..write(_quoteIdentifier(key.referencedTable))
        ..write(' ($remote)')
        ..write(' ON DELETE ${key.onDelete.sql}')
        ..write(' ON UPDATE ${key.onUpdate.sql}');
      if (key.deferred) {
        buffer.write(' DEFERRABLE INITIALLY DEFERRED');
      }
      definitions.add(buffer.toString());
    }

    return 'CREATE TABLE IF NOT EXISTS ${_quoteIdentifier(tableName)} '
        '(${definitions.join(', ')})${withoutRowId ? ' WITHOUT ROWID' : ''}';
  }

  /// SQL statements that create all explicit indices.
  List<String> get createIndexSql {
    _validateDefinition();
    return indices
        .map(
          (index) =>
              'CREATE ${index.unique ? 'UNIQUE ' : ''}INDEX IF NOT EXISTS '
              '${_quoteIdentifier(index.name)} ON ${_quoteIdentifier(tableName)} '
              '(${index.columns.map(_quoteIdentifier).join(', ')})'
              '${index.whereSql == null ? '' : ' WHERE ${index.whereSql}'}',
        )
        .toList(growable: false);
  }

  void _validateDefinition() {
    if (tableName.trim().isEmpty) {
      throw const SPRoomSchemaException('Entity tableName cannot be empty.');
    }
    if (columns.isEmpty) {
      throw SPRoomSchemaException(
        '$tableName must declare at least one column.',
      );
    }
    final columnNames = <String>{};
    for (final column in columns) {
      if (column.name.trim().isEmpty) {
        throw SPRoomSchemaException('$tableName has an empty column name.');
      }
      if (!columnNames.add(column.name)) {
        throw SPRoomSchemaException(
          '$tableName declares duplicate column "${column.name}".',
        );
      }
      if (column.primaryKey && column.nullable) {
        throw SPRoomSchemaException(
          '$tableName.${column.name}: primary-key columns cannot be nullable.',
        );
      }
      if (column.autoIncrement &&
          (!column.primaryKey || column.type != SPRoomSqlType.integer)) {
        throw SPRoomSchemaException(
          '$tableName.${column.name}: AUTOINCREMENT requires an INTEGER primary key.',
        );
      }
    }

    final primaryKeys = primaryKeyColumns;
    if (withoutRowId && primaryKeys.isEmpty) {
      throw SPRoomSchemaException(
        '$tableName: WITHOUT ROWID requires a primary key.',
      );
    }
    if (withoutRowId && primaryKeys.any((column) => column.autoIncrement)) {
      throw SPRoomSchemaException(
        '$tableName: AUTOINCREMENT cannot be used with WITHOUT ROWID.',
      );
    }
    if (primaryKeys.length > 1 &&
        primaryKeys.any((column) => column.autoIncrement)) {
      throw SPRoomSchemaException(
        '$tableName: AUTOINCREMENT is not valid on a composite primary key.',
      );
    }

    final indexNames = <String>{};
    for (final index in indices) {
      if (index.name.trim().isEmpty || index.columns.isEmpty) {
        throw SPRoomSchemaException('$tableName contains an invalid index.');
      }
      if (!indexNames.add(index.name)) {
        throw SPRoomSchemaException(
          '$tableName declares duplicate index "${index.name}".',
        );
      }
      for (final column in index.columns) {
        if (!columnNames.contains(column)) {
          throw SPRoomSchemaException(
            '${index.name} references missing column $tableName.$column.',
          );
        }
      }
    }

    for (final key in foreignKeys) {
      if (key.columns.isEmpty ||
          key.columns.length != key.referencedColumns.length) {
        throw SPRoomSchemaException(
          '$tableName has a foreign key with mismatched columns.',
        );
      }
      for (final column in key.columns) {
        if (!columnNames.contains(column)) {
          throw SPRoomSchemaException(
            '$tableName foreign key references missing local column $column.',
          );
        }
      }
    }
  }
}

/// Converts a Dart entity to/from rows for a specific table.
///
/// Subclass this once per entity. The adapter is intentionally explicit so
/// model mapping stays tree-shakeable and predictable on every Flutter target.
abstract class SPRoomEntityAdapter<T> {
  /// Schema associated with this model.
  SPRoomEntitySchema get schema;

  /// Converts [entity] to SQLite-compatible column values.
  Map<String, Object?> toRow(T entity);

  /// Creates an entity from a database row.
  T fromRow(Map<String, Object?> row);

  /// Resolves the primary-key values from [entity].
  ///
  /// The default implementation reads the columns declared as primary keys
  /// from [toRow]. Override this for custom mapping behavior.
  Map<String, Object?> primaryKeyOf(T entity) {
    final keys = schema.primaryKeyColumns;
    if (keys.isEmpty) {
      throw SPRoomSchemaException(
        '${schema.tableName} has no primary key; entity update/delete requires one.',
      );
    }
    final row = toRow(entity);
    return <String, Object?>{for (final key in keys) key.name: row[key.name]};
  }
}

/// Converts custom application types into values accepted by sqflite.
abstract interface class SPRoomTypeConverter<T, D> {
  /// Converts an application value before persistence.
  D encode(T value);

  /// Recreates the application value from a database value.
  T decode(D value);
}

/// A migration from [startVersion] to [endVersion].
///
/// Like Android Room migrations, each step is explicit and runs inside the
/// database version-change transaction provided by sqflite.
class SPRoomMigration {
  /// Creates a migration step.
  const SPRoomMigration(this.startVersion, this.endVersion, this.migrate)
    : assert(startVersion > 0),
      assert(endVersion > 0),
      assert(startVersion != endVersion);

  /// Source schema version.
  final int startVersion;

  /// Destination schema version.
  final int endVersion;

  /// Migration body.
  final FutureOr<void> Function(SPRoomExecutor database) migrate;
}

/// Lifecycle callback for an SPRoom database.
class SPRoomCallback {
  /// Creates a callback.
  const SPRoomCallback({
    this.onCreate,
    this.onOpen,
    this.onDestructiveMigration,
  });

  /// Runs after a brand-new schema has been created.
  final FutureOr<void> Function(SPRoomExecutor database)? onCreate;

  /// Runs whenever the database has finished opening and schema validation.
  final FutureOr<void> Function(SPRoomExecutor database)? onOpen;

  /// Runs after destructive migration recreates all managed tables.
  final FutureOr<void> Function(
    SPRoomExecutor database,
    int oldVersion,
    int newVersion,
  )?
  onDestructiveMigration;
}

/// Thin public wrapper around a sqflite database/transaction executor.
///
/// Use this for custom SQL in migrations and specialized DAO methods. Regular
/// application code should generally prefer [SPRoomDao].
class SPRoomExecutor {
  SPRoomExecutor._(this._executor);

  final DatabaseExecutor _executor;

  /// Executes a SQL statement without returning rows.
  Future<void> execute(String sql, [List<Object?>? arguments]) =>
      _executor.execute(sql, arguments);

  /// Executes a raw SELECT and returns row maps.
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) => _executor.rawQuery(sql, arguments);

  /// Executes a raw INSERT and returns the inserted row id.
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) =>
      _executor.rawInsert(sql, arguments);

  /// Executes a raw UPDATE and returns the affected row count.
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) =>
      _executor.rawUpdate(sql, arguments);

  /// Executes a raw DELETE and returns the affected row count.
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) =>
      _executor.rawDelete(sql, arguments);

  /// Inserts [values] into [table].
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    SPRoomConflictStrategy? conflictStrategy,
  }) => _executor.insert(
    table,
    values,
    nullColumnHack: nullColumnHack,
    conflictAlgorithm: _toSqfliteConflict(conflictStrategy),
  );

  /// Updates rows in [table].
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    SPRoomConflictStrategy? conflictStrategy,
  }) => _executor.update(
    table,
    values,
    where: where,
    whereArgs: whereArgs,
    conflictAlgorithm: _toSqfliteConflict(conflictStrategy),
  );

  /// Deletes rows from [table].
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      _executor.delete(table, where: where, whereArgs: whereArgs);

  /// Queries [table] with sqflite-style query arguments.
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) => _executor.query(
    table,
    distinct: distinct,
    columns: columns,
    where: where,
    whereArgs: whereArgs,
    groupBy: groupBy,
    having: having,
    orderBy: orderBy,
    limit: limit,
    offset: offset,
  );
}

/// Broadcast invalidation tracker used by reactive DAO queries.
///
/// Changes made through [SPRoomDao] and [SPRoomDatabase.notifyTablesChanged]
/// participate in invalidation. SQL written directly through another database
/// connection cannot be observed automatically.
class SPRoomInvalidationTracker {
  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast(sync: true);

  /// Stream of changed table-name sets.
  Stream<Set<String>> get changes => _controller.stream;

  /// Watches invalidation events for [table].
  Stream<void> watchTable(String table) =>
      changes.where((tables) => tables.contains(table)).map<void>((_) {});

  void _notify(Set<String> tables) {
    if (tables.isNotEmpty && !_controller.isClosed) {
      _controller.add(Set<String>.unmodifiable(tables));
    }
  }

  Future<void> _close() => _controller.close();
}

/// Base class for an application SPRoom database.
///
/// Create a lightweight subclass that exposes your DAOs, then instantiate it
/// through [SPRoom.databaseBuilder] or [SPRoom.inMemoryDatabaseBuilder].
abstract class SPRoomDatabase {
  Database? _database;
  DatabaseFactory? _factory;
  String? _path;
  int? _version;
  List<SPRoomEntitySchema> _entities = const <SPRoomEntitySchema>[];
  final SPRoomInvalidationTracker _invalidationTracker =
      SPRoomInvalidationTracker();

  final Object _transactionZoneKey = Object();

  /// Whether the underlying database is currently open.
  bool get isOpen => _database?.isOpen ?? false;

  /// Opened database path, or an empty string before [SPRoomDatabaseBuilder.build].
  String get path => _path ?? '';

  /// Configured schema version.
  int get version => _version ?? 0;

  /// Managed entity schemas.
  List<SPRoomEntitySchema> get entities =>
      List<SPRoomEntitySchema>.unmodifiable(_entities);

  /// Reactive table invalidation tracker.
  SPRoomInvalidationTracker get invalidationTracker => _invalidationTracker;

  Database get _requireDatabase {
    final database = _database;
    if (database == null || !database.isOpen) {
      throw StateError('SPRoom database is not open. Call build() first.');
    }
    return database;
  }

  _SPRoomTransactionContext? get _transactionContext =>
      Zone.current[_transactionZoneKey] as _SPRoomTransactionContext?;

  DatabaseExecutor get _currentExecutor =>
      _transactionContext?.transaction ?? _requireDatabase;

  /// Runs [action] atomically.
  ///
  /// DAO operations invoked inside [action] automatically use the same sqflite
  /// transaction, avoiding the deadlock-prone pattern of calling the outer
  /// Database object from inside a transaction callback.
  Future<R> writeTransaction<R>(Future<R> Function() action) async {
    final existing = _transactionContext;
    if (existing != null) {
      return action();
    }

    final changedTables = <String>{};
    final result = await _requireDatabase.transaction<R>((transaction) async {
      final context = _SPRoomTransactionContext(transaction, changedTables);
      return runZoned<Future<R>>(
        action,
        zoneValues: <Object, Object>{_transactionZoneKey: context},
      );
    });
    _invalidationTracker._notify(changedTables);
    return result;
  }

  /// Room/KTX-style alias for [writeTransaction].
  Future<R> withTransaction<R>(Future<R> Function() action) =>
      writeTransaction<R>(action);

  /// Room-style alias for [writeTransaction].
  Future<R> runInTransaction<R>(Future<R> Function() action) =>
      writeTransaction<R>(action);

  /// Deletes all rows from every managed table in one transaction.
  Future<void> clearAllTables() => writeTransaction<void>(() async {
    await _currentExecutor.execute('PRAGMA defer_foreign_keys = ON');
    for (final entity in _entities.reversed) {
      await _currentExecutor.delete(entity.tableName);
      _markTablesChanged(<String>{entity.tableName});
    }
  });

  /// Explicitly marks tables as changed after custom raw SQL.
  ///
  /// Use this after writes performed outside [SPRoomDao] so reactive queries
  /// are refreshed.
  void notifyTablesChanged(Iterable<String> tables) {
    _markTablesChanged(tables.toSet());
  }

  /// Runs a custom SQL read using the transaction-aware executor.
  Future<R> rawRead<R>(Future<R> Function(SPRoomExecutor database) action) =>
      action(SPRoomExecutor._(_currentExecutor));

  /// Runs custom SQL atomically and invalidates [changedTables] after commit.
  Future<R> rawWrite<R>(
    Iterable<String> changedTables,
    Future<R> Function(SPRoomExecutor database) action,
  ) => writeTransaction<R>(() async {
    final result = await action(SPRoomExecutor._(_currentExecutor));
    _markTablesChanged(changedTables.toSet());
    return result;
  });

  /// Closes and deletes the database file.
  ///
  /// In-memory databases are only closed. A closed SPRoomDatabase instance is
  /// not reusable; build a new instance if the application needs to reopen it.
  Future<void> closeAndDelete() async {
    final factory = _factory;
    final databasePath = _path;
    await close();
    if (factory != null && databasePath != null && databasePath != ':memory:') {
      await factory.deleteDatabase(databasePath);
    }
  }

  /// Closes the underlying SQLite connection and invalidation stream.
  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null && database.isOpen) {
      await database.close();
    }
    await _invalidationTracker._close();
  }

  void _markTablesChanged(Set<String> tables) {
    if (tables.isEmpty) return;
    final context = _transactionContext;
    if (context != null) {
      context.changedTables.addAll(tables);
    } else {
      _invalidationTracker._notify(tables);
    }
  }

  void _attach({
    required Database database,
    required DatabaseFactory factory,
    required String path,
    required int version,
    required List<SPRoomEntitySchema> entities,
  }) {
    if (_database != null) {
      throw StateError('This SPRoomDatabase instance is already attached.');
    }
    _database = database;
    _factory = factory;
    _path = path;
    _version = version;
    _entities = List<SPRoomEntitySchema>.unmodifiable(entities);
  }
}

/// Generic DAO with Room-style CRUD, raw queries, transactions and streams.
///
/// Subclass this class to add domain-specific query methods while retaining the
/// common insert/update/delete/query behavior.
class SPRoomDao<T> {
  /// Creates a DAO bound to [database] and [adapter].
  SPRoomDao(this.database, this.adapter);

  /// Owning database.
  final SPRoomDatabase database;

  /// Entity mapper/schema.
  final SPRoomEntityAdapter<T> adapter;

  String get _table => adapter.schema.tableName;

  /// Inserts [entity] and returns the SQLite row id.
  Future<int> insert(
    T entity, {
    SPRoomConflictStrategy strategy = SPRoomConflictStrategy.abort,
  }) async {
    final id = await database._currentExecutor.insert(
      _table,
      adapter.toRow(entity),
      conflictAlgorithm: _toSqfliteConflict(strategy),
    );
    database._markTablesChanged(<String>{_table});
    return id;
  }

  /// Inserts all [entities] atomically and returns their row ids.
  Future<List<int>> insertAll(
    Iterable<T> entities, {
    SPRoomConflictStrategy strategy = SPRoomConflictStrategy.abort,
  }) => database.writeTransaction<List<int>>(() async {
    final ids = <int>[];
    for (final entity in entities) {
      ids.add(await insert(entity, strategy: strategy));
    }
    return ids;
  });

  /// Inserts or updates [entity] using the declared primary key.
  ///
  /// This uses SQLite `ON CONFLICT (...) DO UPDATE`, preserving row identity in
  /// contrast to `INSERT OR REPLACE`.
  Future<int> upsert(T entity) async {
    final row = adapter.toRow(entity);
    final keys = adapter.schema.primaryKeyColumns;
    if (keys.isEmpty) {
      throw SPRoomSchemaException(
        'Upsert requires a primary key on ${adapter.schema.tableName}.',
      );
    }
    if (row.isEmpty) {
      throw ArgumentError.value(row, 'entity', 'Entity row cannot be empty.');
    }

    final columns = row.keys.toList(growable: false);
    final placeholders = List<String>.filled(columns.length, '?').join(', ');
    final keyNames = keys.map((key) => key.name).toSet();
    final mutableColumns = columns.where((name) => !keyNames.contains(name));
    final updateClause = mutableColumns.isEmpty
        ? 'DO NOTHING'
        : 'DO UPDATE SET ${mutableColumns.map((name) => '${_quoteIdentifier(name)} = excluded.${_quoteIdentifier(name)}').join(', ')}';
    final sql =
        'INSERT INTO ${_quoteIdentifier(_table)} '
        '(${columns.map(_quoteIdentifier).join(', ')}) VALUES ($placeholders) '
        'ON CONFLICT (${keys.map((e) => _quoteIdentifier(e.name)).join(', ')}) '
        '$updateClause';
    final result = await database._currentExecutor.rawInsert(
      sql,
      columns.map((name) => row[name]).toList(growable: false),
    );
    database._markTablesChanged(<String>{_table});
    return result;
  }

  /// Inserts or updates all [entities] atomically.
  Future<List<int>> upsertAll(Iterable<T> entities) =>
      database.writeTransaction<List<int>>(() async {
        final ids = <int>[];
        for (final entity in entities) {
          ids.add(await upsert(entity));
        }
        return ids;
      });

  /// Updates [entity] by its declared primary key.
  Future<int> update(
    T entity, {
    SPRoomConflictStrategy strategy = SPRoomConflictStrategy.abort,
  }) async {
    final key = adapter.primaryKeyOf(entity);
    _validateKey(key);
    final row = Map<String, Object?>.from(adapter.toRow(entity));
    for (final column in key.keys) {
      row.remove(column);
    }
    if (row.isEmpty) return 0;
    final clause = _whereFromKey(key);
    final count = await database._currentExecutor.update(
      _table,
      row,
      where: clause.$1,
      whereArgs: clause.$2,
      conflictAlgorithm: _toSqfliteConflict(strategy),
    );
    if (count > 0) {
      database._markTablesChanged(<String>{_table});
    }
    return count;
  }

  /// Updates all [entities] atomically and returns the total affected rows.
  Future<int> updateAll(
    Iterable<T> entities, {
    SPRoomConflictStrategy strategy = SPRoomConflictStrategy.abort,
  }) => database.writeTransaction<int>(() async {
    var affected = 0;
    for (final entity in entities) {
      affected += await update(entity, strategy: strategy);
    }
    return affected;
  });

  /// Deletes [entity] by its declared primary key.
  Future<int> delete(T entity) async {
    final key = adapter.primaryKeyOf(entity);
    _validateKey(key);
    final clause = _whereFromKey(key);
    final count = await database._currentExecutor.delete(
      _table,
      where: clause.$1,
      whereArgs: clause.$2,
    );
    if (count > 0) {
      database._markTablesChanged(<String>{_table});
    }
    return count;
  }

  /// Deletes all [entities] atomically and returns the total affected rows.
  Future<int> deleteAll(Iterable<T> entities) =>
      database.writeTransaction<int>(() async {
        var affected = 0;
        for (final entity in entities) {
          affected += await delete(entity);
        }
        return affected;
      });

  /// Deletes rows matching [where].
  Future<int> deleteWhere({
    required String where,
    List<Object?>? whereArgs,
  }) async {
    final count = await database._currentExecutor.delete(
      _table,
      where: where,
      whereArgs: whereArgs,
    );
    if (count > 0) {
      database._markTablesChanged(<String>{_table});
    }
    return count;
  }

  /// Returns all rows using optional ordering/paging.
  Future<List<T>> getAll({String? orderBy, int? limit, int? offset}) =>
      query(orderBy: orderBy, limit: limit, offset: offset);

  /// Finds a single row by its primary-key values.
  Future<T?> findByPrimaryKey(Map<String, Object?> key) async {
    _validateKey(key);
    final clause = _whereFromKey(key);
    final rows = await database._currentExecutor.query(
      _table,
      where: clause.$1,
      whereArgs: clause.$2,
      limit: 1,
    );
    return rows.isEmpty ? null : adapter.fromRow(rows.first);
  }

  /// Convenience lookup for entities with exactly one primary-key column.
  Future<T?> findById(Object? value) {
    final keys = adapter.schema.primaryKeyColumns;
    if (keys.length != 1) {
      throw SPRoomSchemaException(
        'findById() requires exactly one primary key on $_table.',
      );
    }
    return findByPrimaryKey(<String, Object?>{keys.single.name: value});
  }

  /// Runs a structured SELECT against this entity table.
  Future<List<T>> query({
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final rows = await database._currentExecutor.query(
      _table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    return rows.map(adapter.fromRow).toList(growable: false);
  }

  /// Returns the number of rows matching an optional predicate.
  Future<int> count({String? where, List<Object?>? whereArgs}) async {
    final sql = StringBuffer(
      'SELECT COUNT(*) AS c FROM ${_quoteIdentifier(_table)}',
    );
    if (where != null && where.trim().isNotEmpty) {
      sql.write(' WHERE $where');
    }
    final rows = await database._currentExecutor.rawQuery(
      sql.toString(),
      whereArgs,
    );
    return (rows.first['c'] as num).toInt();
  }

  /// Executes a typed custom SELECT.
  Future<List<R>> rawQuery<R>(
    String sql, {
    List<Object?>? arguments,
    required R Function(Map<String, Object?> row) mapper,
  }) async {
    final rows = await database._currentExecutor.rawQuery(sql, arguments);
    return rows.map(mapper).toList(growable: false);
  }

  /// Executes custom write SQL atomically and invalidates this DAO table.
  Future<R> rawWrite<R>(
    Future<R> Function(SPRoomExecutor database) action, {
    Iterable<String> additionalChangedTables = const <String>[],
  }) => database.rawWrite<R>(<String>{
    _table,
    ...additionalChangedTables,
  }, action);

  /// Watches this table and re-runs [query] whenever it is invalidated.
  ///
  /// The returned stream immediately emits the current result before waiting
  /// for later writes, similar to observing a Room Flow/LiveData query.
  Stream<List<T>> watch({
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async* {
    Future<List<T>> load() => query(
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    final invalidations = StreamController<int>();
    final subscription = database.invalidationTracker
        .watchTable(_table)
        .listen((_) => invalidations.add(0), onDone: invalidations.close);
    try {
      yield await load();
      await for (final _ in invalidations.stream) {
        yield await load();
      }
    } finally {
      await subscription.cancel();
      if (!invalidations.isClosed) {
        await invalidations.close();
      }
    }
  }

  /// Watches a custom query that depends on [tables].
  Stream<List<R>> watchRawQuery<R>({
    required String sql,
    List<Object?>? arguments,
    required Iterable<String> tables,
    required R Function(Map<String, Object?> row) mapper,
  }) async* {
    final watchedTables = tables.toSet();
    if (watchedTables.isEmpty) {
      throw ArgumentError.value(
        tables,
        'tables',
        'At least one table is required.',
      );
    }

    Future<List<R>> load() =>
        rawQuery<R>(sql, arguments: arguments, mapper: mapper);

    final invalidations = StreamController<int>();
    final subscription = database.invalidationTracker.changes.listen((changed) {
      if (changed.any(watchedTables.contains)) {
        invalidations.add(0);
      }
    }, onDone: invalidations.close);
    try {
      yield await load();
      await for (final _ in invalidations.stream) {
        yield await load();
      }
    } finally {
      await subscription.cancel();
      if (!invalidations.isClosed) {
        await invalidations.close();
      }
    }
  }

  void _validateKey(Map<String, Object?> key) {
    final expected = adapter.schema.primaryKeyColumns
        .map((column) => column.name)
        .toSet();
    if (expected.isEmpty ||
        key.keys.toSet().difference(expected).isNotEmpty ||
        expected.difference(key.keys.toSet()).isNotEmpty) {
      throw SPRoomSchemaException(
        'Primary key for $_table must contain exactly: ${expected.join(', ')}.',
      );
    }
    if (key.values.any((value) => value == null)) {
      throw ArgumentError.value(
        key,
        'key',
        'Primary-key values cannot be null.',
      );
    }
  }
}

/// Builder for an [SPRoomDatabase].
///
/// The API mirrors the lifecycle of Android Room's database builder while
/// remaining idiomatic Dart. Android/iOS/macOS use sqflite automatically.
/// Linux/Windows/web callers can inject a compatible [DatabaseFactory] from the
/// sqflite ecosystem.
class SPRoomDatabaseBuilder<T extends SPRoomDatabase> {
  SPRoomDatabaseBuilder._({
    required this.name,
    required this.version,
    required this.create,
    required List<SPRoomEntitySchema> entities,
    required this.inMemory,
    DatabaseFactory? factory,
  }) : _entities = List<SPRoomEntitySchema>.unmodifiable(entities),
       _factory = factory;

  /// Database file name.
  final String name;

  /// Target schema version.
  final int version;

  /// Creates the application database subclass.
  final T Function() create;

  /// Whether to open an in-memory database.
  final bool inMemory;

  final List<SPRoomEntitySchema> _entities;
  final List<SPRoomMigration> _migrations = <SPRoomMigration>[];
  final List<SPRoomCallback> _callbacks = <SPRoomCallback>[];
  DatabaseFactory? _factory;
  String? _explicitPath;
  bool _fallbackDestructive = false;
  bool _foreignKeys = true;
  bool _singleInstance = true;
  bool _validateSchema = true;

  /// Adds one or more explicit migration paths.
  SPRoomDatabaseBuilder<T> addMigrations(Iterable<SPRoomMigration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds lifecycle callbacks.
  SPRoomDatabaseBuilder<T> addCallback(SPRoomCallback callback) {
    _callbacks.add(callback);
    return this;
  }

  /// Recreates managed tables if no migration path exists.
  ///
  /// This destroys data and should be used only when that behavior is intended.
  SPRoomDatabaseBuilder<T> fallbackToDestructiveMigration([
    bool enabled = true,
  ]) {
    _fallbackDestructive = enabled;
    return this;
  }

  /// Enables or disables SQLite foreign-key enforcement. Enabled by default.
  SPRoomDatabaseBuilder<T> enableForeignKeys([bool enabled = true]) {
    _foreignKeys = enabled;
    return this;
  }

  /// Enables or disables sqflite single-instance behavior. Enabled by default.
  SPRoomDatabaseBuilder<T> singleInstance([bool enabled = true]) {
    _singleInstance = enabled;
    return this;
  }

  /// Enables or disables structural schema validation. Enabled by default.
  SPRoomDatabaseBuilder<T> validateSchema([bool enabled = true]) {
    _validateSchema = enabled;
    return this;
  }

  /// Overrides the sqflite-compatible database factory.
  ///
  /// This is the portability hook for `sqflite_common_ffi`, web database
  /// factories, tests, or application-specific database backends.
  SPRoomDatabaseBuilder<T> databaseFactory(DatabaseFactory factory) {
    _factory = factory;
    return this;
  }

  /// Overrides the full database path instead of using the factory default.
  SPRoomDatabaseBuilder<T> databasePath(String path) {
    if (path.trim().isEmpty) {
      throw ArgumentError.value(path, 'path', 'Database path cannot be empty.');
    }
    _explicitPath = path;
    return this;
  }

  /// Opens, migrates, validates and returns the database.
  Future<T> build() async {
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'Version must be >= 1.');
    }
    if (!inMemory && name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Database name cannot be empty.');
    }
    _validateEntitySet(_entities);
    _validateMigrations(_migrations);

    final factory = _factory ?? spRoomDefaultDatabaseFactory();
    if (factory == null) {
      throw UnsupportedError(
        'SPRoom has no default database factory on this platform. '
        'Inject a sqflite-compatible DatabaseFactory with databaseFactory(...). '
        'Android, iOS and macOS use sqflite automatically; Linux/Windows can '
        'use sqflite_common_ffi and web can use a compatible web factory.',
      );
    }

    final path = inMemory
        ? ':memory:'
        : _explicitPath ?? await _resolveDefaultPath(factory, name);
    final expectedHash = _schemaIdentityHash(_entities);

    Future<void> createSchema(Database db) async {
      final executor = SPRoomExecutor._(db);
      for (final entity in _entities) {
        await executor.execute(entity.createTableSql);
        for (final indexSql in entity.createIndexSql) {
          await executor.execute(indexSql);
        }
      }
      await _writeMasterIdentity(db, expectedHash, version);
    }

    Future<void> destructiveMigration(
      Database db,
      int oldVersion,
      int newVersion,
    ) async {
      final executor = SPRoomExecutor._(db);
      if (_foreignKeys) {
        await executor.execute('PRAGMA defer_foreign_keys = ON');
      }
      for (final entity in _entities.reversed) {
        await executor.execute(
          'DROP TABLE IF EXISTS ${_quoteIdentifier(entity.tableName)}',
        );
      }
      await executor.execute(
        'DROP TABLE IF EXISTS ${_quoteIdentifier(_masterTable)}',
      );
      await createSchema(db);
      for (final callback in _callbacks) {
        await callback.onDestructiveMigration?.call(
          executor,
          oldVersion,
          newVersion,
        );
      }
    }

    Future<void> migrate(Database db, int oldVersion, int newVersion) async {
      final path = _findMigrationPath(_migrations, oldVersion, newVersion);
      if (path == null) {
        if (!_fallbackDestructive) {
          throw SPRoomMissingMigrationException(oldVersion, newVersion);
        }
        await destructiveMigration(db, oldVersion, newVersion);
        return;
      }
      final executor = SPRoomExecutor._(db);
      for (final migration in path) {
        await migration.migrate(executor);
      }
      if (_validateSchema) {
        await _validateDatabaseSchema(db, _entities);
      }
      await _writeMasterIdentity(db, expectedHash, newVersion);
    }

    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        singleInstance: inMemory ? false : _singleInstance,
        onConfigure: (db) async {
          if (_foreignKeys) {
            await db.execute('PRAGMA foreign_keys = ON');
          }
        },
        onCreate: (db, _) async {
          await createSchema(db);
          if (_validateSchema) {
            await _validateDatabaseSchema(db, _entities);
          }
          final executor = SPRoomExecutor._(db);
          for (final callback in _callbacks) {
            await callback.onCreate?.call(executor);
          }
        },
        onUpgrade: migrate,
        onDowngrade: migrate,
        onOpen: (db) async {
          if (_validateSchema) {
            await _validateDatabaseSchema(db, _entities);
          }
          await _ensureMasterIdentity(db, expectedHash, version);
          final executor = SPRoomExecutor._(db);
          for (final callback in _callbacks) {
            await callback.onOpen?.call(executor);
          }
        },
      ),
    );

    final instance = create();
    instance._attach(
      database: database,
      factory: factory,
      path: path,
      version: version,
      entities: _entities,
    );

    return instance;
  }
}

/// Entry point for creating Room-style sqflite databases.
abstract final class SPRoom {
  /// Creates a file-backed database builder.
  static SPRoomDatabaseBuilder<T> databaseBuilder<T extends SPRoomDatabase>({
    required String name,
    required int version,
    required T Function() create,
    required List<SPRoomEntitySchema> entities,
    DatabaseFactory? factory,
  }) => SPRoomDatabaseBuilder<T>._(
    name: name,
    version: version,
    create: create,
    entities: entities,
    inMemory: false,
    factory: factory,
  );

  /// Creates an in-memory database builder, primarily for tests/previews.
  static SPRoomDatabaseBuilder<T>
  inMemoryDatabaseBuilder<T extends SPRoomDatabase>({
    required int version,
    required T Function() create,
    required List<SPRoomEntitySchema> entities,
    DatabaseFactory? factory,
  }) => SPRoomDatabaseBuilder<T>._(
    name: ':memory:',
    version: version,
    create: create,
    entities: entities,
    inMemory: true,
    factory: factory,
  );
}

/// Base exception for SPRoom failures caused by schema/configuration problems.
class SPRoomException implements Exception {
  /// Creates an exception with [message].
  const SPRoomException(this.message);

  /// Human-readable failure detail.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Indicates an invalid or mismatched entity/database schema.
class SPRoomSchemaException extends SPRoomException {
  /// Creates a schema exception.
  const SPRoomSchemaException(super.message);
}

/// Indicates that no registered migration can reach the target version.
class SPRoomMissingMigrationException extends SPRoomException {
  /// Creates a missing-migration exception.
  SPRoomMissingMigrationException(this.fromVersion, this.toVersion)
    : super(
        'No SPRoom migration path exists from version $fromVersion to '
        '$toVersion. Register migrations or explicitly enable destructive '
        'migration.',
      );

  /// Existing database version.
  final int fromVersion;

  /// Requested database version.
  final int toVersion;
}

class _SPRoomTransactionContext {
  _SPRoomTransactionContext(this.transaction, this.changedTables);

  final Transaction transaction;
  final Set<String> changedTables;
}

ConflictAlgorithm? _toSqfliteConflict(SPRoomConflictStrategy? strategy) {
  if (strategy == null) return null;
  return switch (strategy) {
    SPRoomConflictStrategy.abort => ConflictAlgorithm.abort,
    SPRoomConflictStrategy.fail => ConflictAlgorithm.fail,
    SPRoomConflictStrategy.ignore => ConflictAlgorithm.ignore,
    SPRoomConflictStrategy.replace => ConflictAlgorithm.replace,
    SPRoomConflictStrategy.rollback => ConflictAlgorithm.rollback,
  };
}

(String, List<Object?>) _whereFromKey(Map<String, Object?> key) {
  final columns = key.keys.toList(growable: false);
  return (
    columns.map((column) => '${_quoteIdentifier(column)} = ?').join(' AND '),
    columns.map((column) => key[column]).toList(growable: false),
  );
}

String _quoteIdentifier(String identifier) {
  if (identifier.contains('\u0000')) {
    throw ArgumentError.value(identifier, 'identifier', 'Contains a NUL byte.');
  }
  return '"${identifier.replaceAll('"', '""')}"';
}

void _validateEntitySet(List<SPRoomEntitySchema> entities) {
  if (entities.isEmpty) {
    throw const SPRoomSchemaException(
      'SPRoom database must manage at least one entity.',
    );
  }
  final tables = <String>{};
  final indices = <String>{};
  for (final entity in entities) {
    entity._validateDefinition();
    if (entity.tableName == _masterTable) {
      throw SPRoomSchemaException(
        'Table name "$_masterTable" is reserved for SPRoom schema identity.',
      );
    }
    if (!tables.add(entity.tableName)) {
      throw SPRoomSchemaException(
        'Duplicate managed table "${entity.tableName}".',
      );
    }
    for (final index in entity.indices) {
      if (!indices.add(index.name)) {
        throw SPRoomSchemaException(
          'Index name "${index.name}" is duplicated across the database.',
        );
      }
    }
  }

  final byTable = <String, SPRoomEntitySchema>{
    for (final entity in entities) entity.tableName: entity,
  };
  for (final entity in entities) {
    for (final key in entity.foreignKeys) {
      final target = byTable[key.referencedTable];
      if (target == null) {
        throw SPRoomSchemaException(
          '${entity.tableName} references unmanaged table '
          '${key.referencedTable}.',
        );
      }
      final targetColumns = target.columns.map((column) => column.name).toSet();
      for (final column in key.referencedColumns) {
        if (!targetColumns.contains(column)) {
          throw SPRoomSchemaException(
            '${entity.tableName} foreign key references missing column '
            '${key.referencedTable}.$column.',
          );
        }
      }

      final referenced = key.referencedColumns;
      final targetPrimary = target.primaryKeyColumns
          .map((column) => column.name)
          .toList();
      final matchesPrimary = _sameStrings(referenced, targetPrimary);
      final matchesUniqueColumn =
          referenced.length == 1 &&
          target.columns.any(
            (column) => column.name == referenced.single && column.unique,
          );
      final matchesUniqueIndex = target.indices.any(
        (index) =>
            index.unique &&
            index.whereSql == null &&
            _sameStrings(index.columns, referenced),
      );
      if (!matchesPrimary && !matchesUniqueColumn && !matchesUniqueIndex) {
        throw SPRoomSchemaException(
          '${entity.tableName} foreign key references '
          '${key.referencedTable}(${referenced.join(', ')}) but those columns '
          'are not a primary key or UNIQUE key.',
        );
      }
    }
  }
}

void _validateMigrations(List<SPRoomMigration> migrations) {
  final pairs = <String>{};
  for (final migration in migrations) {
    if (migration.startVersion < 1 ||
        migration.endVersion < 1 ||
        migration.startVersion == migration.endVersion) {
      throw ArgumentError(
        'SPRoom migrations require distinct positive versions.',
      );
    }
    final pair = '${migration.startVersion}->${migration.endVersion}';
    if (!pairs.add(pair)) {
      throw ArgumentError('Duplicate SPRoom migration $pair.');
    }
  }
}

List<SPRoomMigration>? _findMigrationPath(
  List<SPRoomMigration> migrations,
  int from,
  int to,
) {
  if (from == to) return const <SPRoomMigration>[];
  final upgrading = to > from;

  List<SPRoomMigration>? visit(int current, Set<int> visited) {
    if (current == to) return <SPRoomMigration>[];
    if (!visited.add(current)) return null;

    final candidates =
        migrations.where((migration) {
          if (migration.startVersion != current) return false;
          if (upgrading) {
            return migration.endVersion > current && migration.endVersion <= to;
          }
          return migration.endVersion < current && migration.endVersion >= to;
        }).toList()..sort(
          (a, b) => upgrading
              ? b.endVersion.compareTo(a.endVersion)
              : a.endVersion.compareTo(b.endVersion),
        );

    for (final migration in candidates) {
      final remainder = visit(migration.endVersion, Set<int>.from(visited));
      if (remainder != null) {
        return <SPRoomMigration>[migration, ...remainder];
      }
    }
    return null;
  }

  return visit(from, <int>{});
}

Future<String> _resolveDefaultPath(DatabaseFactory factory, String name) async {
  final base = await factory.getDatabasesPath();
  if (base.isEmpty) return name;
  final separator = base.endsWith('/') || base.endsWith('\\')
      ? ''
      : (base.contains('\\') && !base.contains('/') ? '\\' : '/');
  return '$base$separator$name';
}

const String _masterTable = 'sp_room_master_table';

Future<void> _writeMasterIdentity(
  DatabaseExecutor db,
  String identityHash,
  int version,
) async {
  await db.execute(
    'CREATE TABLE IF NOT EXISTS ${_quoteIdentifier(_masterTable)} '
    '(id INTEGER PRIMARY KEY, identity_hash TEXT NOT NULL, version INTEGER NOT NULL)',
  );
  await db.insert(_masterTable, <String, Object?>{
    'id': 1,
    'identity_hash': identityHash,
    'version': version,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<void> _ensureMasterIdentity(
  DatabaseExecutor db,
  String identityHash,
  int version,
) async {
  final exists = await db.rawQuery(
    'SELECT name FROM sqlite_master WHERE type = ? AND name = ? LIMIT 1',
    <Object?>['table', _masterTable],
  );
  if (exists.isEmpty) {
    await _writeMasterIdentity(db, identityHash, version);
    return;
  }
  final rows = await db.query(
    _masterTable,
    where: 'id = ?',
    whereArgs: <Object?>[1],
  );
  if (rows.isEmpty) {
    await _writeMasterIdentity(db, identityHash, version);
    return;
  }
  final stored = rows.first['identity_hash'];
  if (stored != identityHash) {
    throw SPRoomSchemaException(
      'Database schema identity does not match the schema declared by the app. '
      'A migration may be missing or the database was modified outside SPRoom.',
    );
  }
}

String _schemaIdentityHash(List<SPRoomEntitySchema> entities) {
  final canonical = entities.map((entity) {
    final indices = entity.createIndexSql.toList()..sort();
    return '${entity.createTableSql}|${indices.join('|')}';
  }).toList()..sort();

  // Stable 64-bit FNV-1a expressed as hexadecimal. This is an identity marker,
  // not a cryptographic security primitive.
  var hash = BigInt.parse('14695981039346656037');
  final prime = BigInt.from(1099511628211);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final unit in canonical.join('\n').codeUnits) {
    hash ^= BigInt.from(unit);
    hash = (hash * prime) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

Future<void> _validateDatabaseSchema(
  DatabaseExecutor db,
  List<SPRoomEntitySchema> entities,
) async {
  for (final entity in entities) {
    final tableInfo = await db.rawQuery(
      'PRAGMA table_info(${_quoteIdentifier(entity.tableName)})',
    );
    if (tableInfo.isEmpty) {
      throw SPRoomSchemaException(
        'Expected table ${entity.tableName} does not exist.',
      );
    }

    final actualByName = <String, Map<String, Object?>>{
      for (final row in tableInfo) row['name'] as String: row,
    };
    if (actualByName.length != entity.columns.length) {
      throw SPRoomSchemaException(
        '${entity.tableName} has ${actualByName.length} columns; '
        '${entity.columns.length} were declared.',
      );
    }

    final declaredPrimaryKeys = entity.primaryKeyColumns;
    final singlePrimaryKey = declaredPrimaryKeys.length == 1
        ? declaredPrimaryKeys.single
        : null;

    for (final column in entity.columns) {
      final actual = actualByName[column.name];
      if (actual == null) {
        throw SPRoomSchemaException(
          'Missing column ${entity.tableName}.${column.name}.',
        );
      }
      final actualType = (actual['type'] as String? ?? '').toUpperCase();
      if (actualType != column.type.sql) {
        throw SPRoomSchemaException(
          '${entity.tableName}.${column.name} type is $actualType; '
          'expected ${column.type.sql}.',
        );
      }
      final actualPrimaryPosition = (actual['pk'] as num? ?? 0).toInt();
      final expectedPrimaryPosition = column.primaryKey
          ? declaredPrimaryKeys.indexOf(column) + 1
          : 0;
      if (actualPrimaryPosition != expectedPrimaryPosition) {
        throw SPRoomSchemaException(
          '${entity.tableName}.${column.name} primary-key definition/order differs.',
        );
      }
      final expectedNotNull =
          !column.nullable &&
          !(!entity.withoutRowId &&
              identical(column, singlePrimaryKey) &&
              column.type == SPRoomSqlType.integer);
      final actualNotNull = (actual['notnull'] as num? ?? 0).toInt() != 0;
      if (actualNotNull != expectedNotNull) {
        throw SPRoomSchemaException(
          '${entity.tableName}.${column.name} nullability differs.',
        );
      }
      final actualDefault = actual['dflt_value']?.toString();
      if (_normalizeDefaultSql(actualDefault) !=
          _normalizeDefaultSql(column.defaultValueSql)) {
        throw SPRoomSchemaException(
          '${entity.tableName}.${column.name} default value differs.',
        );
      }
    }

    final indexList = await db.rawQuery(
      'PRAGMA index_list(${_quoteIdentifier(entity.tableName)})',
    );
    final actualIndices = <String, Map<String, Object?>>{
      for (final row in indexList)
        if (row['name'] is String) row['name'] as String: row,
    };
    final actualIndexColumns = <String, List<String>>{};
    for (final entry in actualIndices.entries) {
      final info = await db.rawQuery(
        'PRAGMA index_info(${_quoteIdentifier(entry.key)})',
      );
      actualIndexColumns[entry.key] = info
          .map((row) => row['name'] as String)
          .toList(growable: false);
    }

    for (final index in entity.indices) {
      final actual = actualIndices[index.name];
      if (actual == null) {
        throw SPRoomSchemaException(
          'Missing index ${index.name} on ${entity.tableName}.',
        );
      }
      final unique = (actual['unique'] as num? ?? 0).toInt() != 0;
      if (unique != index.unique) {
        throw SPRoomSchemaException('Index ${index.name} uniqueness differs.');
      }
      final columns = actualIndexColumns[index.name] ?? const <String>[];
      if (!_sameStrings(columns, index.columns)) {
        throw SPRoomSchemaException(
          'Index ${index.name} columns differ from the declared schema.',
        );
      }
    }

    for (final column in entity.columns.where((column) => column.unique)) {
      final hasUniqueIndex = actualIndices.entries.any((entry) {
        final unique = (entry.value['unique'] as num? ?? 0).toInt() != 0;
        final columns = actualIndexColumns[entry.key] ?? const <String>[];
        return unique && _sameStrings(columns, <String>[column.name]);
      });
      if (!hasUniqueIndex) {
        throw SPRoomSchemaException(
          '${entity.tableName}.${column.name} is declared UNIQUE but the '
          'database constraint is missing.',
        );
      }
    }

    final foreignKeyRows = await db.rawQuery(
      'PRAGMA foreign_key_list(${_quoteIdentifier(entity.tableName)})',
    );
    final groupedForeignKeys = <int, List<Map<String, Object?>>>{};
    for (final row in foreignKeyRows) {
      final id = (row['id'] as num).toInt();
      groupedForeignKeys
          .putIfAbsent(id, () => <Map<String, Object?>>[])
          .add(row);
    }
    final actualForeignKeys = groupedForeignKeys.values.map((rows) {
      rows.sort(
        (a, b) =>
            (a['seq'] as num).toInt().compareTo((b['seq'] as num).toInt()),
      );
      return _foreignKeySignatureFromRows(rows);
    }).toSet();
    final expectedForeignKeys = entity.foreignKeys
        .map(_foreignKeySignatureFromSchema)
        .toSet();
    if (actualForeignKeys.length != expectedForeignKeys.length ||
        actualForeignKeys.difference(expectedForeignKeys).isNotEmpty) {
      throw SPRoomSchemaException(
        '${entity.tableName} foreign-key definition differs from the '
        'declared schema.',
      );
    }
  }
}

String? _normalizeDefaultSql(String? value) {
  if (value == null) return null;
  var normalized = value.trim();
  while (normalized.length >= 2 &&
      normalized.startsWith('(') &&
      normalized.endsWith(')')) {
    normalized = normalized.substring(1, normalized.length - 1).trim();
  }
  return normalized;
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

String _foreignKeySignatureFromSchema(SPRoomForeignKey key) =>
    '${key.referencedTable}|${key.columns.join(',')}|'
    '${key.referencedColumns.join(',')}|${key.onDelete.sql}|${key.onUpdate.sql}';

String _foreignKeySignatureFromRows(List<Map<String, Object?>> rows) {
  final first = rows.first;
  return '${first['table']}|'
      '${rows.map((row) => row['from']).join(',')}|'
      '${rows.map((row) => row['to']).join(',')}|'
      '${first['on_delete']}|${first['on_update']}';
}
