import 'package:flutter/material.dart';
import 'package:sixplace/room.dart';

const noteSchema = SPRoomEntitySchema(
  tableName: 'notes',
  columns: <SPRoomColumn>[
    SPRoomColumn(
      name: 'id',
      type: SPRoomSqlType.integer,
      primaryKey: true,
      autoIncrement: true,
    ),
    SPRoomColumn(name: 'title', type: SPRoomSqlType.text),
    SPRoomColumn(name: 'created_at', type: SPRoomSqlType.integer),
  ],
);

class Note {
  const Note({this.id, required this.title, required this.createdAt});

  final int? id;
  final String title;
  final DateTime createdAt;
}

class NoteAdapter extends SPRoomEntityAdapter<Note> {
  @override
  SPRoomEntitySchema get schema => noteSchema;

  @override
  Note fromRow(Map<String, Object?> row) => Note(
    id: (row['id'] as num?)?.toInt(),
    title: row['title']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (row['created_at']! as num).toInt(),
    ),
  );

  @override
  Map<String, Object?> toRow(Note entity) => <String, Object?>{
    'id': entity.id,
    'title': entity.title,
    'created_at': entity.createdAt.millisecondsSinceEpoch,
  };
}

class NotesDatabase extends SPRoomDatabase {
  late final SPRoomDao<Note> notes = SPRoomDao<Note>(this, NoteAdapter());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await SPRoom.databaseBuilder<NotesDatabase>(
    name: 'sixplace_notes.db',
    version: 1,
    create: NotesDatabase.new,
    entities: const <SPRoomEntitySchema>[noteSchema],
  ).build();

  runApp(RoomExampleApp(database: database));
}

class RoomExampleApp extends StatelessWidget {
  const RoomExampleApp({super.key, required this.database});

  final NotesDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RoomExamplePage(database: database),
    );
  }
}

class RoomExamplePage extends StatelessWidget {
  const RoomExamplePage({super.key, required this.database});

  final NotesDatabase database;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SPRoom example')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await database.notes.insert(
            Note(
              title: 'Note ${DateTime.now().second}',
              createdAt: DateTime.now(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Note>>(
        stream: database.notes.watch(orderBy: 'id DESC'),
        builder: (context, snapshot) {
          final notes = snapshot.data ?? const <Note>[];
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(note.createdAt.toIso8601String()),
              );
            },
          );
        },
      ),
    );
  }
}
