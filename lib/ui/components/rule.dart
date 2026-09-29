import 'package:flutter/widgets.dart';

import '../theme.dart';
import '../tokens/spacing.dart';

/// 2px editorial `rule` above data blocks and tables.
class ClRule extends StatelessWidget {
  const ClRule({super.key});

  @override
  Widget build(BuildContext context) => Container(height: ClSize.rule, color: context.clColors.rule);
}

/// 1px `border` between rows.
class ClDivider extends StatelessWidget {
  const ClDivider({super.key, this.vertical = false});

  final bool vertical;

  @override
  Widget build(BuildContext context) => Container(
    width: vertical ? ClSize.hairline : null,
    height: vertical ? null : ClSize.hairline,
    color: context.clColors.border,
  );
}

/// Section heading: 2px rule, then an UPPERCASE `label`, optional trailing action.
class ClSectionHeader extends StatelessWidget {
  const ClSectionHeader({super.key, required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClRule(),
        Padding(
          padding: const EdgeInsets.only(top: ClSpace.s2, bottom: ClSpace.s2),
          child: Row(
            children: [
              Expanded(child: Text(label.toUpperCase(), style: context.clText.label)),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }
}
