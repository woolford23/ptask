import 'package:flutter/material.dart';

class WelcomeView extends StatelessWidget {
  final VoidCallback onContinue;

  const WelcomeView({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 72 : 24,
                vertical: isWide ? 56 : 28,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.schedule,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'pTask',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: isWide ? 82 : 56),
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _buildIntro(context)),
                              const SizedBox(width: 56),
                              Expanded(child: _buildPlannerPreview(context)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildIntro(context),
                              const SizedBox(height: 36),
                              _buildPlannerPreview(context),
                            ],
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Make room for\nwhat matters.',
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'pTask turns your priorities into a calm, workable day. Add what needs doing and let the schedule take shape around it.',
          style: textTheme.titleMedium?.copyWith(
            height: 1.45,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Build my day'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onContinue,
          child: const Text('Skip intro'),
        ),
      ],
    );
  }

  Widget _buildPlannerPreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your day, in focus',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Icon(Icons.auto_awesome, color: colorScheme.primary),
            ],
          ),
          const SizedBox(height: 20),
          _buildPreviewRow(context, '9:00', 'Deep work', '45 min', 0),
          _buildPreviewRow(context, '10:00', 'A clear next step', '30 min', 1),
          _buildPreviewRow(context, '11:00', 'A little breathing room', '15 min', 2),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(
    BuildContext context,
    String time,
    String title,
    String duration,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              time,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: colors[index],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  duration,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
