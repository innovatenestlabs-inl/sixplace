import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sixplace/sixplace.dart';

import 'network_demo_transport.dart';
import 'room_main.dart' show Note, NotesDatabase, noteSchema;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SPNetwork.init(
    config: SPNetworkConfig(baseUrl: 'https://demo.invalid/api/'),
    client: createNetworkDemoTransport(),
    closeClient: true,
  );
  runApp(const SixplaceExampleApp());
}

class SixplaceExampleApp extends StatelessWidget {
  const SixplaceExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Sixplace',
    theme: SPTheme.light(seedColor: const Color(0xFF5B5BD6)),
    darkTheme: SPTheme.dark(seedColor: const Color(0xFF5B5BD6)),
    home: const SixPlaceScope(designSize: Size(390, 844), child: HomePage()),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _form = SPFormController();
  final _title = TextEditingController(text: 'My first Sixplace note');
  // These memory adapters do not persist data or encrypt secrets.
  final _storage = SPStorage(
    preferences: SPMemoryPreferencesStore(),
    secure: SPMemorySecureStore(),
  );
  NotesDatabase? _database;
  Stream<List<Note>>? _notes;
  Object? _databaseError;
  late final Future<void> _opening = _openDatabase();
  String _lastSaved = 'No notes submitted yet.';

  @override
  void initState() {
    super.initState();
    unawaited(_opening);
  }

  Future<void> _openDatabase() async {
    if (kIsWeb ||
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)) {
      return;
    }
    try {
      final database = await SPRoom.databaseBuilder<NotesDatabase>(
        name: 'sixplace_notes.db',
        version: 1,
        create: NotesDatabase.new,
        entities: const [noteSchema],
      ).build();
      if (!mounted) {
        await database.close();
        return;
      }
      setState(() {
        _database = database;
        _notes = database.notes.watch(orderBy: 'id DESC');
      });
    } catch (error) {
      if (mounted) setState(() => _databaseError = error);
    }
  }

  Future<void> _submit() async {
    try {
      final status = await _form.submit<int>(
        formKey: _formKey,
        context: context,
        action: () async {
          final title = _title.text.trim();
          final response = await SPNetwork.instance.post<Map<String, dynamic>>(
            'items',
            body: {'title': title},
          );
          await _storage.writePreference('lastNote', title);
          _storage.cache.put(
            'status',
            response.statusCode,
            ttl: const Duration(minutes: 5),
          );
          await _opening;
          await _database?.notes.insert(
            Note(title: title, createdAt: DateTime.now()),
          );
          return response.statusCode;
        },
      );
      if (status == null || !mounted) return;
      final saved = await _storage.readPreference<String>('lastNote');
      if (!mounted) return;
      setState(() => _lastSaved = saved ?? '');
      SPFeedback.showMessage(
        context,
        'Demo submitted (HTTP $status).',
        type: SPFeedbackType.success,
      );
    } catch (error) {
      if (!mounted) return;
      SPFeedback.showMessage(
        context,
        error is SPNetworkException
            ? 'Request failed: ${error.type.name}'
            : 'Could not save the note.',
        type: SPFeedbackType.error,
      );
    }
  }

  @override
  void dispose() {
    _form.dispose();
    _title.dispose();
    unawaited(_database?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SPScaffold(
    appBar: const SPAppBar(title: 'Sixplace 1.0.0'),
    body: SingleChildScrollView(
      child: SPContainer.fluid(
        responsivePadding: const SPResponsiveValue<EdgeInsetsGeometry>(
          base: EdgeInsets.all(16),
          lg: EdgeInsets.all(32),
        ),
        child: SPRow(
          gap: context.spSpacing.md,
          children: [
            SPCol(
              md: 6,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(context.spSpacing.md),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'One responsive note form',
                          style: TextStyle(fontSize: 1.25.rem),
                          textScaler: TextScaler.noScaling,
                        ),
                        Text('Breakpoint: ${context.sp.breakpoint.name}'),
                        SizedBox(height: 16.h),
                        SPTextFormField(
                          controller: _title,
                          label: 'Note title',
                          validator: SPValidators.compose([
                            SPValidators.required(),
                            SPValidators.minLength(3),
                          ]),
                        ),
                        const SizedBox(height: 16),
                        SPSubmitButton(
                          controller: _form,
                          label: 'Submit demo',
                          busyLabel: 'Saving...',
                          onPressed: _submit,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'HTTP uses an offline demo transport. '
                          'Preferences and cache last only for this session.',
                        ),
                        Text('Last preference: $_lastSaved'),
                        Text(
                          'Cached HTTP status: ${_storage.cache.get<int>('status') ?? '-'}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SPCol(
              md: 6,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(context.spSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SPRoom local notes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (_databaseError != null)
                        Text('Could not open SQLite: $_databaseError')
                      else if (_notes == null)
                        const Text(
                          'SQLite opens automatically on Android, iOS and macOS. '
                          'For Windows, Linux or web, inject a compatible factory '
                          'as shown in the README. The form also works without SQLite.',
                        )
                      else
                        StreamBuilder<List<Note>>(
                          stream: _notes,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Text('Could not load notes.');
                            }
                            final notes = snapshot.data ?? const <Note>[];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${notes.length} saved locally'),
                                for (final note in notes.take(5))
                                  Text(note.title),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
