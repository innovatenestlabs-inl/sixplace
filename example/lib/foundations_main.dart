import 'package:flutter/material.dart';
import 'package:sixplace/sixplace.dart';

void main() {
  runApp(const FoundationsDemoApp());
}

class FoundationsDemoApp extends StatelessWidget {
  const FoundationsDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sixplace foundations',
    debugShowCheckedModeBanner: false,
    theme: SPTheme.light(seedColor: const Color(0xFF5B5BD6)),
    darkTheme: SPTheme.dark(seedColor: const Color(0xFF5B5BD6)),
    home: const FoundationsDemoPage(),
  );
}

class FoundationsDemoPage extends StatefulWidget {
  const FoundationsDemoPage({super.key});

  @override
  State<FoundationsDemoPage> createState() => _FoundationsDemoPageState();
}

class _FoundationsDemoPageState extends State<FoundationsDemoPage> {
  final _formKey = GlobalKey<FormState>();
  final _formController = SPFormController();
  final _nameController = TextEditingController();
  final _storage = SPStorage(
    preferences: SPMemoryPreferencesStore(),
    secure: SPMemorySecureStore(),
  );

  int? _customerType;
  bool _confirmed = false;
  String _storedName = 'Nothing stored yet.';

  Future<void> _save() async {
    final saved = await _formController.submit<bool>(
      formKey: _formKey,
      context: context,
      action: () async {
        await _storage.writePreference('name', _nameController.text.trim());
        await _storage.writePreference('customerType', _customerType!);
        await _storage.writeSecure('demoToken', 'session-only-demo-token');
        _storage.cache.put(
          'lastSavedName',
          _nameController.text.trim(),
          ttl: const Duration(minutes: 5),
        );
        return true;
      },
    );

    if (!mounted || saved != true) return;
    setState(() {
      _storedName = _storage.cache.get<String>('lastSavedName') ?? 'Missing';
    });
    SPFeedback.showMessage(
      context,
      'Saved successfully.',
      type: SPFeedbackType.success,
    );
  }

  Future<void> _showStoredData() async {
    final name = await _storage.readPreference<String>('name');
    final token = await _storage.readSecure('demoToken');
    if (!mounted) return;
    await SPFeedback.showAlert(
      context,
      title: 'Stored demo values',
      message: 'Name: ${name ?? 'none'}\nSecure value: ${token ?? 'none'}',
    );
  }

  @override
  void dispose() {
    _formController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const SPAppBar(title: 'Sixplace foundations'),
    body: SingleChildScrollView(
      child: SPContainer.fluid(
        padding: EdgeInsets.all(context.spSpacing.md),
        child: SPRow(
          gap: context.spSpacing.lg,
          children: [
            SPCol(
              lg: 7,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(context.spSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'SPForms + SPFeedback',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: context.spSpacing.md),
                        SPTextFormField(
                          controller: _nameController,
                          label: 'Customer name',
                          validator: SPValidators.compose([
                            SPValidators.required(),
                            SPValidators.minLength(3),
                          ]),
                        ),
                        SizedBox(height: context.spSpacing.md),
                        SPDropdownFormField<int>(
                          label: 'Customer type',
                          initialValue: _customerType,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Retail')),
                            DropdownMenuItem(value: 2, child: Text('Dealer')),
                          ],
                          onChanged: (value) => _customerType = value,
                          validator: (value) =>
                              value == null ? 'Choose a customer type.' : null,
                        ),
                        SizedBox(height: context.spSpacing.sm),
                        SPCheckboxFormField(
                          initialValue: _confirmed,
                          title: 'I confirm the information is correct',
                          onChanged: (value) => _confirmed = value,
                          validator: (value) => value == true
                              ? null
                              : 'Confirmation is required.',
                        ),
                        SizedBox(height: context.spSpacing.md),
                        SPSubmitButton(
                          controller: _formController,
                          label: 'Save',
                          busyLabel: 'Saving…',
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SPCol(
              lg: 5,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(context.spSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'SPTheme + SPStorage',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: context.spSpacing.md),
                      Container(
                        padding: EdgeInsets.all(context.spSpacing.md),
                        decoration: BoxDecoration(
                          color: context.spTheme.success.withAlpha(31),
                          borderRadius: BorderRadius.circular(
                            context.spRadius.lg,
                          ),
                        ),
                        child: Text('Cached name: $_storedName'),
                      ),
                      SizedBox(height: context.spSpacing.md),
                      OutlinedButton(
                        onPressed: _showStoredData,
                        child: const Text('Read stored values'),
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
