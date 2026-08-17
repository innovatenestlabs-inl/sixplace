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
      title: 'Sixplace Layout Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5B5BD6),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const LayoutExamplePage(),
    );
  }
}

class LayoutExamplePage extends StatelessWidget {
  const LayoutExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SPAppBar(
        title: 'Six Place Layout Example',
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SPContainer.fluid(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final breakpoint = SPBreakpoints.standard.resolve(width);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BreakpointBanner(width: width, breakpoint: breakpoint),
                    const SizedBox(height: 32),

                    const _SectionTitle(
                      title: 'Bootstrap-style two-column layout',
                      description:
                          'One column on mobile and two columns from md.',
                    ),
                    const SizedBox(height: 16),

                    const SPRow(
                      gap: 16,
                      children: [
                        SPCol(
                          md: 6,
                          child: _DemoCard(
                            title: 'Card 1',
                            description: 'This is the first responsive card.',
                            specification: 'SPCol(md: 6)',
                            icon: Icons.dashboard_outlined,
                            color: Color(0xFF5B5BD6),
                          ),
                        ),
                        SPCol(
                          md: 6,
                          child: _DemoCard(
                            title: 'Card 2',
                            description: 'This is the second responsive card.',
                            specification: 'SPCol(md: 6)',
                            icon: Icons.widgets_outlined,
                            color: Color(0xFF00897B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    const _SectionTitle(
                      title: 'Three-column layout',
                      description:
                          'One column on mobile, two from sm, and three from lg.',
                    ),
                    const SizedBox(height: 16),

                    const SPRow(
                      gap: 16,
                      children: [
                        SPCol(
                          sm: 6,
                          lg: 4,
                          child: _DemoCard(
                            title: 'Layout',
                            description: 'Responsive grids, rows and columns.',
                            specification: 'sm: 6, lg: 4',
                            icon: Icons.grid_view_rounded,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        SPCol(
                          sm: 6,
                          lg: 4,
                          child: _DemoCard(
                            title: 'Network',
                            description:
                                'Requests, authentication and retries.',
                            specification: 'sm: 6, lg: 4',
                            icon: Icons.cloud_outlined,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        SPCol(
                          sm: 6,
                          lg: 4,
                          child: _DemoCard(
                            title: 'Feedback',
                            description:
                                'Toasts, alerts, loaders and messages.',
                            specification: 'sm: 6, lg: 4',
                            icon: Icons.notifications_none_rounded,
                            color: Color(0xFF7B1FA2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    const _SectionTitle(
                      title: 'Unequal columns',
                      description:
                          'A wider content area with a smaller sidebar.',
                    ),
                    const SizedBox(height: 16),

                    const SPRow(
                      gap: 16,
                      children: [
                        SPCol(
                          lg: 8,
                          child: _DemoCard(
                            title: 'Main content',
                            description:
                                'Uses eight of the twelve available columns.',
                            specification: 'SPCol(lg: 8)',
                            icon: Icons.article_outlined,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        SPCol(
                          lg: 4,
                          child: _DemoCard(
                            title: 'Sidebar',
                            description:
                                'Uses four of the twelve available columns.',
                            specification: 'SPCol(lg: 4)',
                            icon: Icons.view_sidebar_outlined,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakpointBanner extends StatelessWidget {
  const _BreakpointBanner({required this.width, required this.breakpoint});

  final double width;
  final SPBreakpoint breakpoint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.devices_rounded, color: colorScheme.onPrimaryContainer),
          Text(
            'Available width: ${width.toStringAsFixed(0)} px',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              _breakpointName(breakpoint).toUpperCase(),
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.description,
    required this.specification,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final String specification;
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
              Text(
                specification,
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _breakpointName(SPBreakpoint breakpoint) {
  switch (breakpoint) {
    case SPBreakpoint.xs:
      return 'xs';
    case SPBreakpoint.sm:
      return 'sm';
    case SPBreakpoint.md:
      return 'md';
    case SPBreakpoint.lg:
      return 'lg';
    case SPBreakpoint.xl:
      return 'xl';
    case SPBreakpoint.xxl:
      return 'xxl';
  }
}
