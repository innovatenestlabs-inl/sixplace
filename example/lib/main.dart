import 'package:flutter/material.dart';
import 'package:sixplace/sixplace.dart';

void main() {
  runApp(const SixplaceExampleApp());
}

class SixplaceExampleApp extends StatelessWidget {
  const SixplaceExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sixplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5B5BD6),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const SixPlaceScope(
        designSize: Size(390, 844),
        rootFontSize: 16,
        child: ResponsiveSizingExamplePage(),
      ),
    );
  }
}

class ResponsiveSizingExamplePage extends StatefulWidget {
  const ResponsiveSizingExamplePage({super.key});

  @override
  State<ResponsiveSizingExamplePage> createState() =>
      _ResponsiveSizingExamplePageState();
}

class _ResponsiveSizingExamplePageState
    extends State<ResponsiveSizingExamplePage> {
  double textScale = 1.0;

  @override
  Widget build(BuildContext context) {
    SixPlace.init(context, designSize: const Size(390, 844), rootFontSize: 16);

    final screen = MediaQuery.sizeOf(context);
    final width = 100.w;
    final height = 48.h;
    final bodyText = 16.sp;
    final leadText = 1.5.rem;
    final parentText = 1.5.em(context);

    final content = MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        appBar: const SPAppBar(
          title: 'Sixplace sizing + typography',
          centerTitle: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: SPContainer.fluid(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Viewport: ${screen.width.toStringAsFixed(0)} × ${screen.height.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Design size: 390 × 844 | Root font: 16px | Text scale: ${textScale.toStringAsFixed(2)}x',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: textScale,
                          min: 0.8,
                          max: 2,
                          divisions: 12,
                          label: 'Text scale ${textScale.toStringAsFixed(2)}x',
                          onChanged: (value) =>
                              setState(() => textScale = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Numeric sizing',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: '100.w',
                          value: '${width.toStringAsFixed(1)} px',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          label: '48.h',
                          value: '${height.toStringAsFixed(1)} px',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Typography',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '16.sp = ${bodyText.toStringAsFixed(2)} px',
                    style: TextStyle(fontSize: 16.sp),
                    textScaler: TextScaler.noScaling,
                  ),
                  Text(
                    '1.5.rem = ${leadText.toStringAsFixed(2)} px',
                    style: TextStyle(fontSize: 1.5.rem),
                    textScaler: TextScaler.noScaling,
                  ),
                  DefaultTextStyle(
                    style: const TextStyle(fontSize: 18),
                    child: Text(
                      '1.5.em = ${parentText.toStringAsFixed(2)} px',
                      style: TextStyle(fontSize: 1.5.em(context)),
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Layout integration',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  const SPRow(
                    gap: 16,
                    children: [
                      SPCol(
                        sm: 6,
                        md: 4,
                        child: _DemoCard(
                          title: 'Layout',
                          description:
                              'Responsive grid continues to work without init on each widget.',
                          icon: Icons.grid_view_rounded,
                          color: Color(0xFF5B5BD6),
                        ),
                      ),
                      SPCol(
                        sm: 6,
                        md: 4,
                        child: _DemoCard(
                          title: 'Sizing',
                          description:
                              'Values resolve from the active viewport and design dimensions.',
                          icon: Icons.straighten_rounded,
                          color: Color(0xFF00897B),
                        ),
                      ),
                      SPCol(
                        sm: 12,
                        md: 4,
                        child: _DemoCard(
                          title: 'Text',
                          description:
                              'Typography uses the live TextScaler once at render time.',
                          icon: Icons.text_fields_rounded,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return content;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E5EC)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
